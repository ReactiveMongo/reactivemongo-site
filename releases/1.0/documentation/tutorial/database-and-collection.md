---
layout: default
major_version: 1.0
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

By default, it returns a [`BSONCollection`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/collection/index.html#BSONCollection=reactivemongo.api.collections.GenericCollection[reactivemongo.api.bson.collection.package.Pack]withreactivemongo.api.CollectionMetaCommands), which implements the basic `Collection` trait.

The `Collection` trait itself is almost empty, and is not meant to be used as is, as the operations are implemented by [`GenericCollection`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html).

**Go further:**

If looking at the signature of the [`DB.collection`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/DB.html#collection[C%3C:reactivemongo.api.Collection](name:String,failoverStrategy:reactivemongo.api.FailoverStrategy)(implicitproducer:reactivemongo.api.CollectionProducer[C]):C) function, it can be seen that it uses a [`CollectionProducer`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/CollectionProducer.html) (resolved from the [implicit scope](http://docs.scala-lang.org/tutorials/FAQ/finding-implicits.html). This producer is required to create the collection references.

By default the BSON producer is used, so there is nothing more to do.

This mechanism makes ReactiveMongo can support other kinds of serialization, such as the [JSON support](../json/overview.html).

### Operations

The collection references provides the [query and write operations](https://docs.mongodb.com/manual/reference/command/#query-and-write-operation-commands): [`find`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#find[S](selector:S)(implicitswriter:GenericCollection.this.pack.Writer[S]):GenericCollection.this.QueryBuilder), [`insert`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#insert:GenericCollection.this.InsertBuilder), [`update`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#update:GenericCollection.this.UpdateBuilder) and [`delete`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#delete:GenericCollection.this.DeleteBuilder)...

It also supports some [administration commands](https://docs.mongodb.com/manual/reference/command/#instance-administration-commands): [`create`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#create()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Unit]), [`drop`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#drop()(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Unit])...

ReactiveMongo provides a helper to manage indexes (see [`indexesManager`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#indexesManager(implicitec:scala.concurrent.ExecutionContext):reactivemongo.api.indexes.CollectionIndexesManager.Aux[reactivemongo.api.Serialization.Pack])).

Many of these methods take documents as a parameters.
Indeed, they can take anything that can be represented as document, depending on the serialization pack (e.g. for the BSON one, any value for which is provided a [`BSONDocumentWriter`](../bson/typeclasses.html)).

The results from the operations can be turned into the appropriate types, if there is a [`BSONDocumentReader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDocumentReader.html) for this type in the implicit scope.

[Previous: Connect to the database](./connect-database.html) / [Next: Write documents](./write-documents.html)
