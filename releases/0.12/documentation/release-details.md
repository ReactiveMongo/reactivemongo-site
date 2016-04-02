---
layout: default
title: ReactiveMongo 0.12 - Release details
---

## ReactiveMongo {{site._0_12_latest_minor}} – Release details

**What's new?**

The documentation is available [online](index.html), and its code samples are compiled to make sure it's up-to-date.
You can also browse the [API](../api/index.html).

The [MongoDB](https://www.mongodb.org/) compatibility is now from 2.6 up to 3.2.

A new better [DB resolution](../api/index.html#reactivemongo.api.MongoConnection@database%28name:String,failoverStrategy:reactivemongo.api.FailoverStrategy%29%28implicitcontext:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[reactivemongo.api.DefaultDB]) is available (see [connection tutorial](tutorial/connect-database.html)).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.{ DefaultDB, MongoConnection }

def resolve(con: MongoConnection, name: String): Future[DefaultDB] =
  con.database(name)
{% endhighlight %}

Some default [read preference](https://docs.mongodb.org/manual/core/read-preference/) and default [write concern](https://docs.mongodb.org/manual/reference/write-concern/) can be set in the [connection configuration](tutorial/connect-database.html).

{% highlight scala %}
import reactivemongo.api._, commands.WriteConcern

def connection(driver: MongoDriver) =
  driver.connection(List("localhost"), options = MongoConnectionOptions(
    readPreference = ReadPreference.primary,
    writeConcern = WriteConcern.Default
  ))
{% endhighlight %}

The default [failover strategy](../../api/index.html#reactivemongo.api.FailoverStrategy) can be defined in the [connection options](tutorial/connect-database.html).

{% highlight scala %}
import reactivemongo.api.MongoConnectionOptions

val options = MongoConnectionOptions(
  failoverStrategy = FailoverStrategy(retries = 10))
{% endhighlight %}

The interval used by the ReactiveMongo monitor to refresh the information about the MongoDB node can be configured in the [connection options](tutorial/connect-database.html). The default is interval is 2000ms.

{% highlight scala %}
import reactivemongo.api.MongoConnectionOptions

val options = MongoConnectionOptions(
  monitorRefreshMS = 5000 /* 5s */)
{% endhighlight %}

**Aggregation**

TODO: Convenient collection.aggregate

- Newly supported [Pipeline Aggregation Stages](https://docs.mongodb.org/manual/reference/operator/aggregation-pipeline/);
  - [$geoNear](https://docs.mongodb.org/manual/reference/operator/aggregation/geoNear/#pipe._S_geoNear): Returns an ordered stream of documents based on the proximity to a geospatial point.
  - [$out](https://docs.mongodb.org/manual/reference/operator/aggregation/out/#pipe._S_out): Takes the documents returned by the aggregation pipeline and writes them to a specified collection.
  - [$redact](https://docs.mongodb.org/manual/reference/operator/aggregation/redact/#pipe._S_redact): Reshapes each document in the stream by restricting the content for each document based on information stored in the documents themselves..
  - [$sample](https://docs.mongodb.org/manual/reference/operator/aggregation/sample/) aggregation stage only (only since MongoDB 3.2): Randomly selects the specified number of documents from its input.
- collection.{ findAndModify, findAndUpdate, findAndUpdate, aggregate }

The [`distinct`](https://docs.mongodb.org/manual/reference/command/distinct/) command, to find the distinct values for a specified field across a single collection, is now provided as a [collection operation](../api/index.html#reactivemongo.api.collections.GenericCollection@distinct[T]%28key:String,selector:Option[GenericCollection.this.pack.Document],readConcern:reactivemongo.api.ReadConcern%29%28implicitreader:GenericCollection.this.pack.NarrowValueReader[T],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[scala.collection.immutable.ListSet[T]]).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

def distinctStates(col: BSONCollection): Future[Set[String]] =
  col.distinct[String, Set]("state")
{% endhighlight %}

**BSON**

A [BSON handler](../api/index.html#reactivemongo.bson.BSONHandler) is provided to respectively, read a [`java.util.Date`](http://docs.oracle.com/javase/8/docs/api/java/util/Date.html) from a [`BSONDateTime`](../api/reactivemongo/bson/BSONDateTime.html), and write a `Date` as `BSONDateTime`.

{% highlight scala %}
import java.util.Date
import reactivemongo.bson._

def foo(doc: BSONDocument): Option[Date] = doc.getAs[Date]("aBsonDateTime")

def bar(date: Date): BSONDocument = BSONDocument("aBsonDateTime" -> date)
{% endhighlight %}

The traits [`BSONReader`](../api/index.html#reactivemongo.bson.BSONReader) and [`BSONWriter`](../api/index.html#reactivemongo.bson.BSONWriter) have new combinator, so new instances can be easily defined using the existing one.

{% highlight scala %}
import reactivemongo.bson._

sealed trait MyEnum
object EnumValA extends MyEnum
object EnumValB extends MyEnum

implicit def MyEnumReader(implicit underlying: BSONReader[BSONString, String]): BSONReader[BSONString, MyEnum] = underlying.afterRead {
  case "A" => EnumValA
  case "B" => EnumValB
  case v => sys.error(s"unexpected value: $v")
}

implicit def MyEnumWriter(implicit underlying: BSONWriter[String, BSONString]): BSONWriter[MyEnum, BSONString] = underlying.beforeWrite[MyEnum] {
  case EnumValA => "A"
  case _ => "B"
}
{% endhighlight %}

The instances of [`BSONTimestamp`](../api/index.html#reactivemongo.bson.BSONTimestamp) can be now created from a raw numeric value, with the `time` and `ordinal` properties being extracted.

{% highlight scala %}
import reactivemongo.bson.BSONTimestamp

def foo(raw: Long) = BSONTimestamp(raw)

// or...
def bar(time: Long, ordinal: Int) = BSONTimestamp(time, ordinal)
{% endhighlight %}

**Query**

The results from the new [aggregation operation](../api/index.html#reactivemongo.api.collections.GenericCollection@aggregate1[T]%28firstOperator:GenericCollection.this.PipelineOperator,otherOperators:List[GenericCollection.this.PipelineOperator],cursor:GenericCollection.this.BatchCommands.AggregationFramework.Cursor,explain:Boolean,allowDiskUse:Boolean,bypassDocumentValidation:Boolean,readConcern:Option[reactivemongo.api.ReadConcern],readPreference:reactivemongo.api.ReadPreference%29%28implicitec:scala.concurrent.ExecutionContext,implicitr:GenericCollection.this.pack.Reader[T]%29:scala.concurrent.Future[reactivemongo.api.Cursor[T]]) can be processed in a streaming way, using the [cursor option](https://docs.mongodb.org/manual/reference/command/aggregate/).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson._
import reactivemongo.api.Cursor
import reactivemongo.api.collections.bson.BSONCollection

def populatedStates(cities: BSONCollection): Future[Cursor[BSONDocument]] = {
  import cities.BatchCommands.AggregationFramework
  import AggregationFramework.{ Cursor => AggCursor, Group, Match, SumField }

  val cursor = AggCursor(batchSize = 1) // initial batch size

  cities.aggregate1[BSONDocument](Group(BSONString("$state"))(
    "totalPop" -> SumField("population")), List(
    Match(document("totalPop" -> document("$gte" -> 10000000L)))),
    cursor)
}
{% endhighlight %}

An [`ErrorHandler`](../api/index.html#reactivemongo.api.Cursor$@ErrorHandler[A]=%28A,Throwable%29=%3Ereactivemongo.api.Cursor.State[A]) can be used with the [`Cursor`](../api/index.html#reactivemongo.api.Cursor), instead of the limited `stopOnError` flag.

{% highlight scala %}
// TODO: Code sample
{% endhighlight %}

The field [`maxTimeMs`](https://docs.mongodb.org/manual/reference/method/cursor.maxTimeMS/) is supported by the [query builder](../api/index.html#reactivemongo.api.collections.GenericQueryBuilder@maxTimeMs%28p:Long%29:GenericQueryBuilder.this.Self), to specifies a cumulative time limit in milliseconds for processing operations.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

def withMaxTimeMs(col: BSONCollection): Future[List[BSONDocument]] = 
  col.find(BSONDocument("foo" -> "bar")).maxTimeMs(1234L).
  cursor[BSONDocument]().collect[List]()
{% endhighlight %}

The [`explain`](https://docs.mongodb.org/manual/reference/explain-results/) operation is now supported, to get information on the query plan.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

// If using the Play JSON support
import play.api.libs.json.{ Json, JsObject }
import reactivemongo.play.json._, collection.JSONCollection

def bsonExplain(col: BSONCollection): Future[Option[BSONDocument]] =
  col.find(BSONDocument.empty).explain().one[BSONDocument]

def jsonExplain(col: JSONCollection): Future[Option[JsObject]] =
  col.find(Json.obj()).explain().one[JsObject]
{% endhighlight %}

[See the API for query builder](../api/index.html#reactivemongo.api.collections.GenericQueryBuilder)

**Administration**
  
The new [`drop`](../api/index.html#reactivemongo.api.collections.GenericCollection@drop%28failIfNotFound:Boolean%29%28implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[Boolean]) operation can try, without failing if the collection doesn't exist. The previous behaviour is still available.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

// Doesn't fail if the collection represented by `col` doesn't exists,
// but return Future(false)
def dropNotFail(col: BSONCollection): Future[Boolean] = col.drop(false)

// Fails if the collection represented by `col` doesn't exists,
// as in the previous behaviour
def dropFail(col: BSONCollection): Future[Unit] = col.drop(true).map(_ => {})

def deprecatedDrop(col: BSONCollection): Future[Unit] = col.drop()
{% endhighlight %}

The replication command [`resync`](https://docs.mongodb.org/manual/reference/command/resync/) is now provided.

{% highlight scala %}
// TODO: Code sample
{% endhighlight %}

In the case class `reactivemongo.api.commands.CollStatsResult`, the field `maxSize` has been added.

{% highlight scala %}
// TODO: Code sample
{% endhighlight %}

**Playframework**

The [integration with Playframework](./tutorial/play2.html) is still easy.

- Separate [Play JSON library](./json/overview.html): serialization pack without the Play module
  - [BSONJavaScript](../../api/reactivemongo/bson/BSONJavaScript.html)
  - [BSONUndefined](../../api/reactivemongo/bson/BSONUndefined$.html)

When using the **[support for Play JSON](json/overview.html)**, if the following error occurs, it's necessary to make sure `import reactivemongo.play.json._` is used, to import default BSON/JSON conversions.

{% highlight text %}
No Json serializer as JsObject found for type play.api.libs.json.JsObject.
Try to implement an implicit OWrites or OFormat for this type.
{% endhighlight %}

Play Formatter instances

{% highlight scala %}
// TODO: Code sample
{% endhighlight %}

Play PathBindable instances

{% highlight scala %}
// TODO: Code sample
{% endhighlight %}

Separate Iteratee module

{% highlight scala %}
// TODO: Code sample
{% endhighlight %}

- For the type `reactivemongo.api.commands.LastError`, the properties `writeErrors` and `writeConcernError` have been added.

**Logging**

Log4J is still required for backward compatibility (by deprecated code), but is replaced by [SLF4J](http://www.slf4j.org/) for the [ReactiveMongo logging](./index.html#logging).

If you see the following message, please make sure you have a Log4J framework available.

{% highlight text %}
ERROR StatusLogger No log4j2 configuration file found. Using default configuration: logging only errors to the console.
{% endhighlight %}

As for SLF4J is now used, the following error is raised, please make sure to provide a [SLF4J binding](http://www.slf4j.org/manual.html#swapping) (e.g. `slf4j-simple`).

{% highlight text %}
NoClassDefFoundError: : org/slf4j/LoggerFactory
{% endhighlight %}

**Dependencies**

The [Netty](http://netty.io/) dependency has been updated to the version 3.10.4. To avoid conflict ([dependency hell](https://en.wikipedia.org/wiki/Dependency_hell)), this dependency has also been excluded from the Play module (as provided by Play). The Netty dependency will be shaded in a next release.

> MongoDB versions older than 2.6 are not longer supported by ReactiveMongo.

### Breaking changes

The [Typesafe Migration Manager](https://github.com/typesafehub/migration-manager#migration-manager-for-scala) has been setup on the ReactiveMongo repository.
It will validate all the future contributions, and help to make the API more stable.

For the current 0.12 release, it has detected the following breaking changes.

**Connection**

- In the case class [`reactivemongo.api.MongoConnectionOptions`](../api/index.html#reactivemongo.api.MongoConnectionOptions), the constructor has 2 extra properties [`writeConcern`](../api/index.html#reactivemongo.api.commands.package@WriteConcern=reactivemongo.api.commands.GetLastError) and [`readPreference`](../api/index.html#reactivemongo.api.ReadPreference).
- In the class [`reactivemongo.api.MongoConnection`](../api/index.html#reactivemongo.api.MongoConnection);
  * method `ask(reactivemongo.core.protocol.CheckedWriteRequest)` is removed
  * method `ask(reactivemongo.core.protocol.RequestMaker,Boolean)` is removed
  * method `waitForPrimary(scala.concurrent.duration.FiniteDuration)` is removed

Since [release 0.11](../../0.11/documentation/release-details.html), the package [`reactivemongo.api.collections.default`](http://reactivemongo.org/releases/0.10/api/index.html#reactivemongo.api.collections.default.package) has been refactored as the package [`reactivemongo.api.collections.bson`](http://reactivemongo.org/releases/0.11/api/index.html#reactivemongo.api.collections.bson.package).
If you get a compilation error like the following one, you need to update the corresponding imports.

{% highlight text %}
object default is not a member of package reactivemongo.api.collections
[error] import reactivemongo.api.collections.default.BSONCollection
{% endhighlight %}

**Operation results**

- The type hierarchy of the trait [`reactivemongo.api.commands.WriteResult`](../api/index.html#reactivemongo.api.commands.WriteResult) has changed in new version. It's no longer an `Exception`, and no longer inherits from [`reactivemongo.core.errors.DatabaseException`](../api/index.html#reactivemongo.core.errors.DatabaseException), `scala.util.control.NoStackTrace`, `reactivemongo.core.errors.ReactiveMongoException`
- The type hierarchy of the classes [`reactivemongo.api.commands.DefaultWriteResult`](../api/index.html#reactivemongo.api.commands.DefaultWriteResult) and [`reactivemongo.api.commands.UpdateWriteResult`](../api/index.html#reactivemongo.api.commands.UpdateWriteResult) have changed in new version; no longer inherits from `java.lang.Exception`.
  * method `fillInStackTrace()` is removed
  * method `isUnauthorized()` is removed
  * method `getMessage()` is removed
  * method `isNotAPrimaryError()` is removed
- In class [`reactivemongo.api.commands.Upserted`](../api/index.html#reactivemongo.api.commands.Upserted);
  * The constructor has changed; was `(Int, java.lang.Object)`, is now: `(Int, reactivemongo.bson.BSONValue)`.
  * The field `_id`  has now a different result type; was: `java.lang.Object`, is now: `reactivemongo.bson.BSONValue`.
- In the case class [`reactivemongo.api.commands.GetLastError.TagSet`](reactivemongo.api.commands.GetLastError$$TagSet), the field `s`  is renamed to `tag`.

**Aggregation framework**

- In the trait [`reactivemongo.api.commands.AggregationFramework`](../api/index.html#reactivemongo.api.commands.AggregationFramework);
  * the type `PipelineStage` is removed
  * the type `DocumentStage` is removed
  * the type `DocumentStageCompanion` is removed
  * the type `PipelineStageDocumentProducer` is removed
  * the type `AggregateCursorOptions` is removed
  * the field `name` is removed from all the pipeline stages
- In the case class [`reactivemongo.api.commands.AggregationFramework#Aggregate`](../api/index.html#reactivemongo.api.commands.AggregationFramework$Aggregate);
  * field `needsCursor` is removed
  * field `cursorOptions` is removed
- In case classes [`reactivemongo.api.commands.AggregationFramework.Limit`](../api/index.html#reactivemongo.api.commands.AggregationFramework@LimitextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable) and [`reactivemongo.api.commands.AggregationFramework.Skip`](../api/index.html#reactivemongo.api.commands.AggregationFramework@SkipextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable);
  * field `n` is removed
- In the case class [`reactivemongo.api.commands.AggregationFramework#Unwind`](../api/index.html#reactivemongo.api.commands.AggregationFramework$Unwind), the field `prefixedField` is removed.

**Operations and commands**

- The enumerated type `reactivemongo.api.SortOrder` is removed, as not used in the API.
- The trait `reactivemongo.api.commands.CursorCommand` is removed
- In the case class [`reactivemongo.api.commands.FindAndModifyCommand.FindAndModify`](../api/index.html#reactivemongo.api.commands.FindAndModifyCommand$Update);
  * the field `upsert` (and the corresponding constructor parameter) has been added
  * the type of the field `update` is now `Document`; was `java.lang.Object`.

**GridFS**

- In the trait [`reactivemongo.api.gridfs.ComputedMetadata`](../api/index.html#reactivemongo.api.gridfs.ComputedMetadata), the field `length` has now a different result type; was: `Int`, is now: `Long`
- In the case class [`reactivemongo.api.gridfs.DefaultFileToSave`](../api/index.html#reactivemongo.api.gridfs.DefaultFileToSave) has changed to a plain class, and its method `filename()`  has now a different result type; was: `String`, is now: `Option[String]`.
- In class [`reactivemongo.api.gridfs.DefaultReadFile`](../api/index.html#reactivemongo.api.gridfs.DefaultReadFile);
  * field `length` in  has now a different result type; was: `Int`, is now: `Long`;
  * field `filename` has now a different result type; was: `String`, is now: `Option[String]`.
- In the trait [`reactivemongo.api.gridfs.BasicMetadata`](../api/index.html#reactivemongo.api.gridfs.BasicMetadata), the field `filename` has now a different result type; was: `String`, is now: `Option[String]`.

**Core/internal**

- The class [`reactivemongo.core.commands.Authenticate`](../api/index.html#reactivemongo.core.commands.Authenticate) is now deprecated;
  * The type hierarchy of has changed in new version. No longer inherits from `reactivemongo.core.commands.BSONCommandResultMaker` and `reactivemongo.core.commands.CommandResultMaker`.
  * method `apply(reactivemongo.bson.BSONDocument)` is removed
  * method `apply(reactivemongo.core.protocol.Response)` is removed
  * see [`reactivemongo.core.commands.CrAuthenticate`](../api/index.html#reactivemongo.core.commands.CrAuthenticate) (only for the legacy MongoDB CR authentication)
- The class [`reactivemongo.core.actors.MongoDBSystem`](../api/index.html#reactivemongo.core.actors.MongoDBSystem) has changed to a trait.
- The declaration of class [`reactivemongo.core.nodeset.Authenticating`](../api/index.html#reactivemongo.core.nodeset.Authenticating) has changed to a sealed trait.