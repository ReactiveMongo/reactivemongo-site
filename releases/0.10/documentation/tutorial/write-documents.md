---
layout: default
major_version: "0.10"
title: Write Documents
sitemap: false
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
  case Success(lastError) => {
    println("successfully inserted document with lastError = " + lastError)
  }
}
{% endhighlight %}

> #### What does LastError mean?
> A `LastError` is a special document that contains information about the write operation, like the number of documents where updated for example, or the description of the error if an error happened. If the `LastError` actually indicates an error, the `Future` will be in Failure state.

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
  case Success(lastError) => {
    println("successfully inserted document: " + lastError)
  }
}
{% endhighlight %}

### Update a document

Updates are done with the `update()` method, which follow the same logic as `insert()`.

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
  case Success(lasterror) => {
    println("successfully removed document")
  }
}
{% endhighlight %}

By default, `remove()` deletes all the documents that match the `selector`. You can change this behaviour by setting the `firstMatchOnly` parameter to `true`:

{% highlight scala %}
val futureRemove = collection.remove(selector, firstMatchOnly = true)
{% endhighlight %}
