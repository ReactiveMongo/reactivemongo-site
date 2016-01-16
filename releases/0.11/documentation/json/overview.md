---
layout: default
title: ReactiveMongo 0.11 - Play JSON support
---

This [Play JSON library](https://github.com/reactivemongo/reactivemongo-play-json) provides a JSON serialization pack for ReactiveMongo, based on [Play Framework JSON library](https://www.playframework.com/documentation/latest/ScalaJson).

## Setup

You can setup this serialization pack by adding the following dependency in your `project/Build.scala` (or `build.sbt`).

{% highlight ocaml %}
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo-play-json" % "{{site._0_11_latest_minor}}"
)
{% endhighlight %}

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo-play-json_2.11/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo-play-json_2.11/)

## Documents and values

There is one Play JSON class for most of the BSON types, all in the [`play.api.libs.json` package](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.package):

All these JSON types extend [`JsValue`](https://www.playframework.com/documentation/2.4.x/api/scala/index.html#play.api.libs.json.JsValue), thus any JSON value can be converted to appropriate [BSON value](../../api/reactivemongo/bson/BSONValue.html):

| BSON | JSON |
| -----| ---- |
| [BSONDocument](../../api/reactivemongo/bson/BSONDocument.html) | [JsObject](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsObject) |
| [BSONArray](../../api/reactivemongo/bson/BSONArray.html) | [JsArray](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsArray) |
| [BSONBinary](../../api/reactivemongo/bson/BSONBinary.html) | `JsObject` with a `$binary` `JsString` field containing the value in hexadecimal representation |
| [BSONBoolean](../../api/reactivemongo/bson/BSONBoolean.html) | [JsBoolean](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsBoolean) |
| [BSONDBPointer](../../api/reactivemongo/bson/BSONDBPointer.html) | *No JSON type* |
| [BSONDateTime](../../api/reactivemongo/bson/BSONDateTime.html) | `JsObject` with a `$date` `JsNumber` field with the timestamp (milliseconds) as value |
| [BSONDouble](../../api/reactivemongo/bson/BSONDouble.html) | [JsNumber](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsNumber) |
| [BSONInteger](../../api/reactivemongo/bson/BSONInteger.html) | `JsNumber` |
| [BSONJavaScript](../../api/reactivemongo/bson/BSONJavaScript.html) | `JsObject` with a `$javascript` `JsString` value representing the [JavaScript code](../../api/reactivemongo/bson/BSONJavaScript.html@value:String) |
| [BSONLong](../../api/reactivemongo/bson/BSONLong.html) | `JsNumber` |
| [BSONMaxKey](../../api/reactivemongo/bson/BSONMaxKey$.html) | *No JSON type* |
[BSONMinKey](../../api/reactivemongo/bson/BSONMinKey$.html) | *No JSON type* |
| [BSONNull](../../api/reactivemongo/bson/BSONNull$.html) | *No JSON type* |
| [BSONObjectID](../../api/reactivemongo/bson/BSONObjectID.html) | `JsObject` with a `$oid` `JsString` field with the stringified ID as value |
[BSONRegex](../../api/reactivemongo/bson/BSONRegex.html) | `JsObject` with a `$regex` `JsString` field with the regular expression, and optionally an `$options` `JsString` field with the regex flags (e.g. `"i"` for case insensitive) |
| [BSONString](../../api/reactivemongo/bson/BSONString.html) | [JsString](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsString) |
| [BSONSymbol](../../api/reactivemongo/bson/BSONSymbol.html) | `JsObject` with a `$symbol` `JsString` field with the symbol name as value |
| [BSONTimestamp](../../api/reactivemongo/bson/BSONTimestamp.html) | `JsObject` with a `$time` and a `$i` `JsNumber` fields |
| [BSONUndefined](../../api/reactivemongo/bson/BSONUndefined$.html) | *No JSON type* |

Furthermore, the whole library is articulated around the concept of [`Writes`](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.Writes) and [`Reads`](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.Reads). These are type classes which purpose is to serialize/deserialize objects of arbitraty types into/from JSON.

Consequently, any type that can be serialized as JSON can be also be serialized as BSON.

A document is represented by `JsObject`, which is basically an immutable list of key-value pairs. Since it is the most used JSON type, one of the main focuses of the ReactiveMongo Play JSON library is to manage such `JsObject`s as easy as possible. The encode of such JSON object needs an instance of the typeclass [`OWrites`](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.OWrites).