---
layout: default
title: ReactiveMongo - Ecosystem
---

## ReactiveMongo Components

ReactiveMongo is composed of subprojects.

* [ReactiveMongo BSON](https://github.com/ReactiveMongo/ReactiveMongo): the core BSON library of ReactiveMongo. Though it can be used seperately from the rest of the project – it has no other dependency than the Scala library itself.

* [ReactiveMongo BSON Macros](https://github.com/ReactiveMongo/ReactiveMongo): a small library on top of `ReactiveMongo-BSON`, that brings Macros for BSON. With this library you don't have to write your BSONDocumentReader/BSONDocumentWriter de/serializers yourself anymore, but rather generate them with compile-time macros.

* [ReactiveMongo](https://github.com/ReactiveMongo/ReactiveMongo): well, the core of ReactiveMongo :)

* Playframework
  - [ReactiveMongo Play JSON](https://github.com/ReactiveMongo/ReactiveMongo-Play-Json): the JSON serialization pack for ReactiveMongo, based on the JSON library of Play! Framework. It provides a specialized collection implementation that enables to use directly JSON (including Writes and Reads de/serializers) with ReactiveMongo.
  - [Play ReactiveMongo](https://github.com/ReactiveMongo/Play-ReactiveMongo): the official plugin for PlayFramework. Setup the connection according the configuration of the Play application.

* Streaming
  - [ReactiveMongo AkkaStream](https://github.com/ReactiveMongo/ReactiveMongo-AkkaStream): the [AkkaStream](http://doc.akka.io/docs/akka/2.4/scala/stream/index.html) for ReactiveMongo.
