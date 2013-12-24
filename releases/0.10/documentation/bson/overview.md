---
layout: default
title: ReactiveMongo 0.10 - BSON Library Overview
---

## Overview of the ReactiveMongo BSON library

The BSON library of ReactiveMongo implements the [BSON protocol](http://bsonspec.org), or _Binary JSON_, which is used by MongoDB to encode data. Because of that, when we use MongoDB we tend to manipulate a lot of BSON structures; thus the BSON library is designed with the following points in mind:
* ease of use
* strong typing
* efficiency

### Documents and values

There is one Scala class for each BSON type:
- [BSONDocument]() – set of key-value pairs
- [BSONArray]() – sequence of values
- [BSONBinary]() – binary data
- [BSONBoolean]() – boolean
- [BSONDBPointer]() – _deprecated in the protocol_
- [BSONDateTime]() – UTC Date Time
- [BSONDouble]() – 64-bit IEEE 754 floating point
- [BSONInteger]() – 32-bit integer
- [BSONJavaScript]() – javascript code
- [BSONJavaScriptWS]() – javascript scoped code
- [BSONLong]() – 64-bit integer
- [BSONMaxKey]() – max key
- [BSONMinKey]() – min key
- [BSONNull]() – null
- [BSONObjectID]() – [12-bytes default id type in MongoDB](http://docs.mongodb.org/manual/reference/object-id/)
- [BSONRegex]() – regular expression
- [BSONString]() – UTF-8 string
- [BSONSymbol]() – _deprecated in the protocol_
- [BSONTimestamp]() – special date type used in MongoDB internals
- [BSONUndefined]() – _deprecated in the protocol_

All these classes extend [BSONValue]().

A document is represented by `BSONDocument`. A `BSONDocument` is basically an immutable list of key-value pairs. Since it is the most used BSON type, one of the main focuses of the ReactiveMongo BSON library is to make manipulations of BSONDocuments as easy as possible.

Furthermore, the whole library is articulated around the concept of `BSONDocumentWriter` and `BSONDocumentReader`. These are type classes which purpose is to serialize/deserialize objects of arbitraty types into/from BSON. This makes usage of MongoDB much less verbose and more natural.
