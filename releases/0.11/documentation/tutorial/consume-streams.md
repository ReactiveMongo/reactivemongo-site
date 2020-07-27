---
layout: default
major_version: 0.11
title: Streaming
---

## Streaming

Instead of accumulating documents in memory like in the two previous examples, we can process them as a stream.

ReactiveMongo can be used with several streaming frameworks: [Play Iteratees](http://www.playframework.com/documentation/latest/Iteratees), [Akka Streams](http://akka.io/docs/), or with custom processors using `foldWhile`.

### Play Iteratees

The Play Iteratees library can work with document streams as follows.

- Get an `Enumerator` of documents from ReactiveMongo. This is a producer of data.
- Run an `Iteratee` (that we build for this purpose), which will consume data and eventually produce a result.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import play.api.libs.iteratee._
import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

def processPerson1(collection: BSONCollection, query: BSONDocument): Future[Unit] = {
  val enumeratorOfPeople: Enumerator[BSONDocument] =
    collection.find(query).cursor[BSONDocument].enumerate()

  val processDocuments: Iteratee[BSONDocument, Unit] =
    Iteratee.foreach { person =>
      val lastName = person.getAs[String]("lastName")
      val prettyBson = BSONDocument.pretty(person)
      println(s"found $lastName: $prettyBson")
    }

  enumeratorOfPeople.run(processDocuments)
}
```

The method `cursor.enumerate()` returns an `Enumerator[T]`. In this case, we get a producer of documents (of type `BSONDocument`).

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

The line `enumeratorOfPeople.run(processDocuments)` returns a `Future[Unit]`; it will eventually return the final value of the Iteratee, which is `Unit` in our case.

> The `run` method on `Enumerator` has an operator alias, `|>>>`. So we can rewrite the last line like this: `enumeratorOfPeople |>>> processDocuments`.

Obviously, we may use a pure `Iteratee` that performs some computation:

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import play.api.libs.iteratee._
import reactivemongo.bson.BSONDocument

def processPerson2(enumeratorOfPeople: Enumerator[BSONDocument]) = {
  val cumulateAge: Iteratee[BSONDocument, (Int, Int)] =
    Iteratee.fold(0 -> 0) {
      case ((cumulatedAge, n), doc) =>
        val age = doc.getAs[Int]("age").getOrElse(0)
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

At each step, this Iteratee will extract the age from the document and add it to the current result; it also counts the number of documents processed. It eventually produces a tuple of two integers; in our case `(173, 3)`. When the `cumulated` future is completed, we divide the cumulated age by the number of documents to get the mean age.

### Custom streaming

ReactiveMongo streaming is based on the function `Cursor.foldWhile[A]`, which also allows you to implement a custom stream processor.

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