---
layout: default
major_version: 1.0
title: BSON Library Overview
---

## Overview of the ReactiveMongo BSON library

The Biːsən library of ReactiveMongo implements the [BSON format](http://bsonspec.org), or _Binary JSON_, which is used by MongoDB to encode data.

The library is designed with the following points in mind:

- Ease of use
- Strong typing
- Efficiency

It can be configured in a `build.sbt` as below.

```ocaml
libraryDependencies += "org.reactivemongo" %% "reactivemongo-bson-api" % "{{site._1_0_latest_minor}}"
```

*See [Scaladoc](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}})*

### Documents and values

There is one Scala class for each BSON type, all in the [`reactivemongo.api.bson` package](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/).

```scala
import scala.util.Try
import reactivemongo.api.bson._

val bsonDouble = BSONDouble(12.34D)

val bsonStr = BSONString("foo")

val bsonInt = BSONInteger(2345)

// BSON array: [ 12.34, "foo", 2345 ]
val bsonArray = BSONArray(bsonDouble, bsonStr, bsonInt)

val bsonEmptyDoc: BSONDocument = BSONDocument.empty

/* BSON Document:
{
  'foo': 'bar',
  'lorem': 2,
  'values': [ 12.34, "foo", 2345 ],
  'nested': {
    'position': 1000,
    'score': 1.2
  }
}
*/
val bsonDoc = BSONDocument(
  "foo" -> "bar", // as BSONString
  "lorem" -> 2, // as BSONInteger
  "values" -> bsonArray,
  "nested" -> BSONDocument(
    "position" -> 1000,
    "score" -> 1.2D // as BSONDouble
  )
)

val bsonBin = BSONBinary(Array[Byte](0, 1, 2), Subtype.GenericBinarySubtype)
// See Subtype

val bsonObjectID = BSONObjectID.generate()

val bsonBool = BSONBoolean(true)

val bsonDateTime = BSONDateTime(System.currentTimeMillis())

val bsonRegex = BSONRegex("/foo/bar/", "g")

val bsonJavaScript = BSONJavaScript("lorem(0)")

val bsonJavaScriptWs = BSONJavaScriptWS("bar", BSONDocument("bar" -> 1))

val bsonTimestamp = BSONTimestamp(45678L)

val bsonLong = BSONLong(Long.MaxValue)

val bsonZeroDecimal = BSONDecimal.PositiveZero

val bsonDecimal: Try[BSONDecimal] =
  BSONDecimal.fromBigDecimal(BigDecimal("12.23"))

val bsonNull = BSONNull

val bsonMinKey = BSONMinKey

val bsonMaxKey = BSONMaxKey
```

#### Documents

A document is represented by `BSONDocument`, which is basically an immutable list of key-value pairs. Since it is the most used BSON type, one of the main focuses of the ReactiveMongo BSON library is to make manipulations of BSONDocument as easy as possible.

```scala
import reactivemongo.api.bson._

/* Document: {
  'title': 'Everybody Knows this is Nowhere',
  'releaseYear': 1969
} */
val album = BSONDocument(
  "title" -> "Everybody Knows this is Nowhere",
  "releaseYear" -> 1969)

val albumTitle = album.getAsOpt[String]("title")

albumTitle match {
  case Some(title) =>
    println(s"The title of this album is $title")

  case _           =>
    println("""This document does not contain a title 
(or title is not a BSONString)""")
}
```

The API for [`BSONDocument`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDocument.html) provides the function `getAsOpt` and `getAsTry` to get the field values, and `getOrElse`.

```scala
import scala.util.Try
import reactivemongo.api.bson._

def bar(doc: BSONDocument): Unit = {
  val i: Option[Int] = doc.getAsOpt[Int]("fieldNameInt")
  val d: Option[Double] = doc.getAsOpt[Double]("fieldNameDouble")
  val l: Try[Long] = doc.getAsTry[Long]("fieldNameLong")
  val s: Try[String] = doc.getAsTry[String]("fieldNameStr")

  val fallback: String = doc.getOrElse[String]("strField", "defaultValue")
  // Equivalent to: doc.getAsOpt[String]("strField").getOrElse("defaultValue")
}
```

Field utilities are provided for the most common types:

```scala
import reactivemongo.api.bson._

def foo(doc: BSONDocument): Unit = {
  val i: Option[Int] = doc.int("fieldNameInt")
  val d: Option[Double] = doc.double("fieldNameDouble")
  val l: Option[Long] = doc.long("fieldNameLong")
  val s: Option[String] = doc.string("fieldNameStr")
  val a: Option[Seq[BSONValue]] = doc.array("fieldNameArr")
  val b: Option[Boolean] = doc.booleanLike("fieldNameBool")
  val c: Option[BSONDocument] = doc.child("nestedDoc")
  val _: List[BSONDocument] = doc.children("arrayOfDocs")
}
```

