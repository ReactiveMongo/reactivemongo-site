---
layout: default
major_version: 0.1x
title: ReactiveMongo Biːsən
---

## ReactiveMongo Biːsən

These libraries are intended to replace (at some point after release 1.0) the [current BSON library](../bson/overview.html) (shipped along with ReactiveMongo driver).

The motivation for that is to fix some issues, to bring multiple API and performance improvements (simpler & better).

### BSON types and handlers

The main API library migrates both the BSON value types and the handler typeclasses.

It can be configured in a `build.sbt` as below.

{% highlight ocaml %}
libraryDependencies += "org.reactivemongo" %% "reactivemongo-bson-api" % "{{site._0_1x_latest_minor}}"
{% endhighlight %}

*See [Scaladoc](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}})*

#### Documents and values

The names of the BSON value types are the [same as the current BSON library](../bson/overview.html#documents-and-values), except the package that is `reactivemongo.api.bson` (instead of `reactivemongo.bson`).

{% highlight scala %}
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
{% endhighlight %}

The API for [`BSONDocument`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo/api/bson/BSONDocument.html) has been slightly updated, with the function `getAs` renamed as `getAsOpt` (to be consistent with `getAsTry`).

The traits [`BSONNumberLike`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo/api/bson/BSONNumberLike.html) and [`BSONBooleanLike`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo/api/bson/BSONBooleanLike.html) are also kept in the new API, to generalize the handling of numerical and boolean values.

{% highlight scala %}
import scala.util.Try
import reactivemongo.api.bson._

val doc = BSONDocument("ok" -> 1.0D /* BSON double */ )

val bsonNumLike: Try[BSONNumberLike] = doc.getAsTry[BSONNumberLike]("ok")
val intLike: Try[Int] = bsonNumLike.flatMap(_.toInt) // =Success(1)

val bsonBoolLike: Try[BSONBooleanLike] = doc.getAsTry[BSONBooleanLike]("ok")
val boolLike: Try[Boolean] = bsonBoolLike.flatMap(_.toBoolean) // =Success(true)
{% endhighlight %}

<!-- TODO: trait for constant type such as BSONNUll -->

#### Reader and writer typeclasses

As for the [current BSON library](../bson/typeclasses.html), the new API provides an extensible typeclass mechanism, to define how to get and set data as BSON in a typesafe way.

The names of these typeclasses are unchanged ([`BSONReader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo/api/bson/BSONReader.html) and [`BSONWriter`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo/api/bson/BSONWriter.html)), except the package that is `reactivemongo.api.bson` (instead of `reactivemongo.bson`).

In the current BSON library, `BSONReader` and `BSONWriter` are defined with two type parameters:

{% highlight ocaml %}
BSONReader[B <: BSONValue, T]

BSONWriter[T, B <: BSONValue]
{% endhighlight %}

- `B` being the type of BSON value to be read/written,
- and `T` being the Scala type to be handled.

The new API has been simplified, with only the `T` type parameter kept.

{% highlight scala %}
import reactivemongo.api.bson._

// read a String from BSON, whatever is the specific BSON value type
def stringReader: BSONReader[String] = ???
{% endhighlight %}

Not only it makes the API simpler, but it also allows to read different BSON types as a target Scala type (before only supported for numeric/boolean, using the dedicated typeclasses).
For example, the Scala numeric types (`BigDecimal`, `Double`, `Float`, `Int`, `Long`) can be directly read from any consistent BSON numeric type (e.g. `1.0` as integer `1`), without having to use `BSONNumberLike`.

<!-- TODO: BSON handler BSONDateTime Date => Instant; Java time handlers -->

The new API is also safer, replacing `BSONReader.read` and `BSONWriter.write` respectively with `BSONReader.readTry` and `BSONWriter.writeTry`, so that serialization errors can be handle at typelevel.

Like the current BSON library, some specific typeclasses are available (with same names) to read and write using BSON documents: `BSONDocumentReader` and `BSONDocumentWriter`.

<!-- TODO: BSONDocumentReader + .from factory (plus de trait) -->

The new library also provide similar macros, to easily materialized document readers and writers for Scala case classes and sealed traits.

{% highlight scala %}
case class Person(name: String, age: Int)

import reactivemongo.api.bson._

val personHandler: BSONDocumentHandler[Person] = Macros.handler[Person]

// Or only ...
val personReader: BSONDocumentReader[Person] = Macros.reader[Person]
val personWriter: BSONDocumentWriter[Person] = Macros.writer[Person]
{% endhighlight %}

<!-- TODO:
Improved macros: MacroOptions SaveSimpleName => MacroConfiguration
-->

<!-- TODO: Changelog

BSONIterator
serialization (OOM with reactivemongo.bson)
BSONArray no longer ElementProducer (only values)

BSONBinary.unapply only Subtype (no byte array)
BSONObjectID.valueAsArray => byteArray
DocumentKeyNotFoundException => BSONValueNotFoundException & improved exceptions more explicit

BSONObjectID parse => Try

TODO: BSONDocument varArg factory optimized and support more cases
-->