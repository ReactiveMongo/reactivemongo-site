---
layout: default
major_version: 0.1x
title: Streaming
---

## Streaming

Instead of accumulating documents in memory, they can be processed as a stream, using a reactive [`Cursor`](../../api/reactivemongo/api/Cursor).

ReactiveMongo can be used with several streaming frameworks: [Play Iteratees](http://www.playframework.com/documentation/latest/Iteratees), [Akka Streams](http://akka.io/docs/), or with custom processors using [`foldWhile`](../../api/reactivemongo/api/Cursor#foldWhile[A](z:=%3EA,maxDocs:Int)(suc:(A,T)=%3Ereactivemongo.api.Cursor.State[A],err:reactivemongo.api.Cursor.ErrorHandler[A])(implicitctx:scala.concurrent.ExecutionContext):scala.concurrent.Future[A]) (and the other similar operations).

### Akka Stream

The [Akka Stream](http://akka.io/) library can be used to consume ReactiveMongo results.

The following dependency must be configured in your `project/Build.scala` (or `build.sbt`).

```ocaml
libraryDependencies += "org.reactivemongo" %% "reactivemongo-akkastream" % "{{site._0_1x_latest_minor}}"
```

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo-akkastream_{{site._0_1x_scala_major}}/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo-akkastream_{{site._0_1x_scala_major}}/)

The main features of this modules are as follows.

- Get a [`Source`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-akkastream_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-akkastream_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/index.html#reactivemongo.akkastream.AkkaStreamCursor#documentSource(maxDocs:Int,err:reactivemongo.api.Cursor.ErrorHandler[Option[T]])(implicitm:akka.stream.Materializer):akka.stream.scaladsl.Source[T,akka.NotUsed]) of documents from a ReactiveMongo cursor. This is a document producer.
- Run with a [`Flow`](http://doc.akka.io/api/akka/2.4.10/#akka.stream.javadsl.Flow) or a [`Sink`](http://doc.akka.io/api/akka/2.4.10/#akka.stream.javadsl.Sink), which will consume the documents, with possible transformation.

To use the Akka Stream support for the ReactiveMongo cursors, [`reactivemongo.akkastream.cursorProducer`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-akkastream_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-akkastream_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/index.html#reactivemongo.akkastream.package$$cursorFlattener$) must be imported.

```scala
import scala.concurrent.Future

import akka.stream.Materializer
import akka.stream.scaladsl.{ Sink, Source }

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

import reactivemongo.akkastream.{ State, cursorProducer }
// Provides the cursor producer with the Akka Stream capabilities

def processPerson1(collection: BSONCollection, query: BSONDocument)(implicit m: Materializer): Future[Seq[BSONDocument]] = {
  val sourceOfPeople: Source[BSONDocument, Future[State]] =
    collection.find(query).cursor[BSONDocument]().documentSource()

  sourceOfPeople.runWith(Sink.seq[BSONDocument])
}
```

The operation [`AkkaStreamCursor.documentSource`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-akkastream_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-akkastream_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/index.html#reactivemongo.akkastream.AkkaStreamCursor#documentSource(maxDocs:Int,err:reactivemongo.api.Cursor.ErrorHandler[Option[T]])(implicitm:akka.stream.Materializer):akka.stream.scaladsl.Source[T,scala.concurrent.Future[reactivemongo.akkastream.State]]) returns an `Source[T, Future[State]]` (with `Future[State]` representing the completion of the asynchronous materialization). In this case, we get a producer of documents (of type `BSONDocument`).

Now that we have the producer, we need to define how the documents are processed, using a `Sink` or a `Flow` (with transformations).

The line `sourceOfPeople.run(processDocuments)` returns a `Future[Unit]`. It will eventually return the final value of the sink, which is a `Seq` in our case.

Obviously, we may use a pure `Sink` that performs some computation.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import akka.NotUsed
import akka.stream.Materializer
import akka.stream.scaladsl.{ Sink, Source }

import reactivemongo.api.bson.BSONDocument

def processPerson2(sourceOfPeople: Source[BSONDocument, NotUsed])(implicit m: Materializer): Future[Float] = {
  val cumulateAge: Sink[BSONDocument, Future[(Int, Int)]] =
    Sink.fold(0 -> 0) {
      case ((cumulatedAge, n), doc) =>
        val age = doc.getAsOpt[Int]("age").getOrElse(0)
        (cumulatedAge + age, n + 1)
    }

  val cumulated: Future[(Int, Int)] = sourceOfPeople runWith cumulateAge

  val meanAge: Future[Float] =
    cumulated.map { case (cumulatedAge, n) =>
      if (n == 0) 0
      else cumulatedAge / n
    }

  meanAge
}
```

The `cumulateAge` sink extracts the age from the each document, and add it the current result. At the same time, it counts the processed documents. When the `cumulated` age is completed, it is divided by the number of documents to get the mean age.

More:

- [**ReactiveMongo AkkaStream API**](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-akkastream_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-akkastream_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/index.html#package)
- Streaming with [GridFS](../advanced-topics/gridfs.html)

### Play Iteratees

The [Play Iteratees](https://www.playframework.com/documentation/latest/Iteratees) library can work with streams of MongoDB documents.

The dependencies can be updated as follows.

```ocaml
val reactiveMongoVer = "{{site._0_1x_latest_minor}}"
val playVer = "2.5.4" // or greater

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "rectivemongo" % reactiveMongoVer,
  "org.reactivemongo" %% "reactivemongo-iteratees" % reactiveMongoVer,
  "com.typesafe.play" %% "play-iteratees" % playVer)
```

To use the Iteratees support for the ReactiveMongo cursors, [`reactivemongo.play.iteratees.cursorProducer`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-iteratees_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-iteratees_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/reactivemongo/play/iteratees/index.html#cursorProducer[T]:reactivemongo.api.CursorProducer[T]{typeProducedCursor=reactivemongo.play.iteratees.PlayIterateesCursor[T]}) must be imported.

Then the corresponding operations are available on the cursors.

- Get an [`Enumerator`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-iteratees_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-iteratees_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/reactivemongo/play/iteratees/PlayIterateesCursor.html#enumerator(maxDocs:Int,err:reactivemongo.api.Cursor.ErrorHandler[Unit])(implicitctx:scala.concurrent.ExecutionContext):play.api.libs.iteratee.Enumerator[T]) of documents from ReactiveMongo. This is a producer of data.
- Run an `Iteratee` (that we build for this purpose), which will consume data and eventually produce a result.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import play.api.libs.iteratee._

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

import reactivemongo.play.iteratees.cursorProducer
// Provides the cursor producer with the Iteratees capabilities

def processPerson3(collection: BSONCollection, query: BSONDocument): Future[Unit] = {
  val enumeratorOfPeople: Enumerator[BSONDocument] =
    collection.find(query).cursor[BSONDocument]().enumerator()

  val processDocuments: Iteratee[BSONDocument, Unit] =
    Iteratee.foreach { person =>
      val lastName = person.getAsOpt[String]("lastName")
      val prettyBson = BSONDocument.pretty(person)
      println(s"found $lastName: $prettyBson")
    }

  enumeratorOfPeople.run(processDocuments)
}
```

The operation [`PlayIterateesCursor.enumerator`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-iteratees_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-iteratees_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/reactivemongo/play/iteratees/PlayIterateesCursor.html#enumerator(maxDocs:Int,err:reactivemongo.api.Cursor.ErrorHandler[Unit])(implicitctx:scala.concurrent.ExecutionContext):play.api.libs.iteratee.Enumerator[T]) returns an `Enumerator[T]`. In this case, we get a producer of documents (of type `BSONDocument`).

Now that we have the producer, we need to define how the documents are processed: that is the Iteratee's job. Iteratees, as the opposite of Enumerators, are consumers: they are fed in by enumerators and do some computation with the chunks they get.

Here, we build an `Iteratee[BSONDocument, Unit]` that takes `BSONDocument` as an input and eventually returns `Unit` – which is normal because we just print the results without computing any final value. Each time it gets a document, it extracts the `lastName` and prints it on the console along with the whole document. Note that none of these operations are blocking: when the running thread is not processing the callback of our Iteratee, it can be used to compute other things.

When this snippet is run, we get the following:

```javascript
found London: {
  _id: BSONObjectID("4f899e7eaf527324ab25c56b"),
  firstName: BSONString(Jack),
  lastName: BSONString(London),
  age: BSONInteger(40)
}
found Whitman: {
  _id: BSONObjectID("4f899f9baf527324ab25c56c"),
  firstName: BSONString(Walt),
  lastName: BSONString(Whitman),
  age: BSONInteger(72)
}
found Hemingway: {
  _id: BSONObjectID("4f899f9baf527324ab25c56d"),
  firstName: BSONString(Ernest),
  lastName: BSONString(Hemingway),
  age: BSONInteger(61)
}
```

The line `enumeratorOfPeople.run(processDocuments)` returns a `Future[Unit]`. It will eventually return the final value of the Iteratee, which is `Unit` in our case.

> The `run` method on `Enumerator` has an operator alias, `|>>>`. So we can rewrite the last line like this: `enumeratorOfPeople |>>> processDocuments`.

Obviously, we may use a pure `Iteratee` that performs some computation:

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import play.api.libs.iteratee._
import reactivemongo.api.bson.BSONDocument

def processPerson4(enumeratorOfPeople: Enumerator[BSONDocument]) = {
  val cumulateAge: Iteratee[BSONDocument, (Int, Int)] =
    Iteratee.fold(0 -> 0) {
      case ((cumulatedAge, n), doc) =>
        val age = doc.getAsOpt[Int]("age").getOrElse(0)
        (cumulatedAge + age, n + 1)
    }

  val cumulated: Future[(Int, Int)] = enumeratorOfPeople |>>> cumulateAge

  val meanAge: Future[Float] =
    cumulated.map { case (cumulatedAge, n) =>
      if (n == 0) 0
      else cumulatedAge / n
    }

  meanAge
}
```

At each step, this Iteratee will extract the age from the document and add it to the current result. It also counts the number of documents processed. It eventually produces a tuple of two integers; in our case `(173, 3)`. When the `cumulated` age is completed, we divide it by the number of documents to get the mean age.

[More: **ReactiveMongo Iteratees API**](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-iteratees_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-iteratees_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/reactivemongo/play/iteratees/index.html)

### Custom streaming

ReactiveMongo streaming is based on the function [`Cursor.foldWhileM[A]`](../../api/reactivemongo/api/Cursor#foldWhileM[A](z:=%3EA,maxDocs:Int)(suc:(A,T)=%3Escala.concurrent.Future[reactivemongo.api.Cursor.State[A]],err:reactivemongo.api.Cursor.ErrorHandler[A])(implicitctx:scala.concurrent.ExecutionContext):scala.concurrent.Future[A]), which also allows you to implement a custom stream processor.

```scala
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
```

At each streaming step, for each new value or error, you choose how you want to proceed, using the cases `Cursor.{ Cont, Done, Fail }`.

- `Cont`: Continue processing.
- `Done`: End processing, without error; A `Future.successful[T](t)` will be returned by `foldWhile[T]`.
- `Stop`: Stop processing on an error; A `Future.failed` will be returned by `foldWhile[T]`.

There are convenient handler functions, that are helpful to implement a custom streaming: `Cursor.{ ContOnError, DoneOnError, FailOnError, Ignore }`.

- [`ContOnError`](../../api/reactivemongo/api/Cursor$#ContOnError[A](callback:(A,Throwable)=%3EUnit):reactivemongo.api.Cursor.ErrorHandler[A]): Error handler skipping exception.
- [`DoneOnError`](../../api/reactivemongo/api/Cursor$#DoneOnError[A](callback:(A,Throwable)=%3EUnit):reactivemongo.api.Cursor.ErrorHandler[A]): Error handler stopping successfully.
- [`FailOnError`](../../api/reactivemongo/api/Cursor$#FailOnError[A](callback:(A,Throwable)=%3EUnit):reactivemongo.api.Cursor.ErrorHandler[A]): The default error handler, stopping with failure when an error is encountered.
- [`Ignore`](../../api/reactivemongo/api/Cursor$#Ignore[A](callback:A=%3EUnit):(Unit,A)=%3Ereactivemongo.api.Cursor.State[Unit]): Consume all the results, but ignoring all the values as `Unit`.

Each fold operations (`foldResponses`, `foldBulks` or `foldWhile`) have variants working with a function returning a `Future[State[T]]` (instead of a synchronous `State[T]`).

[Previous: Find Documents](./find-documents.html)
