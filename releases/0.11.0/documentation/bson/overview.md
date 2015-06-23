---
layout: default
title: ReactiveMongo 0.11.0 - BSON Library Overview
---

## Overview of the ReactiveMongo BSON library

The BSON library of ReactiveMongo implements the [BSON protocol](http://bsonspec.org), or _Binary JSON_, which is used by MongoDB to encode data. Because of that, when we use MongoDB we tend to manipulate a lot of BSON structures; thus the BSON library is designed with the following points in mind:

- ease of use
- strong typing
- efficiency

### Documents and values

There is one Scala class for each BSON type, all in the [`reactivemongo.bson` package](../../api/reactivemongo/bson/package.html):

- [BSONDocument](../../api/reactivemongo/bson/BSONDocument.html) – set of key-value pairs
- [BSONArray](../../api/reactivemongo/bson/BSONArray.html) – sequence of values
- [BSONBinary](../../api/reactivemongo/bson/BSONBinary.html) – binary data
- [BSONBoolean](../../api/reactivemongo/bson/BSONBoolean.html) – boolean
- [BSONDBPointer](../../api/reactivemongo/bson/BSONDBPointer.html) – _deprecated in the protocol_
- [BSONDateTime](../../api/reactivemongo/bson/BSONDateTime.html) – UTC Date Time
- [BSONDouble](../../api/reactivemongo/bson/BSONDouble.html) – 64-bit IEEE 754 floating point
- [BSONInteger](../../api/reactivemongo/bson/BSONInteger.html) – 32-bit integer
- [BSONJavaScript](../../api/reactivemongo/bson/BSONJavaScript.html) – javascript code
- [BSONJavaScriptWS](../../api/reactivemongo/bson/BSONJavaScriptWS.html) – javascript scoped code
- [BSONLong](../../api/reactivemongo/bson/BSONLong.html) – 64-bit integer
- [BSONMaxKey](../../api/reactivemongo/bson/BSONMaxKey$.html) – max key
- [BSONMinKey](../../api/reactivemongo/bson/BSONMinKey$.html) – min key
- [BSONNull](../../api/reactivemongo/bson/BSONNull$.html) – null
- [BSONObjectID](../../api/reactivemongo/bson/BSONObjectID.html) – [12-bytes default id type in MongoDB](http://docs.mongodb.org/manual/reference/object-id/)
- [BSONRegex](../../api/reactivemongo/bson/BSONRegex.html) – regular expression
- [BSONString](../../api/reactivemongo/bson/BSONString.html) – UTF-8 string
- [BSONSymbol](../../api/reactivemongo/bson/BSONSymbol.html) – _deprecated in the protocol_
- [BSONTimestamp](../../api/reactivemongo/bson/BSONTimestamp.html) – special date type used in MongoDB internals
- [BSONUndefined](../../api/reactivemongo/bson/BSONUndefined$.html) – _deprecated in the protocol_

All these classes extend [BSONValue](../../api/reactivemongo/bson/BSONValue.html).

A document is represented by `BSONDocument`. A `BSONDocument` is basically an immutable list of key-value pairs. Since it is the most used BSON type, one of the main focuses of the ReactiveMongo BSON library is to make manipulations of BSONDocuments as easy as possible.

Furthermore, the whole library is articulated around the concept of `BSONDocumentWriter` and `BSONDocumentReader`. These are type classes which purpose is to serialize/deserialize objects of arbitraty types into/from BSON. This makes usage of MongoDB much less verbose and more natural.

[Next: Using the ReactiveMongo BSON library](usage.html)
