---
layout: default
title: ReactiveMongo 0.11 - Database and collections
---

## Database and collections

Once you have a connection and [resolved the database](./connect-database.html), the collections can be easily referenced.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
import reactivemongo.api.MongoConnection
import reactivemongo.api.collections.bson.BSONCollection

def dbFromConnection(connection: MongoConnection): Future[BSONCollection] =
  connection.database("somedatabase").
    map(_.collection("somecollection"))
{% endhighlight %}

By default, it returns a [`BSONCollection`](../../api/index.html#reactivemongo.api.collections.bson.BSONCollection), which implements the basic `Collection` trait.

The `Collection` trait itself is almost empty, and is not meant to be used as is. The collection operations are implemented by [`GenericCollection`](../../api/index.html#reactivemongo.api.collections.GenericCollection).

**Go further:**

If looking at the signature of the [`DB.collection`](../../api/index.html#reactivemongo.api.DefaultDB@collection[C%3C:reactivemongo.api.Collection](name:String,failoverStrategy:reactivemongo.api.FailoverStrategy)(implicitproducer:reactivemongo.api.CollectionProducer[C]):C) function, it can be seen that it uses a [`CollectionProducer`](../../api/index.html#reactivemongo.api.CollectionProducer) (resolved from the [implicit scope](http://docs.scala-lang.org/tutorials/FAQ/finding-implicits.html). This producer is required to create the collection references.

By default the BSON producer is used, so there is nothing more to do.

It is this mechanism which makes ReactiveMongo can support other kinds of serialization, such as the [JSON support](../json/overview.html).

### Operations

The collection references provides the [query and write operations](https://docs.mongodb.com/manual/reference/command/#query-and-write-operation-commands): [`find`](../../api/index.html#reactivemongo.api.collections.GenericCollection@find[S,P](selector:S,projection:P)(implicitswriter:GenericCollection.this.pack.Writer[S],implicitpwriter:GenericCollection.this.pack.Writer[P]):reactivemongo.api.collections.GenericQueryBuilder[GenericCollection.this.pack.type]), [`insert`](../../api/index.html#reactivemongo.api.collections.GenericCollection@insert[T](document:T,writeConcern:reactivemongo.api.commands.WriteConcern)(implicitwriter:GenericCollection.this.pack.Writer[T],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.commands.WriteResult]), [`update`](../../api/index.html#reactivemongo.api.collections.GenericCollection@update[S,U](selector:S,update:U,writeConcern:reactivemongo.api.commands.WriteConcern,upsert:Boolean,multi:Boolean)(implicitselectorWriter:GenericCollection.this.pack.Writer[S],implicitupdateWriter:GenericCollection.this.pack.Writer[U],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.commands.UpdateWriteResult]) and [`remove`](../../api/index.html#reactivemongo.api.collections.GenericCollection@remove[T](query:T,writeConcern:reactivemongo.api.commands.WriteConcern,firstMatchOnly:Boolean)(implicitwriter:GenericCollection.this.pack.Writer[T],implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.commands.WriteResult])...

It also supports some [administration commands](https://docs.mongodb.com/manual/reference/command/#instance-administration-commands): [`create`](../../api/index.html#reactivemongo.api.collections.GenericCollection@create(autoIndexId:Boolean)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Unit]), [`drop`](../../api/index.html#reactivemongo.api.collections.GenericCollection@drop(failIfNotFound:Boolean)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Boolean])...

It also includes a helper to manage indexes (see [`indexesManager`](../../api/index.html#reactivemongo.api.collections.GenericCollection@indexesManager(implicitec:scala.concurrent.ExecutionContext):reactivemongo.api.indexes.CollectionIndexesManager)).

Many of these methods take documents as a parameters.
Indeed, they can take anything that can be represented as document, depending on the serialization pack (the BSON one by default).

Considering the default serialization (BSON), the functions requiring documents will accept any value for which is provided a [`BSONDocumentWriter`](../bson/typeclasses.html).

The results from the operations can be turned into the appropriate types, if there is a [`BSONDocumentReader`](../../api/index.html#reactivemongo.bson.BSONDocumentReader) for this type in the implicit scope.

### Additional Notes

When using the [Play JSON serialization pack](../json/overview.html), it provides `JSONCollection` which is an implementation of `GenericCollection` that deals with Play JSON library, using its own de/serializations type classes (`Reads[T]` and `Writes[T]`).

[Previous: Connect to the database](./connect-database.html) / [Next: Write documents](./write-documents.html)