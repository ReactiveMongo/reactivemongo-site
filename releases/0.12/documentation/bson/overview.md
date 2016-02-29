---
layout: default
title: ReactiveMongo 0.12 - BSON Library Overview
---

## Overview of the ReactiveMongo BSON library

The BSON library of ReactiveMongo implements the [BSON protocol](http://bsonspec.org), or _Binary JSON_, which is used by MongoDB to encode data. Because of that, when we use MongoDB we tend to manipulate a lot of BSON structures; thus the BSON library is designed with the following points in mind:

- ease of use
- strong typing
- efficiency

### Documents and values

There is one Scala class for each BSON type, all in the [`reactivemongo.bson` package](../../api/reactivemongo/bson/package.html).

[BSONDocument](../../api/reactivemongo/bson/BSONDocument.html): set of key-value pairs

{% highlight scala %}
import reactivemongo.bson._

// BSONDocument(BSONElement*)
val doc1 = BSONDocument("foo" -> BSONString("bar"))
val doc2 = BSONDocument("lorem" -> 1)
{% endhighlight %}

> Any type `T` for which a `BSONWriter[T, _]` is available can be used as value for a `BSONElement` in a `BSONDocument`, as in the `doc2` of the previous example (see [BSON typeclasses](./typeclasses.html)).

[BSONArray](../../api/reactivemongo/bson/BSONArray.html): sequence of values

{% highlight scala %}
import reactivemongo.bson._

val arr1 = BSONArray(BSONString("foo"), BSONString("bar"))
val arr2 = BSONArray("lorem", "ipsum")

val arrField = BSONDocument("array_field" -> List("written", "values"))
{% endhighlight %}

> As for `BSONDocument`, any type with a `BSONWriter` (see [provided handlers](./typeclasses.html#provided-handlers)) can be added to a `BSONArray` (see `arr2` in the previous example).
> Moreover, a [`Traversable[T]`](http://www.scala-lang.org/api/current/index.html#scala.collection.Traversable) whose element type `T` has a `BSONWriter[T, _]` can be used a BSON array (see `arrField` in the previous example).

| BSON | Description | JVM type |
| ---- | ----------- | -------- |
| [BSONBinary](../../api/reactivemongo/bson/BSONBinary.html) | binary data | `Array[Byte]` |
| [BSONBoolean](../../api/reactivemongo/bson/BSONBoolean.html) | boolean | `Boolean` |
| [BSONDBPointer](../../api/reactivemongo/bson/BSONDBPointer.html) | _deprecated in the protocol_ | _None_ |
| [BSONDateTime](../../api/reactivemongo/bson/BSONDateTime.html) | UTC Date Time | `java.util.Date` |
| [BSONDouble](../../api/reactivemongo/bson/BSONDouble.html) | 64-bit IEEE 754 floating point | `Double` |
| [BSONInteger](../../api/reactivemongo/bson/BSONInteger.html) | 32-bit integer | `Int` |
| [BSONJavaScript](../../api/reactivemongo/bson/BSONJavaScript.html) | Javascript code | _None_ |
| [BSONJavaScriptWS](../../api/reactivemongo/bson/BSONJavaScriptWS.html) | Javascript scoped code | _None_ |
| [BSONLong](../../api/reactivemongo/bson/BSONLong.html) | 64-bit integer | `Long` |
| [BSONMaxKey](../../api/reactivemongo/bson/BSONMaxKey$.html) | max key | _None_ |
| [BSONMinKey](../../api/reactivemongo/bson/BSONMinKey$.html) | min key | _None_ |
| [BSONNull](../../api/reactivemongo/bson/BSONNull$.html) | null | _None_ |
| [BSONObjectID](../../api/reactivemongo/bson/BSONObjectID.html) | [12-bytes default id type in MongoDB](http://docs.mongodb.org/manual/reference/object-id/) | _None_ |
| [BSONRegex](../../api/reactivemongo/bson/BSONRegex.html) | regular expression | _None_ |
| [BSONString](../../api/reactivemongo/bson/BSONString.html) | UTF-8 string | `String` |
| [BSONSymbol](../../api/reactivemongo/bson/BSONSymbol.html) | _deprecated in the protocol_ | _None_ |
| [BSONTimestamp](../../api/reactivemongo/bson/BSONTimestamp.html) | special date type used in MongoDB internals | _None_ |
| [BSONUndefined](../../api/reactivemongo/bson/BSONUndefined$.html) | _deprecated in the protocol_ | _None_ |

(See also [BSONNumberLike](../../api/reactivemongo/bson/BSONNumberLike.html) and [BSONBooleanLike](../../api/reactivemongo/bson/BSONBooleanLike.html)

All these classes extend [BSONValue](../../api/reactivemongo/bson/BSONValue.html).

A document is represented by `BSONDocument`. A `BSONDocument` is basically an immutable list of key-value pairs. Since it is the most used BSON type, one of the main focuses of the ReactiveMongo BSON library is to make manipulations of BSONDocuments as easy as possible.

{% highlight scala %}
import reactivemongo.bson._

val album = BSONDocument(
  "title" -> BSONString("Everybody Knows this is Nowhere"),
  "releaseYear" -> BSONInteger(1969))

val albumTitle = album.getAs[String]("title")
albumTitle match {
  case Some(title) => println(s"The title of this album is $title")
  case _           => println("this document does not contain a title (or title is not a BSONString)")
}
{% endhighlight %}

Furthermore, the whole library is articulated around the concept of [`BSONDocumentWriter`](../../api/reactivemongo/bson/BSONDocumentWriter.html) and [`BSONDocumentReader`](../../api/reactivemongo/bson/BSONDocumentReader.html).
These are type classes which purpose is to serialize/deserialize objects of arbitraty types into/from BSON. This makes usage of MongoDB much less verbose and more natural.

[Next: The readers and writers](typeclasses.html)