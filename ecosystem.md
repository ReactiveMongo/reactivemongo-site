---
layout: default
title: Ecosystem
---

## ReactiveMongo components

ReactiveMongo is composed of subprojects.

* [ReactiveMongo BSON](./releases/{{site.latest_major_release}}/documentation/bson/overview.html): the core BSON library of ReactiveMongo. Though it can be used separately from the rest of the project – it has no other dependency than the Scala library itself.

* [ReactiveMongo BSON Macros](./releases/{{site.latest_major_release}}/documentation/bson/typeclasses.html): a small library on top of `ReactiveMongo-BSON`, that brings Macros for BSON. With this library you don't have any more to write yourself the [`BSONDocumentReader`](./releases/{{site.latest_major_release}}/api/index.html#reactivemongo.bson.BSONDocumentReader) or the [`BSONDocumentWriter`](./releases/{{site.latest_major_release}}/api/index.html#reactivemongo.bson.BSONDocumentWriter) to de/serialize, but rather generate them with compile-time macros.

* [ReactiveMongo](./releases/{{site.latest_major_release}}/documentation/): well, the core of ReactiveMongo :)

* Play Framework
  - [ReactiveMongo Play JSON](./releases/{{site.latest_major_release}}/documentation/json/overview.html): the JSON serialization pack for ReactiveMongo, based on the JSON library of Play! Framework. It provides a specialized collection implementation that enables to use directly JSON (including Writes and Reads de/serializers) with ReactiveMongo.
  - [Play ReactiveMongo](./releases/{{site.latest_major_release}}/documentation/tutorial/play.html): the official plugin for Play Framework. Setup the connection according the configuration of the Play application.

* [ReactiveMongo Streaming](./releases/{{site.latest_major_release}}/documentation/tutorial/streaming.html)
  - [ReactiveMongo AkkaStream](./releases/{{site.latest_major_release}}/documentation/tutorial/streaming.html#akka-stream): the [AkkaStream](http://doc.akka.io/docs/akka/2.5/scala/stream/index.html) for ReactiveMongo.
  - [ReactiveMongo Iteratees](./releases/{{site.latest_major_release}}/documentation/tutorial/streaming.html#play-iteratees)

## Third party

**[Acolyte for ReactiveMongo](http://acolyte.eu.org/reactive-mongo/):** 
Framework to unit test a ReactiveMongo persistence.

**[Akka Persistence Mongo](https://github.com/scullxbones/akka-persistence-mongo):** 
MongoDB support for [Akka Persistence](https://doc.akka.io/docs/akka/current/persistence.html), including a ReactiveMongo implementation.

**[Circe BSON](https://github.com/circe/circe-bson):**
Conversions for circe and ReactiveMongo.

**[Enumeratum for ReactiveMongo](https://github.com/lloydmeta/enumeratum/#reactivemongo-bson):**
BSON codecs to use Enumeratum with MongoDB.

**[ReactiveMongo Silhouette](https://github.com/mohiva/play-silhouette-persistence-reactivemongo):** 
An implementation of the Silhouette persistence layer using ReactiveMongo.
