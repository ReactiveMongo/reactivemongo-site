---
layout: default
major_version: 0.10.5
title: The Collection API Design
---

## The Collection API Design

The Collection API is designed to be very extensible, allowing the use of third-party libraries for building documents (ie use something else than the embedded BSON library), including specific serializers and deserializers. For example, that's the case of the [ReactiveMongo Play plugin](https://github.com/ReactiveMongo/Play-ReactiveMongo), which relies on the [Play JSON library](http://www.playframework.com/documentation/2.3.x/ScalaJson) instead.

{% highlight scala %}
// using the default Collection implementation
// (relying on the embedded BSON library)

import reactivemongo.bson._
import reactivemongo.api.collections.default._

case class Person(name: String, age: Int)
object Person {
  implicit val reader: BSONDocumentReader[Person] = Macros.reader[Person]
}

val collection: BSONCollection = db.collection("people")

// find people who are older than 25
val query =
  BSONDocument("age" -> BSONDocument("$gt" -> 25))

// run the query then convert the result to a `Person` instance
// using the implicit (BSON) reader
val result: Future[Option[Person]] = collection.find(query).one[Person]
{% endhighlight %}

{% highlight scala %}
// using the Play plugin's Collection implementation
// (relying on Play's JSON library)

import play.api.libs.json._
import play.modules.reactivemongo.json.collection._

case class Person(name: String, age: Int)
object Person {
  implicit val reader: Reads[Person] = Json.reads[Person]
}

val collection: JSONCollection = db.collection("people")

// find people who are older than 25
val query =
  Json.obj("age" -> Json.obj("$gt" -> 25))

// run the query then convert the result to a `Person` instance
// using the implicit (JSON) reader
val result: Future[Option[Person]] = collection.find(query).one[Person]
{% endhighlight %}

This is very useful when you don't want to explicitly convert your objects into yet another different structure – if your application uses JSON, it is perfectly understandable to want to avoid using BSON only for dealing with MongoDB.

### The `Collection` trait

This trait is almost empty.

{% highlight scala %}
// simplified for the sake of readability
trait Collection {
  /** The database which this collection belong to. */
  def db: DB
  /** The name of the collection. */
  def name: String
  /** The default failover strategy for the methods of this collection. */
  def failoverStrategy: FailoverStrategy

  // already implementated methods

  /** Gets the full qualified name of this collection. */
  def fullCollectionName = db.name + "." + name

  /**
   * Gets another implementation of this collection.
   * An implicit CollectionProducer[C] must be present in the scope, or it will be the default implementation ([[reactivemongo.api.collections.default.BSONCollection]]).
   *
   * @param failoverStrategy Overrides the default strategy.
   */
  def as[C <: Collection](failoverStrategy: FailoverStrategy = failoverStrategy)(implicit producer: CollectionProducer[C] = collections.default.BSONCollectionProducer): C = ...

  /**
   * Gets another collection in the current database.
   * An implicit CollectionProducer[C] must be present in the scope, or it will be the default implementation ([[reactivemongo.api.collections.default.BSONCollection]]).
   *
   * @param name The other collection name.
   * @param failoverStrategy Overrides the default strategy.
   */
  def sibling[C <: Collection](name: String, failoverStrategy: FailoverStrategy = failoverStrategy)(implicit producer: CollectionProducer[C] = collections.default.BSONCollectionProducer): C = ...
}
{% endhighlight %}

All collections implementations must mix this trait in. They also provide implicit objects of type `CollectionProducer` that make new (specialized) instances of them. Since `db.collection()` is parametrized with `C <: Collection` and accepts an implicit `CollectionProducer[C]`, the returned instance of collection can be inferred to the right type if there is only one producer in the implicit scope, which is a typical situation.

{% highlight scala %}
// db.collection() simplified signature
def collection[C <: Collection](name: String)(implicit producer: CollectionProducer[C])
{% endhighlight %}

