---
layout: default
title: ReactiveMongo 0.12 - Write Documents
---

## Write Documents

MongoDB offers different kinds of write operations: insertion, update or removal. Using ReactiveMongo Data, this can be performed asynchronously.

### Insert a document

Insertions are done with the [`insert`](../../api/index.html#reactivemongo.api.collections.GenericCollection@insert[T]%28document:T,writeConcern:reactivemongo.api.commands.WriteConcern%29%28implicitwriter:GenericCollection.this.pack.Writer[T],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[reactivemongo.api.commands.WriteResult]) function.

{% highlight scala %}
import scala.util.{ Failure, Success }

import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.commands.WriteResult
import reactivemongo.api.collections.bson.BSONCollection

val document1 = BSONDocument(
  "firstName" -> "Stephane",
  "lastName" -> "Godbillon",
  "age" -> 29)

def insertDoc1(coll: BSONCollection, doc: BSONDocument): Future[Unit] = {
  val writeRes: Future[WriteResult] = coll.insert(document1)

  writeRes.onComplete { // Dummy callbacks
    case Failure(e) => e.printStackTrace()
    case Success(writeResult) =>
      println(s"successfully inserted document with result: $writeResult")
  }

  writeRes.map(_ => {}) // in this example, do nothing with the success
}
{% endhighlight %}

> The type `Future[LastError]` previously returned by the write operations is replaced by `Future[WriteResult]` in the new API.

**What does WriteResult mean?**

A [`WriteResult`](../../api/index.html#reactivemongo.api.commands.WriteResult) is a special document that contains information about the write operation, like the number of documents that were updated.

If the write result actually indicates an error, the `Future` will be in a [`failed` state](http://www.scala-lang.org/api/current/index.html#scala.concurrent.Future$@failed[T](exception:Throwable):scala.concurrent.Future[T]).

Like all the other collection operations (in [`GenericCollection`](../../api/index.html#reactivemongo.api.collections.GenericCollection) trait), you can insert any [writable value](../bson/typeclasses.html) to `insert()`. With the default BSON serialization, that means provided there a [`BSONDocumentWriter`](../../api/index.html#reactivemongo.bson.BSONDocumentWriter) for its type in the [implicit scope](http://docs.scala-lang.org/tutorials/FAQ/finding-implicits.html). So, considering the `Person` case class:

{% highlight scala %}
import scala.util.{ Failure, Success }
import scala.concurrent.ExecutionContext.Implicits.global

val person = Person("Stephane Godbillon", 29)

val future2 = personColl.insert(person)

future2.onComplete {
  case Failure(e) => throw e
  case Success(writeResult) => {
    println(s"successfully inserted document: $writeResult")
  }
}
{% endhighlight %}

When calling a write operation, it's possible to handle some specific error case by testing the result.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.commands.{ CommandError, WriteResult }

val future: Future[WriteResult] = personColl.insert(person)

val end: Future[Unit] = future.map(_ => {}).recover {
  case err: CommandError if (err.code contains 11000) =>
    // if the result is defined with the error code 11000 (duplicate error)
    println("Just a warning")

  case _ => ()
}
{% endhighlight %}

### Insert multiple document

The operation [`bulkInsert`](../../api/index.html#reactivemongo.api.collections.GenericCollection@bulkInsert%28ordered:Boolean%29%28documents:GenericCollection.this.ImplicitlyDocumentProducer*%29%28implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[reactivemongo.api.commands.MultiBulkWriteResult]) makes it possible to insert multiple documents.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.commands.MultiBulkWriteResult

def bsonCollection: reactivemongo.api.collections.bson.BSONCollection = ???
def persons: List[Person] = ???

val personColl = bsonCollection

val bulkResult1: Future[MultiBulkWriteResult] =
  personColl.bulkInsert(ordered = false)(
    BSONDocument("name" -> "document1"),
    BSONDocument("name" -> "document2"),
    BSONDocument("name" -> "document3"))

// Considering `persons` a `Seq[Person]`, 
// provided a `BSONDocumentWriter[Person]` can be resolved.
val bulkDocs = // prepare the person documents to be inserted
  persons.map(implicitly[personColl.ImplicitlyDocumentProducer](_))
  
val bulkResult2 = personColl.bulkInsert(ordered = true)(bulkDocs: _*)
{% endhighlight %}

### Update a document

Updates are done with the [`update()`](../../api/index.html#reactivemongo.api.collections.GenericCollection@update[S,U]%28selector:S,update:U,writeConcern:reactivemongo.api.commands.WriteConcern,upsert:Boolean,multi:Boolean%29%28implicitselectorWriter:GenericCollection.this.pack.Writer[S],implicitupdateWriter:GenericCollection.this.pack.Writer[U],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[reactivemongo.api.commands.WriteResult]) method, which follows the same logic as `insert`.

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument

val selector = BSONDocument("name" -> "Jack")

val modifier = BSONDocument(
  "$set" -> BSONDocument(
    "lastName" -> "London",
    "firstName" -> "Jack"),
    "$unset" -> BSONDocument("name" -> 1))

// get a future update
val futureUpdate1 = personColl.update(selector, modifier)
{% endhighlight %}

By default, the update operation only update a single matching document. You can also specify that the update should be applied to all the documents that are matching, with the `multi` parameter.

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

// get a future update
val futureUpdate2 = personColl.update(selector, modifier, multi = true)
{% endhighlight %}

It's possible to automatically insert data if there is no existing document matching the update using the `upsert` parameter.

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

val futureUpdate3 = personColl.update(selector, modifier, upsert = true)
{% endhighlight %}

### Remove a document

{% highlight scala %}
import scala.util.{ Failure, Success }
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument

val selector1 = BSONDocument("firstName" -> "Stephane")

val futureRemove1 = personColl.remove(selector1)

futureRemove1.onComplete { // callback
  case Failure(e) => throw e
  case Success(writeResult) => println("successfully removed document")
}
{% endhighlight %}

By default, this [`remove`](../../api/index.html#reactivemongo.api.collections.GenericCollection@remove[T]%28query:T,writeConcern:reactivemongo.api.commands.WriteConcern,firstMatchOnly:Boolean%29%28implicitwriter:GenericCollection.this.pack.Writer[T],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[reactivemongo.api.commands.WriteResult]) function deletes all the documents that match the `selector`. You can change this behavior by setting the `firstMatchOnly` parameter to `true`:

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global
import reactivemongo.bson.BSONDocument

def removeFirst(selector: BSONDocument) =
  personColl.remove(selector, firstMatchOnly = true)
{% endhighlight %}

> ReactiveMongo can even store instances of a custom class directly by defining a [custom writer](../bson/typeclasses.html#custom-writer).

### Find and modify

ReactiveMongo also supports the MongoDB [findAndModify](http://docs.mongodb.org/manual/reference/command/findAndModify/) operation.

In the case you want to update the age of a document in a collection of persons, and at the same time to return the information about the person before this change, it can be done using [`findAndUpdate`](../../api/index.html#reactivemongo.api.collections.GenericCollection@findAndUpdate[Q,U]%28selector:Q,update:U,fetchNewObject:Boolean,upsert:Boolean,sort:Option[GenericCollection.this.pack.Document]%29%28implicitselectorWriter:GenericCollection.this.pack.Writer[Q],implicitupdateWriter:GenericCollection.this.pack.Writer[U],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[GenericCollection.this.BatchCommands.FindAndModifyCommand.FindAndModifyResult]).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.{ BSONDocument, BSONDocumentReader, Macros }
import reactivemongo.api.collections.bson.BSONCollection

case class Person(name: String, age: Int)

def update(collection: BSONCollection, age: Int): Future[Option[Person]] = {
  import collection.BatchCommands.FindAndModifyCommand.FindAndModifyResult
  implicit val reader = Macros.reader[Person]  
  
  val result: Future[FindAndModifyResult] = collection.findAndUpdate(
    BSONDocument("name" -> "James"),
    BSONDocument("$set" -> BSONDocument("age" -> 17)),
    fetchNewObject = true)

  result.map(_.result[Person])
}
{% endhighlight %}

As on a simple update, it's possible to insert a new document when one does not already exist. 

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.{ BSONDocument, Macros }
import reactivemongo.api.collections.bson.BSONCollection

implicit val writer = Macros.writer[Person]

def result(coll: BSONCollection): Future[coll.BatchCommands.FindAndModifyCommand.FindAndModifyResult] = coll.findAndUpdate(
  BSONDocument("name" -> "James"),
  Person(name = "Foo", age = 25),
  upsert = true)
  // insert a new document if a matching one does not already exist
{% endhighlight %}

The [`findAndModify`](../../api/index.html#reactivemongo.api.collections.GenericCollection@findAndModify[Q]%28selector:Q,modifier:GenericCollection.this.BatchCommands.FindAndModifyCommand.Modify,sort:Option[GenericCollection.this.pack.Document]%29%28implicitselectorWriter:GenericCollection.this.pack.Writer[Q],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[GenericCollection.this.BatchCommands.FindAndModifyCommand.FindAndModifyResult]) approach can be used on removal.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.{ BSONDocument, BSONDocumentReader }
import reactivemongo.api.collections.bson.BSONCollection

def removedPerson(coll: BSONCollection, name: String)(implicit ec: ExecutionContext, reader: BSONDocumentReader[Person]): Future[Option[Person]] =
  coll.findAndRemove(BSONDocument("name" -> name)).
    map(_.result[Person])
{% endhighlight %}

[Previous: Database and collections](./database-and-collection.html) / [Next: Find documents](./find-documents.html)
