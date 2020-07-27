---
layout: default
major_version: 0.1x
title: Database and collections
---

## Database and collections

Once you have a connection and [resolved the database](./connect-database.html), the collections can be easily referenced.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.MongoConnection
import reactivemongo.api.bson.collection.BSONCollection

def dbFromConnection(connection: MongoConnection): Future[BSONCollection] =
  connection.database("somedatabase").
    map(_.collection("somecollection"))
```

By default, it returns a [`BSONCollection`](../../api/reactivemongo/api/collections/GenericCollection.bson.BSONCollection), which implements the basic `Collection` trait.

The `Collection` trait itself is almost empty, and is not meant to be used as is, as the operations are implemented by [`GenericCollection`](../../api/reactivemongo/api/collections/GenericCollection.GenericCollection).

**Go further:**

If looking at the signature of the [`DefaultDB.collection`](../../api/reactivemongo/api/DefaultDB#collection[C%3C:reactivemongo.api.Collection](name:String,failoverStrategy:reactivemongo.api.FailoverStrategy)(implicitproducer:reactivemongo.api.CollectionProducer[C]):C) function, it can be seen that it uses a [`CollectionProducer`](../../api/reactivemongo/api/CollectionProducer) (resolved from the [implicit scope](http://docs.scala-lang.org/tutorials/FAQ/finding-implicits.html). This producer is required to create the collection references.

By default the BSON producer is used, so there is nothing more to do.

This mechanism makes ReactiveMongo can support other kinds of serialization, such as the [JSON support](../json/overview.html).

### Operations

The collection references provides the [query and write operations](https://docs.mongodb.com/manual/reference/command/#query-and-write-operation-commands): [`find`](../../api/reactivemongo/api/collections/GenericCollection.GenericCollection#find[S,P](selector:S,projection:P)(implicitswriter:GenericCollection.this.pack.Writer[S],implicitpwriter:GenericCollection.this.pack.Writer[P]):reactivemongo.api.collections.GenericQueryBuilder[GenericCollection.this.pack.type]), [`insert`](../../api/reactivemongo/api/collections/GenericCollection.GenericCollection#insert(document:T,writeConcern:reactivemongo.api.commands.WriteConcern)(implicitwriter:GenericCollection.this.pack.Writer[T],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.commands.WriteResult]), [`update`](../../api/reactivemongo/api/collections/GenericCollection.html#update(ordered:Boolean,writeConcern:reactivemongo.api.commands.WriteConcern):GenericCollection.this.UpdateBuilder) and [`delete`](../../api/reactivemongo/api/collections/GenericCollection.html#delete(ordered:Boolean,writeConcern:reactivemongo.api.commands.WriteConcern):GenericCollection.this.DeleteBuilder)...

It also supports some [administration commands](https://docs.mongodb.com/manual/reference/command/#instance-administration-commands): [`create`](../../api/reactivemongo/api/collections/GenericCollection.GenericCollection#create(autoIndexId:Boolean)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Unit]), [`drop`](../../api/reactivemongo/api/collections/GenericCollection.GenericCollection#drop(failIfNotFound:Boolean)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Boolean])...

ReactiveMongo provides a helper to manage indexes (see [`indexesManager`](../../api/reactivemongo/api/collections/GenericCollection.GenericCollection#indexesManager(implicitec:scala.concurrent.ExecutionContext):reactivemongo.api.indexes.CollectionIndexesManager)).

Many of these methods take documents as a parameters.
Indeed, they can take anything that can be represented as document, depending on the serialization pack (e.g. for the BSON one, any value for which is provided a [`BSONDocumentWriter`](../bson/typeclasses.html)).

The results from the operations can be turned into the appropriate types, if there is a [`BSONDocumentReader`](../../api/reactivemongo/bson/BSONDocumentReader) for this type in the implicit scope.

### Additional Notes

When using the [Play JSON serialization pack](../json/overview.html), a `JSONCollection` is provided as an implementation of `GenericCollection` that deals with Play JSON library, using its own de/serializations type classes (Play JSON `Reads[T]` and `Writes[T]`).

[Previous: Connect to the database](./connect-database.html) / [Next: Write documents](./write-documents.html)