Most implementations actually extend another trait, `GenericCollection`.

### The `GenericCollection` trait


This trait is much more complete than `Collection`. It defines common methods, like `find()`, `update()`, `remove()` and `insert()`, among others. One particularity of them is that they may be given ...

`GenericCollection` takes 3 type parameters:

- `Structure` is a type which instances may eventually be deserialized or serialized into BSON. It may be BSONDocument of course (as it is in the default Collection implementation), but can be a JSON objector any other third-party structure.
- `Reader[T]` is a type constructor that represents something that knows how to produce a new instance of `T` from a `Structure` instance (`T` being the type parameter of `Reader`). In the default Collection implementation, this is `BSONDocumentReader[_]`.
- `Writer[T]` is a type constructor that represents something that knows how to produce a new instance of `Structure` from a `T` instance (`T` being the type parameter of `Reader`). In the default Collection implementation, this is `BSONDocumentWriter[_]`.

`GenericCollection` extends another trait, `GenericHandlers`, which takes the same type arguments and is used to do the conversions:

{% highlight scala %}
trait GenericHandlers[Structure, Reader[_], Writer[_]] {
  // the following methods need to be implemented
  def StructureBufferReader: BufferReader[Structure]
  def StructureBufferWriter: BufferWriter[Structure]

  def StructureReader[T](reader: Reader[T]): GenericReader[Structure, T]
  def StructureWriter[T](writer: Writer[T]): GenericWriter[T, Structure]

  // other definitions are stripped off
}
{% endhighlight %}

Here, `BufferReader` and `BufferWriter` denote types that define how to read or write `Structure` from/to a byte string, while `StructureReader` and `StructureWriter` define how to convert a `T` instance into `Structure` and _vice versa_. In other words, `StructureReader` turns a given abstract `reader`, useless to ReactiveMongo, into a `GenericReader` that ReactiveMongo can handle.

{% highlight scala %}
trait GenericCollection[Structure, Reader[_], Writer[_]] extends Collection with GenericHandlers[Structure, Reader, Writer] {
  // abstract declarations, that need to be implemented
  def failoverStrategy: FailoverStrategy

  def genericQueryBuilder: GenericQueryBuilder[Structure, Reader, Writer]


  // implementations provided by this trait
  def find[S](selector: S)(implicit swriter: Writer[S]): GenericQueryBuilder[Structure, Reader, Writer] = ...

  def find[S, P](selector: S, projection: P)(implicit swriter: Writer[S], pwriter: Writer[P]): GenericQueryBuilder[Structure, Reader, Writer] = ...


  def insert[T](document: T, writeConcern: GetLastError = GetLastError())(implicit writer: Writer[T], ec: ExecutionContext): Future[LastError] = ...

  def insert(document: Structure, writeConcern: GetLastError)(implicit ec: ExecutionContext): Future[LastError] = ...

  def insert(document: Structure)(implicit ec: ExecutionContext): Future[LastError] = ...

  def update[S, U](selector: S, update: U, writeConcern: GetLastError = GetLastError(), upsert: Boolean = false, multi: Boolean = false)(implicit selectorWriter: Writer[S], updateWriter: Writer[U], ec: ExecutionContext): Future[LastError] = ...

  def remove[T](query: T, writeConcern: GetLastError = GetLastError(), firstMatchOnly: Boolean = false)(implicit writer: Writer[T], ec: ExecutionContext): Future[LastError] = ...

  def bulkInsert[T](enumerator: Enumerator[T], bulkSize: Int = bulk.MaxDocs, bulkByteSize: Int = bulk.MaxBulkSize)(implicit writer: Writer[T], ec: ExecutionContext): Future[Int] = ...

  def bulkInsertIteratee[T](bulkSize: Int = bulk.MaxDocs, bulkByteSize: Int = bulk.MaxBulkSize)(implicit writer: Writer[T], ec: ExecutionContext): Iteratee[T, Int] = ...

