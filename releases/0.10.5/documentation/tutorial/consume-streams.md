---
layout: default
major_version: 0.10.5
title: Consume Streams of Documents
---

## Consume streams of documents

Instead of accumulating documents in memory like in the two previous examples, we can process them in a streaming way. This is achieved using the [`play-iteratees`](http://www.playframework.com/documentation/2.3.x/Iteratees) library, in two steps:

- get an `Enumerator` of documents from ReactiveMongo. This is a producer of data;
- apply an `Iteratee` (that we build for this purpose), which will consume data and eventually produce a result.

{% highlight scala %}
import play.api.libs.iteratee._

// result type is Enumerator[BSONDocument]
val enumeratorOfPeople =
  collection.
    find(query).
    cursor[BSONDocument].
    enumerate()

val processDocuments: Iteratee[BSONDocument, Unit] =
  Iteratee.foreach { person =>
    val lastName = person.getAs[String]("lastName")
    val prettyBson = BSONDocument.pretty(person)
    println(s"found $lastName: $prettyBson")
  }

enumeratorOfPeople.apply(processDocuments) // returns Future[Unit]
{% endhighlight %}

The method `cursor.enumerate()` returns an `Enumerator[T]`. In this case, we get a producer of documents (of type `BSONDocument`).

Now that we have the producer, we need to define how the documents are processed: that is the Iteratee's job. Iteratees, as the opposite of Enumerators, are consumers: they are fed in by enumerators and do some computation with the chunks they get.

Here, we build an `Iteratee[BSONDocument, Unit]` that takes `BSONDocument` as an input and eventually returns `Unit` – which is normal because we just print the results without computing any final value. Each time it gets a document, it extracts the `lastName` and prints it on the console along with the whole document. Note that none of these operations are blocking: when the running thread is not processing the callback of our iteratee, it can be used to compute other things.

When this snippet is run, we get the following:

{% highlight scala %}
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

The line `enumeratorOfPeople.apply(processDocuments)` returns a `Future[Unit]`; it will eventually return the final value of the iteratee, which is `Unit` in our case.

> The `apply` method on `Enumerator` has an operator alias, `|>>>`. So we can rewrite the last line like this: `enumeratorOfPeople |>>> processDocuments`.

Obviously, we may use a pure `Iteratee` that performs some computation:

{% highlight scala %}
val cumulateAge: Iteratee[BSONDocument, (Int, Int)] =
  Iteratee.fold( 0 -> 0 ) { case ( (cumulatedAge, n), doc) =>
    val age = person.getAs[Int]("age").getOrElse(0)
    (cumulatedAge + age, n + 1)
  }

val cumulated = enumeratorOfPeople |>>> cumulateAge // Future[(Int, Int)]

val meanAge =
  cumulated.map { case (cumulatedAge, n) =>
    if(n == 0)
      0
    else cumulatedAge / n
  }

// meanAge is of type Future[Float]
{% endhighlight %}

At each step, this Iteratee will extract the age from the document and add it to the current result; it also counts the number of documents processed. It eventually produces a tuple of two integers; in our case `(173, 3)`. When the `cumulated` future is completed, we divide the cumulated age by the number of documents to get the mean age.

