---
layout: default
major_version: 0.1x
title: Write Documents
---

## Write Documents

MongoDB offers different kinds of write operations: insertion, update or removal. Using ReactiveMongo Data, this can be performed asynchronously.

### Insert a document

Insertions are done with the [`insert`](../../api/reactivemongo/api/collections/GenericCollection.html#insert(ordered:Boolean,writeConcern:reactivemongo.api.commands.WriteConcern)(implicitevidence$2:GenericCollection.this.pack.Writer[T]):GenericCollection.this.InsertBuilder[T]) function.

{% highlight scala %}
import scala.util.{ Failure, Success }

import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.commands.{ MultiBulkWriteResult, WriteResult }
import reactivemongo.api.collections.bson.BSONCollection

val document1 = BSONDocument(
  "firstName" -> "Stephane",
  "lastName" -> "Godbillon",
  "age" -> 29)

// Simple: .insert.one(t)
def simpleInsert(coll: BSONCollection): Future[Unit] = {
  val writeRes: Future[WriteResult] = coll.insert.one(document1)

  writeRes.onComplete { // Dummy callbacks
    case Failure(e) => e.printStackTrace()
    case Success(writeResult) =>
      println(s"successfully inserted document with result: $writeResult")
  }

  writeRes.map(_ => {}) // in this example, do nothing with the success
}

// Bulk: .insert.many(Seq(t1, t2, ..., tN))
def bulkInsert(coll: BSONCollection): Future[Unit] = {
  val writeRes: Future[MultiBulkWriteResult] =
    coll.insert(ordered = false).many(Seq(
      document1, BSONDocument(
        "firstName" -> "Foo",
        "lastName" -> "Bar",
        "age" -> 1)))

  writeRes.onComplete { // Dummy callbacks
    case Failure(e) => e.printStackTrace()
    case Success(writeResult) =>
      println(s"successfully inserted document with result: $writeResult")
  }

  writeRes.map(_ => {}) // in this example, do nothing with the success
}
{% endhighlight %}

**What does `WriteResult` mean?**

A [`WriteResult`](../../api/reactivemongo/api/commands/WriteResult) is a special document that contains information about the write operation, like the number of documents that were updated.

If the write result actually indicates an error, the `Future` will be in a [`failed` state](http://www.scala-lang.org/api/current/index.html#scala.concurrent.Future$@failed[T](exception:Throwable):scala.concurrent.Future[T]) (no need to check for `WriteResult.ok`).

Like all the other collection operations (in [`GenericCollection`](../../api/reactivemongo/api/collections/GenericCollection.GenericCollection) trait), you can insert any [writeable value](../bson/typeclasses.html) to `insert()`. With the default BSON serialization, that means provided there a [`BSONDocumentWriter`](../../api/reactivemongo/bson/BSONDocumentWriter) for its type in the [implicit scope](http://docs.scala-lang.org/tutorials/FAQ/finding-implicits.html). So, considering the `Person` case class:

{% highlight scala %}
import scala.util.{ Failure, Success }
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.collections.bson.BSONCollection

val person = Person("Stephane Godbillon", 29)

def testInsert(personColl: BSONCollection) = {
  val future2 = personColl.insert.one(person)

  future2.onComplete {
    case Failure(e) => throw e
    case Success(writeResult) => {
      println(s"successfully inserted document: $writeResult")
    }
  }
}
{% endhighlight %}

**Error handling:**

When calling a write operation, it's possible to handle some specific error case by testing the result, using some pattern matching utilities.

- [`WriteResult.Code`](../../api/reactivemongo/api/commands/WriteResult$@Code): matches the errors according the specified code (e.g. the 11000 code for the Duplicate error)
- [`WriteResult.Message`](../../api/reactivemongo/api/commands/WriteResult$@Message): matches the errors according the message

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.commands.WriteResult

import reactivemongo.api.collections.bson.BSONCollection

def insertErrors(personColl: BSONCollection) = {
  val future: Future[WriteResult] = personColl.insert.one(person)

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

### Update a document

Updates are done with the [`update`](../../api/collections/GenericCollection.html#update(ordered:Boolean,writeConcern:reactivemongo.api.commands.WriteConcern):GenericCollection.this.UpdateBuilder) operation, which follows the same logic as `insert`.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument

import reactivemongo.api.collections.bson.BSONCollection

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

By default, the update operation only updates a single matching document. You can also indicate that the update should be applied to all the documents that are matching, with the `multi` parameter.

It's possible to automatically insert data if there is no matching document using the `upsert` parameter.

The [`arrayFilters`](https://docs.mongodb.com/manual/reference/command/update/#update-elements-match-arrayfilters-criteria) criteria can also be specified on update.

{% highlight scala %}
import scala.concurrent.ExecutionContext

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

def updateArrayFilters(personColl: BSONCollection)(
  implicit ec: ExecutionContext) =
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

### Delete a document

The [`.delete`](../../api/reactivemongo/api/collections/GenericCollection.html#delete(ordered:Boolean,writeConcern:reactivemongo.api.commands.WriteConcern):GenericCollection.this.DeleteBuilder) function returns a [`DeleteBuilder`](../../api/reactivemongo/api/collections/DeleteOps$DeleteBuilder.html), which allows to perform simple or bulk delete.

{% highlight scala %}
import scala.util.{ Failure, Success }

import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument

import reactivemongo.api.collections.bson.BSONCollection

def simpleDelete1(personColl: BSONCollection) = {
  val selector1 = BSONDocument("firstName" -> "Stephane")

  val futureRemove1 = personColl.delete.one(selector1)

  futureRemove1.onComplete { // callback
    case Failure(e) => throw e
    case Success(writeResult) => println("successfully removed document")
  }
}

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

### Find and modify

ReactiveMongo also supports the MongoDB [`findAndModify`](http://docs.mongodb.org/manual/reference/command/findAndModify/) operation.

In the case you want to update the age of a document in a collection of persons, and at the same time to return the information about the person before this change, it can be done using [`findAndUpdate`](../../api/reactivemongo/api/collections/GenericCollection.GenericCollection#findAndUpdate[Q,U]%28selector:Q,update:U,fetchNewObject:Boolean,upsert:Boolean,sort:Option[GenericCollection.this.pack.Document]%29%28implicitselectorWriter:GenericCollection.this.pack.Writer[Q],implicitupdateWriter:GenericCollection.this.pack.Writer[U],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[GenericCollection.this.BatchCommands.FindAndModifyCommand.FindAndModifyResult]).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.{ BSONDocument, Macros }
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

The [`findAndModify`](../../api/reactivemongo/api/collections/GenericCollection.GenericCollection#findAndModify[Q]%28selector:Q,modifier:GenericCollection.this.BatchCommands.FindAndModifyCommand.Modify,sort:Option[GenericCollection.this.pack.Document]%29%28implicitselectorWriter:GenericCollection.this.pack.Writer[Q],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[GenericCollection.this.BatchCommands.FindAndModifyCommand.FindAndModifyResult]) approach can be used on removal.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.{ BSONDocument, BSONDocumentReader }
import reactivemongo.api.collections.bson.BSONCollection

def removedPerson(coll: BSONCollection, name: String)(implicit ec: ExecutionContext, reader: BSONDocumentReader[Person]): Future[Option[Person]] =
  coll.findAndRemove(BSONDocument("name" -> name)).
    map(_.result[Person])
{% endhighlight %}

As when [using `update`](#update-a-document) [`arrayFilters`](https://docs.mongodb.com/manual/reference/command/findAndModify/index.html#specify-arrayfilters-for-an-array-update-operations) criteria can be specified for a `findAndModify` operation.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument

import reactivemongo.api.WriteConcern
import reactivemongo.api.collections.bson.BSONCollection

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
{% endhighlight %}

### Session/transaction

Starting in 3.6, MongoDB offers [session management](https://docs.mongodb.com/manual/reference/server-sessions/) to gather operations, and since MongoDB 4.0, [transactions](https://docs.mongodb.com/master/core/transactions/) can be defined for session.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.BSONDocument

import reactivemongo.api.DefaultDB

def testTx(db: DefaultDB)(implicit ec: ExecutionContext): Future[Unit] = 
  db.startSession().flatMap {
    case Some(dbWithSession) => dbWithSession.startTransaction(None) match {
      case Some(dbWithTx) => {
        val coll = dbWithTx.collection("foo")

        for {
          _ <- coll.insert.one(BSONDocument("id" -> 1, "bar" -> "lorem"))
          r <- coll.find(BSONDocument("id" -> 1)).one[BSONDocument] // found

          _ <- db.collection("foo").find(
            BSONDocument("id" -> 1)).one[BSONDocument]
            // not found for DB outside transaction

          _ <- dbWithTx.commitTransaction() // or abortTransaction()
          // session still open, can start another transaction, or other ops

          _ <- dbWithSession.endSession()
        } yield ()
      }

      case _ => Future.successful(println("No transaction"))
    }

    case _ => Future.successful(println("No session"))
  }
{% endhighlight %}

The support for session and transaction is defined in the database API (still experimental).

- [`startSession`](../../api/reactivemongo/api/DefaultDB.html#startSession()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Option[reactivemongo.api.DefaultDB]])
- [`startTransaction`](../../api/reactivemongo/api/DefaultDB.html#startTransaction(writeConcern:Option[reactivemongo.api.WriteConcern]):Option[DefaultDB.this.DBType]), for a DB reference with a session started.
- [`abortTransaction`](../../api/reactivemongo/api/DefaultDB.html#abortTransaction()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Option[DefaultDB.this.DBType]]) or [`commitTransaction`](../../api/reactivemongo/api/DefaultDB.html#commitTransaction()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Option[DefaultDB.this.DBType]]) on a DB reference with transaction.
- [`endSession`](../../api/reactivemongo/api/DefaultDB.html#endSession()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Option[reactivemongo.api.DefaultDB]]) or [`killSession`](../../api/reactivemongo/api/DefaultDB.html#killSession()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.DefaultDB])

### Troubleshooting

The synchronous [`.db` has been deprecated](../release-details.html#database-resolution) as it didn't offer a sufficient guaranty that it can initially find an active channel in the connection pool (`MongoConnection`).
The new [`.database` resolution](../../api/reactivemongo/api/MongoConnection#database%28name:String,failoverStrategy:reactivemongo.api.FailoverStrategy%29%28implicitcontext:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[reactivemongo.api.DefaultDB]) must be used (see [connection tutorial](./connect-database.html)).

If the deprecated database resolution is still used, a runtime error such as `ConnectionNotInitialized` can be raised when writing documents.

[Previous: Database and collections](./database-and-collection.html) / [Next: Find documents](./find-documents.html)
