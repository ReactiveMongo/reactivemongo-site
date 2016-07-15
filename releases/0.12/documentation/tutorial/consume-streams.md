---
layout: default
title: ReactiveMongo 0.12 - Consume streams of documents
---

## Consume streams of documents

Instead of accumulating documents in memory like in the two previous examples, we can process them as a stream, using a reactive [Cursor](../../api/index.html#reactivemongo.api.Cursor).

ReactiveMongo can be used with several streaming frameworks: [Play Iteratees](http://www.playframework.com/documentation/latest/Iteratees), [Akka Streams](http://akka.io/docs/), or with custom processors using [`foldWhile`](../../api/index.html#reactivemongo.api.Cursor@foldWhile[A](z:=%3EA,maxDocs:Int)(suc:(A,T)=%3Ereactivemongo.api.Cursor.State[A],err:reactivemongo.api.Cursor.ErrorHandler[A])(implicitctx:scala.concurrent.ExecutionContext):scala.concurrent.Future[A]) (and the other similar operations).

### Play Iteratee

The [Play Iteratees](https://www.playframework.com/documentation/latest/Iteratees) library can work with streams of MongoDB documents.

- Get an [`Enumerator`](../../api/index.html#reactivemongo.play.iteratees.PlayIterateesCursor@enumerator(maxDocs:Int,err:reactivemongo.api.Cursor.ErrorHandler[Unit])(implicitctx:scala.concurrent.ExecutionContext):play.api.libs.iteratee.Enumerator[T]) of documents from ReactiveMongo. This is a producer of data.
- Run an `Iteratee` (that we build for this purpose), which will consume data and eventually produce a result.

To use the Iteratees support for the ReactiveMongo cursors, [`reactivemongo.play.iteratees.cursorProducer`](../../api/index.html#reactivemongo.play.iteratees.package@cursorProducer[T]:reactivemongo.api.CursorProducer[T]{typeProducedCursor=reactivemongo.play.iteratees.PlayIterateesCursor[T]}) must be imported.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import play.api.libs.iteratee._

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

import reactivemongo.play.iteratees.cursorProducer
// Provides the cursor producer with the Iteratees capabilities

def processPerson1(collection: BSONCollection, query: BSONDocument): Future[Unit] = {
  val enumeratorOfPeople: Enumerator[BSONDocument] =
    collection.find(query).cursor[BSONDocument].enumerator()

  val processDocuments: Iteratee[BSONDocument, Unit] =
    Iteratee.foreach { person =>
      val lastName = person.getAs[String]("lastName")
      val prettyBson = BSONDocument.pretty(person)
      println(s"found $lastName: $prettyBson")
    }

  enumeratorOfPeople.run(processDocuments)
}
{% endhighlight %}

The operation [`PlayIterateesCursor.enumerate`](../../api/index.html#reactivemongo.play.iteratees.PlayIterateesCursor@enumerator(maxDocs:Int,err:reactivemongo.api.Cursor.ErrorHandler[Unit])(implicitctx:scala.concurrent.ExecutionContext):play.api.libs.iteratee.Enumerator[T]) returns an `Enumerator[T]`. In this case, we get a producer of documents (of type `BSONDocument`).

Now that we have the producer, we need to define how the documents are processed: that is the Iteratee's job. Iteratees, as the opposite of Enumerators, are consumers: they are fed in by enumerators and do some computation with the chunks they get.

Here, we build an `Iteratee[BSONDocument, Unit]` that takes `BSONDocument` as an input and eventually returns `Unit` – which is normal because we just print the results without computing any final value. Each time it gets a document, it extracts the `lastName` and prints it on the console along with the whole document. Note that none of these operations are blocking: when the running thread is not processing the callback of our iteratee, it can be used to compute other things.

When this snippet is run, we get the following:

{% highlight javascript %}
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
{% endhighlight %}

The line `enumeratorOfPeople.run(processDocuments)` returns a `Future[Unit]`; it will eventually return the final value of the iteratee, which is `Unit` in our case.

> The `run` method on `Enumerator` has an operator alias, `|>>>`. So we can rewrite the last line like this: `enumeratorOfPeople |>>> processDocuments`.

Obviously, we may use a pure `Iteratee` that performs some computation:

{% highlight scala %}
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
{% endhighlight %}

At each step, this Iteratee will extract the age from the document and add it to the current result; it also counts the number of documents processed. It eventually produces a tuple of two integers; in our case `(173, 3)`. When the `cumulated` future is completed, we divide the cumulated age by the number of documents to get the mean age.

> The similar operations [`bulkEnumerator`](../../api/index.html#reactivemongo.play.iteratees.PlayIterateesCursor@bulkEnumerator(maxDocs:Int,err:reactivemongo.api.Cursor.ErrorHandler[Unit])(implicitctx:scala.concurrent.ExecutionContext):play.api.libs.iteratee.Enumerator[Iterator[T]]) and [`responseEnumerator`](../../api/index.html#reactivemongo.play.iteratees.PlayIterateesCursor@responseEnumerator(maxDocs:Int,err:reactivemongo.api.Cursor.ErrorHandler[Unit])(implicitctx:scala.concurrent.ExecutionContext):play.api.libs.iteratee.Enumerator[reactivemongo.core.protocol.Response]) are also provided, to respectively have `Enumerator` per MongoDB result batch or per response.

### Custom streaming

ReactiveMongo streaming is based on the function [`Cursor.foldWhileM[A]`](../../api/index.html#reactivemongo.api.Cursor@foldWhileM[A](z:=%3EA,maxDocs:Int)(suc:(A,T)=%3Escala.concurrent.Future[reactivemongo.api.Cursor.State[A]],err:reactivemongo.api.Cursor.ErrorHandler[A])(implicitctx:scala.concurrent.ExecutionContext):scala.concurrent.Future[A]), which also allows you to implement a custom stream processor.

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

At each streaming step, for each new value or error, you choose how you want to proceed, using the cases `Cursor.{ Cont, Done, Fail }`.

- `Cont`: Continue processing.
- `Done`: End processing, without error; A `Future.successful[T](t)` will be returned by `foldWhile[T]`.
- `Stop`: Stop processing on an error; A `Future.failed` will be returned by `foldWhile[T]`.

There are convenient handler functions, that are helpful to implement a custom streaming: `Cursor.{ ContOnError, DoneOnError, FailOnError, Ignore }`.

- [`ContOnError`](../../api/index.html#reactivemongo.api.Cursor$@ContOnError[A](callback:(A,Throwable)=%3EUnit):reactivemongo.api.Cursor.ErrorHandler[A]): Error handler skipping exception.
- [`DoneOnError`](../../api/index.html#reactivemongo.api.Cursor$@DoneOnError[A](callback:(A,Throwable)=%3EUnit):reactivemongo.api.Cursor.ErrorHandler[A]): Error handler stopping successfully.
- [`FailOnError`](../../api/index.html#reactivemongo.api.Cursor$@FailOnError[A](callback:(A,Throwable)=%3EUnit):reactivemongo.api.Cursor.ErrorHandler[A]): The default error handler, stopping with failure when an error is encountered.
- [`Ignore`](../../api/index.html#reactivemongo.api.Cursor$@Ignore[A](callback:A=%3EUnit):(Unit,A)=%3Ereactivemongo.api.Cursor.State[Unit]): Consume all the results, but ignoring all the values as `Unit`.

Each fold operations (`foldResponses`, `foldBulks` or `foldWhile`) have variants working with a function returning a `Future[State[T]]` (instead of a synchronous `State[T]`).

> When using the asynchronous fold operations, you need to take care of the fast producer/slow consumer issue. Otherwise, an unbound number of `Future` can be created, and so raise memory and/or thread issue.