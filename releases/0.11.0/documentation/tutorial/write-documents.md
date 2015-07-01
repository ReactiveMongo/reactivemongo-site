---
layout: default
title: ReactiveMongo 0.11.0 - Write Documents
---

## Classic Write Operations

### Insert a document

Insertions are done with the `insert()` method, which returns a `Future[LastError]`.

{% highlight scala %}
val document = BSONDocument(
  "firstName" -> "Stephane",
  "lastName" -> "Godbillon",
  "age" -> 29)

val future = collection.insert(document)

future.onComplete {
  case Failure(e) => throw e
  case Success(writeResult) =>
    println(s"successfully inserted document with result: $writeResult")
}
{% endhighlight %}

#### What does WriteResult mean?

A [`WriteResult`](../../api/index.html#reactivemongo.api.commands.WriteResult) is a special document that contains information about the write operation, like the number of documents where updated for example, or the description of the error if an error happened. If the write result actually indicates an error, the `Future` will be in a `failed` state.

Like all the other operations in the `GenericCollection` trait, you can give any object to `insert()`, provided that you have a `BSONDocumentWriter` for its type in the implicit scope. So, with the `Person` case class:

{% highlight scala %}
val person = Person(
  BSONObjectID.generate,
  "Stephane",
  "Godbillon",
  29)

val future = collection.insert(person)

future.onComplete {
  case Failure(e) => throw e
  case Success(writeResult) => {
    println(s"successfully inserted document: $writeResult")
  }
}
{% endhighlight %}

### Insert multiple document

The operation [`bulkInsert`](../../api/index.html#reactivemongo.api.collections.GenericCollection@bulkInsert%28ordered:Boolean%29%28documents:GenericCollection.this.ImplicitlyDocumentProducer*%29%28implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[reactivemongo.api.commands.MultiBulkWriteResult]) make it possible to insert multiple document.

{% highlight scala %}
import scala.concurrent.Future
import reactivemongo.api.commands.MultiBulkWriteResult

// Considering `collection` a ReactiveMongo collection
val bulkResult: Future[MultiBulkWriteResult] =
  collection.bulkInsert(ordered = false)(
    BSONDocument("name" -> "document1"),
    BSONDocument("name" -> "document2"),
    BSONDocument("name" -> "document3"))

// Considering `persons` a `Seq[Person]`, 
// provided a `BSONDocumentWriter[Person]` can be resolved.
val bulkDocs = // prepare the person documents to be inserted
  persons.map(implicitly[collection.ImplicitlyDocumentProducer](_))
  
val bulkResult = collection.bulkInsert(ordered = true)(bulkDocs: _*)
{% endhighlight %}

### Update a document

The updates are done with the `update()` method, which follow the same logic as `insert()`.

{% highlight scala %}
val selector = BSONDocument("name" -> "Jack")

val modifier = BSONDocument(
  "$set" -> BSONDocument(
    "lastName" -> "London",
    "firstName" -> "Jack"),
    "$unset" -> BSONDocument(
      "name" -> 1))

// get a future update
val futureUpdate = collection.update(selector, modifier)
{% endhighlight %}

You can also specify whether if the update should concern all the documents that match `selector`.

{% highlight scala %}
// get a future update
val futureUpdate = collection.update(selector, modifier, multi = true)
{% endhighlight %}

### Remove a document

{% highlight scala %}
val selector = BSONDocument(
  "firstName" -> "Stephane")

val futureRemove = collection.remove(selector)

futureRemove.onComplete {
  case Failure(e) => throw e
  case Success(writeResult) => println("successfully removed document")
}
{% endhighlight %}

By default, `remove()` deletes all the documents that match the `selector`. You can change this behavior by setting the `firstMatchOnly` parameter to `true`:

{% highlight scala %}
val futureRemove = collection.remove(selector, firstMatchOnly = true)
{% endhighlight %}