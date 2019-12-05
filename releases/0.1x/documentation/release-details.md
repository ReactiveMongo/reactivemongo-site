---
layout: default
major_version: 0.1x
title: Release details
---

## ReactiveMongo {{site._0_1x_latest_minor}} – Release details

**What's new?**

The documentation is available [online](index.html), and its code samples are compiled to make sure it's up-to-date.

- [Compatibility](#compatibility)
- [Connection options](#connection-options)
  - Support [x.509 certificate](https://docs.mongodb.com/manual/tutorial/configure-x509-client-authentication/) to authenticate.
  - Support [DNS seedlist](https://docs.mongodb.com/manual/reference/connection-string/#dns-seedlist-connection-format) in the connection URI.
  - New `rm.reconnectDelayMS` setting.
  - Add `credentials` in the [`MongoConnectionOptions`](http://reactivemongo.org/releases/0.1x/api/reactivemongo/api/MongoConnectionOptions.html)
  - [Netty native](#netty-native)
- [BSON library](#bson-library)
  - [BSON Decimal128](https://github.com/mongodb/specifications/blob/master/source/bson-decimal128/decimal128.rst#bson-decimal128-type-handling-in-drivers)
  - `Option` support & new `@NoneAsNull` annotation
- New [query and write operations](#query-and-write-operations),
  - bulk operations (e.g. `.delete.many`) on [collection](../api/reactivemongo/api/collections/GenericCollection.html),
  - `arrayFilters` on update operations.
- [Aggregation](#aggregation)
  - [`CursorOptions`](../api/reactivemongo/api/CursorOptions.html) parameter when using `.aggregatorContext`.
  - New stages: `$addFields`, `$bucketAuto`, `$count`, `$filter`, `$replaceRoot`, `$slice`
- [Administration](#administration)
- [Breaking changes](#breaking-changes)

> The next release will be 1.0.0.

The impatient can have a look at the [release slideshow](../slideshow.html).

### Compatibility

This release is compatible with the following runtime.

- [MongoDB](https://www.mongodb.org/) from 3.0 up to 4.2.
- [Akka](http://akka.io/) from 2.3.13 up to 2.5.23 (see [Setup](./tutorial/setup.html))
- [Play Framework](https://playframework.com) from 2.3.13 to 2.7.1

> MongoDB versions older than 3.0 are not longer (end of life 2018-2).

**Recommended configuration:**

The driver core and the modules are tested in a [container based environment](https://docs.travis-ci.com/user/ci-environment/#Virtualization-environments), with the specifications as bellow.

- 2 [cores](https://cloud.google.com/compute/) (64 bits)
- 4 GB of system memory, with a maximum of 2 GB for the JVM

This can be considered as a recommended environment.

### Connection options

The following options are deprecated:

- `authSource` replaced by `authenticationDatabase` (as the MongoShell option)
- `authMode` replaced by `authenticationMechanism` (as the MongoShell option)
- `sslEnabled` replaced by `ssh` (as the MongoShell option)

> [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) is now supported for the SSL connection.

The [x.509 certificate authentication](https://docs.mongodb.com/manual/tutorial/configure-x509-client-authentication/) is now supported, and can be configured by setting `x509` as `authenticationMechanism`, and with the following new options.

- **`keyStore`**: An URI to a key store (e.g. `file:///path/to/keystore.p12`)
- **`keyStorePassword`**: Provides the password to load it (if required)
- **`keyStoreType`**: Indicates the [type of the store](https://docs.oracle.com/javase/7/docs/technotes/guides/security/StandardNames.html#KeyStore)

{% highlight scala %}
import reactivemongo.api._

def connection(driver: MongoDriver) =
  driver.connection("mongodb://server:27017/db?ssl=true&authenticationMechanism=x509&keyStore=file:///path/to/keystore.p12&keyStoreType=PKCS12")
{% endhighlight %}

The [DNS seedlist](https://docs.mongodb.com/manual/reference/connection-string/#dns-seedlist-connection-format) is now supported, using `mongodb+srv://` scheme in the connection URI.
It's also possible to specify the credential directly in the URI.

{% highlight scala %}
import reactivemongo.api._

def seedListCon(driver: MongoDriver) =
  driver.connection("mongodb+srv://usr:pass@mymongo.mydomain.tld/mydb")
{% endhighlight %}

The option `rm.monitorRefreshMS` is renamed [`heartbeatFrequencyMS`](https://github.com/mongodb/specifications/blob/master/source/server-discovery-and-monitoring/server-discovery-and-monitoring.rst#heartbeatfrequencyms).

*[See the documentation](./tutorial/connect-database.html)*

#### Netty native

The internal [Netty](http://netty.io/) dependency has been updated to the version [4.1](http://netty.io/wiki/new-and-noteworthy-in-4.1.html).

It comes with various improvements (memory consumption, ...), and also to use Netty native support (kqueue for Mac OS X and epoll for Linux, on `x86_64` arch).

> Note that the Netty dependency is [shaded](https://maven.apache.org/plugins/maven-shade-plugin/) so it won't conflict with any Netty version in your environment.

*[See the documentation](./tutorial/connect-database.html#netty-native)*

### BSON library

<!-- TODO: Bison -->

The current BSON library for ReactiveMongo has been updated.

It now supports [BSON Decimal128](https://github.com/mongodb/specifications/blob/master/source/bson-decimal128/decimal128.rst#bson-decimal128-type-handling-in-drivers) (MongoDB 3.4+).

The way `Option` is handled by the macros has been improved, also with a new annotation `@NoneAsNull`, which write `None` values as `BSONNull` (instead of omitting field/value).

More: [**BSON Library overview**](./bson/overview.html)

#### Types

The [Decimal128](https://github.com/mongodb/specifications/blob/master/source/bson-decimal128/decimal128.rst) type introduced by MongoDB 3.4 is supported, as [`BSONDecimal`](../api/reactivemongo/bson/BSONDecimal$.html), and can be read or write as `java.math.BigDecimal`.

#### Handlers

A handler is now available to write and read Scala `Map` as BSON, provided the key and value types are themselves supported.

{% highlight scala %}
import scala.util.Try
import reactivemongo.api.bson._

def bsonMap = {
  val input: Map[String, Int] = Map("a" -> 1, "b" -> 2)

  // Ok as key and value (String, Int) are provided BSON handlers
  val doc: Try[BSONDocument] = BSON.writeDocument(input)

  val output = doc.flatMap { BSON.readDocument[Map[String, Int]](_) }
}
{% endhighlight %}

#### Macros

The compile-time option `AutomaticMaterialization` has been added, when using the macros with sealed family, to explicitly indicate when you want to automatically materialize required instances for the subtypes (if missing from the implicit scope).

{% highlight scala %}
sealed trait Color

case object Red extends Color
case object Blue extends Color
case class Green(brightness: Int) extends Color
case class CustomColor(code: String) extends Color

object Color {
  import reactivemongo.api.bson.{ Macros, MacroOptions },
    MacroOptions.{ AutomaticMaterialization, UnionType, \/ }

  // Use `UnionType` to define a subset of the `Color` type,
  type PredefinedColor =
    UnionType[Red.type \/ Green \/ Blue.type] with AutomaticMaterialization

  val predefinedColor = Macros.handlerOpts[Color, PredefinedColor]
}
{% endhighlight %}

A new annotation [`@Flatten`](../api/reactivemongo/bson/Macros$$Annotations$$Flatten.html) has been added, to indicate to the macros that the representation of a property must be flatten rather than a nested document.

{% highlight scala %}
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.Macros.Annotations.Flatten

case class Range(start: Int, end: Int)

case class LabelledRange(
  name: String,
  @Flatten range: Range)

// Flattened with macro as bellow:
BSONDocument("name" -> "foo", "start" -> 0, "end" -> 1)

// Rather than:
// BSONDocument("name" -> "foo", "range" -> BSONDocument(
//   "start" -> 0, "end" -> 1))
{% endhighlight %}

### Query and write operations

The collection API provides new builders for write operations. This supports bulk operations (e.g. insert many documents at once).

**[`InsertBuilder`](../api/reactivemongo/api/collections/InsertOps$InsertBuilder.html)**

The new [`insert`](../api/reactivemongo/api/collections/GenericCollection.html#insert(ordered:Boolean,writeConcern:reactivemongo.api.commands.WriteConcern)(implicitevidence$2:GenericCollection.this.pack.Writer[T]):GenericCollection.this.InsertBuilder[T]) operation is providing an `InsertBuilder`, which supports,

- simple insert with [`.one`](../api/reactivemongo/api/collections/InsertOps$InsertBuilder.html#one(document:T)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.commands.WriteResult]),
- and bulk insert with [`.many`](../api/reactivemongo/api/collections/InsertOps$InsertBuilder.html#many(documents:Iterable[T])(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.commands.MultiBulkWriteResult]).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.commands.{ MultiBulkWriteResult, WriteResult }

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

val document1 = BSONDocument(
  "firstName" -> "Stephane",
  "lastName" -> "Godbillon",
  "age" -> 29)

// Simple: .insert.one(t)
def simpleInsert(coll: BSONCollection): Future[WriteResult] =
  coll.insert.one(document1)

// Bulk: .insert.many(Seq(t1, t2, ..., tN))
def bulkInsert(coll: BSONCollection): Future[MultiBulkWriteResult] =
  coll.insert(ordered = false).many(Seq(
    document1, BSONDocument(
      "firstName" -> "Foo",
      "lastName" -> "Bar",
      "age" -> 1)))
{% endhighlight %}

**[`UpdateBuilder`](../api/reactivemongo/api/collections/UpdateOps$UpdateBuilder.html)**

The new [`update`](../api/collections/GenericCollection.html#update(ordered:Boolean,writeConcern:reactivemongo.api.commands.WriteConcern):GenericCollection.this.UpdateBuilder) operation returns an `UpdateBuilder`, which can be used to perform simple or bulk update.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def update1(personColl: BSONCollection) = {
  val selector = BSONDocument("name" -> "Jack")

  val modifier = BSONDocument(
    "$set" -> BSONDocument(
      "lastName" -> "London",
      "firstName" -> "Jack"),
      "$unset" -> BSONDocument("name" -> 1))

  // Simple update: get a future update
  val futureUpdate1 = personColl.update.one(
    q = selector, u = modifier,
    upsert = false, multi = false)

  // Bulk update: multiple update
  val updateBuilder1 = personColl.update(ordered = true)
  val updates = Future.sequence(Seq(
    updateBuilder1.element(
      q = BSONDocument("firstName" -> "Jane", "lastName" -> "Doh"),
      u = BSONDocument("age" -> 18),
      upsert = true,
      multi = false),
    updateBuilder1.element(
      q = BSONDocument("firstName" -> "Bob"),
      u = BSONDocument("age" -> 19),
      upsert = false,
      multi = true)))

  val bulkUpdateRes1 = updates.flatMap { ops => updateBuilder1.many(ops) }
}
{% endhighlight %}

**[`DeleteBuilder`](../api/reactivemongo/api/collections/DeleteOps$DeleteBuilder.html)**

The [`.delete`](../api/reactivemongo/api/collections/GenericCollection.html#delete(ordered:Boolean,writeConcern:reactivemongo.api.commands.WriteConcern):GenericCollection.this.DeleteBuilder) function returns a `DeleteBuilder`, to perform simple or bulk delete.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def simpleDelete1(personColl: BSONCollection) =
  personColl.delete.one(BSONDocument("firstName" -> "Stephane"))

def bulkDelete1(personColl: BSONCollection) = {
  val deleteBuilder = personColl.delete(ordered = false)

  val deletes = Future.sequence(Seq(
    deleteBuilder.element(
      q = BSONDocument("firstName" -> "Stephane"),
      limit = Some(1), // former option firstMatch
      collation = None),
    deleteBuilder.element(
      q = BSONDocument("lastName" -> "Doh"),
      limit = None, // delete all the matching document
      collation = None)))

  deletes.flatMap { ops => deleteBuilder.many(ops) }
}
{% endhighlight %}

> The `.remove` operation is now deprecated.

**`arrayFilters`**

The [`arrayFilters`](https://docs.mongodb.com/manual/release-notes/3.6/#arrayfilters) criteria is supported for [`findAndModify` and `update`](./tutorial/write-documents.html#find-and-modify) operations.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.WriteConcern
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def findAndUpdateArrayFilters(personColl: BSONCollection) =
  personColl.findAndModify(
    selector = BSONDocument.empty,
    modifier = personColl.updateModifier(
      update = BSONDocument(f"$$set" -> BSONDocument(
        f"grades.$$[element]" -> 100)),
      fetchNewObject = true,
      upsert = false),
    sort = None,
    fields = None,
    bypassDocumentValidation = false,
    writeConcern = WriteConcern.Journaled,
    maxTime = None,
    collation = None,
    arrayFilters = Seq(
      BSONDocument("elem.grade" -> BSONDocument(f"$$gte" -> 85))))

def updateArrayFilters(personColl: BSONCollection) =
  personColl.update.one(
    q = BSONDocument("grades" -> BSONDocument(f"$$gte" -> 100)),
    u = BSONDocument(f"$$set" -> BSONDocument(
      f"grades.$$[element]" -> 100)),
    upsert = false,
    multi = true,
    collation = None,
    arrayFilters = Seq(
      BSONDocument("element" -> BSONDocument(f"$$gte" -> 100))))
{% endhighlight %}

More: [**Find documents**](./tutorial/find-documents.html), [**Write documents**](./tutorial/write-documents.html)

### Aggregation

There are newly supported by the [Aggregation Framework](./advanced-topics/aggregation.html).

**addFields:**

The [`$addFields`](https://docs.mongodb.com/manual/reference/operator/aggregation/addFields/) stage can now be used.

{% highlight javascript %}
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson.collection.BSONCollection

def sumHomeworkQuizz(students: BSONCollection) =
  students.aggregateWith1[BSONDocument]() { framework =>
    import framework.AddFields

    AddFields(document(
      "totalHomework" -> document(f"$$sum" -> f"$$homework"),
      "totalQuiz" -> document(f"$$sum" -> f"$$quiz"))) -> List(
      AddFields(document(
        "totalScore" -> document(f"$$add" -> array(
        f"$$totalHomework", f"$$totalQuiz", f"$$extraCredit")))))
  }
{% endhighlight %}

**bucketAuto:**

The [`$bucketAuto`](https://docs.mongodb.com/manual/reference/operator/aggregation/bucketAuto/) stage introduced by MongoDB 3.4 can be used as bellow.

{% highlight scala %}
import scala.concurrent.ExecutionContext

import reactivemongo.api.Cursor

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def populationBuckets(zipcodes: BSONCollection)(implicit ec: ExecutionContext) =
  zipcodes.aggregateWith1[BSONDocument]() { framework =>
    import framework.BucketAuto

    BucketAuto(BSONString(f"$$population"), 2, None)() -> List.empty
  }.collect[Set](Int.MaxValue, Cursor.FailOnError[Set[BSONDocument]]())
{% endhighlight %}

**count:**

If the goal is only to count the aggregated documents, the [`$count`](https://docs.mongodb.com/manual/reference/operator/aggregation/count/index.html) stage can be used.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.Cursor

import reactivemongo.api.bson.{ BSONDocument, BSONDocumentReader, BSONString }
import reactivemongo.api.bson.collection.BSONCollection

def countPopulatedStates1(col: BSONCollection): Future[Int] = {
  implicit val countReader = BSONDocumentReader[Int] { doc =>
    doc.getAsTry[Int]("popCount").get
  }

  col.aggregateWith[Int]() { framework =>
    import framework.{ Count, Group, Match, SumField }

    Group(BSONString("$state"))(
      "totalPop" -> SumField("population")) -> List(
        Match(BSONDocument("totalPop" -> BSONDocument("$gte" -> 10000000L))),
        Count("popCount"))
  }.head
}
{% endhighlight %}

**facet:**

The [`$facet`](https://docs.mongodb.com/manual/reference/operator/aggregation/facet/) stage is now supported, to create multi-faceted aggregations which characterize data across multiple dimensions, or facets.

{% highlight scala %}
import reactivemongo.api.bson.collection.BSONCollection

def useFacetAgg(coll: BSONCollection) = {
  import coll.aggregationFramework.{ Count, Facet, Out, UnwindField }

  Facet(Seq(
    "foo" -> (UnwindField("bar"), List(Count("c"))),
    "lorem" -> (Out("ipsum"), List.empty)))
  /* {
    $facet: {
      'foo': [
        { '$unwind': '$bar' },
        { '$count': 'c' }
      ],
      'lorem': [
        { '$out': 'ipsum' }
      ]
    }
  } */
}
{% endhighlight %}

**filter:**

The [`$filter`](https://docs.mongodb.com/master/reference/operator/aggregation/filter/#definition) stage is now supported.

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.Cursor

import reactivemongo.api.bson.{ BSONArray, BSONDocument, BSONString }
import reactivemongo.api.bson.collection.BSONCollection

def salesWithItemGreaterThanHundered(sales: BSONCollection) =
  sales.aggregateWith1[BSONDocument]() { framework =>
    import framework._

    val sort = Sort(Ascending("_id"))

    Project(BSONDocument("items" -> Filter(
      input = BSONString(f"$$items"),
      as = "item",
      cond = BSONDocument(
        f"$$gte" -> BSONArray(f"$$$$item.price", 100))))) -> List(sort)

  }.collect[List](Int.MaxValue, Cursor.FailOnError[List[BSONDocument]]())
{% endhighlight %}

**replaceRoot:**

The [`$replaceRoot`](https://docs.mongodb.com/manual/reference/operator/aggregation/replaceRoot/#pipe._S_replaceRoot) stage is now supported.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

/* For a fruits collection:
{
   "_id" : 1,
   "fruit" : [ "apples", "oranges" ],
   "in_stock" : { "oranges" : 20, "apples" : 60 },
   "on_order" : { "oranges" : 35, "apples" : 75 }
}, ...
*/

def replaceRootTest(fruits: BSONCollection): Future[Option[BSONDocument]] = {
  fruits.aggregateWith1[BSONDocument]() { framework =>
    import framework._

    ReplaceRootField("in_stock") -> List.empty
  }.headOption
  // Results: { "oranges": 20, "apples": 60 }, ...
}
{% endhighlight %}

**slice:**

The [`$slice`](https://docs.mongodb.com/manual/reference/operator/aggregation/slice) operator is also supported as bellow.

{% highlight scala %}
import scala.concurrent.ExecutionContext

import reactivemongo.api.Cursor

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def sliceFavorites(coll: BSONCollection)(implicit ec: ExecutionContext) =
  coll.aggregateWith1[BSONDocument]() { framework =>
    import framework.{ Project, Slice }

    Project(BSONDocument(
      "name" -> 1,
      "favorites" -> Slice(
        array = BSONString(f"$$favorites"),
        n = BSONInteger(3)).makePipe)) -> List.empty
  }.collect[Seq](4, Cursor.FailOnError[Seq[BSONDocument]]())
{% endhighlight %}

More: [**Aggregation Framework**](./advanced-topics/aggregation.html)

### Administration

The operations to manage a MongoDB instance can be executed using ReactiveMongo. This new release has new functions for DB administration.

**Ping:**

The `DefaultDB` has now a [`ping`](../api/reactivemongo/api/DefaultDB.html#ping(readPreference:reactivemongo.api.ReadPreference)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Boolean]) operation, to execute a [ping command](https://docs.mongodb.com/manual/reference/command/ping/).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.DefaultDB

def ping(admin: DefaultDB): Future[Boolean] = admin.ping()
{% endhighlight %}

### Breaking changes

The [Typesafe Migration Manager](https://github.com/typesafehub/migration-manager#migration-manager-for-scala) has been setup on the ReactiveMongo repository.
It will validate all the future contributions, and help to make the API more stable.

For the current {{site._0_1x_latest_minor}} release, it has detected the following breaking changes.

[![Test coverage](https://img.shields.io/badge/coverage-60%25-yellowgreen.svg)](https://reactivemongo.github.io/ReactiveMongo/coverage/{{site._0_1x_latest_minor}}/)

**Connection**

- `reactivemongo.api.ReadPreference.Taggable`

**Operations and commands**

- `reactivemongo.api.commands.DeleteCommand.DeleteElement`

**Core/internal**

- `reactivemongo.core` packages after Netty 4.1.25 upgrade.
