---
layout: default
major_version: 0.11
title: BSON Library Overview
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

[BSONBinary](../../api/reactivemongo/bson/BSONBinary.html): binary data

[BSONBoolean](../../api/reactivemongo/bson/BSONBoolean.html): boolean

[BSONDBPointer](../../api/reactivemongo/bson/BSONDBPointer.html): _deprecated in the protocol_

[BSONDateTime](../../api/reactivemongo/bson/BSONDateTime.html): UTC Date Time

[BSONDouble](../../api/reactivemongo/bson/BSONDouble.html): 64-bit IEEE 754 floating point

[BSONInteger](../../api/reactivemongo/bson/BSONInteger.html): 32-bit integer

[BSONJavaScript](../../api/reactivemongo/bson/BSONJavaScript.html): javascript code

[BSONJavaScriptWS](../../api/reactivemongo/bson/BSONJavaScriptWS.html): javascript scoped code

[BSONLong](../../api/reactivemongo/bson/BSONLong.html): 64-bit integer

[BSONMaxKey](../../api/reactivemongo/bson/BSONMaxKey$.html): max key

[BSONMinKey](../../api/reactivemongo/bson/BSONMinKey$.html): min key

[BSONNull](../../api/reactivemongo/bson/BSONNull$.html): null

[BSONObjectID](../../api/reactivemongo/bson/BSONObjectID.html): [12-bytes default id type in MongoDB](http://docs.mongodb.org/manual/reference/object-id/)

[BSONRegex](../../api/reactivemongo/bson/BSONRegex.html): regular expression

[BSONString](../../api/reactivemongo/bson/BSONString.html): UTF-8 string

[BSONSymbol](../../api/reactivemongo/bson/BSONSymbol.html): _deprecated in the protocol_

[BSONTimestamp](../../api/reactivemongo/bson/BSONTimestamp.html): special date type used in MongoDB internals

[BSONUndefined](../../api/reactivemongo/bson/BSONUndefined$.html): _deprecated in the protocol_

> See how to handle the [optional values](./typeclasses.html#optional-value).

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