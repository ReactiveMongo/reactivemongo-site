---
layout: default
major_version: 0.1x
title: Find Documents
---

## Find documents

> Note: the following snippets of code use a [`BSONCollection`](../../api/reactivemongo/api/collections/bson/BSONCollection.html) (the default collection implementation return by `db.collection()`).

### Perform a simple query

Queries are performed in quite the same way as in the MongoDB Shell.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def findOlder1(collection: BSONCollection): Future[Option[BSONDocument]] = {
  // { "age": { "$gt": 27 } }
  val query = BSONDocument("age" -> BSONDocument("$gt" -> 27))

  // MongoDB .findOne
  collection.find(query).one[BSONDocument]
}
{% endhighlight %}

Of course you can collect only a limited number of documents.

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def findOlder2(collection: BSONCollection) = {
  val query = BSONDocument("age" -> BSONDocument("$gt" -> 27))

  // only fetch the name field for the result documents
  val projection = BSONDocument("name" -> 1)

  collection.find(query, projection).cursor[BSONDocument]().
    collect[List](25, // get up to 25 documents
      Cursor.FailOnError[List[BSONDocument]]())
}
{% endhighlight %}

> When using a serialization pack other than the BSON default one, then the appropriate document type must be used to define query (e.g. [`JsObject`](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsObject) for the [JSON serialization](../json/overview.html)).

The `find` method returns a query builder (e.g. a [`BSONQueryBuilder`](../../api/reactivemongo/api/collections/GenericQueryBuilder.default.BSONQueryBuilder)), which means the query is therefore not performed yet.
It gives you the opportunity to add options to the query, like a sort order, projection, flags...

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.{ Cursor, QueryOpts }
import reactivemongo.api.bson.collection.BSONCollection

def findNOlder(collection: BSONCollection, limit: Int) = {
  val querybuilder =
    collection.find(BSONDocument("age" -> BSONDocument("$gt" -> 27)))

  // Sets options before executing the query
  querybuilder.options(QueryOpts().batchSize(limit)).
    cursor[BSONDocument]().collect[List](10, // get up to 10 documents
      Cursor.FailOnError[List[BSONDocument]]())
 
}
{% endhighlight %}

The class [`QueryOpts`](../../api/reactivemongo/api/QueryOpts) is used to prepared the query options.

When your query is ready to be sent to MongoDB, you may just call one of the following function.

