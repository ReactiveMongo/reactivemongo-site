---
layout: default
title: ReactiveMongo 0.11 - The ReactiveMongo BSON Library
---

## The ReactiveMongo BSON Library

Every BSON type has its matching class or object in [ReactiveMongo](../../api/index.html#reactivemongo.bson.package).

For example:

- [`BSONString`](../../api/index.html#reactivemongo.bson.BSONString) for strings
- [`BSONDouble`](../../api/index.html#reactivemongo.bson.BSONDouble) for double values
- [`BSONInteger`](../../api/index.html#reactivemongo.bson.BSONInteger) for integer
- [`BSONLong`](../../api/index.html#reactivemongo.bson.BSONLong) for long values
- [`BSONObjectID`](../../api/index.html#reactivemongo.bson.BSONObjectID) for MongoDB ObjectIds
- [`BSONDocument`](../../api/index.html#reactivemongo.bson.BSONDocument) for MongoDB documents
- [`BSONArray`](../../api/index.html#reactivemongo.bson.BSONArray) for MongoDB Arrays
- [`BSONBinary`](../../api/index.html#reactivemongo.bson.BSONBinary) for binary values (raw binary arrays stored in the document)
- etc.

All this classes or objects extend the trait [`BSONValue`](../../api/index.html#reactivemongo.bson.BSONValue).

You can build documents with the `BSONDocument` class. It accepts tuples of `String` and `BSONValue`.

Let's build a very simple document representing an album.

{% highlight scala %}
import reactivemongo.bson._

val album = BSONDocument(
  "title" -> BSONString("Everybody Knows this is Nowhere"),
  "releaseYear" -> BSONInteger(1969))
{% endhighlight %}

You can read a `BSONDocument` using the `getAs` method, which will return an `Option[String]` whether the requested field is present or not.

{% highlight scala %}
val albumTitle = album.getAs[String]("title")
albumTitle match {
  case Some(title) => println(s"The title of this album is $title")
  case _           => println("this document does not contain a title (or title is not a BSONString)")
}
{% endhighlight %}

[Next: The readers and writers](typeclasses.html)