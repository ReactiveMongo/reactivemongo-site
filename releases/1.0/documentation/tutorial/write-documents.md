---
layout: default
major_version: 1.0
title: Write Documents
---

## Write Documents

MongoDB offers different kinds of write operations: insertion, update or removal. Using ReactiveMongo Data, this can be performed asynchronously.

### Insert a document

Insertions are done with the [`insert`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#insert:GenericCollection.this.InsertBuilder) function.

```scala
import scala.util.{ Failure, Success }

import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.commands.WriteResult
import reactivemongo.api.bson.collection.BSONCollection

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
  val writeRes: Future[coll.MultiBulkWriteResult] =
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
```

**What does `WriteResult` mean?**

A [`WriteResult`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/commands/WriteResult.html) is a special document that contains information about the write operation, like the number of documents that were updated.

If the write result actually indicates an error, the `Future` will be in a [`failed` state](http://www.scala-lang.org/api/current/index.html#scala.concurrent.Future$@failed[T](exception:Throwable):scala.concurrent.Future[T]) (no need to check for `WriteResult.ok`).

Like all the other collection operations (in [`GenericCollection`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html) trait), you can insert any [writeable value](../bson/typeclasses.html) to `insert()`. With the default BSON serialization, that means provided there a [`BSONDocumentWriter`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDocumentWriter.html) for its type in the [implicit scope](http://docs.scala-lang.org/tutorials/FAQ/finding-implicits.html). So, considering the `Person` case class:

```scala
import scala.util.{ Failure, Success }
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.collection.BSONCollection

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
```

**Error handling:**

When calling a write operation, it's possible to handle some specific error case by testing the result, using some pattern matching utilities.

- [`WriteResult.Code`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/commands/WriteResult$$Code$.html): matches the errors according the specified code (e.g. the 11000 code for the Duplicate error)
- [`WriteResult.Message`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/commands/WriteResult$$Message$.html): matches the errors according the message
- [`WriteResult.Exception`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/commands/WriteResult$$Message$.html): matches the exception details

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.commands.WriteResult

import reactivemongo.api.bson.collection.BSONCollection

def insertErrors(personColl: BSONCollection) = {
  val future: Future[WriteResult] = personColl.insert.one(person)

  val end: Future[Unit] = future.map(_ => {}).recover {
    case WriteResult.Code(11000) =>
      // if the result is defined with the error code 11000 (duplicate error)
      println("Match the code 11000")

    case WriteResult.Message("Must match this exact message") =>
      println("Match the error message")

    case WriteResult.Exception(cause) =>
      cause.printStackTrace() // Print any other Exception

    case _ => ()
  }
}
```

### Update a document

Updates are done with the [`update`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#update:GenericCollection.this.UpdateBuilder) operation, which follows the same logic as `insert`.

```scala
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
```

By default, the update operation only updates a single matching document. You can also indicate that the update should be applied to all the documents that are matching, with the `multi` parameter.

It's possible to automatically insert data if there is no matching document using the `upsert` parameter.

The [`arrayFilters`](https://docs.mongodb.com/manual/reference/command/update/#update-elements-match-arrayfilters-criteria) criteria can also be specified on update.

```scala
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

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
```

### Delete a document

The [`.delete`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#delete:GenericCollection.this.DeleteBuilder) function returns a [`DeleteBuilder`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/DeleteOps$DeleteBuilder.html), which allows to perform simple or bulk delete.

```scala
import scala.util.{ Failure, Success }

import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.bson.collection.BSONCollection

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
```

> The `.remove` operation is now deprecated.

### Find and modify

ReactiveMongo also supports the MongoDB [`findAndModify`](http://docs.mongodb.org/manual/reference/command/findAndModify/) operation.

In the case you want to update the age of a document in a collection of persons, and at the same time to return the information about the person before this change, it can be done using [`findAndUpdate`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#findAndUpdate[S,T](selector:S,update:T,fetchNewObject:Boolean,upsert:Boolean,sort:Option[GenericCollection.this.pack.Document],fields:Option[GenericCollection.this.pack.Document],bypassDocumentValidation:Boolean,writeConcern:reactivemongo.api.WriteConcern,maxTime:Option[scala.concurrent.duration.FiniteDuration],collation:Option[reactivemongo.api.Collation],arrayFilters:Seq[GenericCollection.this.pack.Document])(implicitswriter:GenericCollection.this.pack.Writer[S],implicitwriter:GenericCollection.this.pack.Writer[T],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[GenericCollection.this.FindAndModifyResult]).

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.{ BSONDocument, Macros }
import reactivemongo.api.bson.collection.BSONCollection

case class Person(name: String, age: Int)

def update(collection: BSONCollection, age: Int): Future[Option[Person]] = {
  implicit val reader = Macros.reader[Person]  
  
  val result = collection.findAndUpdate(
    BSONDocument("name" -> "James"),
    BSONDocument("$set" -> BSONDocument("age" -> 17)),
    fetchNewObject = true)

  result.map(_.result[Person])
}
```

As on a simple update, it's possible to insert a new document when one does not already exist. 

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.{ BSONDocument, BSONDocumentHandler, Macros }
import reactivemongo.api.bson.collection.BSONCollection

implicit val handler: BSONDocumentHandler[Person] = Macros.handler[Person]

/** Insert a new document if a matching one does not already exist. */
def result(coll: BSONCollection): Future[Option[Person]] =
  coll.findAndUpdate(
    BSONDocument("name" -> "James"),
    Person(name = "Foo", age = 25),
    upsert = true).map(_.result[Person])
```

The [`findAndModify`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#findAndModify[S](selector:S,modifier:GenericCollection.this.FindAndModifyOp,sort:Option[GenericCollection.this.pack.Document],fields:Option[GenericCollection.this.pack.Document],bypassDocumentValidation:Boolean,writeConcern:reactivemongo.api.WriteConcern,maxTime:Option[scala.concurrent.duration.FiniteDuration],collation:Option[reactivemongo.api.Collation],arrayFilters:Seq[GenericCollection.this.pack.Document])(implicitswriter:GenericCollection.this.pack.Writer[S],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[GenericCollection.this.FindAndModifyResult]) approach can be used on removal.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.{ BSONDocument, BSONDocumentReader }
import reactivemongo.api.bson.collection.BSONCollection

def removedPerson(coll: BSONCollection, name: String)(implicit ec: ExecutionContext, reader: BSONDocumentReader[Person]): Future[Option[Person]] =
  coll.findAndRemove(BSONDocument("name" -> name)).
    map(_.result[Person])
```

As when [using `update`](#update-a-document) [`arrayFilters`](https://docs.mongodb.com/manual/reference/command/findAndModify/index.html#specify-arrayfilters-for-an-array-update-operations) criteria can be specified for a `findAndModify` operation.

```scala
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.WriteConcern
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
```

### Session/transaction

Starting in 3.6, MongoDB offers [session management](https://docs.mongodb.com/manual/reference/server-sessions/) to gather operations, and since MongoDB 4.0, [transactions](https://docs.mongodb.com/master/core/transactions/) can be defined for session.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.DB

def testTx(db: DB)(implicit ec: ExecutionContext): Future[Unit] = 
  for {
    dbWithSession <- db.startSession()
    dbWithTx <- dbWithSession.startTransaction(None)
    coll = dbWithTx.collection("foo")

    _ <- coll.insert.one(BSONDocument("id" -> 1, "bar" -> "lorem"))
    r <- coll.find(BSONDocument("id" -> 1)).one[BSONDocument] // found

    _ <- db.collection("foo").find(
      BSONDocument("id" -> 1)).one[BSONDocument]
      // not found for DB outside transaction

    _ <- dbWithTx.commitTransaction() // or abortTransaction()
      // session still open, can start another transaction, or other ops

    _ <- dbWithSession.endSession()
  } yield ()
```

The support for session and transaction is defined in the database API (still experimental).

- [`startSession`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/DB.html#startSession()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.DB])
- [`startTransaction`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/DB.html#startTransaction(writeConcern:Option[reactivemongo.api.WriteConcern])(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.DB]), for a DB reference with a session started.
- [`abortTransaction`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/DB.html#abortTransaction()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.DB]) or [`commitTransaction`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/DB.html#commitTransaction()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.DB]) on a DB reference with transaction.
- [`endSession`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/DB.html#endSession()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.DB]) or [`killSession`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/DB.html#killSession()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.DB])

[Previous: Database and collections](./database-and-collection.html) / [Next: Find documents](./find-documents.html)
