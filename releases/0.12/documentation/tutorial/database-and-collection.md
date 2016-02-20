---
layout: default
title: ReactiveMongo 0.12 - Database and collections
---

## Database and collections

### Get a `DB` reference

You can get a `DB` reference using the method `db` on a `MongoConnection`:

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

def connection1: reactivemongo.api.MongoConnection = ???

val database1 = connection1.db("mydatabase")
{% endhighlight %}

There is an `apply` method on `MongoConnection` that is an alias for `db()`, so you can also do this:

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

def db2: reactivemongo.api.DefaultDB = ???

val database2 = db2.connection("mydatabase")
{% endhighlight %}

[`DB`](../../api/index.html#reactivemongo.api.DB) is just a trait. Both `MongoConnection.db()` and `MongoConnection.apply()` return a default implementation, [`DefaultDB`](../../api/index.html#reactivemongo.api.DefaultDB), which defines other useful methods (like `drop()`, `sister()`, …)

### Get a `Collection` reference

It works the same way as for databases, thanks to the `collection` method on a `Database`.

{% highlight scala %}
import reactivemongo.api.collections.bson.BSONCollection

def db3: reactivemongo.api.DefaultDB = ???

val collection3 = db3.collection[BSONCollection]("acollection")
{% endhighlight %}

Or, with the `apply()` alias:

{% highlight scala %}
import reactivemongo.api.collections.bson.BSONCollection

def db4: reactivemongo.api.DefaultDB = ???

val collection4 = db4[BSONCollection]("acollection")
{% endhighlight %}

Both return a [`BSONCollection`](../../api/index.html#reactivemongo.api.collections.bson.BSONCollection), which implements the basic [`Collection`](../../api/index.html#reactivemongo.api.Collection) trait.

The `Collection` trait itself is almost empty. It is not meant to be used as is. Let's take a look to the `DB.collection` method signature:

{% highlight scala %}
package api

trait db {
  import reactivemongo.api.{
    Collection, CollectionProducer, FailoverStrategy
  }
  import reactivemongo.api.collections.bson.BSONCollectionProducer

  def collection[C <: Collection](name: String, failoverStrategy: FailoverStrategy)(implicit producer: CollectionProducer[C] = BSONCollectionProducer): C

}
{% endhighlight %}

When you call this method, there must be an implicit `CollectionProducer` instance in the scope. Then the actual type of the return `Collection` will be the type parameter of the implicit producer.

In most cases, you want to use the default BSON implementation. That's why we wrote `collection[BSONCollection](name)`. Note that you don't need to import an implicit `CollectionProducer[BSONCollection]`, since it is the default value of the implicit parameter `producer` (` = collections.bson.BSONCollectionProducer`).

#### `BSONCollection`

`BSONCollection` is the default implementation of `Collection` in ReactiveMongo. It defines all the classic operations:

- `find`
- `insert`
- `update`
- `remove`
- `save`
- `bulkInsert`

and some commands that operate on the collection itself:

- `create` (to create the collection explicitely)
- `rename`
- `drop`

It also includes a helper to manage indexes, called `indexesManager`.

Many of these methods take `BSONDocument` instances as a parameter. But they can take anything actually, provided that there exists a special transformer called `BSONDocumentWriter` in the implicit scope. The results from the database themselves can be turned into an object of some arbitrary class, if there is a `BSONDocumentReader` for this type in the implicit scope. It is a very handy to deal with the database without having to transform explicitely all you models into `BSONDocument`.

#### Notes about the Collections design

`BSONCollection` extends a trait called [`GenericCollection`](../../api/index.html#reactivemongo.api.collections.GenericCollection). Actually, it is this trait that provides most of its methods. Moreover, it works with a structure type (which is `BSONDocument` in `BSONCollection`) and de/serialization type classes (which are `BSONDocumentReader[T]` and `BSONDocumentWriter[T]` in `BSONCollection`).

Such a design enables third-party libraries to provide their own collection API. And by extending the `GenericCollection` trait, one can implement a collection that deals with any other structure (like JSON, or even another BSON library).

There is one example of that in the [Play JSON serialization pack](../json/overview.html): `JSONCollection` is an implementation of `GenericCollection` that deals with Play JSON library, using its own de/serializations type classes (`Reads[T]` and `Writes[T]`).

[Next: Write documents](./write-documents.html)
