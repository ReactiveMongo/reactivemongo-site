---
layout: default
major_version: 0.12
title: Play JSON support
---

The [ReactiveMongo Play JSON](https://github.com/reactivemongo/reactivemongo-play-json) library provides a JSON serialization pack for ReactiveMongo, based on the [Play Framework JSON library](https://www.playframework.com/documentation/latest/ScalaJson).

## Setup

You can setup this serialization pack by adding the following dependency in your `project/Build.scala` (or `build.sbt`).

{% highlight ocaml %}
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo-play-json" % "{{site._0_12_latest_minor}}"
)
{% endhighlight %}

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo-play-json_2.11/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo-play-json_2.11/) 
[![Build Status](https://travis-ci.org/ReactiveMongo/ReactiveMongo-Play-Json.svg?branch=master)](https://travis-ci.org/ReactiveMongo/ReactiveMongo-Play-Json) 
[![Test coverage](https://img.shields.io/badge/coverage-69%25-green.svg)](https://reactivemongo.github.io/ReactiveMongo-Play-Json/coverage/{{site._0_12_latest_minor}}/)

> If the dependency for the [Play plugin](../tutorial/play.html) (with the right version) is present, it already provides the JSON support and this JSON serialization pack must not be added as a separate dependency.

Then, the following code enables this JSON serialization pack.

{% highlight scala %}
import reactivemongo.play.json._
{% endhighlight %}

**API documentations:** [Play JSON API](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_2.11/{{site._0_12_latest_minor}}/reactivemongo-play-json_2.11-{{site._0_12_latest_minor}}-javadoc.jar/!/index.html)

## Documents and values

There is one Play JSON class for most of the BSON types, from the [`play.api.libs.json` package](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.package):

All these JSON types extend [`JsValue`](https://www.playframework.com/documentation/latest/api/scala/index.html#play.api.libs.json.JsValue), thus any JSON value can be converted to an appropriate [BSON value](../../api/reactivemongo/bson/BSONValue.html):

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
| [BSONJavaScript](../../api/reactivemongo/bson/BSONJavaScript.html) | `JsObject` with a `$javascript` `JsString` value representing the [JavaScript code](../../api/index.html#reactivemongo.bson.BSONJavaScript@value:String) |
| [BSONLong](../../api/reactivemongo/bson/BSONLong.html) | `JsNumber` |
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

This library provides a specialized collection called [`JSONCollection`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_2.11/{{site._0_12_latest_minor}}/reactivemongo-play-json_2.11-{{site._0_12_latest_minor}}-javadoc.jar/!/index.html#reactivemongo.play.json.collection.JSONCollection) that deals naturally with `JsValue` and `JsObject`. Thanks to it, you can fetch documents from MongoDB in the Play JSON format, transform them by removing and/or adding some properties, and send them to the client.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }
import play.api.libs.json._
import reactivemongo.play.json._, collection._

def jsonFind(coll: JSONCollection)(implicit ec: ExecutionContext): Future[List[JsObject]] =
  coll.find(Json.obj()).sort(Json.obj("updated" -> -1)).
    cursor[JsObject]().collect[List]()
{% endhighlight %}

Even better, when a client sends a JSON document, you can validate it and transform it before saving it into a MongoDB collection (coast-to-coast approach).

## JSON cursors

The support of Play JSON for ReactiveMongo provides some extensions of the result cursors, as `.jsArray()` to read underlying data as a JSON array.

{% highlight scala %}
import scala.concurrent.Future

import play.api.libs.json._
import play.api.libs.concurrent.Execution.Implicits.defaultContext

import reactivemongo.play.json._
import reactivemongo.play.json.collection.{
  JSONCollection, JsCursor
}, JsCursor._

def jsAll(collection: JSONCollection): Future[JsArray] = {
  type ResultType = JsObject // any type which is provided a `Writes[T]`

  collection.find(Json.obj()).cursor[ResultType].jsArray()
}
{% endhighlight %}

In the previous example, the function `jsAll` will return a JSON array containing all the documents of the given collection (as JSON objects).

## Helpers

There are some helpers coming along with the JSON support.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.play.json.collection._

// Import a list of JSON objects as documents into the JSON `collection`,
// and returns the insertion count.
def importJson(collection: JSONCollection, resource: String): Future[Int] =
  Helpers.bulkInsert(collection, getClass.getResourceAsStream(resource)).
    map(_.totalN)
{% endhighlight %}

As illustrated by the previous example, the function `Helpers.bulkInsert` provides a JSON import feature.

## Run a raw command

The [command API](../advanced-topics/commands.html) can be used with the JSON serialization to execution a JSON object as a raw command.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import play.api.libs.json.{ JsObject, Json }

import reactivemongo.play.json._
import reactivemongo.api.commands.Command

def rawResult(db: reactivemongo.api.DefaultDB)(implicit ec: ExecutionContext): Future[JsObject] = {
  val commandDoc = Json.obj(
    "aggregate" -> "orders", // we aggregate on collection `orders`
    "pipeline" -> List(
      Json.obj("$match" -> Json.obj("status" -> "A")),
      Json.obj(
        "$group" -> Json.obj(
          "_id" -> "$cust_id",
          "total" -> Json.obj("$sum" -> "$amount"))),
      Json.obj("$sort" -> Json.obj("total" -> -1))
    )
  )
  val runner = Command.run(JSONSerializationPack)

  runner.apply(db, runner.rawCommand(commandDoc)).one[JsObject]
}
{% endhighlight %}

## Troubleshooting

If the following error is raised;

    No Json serializer as JsObject found for type play.api.libs.json.JsObject.
    Try to implement an implicit OWrites or OFormat for this type.

It's necessary to make sure the right imports are there.

{% highlight scala %}
import reactivemongo.play.json._
// import the default BSON/JSON conversions
{% endhighlight %}

[Next: Integration with Play Framework](../tutorial/play.html)
