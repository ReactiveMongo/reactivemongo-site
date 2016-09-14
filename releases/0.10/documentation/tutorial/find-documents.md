---
layout: default
major_version: "0.10"
title: Find Documents
---

## Find documents

> Note: the following snippets of code use a `BSONCollection` (the default collection implementation return by `db.collection()`).

### Performing a simple query

Queries are performed quite the same way as in the Mongo Shell.

{% highlight scala %}
val query = BSONDocument(
  "age" -> BSONDocument(
    "$gt" -> 27))

// result type is Future[List[BSONDocument]]
val peopleOlderThanTwentySeven = 
  collection.
    find(query). 
    cursor[BSONDocument].
    collect[List]()
{% endhighlight %}

Of course you can collect only a limited number of documents.

{% highlight scala %}
val peopleOlderThanTwentySeven = 
  collection.
    find(query). 
    cursor[BSONDocument].
    collect[List](25) // get up to 25 documents
{% endhighlight %}

The `find` method returns a [`BSONQueryBuilder`](http://reactivemongo.org/releases/0.9/api/index.html#reactivemongo.api.collections.default.BSONQueryBuilder) – the query is therefore not performed yet. It gives you the opportunity to add options to the query, like a sort order, projection, flags... When your query is ready to be sent to MongoDB, you may just call one of the following methods:
* `cursor` which returns a [`Cursor[BSONDocument]`](http://reactivemongo.org/releases/0.9/api/index.html#reactivemongo.api.Cursor)
* `one` wich returns a `Future[Option[BSONDocument]]` (the first document that matches the query, if any)

On a cursor, there are two interesting methods you can use to collect the results:
* `collect[List]()` which returns a future list of documents
* `enumerate()` which returns an `Enumerator` of documents (more on that later.)

The `collect` method must be given a Scala collection type, like `List` or `Vector`. It accumulates all the results in memory, as opposed to `enumerate`.

## Find and sort documents

The return type of the `find` method is a `GenericQueryBuilder`, which enables to customize the query, especially to add sort information. Like in the MongoDB console, you sort by giving a document containing the field names associated with an order (1 for ascending, -1 descending). Let's sort our previous query by lastName, in the alphabetical order (the sort document is also `{ lastName: 1 }`).

{% highlight scala %}
val peopleOlderThanTwentySeven = 
  collection.
    find(query).
    // sort by lastName 
    sort(BSONDocument("lastName" -> 1)). 
    cursor[BSONDocument].
    collect[List]()
{% endhighlight %}

### Use Readers to deserialize documents automatically

[As explained here](), you can use the `BSONDocumentReader` / `BSONDocumentWriter` typeclasses to handle de/serialization between `BSONDocument` and your model classes.

{% highlight scala %}
case class Person(id: BSONObjectID, firstName: String, lastName: String, age: Int)

object Person {
  implicit object PersonReader extends BSONDocumentReader[Person] {
    def read(doc: BSONDocument): Person = {
      val id = doc.getAs[BSONObjectID]("_id").get
      val firstName = doc.getAs[String]("firstName").get
      val lastName = doc.getAs[String]("lastName").get
      val age = doc.getAs[Int]("age").get

      Person(id, firstName, lastName, age)
    }
  }
}
{% endhighlight %}

This system is fully supported in the Collection API, so you can get the results of your queries in the right type.

{% highlight scala %}
// result type is Future[List[Person]]
val peopleOlderThanTwentySeven = 
  collection.
    find(query).
    /*
     * Indicate that the documents should be transformed into `Person`.
     * A `BSONDocumentReader[Person]` should be in the implicit scope.
     */
    cursor[Person].
    collect[List]()

peopleOlderThanTwentySeven.map { people =>
  for(person <- people) {
    val firstName = person.firstName
    println(s"found $firstName")
  }
}
{% endhighlight %}

