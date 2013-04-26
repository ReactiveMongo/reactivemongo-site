---
layout: default
title: ReactiveMongo - Ecosystem
---

## ReactiveMongo Components

ReactiveMongo is composed of three subprojects.

### ReactiveMongo BSON
_ReactiveMongo BSON_ is the core BSON library of ReactiveMongo. Though it can be used seperately from the rest of the project – it has no other dependency than the Scala library itself.

### ReactiveMongo BSON Macros
_ReactiveMongo BSON Macros_ is a small library on top of _ReactiveMongo-BSON_, that brings Macros for BSON. With this library you don't have to write your BSONDocumentReader/BSONDocumentWriter de/serializers yourself anymore, but rather generate them with compile-time macros.

### ReactiveMongo
_ReactiveMongo_ is... well, the core of ReactiveMongo :)

## Third party libraries and plugins

* [PlayFramework ReactiveMongo plugin](https://github.com/zenexity/Play-ReactiveMongo): the official plugin for PlayFramework. It provides a specialized collection implementation that enables to use directly JSON (including Writes and Reads de/serializers) with ReactiveMongo.