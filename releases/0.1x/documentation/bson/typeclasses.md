---
layout: default
major_version: 0.1x
title: BSON readers & writers
---

## BSON readers and writers

In order to get and store data with MongoDB, ReactiveMongo provides an extensible API to define appropriate readers and writers.

As long as you are working with [`BSONValue`s](../../api/reactivemongo/bson/BSONValue), some [default implementations of readers and writers](#provided-handlers) are provided by the following import.

{% highlight scala %}
import reactivemongo.bson._
{% endhighlight %}

### Custom reader

Getting values follows the same principle using `getAs(String)` method. This method is parametrized with a type that can be transformed into a `BSONValue` using a `BSONReader` instance that is implicitly available in the scope (again, the default readers are already imported if you imported `reactivemongo.bson._`.) If the value could not be found, or if the reader could not deserialize it (often because the type did not match), `None` will be returned.

{% highlight scala %}
import reactivemongo.bson.BSONString

val albumTitle2 = album2.getAs[String]("title")
// Some("Everybody Knows this is Nowhere")

val albumTitle3 = album2.getAs[BSONString]("title")
// Some(BSONString("Everybody Knows this is Nowhere"))
{% endhighlight %}

In order to read values of custom types. To do so, a custom instance of [`BSONReader`](../../api/reactivemongo/bson/BSONReader), or of [`BSONDocumentReader`](../../api/reactivemongo/bson/BSONDocumentReader), must be resolved (in the implicit scope).

*A `BSONReader` for a custom value class:*

{% highlight scala %}
package object custom {
  class Score(val value: Float) extends AnyVal

  import reactivemongo.bson._

  implicit object ScoreReader extends BSONReader[BSONValue, Score] {
    def read(bson: BSONValue): Score =
      new Score(bson.as[BSONNumberLike].toFloat)
  }
}
{% endhighlight %}

> When reading a numeric value from MongoDB, it's recommended to use the typeclass [`BSONNumberLike`](../../api/reactivemongo/bson/BSONNumberLike), to benefit from numeric conversions it provides.

Once a custom `BSONReader` (or `BSONDocumentReader`) is defined, it can be used in `aDocument.getAs[MyValueType]("docProperty")`.

*A `BSONDocumentReader` for a custom case class:*

{% highlight scala %}
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
import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.bson.{ BSONDocument, BSONDocumentReader }
import reactivemongo.api.collections.bson.BSONCollection

// Provided the `Person` case class is defined, with its `BSONDocumentReader`
implicit def personReader: BSONDocumentReader[Person] = ???

def findPerson(personCollection: BSONCollection, name: String)(implicit ec: ExecutionContext): Future[Option[Person]] = personCollection.find(BSONDocument("fullName" -> name)).one[Person]
{% endhighlight %}

*See [how to find documents](../tutorial/find-documents.html).*

### Custom writer

Of course it's also possible to write a value of a custom type, a custom instance of [`BSONWriter`](../../api/reactivemongo/bson/BSONWriter), or of [`BSONDocumentWriter`](../../api/reactivemongo/bson/BSONDocumentWriter) must be available.

{% highlight scala %}
import reactivemongo.bson._

case class Score(value: Float)

implicit object ScoreWriter extends BSONWriter[Score, BSONDouble] {
  def write(score: Score): BSONDouble = BSONDouble(score.value)
}

// Uses `BSONDouble` to write `Float`,
// for compatibility with MongoDB numeric values
{% endhighlight %}

Each value that can be written using a `BSONWriter` can be used directly when calling a `BSONDocument` constructor.

{% highlight scala %}
val album2 = reactivemongo.bson.BSONDocument(
  "title" -> "Everybody Knows this is Nowhere",
  "releaseYear" -> 1969)
{% endhighlight %}

Note that this does _not_ use implicit conversions, but rather implicit type classes.

{% highlight scala %}
import reactivemongo.bson._

implicit object PersonWriter extends BSONDocumentWriter[Person] {
  def write(person: Person): BSONDocument =
    BSONDocument("fullName" -> person.name, "personAge" -> person.age)
}
{% endhighlight %}

Once a `BSONDocumentWriter` is available, an instance of the custom class can be inserted or updated to the MongoDB.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.BSONDocumentWriter
import reactivemongo.api.collections.bson.BSONCollection

// Provided the `Person` case class is defined, with its `BSONDocumentWriter`
implicit def personWriter: BSONDocumentWriter[Person] = ???

def create(personCollection: BSONCollection, person: Person)(implicit ec: ExecutionContext): Future[Unit] = {
  val writeResult = personCollection.insert(person)
  writeResult.map(_ => {/*once this is successful, just return successfully*/})
}
{% endhighlight %}

*See [how to write documents](../tutorial/write-documents.html).*

### Helpful macros

To ease the definition of reader and writer instances for your custom types, ReactiveMongo provides some helper [Macros](../../api/reactivemongo/bson/Macros).

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

The [`BSONHandler`](../../api/reactivemongo/bson/BSONHandler) provided by [`Macros.handler`](../../api/reactivemongo/bson/Macros$#handler[A]:reactivemongo.bson.BSONDocumentReader[A]withreactivemongo.bson.BSONDocumentWriter[A]withreactivemongo.bson.BSONHandler[reactivemongo.bson.BSONDocument,A]) gathers both `BSONReader` and `BSONWriter` traits.

The [`Macros.reader`](../../api/reactivemongo/bson/Macros$#reader[A]:reactivemongo.bson.BSONDocumentReader[A]) can be used to generate only the `BSONReader`, while the [`Macros.writer`](../../api/reactivemongo/bson/Macros$#writer[A]:reactivemongo.bson.BSONDocumentWriter[A]) is for `BSONWriter`.

The `A` type parameter (e.g. with `A` being `Person`, `Macros.reader[Person]`) defines a type for a case class, or for a [sealed trait](http://docs.scala-lang.org/tutorials/tour/traits.html) with subclasses.
This type will be the basis for the auto-generated implementation.

> Some other types with matching `apply`-`unapply` might work but behaviour is undefined. Since macros will match the `apply`-`unapply` pair you are free to overload these methods in the companion object.

**Case class mapping:**

For the case classes, the fields get mapped into BSON properties with respective names, and BSON handlers are pulled from implicit scope to (de)serialize them (in the previous `Person` example, the handlers for `String` are resolved for the `name` property).

So in order to use custom types as properties in case classes, the appropriate handlers are in scope.

For example if you have `case class Foo(bar: Bar)` and want to create a handler for it is enough to put an implicit handler for `Bar` in it's companion object. That handler might itself be macro generated, or written by hand.

> The macros are currently limited to case classes whose constructor doesn't take more than 22 parameters (due to Scala not generating `apply` and `unapply` in the other cases).

**Sealed trait and union types:**

Sealed traits are also supported as [union types](https://en.wikipedia.org/wiki/Union_type), with each of their subclasses considered as a disjoint case.

{% highlight scala %}
import reactivemongo.bson.{ BSONDocument, BSONHandler, Macros }

sealed trait Tree
case class Node(left: Tree, right: Tree) extends Tree
case class Leaf(data: String) extends Tree

object Tree {
  implicit val node = Macros.handler[Node]
  implicit val leaf = Macros.handler[Leaf]

  implicit val bson: BSONHandler[BSONDocument, Tree] = Macros.handler[Tree]
}
{% endhighlight %}

The `handler`, `reader` and `writer` macros each have a corresponding extended macro: [`readerOpts`](../../api/reactivemongo/bson/Macros$#readerOpts[A,Opts%3C:reactivemongo.bson.Macros.Options.Default]:reactivemongo.bson.BSONDocumentReader[A]), [`writerOpts`](../../api/reactivemongo/bson/Macros$#writerOpts[A,Opts%3C:reactivemongo.bson.Macros.Options.Default]:reactivemongo.bson.BSONDocumentWriter[A]) and [`handlerOpts`](../../api/reactivemongo/bson/Macros$#handlerOpts[A,Opts%3C:reactivemongo.bson.Macros.Options.Default]:reactivemongo.bson.BSONDocumentReader[A]withreactivemongo.bson.BSONDocumentWriter[A]withreactivemongo.bson.BSONHandler[reactivemongo.bson.BSONDocument,A]).

These 'Opts' suffixed macros can be used to explicitly define the [`UnionType`](../../api/reactivemongo/bson/Macros$$Options$@UnionType[Types%3C:reactivemongo.bson.Macros.Options.\/[_,_]]extendsMacros.Options.SaveClassNamewithMacros.Options.Default).

{% highlight scala %}
sealed trait Color

case object Red extends Color
case object Blue extends Color
case class Green(brightness: Int) extends Color
case class CustomColor(code: String) extends Color

object Color {
  import reactivemongo.bson.Macros,
    Macros.Options.{ AutomaticMaterialization, UnionType, \/ }

  // Use `UnionType` to define a subset of the `Color` type,
  type PredefinedColor =
    UnionType[Red.type \/ Green \/ Blue.type] with AutomaticMaterialization

  val predefinedColor = Macros.handlerOpts[Color, PredefinedColor]
}
{% endhighlight %}

As for the `UnionType` definition, `Foo \/ Bar \/ Baz` is interpreted as type `Foo` or type `Bar` or type `Baz`. The option `AutomaticMaterialization` is used there to automatically try to materialize the handlers for the sub-types (disabled by default).

The other options available to configure the typeclasses generation at compile time are the following.

- [`Verbose`](../../api/reactivemongo/bson/Macros$$Options$@VerboseextendsMacros.Options.Default): Print out generated code during compilation.
- [`SaveClassName`](../../api/reactivemongo/bson/Macros$$Options$@SaveClassNameextendsMacros.Options.Default): Indicate to the `BSONWriter` to add a "className" field in the written document along with the other properties. The value for this meta field is the fully qualified name of the class. This is the default behaviour when the target type is a sealed trait (the "className" field is used as discriminator).

**Annotations:**

Some annotations are also available to configure the macros.

The [`@Key`](../../api/reactivemongo/bson/Macros$$Annotations$@KeyextendsAnnotationwithStaticAnnotationwithProductwithSerializable) annotation allows to specify the field name for a class property.

For example, it is convenient to use when you'd like to leverage the MongoDB `_id` index but you don't want to actually use `_id` in your code.

{% highlight scala %}
import reactivemongo.bson.Macros.Annotations.Key

case class Website(@Key("_id") url: String)
// Generated handler will map the `url` field in your code to as `_id` field
{% endhighlight %}

The [`@Ignore`](../../api/reactivemongo/bson/Macros$$Annotations$@IgnoreextendsAnnotationwithStaticAnnotationwithProductwithSerializable) can be applied on the class properties to be ignored.

{% highlight scala %}
import reactivemongo.bson.Macros.Annotations.Ignore

case class Foo(
  bar: String,
  @Ignore lastAccessed: Long = -1L
)
{% endhighlight %}

**Troubleshooting:**

The mapped type can also be defined inside other classes, objects or traits but not inside functions (known macro limitation). In order to work you should have the case class in scope (where you call the macro), so you can refer to it by it's short name - without package. This is necessary because the generated implementations refer to it by the short name to support nested declarations. You can work around this with local imports.

{% highlight scala %}
object lorem {
  case class Ipsum(v: String)
}

implicit val handler = {
  import lorem.Ipsum
  reactivemongo.bson.Macros.handler[Ipsum]
}
{% endhighlight %}

### Provided handlers

The following handlers are provided by ReactiveMongo, to read and write the [BSON values](../../api/reactivemongo/bson/).

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

#### Optional value

An optional value can be added to a document using the [`Option` type](http://www.scala-lang.org/api/current/index.html#scala.Option) (e.g. for an optional string, `Option[String]`).

Using [`BSONBooleanLike`](../../api/reactivemongo/bson/BSONBooleanLike), it is possible to read the following BSON values as boolean.

| BSON type     | Rule           |
| ------------- | -------------- |
| BSONInteger   | `true` if > 0  |
| BSONDouble    | `true` if > 0  |
| BSONNull      | always `false` |
| BSONUndefined | always `false` |

Using [`BSONNumberLike`](../../api/reactivemongo/bson/BSONNumberLike), it is possible to read the following BSON values as number.

- [`BSONInteger`](../../api/reactivemongo/bson/BSONInteger)
- [`BSONLong`](../../api/reactivemongo/bson/BSONLong)
- [`BSONDouble`](../../api/reactivemongo/bson/BSONDouble)
- [`BSONDateTime`](../../api/reactivemongo/bson/BSONDateTime): the number of milliseconds since epoch.
- [`BSONTimestamp`](../../api/reactivemongo/bson/BSONTimestamp): the number of milliseconds since epoch.

### Concrete examples

- [BigDecimal](example-bigdecimal.html)
- [Map](example-maps.html)
- [Document](example-document.html)

### Troubleshooting

When using the compiler option `-Ywarn-unused` and the BSON macro (e.g. `Macros.handler`), you can get a warning as bellow. It can be safely ignore (there for compatibility).

    private val in <$anon: reactivemongo.bson.BSONDocumentReader[foo.Bar] with reactivemongo.bson.BSONDocumentWriter[foo.Bar] with reactivemongo.bson.BSONHandler[reactivemongo.bson.BSONDocument,foo.Bar]> is never used

[Previous: Overview of the ReactiveMongo BSON library](overview.html)
