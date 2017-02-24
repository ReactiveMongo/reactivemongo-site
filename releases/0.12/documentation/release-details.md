---
layout: default
major_version: 0.12
title: Release details
---

## ReactiveMongo {{site._0_12_latest_minor}} – Release details

**What's new?**

The documentation is available [online](index.html), and its code samples are compiled to make sure it's up-to-date.

- [Compatibility](#compatibility)
- [Connection pool](#connection-pool)
  - [Database resolution](#database-resolution)
  - [Connection options](#connection-options)
- [Query and write operations](#query-and-write-operations)
- [BSON library](#bson-library)
- [Streaming](#streaming)
  - [Akka Stream](#akka-stream)
  - [Aggregated streams](#aggregated-streams)
  - [Custom streaming](#custom-streaming)
- [Aggregation](#aggregation)
- [Play Framework](#play-framework)
  - [JSON serialization](#json-serialization)
  - [Dependency injection](#dependency-injection)
  - [MVC integration](#mvc-integration)
  - [Routing](#routing)
  - [Play Iteratees](#play-iteratees)
- [Administration](#administration)
- [Logging](#logging)
- [Monitoring](#monitoring)
- [Dependencies](#dependencies)
- [Breaking changes](#breaking-changes)

> The next release will be 1.0.0 (not 0.13.0).

The impatient can have a look at the [release slideshow](../slideshow.html).

### Compatibility

This release is compatible with the following runtime.

- [MongoDB](https://www.mongodb.org/) from 2.6 up to 3.4.
- [Akka](http://akka.io/) from 2.3.13 up to 2.4.x (see [Setup](./tutorial/setup.html))
- [Play Framework](https://playframework.com) from 2.3.13 to 2.5.9

> MongoDB versions older than 2.6 are not longer supported by ReactiveMongo.

**Recommended configuration:**

The driver core and the modules are tested in a [container based environment](https://docs.travis-ci.com/user/ci-environment/#Virtualization-environments), with the specifications as bellow.

- 2 [cores](https://cloud.google.com/compute/) (64 bits)
- 4 GB of system memory, with a maximum of 2 GB for the JVM

This can be considered as a recommended environment.

### Connection pool

The way ReactiveMongo manages the connection pool has been improved.

#### Database resolution

A new better [DB resolution](../api/index.html#reactivemongo.api.MongoConnection@database%28name:String,failoverStrategy:reactivemongo.api.FailoverStrategy%29%28implicitcontext:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[reactivemongo.api.DefaultDB]) is available (see [connection tutorial](tutorial/connect-database.html)).

The synchronous `.db` has been deprecated as it was assuming it can initially find an active channel in the connection pool (`MongoConnection`), whereas checking/discovering the initial node set can take time, according the network speed/latency.

The new version fix this assumption with an asynchronous/reactive resolution of the database (possibly using a [failover strategy](../api/index.html#reactivemongo.api.FailoverStrategy)) to make sure at least one initial channel (according the chosen [read preference](../api/index.html#reactivemongo.api.ReadPreference)).

The new resolution returns a [`Future[DefaultDB]`](../api/index.html#reactivemongo.api.DefaultDB), and should be used instead of the former `connection(..)` (or its alias `connection.db(..)`).

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.{ DefaultDB, MongoConnection }

def newResolution(con: MongoConnection, name: String)(implicit ec: ExecutionContext): Future[DefaultDB] = con.database(name)
{% endhighlight %}

Similarly the function `.db` of the [Play module](./tutorial/play2.html) must be replaced by its `.database` equivalent.

It's generally a good practice not to assign the database and collection references to `val` (even to `lazy val`), as it's better to get a fresh reference each time, to automatically recover from any previous issues (e.g. network failure).

Consequently to this change, a runtime error such as `ConnectionNotInitialized` can be raised when calling a database or collection operation (e.g. `collection.find(..)`), if the *deprecated database resolution is still used*.

#### Connection options

Some default [read preference](https://docs.mongodb.org/manual/core/read-preference/) and default [write concern](https://docs.mongodb.org/manual/reference/write-concern/) can be set in the [connection configuration](tutorial/connect-database.html).

{% highlight scala %}
import reactivemongo.api._, commands.WriteConcern

def connection(driver: MongoDriver) =
  driver.connection(List("localhost"), options = MongoConnectionOptions(
    readPreference = ReadPreference.primary,
    writeConcern = WriteConcern.Default // Acknowledged
  ))
{% endhighlight %}

The authentication algorithm is now [SCRAM SHA1](https://docs.mongodb.org/manual/core/security-scram-sha-1/) by default. To change it (e.g. for MongoDB 2.6.x), see the [connection options](./tutorial/connect-database.html#connection-options).

The default [failover strategy](../api/index.html#reactivemongo.api.FailoverStrategy) can also be defined in the [connection options](tutorial/connect-database.html).

{% highlight scala %}
import reactivemongo.api.{ FailoverStrategy, MongoConnectionOptions }

val options1 = MongoConnectionOptions(
  failoverStrategy = FailoverStrategy(retries = 10))
{% endhighlight %}

The option [`maxIdleTimeMS`](https://docs.mongodb.org/manual/reference/connection-string/#urioption.maxIdleTimeMS) is now supported, with a default value 0 (no timeout).

{% highlight scala %}
import reactivemongo.api.MongoConnectionOptions

val options2 = MongoConnectionOptions(maxIdleTimeMS = 2000 /* 2s */)
{% endhighlight %}

The frequency at which the ReactiveMongo monitor refreshes the information about the MongoDB nodes can be configured in the [connection options](tutorial/connect-database.html). The default interval is 10 seconds.

{% highlight scala %}
import reactivemongo.api.MongoConnectionOptions

val options3 = MongoConnectionOptions(monitorRefreshMS = 5000 /* 5s */)
{% endhighlight %}

### Query and write operations

The collection API provides new operations.

**FindAndModify:**

The MongoDB [`findAndModify`](https://docs.mongodb.com/manual/reference/command/findAndModify/) command modifies and returns a single document. The ReactiveMongo API now has a corresponding [operation](../api/index.html#reactivemongo.api.collections.GenericCollection@findAndModify[Q](selector:Q,modifier:GenericCollection.this.BatchCommands.FindAndModifyCommand.Modify,sort:Option[GenericCollection.this.pack.Document],fields:Option[GenericCollection.this.pack.Document])(implicitselectorWriter:GenericCollection.this.pack.Writer[Q],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[GenericCollection.this.BatchCommands.FindAndModifyCommand.FindAndModifyResult]).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.{ BSONDocument, BSONDocumentReader, Macros }
import reactivemongo.api.collections.bson.BSONCollection

case class Person(firstName: String, lastName: String, age: Int)

object Person {
  implicit def reader: BSONDocumentReader[Person] =
    Macros.reader[Person]
}

def findAndModifyTests(coll: BSONCollection) = {
  val updateOp = coll.updateModifier(
    BSONDocument("$set" -> BSONDocument("age" -> 35)))

  val personBeforeUpdate: Future[Option[Person]] =
    coll.findAndModify(BSONDocument("name" -> "Joline"), updateOp).
    map(_.result[Person])

  val removedPerson: Future[Option[Person]] = coll.findAndModify(
    BSONDocument("name" -> "Jack"), coll.removeModifier).
    map(_.result[Person])
}
{% endhighlight %}

In the previous example, the `findAndModify` is used to find and update the person whose name is Joline by setting its age to 35, and it's also used to remove the document about Jack.

The `findAndModify` can be performed more easily to find and update documents, using [`findAndUpdate`](../api/index.html#reactivemongo.api.collections.GenericCollection@findAndUpdate[Q,U]%28selector:Q,update:U,fetchNewObject:Boolean,upsert:Boolean,sort:Option[GenericCollection.this.pack.Document]%29%28implicitselectorWriter:GenericCollection.this.pack.Writer[Q],implicitupdateWriter:GenericCollection.this.pack.Writer[U],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[GenericCollection.this.BatchCommands.FindAndModifyCommand.FindAndModifyResult]).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.{ BSONDocument, BSONDocumentReader, Macros }
import reactivemongo.api.collections.bson.BSONCollection

def update(collection: BSONCollection, age: Int): Future[Option[Person]] = {
  import collection.BatchCommands.FindAndModifyCommand.FindAndModifyResult
  
  val result: Future[FindAndModifyResult] = collection.findAndUpdate(
    BSONDocument("firstName" -> "James"),
    BSONDocument("$set" -> BSONDocument("age" -> 17)),
    fetchNewObject = true)

  result.map(_.result[Person])
}
{% endhighlight %}

For removal, a convenient [`findAndRemove`](../api/index.html#reactivemongo.api.collections.GenericCollection@findAndRemove[Q](selector:Q,sort:Option[GenericCollection.this.pack.Document],fields:Option[GenericCollection.this.pack.Document])(implicitselectorWriter:GenericCollection.this.pack.Writer[Q],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[GenericCollection.this.BatchCommands.FindAndModifyCommand.FindAndModifyResult]) is also available.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.{ BSONDocument, BSONDocumentReader }
import reactivemongo.api.collections.bson.BSONCollection

def removedPerson(coll: BSONCollection, name: String)(implicit ec: ExecutionContext, reader: BSONDocumentReader[Person]): Future[Option[Person]] =
  coll.findAndRemove(BSONDocument("firstName" -> name)).
    map(_.result[Person])
{% endhighlight %}

**Query builder:**

The new [`requireOne`](../api/index.html#reactivemongo.api.collections.GenericQueryBuilder@requireOne[T](readPreference:reactivemongo.api.ReadPreference)(implicitreader:GenericQueryBuilder.this.pack.Reader[T],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[T]) function, based on the [`head`](../api/index.html#reactivemongo.api.Cursor@headOption(implicitctx:scala.concurrent.ExecutionContext):scala.concurrent.Future[Option[T]]) cursor, allows to more easily find and require a single result.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

trait PersonService {
  def collection: BSONCollection

  def requirePerson(firstName: String, lastName: String)(implicit ec: ExecutionContext): Future[Person] = collection.find(BSONDocument(
    "firstName" -> firstName,
    "lastName" -> lastName
  )).requireOne[Person]
}
{% endhighlight %}

The option [`maxTimeMs`](https://docs.mongodb.org/manual/reference/method/cursor.maxTimeMS/) is supported by the [query builder](../api/index.html#reactivemongo.api.collections.GenericQueryBuilder@maxTimeMs%28p:Long%29:GenericQueryBuilder.this.Self), to specify a cumulative time limit in milliseconds for the processing of the operations.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

def withMaxTimeMs(col: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = col.find(BSONDocument("foo" -> "bar")).maxTimeMs(1234L).cursor[BSONDocument]().collect[List]()
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

[More: **Query builder API**](../api/index.html#reactivemongo.api.collections.GenericQueryBuilder)

**Error handling:**

The [`WriteResult`](../api/index.html#reactivemongo.api.commands.WriteResult) that represents the errors from executing commands, is now coming with pattern matching utilities.

- [`WriteResult.Code`](../api/index.html#reactivemongo.api.commands.WriteResult$@Code): matches the errors according the specified code (e.g. the 11000 code for the Duplicate error)
- [`WriteResult.Message`](../api/index.html#reactivemongo.api.commands.WriteResult$@Message): matches the errors according the message

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.collections.bson.BSONCollection
import reactivemongo.api.commands.WriteResult 

def insertPerson(personColl: BSONCollection, person: Person) = {
  implicit val writer = reactivemongo.bson.Macros.writer[Person]
  val future: Future[WriteResult] = personColl.insert(person)

  val end: Future[Unit] = future.map(_ => {}).recover {
    case WriteResult.Code(11000) =>
      // if the result is defined with the error code 11000 (duplicate error)
      println("Match the code 11000")

    case WriteResult.Message("Must match this exact message") =>
      println("Match the error message")

    case _ => ()
  }
}
{% endhighlight %}

The same approach can be used with [`CommandError`](../api/index.html#reactivemongo.api.commands.CommandError).

- [`CommandError.Code`](../api/index.html#reactivemongo.api.commands.CommandError$@Code): matches the errors according the specified code (e.g. the 11000 code for the Duplicate error)
- [`CommandError.Message`](../api/index.html#reactivemongo.api.commands.CommandError$@Message): matches the errors according the message

**GridFS:**

The [`GridFS`](../api/index.html#reactivemongo.api.gridfs.GridFS) provides the new `saveWithMD5` and `iterateeWithMD5`, which automatically compute the MD5 digested while storing data.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import play.api.libs.iteratee.Enumerator

import reactivemongo.api.BSONSerializationPack
import reactivemongo.api.gridfs.{ DefaultFileToSave, GridFS }
import reactivemongo.api.gridfs.Implicits._
import reactivemongo.bson.BSONValue

type BSONFile = 
  reactivemongo.api.gridfs.ReadFile[BSONSerializationPack.type, BSONValue]

def saveWithComputedMD5(
  gridfs: GridFS[BSONSerializationPack.type],
  filename: String, 
  contentType: Option[String], 
  data: Enumerator[Array[Byte]]
)(implicit ec: ExecutionContext): Future[BSONFile] = {
  // Prepare the GridFS object to the file to be pushed
  val gridfsObj = DefaultFileToSave(Some(filename), contentType)

  gridfs.saveWithMD5(data, gridfsObj)
}
{% endhighlight %}

### BSON library

The BSON library for ReactiveMongo has been updated.

A [BSON handler](../api/index.html#reactivemongo.bson.BSONHandler) is provided to respectively, read a [`java.util.Date`](http://docs.oracle.com/javase/8/docs/api/java/util/Date.html) from a [`BSONDateTime`](../api/reactivemongo/bson/BSONDateTime.html), and write a `Date` as `BSONDateTime`.

{% highlight scala %}
import java.util.Date
import reactivemongo.bson._

def foo(doc: BSONDocument): Option[Date] = doc.getAs[Date]("aBsonDateTime")

def bar(date: Date): BSONDocument = BSONDocument("aBsonDateTime" -> date)
{% endhighlight %}

The traits [`BSONReader`](../api/index.html#reactivemongo.bson.BSONReader) and [`BSONWriter`](../api/index.html#reactivemongo.bson.BSONWriter) have new combinators, so new instances can be easily defined using the existing ones.

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

The companion objects for [`BSONDocumentReader`](../api/index.html#reactivemongo.bson.BSONDocumentReader) and [`BSONDocumentWriter`](../api/index.html#reactivemongo.bson.BSONDocumentWriter) provides new factories.

{% highlight scala %}
import reactivemongo.bson.{
  BSONDocument, BSONDocumentReader, BSONDocumentWriter, BSONNumberLike
}

case class Foo(bar: String, lorem: Int)

val w1 = BSONDocumentWriter[Foo] { foo =>
  BSONDocument("_bar" -> foo.bar, "ipsum" -> foo.lorem)
}

val r1 = BSONDocumentReader[Foo] { doc =>
  (for {
    bar <- doc.getAsTry[String]("_bar")
    lorem <- doc.getAsTry[BSONNumberLike]("ipsum").map(_.toInt)
  } yield Foo(bar, lorem)).get
}
{% endhighlight %}

The new instances of [`BSONTimestamp`](../api/index.html#reactivemongo.bson.BSONTimestamp) can be created from a raw numeric value, representing the milliseconds timestamp, with the `time` and `ordinal` properties being extracted.

{% highlight scala %}
import reactivemongo.bson.BSONTimestamp

def foo(millis: Long) = BSONTimestamp(millis)

// or...
def bar(time: Long, ordinal: Int) = BSONTimestamp(time, ordinal)
{% endhighlight %}

The generic types are now supported:

{% highlight scala %}
case class GenFoo[T](bar: T, lorem: Int)

reactivemongo.bson.Macros.reader[GenFoo[String]]
{% endhighlight %}

Some undocumented macro features, such as **union types** and sealed trait support are now [explained](./bson/typeclasses.html#helpful-macros).

{% highlight scala %}
import reactivemongo.bson.{ BSONDocument, BSONHandler, Macros }

sealed trait Tree
case class Node(left: Tree, right: Tree) extends Tree
case class Leaf(data: String) extends Tree

object Tree {
  implicit val bson: BSONHandler[BSONDocument, Tree] = Macros.handler[Tree]
}
{% endhighlight %}

Taking care of backward compatibility, a refactoring of the BSON types has been started.

- The type alias `BSONElement` has been promoted to a [trait](../api/index.html#reactivemongo.bson.BSONElement).
- A new sealed family is introduced by the [`ElementProducer`](../api/index.html#reactivemongo.bson.ElementProducer) trait, implemented by `BSONElement` (that produces a single element) and `BSONElementSet`, whose instances can produce many BSON elements (`ElementProducer` can be considered as a monoid with its [composition operation](../api/index.html#reactivemongo.bson.ElementProducer$@Composition) and its [identity instance](../api/index.html#reactivemongo.bson.ElementProducer$@Empty)).
- The [`BSONElementSet`](../api/index.html#reactivemongo.bson.BSONElementSet) trait now gathers `BSONDocument` and `BSONArray`, with new operations such `prepend`, `headOption`.

[More: **BSON Library overview**](./bson/overview.html)

### Streaming

Instead of accumulating documents in memory, they can be [processed as a stream](./tutorial/streaming.html), using a reactive [`Cursor`](../api/index.html#reactivemongo.api.Cursor).

ReactiveMongo can now be used with several streaming frameworks.

#### Akka Stream

The [Akka Stream library](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-akkastream_2.11/{{site._0_12_latest_minor}}/reactivemongo-akkastream_2.11-{{site._0_12_latest_minor}}-javadoc.jar/!/index.html#package) can be used to consume ReactiveMongo results.

To enable the Akka Stream support (up to Akka 2.4.8), the import [`reactivemongo.play.akkastream.cursorProducer`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-akkastream_2.11/{{site._0_12_latest_minor}}/reactivemongo-akkastream_2.11-{{site._0_12_latest_minor}}-javadoc.jar/!/index.html#reactivemongo.akkastream.package$$cursorFlattener$) must be added.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import akka.stream.Materializer
import akka.stream.scaladsl.{ Sink, Source }

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

import reactivemongo.akkastream.{ State, cursorProducer }
// Provides the cursor producer with the AkkaStream capabilities

def processPerson0(collection: BSONCollection, query: BSONDocument)(implicit m: Materializer): Future[Seq[BSONDocument]] = {
  val sourceOfPeople: Source[BSONDocument, Future[State]] =
    collection.find(query).cursor[BSONDocument].documentSource()

  sourceOfPeople.runWith(Sink.seq[BSONDocument])
}
{% endhighlight %}

[More: **ReactiveMongo AkkaStream**](./tutorial/streaming.html#akka-stream)

#### Aggregated streams

The results from the new [aggregation operation](../api/index.html#reactivemongo.api.collections.GenericCollection@aggregateWith[T](explain:Boolean,allowDiskUse:Boolean,bypassDocumentValidation:Boolean,readConcern:Option[reactivemongo.api.ReadConcern],readPreference:reactivemongo.api.ReadPreference,batchSize:Option[Int])(f:GenericCollection.this.AggregationFramework=%3E(GenericCollection.this.PipelineOperator,List[GenericCollection.this.PipelineOperator]))(implicitec:scala.concurrent.ExecutionContext,implicitreader:GenericCollection.this.pack.Reader[T]):scala.concurrent.Future[reactivemongo.api.Cursor[T]]) can be processed in a streaming way, using the [cursor option](https://docs.mongodb.org/manual/reference/command/aggregate/).

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson._
import reactivemongo.api.Cursor
import reactivemongo.api.collections.bson.BSONCollection

def populatedStates(cities: BSONCollection)(implicit ec: ExecutionContext): Cursor[BSONDocument] = cities.aggregateWith[BSONDocument]() { framework =>
  import framework.{ Group, Match, SumField }

  Group(BSONString("$state"))("totalPop" -> SumField("population")) -> List(
    Match(document("totalPop" -> document("$gte" -> 10000000L)))
  )
}
{% endhighlight %}

#### Custom streaming

The new streaming support is based on the function [`Cursor.foldWhileM[A]`](../api/index.html#reactivemongo.api.Cursor@foldWhileM[A](z:=%3EA,maxDocs:Int)(suc:(A,T)=%3Escala.concurrent.Future[reactivemongo.api.Cursor.State[A]],err:reactivemongo.api.Cursor.ErrorHandler[A])(implicitctx:scala.concurrent.ExecutionContext):scala.concurrent.Future[A]) (and its variants), which allows to implement custom stream processing.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.Cursor

def streaming(c: Cursor[String]): Future[List[String]] =
  c.foldWhile(List.empty[String], 1000/* optional: max doc */)(
    { (ls, str) => // process next String value
      if (str startsWith "#") Cursor.Cont(ls) // Skip: continue unchanged `ls`
      else if (str == "_end") Cursor.Done(ls) // End processing
      else Cursor.Cont(str :: ls) // Continue with updated `ls`
    },
    { (ls, err) => // handle failure
      err match {
        case e: RuntimeException => Cursor.Cont(ls) // Skip error, continue
        case _ => Cursor.Fail(err) // Stop with current failure -> Future.failed
      }
    })
{% endhighlight %}

An [`ErrorHandler`](../api/index.html#reactivemongo.api.Cursor$@ErrorHandler[A]=%28A,Throwable%29=%3Ereactivemongo.api.Cursor.State[A]) can be used with the [`Cursor`](../api/index.html#reactivemongo.api.Cursor), instead of the previous `stopOnError` boolean flag.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.Cursor

def foldStrings(cursor: Cursor[String]): Future[Seq[String]] = {
  val handler: Cursor.ErrorHandler[Seq[String]] =
    { (last: Seq[String], error: Throwable) =>
      println(s"Encounter error: $error")

      if (last.isEmpty) { // continue, skip error if no previous value
        Cursor.Cont(last)
      } else Cursor.Fail(error)
    }

  cursor.foldWhile(Seq.empty[String])({ (agg, str) =>
    Cursor.Cont(agg :+ str)
  }, handler)
}
{% endhighlight %}

Some convenient error handlers are provided along with the driver:

- [`ContOnError`](../api/index.html#reactivemongo.api.Cursor$@ContOnError[A](callback:(A,Throwable)=%3EUnit):reactivemongo.api.Cursor.ErrorHandler[A]) (skip all errors),
- [`DoneOnError`](../api/index.html#reactivemongo.api.Cursor$@DoneOnError[A](callback:(A,Throwable)=%3EUnit):reactivemongo.api.Cursor.ErrorHandler[A]) (stop quietly on the first error),
- and [`FailOnError`](../api/index.html#reactivemongo.api.Cursor$@FailOnError[A](callback:(A,Throwable)=%3EUnit):reactivemongo.api.Cursor.ErrorHandler[A]) (fail on the first error).

### Aggregation

The [`distinct`](https://docs.mongodb.org/manual/reference/command/distinct/) command to find the distinct values for a specified field across a single collection, is now provided as a [collection operation](../api/index.html#reactivemongo.api.collections.GenericCollection@distinct[T]%28key:String,selector:Option[GenericCollection.this.pack.Document],readConcern:reactivemongo.api.ReadConcern%29%28implicitreader:GenericCollection.this.pack.NarrowValueReader[T],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[scala.collection.immutable.ListSet[T]]).

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

def distinctStates(col: BSONCollection)(implicit ec: ExecutionContext): Future[Set[String]] = col.distinct[String, Set]("state")
{% endhighlight %}

The ReactiveMongo collections now has the convenient operation [`.aggregate`](../api/index.html#reactivemongo.api.collections.GenericCollection@aggregate%28firstOperator:GenericCollection.this.PipelineOperator,otherOperators:List[GenericCollection.this.PipelineOperator],explain:Boolean,allowDiskUse:Boolean,cursor:Option[GenericCollection.this.BatchCommands.AggregationFramework.Cursor]%29%28implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[GenericCollection.this.BatchCommands.AggregationFramework.AggregationResult]).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.{ BSONDocument, BSONString }
import reactivemongo.api.collections.bson.BSONCollection

def populatedStates(col: BSONCollection): Future[List[BSONDocument]] = {
  import col.BatchCommands.AggregationFramework.{
    AggregationResult, Group, Match, SumField
  }

  val res: Future[AggregationResult] = col.aggregate(
    Group(BSONString("$state"))( "totalPop" -> SumField("population")),
    List(Match(BSONDocument("totalPop" -> BSONDocument("$gte" -> 10000000L)))))

  res.map(_.documents)
}
{% endhighlight %}

About the type `AggregationResult` the property [`documents`](../api/index.html#reactivemongo.api.commands.AggregationFramework$AggregationResult@documents:List[AggregationFramework.this.pack.Document]) has been renamed to `firstBatch`, to clearly indicate it returns the first batch from result (which is frequently the single one).

There are also some newly supported [Pipeline Aggregation Stages](https://docs.mongodb.org/manual/reference/operator/aggregation-pipeline/).

**filter:**

The [`$filter` stage](https://docs.mongodb.org/master/reference/operator/aggregation/filter/) is available in this new version.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.{ BSONString, Macros, array, document }
import reactivemongo.api.collections.bson.BSONCollection

object FilterUseCase {
  case class SaleItem(itemId: Int, quantity: Int, price: Int)
  case class Sale(_id: Int, items: List[SaleItem])

  implicit val saleItemHandler = Macros.handler[SaleItem]
  implicit val saleHandler = Macros.handler[Sale]

  def filterSales(sales: BSONCollection)(implicit ec: ExecutionContext): Future[List[Sale]] = {
    import sales.BatchCommands.AggregationFramework.{ Project, Filter }

    sales.aggregate(Project(document("items" -> Filter(
      input = BSONString("$items"),
      as = "item",
      cond = document("$gte" -> array("$$item.price", 100))
    )))).map(_.head[Sale])
  }
}
{% endhighlight %}

**geoNear:**

The [$geoNear](https://docs.mongodb.org/manual/reference/operator/aggregation/geoNear/#pipe._S_geoNear) stage returns an ordered stream of documents based on the proximity to a geospatial point.

It can be used in the MongoDB shell as follows.

{% highlight javascript %}
db.places.aggregate([{
  $geoNear: {
    near: { type: "Point", coordinates: [ -73.9667, 40.78 ] },
    distanceField: "dist.calculated",
    minDistance: 1000,
    maxDistance: 5000,
    query: { type: "public" },
    includeLocs: "dist.location",
    num: 5,
    spherical: true
  }
}])
{% endhighlight %}

The same can be done with ReactiveMongo.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.{ array, document, Macros }
import reactivemongo.api.collections.bson.BSONCollection

case class GeoPoint(coordinates: List[Double])
case class GeoDistance(calculated: Double, loc: GeoPoint)

case class GeoPlace(
  loc: GeoPoint,
  name: String,
  category: String,
  dist: GeoDistance
)

object GeoPlace {
  implicit val pointReader = Macros.reader[GeoPoint]
  implicit val distanceReader = Macros.reader[GeoDistance]
  implicit val placeReader = Macros.reader[GeoPlace]
}

def placeArround(places: BSONCollection)(implicit ec: ExecutionContext): Future[List[GeoPlace]] = {
  import places.BatchCommands.AggregationFramework.GeoNear

  places.aggregate(GeoNear(document(
    "type" -> "Point",
    "coordinates" -> array(-73.9667, 40.78)
  ), distanceField = Some("dist.calculated"),
    minDistance = Some(1000),
    maxDistance = Some(5000),
    query = Some(document("type" -> "public")),
    includeLocs = Some("dist.loc"),
    limit = 5,
    spherical = true)).map(_.head[GeoPlace])
}
{% endhighlight %}

**group:**

Now all the accumulators of the [`$group`](https://docs.mongodb.com/manual/reference/operator/aggregation/group/) aggregation stage are supported, for example the [`$avg` accumulator](https://docs.mongodb.com/manual/reference/operator/aggregation/avg/#grp._S_avg).

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.{ BSONDocument, BSONString }
import reactivemongo.api.collections.bson.BSONCollection

def avgPopByState(col: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import col.BatchCommands.AggregationFramework.{
    AggregationResult, AvgField, Group, SumField
  }

  col.aggregate(Group(BSONDocument("state" -> "$state", "city" -> "$city"))(
    "pop" -> SumField("population")),
    List(Group(BSONString("$_id.state"))("avgCityPop" -> AvgField("pop")))).
    map(_.documents)
}
{% endhighlight %}

**indexStats:**

The `$indexStats` stage returns statistics regarding the use of each index for the collection.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.collections.bson.BSONCollection

def aggregateIndexes(coll: BSONCollection) = {
  import coll.BatchCommands.AggregationFramework.{ Ascending, IndexStats, Sort }
  import reactivemongo.api.commands.{ bson => bsoncommands }
  import bsoncommands.BSONAggregationFramework.{
    IndexStatsResult, IndexStatAccesses
  }
  import bsoncommands.BSONAggregationResultImplicits.BSONIndexStatsReader

  val result: Future[List[IndexStatsResult]] =
    coll.aggregate(IndexStats, List(Sort(Ascending("name")))).
    map(_.head[IndexStatsResult])

  result
}
{% endhighlight %}

**lookup:**

Using the MongoDB aggregation, the [$lookup](https://docs.mongodb.com/v3.2/reference/operator/aggregation/lookup/#pipe._S_lookup) stage performs a left outer join between two collections in the same database (see the [examples](https://docs.mongodb.com/v3.2/reference/operator/aggregation/lookup/#examples)).
ReactiveMongo now supports this [new stage](../api/index.html#reactivemongo.api.commands.AggregationFramework@LookupextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.Macros
import reactivemongo.api.collections.bson.BSONCollection

object LookupUseCase {
  implicit def productHandler = Macros.handler[Product]
  implicit def invReportHandler = Macros.handler[InventoryReport]

  def lookupInventoryReports(orders: BSONCollection, inventory: BSONCollection): Future[List[InventoryReport]] = {
    import orders.BatchCommands.AggregationFramework.Lookup

    // Left outer join between the current `orders` collection,
    // and the inventory collection (referenced by its name)
    orders.aggregate(Lookup(inventory.name, "item", "sku", "docs")).
      map(_.head[InventoryReport].toList)
  }

  case class Product(
    _id: Int, sku: Option[String] = None,
    description: Option[String] = None,
    instock: Option[Int] = None
  )

  case class InventoryReport(
    _id: Int,
    item: Option[String] = None,
    price: Option[Int] = None,
    quantity: Option[Int] = None,
    docs: List[Product] = Nil
  )
}
{% endhighlight %}

**out:**

The [$out](https://docs.mongodb.org/manual/reference/operator/aggregation/out/#pipe._S_out) aggregation stage takes the documents returned by the aggregation pipeline and writes them to a specified collection.

Consider a collection *books* that contains the following documents.

{% highlight javascript %}
{ "_id" : 8751, "title" : "The Banquet", "author" : "Dante", "copies" : 2 }
{ "_id" : 8752, "title" : "Divine Comedy", "author" : "Dante", "copies" : 1 }
{ "_id" : 8645, "title" : "Eclogues", "author" : "Dante", "copies" : 2 }
{ "_id" : 7000, "title" : "The Odyssey", "author" : "Homer", "copies" : 10 }
{ "_id" : 7020, "title" : "Iliad", "author" : "Homer", "copies" : 10 }
{% endhighlight %}

Then its documents can be aggregated and outputted to another collection.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONString
import reactivemongo.api.collections.bson.BSONCollection

def outputBooks(books: BSONCollection, outColl: String): Future[Unit] = {
  import books.BatchCommands.AggregationFramework
  import AggregationFramework.{ Ascending, Group, PushField, Out, Sort }

  books.aggregate(Sort(Ascending("title")), List(
    Group(BSONString("$author"))("books" -> PushField("title")),
    Out(outColl))).map(_ => {})
}
{% endhighlight %}

For the current example, the result collection will contain the following documents.

{% highlight javascript %}
{ "_id" : "Homer", "books" : [ "Iliad", "The Odyssey" ] }
{ "_id" : "Dante", "books" : [ "Divine Comedy", "Eclogues", "The Banquet" ] }
{% endhighlight %}

**redact:**

The [$redact](https://docs.mongodb.org/manual/reference/operator/aggregation/redact/#pipe._S_redact) stage reshapes each document in the stream by restricting the content for each document based on information stored in the documents themselves.

It can be done in the MongoDB shell as follows.

{% highlight javascript %}
db.forecasts.aggregate([
  { $match: { year: 2014 } },
  { 
    $redact: {
      $cond: {
        if: { $gt: [ { $size: { 
          $setIntersection: [ "$tags", [ "STLW", "G" ] ] } }, 0 ]
        },
        then: "$$DESCEND",
        else: "$$PRUNE"
      }
    }
  }
])
{% endhighlight %}

With ReactiveMongo, the aggregation framework can perform a similar redaction.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson._
import reactivemongo.api.collections.bson.BSONCollection

def redactForecasts(forecasts: BSONCollection)(implicit ec: ExecutionContext) = {
  import forecasts.BatchCommands.AggregationFramework.{ Match, Redact }

  forecasts.aggregate(Match(document("year" -> 2014)), List(
    Redact(document("$cond" -> document(
      "if" -> document(
        "$gt" -> array(document(
          "$size" -> document("$setIntersection" -> array(
            "$tags", array("STLW", "G")
          ))
        ), 0)
      ),
      "then" -> "$$DESCEND",
      "else" -> "$$PRUNE"
    ))))).map(_.head[BSONDocument])
}
{% endhighlight %}

**sample:**

The [$sample](https://docs.mongodb.org/manual/reference/operator/aggregation/sample/) aggregation stage is also supported (only MongoDB >= 3.2). It randomly selects the specified number of documents from its input.
With ReactiveMongo, the [`Sample`](../api/index.html#reactivemongo.api.commands.AggregationFramework@SampleextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable) stage can be used as follows.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

def randomDocs(coll: BSONCollection, count: Int): Future[List[BSONDocument]] = {
  import coll.BatchCommands.AggregationFramework

  coll.aggregate(AggregationFramework.Sample(count)).map(_.head[BSONDocument])
}
{% endhighlight %}

**text:**

When the [`$text` operator](https://docs.mongodb.org/v3.0/reference/operator/query/text/#op._S_text) is used in an aggregation pipeline, then new the results can be [sorted](https://docs.mongodb.org/v3.0/reference/operator/aggregation/sort/#metadata-sort) according the [text scores](https://docs.mongodb.org/v3.0/reference/operator/query/text/#text-operator-text-score).

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

/**
 * 1. Find the documents matching the text `"JP"`,
 * 2. and sort according the (metadata) text score.
 */
def textFind(coll: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import coll.BatchCommands.AggregationFramework
  import AggregationFramework.{
    Cursor,
    Match,
    MetadataSort,
    Sort,
    TextScore
  }

  val firstOp = Match(BSONDocument(
    "$text" -> BSONDocument("$search" -> "JP")))

  val pipeline = List(Sort(MetadataSort("score", TextScore)))

  coll.aggregate1[BSONDocument](firstOp, pipeline).collect[List]()
}
{% endhighlight %}

> With the changes, the aggregation framework provides an API for all the stages supported by MongoDB 3.2.

[More: **Aggregation Framework**](./advanced-topics/aggregation.html)

### Play Framework

The [integration with Play Framework](./tutorial/play.html) is still a priority for ReactiveMongo.

For Play > 2.4, if you still have a file `conf/play.plugins`, it's important to make sure this file no longer mentions `ReactiveMongoPlugin`, which is replaced by `ReactiveMongoModule`. With such deprecated configuration, the following error can be raised.

    ConfigurationException: Guice configuration errors: 
    1) Could not find a suitable constructor in 
    play.modules.reactivemongo.ReactiveMongoPlugin.

Considering the configuration with Play, the new setting `mongodb.connection.strictUri` (`true` or `false`) can be added. It makes the ReactiveMongo module for Play will enforce that only strict connection URI is accepted: with no unsupported option in it (otherwise it throws an exception). By default this setting is disabled (`false`).

As for Play 2.5, due to the [Streams Migration](https://playframework.com/documentation/2.5.x/StreamsMigration25), a `akka.stream.Materializer` is required when implementing Play/ReactiveMongo controllers, otherwise the following error will be raised.

    could not find implicit value for parameter materializer: akka.Stream.Materializer

It's also important to note that the Play support has also been modularized.

#### JSON serialization

There is now a standalone [Play JSON library](./json/overview.html), providing a serialization pack that can be used outside a Play application.

This new library increases the JSON support to handle the following BSON types.

- [BSONJavaScript](../api/reactivemongo/bson/BSONJavaScript.html)
- [BSONUndefined](../api/reactivemongo/bson/BSONUndefined$.html)

To use this JSON library, it's necessary to make sure the right imports are there.

{% highlight scala %}
import reactivemongo.play.json._
// import the default BSON/JSON conversions
{% endhighlight %}

Without these imports, the following error can occur.

{% highlight text %}
No Json serializer as JsObject found for type play.api.libs.json.JsObject.
Try to implement an implicit OWrites or OFormat for this type.
{% endhighlight %}

There are also some helpers coming along with this JSON pack.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.play.json.collection._

// Import a list of JSON object as document into the JSON `collection`,
// and returns the insertion count.
def importJson(collection: JSONCollection, resource: String): Future[Int] =
  Helpers.bulkInsert(collection, getClass.getResourceAsStream(resource)).
    map(_.totalN)
{% endhighlight %}

In order to comply with the [extended JSON syntax for the timestamps](https://docs.mongodb.com/manual/reference/mongodb-extended-json/#data_timestamp), [`BSONTimestamp`](../api/index.html#reactivemongo.bson.BSONTimestamp) values are written with both `$time` and `$timestamp` formats.

{% highlight javascript %}
{
  "$time": <t>, "$i": <i>,
  "$timestamp": { "t": <t>, "i": <i> }
}
{% endhighlight %}

> The deprecated properties `$time` and `$i` will be removed.

These two formats are also supported when reading from JSON.

The extended syntax is also supported for the [`BSONMinKey`](../api/index.html#reactivemongo.bson.BSONMinKey$) and the [`BSONMaxKey`](../api/index.html#reactivemongo.bson.BSONMaxKey$).

{% highlight javascript %}
{
  "aMinKey": { "$minKey": 1 },
  "aMaxKey" : { "$maxKey": 1 }
}
{% endhighlight %}

New functions from the `BSONFormats` provides JSON formats derived from BSON handlers.

- The [`jsonOFormat`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_2.11/{{page.major_version}}/reactivemongo-play-json_2.11-{{page.major_version}}-javadoc.jar/!/index.html#reactivemongo.play.json.BSONFormats$@jsonOFormat[T](implicitevidence$1:reactivemongo.bson.BSONDocumentWriter[T],implicitevidence$2:reactivemongo.bson.BSONDocumentReader[T]):play.api.libs.json.OFormat[T]) derives a [`BSONHandler`](../api/index.html#reactivemongo.bson.BSONHandler) as a Play [`OFormat`](https://www.playframework.com/documentation/2.4.0/api/scala/index.html#play.api.libs.json.OFormat), to map JSON objects and BSON documents.
- The similar [`jsonFormat`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_2.11/{{page.major_version}}/reactivemongo-play-json_2.11-{{page.major_version}}-javadoc.jar/!/index.html#reactivemongo.play.json.BSONFormats$@jsonFormat[T](implicith:reactivemongo.bson.BSONHandler[_%3C:reactivemongo.bson.BSONValue,T]):play.api.libs.json.Format[T]) derives a `BSONWriter` and its corresponding `BSONReader` to provide a Play `Format`.
- The write-only `jsonOWrites` and `jsonWrites`, and also the read-only `jsonReads`.

{% highlight scala %}
import play.api.libs.json.OFormat
import reactivemongo.bson._
import reactivemongo.play.json.BSONFormats

def derivesBsonHandlers[T](
  implicit bsonWriter: BSONDocumentWriter[T],
  bsonReader: BSONDocumentReader[T]
): OFormat[T] = BSONFormats.jsonOFormat[T]
{% endhighlight %}

[More: **JSON overview**](json/overview.html)

#### Dependency injection

Now multiple connection pools can be injected using the `@NamedDatabase` annotation.

For example with the following configuration:

{% highlight text %}
# The default URI
mongodb.uri = "mongodb://someuser:somepasswd@localhost:27017/foo"

# Another one, named with 'bar'
mongodb.bar.uri = "mongodb://someuser:somepasswd@localhost:27017/lorem"
{% endhighlight %}

Then the dependency injection can select the API instances using the names.

{% highlight scala %}
import javax.inject.Inject

import play.modules.reactivemongo._

class MyComponent @Inject() (
  val defaultApi: ReactiveMongoApi, // corresponds to 'mongodb.uri'
  @NamedDatabase("bar") val barApi: ReactiveMongoApi // 'mongodb.bar'
) {

}
{% endhighlight %}

#### MVC integration

Instances of [Play Formatter](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.data.format.Formatter) are provided for the [BSON values](./bson/overview.html).

{% highlight scala %}
import play.api.data.format.Formatter
import play.api.libs.json.Json

import reactivemongo.bson.BSONValue

import reactivemongo.play.json._
import play.modules.reactivemongo.Formatters._

def playFormat[T <: BSONValue](bson: T)(implicit formatter: Formatter[T]) = {
  val binding = Map("foo" -> Json.stringify(Json.toJson(bson)))

  formatter.bind("foo", binding)
  // must be Right(bson)

  formatter.unbind("foo", bson)
  // must == binding
}
{% endhighlight %}

#### Routing

The [BSON types](bson/overview.html) can be used in the bindings of the Play routing.

For example, consider a Play action as follows.

{% highlight scala %}
package mine

import play.api.mvc.{ Action, Controller }
import reactivemongo.bson.BSONObjectID

class Application extends Controller {
  def foo(id: BSONObjectID) = Action {
    Ok(s"Foo: ${id.stringify}")
  }
}
{% endhighlight %}

This action can be configured with a [`BSONObjectID`](../api/reactivemongo/bson/BSONObjectID.html) binding, in the `conf/routes` file.

    GET /foo/:id mine.Application.foo(id: reactivemongo.bson.BSONObjectID)

When using BSON types in the route bindings, the Play plugin for SBT must be setup (in your `build.sbt` or `project/Build.scala`) to install the appropriate import in the generated routes.

{% highlight ocaml %}
import play.sbt.routes.RoutesKeys

RoutesKeys.routesImport += "play.modules.reactivemongo.PathBindables._"
{% endhighlight %}

#### Play Iteratees

The [`enumerate`](../api/index.html#reactivemongo.api.Cursor@enumerate(maxDocs:Int,stopOnError:Boolean)(implicitctx:scala.concurrent.ExecutionContext):play.api.libs.iteratee.Enumerator[T]) on the cursors is now deprecated, and the [Play Iteratees](https://www.playframework.com/documentation/latest/Iteratees) support has been moved to a separate module, with a new [`enumerator`](../api/index.html#reactivemongo.play.iteratees.PlayIterateesCursor@enumerator(maxDocs:Int,err:reactivemongo.api.Cursor.ErrorHandler[Unit])(implicitctx:scala.concurrent.ExecutionContext):play.api.libs.iteratee.Enumerator[T]) operation.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import play.api.libs.iteratee.{ Enumerator, Iteratee }

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

def workWithIteratees(personColl: BSONCollection): Future[Int] = {
  import reactivemongo.play.iteratees.cursorProducer
  // Provides the cursor producer with the Iteratees capabilities

  val cur = personColl.find(BSONDocument("plop" -> "plop")).
    cursor[BSONDocument]() // can be seen as PlayIterateesCursor ...

  // ... so the new `enumerator` operation is available
  val source: Enumerator[BSONDocument] = cur.enumerator(10)

  source |>>> Iteratee.fold(0) { (r, doc) => r + 1 }
}
{% endhighlight %}

To use the Iteratees support for the ReactiveMongo cursors, [`reactivemongo.play.iteratees.cursorProducer`](../api/index.html#reactivemongo.play.iteratees.package@cursorProducer[T]:reactivemongo.api.CursorProducer[T]{typeProducedCursor=reactivemongo.play.iteratees.PlayIterateesCursor[T]}) must be imported.

{% highlight scala %}
import reactivemongo.play.iteratees.cursorProducer
// Provides the cursor producer with the Iteratees capabilities
{% endhighlight %}

Without this import, the following error can occur.

{% highlight text %}
value enumerator is not a member of reactivemongo.api.CursorProducer[reactivemongo.bson.BSONDocument]#ProducedCursor
{% endhighlight %}

### Administration

The operations to manage a MongoDB instance can be executed using ReactiveMongo. This new release has new functions for DB administration.

**Rename collection:**

The `Database` now has a [`renameCollection`](../api/index.html#reactivemongo.api.DefaultDB@renameCollection[C%3C:reactivemongo.api.Collection](db:String,from:String,to:String,dropExisting:Boolean,failoverStrategy:reactivemongo.api.FailoverStrategy)(implicitec:scala.concurrent.ExecutionContext,implicitproducer:reactivemongo.api.CollectionProducer[C]):scala.concurrent.Future[C]) operation, which can be easily used with the 'admin' database, to rename collections in the other databases.

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global
import reactivemongo.api.DefaultDB

def renameWithSuffix(
  admin: DefaultDB,
  otherDb: String,
  collName: String,
  suffix: String
) = admin.renameCollection(otherDb, collName, s"$collName-$suffix")
{% endhighlight %}

**Drop collection:**

The new [`drop`](../api/index.html#reactivemongo.api.collections.GenericCollection@drop%28failIfNotFound:Boolean%29%28implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[Boolean]) operation can try to perform, without failing if the collection doesn't exist. The previous behaviour is still available.

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

**Create user:**

The [`DefaultDB`](../api/index.html#reactivemongo.api.DefaultDB) is defined with a function to create a database user.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.DefaultDB
import reactivemongo.api.commands.UserRole

// Creates a 'foo' user, with the 'readWrite' role
def createFooUser(db: DefaultDB, password: String): Future[Unit] =
  db.createUser("foo", Some(password), roles = List(UserRole("readWrite")))
{% endhighlight %}

**Indexes:**

In the case class [`Index`](../api/index.html#reactivemongo.api.indexes.Index), the property `partialFilter` has been added to support MongoDB index with [`partialFilterExpression`](https://docs.mongodb.com/manual/core/index-partial/#partial-index-with-unique-constraints).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection
import reactivemongo.api.commands.WriteResult
import reactivemongo.api.indexes.{ Index, IndexType }

def createPartialIndex(col: BSONCollection): Future[WriteResult] = 
  col.indexesManager.create(Index(
    key = Seq("username" -> IndexType.Ascending),
    unique = true,
    partialFilter = Some(BSONDocument("age" -> BSONDocument("$gte" -> 21)))))
{% endhighlight %}

**Collection statistics:**

In the case class [`CollStatsResult`](../api/index.html#reactivemongo.api.commands.CollStatsResult), the field `maxSize` has been added.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.api.collections.bson.BSONCollection
import reactivemongo.api.commands.CollStatsResult

def maxSize(coll: BSONCollection)(implicit ec: ExecutionContext): Future[Option[Double]] = coll.stats.map(_.maxSize)
{% endhighlight %}

**Resync replica set members:**

The replication command [`resync`](https://docs.mongodb.org/manual/reference/command/resync/) is now provided.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.api.MongoConnection
import reactivemongo.api.commands.{ Resync, bson }, bson.BSONResyncImplicits._

def resyncDatabase(con: MongoConnection)(implicit ec: ExecutionContext): Future[Unit] = con.database("admin").flatMap(_.runCommand(Resync)).map(_ => {})
{% endhighlight %}

### Logging

Log4J is still required for backward compatibility (by deprecated code), but is replaced by [SLF4J](http://www.slf4j.org/) for the [ReactiveMongo logging](./index.html#logging).

If you see the following message, please make sure you have a Log4J framework available.

    ERROR StatusLogger No log4j2 configuration file found. Using default configuration: logging only errors to the console.

As SLF4J is now used, if the following error is raised, please make sure to provide a [SLF4J binding](http://www.slf4j.org/manual.html#swapping) (e.g. slf4j-simple).

    NoClassDefFoundError: : org/slf4j/LoggerFactory

In order to debug the networking issues, the internal state of the node set is provided as details of the related exceptions, as bellow.

{% highlight text %}{% raw %}
reactivemongo.core.actors.Exceptions$InternalState: null (<time:1469208071685>:-1)
reactivemongo.ChannelClosed(-2079537712, {{NodeSet None Node[localhost:27017: Primary (0/0 available connections), latency=5], auth=Set() }})(<time:1469208071685>)
reactivemongo.Shutdown(<time:1469208071673>)
reactivemongo.ChannelDisconnected(-2079537712, {{NodeSet None Node[localhost:27017: Primary (1/1 available connections), latency=5], auth=Set() }})(<time:1469208071663>)
reactivemongo.ChannelClosed(967102512, {{NodeSet None Node[localhost:27017: Primary (1/2 available connections), latency=5], auth=Set() }})(<time:1469208071663>)
reactivemongo.ChannelDisconnected(967102512, {{NodeSet None Node[localhost:27017: Primary (2/2 available connections), latency=5], auth=Set() }})(<time:1469208071663>)
reactivemongo.ChannelClosed(651496230, {{NodeSet None Node[localhost:27017: Primary (2/3 available connections), latency=5], auth=Set() }})(<time:1469208071663>)
reactivemongo.ChannelDisconnected(651496230, {{NodeSet None Node[localhost:27017: Primary (3/3 available connections), latency=5], auth=Set() }})(<time:1469208071663>)
reactivemongo.ChannelClosed(1503989210, {{NodeSet None Node[localhost:27017: Primary (3/4 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelDisconnected(1503989210, {{NodeSet None Node[localhost:27017: Primary (4/4 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelClosed(-228911231, {{NodeSet None Node[localhost:27017: Primary (4/5 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelDisconnected(-228911231, {{NodeSet None Node[localhost:27017: Primary (5/5 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelClosed(-562085577, {{NodeSet None Node[localhost:27017: Primary (5/6 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelDisconnected(-562085577, {{NodeSet None Node[localhost:27017: Primary (6/6 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelClosed(-857553810, {{NodeSet None Node[localhost:27017: Primary (6/7 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
{% endraw %}{% endhighlight %}

### Monitoring

A new [JMX](https://en.wikipedia.org/wiki/Java_Management_Extensions) module is available. It can be enabled by adding the corresponding dependency:

{% highlight ocaml %}
"org.reactivemongo" %% "reactivemongo-jmx" % "{{site._0_12_latest_minor}}"
{% endhighlight %}

[More: **Monitoring**](advanced-topics/monitoring.html)

### Dependencies

The internal [Netty](http://netty.io/) dependency has been updated to the version 3.10.4, and is now [shaded](http://forgegradle.readthedocs.io/en/latest/user-guide/shading/) to avoid conflict ([dependency hell](https://en.wikipedia.org/wiki/Dependency_hell)).

[![Test coverage](https://img.shields.io/badge/coverage-60%25-yellowgreen.svg)](https://reactivemongo.github.io/ReactiveMongo/coverage/{{site._0_12_latest_minor}}/)

### Breaking changes

The [Typesafe Migration Manager](https://github.com/typesafehub/migration-manager#migration-manager-for-scala) has been setup on the ReactiveMongo repository.
It will validate all the future contributions, and help to make the API more stable.

For the current 0.12 release, it has detected the following breaking changes.

**Connection**

- In the case class [`MongoConnectionOptions`](../api/index.html#reactivemongo.api.MongoConnectionOptions), the constructor has 2 extra properties [`writeConcern`](../api/index.html#reactivemongo.api.commands.package@WriteConcern=reactivemongo.api.commands.GetLastError) and [`readPreference`](../api/index.html#reactivemongo.api.ReadPreference).
- In the class [`MongoConnection`](../api/index.html#reactivemongo.api.MongoConnection);
  * method `ask(reactivemongo.core.protocol.CheckedWriteRequest)` is removed
  * method `ask(reactivemongo.core.protocol.RequestMaker,Boolean)` is removed
  * method `waitForPrimary(scala.concurrent.duration.FiniteDuration)` is removed

Since [release 0.11](../../0.11/documentation/release-details.html), the package [`reactivemongo.api.collections.default`](../../0.10/api/index.html#reactivemongo.api.collections.default.package) has been refactored as the package [`reactivemongo.api.collections.bson`](http://reactivemongo.org/releases/0.11/api/index.html#reactivemongo.api.collections.bson.package).
If you get a compilation error like the following one, you need to update the corresponding imports.

{% highlight text %}
object default is not a member of package reactivemongo.api.collections
[error] import reactivemongo.api.collections.default.BSONCollection
{% endhighlight %}

**Operation results**

The type hierarchy of the trait [`WriteResult`](../api/index.html#reactivemongo.api.commands.WriteResult) has changed in new version. It's no longer an `Exception`, and no longer inherits from [`reactivemongo.core.errors.DatabaseException`](../api/index.html#reactivemongo.core.errors.DatabaseException), `scala.util.control.NoStackTrace`, `reactivemongo.core.errors.ReactiveMongoException`.
As it now longer represents errors in the public API, the following properties have been removed: `errmsg`, `hasErrors`, `inError` and `message`.

For the type [`LastError`](../api/index.html#reactivemongo.api.commands.LastError), the properties `writeErrors` and `writeConcernError` have been added.

The type hierarchy of the classes [`DefaultWriteResult`](../api/index.html#reactivemongo.api.commands.DefaultWriteResult) and [`UpdateWriteResult`](../api/index.html#reactivemongo.api.commands.UpdateWriteResult) have changed in new version; no longer inherits from `java.lang.Exception`:

- method `fillInStackTrace()` is removed
- method `isUnauthorized()` is removed
- method `getMessage()` is removed
- method `isNotAPrimaryError()` is removed

In the class [`Upserted`](../api/index.html#reactivemongo.api.commands.Upserted);

- The constructor has changed; was `(Int, java.lang.Object)`, is now: `(Int, reactivemongo.bson.BSONValue)`.
- The field `_id`  has now a different result type; was: `java.lang.Object`, is now: `reactivemongo.bson.BSONValue`.

In the case class [`GetLastError.TagSet`](../api/index.html#reactivemongo.api.commands.GetLastError$$TagSet), the field `s`  is renamed to `tag`.

The exception case objects [`NodeSetNotReachable`](../api/index.html#reactivemongo.core.actors.Exceptions$@NodeSetNotReachable), [`NodeSetNotReachable`](../api/index.html#reactivemongo.core.actors.Exceptions$@PrimaryUnavailableExceptionextendsExceptionwithDriverExceptionwithNoStackTrace), [`ChannelNotFound`](../api/index.html#reactivemongo.core.actors.Exceptions$@ChannelNotFoundextendsExceptionwithDriverExceptionwithNoStackTrace) and [`ClosedException`](../api/index.html#reactivemongo.core.actors.Exceptions$@ClosedException) have been refactored as sealed classes. When try to catch such exception the class type must be used, rather than the object patterns.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.core.actors.Exceptions.{
  ClosedException, NodeSetNotReachable
}

def handle(mongoOp: Future[String])(implicit ec: ExecutionContext) =
  mongoOp.recover {
    case err1: ClosedException => // rather than `case ClosedException`
      "closed"
  
    case err2: NodeSetNotReachable => // rather than `case NodeSetNotReachable`
      "notReachable"
  }
{% endhighlight %}

**Aggregation framework**

- In the trait [`AggregationFramework`](../api/index.html#reactivemongo.api.commands.AggregationFramework);
  * the type `PipelineStage` is removed
  * the type `DocumentStage` is removed
  * the type `DocumentStageCompanion` is removed
  * the type `PipelineStageDocumentProducer` is removed
  * the type `AggregateCursorOptions` is removed
  * the field `name` is removed from all the pipeline stages
- In the case class [`AggregationFramework.Aggregate`](../api/index.html#reactivemongo.api.commands.AggregationFramework$Aggregate);
  * field `needsCursor` is removed
  * field `cursorOptions` is removed
- In case classes [`AggregationFramework.Limit`](../api/index.html#reactivemongo.api.commands.AggregationFramework@LimitextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable) and [`reactivemongo.api.commands.AggregationFramework.Skip`](../api/index.html#reactivemongo.api.commands.AggregationFramework@SkipextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable);
  * field `n` is removed
- In the case class [`reactivemongo.api.commands.AggregationFramework#Unwind`](../api/index.html#reactivemongo.api.commands.AggregationFramework$Unwind), the field `prefixedField` is removed.

**Operations and commands**

- The enumerated type `reactivemongo.api.SortOrder` is removed, as not used in the API.
- The trait `reactivemongo.api.commands.CursorCommand` is removed
- In the case class [`FindAndModify`](../api/index.html#reactivemongo.api.commands.FindAndModifyCommand$Update);
  * the field `upsert` (and the corresponding constructor parameter) has been added
  * the type of the field `update` is now `Document`; was `java.lang.Object`.

**GridFS**

- In the trait [`ComputedMetadata`](../api/index.html#reactivemongo.api.gridfs.ComputedMetadata), the field `length` has now a different result type; was: `Int`, is now: `Long`
- In the case class [`DefaultFileToSave`](../api/index.html#reactivemongo.api.gridfs.DefaultFileToSave) has changed to a plain class, and its method `filename()`  has now a different result type; was: `String`, is now: `Option[String]`.
- In class [`DefaultReadFile`](../api/index.html#reactivemongo.api.gridfs.DefaultReadFile);
  * field `length` in  has now a different result type; was: `Int`, is now: `Long`;
  * field `filename` has now a different result type; was: `String`, is now: `Option[String]`.
- In the trait [`BasicMetadata`](../api/index.html#reactivemongo.api.gridfs.BasicMetadata), the field `filename` has now a different result type; was: `String`, is now: `Option[String]`.

**Core/internal**

- The class [`Authenticate`](../api/index.html#reactivemongo.core.commands.Authenticate) is now deprecated;
  * The type hierarchy of has changed in new version. No longer inherits from `reactivemongo.core.commands.BSONCommandResultMaker` and `reactivemongo.core.commands.CommandResultMaker`.
  * method `apply(reactivemongo.bson.BSONDocument)` is removed
  * method `apply(reactivemongo.core.protocol.Response)` is removed
  * see [`CrAuthenticate`](../api/index.html#reactivemongo.core.commands.CrAuthenticate) (only for the legacy MongoDB CR authentication)
- The class [`MongoDBSystem`](../api/index.html#reactivemongo.core.actors.MongoDBSystem) has changed to a trait.
- The declaration of class [`Authenticating`](../api/index.html#reactivemongo.core.nodeset.Authenticating) has changed to a sealed trait.
