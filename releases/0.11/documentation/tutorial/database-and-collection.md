---
layout: default
title: ReactiveMongo 0.11 - Database and collections
---

## Database and collections

Once you have a connection and [resolved the database](./connect-database.html), the collections of the database can be referenced.

### Get a `Collection` reference

A collection can be resolved from the database, thanks to the `collection`.

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

[Previous: Connect to the database](./connect-database.html) | [Next: Write documents](./write-documents.html)
