---
layout: default
title: ReactiveMongo 0.11.2 - BSON readers & writers
---

## BSON readers and writers

In order to get and store data with MongoDB, ReactiveMongo provides an extensible API to define appropriate readers and writers.

As long as you are working with [`BSONValue`s](../../api/index.html#reactivemongo.bson.BSONValue), some default implementations of readers and writers are provided by the following import.

{% highlight scala %}
import reactivemongo.bson._
{% endhighlight %}

### Custom reader

Of course it also possible to read values of custom types. To do so, a custom instance of [`BSONReader`](../../api/index.html#reactivemongo.bson.BSONReader), or of [`BSONDocumentReader`](../../api/index.html#reactivemongo.bson.BSONDocumentReader), must be resolved (in the implicit scope).

*A `BSONReader` for a custom value class:*

{% highlight scala %}
class Score(val value: Float) extends AnyVal

import reactivemongo.bson._

implicit object ScoreReader extends BSONReader[BSONValue, Score] {
  def read(bson: BSONValue): Score = new Score(bson.as[BSONNumberLike].toFloat)
}
{% endhighlight %}

> When reading a numeric value from MongoDB, it's recommanded to use the typeclass [`BSONNumberLike`](../../api/index.html#reactivemongo.bson.BSONNumberLike), to benefit from numeric conversions it provides.

Once a custom `BSONReader` (or `BSONDocumentReader`) is defined, it can be used in `aDocument.getAs[MyValueType]("docProperty")`.

*A `BSONDocumentReader` for a custom case class:*

{% highlight scala %}
case class Person(name: String, age: Int)

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
{% endhighlight %}

Once a custom `BSONDocumentReader` can be resolved, it can be used when working with a query result.

{% highlight scala %}
// Provided the `Person` case class is defined,
// with its `BSONDocumentReader`

import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.api.collections.bson.BSONCollection

def findPerson(personCollection: BSONCollection, name: String)(implicit ec: ExecutionContext): Future[Option[Person]] = personCollection.find(BSONDocument("fullName" -> name)).one[Person]
{% endhighlight %}

*See [how to find documents](../tutorial/find-documents.html).*

### Custom writer

In order to write a value of a custom type, a custom instance of [`BSONWriter`](../../api/index.html#reactivemongo.bson.BSONWriter), or of [`BSONDocumentWriter`](../../api/index.html#reactivemongo.bson.BSONDocumentWriter) must be available.

{% highlight scala %}
class Score(val value: Float) extends AnyVal

import reactivemongo.bson._

implicit object ScoreWriter extends BSONWriter[Score, BSONDouble] {
  def write(score: Score): BSONDouble = BSONDouble(score.value)
}

// Uses `BSONDouble` to write `Float`,
// for compatibility with MongoDB numeric values
{% endhighlight %}

Once a custom `BSONWriter` (or `BSONDocumentWriter`) is defined, it can be used to set a document property as in `BSONDocument("score" -> Score(21F))`.

{% highlight scala %}
case class Person(name: String, age: Int)

import reactivemongo.bson._

implicit object PersonWriter extends BSONDocumentWriter[Person] {
  def write(person: Person): BSONDocument =
    BSONDocument("fullName" -> person.name, "personAge" -> person.age)
}
{% endhighlight %}

Once a `BSONDocumentWriter` is available, an instance of the custom class can be inserted or updated to the MongoDB.

{% highlight scala %}
// Provided the `Person` case class is defined,
// with its `BSONDocumentWriter`

import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.api.collections.bson.BSONCollection
import reactivemongo.api.commands.WriteResult

def create(personCollection: BSONCollection, person: Person)(implicit ec: ExecutionContext): Future[Unit] = {
  val writeResult = personCollection.insert(person)
  writeResult.map(_ => {/*once this is successful, just return successfully*/})
}
{% endhighlight %}

*See [how to write documents](../tutorial/write-documents.html).*

### Helpful macros

To ease the definition or reader and writer instances for your custom types, ReactiveMongo provides some helper [Macros](../../api/index.html#reactivemongo.bson.Macros).

{% highlight scala %}
case class Person(name: String, age: Int)

import reactivemongo.bson._

implicit val personHandler: BSONHandler[BSONDocument, Person] =
  Macros.handler[Person]

/* Or only one of:
implicit val personReader: BSONDocumentReader[Person] = Macros.reader[Person]
implicit val personWriter: BSONDocumentWriter[Person] = Macros.writer[Person]
*/
{% endhighlight %}

> A [`BSONHandler`](../../api/index.html#reactivemongo.bson.BSONHandler) gathers both `BSONDocumentReader` and `BSONDocumentWriter` traits.

### Concrete examples

- [BigDecimal](example-bigdecimal.html)
- [Map](example-maps.html)
