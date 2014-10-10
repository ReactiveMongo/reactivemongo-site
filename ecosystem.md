---
layout: default
title: ReactiveMongo - Ecosystem
---

## ReactiveMongo Components

ReactiveMongo is composed of three subprojects.

* [ReactiveMongo BSON](https://github.com/ReactiveMongo/ReactiveMongo): the core BSON library of ReactiveMongo. Though it can be used seperately from the rest of the project – it has no other dependency than the Scala library itself.

* [ReactiveMongo BSON Macros](https://github.com/ReactiveMongo/ReactiveMongo): a small library on top of `ReactiveMongo-BSON`, that brings Macros for BSON. With this library you don't have to write your BSONDocumentReader/BSONDocumentWriter de/serializers yourself anymore, but rather generate them with compile-time macros.

* [ReactiveMongo](https://github.com/ReactiveMongo/ReactiveMongo): well, the core of ReactiveMongo :)

## Officially supported projects

* [Play-ReactiveMongo](https://github.com/ReactiveMongo/Play-ReactiveMongo): the official plugin for PlayFramework. It provides a specialized collection implementation that enables to use directly JSON (including Writes and Reads de/serializers) with ReactiveMongo.

* [ReactiveMongo Extensions](https://github.com/ReactiveMongo/ReactiveMongo-Extensions): a project aiming to provide all the necessary tools for ReactiveMongo other than the core functionality.