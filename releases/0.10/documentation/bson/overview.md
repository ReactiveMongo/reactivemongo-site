---
layout: default
title: ReactiveMongo 0.10 - BSON Library Overview
---

## Overview of the ReactiveMongo BSON library

The BSON library of ReactiveMongo implements the [BSON protocol](http://bsonspec.org), or _Binary JSON_, which is used by MongoDB to encode data. Because of that, when we use MongoDB we tend to manipulate a lot of BSON structures; thus the BSON library is designed with the following points in mind:

- ease of use
- strong typing
- efficiency

### Documents and values

There is one Scala class for each BSON type, all in the [`reactivemongo.bson` package](/releases/0.10/api/reactivemongo/bson/package.html):

- [BSONDocument](/releases/0.10/api/reactivemongo/bson/BSONDocument.html) – set of key-value pairs
- [BSONArray](/releases/0.10/api/reactivemongo/bson/BSONArray.html) – sequence of values
- [BSONBinary](/releases/0.10/api/reactivemongo/bson/BSONBinary.html) – binary data
- [BSONBoolean](/releases/0.10/api/reactivemongo/bson/BSONBoolean.html) – boolean
- [BSONDBPointer](/releases/0.10/api/reactivemongo/bson/BSONDBPointer.html) – _deprecated in the protocol_
- [BSONDateTime](/releases/0.10/api/reactivemongo/bson/BSONDateTime.html) – UTC Date Time
- [BSONDouble](/releases/0.10/api/reactivemongo/bson/BSONDouble.html) – 64-bit IEEE 754 floating point
- [BSONInteger](/releases/0.10/api/reactivemongo/bson/BSONInteger.html) – 32-bit integer
- [BSONJavaScript](/releases/0.10/api/reactivemongo/bson/BSONJavaScript.html) – javascript code
- [BSONJavaScriptWS](/releases/0.10/api/reactivemongo/bson/BSONJavaScriptWS.html) – javascript scoped code
- [BSONLong](/releases/0.10/api/reactivemongo/bson/BSONLong.html) – 64-bit integer
- [BSONMaxKey](/releases/0.10/api/reactivemongo/bson/BSONMaxKey$.html) – max key
- [BSONMinKey](/releases/0.10/api/reactivemongo/bson/BSONMinKey$.html) – min key
- [BSONNull](/releases/0.10/api/reactivemongo/bson/BSONNull$.html) – null
- [BSONObjectID](/releases/0.10/api/reactivemongo/bson/BSONObjectID.html) – [12-bytes default id type in MongoDB](http://docs.mongodb.org/manual/reference/object-id/)
- [BSONRegex](/releases/0.10/api/reactivemongo/bson/BSONRegex.html) – regular expression
- [BSONString](/releases/0.10/api/reactivemongo/bson/BSONString.html) – UTF-8 string
- [BSONSymbol](/releases/0.10/api/reactivemongo/bson/BSONSymbol.html) – _deprecated in the protocol_
- [BSONTimestamp](/releases/0.10/api/reactivemongo/bson/BSONTimestamp.html) – special date type used in MongoDB internals
- [BSONUndefined](/releases/0.10/api/reactivemongo/bson/BSONUndefined$.html) – _deprecated in the protocol_

All these classes extend [BSONValue](/releases/0.10/api/reactivemongo/bson/BSONValue.html).

A document is represented by `BSONDocument`. A `BSONDocument` is basically an immutable list of key-value pairs. Since it is the most used BSON type, one of the main focuses of the ReactiveMongo BSON library is to make manipulations of BSONDocuments as easy as possible.

Furthermore, the whole library is articulated around the concept of `BSONDocumentWriter` and `BSONDocumentReader`. These are type classes which purpose is to serialize/deserialize objects of arbitraty types into/from BSON. This makes usage of MongoDB much less verbose and more natural.

[Next: Using the ReactiveMongo BSON library](usage.html)
