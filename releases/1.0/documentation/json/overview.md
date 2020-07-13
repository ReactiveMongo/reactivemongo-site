---
layout: default
major_version: 1.0
title: Play JSON support
---

The [ReactiveMongo Play JSON](https://github.com/reactivemongo/reactivemongo-play-json) library provides a JSON serialization pack for ReactiveMongo, based on the [Play Framework JSON library](https://www.playframework.com/documentation/latest/ScalaJson).

<!-- TODO:

 https://gist.github.com/cchantep/3da3ab798802e433ec9f7a35d8bd1140
https://groups.google.com/forum/#!msg/reactivemongo/-2fa1Cp2OzM/xQreqBovBAAJ

-->

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

All these JSON types extend [`JsValue`](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsValue), thus any JSON value can be converted to an appropriate [BSON value](../../api/reactivemongo/bson/BSONValue.html).

This serialization is based on the [MongoDB Extension JSON](https://docs.mongodb.com/manual/reference/mongodb-extended-json/) syntax (e.g. `{ "$oid": "<id>" }` for a Object ID):

| BSON | JSON |
| -----| ---- |
| [BSONDocument](../../api/reactivemongo/bson/BSONDocument.html) | [JsObject](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsObject) |
| [BSONArray](../../api/reactivemongo/bson/BSONArray.html) | [JsArray](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsArray) |
| [BSONBinary](../../api/reactivemongo/bson/BSONBinary.html) | `JsObject` with a `$binary` `JsString` field containing the value in hexadecimal representation |
| [BSONBoolean](../../api/reactivemongo/bson/BSONBoolean.html) | [JsBoolean](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsBoolean) |
| [BSONDBPointer](../../api/reactivemongo/bson/BSONDBPointer.html) | *No JSON type* |
| [BSONDateTime](../../api/reactivemongo/bson/BSONDateTime.html) | `JsObject` with a `$date` `JsNumber` field with the timestamp (milliseconds) as value |
| [BSONDouble](../../api/reactivemongo/bson/BSONDouble.html) | [JsNumber](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsNumber) or `JsObject` with `$numberDouble` value |
| [BSONInteger](../../api/reactivemongo/bson/BSONInteger.html) | `JsNumber` or `JsObject` with `$numberInt` value |
| [BSONJavaScript](../../api/reactivemongo/bson/BSONJavaScript.html) | `JsObject` with a `$javascript` `JsString` value representing the [JavaScript code](../../api/reactivemongo/bson/BSONJavaScript#value:String) |
| [BSONLong](../../api/reactivemongo/bson/BSONLong.html) | `JsNumber` or `JsObject` with `$numberLong` value |
| [BSONMaxKey](../../api/reactivemongo/bson/BSONMaxKey$.html) | `JsObject` as constant `{ "$maxKey": 1 }` |
[BSONMinKey](../../api/reactivemongo/bson/BSONMinKey$.html) | `JsObject` as constant `{ "$minKey": 1 }` |
| [BSONNull](../../api/reactivemongo/bson/BSONNull$.html) | *No JSON type* |
| [BSONObjectID](../../api/reactivemongo/bson/BSONObjectID.html) | `JsObject` with a `$oid` `JsString` field with the stringified ID as value |
[BSONRegex](../../api/reactivemongo/bson/BSONRegex.html) | `JsObject` with a `$regex` `JsString` field with the regular expression, and optionally an `$options` `JsString` field with the regex flags (e.g. `"i"` for case insensitive) |
| [BSONString](../../api/reactivemongo/bson/BSONString.html) | [JsString](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsString) |
| [BSONSymbol](../../api/reactivemongo/bson/BSONSymbol.html) | `JsObject` with a `$symbol` `JsString` field with the symbol name as value |
| [BSONTimestamp](../../api/reactivemongo/bson/BSONTimestamp.html) | `JsObject` with a `$timestamp` nested object having a `t` and a `i` `JsNumber` fields |
| [BSONUndefined](../../api/reactivemongo/bson/BSONUndefined$.html) | `JsObject` of the form `{ "$undefined": true }` |

Furthermore, the whole library is articulated around the concept of [`Writes`](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.Writes) and [`Reads`](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.Reads). These are typeclasses whose purpose is to serialize/deserialize objects of arbitrary types into/from JSON.

Using that, any type that can be serialized as JSON can be also be serialized as BSON.

A document is represented by `JsObject`, which is basically an immutable list of key-value pairs. Since it is the most used JSON type when working with MongoDB, the ReactiveMongo Play JSON library handles such `JsObject`s as seamless as possible. The encoding of such JSON object needs an instance of the typeclass [`OWrites`](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.OWrites) (a `Writes` specialized for object).

The default JSON serialization can also be customized, using the functions [`BSONFormats.readAsBSONValue`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo-play-json_{{site._1_0_scala_major}}-{{site._1_0_latest_minor}}-javadoc.jar/!/index.html#reactivemongo.play.json.BSONFormats$@readAsBSONValue(json:play.api.libs.json.JsValue)(implicitstring:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONString],implicitobjectID:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONObjectID],implicitjavascript:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONJavaScript],implicitdateTime:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONDateTime],implicittimestamp:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONTimestamp],implicitbinary:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONBinary],implicitregex:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONRegex],implicitdouble:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONDouble],implicitinteger:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONInteger],implicitlong:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONLong],implicitboolean:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONBoolean],implicitminKey:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONMinKey.type],implicitmaxKey:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONMaxKey.type],implicitbnull:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONNull.type],implicitsymbol:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONSymbol],implicitarray:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONArray],implicitdoc:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONDocument],implicitundef:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONUndefined.type]):play.api.libs.json.JsResult[reactivemongo.api.bson.BSONValue]) and [`BSONFormats.writeAsJsValue`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo-play-json_{{site._1_0_scala_major}}-{{site._1_0_latest_minor}}-javadoc.jar/!/index.html#reactivemongo.play.json.BSONFormats$@writeAsJsValue(bson:reactivemongo.api.bson.BSONValue)(implicitstring:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONString],implicitobjectID:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONObjectID],implicitjavascript:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONJavaScript],implicitdateTime:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONDateTime],implicittimestamp:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONTimestamp],implicitbinary:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONBinary],implicitregex:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONRegex],implicitdouble:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONDouble],implicitinteger:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONInteger],implicitlong:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONLong],implicitboolean:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONBoolean],implicitminKey:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONMinKey.type],implicitmaxKey:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONMaxKey.type],implicitbnull:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONNull.type],implicitsymbol:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONSymbol],implicitarray:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONArray],implicitdoc:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONDocument],implicitundef:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONUndefined.type]):play.api.libs.json.JsValue).

<!-- TODO: compat -->

<!-- TODO: Troubleshot

could not find implicit value for parameter e: reactivemongo.api.bson.BSONDocumentWriter[play.api.libs.json.JsObject]
~> import reactivemongo.play.json.compat._, json2bson._

Implicit not found for '..': reactivemongo.api.bson.BSONReader[play.api.libs.json.JsObject]
~> import reactivemongo.play.json.compat._, json2bson._

Implicit not found for '..': reactivemongo.api.bson.BSONReader[play.api.libs.json.JsValue]
~> import reactivemongo.play.json.compat._, json2bson._

Implicit not found for '..': reactivemongo.api.bson.BSONWriter[play.api.libs.json.JsValue]
~> import reactivemongo.play.json.compat.json2bson._

JsError(List((,List(JsonValidationError(List(Fails to handle _id: BSONString != BSONObjectID),WrappedArray())))))
~> redefined BSONReader with lax
-->

[Next: Integration with Play Framework](../tutorial/play.html)
