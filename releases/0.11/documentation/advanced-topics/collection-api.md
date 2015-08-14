---
layout: default
title: ReactiveMongo 0.11 - The Collection API
---

## The Collection API

The Collection API is designed to be very extensible, allowing the use of third-party libraries for building documents (ie use something else than the embedded BSON library), including specific serializers and deserializers. For example, that's the case of the [ReactiveMongo Play plugin](https://github.com/ReactiveMongo/Play-ReactiveMongo), which relies on the [Play JSON library](http://www.playframework.com/documentation/2.3.x/ScalaJson) instead.

{% highlight scala %}
// using the default Collection implementation
// (relying on the embedded BSON library)

import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.{ BSONDocument, BSONDocumentReader, Macros }
import reactivemongo.api.collections.bson.BSONCollection

case class Person(name: String, age: Int)

object Person {
  implicit val reader: BSONDocumentReader[Person] = Macros.reader[Person]
}

def db1: reactivemongo.api.DefaultDB = ???

val collection1: BSONCollection = db1.collection("people")

// find people who are older than 25
val query1 =
  BSONDocument("age" -> BSONDocument("$gt" -> 25))

// run the query then convert the result to a `Person` instance
// using the implicit (BSON) reader
val result1: Future[Option[Person]] = collection1.find(query1).one[Person]
{% endhighlight %}

{% highlight scala %}
// using the Play plugin's Collection implementation
// (relying on Play's JSON library)
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import play.api.libs.json._
import play.modules.reactivemongo.json._
import play.modules.reactivemongo.json.collection.JSONCollection

def db2: reactivemongo.api.DefaultDB = ???

val collection2 = db2.collection[JSONCollection]("people")

// find people who are older than 25
val query2 = Json.obj("age" -> Json.obj("$gt" -> 25))

// run the query then convert the result to a `Person` instance
// using the implicit (JSON) reader
def result2(implicit jsonReads: Reads[Person]): Future[Option[Person]] =
  collection2.find(query2).one[Person]
{% endhighlight %}

This is very useful when you don't want to explicitly convert your objects into yet another different structure – if your application uses JSON, it is perfectly understandable to want to avoid using BSON only for dealing with MongoDB.

### The `Collection` trait

This trait is almost empty.

{% highlight scala %}
package simplified.api

import reactivemongo.api.{ CollectionProducer, DB, FailoverStrategy }

// simplified for the sake of readability
trait Collection {
  /** The database which this collection belong to. */
  def db: DB

  /** The name of the collection. */
  def name: String

  /** Gets the full qualified name of this collection. */
  def fullCollectionName = db.name + "." + name
}
{% endhighlight %}

All collections implementations must mix this trait in. They also provide implicit objects of type `CollectionProducer` that make new (specialized) instances of them. Since `db.collection()` is parametrized with `C <: Collection` and accepts an implicit `CollectionProducer[C]`, the returned instance of collection can be inferred to the right type if there is only one producer in the implicit scope, which is a typical situation.

{% highlight scala %}
package simplifiedapi

import reactivemongo.api.{ Collection, CollectionProducer }

trait DB {
  def collection[C <: Collection](name: String)(implicit producer: CollectionProducer[C])
}
{% endhighlight %}

Most implementations actually extend another trait, `GenericCollection`.

### The `GenericCollection` trait


This trait is much more complete than `Collection`. It defines common methods, like `find()`, `update()`, `remove()` and `insert()`, among others. One particularity of them is that they may be given ...

`GenericCollection` takes 1 type parameter: the `SerializationPack`.

TODO

Let's take an example of how these types are used with `find()`, which is defined like this:

{% highlight scala %}
package simplifiedapi

import reactivemongo.api.collections.GenericQueryBuilder

trait GenericCollection {
  def serializationPack: reactivemongo.api.SerializationPack
  val pack = serializationPack

  def find[S](selector: S)(implicit swriter: pack.Writer[S]): GenericQueryBuilder[pack.type]
}
{% endhighlight %}

This method takes a `selector` (or query), of type `S`. This object is then transformed into BSON thanks to the implicit `swriter` parameter. Moreover, you can notice that the return type is another trait, `GenericQueryBuilder`, with the same paramater types.

### The `GenericQueryBuilder` trait

A `GenericQueryBuilder`, like its name says it, helps building and customizing the query.

TODO

### Examples

- The default implementation in ReactiveMongo, `BSONCollection`. It relies on the embedded BSON library, with `BSONCollection` as the `Structure`, and `BSONDocumentReader` and `BSONDocumentWriter` as the de/serializer typeclasses.
- The implementation in the Play plugin, `JSONCollection`. It uses `JsObject` (a JSON object), and the de/serializer typeclasses `Writes` and `Reads`.