  def uncheckedRemove[T](query: T, firstMatchOnly: Boolean = false)(implicit writer: Writer[T], ec: ExecutionContext): Unit = ...

  def uncheckedUpdate[S, U](selector: S, update: U, upsert: Boolean = false, multi: Boolean = false)(implicit selectorWriter: Writer[S], updateWriter: Writer[U]): Unit = ...

  def uncheckedInsert[T](document: T)(implicit writer: Writer[T]): Unit = ...
}

{% endhighlight %}

Let's take an example of how these types are used with `find()`, which is defined like this:

{% highlight scala %}
def find[S](selector: S)(implicit swriter: Writer[S]): GenericQueryBuilder[Structure, Reader, Writer]
{% endhighlight %}

This method takes a `selector` (or query), of type `S`. This object is then transformed into BSON thanks to the implicit `swriter` parameter. Moreover, you can notice that the return type is another trait, `GenericQueryBuilder`, with the same paramater types.

### The `GenericQueryBuilder` trait

A `GenericQueryBuilder`, like its name says it, helps building and customizing the query. As `GenericCollection`, it extends `GenericHandlers`.

{% highlight scala %}
trait GenericQueryBuilder[Structure, Reader[_], Writer[_]] extends GenericHandlers[Structure, Reader, Writer] {
  // abstract declarations, that need to be implemented
  type Self <: GenericQueryBuilder[Structure, Reader, Writer]

  def queryOption: Option[Structure]
  def sortOption: Option[Structure]
  def projectionOption: Option[Structure]
  def hintOption: Option[Structure]
  def explainFlag: Boolean
  def snapshotFlag: Boolean
  def commentString: Option[String]
  def options: QueryOpts
  def failover: FailoverStrategy
  def collection: Collection

  // makes the final Structure instance that stands for the whole query
  // (ie including sort, )
  def merge: Structure

  def structureReader: Reader[Structure]

  def copy(
    queryOption: Option[Structure] = queryOption,
    sortOption: Option[Structure] = sortOption,
    projectionOption: Option[Structure] = projectionOption,
    hintOption: Option[Structure] = hintOption,
    explainFlag: Boolean = explainFlag,
    snapshotFlag: Boolean = snapshotFlag,
    commentString: Option[String] = commentString,
    options: QueryOpts = options,
    failover: FailoverStrategy = failover): Self


  // implementations provided by this trait

  def cursor[T](implicit reader: Reader[T] = structureReader, ec: ExecutionContext): Cursor[T] = ...

  def cursor[T](readPreference: ReadPreference)(implicit reader: Reader[T] = structureReader, ec: ExecutionContext): Cursor[T] = ...

  def one[T](implicit reader: Reader[T], ec: ExecutionContext): Future[Option[T]] = ...

  def one[T](readPreference: ReadPreference)(implicit reader: Reader[T], ec: ExecutionContext): Future[Option[T]] = ...

  def query[Qry](selector: Qry)(implicit writer: Writer[Qry]): Self = ...

  def query(selector: Structure): Self = ...

  def sort(document: Structure): Self = ...

  def options(options: QueryOpts): Self = ...

  def projection[Pjn](p: Pjn)(implicit writer: Writer[Pjn]): Self = ...

  def projection(p: Structure): Self = ...

  def hint(document: Structure): Self = ...

  def snapshot(flag: Boolean = true): Self = ...

  def comment(message: String): Self = ...
}
{% endhighlight %}

### Examples

- The default implementation in ReactiveMongo, `BSONCollection`. It relies on the embedded BSON library, with `BSONCollection` as the `Structure`, and `BSONDocumentReader` and `BSONDocumentWriter` as the de/serializer typeclasses.
- The implementation in the Play plugin, `JSONCollection`. It uses `JsObject` (a JSON object) as the `Structure`, and the de/serializer typeclasses `Writes` and `Reads`.