#### Numeric & Boolean values

The traits [`BSONNumberLike`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONNumberLike.html) and [`BSONBooleanLike`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONBooleanLike.html) are also kept in the new API, to generalize the handling of numerical and boolean values.

```scala
import scala.util.Try
import reactivemongo.api.bson._

val doc = BSONDocument("ok" -> 1.0D /* BSON double */ )

val bsonNumLike: Try[BSONNumberLike] = doc.getAsTry[BSONNumberLike]("ok")
val intLike: Try[Int] = bsonNumLike.flatMap(_.toInt) // =Success(1)

val bsonBoolLike: Try[BSONBooleanLike] = doc.getAsTry[BSONBooleanLike]("ok")
val boolLike: Try[Boolean] = bsonBoolLike.flatMap(_.toBoolean) // =Success(true)
```

Now `Float` is handled as a BSON double (as `Double`, as it's now possible to have several Scala types corresponding to the same BSON type).

The [Decimal128](https://github.com/mongodb/specifications/blob/master/source/bson-decimal128/decimal128.rst) type introduced by MongoDB 3.4 is also supported, as [`BSONDecimal`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDecimal.html), and can be read or write as `java.math.BigDecimal`.

```scala
import scala.util.Try
import reactivemongo.api.bson._

def readFloat(
  doc: BSONDocument,
  n: String
)(implicit r: BSONReader[Float]): Try[Float] = doc.getAsTry[Float](n)
```

Still to make the API simpler, the BSON singleton types (e.g. `BSONNull`) are also defined with a trait, to be able to reference them without `.type` suffix.

```scala
import reactivemongo.api.bson.BSONNull

def useNullBefore(bson: BSONNull.type) = println(".type was required")

def useNullNow(bson: BSONNull) = print("Suffix no longer required")
```

#### Binary values

The `BSONBinary` extractor now only bind subtype:

```scala
import reactivemongo.api.bson.{ BSONBinary, Subtype }

def binExtractor = {
  BSONBinary(Array[Byte](0, 1, 2), Subtype.GenericBinarySubtype) match {
    case genBin @ BSONBinary(Subtype.GenericBinarySubtype) =>
      genBin.byteArray

    case _ => ???
  }
}
```

#### Miscellaneous

- Type `BSONArray` is no longer an `ElementProducer` (only a value producer).
- The function `BSONObjectID.valueAsArray` is renamed to `byteArray`.
- The deprecated type `BSONDBPointer` is removed.
- The scope property is now supported by `BSONJavascriptWS`

#### Summary

| BSON | Description | JVM type |
| ---- | ----------- | -------- |
| [BSONBinary](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONBinary.html) | binary data | `Array[Byte]` |
| [BSONBoolean](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONBoolean.html) | boolean | `Boolean` |
| [BSONDateTime](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDateTime.html) | UTC Date Time | `java.util.Date` |
| [BSONDecimal](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDecimal$.html) | [Decimal128](https://github.com/mongodb/specifications/blob/master/source/bson-decimal128/decimal128.rst) | `java.math.BigDecimal` |
| [BSONDouble](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDouble.html) | 64-bit IEEE 754 floating point | `Double` |
| [BSONInteger](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONInteger.html) | 32-bit integer | `Int` |
| [BSONJavaScript](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONJavaScript.html) | JavaScript code | _None_ |
| [BSONJavaScriptWS](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONJavaScriptWS.html) | JavaScript scoped code | _None_ |
| [BSONLong](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONLong.html) | 64-bit integer | `Long` |
| [BSONMaxKey](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONMaxKey$.html) | max key | _None_ |
| [BSONMinKey](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONMinKey$.html) | min key | _None_ |
| [BSONNull](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONNull$.html) | null | _None_ |
| [BSONObjectID](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONObjectID.html) | [12 bytes default id type in MongoDB](http://docs.mongodb.org/manual/reference/object-id/) | _None_ |
| [BSONRegex](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONRegex.html) | regular expression | _None_ |
| [BSONString](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONString.html) | UTF-8 string | `String` |
| [BSONSymbol](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONSymbol.html) | _deprecated in the protocol_ | _None_ |
| [BSONTimestamp](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONTimestamp.html) | special date type used in MongoDB internals | _None_ |
| [BSONUndefined](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONUndefined$.html) | _deprecated in the protocol_ | _None_ |

All these classes extend [BSONValue](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONValue.html).

[Next: The readers and writers](typeclasses.html)