- The function [`cursor`](../../api/reactivemongo/api/collections/GenericQueryBuilder.GenericQueryBuilder#cursor[T](readPreference:reactivemongo.api.ReadPreference,isMongo26WriteOp:Boolean)(implicitreader:GenericQueryBuilder.this.pack.Reader[T],implicitec:scala.concurrent.ExecutionContext,implicitcp:reactivemongo.api.CursorProducer[T]):cp.ProducedCursor) which returns a [`Cursor[BSONDocument]`](../../api/reactivemongo/api/Cursor).
- The function [`one`](../../api/reactivemongo/api/collections/GenericQueryBuilder.GenericQueryBuilder#one[T](readPreference:reactivemongo.api.ReadPreference)(implicitreader:GenericQueryBuilder.this.pack.Reader[T],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Option[T]]) which returns a `Future[Option[T]]` (the first document that matches the query, if any).
- The function [`requireOne`](../../api/reactivemongo/api/collections/GenericQueryBuilder.GenericQueryBuilder#requireOne[T](readPreference:reactivemongo.api.ReadPreference)(implicitreader:GenericQueryBuilder.this.pack.Reader[T],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[T]) which returns a `Future[T]` with the first matching document, or fails if none.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

trait PersonService1 {
  def collection: BSONCollection

  def requirePerson(firstName: String, lastName: String)(implicit ec: ExecutionContext): Future[Person] = collection.find(BSONDocument(
    "firstName" -> firstName,
    "lastName" -> lastName
  )).requireOne[Person]
}
{% endhighlight %}

On a cursor, the [`collect`](../../api/reactivemongo/api/Cursor#collect[M[_]](maxDocs:Int,stopOnError:Boolean)(implicitcbf:scala.collection.generic.CanBuildFrom[M[_],T,M[T]],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[M[T]]) function can be used.
It must be given a Scala collection type, like [`List`](http://www.scala-lang.org/api/current/index.html#scala.collection.immutable.List) or [`Vector`](http://www.scala-lang.org/api/current/index.html#scala.collection.immutable.Vector). It accumulates all the results in memory.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

trait PersonService2 {
  def collection: BSONCollection

  def persons(age: Int)(implicit ec: ExecutionContext): Future[List[Person]] =
    collection.find(BSONDocument("age" -> age)).cursor[Person]().
    collect[List](-1, Cursor.FailOnError[List[Person]]())
}
{% endhighlight %}

[More: **Streaming**](./streaming.html)

### Find and sort documents

The return type of the `find` method is a `GenericQueryBuilder`, which enables to customize the query, especially to add sort information. Like in the MongoDB console, you sort by giving a document containing the field names associated with an order (1 for ascending, -1 descending). Let's sort our previous query by last name, in the alphabetical order (the sort document is also `{ lastName: 1 }`).

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global
import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def findOlder3(collection: BSONCollection) = {
  val query = BSONDocument("age" -> BSONDocument("$gt" -> 27))

  collection.find(query).
    sort(BSONDocument("lastName" -> 1)). // sort by lastName
    cursor[BSONDocument]().
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())
}
{% endhighlight %}

See: [**Query builder**](../../api/reactivemongo/api/collections/GenericQueryBuilder.html)

### Use Readers to deserialize documents automatically

[As explained here](), you can use the `BSONDocumentReader` and `BSONDocumentWriter` typeclasses to handle de/serialization between `BSONDocument` and your model classes.

<!-- TODO: id=java.util.UUID -->
{% highlight scala %}
import reactivemongo.api.bson._

case class Person(
  id: String,
  firstName: String,
  lastName: String,
  age: Int)

object Person {
  implicit object PersonReader extends BSONDocumentReader[Person] {
    def readDocument(doc: BSONDocument) = for {
      id <- doc.getAsTry[BSONObjectID]("_id").map(_.stringify)
      firstName <- doc.getAsTry[String]("firstName")
      lastName <- doc.getAsTry[String]("lastName")
      age <- doc.getAsTry[Int]("age")
    } yield Person(id, firstName, lastName, age)
  }
}
{% endhighlight %}

This system is fully supported in the Collection API, so you can get the results of your queries in the right type.

> Any error raised by the `read` function will be caught by ReactiveMongo deserialization, and will result in an explicit `Future` failure.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.{ BSONDocument, BSONDocumentReader }

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def findOlder4(collection: BSONCollection)(implicit ec: ExecutionContext, reader: BSONDocumentReader[Person]): Future[List[Person]] = {
  val query = BSONDocument("age" -> BSONDocument("$gt" -> 27))

  val peopleOlderThanTwentySeven = collection.find(query).
    /*
     * Indicate that the documents should be transformed into `Person`.
     * A `BSONDocumentReader[Person]` should be in the implicit scope.
     */
    cursor[Person](). // ... collect in a `List`
    collect[List](-1, Cursor.FailOnError[List[Person]]())

  peopleOlderThanTwentySeven.map { people =>
    for (person <- people) println(s"found $person")
  }

  peopleOlderThanTwentySeven
}
{% endhighlight %}

> ReactiveMongo can directly return instances of a custom class, by defining a [custom reader](../bson/typeclasses.html#custom-reader).

### Troubleshooting

The synchronous [`.db` has been deprecated](../release-details.html#database-resolution) as it didn't offer a sufficient guaranty that it can initially find an active channel in the connection pool (`MongoConnection`). A corresponding warning is raised by the compiler in such case.

{% highlight text %}
method db in class MongoConnection is deprecated: Must use [[database]]
{% endhighlight %}

The new [`.database` resolution](../../api/reactivemongo/api/MongoConnection#database%28name:String,failoverStrategy:reactivemongo.api.FailoverStrategy%29%28implicitcontext:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[reactivemongo.api.DefaultDB]) must be used (see [connection tutorial](./connect-database.html)).

If the deprecated database resolution is still used, a runtime error such as `ConnectionNotInitialized` can be raised when querying documents.

On query builder, the [previous `cursor`](../../api/reactivemongo/api/collections/GenericQueryBuilder.GenericQueryBuilder#cursor[T](implicitreader:GenericQueryBuilder.this.pack.Reader[T],implicitec:scala.concurrent.ExecutionContext,implicitcp:reactivemongo.api.CursorProducer[T]):cp.ProducedCursor) has been deprecated:

{% highlight text %}
Use `cursor()` or `cursor(readPreference)`
{% endhighlight %}

As indicated by this compilation warning, the [new `cursor`](../../api/reactivemongo/api/collections/GenericQueryBuilder.GenericQueryBuilder#cursor[T](readPreference:reactivemongo.api.ReadPreference,isMongo26WriteOp:Boolean)(implicitreader:GenericQueryBuilder.this.pack.Reader[T],implicitec:scala.concurrent.ExecutionContext,implicitcp:reactivemongo.api.CursorProducer[T]):cp.ProducedCursor) is expecting a [`ReadPreference`](../../api/reactivemongo/api/ReadPreference) as parameter.

When a `Cursor` has been obtained, a warning can be raised if using the [deprecated `collect`](../../api/reactivemongo/api/Cursor#collect[M[_]](maxDocs:Int,stopOnError:Boolean)(implicitcbf:scala.collection.generic.CanBuildFrom[M[_],T,M[T]],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[M[T]]) function:

{% highlight text %}
method collect in trait Cursor is deprecated: Use `collect` with an [[Cursor.ErrorHandler]].
{% endhighlight %}

The [new `collect`](../../api/reactivemongo/api/Cursor#collect[M[_]](maxDocs:Int,err:reactivemongo.api.Cursor.ErrorHandler[M[T]])(implicitcbf:scala.collection.generic.CanBuildFrom[M[_],T,M[T]],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[M[T]]) function must be used instead.

Due to the refactoring of the BSON API, the following warnings can be raised.

{% highlight text %}
Use reactivemongo-bson-api or use reactivemongo-bson-compat: import reactivemongo.api.bson.compat._

- OR -

Use reactivemongo-bson-api
{% endhighlight %}

In this case either update the code to the [new BSON API](./bison.html), or use the compatibility library to ease the migration.

{% highlight scala %}
import reactivemongo.api.bson.compat._
{% endhighlight %}

[Previous: Write Documents](./write-documents.html) / [Next: Streaming](./streaming.html)
