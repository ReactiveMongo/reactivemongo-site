---
layout: default
major_version: 0.11
title: BSON readers & writers
---

## BSON readers and writers

In order to get and store data with MongoDB, ReactiveMongo provides an extensible API to define appropriate readers and writers.

As long as you are working with [`BSONValue`s](../../api/index.html#reactivemongo.bson.BSONValue), some [default implementations of readers and writers](#provided-handlers) are provided by the following import.

```scala
import reactivemongo.bson._
```

### Custom reader

Getting values follow the same principle using `getAs(String)` method. This method is parametrized with a type that can be transformed into a `BSONValue` using a `BSONReader` instance that is implicitly available in the scope (again, the default readers are already imported if you imported `reactivemongo.bson._`.) If the value could not be found, or if the reader could not deserialize it (often because the type did not match), `None` will be returned.

```scala
import reactivemongo.bson.BSONString

val albumTitle2 = album2.getAs[String]("title")
// Some("Everybody Knows this is Nowhere")

val albumTitle3 = album2.getAs[BSONString]("title")
// Some(BSONString("Everybody Knows this is Nowhere"))
```

In order to read values of custom types. To do so, a custom instance of [`BSONReader`](../../api/index.html#reactivemongo.bson.BSONReader), or of [`BSONDocumentReader`](../../api/index.html#reactivemongo.bson.BSONDocumentReader), must be resolved (in the implicit scope).

*A `BSONReader` for a custom value class:*

```scala
package object custom {
  class Score(val value: Float) extends AnyVal

  import reactivemongo.bson._

  implicit object ScoreReader extends BSONReader[BSONValue, Score] {
    def read(bson: BSONValue): Score =
      new Score(bson.as[BSONNumberLike].toFloat)
  }
}
```

> When reading a numeric value from MongoDB, it's recommended to use the typeclass [`BSONNumberLike`](../../api/index.html#reactivemongo.bson.BSONNumberLike), to benefit from numeric conversions it provides.

Once a custom `BSONReader` (or `BSONDocumentReader`) is defined, it can be used in `aDocument.getAs[MyValueType]("docProperty")`.

*A `BSONDocumentReader` for a custom case class:*

```scala
import reactivemongo.bson._

implicit object PersonReader extends BSONDocumentReader[Person] {
  def read(bson: BSONDocument): Person = {
    val opt: Option[Person] = for {
      name <- bson.getAs[String]("fullName")
      age <- bson.getAs[BSONNumberLike]("personAge").map(_.toInt)
    } yield new Person(name, age)

    opt.get // the person is required (or let throw an exception)
  }
}
```

Once a custom `BSONDocumentReader` can be resolved, it can be used when working with a query result.

```scala
import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.bson.{ BSONDocument, BSONDocumentReader }
import reactivemongo.api.collections.bson.BSONCollection

// Provided the `Person` case class is defined, with its `BSONDocumentReader`
implicit def personReader: BSONDocumentReader[Person] = ???

def findPerson(personCollection: BSONCollection, name: String)(implicit ec: ExecutionContext): Future[Option[Person]] = personCollection.find(BSONDocument("fullName" -> name)).one[Person]
```

*See [how to find documents](../tutorial/find-documents.html).*

### Custom writer

Of course it also possible to write a value of a custom type, a custom instance of [`BSONWriter`](../../api/index.html#reactivemongo.bson.BSONWriter), or of [`BSONDocumentWriter`](../../api/index.html#reactivemongo.bson.BSONDocumentWriter) must be available.

```scala
import reactivemongo.bson._

case class Score(value: Float)

implicit object ScoreWriter extends BSONWriter[Score, BSONDouble] {
  def write(score: Score): BSONDouble = BSONDouble(score.value)
}

// Uses `BSONDouble` to write `Float`,
// for compatibility with MongoDB numeric values
```

Each value that can be written using a `BSONWriter` can be used directly when calling a `BSONDocument` constructor.

```scala
val album2 = reactivemongo.bson.BSONDocument(
  "title" -> "Everybody Knows this is Nowhere",
  "releaseYear" -> 1969)
```

Note that this does _not_ use implicit conversions, but rather implicit type classes.

```scala
import reactivemongo.bson._

implicit object PersonWriter extends BSONDocumentWriter[Person] {
  def write(person: Person): BSONDocument =
    BSONDocument("fullName" -> person.name, "personAge" -> person.age)
}
```

Once a `BSONDocumentWriter` is available, an instance of the custom class can be inserted or updated to the MongoDB.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.BSONDocumentWriter
import reactivemongo.api.collections.bson.BSONCollection
import reactivemongo.api.commands.WriteResult

// Provided the `Person` case class is defined, with its `BSONDocumentWriter`
implicit def personWriter: BSONDocumentWriter[Person] = ???

def create(personCollection: BSONCollection, person: Person)(implicit ec: ExecutionContext): Future[Unit] = {
  val writeResult = personCollection.insert(person)
  writeResult.map(_ => {/*once this is successful, just return successfully*/})
}
```

*See [how to write documents](../tutorial/write-documents.html).*

### Helpful macros

To ease the definition or reader and writer instances for your custom types, ReactiveMongo provides some helper [Macros](../../api/index.html#reactivemongo.bson.Macros).

```scala
case class Person(name: String, age: Int)

import reactivemongo.bson._

implicit val personHandler: BSONHandler[BSONDocument, Person] =
  Macros.handler[Person]

/* Or only one of:
implicit val personReader: BSONDocumentReader[Person] = Macros.reader[Person]
implicit val personWriter: BSONDocumentWriter[Person] = Macros.writer[Person]
*/
```

A [`BSONHandler`](../../api/index.html#reactivemongo.bson.BSONHandler) gathers both `BSONReader` and `BSONWriter` traits.

> The macros are currently limited to case classes whose constructor doesn't take more than 22 parameters (due to Scala not generating `apply` and `unapply` in these cases).

### Provided handlers

The following handlers are provided by ReactiveMongo, to read and write the [BSON values](../../api/index.html#reactivemongo.bson.package).

| BSON type    | Value type     |
| ------------ | -------------- |
| BSONArray    | Any collection |
| BSONString   | String         |
| BSONBinary   | Array[Byte]    |
| BSONBoolean  | Boolean        |
| BSONInteger  | Int            |
| BSONLong     | Long           |
| BSONDouble   | Double         |
| BSONDateTime | java.util.Date |

Using [`BSONBooleanLike`](../../api/index.html#reactivemongo.bson.BSONBooleanLike), it is possible to read the following BSON values as boolean.

| BSON type     | Rule           |
| ------------- | -------------- |
| BSONInteger   | `true` if > 0  |
| BSONDouble    | `true` if > 0  |
| BSONNull      | always `false` |
| BSONUndefined | always `false` |

Using [`BSONNumberLike`](../../api/index.html#reactivemongo.bson.BSONNumberLike), it is possible to read the following BSON values as number.

- [`BSONInteger`](../../api/index.html#reactivemongo.bson.BSONInteger)
- [`BSONLong`](../../api/index.html#reactivemongo.bson.BSONLong)
- [`BSONDouble`](../../api/index.html#reactivemongo.bson.BSONDouble)
- [`BSONDateTime`](../../api/index.html#reactivemongo.bson.BSONDateTime): the number of milliseconds since epoch.
- [`BSONTimestamp`](../../api/index.html#reactivemongo.bson.BSONTimestamp): the number of milliseconds since epoch.

#### Optional value

An optional value can be added to a document using the [`Option` type](http://www.scala-lang.org/api/current/index.html#scala.Option) (e.g. for an optional string, `Option[String]`).

### Concrete examples

- [BigDecimal](example-bigdecimal.html)
- [Map](example-maps.html)
- [Document](example-document.html)

[Previous: Overview of the ReactiveMongo BSON library](overview.html)