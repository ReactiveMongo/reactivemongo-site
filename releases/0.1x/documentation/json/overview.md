---
layout: default
major_version: 0.1x
title: Play JSON support
---

The [ReactiveMongo Play JSON](https://github.com/reactivemongo/reactivemongo-play-json) library provides a JSON serialization pack for ReactiveMongo, based on the [Play Framework JSON library](https://www.playframework.com/documentation/latest/ScalaJson).

## Setup

You can setup this serialization pack by adding the following dependency in your `project/Build.scala` (or `build.sbt`).

```ocaml
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo-play-json" % "{{site._0_1x_latest_minor}}-play27"
)
```

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo-play-json_{{site._0_1x_scala_major}}/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo-play-json_{{site._0_1x_scala_major}}/) 
[![Build Status](https://travis-ci.org/ReactiveMongo/ReactiveMongo-Play-Json.svg?branch=master)](https://travis-ci.org/ReactiveMongo/ReactiveMongo-Play-Json) 
[![Test coverage](https://img.shields.io/badge/coverage-69%25-green.svg)](https://reactivemongo.github.io/ReactiveMongo-Play-Json/coverage/{{site._0_1x_latest_minor}}/)

> If the dependency for the [Play plugin](../tutorial/play.html) (with the right version) is present, it already provides the JSON support and this JSON serialization pack must not be added as a separate dependency.

Then, the following code enables this JSON serialization pack.

```scala
import reactivemongo.play.json._
```

**API documentations:** [ReactiveMongo Play JSON API](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}-play27/reactivemongo-play-json_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-play27-javadoc.jar/!/index.html)

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

The default JSON serialization can also be customized, using the functions [`BSONFormats.readAsBSONValue`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-play-json_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/index.html#reactivemongo.play.json.BSONFormats$@readAsBSONValue(json:play.api.libs.json.JsValue)(implicitstring:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONString],implicitobjectID:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONObjectID],implicitjavascript:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONJavaScript],implicitdateTime:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONDateTime],implicittimestamp:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONTimestamp],implicitbinary:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONBinary],implicitregex:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONRegex],implicitdouble:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONDouble],implicitinteger:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONInteger],implicitlong:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONLong],implicitboolean:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONBoolean],implicitminKey:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONMinKey.type],implicitmaxKey:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONMaxKey.type],implicitbnull:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONNull.type],implicitsymbol:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONSymbol],implicitarray:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONArray],implicitdoc:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONDocument],implicitundef:BSONFormats.this.PartialReads[reactivemongo.api.bson.BSONUndefined.type]):play.api.libs.json.JsResult[reactivemongo.api.bson.BSONValue]) and [`BSONFormats.writeAsJsValue`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-play-json_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/index.html#reactivemongo.play.json.BSONFormats$@writeAsJsValue(bson:reactivemongo.api.bson.BSONValue)(implicitstring:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONString],implicitobjectID:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONObjectID],implicitjavascript:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONJavaScript],implicitdateTime:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONDateTime],implicittimestamp:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONTimestamp],implicitbinary:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONBinary],implicitregex:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONRegex],implicitdouble:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONDouble],implicitinteger:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONInteger],implicitlong:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONLong],implicitboolean:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONBoolean],implicitminKey:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONMinKey.type],implicitmaxKey:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONMaxKey.type],implicitbnull:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONNull.type],implicitsymbol:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONSymbol],implicitarray:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONArray],implicitdoc:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONDocument],implicitundef:BSONFormats.this.PartialWrites[reactivemongo.api.bson.BSONUndefined.type]):play.api.libs.json.JsValue).

## JSON collections

This library provides a specialized collection reference called [`JSONCollection`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-play-json_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/index.html#reactivemongo.play.json.collection.JSONCollection) that deals naturally with `JsValue` and `JsObject`. Thanks to it, you can fetch documents from MongoDB in the Play JSON format, transform them by removing and/or adding some properties, and send them to the client.

```scala
import scala.concurrent.{ ExecutionContext, Future }
import play.api.libs.json._

import reactivemongo.api.{ Cursor, ReadPreference }
import reactivemongo.play.json._, collection._

def jsonFind(coll: JSONCollection)(implicit ec: ExecutionContext): Future[List[JsObject]] =
  coll.find(Json.obj()).sort(Json.obj("updated" -> -1)).
    cursor[JsObject](ReadPreference.Primary).
    collect[List](-1, Cursor.FailOnError[List[JsObject]]())
```

Even better, when a client sends a JSON document, you can validate it and transform it before saving it into a MongoDB collection (coast-to-coast approach).

## JSON cursors

The support of Play JSON for ReactiveMongo provides some extensions of the result cursors, as `.jsArray()` to read underlying data as a JSON array.

```scala
import scala.concurrent.Future

import play.api.libs.json._
import play.api.libs.concurrent.Execution.Implicits.defaultContext

import reactivemongo.api.ReadPreference
import reactivemongo.play.json._
import reactivemongo.play.json.collection.{
  JSONCollection, JsCursor
}, JsCursor._

def jsAll(collection: JSONCollection): Future[JsArray] = {
  type ResultType = JsObject // any type which is provided a `Writes[T]`

  collection.find(Json.obj()).
    cursor[ResultType](ReadPreference.Primary).jsArray()
}
```

In the previous example, the function `jsAll` will return a JSON array containing all the documents of the given collection (as JSON objects).

## Helpers

There are some helpers coming along with the JSON support.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.play.json.collection._

// Import a list of JSON objects as documents into the JSON `collection`,
// and returns the insertion count.
def importJson(collection: JSONCollection, resource: String): Future[Int] =
  Helpers.bulkInsert(collection, getClass.getResourceAsStream(resource)).
    map(_.totalN)
```

As illustrated by the previous example, the function `Helpers.bulkInsert` provides a JSON import feature.

## Run a raw command

The [command API](../advanced-topics/commands.html) can be used with the JSON serialization to execution a JSON object as a raw command.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import play.api.libs.json.{ JsObject, Json }

import reactivemongo.play.json._

import reactivemongo.api.{ ReadPreference, FailoverStrategy }
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
  val runner = Command.run(JSONSerializationPack, FailoverStrategy())

  runner.apply(db, runner.rawCommand(commandDoc)).
    one[JsObject](ReadPreference.Primary)
}
```

## Troubleshooting

If the following error is raised;

    No Json serializer as JsObject found for type play.api.libs.json.JsObject.
    Try to implement an implicit OWrites or OFormat for this type.

It's necessary to make sure the right imports are there.

```scala
import reactivemongo.play.json._
// import the default BSON/JSON conversions
```

If the following error is raised;

    Error:(X, Y) type mismatch;
      found   : reactivemongo.api.bson.collection.BSONCollection
      required: ... reactivemongo.play.json.collection.JSONCollection ...

It's necessary to also make sure the right imports are there.

```scala
import reactivemongo.play.json.collection._
```

[Next: Integration with Play Framework](../tutorial/play.html)
