---
layout: default
major_version: 1.0
title: Play JSON support
---

The [ReactiveMongo Play JSON](https://github.com/reactivemongo/reactivemongo-play-json) library provides a JSON serialization pack for ReactiveMongo, based on the [Play Framework JSON library](https://www.playframework.com/documentation/latest/ScalaJson).

## Setup

You can setup the Play JSON compatibility for ReactiveMongo by adding the following dependency in your `project/Build.scala` (or `build.sbt`).

{% highlight ocaml %}
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo-play-json-compat" % "{{site._1_0_latest_minor}}-play27" // For Play 2.7.x (ajust accordingly)
)
{% endhighlight %}

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo-play-json_{{site._1_0_scala_major}}/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo-play-json_{{site._1_0_scala_major}}/) 
[![Build Status](https://travis-ci.org/ReactiveMongo/ReactiveMongo-Play-Json.svg?branch=master)](https://travis-ci.org/ReactiveMongo/ReactiveMongo-Play-Json) 
[![Test coverage](https://img.shields.io/badge/coverage-69%25-green.svg)](https://reactivemongo.github.io/ReactiveMongo-Play-Json/coverage/{{site._1_0_latest_minor}}/)

> If the dependency for the [Play plugin](../tutorial/play.html) (with the right version) is present, it already provides the JSON support and this JSON serialization pack must not be added as a separate dependency.

The following import enables the compatibility.

{% highlight scala %}
import reactivemongo.play.json.compat._
{% endhighlight %}

Then JSON values can be converted to BSON, and it's possible to convert BSON values to JSON.

{% highlight scala %}
import play.api.libs.json.JsValue
import reactivemongo.api.bson.BSONValue

import reactivemongo.play.json.compat._

def foo(v: BSONValue): JsValue = v // ValueConverters.fromValue
{% endhighlight %}

**API documentations:** [ReactiveMongo Play JSON API](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}-play27/reactivemongo-play-json_{{site._1_0_scala_major}}-{{site._1_0_latest_minor}}-play27-javadoc.jar/!/index.html)

> If you want to use this JSON serialization outside of Play application, the dependency to the standalone Play JSON library must then be added: `"com.typesafe.play" %% "play-json" % version`.

## Documents and values

There is one Play JSON class for most of the BSON types, from the [`play.api.libs.json` package](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.package):

All these JSON types extend [`JsValue`](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsValue), thus any JSON value can be converted to an appropriate [BSON value](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONValue.html).

The default serialization is based on the [MongoDB Extension JSON](https://docs.mongodb.com/manual/reference/mongodb-extended-json/) syntax (e.g. `{ "$oid": "<id>" }` for a Object ID):

| BSON | JSON |
| -----| ---- |
| [BSONDocument](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDocument.html) | [JsObject](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsObject) |
| [BSONArray](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONArray.html) | [JsArray](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsArray) |
| [BSONBinary](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONBinary.html) | `JsObject` with a `$binary` `JsString` field containing the value in hexadecimal representation |
| [BSONBoolean](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONBoolean.html) | [JsBoolean](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsBoolean) |
| [BSONDBPointer](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDBPointer.html) | *No JSON type* |
| [BSONDateTime](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDateTime.html) | `JsObject` with a `$date` `JsNumber` field with the timestamp (milliseconds) as value |
| [BSONDouble](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDouble.html) | [JsNumber](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsNumber) or `JsObject` with `$numberDouble` value |
| [BSONInteger](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONInteger.html) | `JsNumber` or `JsObject` with `$numberInt` value |
| [BSONJavaScript](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONJavaScript.html) | `JsObject` with a `$javascript` `JsString` value representing the [JavaScript code](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONJavaScript#value:String) |
| [BSONLong](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONLong.html) | `JsNumber` or `JsObject` with `$numberLong` value |
| [BSONMaxKey](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONMaxKey$.html) | `JsObject` as constant `{ "$maxKey": 1 }` |
[BSONMinKey](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONMinKey$.html) | `JsObject` as constant `{ "$minKey": 1 }` |
| [BSONNull](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONNull$.html) | *No JSON type* |
| [BSONObjectID](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONObjectID.html) | `JsObject` with a `$oid` `JsString` field with the stringified ID as value |
[BSONRegex](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONRegex.html) | `JsObject` with a `$regex` `JsString` field with the regular expression, and optionally an `$options` `JsString` field with the regex flags (e.g. `"i"` for case insensitive) |
| [BSONString](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONString.html) | [JsString](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsString) |
| [BSONSymbol](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONSymbol.html) | `JsObject` with a `$symbol` `JsString` field with the symbol name as value |
| [BSONTimestamp](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONTimestamp.html) | `JsObject` with a `$timestamp` nested object having a `t` and a `i` `JsNumber` fields |
| [BSONUndefined](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONUndefined$.html) | `JsObject` of the form `{ "$undefined": true }` |

## Handlers

Conversions are provided between JSON and BSON handlers.

Considering the following `User` class:

{% highlight scala %}
package object jsonsamples1 {
  import reactivemongo.api.bson._

  case class User(
    _id: BSONObjectID, // Rather use UUID or String
    username: String,
    role: String,
    created: BSONTimestamp, // Rather use Instance
    lastModified: BSONDateTime,
    sym: Option[BSONSymbol]) // Rather use String

  object User {
    implicit val bsonWriter: BSONDocumentWriter[User] = Macros.writer[User]

    implicit val bsonReader: BSONDocumentReader[User] = Macros.reader[User]
  }
}
{% endhighlight %}

The main import to use the handler conversions is:

{% highlight scala %}
import reactivemongo.play.json.compat._
{% endhighlight %}

Then specific imports are available to enable conversions, according the use cases.

{% highlight scala %}
import reactivemongo.play.json.compat._

// Conversions from BSON to JSON extended syntax
import bson2json._

// Override conversions with lax syntax
import lax._

// Conversions from JSON to BSON
import json2bson._
{% endhighlight %}

**Convert BSON to JSON extended syntax:**

*Scala:*

{% highlight scala %}
import _root_.play.api.libs.json._

import _root_.reactivemongo.api.bson._

// Global compatibility import:
import reactivemongo.play.json.compat._

// Import BSON to JSON extended syntax (default)
import bson2json._ // Required import

import jsonsamples1.User

val user1 = User(
  BSONObjectID.generate(), "lorem", "ipsum",
  created = BSONTimestamp(987654321L),
  lastModified = BSONDateTime(123456789L),
  sym = Some(BSONSymbol("foo")))

val userJs = Json.toJson(user1)

// Resolved from User.bsonReader
val jsonReader = implicitly[Reads[User]]

userJs.validate[User](jsonReader)
// => JsSuccess(user1)

// Resolved from User.bsonWriter
val jsonWriter: OWrites[User] = implicitly[OWrites[User]]

jsonWriter.writes(user1) // => userJs
{% endhighlight %}

*JSON output:* (`userJs`)

{% highlight javascript %}
{
  "_id": {"$$oid":"..."},
  "username": "lorem",
  "role": "ipsum",
  "created": {
    "$$timestamp": {"t":0,"i":987654321}
          },
  "lastModified": {
    "$$date": {"$$numberLong":"123456789"}
          },
  "sym": {
    "$$symbol":"foo"
  }
}
{% endhighlight %}

**Convert BSON to JSON lax syntax:**

*Scala:*

{% highlight scala %}
import _root_.play.api.libs.json._

import _root_.reactivemongo.api.bson._

// Global compatibility import:
import reactivemongo.play.json.compat._

// Import BSON to JSON extended syntax (default)
import bson2json._ // Required import

// Import lax overrides
import lax._

import jsonsamples1.User

val user2 = User(
  BSONObjectID.generate(), "lorem", "ipsum",
  created = BSONTimestamp(987654321L),
  lastModified = BSONDateTime(123456789L),
  sym = Some(BSONSymbol("foo")))

// Overrides BSONWriters for OID/Timestamp/DateTime
// so that the BSON representation matches the JSON lax one
implicit val bsonWriter: BSONDocumentWriter[User] = Macros.writer[User]

// Resolved from bsonWriter
val laxJsonWriter: OWrites[User] = implicitly[OWrites[User]]

val laxUserJs = laxJsonWriter.writes(user2)

// Overrides BSONReaders for OID/Timestamp/DateTime
// so that the BSON representation matches the JSON lax one
implicit val laxBsonReader: BSONDocumentReader[User] =
  Macros.reader[User]

val laxJsonReader = implicitly[Reads[User]] // resolved from laxBsonReader

laxUserJs.validate[User](laxJsonReader)
// => JsSuccess(user2)
{% endhighlight %}

*JSON output:* (`userLaxJs`)

{% highlight javascript %}
{
  "_id": "...",
  "username": "lorem",
  "role": "ipsum",
  "created": 987654321,
  "lastModified": 123456789,
  "sym": "foo"
}
{% endhighlight %}

**Convert JSON to BSON:**

Considering the `Street` class:

{% highlight scala %}
package object jsonsamples2 {
 case class Street(
   number: Option[Int],
   name: String)
}
{% endhighlight %}

The BSON representation can be derived from the JSON as below.

{% highlight scala %}
import _root_.play.api.libs.json._
import _root_.reactivemongo.api.bson._

// Global compatibility import:
import reactivemongo.play.json.compat._

// Import JSON to BSON conversions
import json2bson._ // Required import

import jsonsamples2.Street

implicit val jsonFormat: OFormat[Street] = Json.format[Street]

// Expected BSON:
val doc = BSONDocument(
  "number" -> 1,
  "name" -> "rue de la lune")

val street = Street(Some(1), "rue de la lune")

// Resolved from jsonFormat
val bsonStreetWriter = implicitly[BSONDocumentWriter[Street]]

bsonStreetWriter.writeTry(street)
/* Success: doc = {
  'number': 1,
  'name': 'rue de la lune'
} */

// Resolved from jsonFormat
val bsonStreetReader = implicitly[BSONDocumentReader[Street]]

bsonStreetReader.readTry(doc)
// Success: street
{% endhighlight %}

**Value converters:**

Using that, any type that can be serialized as JSON can be also be serialized as BSON.

A document is represented by `JsObject`, which is basically an immutable list of key-value pairs. Since it is the most used JSON type when working with MongoDB, the ReactiveMongo Play JSON library handles such `JsObject`s as seamless as possible. The encoding of such JSON object needs an instance of the typeclass [`OWrites`](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.OWrites) (a `Writes` specialized for object).

## Troubleshooting

**Missing `json2bson`:** If any of the following errors, then add the imports as below.

{% highlight scala %}
import reactivemongo.play.json.compat.json2bson._
{% endhighlight %}

*Errors:*

{% highlight text %}
Implicit not found for '..': reactivemongo.api.bson.BSONReader[play.api.libs.json.JsObject]

Implicit not found for '..': reactivemongo.api.bson.BSONReader[play.api.libs.json.JsValue]

Implicit not found for '..': reactivemongo.api.bson.BSONWriter[play.api.libs.json.JsValue]

could not find implicit value for parameter writer: reactivemongo.api.bson.BSONDocumentWriter[AnyTypeProvideWithOWrites]
{% endhighlight %}

**Missing `JsObject` writer:**

{% highlight text %}
could not find implicit value for parameter e: reactivemongo.api.bson.BSONDocumentWriter[play.api.libs.json.JsObject]
{% endhighlight %}

{% highlight scala %}
import reactivemongo.play.json.compat.jsObjectWrites
{% endhighlight %}

**Lax:**

{% highlight scala %}
import reactivemongo.play.json.compat._,
  json2bson._, lax._
{% endhighlight %}

*Errors:*

{% highlight text %}
JsError(List((,List(JsonValidationError(List(Fails to handle _id: BSONString != BSONObjectID),WrappedArray())))))
{% endhighlight %}

[Next: Integration with Play Framework](../tutorial/play.html)
