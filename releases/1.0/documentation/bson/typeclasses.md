---
layout: default
major_version: 1.0
title: BSON readers & writers
---

## BSON readers and writers

In order to [get](../tutorial/find-documents.html) and [store](../tutorial/write-documents.html) data with MongoDB, ReactiveMongo provides an extensible mechanism to appropriately read and write data from/to BSON.
This makes usage of MongoDB much less verbose and more natural.

This is articulated around the concept of [`BSONWriter`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONWriter.html) and [`BSONReader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONReader.html).

As long as you are working with [`BSONValue`s](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONValue), some [default implementations of readers and writers](#provided-handlers) are provided by the following import.

{% highlight scala %}
import reactivemongo.api.bson._
{% endhighlight %}

Some specific typeclasses are available to only work with BSON documents: [`BSONDocumentWriter`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDocumentWriter.html) and [`BSONDocumentReader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDocumentReader.html).

### Custom reader

Getting values follows the same principle using `getAsTry(String)` method. This method is parametrized with a type that can be transformed into a `BSONValue` using a `BSONReader` instance that is implicitly available in the scope (again, the default readers are already imported if you imported `reactivemongo.api.bson._`.) If the value could not be found, or if the reader could not deserialize it (often because the type did not match), `None` will be returned.

{% highlight scala %}
import reactivemongo.api.bson.BSONString

val albumTitle2 = album2.getAsTry[String]("title")
// Some("Everybody Knows this is Nowhere")

val albumTitle3 = album2.getAsTry[BSONString]("title")
// Some(BSONString("Everybody Knows this is Nowhere"))
{% endhighlight %}

In order to read values of custom types, a custom instance of [`BSONReader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONReader), or of [`BSONDocumentReader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONDocumentReader), must be resolved (in the implicit scope).

*A `BSONReader` for a custom class:*

{% highlight scala %}
package object custom {
  class Score(val value: Float)

  import reactivemongo.api.bson._

  implicit object ScoreReader extends BSONReader[Score] {
    def readTry(bson: BSONValue) =
      bson.asTry[BSONNumberLike].flatMap(_.toFloat).map(new Score(_))
  }
}
{% endhighlight %}

Once a custom `BSONReader` (or `BSONDocumentReader`) is defined, it can thus be used in `aDocument.getAsTry[MyValueType]("docProperty")`.

*A `BSONDocumentReader` for a custom case class:*

{% highlight scala %}
import reactivemongo.api.bson._

implicit object PersonReader extends BSONDocumentReader[Person] {
  def readDocument(bson: BSONDocument) = for {
    name <- bson.getAsTry[String]("fullName")
    age <- bson.getAsTry[BSONNumberLike]("personAge").flatMap(_.toInt)
  } yield new Person(name, age)
}
{% endhighlight %}

Once a custom `BSONDocumentReader` can be resolved, it can be used when working with a query result.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.api.bson.{ BSONDocument, BSONDocumentReader }
import reactivemongo.api.bson.collection.BSONCollection

// Provided the `Person` case class is defined, with its `BSONDocumentReader`
implicit def personReader: BSONDocumentReader[Person] = ???

def findPerson(personCollection: BSONCollection, name: String)(implicit ec: ExecutionContext): Future[Option[Person]] = personCollection.find(BSONDocument("fullName" -> name)).one[Person]
{% endhighlight %}

*See [how to find documents](../tutorial/find-documents.html).*

### Custom writer

It's also possible to write a value of a custom type, a custom instance of [`BSONWriter`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONWriter), or of [`BSONDocumentWriter`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONDocumentWriter) must be available.

{% highlight scala %}
import reactivemongo.api.bson._

case class Score(value: Float)

implicit object ScoreWriter extends BSONWriter[Score] {
  def writeTry(score: Score) =
    scala.util.Success(BSONDouble(score.value))
}

// Uses `BSONDouble` to write `Float`,
// for compatibility with MongoDB numeric values
{% endhighlight %}

Each value that can be written using a `BSONWriter` can be used directly when calling a `BSONDocument` constructor.

{% highlight scala %}
val album2 = reactivemongo.api.bson.BSONDocument(
  "title" -> "Everybody Knows this is Nowhere",
  "releaseYear" -> 1969)
{% endhighlight %}

Note that this does _not_ use implicit conversions, but rather implicit type classes.

{% highlight scala %}
import reactivemongo.api.bson._

// Declare it as implicit for resolution
val personWriter0: BSONDocumentWriter[Person] =
  BSONDocumentWriter[Person] { person =>
    BSONDocument("fullName" -> person.name, "personAge" -> person.age)
  }
{% endhighlight %}

Once a `BSONDocumentWriter` is available, an instance of the custom class can be inserted or updated to the MongoDB.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.BSONDocumentWriter
import reactivemongo.api.bson.collection.BSONCollection

// Provided the `Person` case class is defined, with its `BSONDocumentWriter`
implicit def personWriter: BSONDocumentWriter[Person] = ???

def create(personCollection: BSONCollection, person: Person)(implicit ec: ExecutionContext): Future[Unit] = {
  val writeResult = personCollection.insert.one(person)
  writeResult.map(_ => {/*once this is successful, just return successfully*/})
}
{% endhighlight %}

*See [how to write documents](../tutorial/write-documents.html).*

### Utility factories

Some factories are available to create handlers for common types.

**Iterable:**

Factories to handle BSON array are provided: `{ BSONReader, BSONWriter }.{ iterable, sequence }`

{% highlight scala %}
import reactivemongo.api.bson.{ BSONReader, BSONWriter, Macros }

case class Element(str: String, v: Int)

val elementHandler = Macros.handler[Element]

val setReader: BSONReader[Set[Element]] =
  BSONReader.iterable[Element, Set](elementHandler readTry _)

val seqWriter: BSONWriter[Seq[Element]] =
  BSONWriter.sequence[Element](elementHandler writeTry _)

// ---

import reactivemongo.api.bson.{ BSONArray, BSONDocument }

val fixture = BSONArray(
  BSONDocument("str" -> "foo", "v" -> 1),
  BSONDocument("str" -> "bar", "v" -> 2))

setReader.readTry(fixture)
// Success: Set(Element("foo", 1), Element("bar", 2))

seqWriter.writeTry(Seq(Element("foo", 1), Element("bar", 2)))
// Success: fixture
{% endhighlight %}

**Tuples:**

Factories to create handler for tuple types (up to 5-arity) are provided.

If an array is the wanted BSON representation:

{% highlight scala %}
import reactivemongo.api.bson.{ BSONArray, BSONReader, BSONWriter }

val readerArrAsStrInt = BSONReader.tuple2[String, Int]
val writerStrIntToArr = BSONWriter.tuple2[String, Int]

val arr = BSONArray("Foo", 20)

readerArrAsStrInt.readTry(arr) // => Success(("Foo", 20))

writerStrIntToArr.writeTry("Foo" -> 20)
// => Success: arr = ['Foo', 20]
{% endhighlight %}

If a document representation is wanted: 

{% highlight scala %}
import reactivemongo.api.bson.{
  BSONDocument, BSONDocumentReader, BSONDocumentWriter
}

val writerStrIntToDoc = BSONDocumentWriter.tuple2[String, Int]("name", "age")

writerStrIntToDoc.writeTry("Foo" -> 20)
// => Success: {'name': 'Foo', 'age': 20}

val readerDocAsStrInt = BSONDocumentReader.tuple2[String, Int]("name", "age")

reader.readTry(BSONDocument("name" -> "Foo", "age" -> 20))
// => Success(("Foo", 20))
{% endhighlight %}

<!-- TODO: collectFrom partial -->

### Macros

To ease the implementation of readers or writers for your custom types (case classes and sealed traits), ReactiveMongo provides some helper [Macros](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/Macros).

{% highlight scala %}
case class Person(name: String, age: Int)

import reactivemongo.api.bson._

val personHandler: BSONDocumentHandler[Person] = Macros.handler[Person]

// Or only ...
val separatePersonReader: BSONDocumentReader[Person] = Macros.reader[Person]
val separatePersonWriter: BSONDocumentWriter[Person] = Macros.writer[Person]
{% endhighlight %}

The [`BSONHandler`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONHandler) provided by [`Macros.handler`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$#handler[A]:reactivemongo.api.bson.BSONDocumentReader[A]withreactivemongo.api.bson.BSONDocumentWriter[A]withreactivemongo.api.bson.BSONHandler[reactivemongo.api.bson.BSONDocument,A]) gathers both `BSONReader` and `BSONWriter` traits.

The [`Macros.reader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$#reader[A]:reactivemongo.api.bson.BSONDocumentReader[A]) can be used to generate only the `BSONReader`, while the [`Macros.writer`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$#writer[A]:reactivemongo.api.bson.BSONDocumentWriter[A]) is for `BSONWriter`.

The `A` type parameter (e.g. with `A` being `Person`, `Macros.reader[Person]`) defines a type for a case class, or for a [sealed trait](http://docs.scala-lang.org/tutorials/tour/traits.html) with subclasses.
This type will be the basis for the auto-generated implementation.

> Some other types with matching `apply`-`unapply` might work but behaviour is undefined. Since macros will match the `apply`-`unapply` pair you are free to overload these methods in the companion object.

**Case class mapping:**

For the case classes, the fields get mapped into BSON properties with respective names, and BSON handlers are pulled from implicit scope to (de)serialize them (in the previous `Person` example, the handlers for `String` are resolved for the `name` property).

So in order to use custom types as properties in case classes, the appropriate handlers are in scope.

For example if you have `case class Foo(bar: Bar)` and want to create a handler for it is enough to put an implicit handler for `Bar` in it's companion object. That handler might itself be macro generated, or written by hand.

> The macros are currently limited to case classes whose constructor doesn't take more than 22 parameters (due to Scala not generating `apply` and `unapply` in the other cases).

The default values for the class properties can be used by BSON reader when the corresponding BSON value is missing, with `MacroOptions.ReadDefaultValues`.

{% highlight scala %}
import reactivemongo.api.bson.{
  BSONDocument, BSONDocumentReader, Macros, MacroOptions
}

case class FooWithDefault1(id: Int, title: String = "default")

{
  val reader: BSONDocumentReader[FooWithDefault1] =
    Macros.using[MacroOptions.ReadDefaultValues].reader[FooWithDefault1]

  reader.readTry(BSONDocument("id" -> 1)) // missing BSON title
  // => Success: FooWithDefault1(id = 1, title = "default")
}
{% endhighlight %}

**Sealed trait and union types:**

Sealed traits are also supported as [union types](https://en.wikipedia.org/wiki/Union_type), with each of their subclasses considered as a disjoint case.

{% highlight scala %}
import reactivemongo.api.bson.{ BSONHandler, Macros }

sealed trait Tree
case class Node(left: Tree, right: Tree) extends Tree
case class Leaf(data: String) extends Tree

object Tree {
  implicit val node = Macros.handler[Node]
  implicit val leaf = Macros.handler[Leaf]

  implicit val bson: BSONHandler[Tree] = Macros.handler[Tree]
}
{% endhighlight %}

The `handler`, `reader` and `writer` macros each have a corresponding extended macro: [`readerOpts`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$#readerOpts[A,Opts%3C:reactivemongo.api.bson.MacroOptions.Default]:reactivemongo.api.bson.BSONDocumentReader[A]), [`writerOpts`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$#writerOpts[A,Opts%3C:reactivemongo.api.bson.MacroOptions.Default]:reactivemongo.api.bson.BSONDocumentWriter[A]) and [`handlerOpts`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$#handlerOpts[A,Opts%3C:reactivemongo.api.bson.MacroOptions.Default]:reactivemongo.api.bson.BSONDocumentReader[A]withreactivemongo.api.bson.BSONDocumentWriter[A]withreactivemongo.api.bson.BSONHandler[reactivemongo.api.bson.BSONDocument,A]).

These 'Opts' suffixed macros can be used to explicitly define the [`UnionType`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/MacroOptions$@UnionType[Types%3C:reactivemongo.api.bson.MacroOptions.\/[_,_]]extendsMacroOptions.SaveClassNamewithMacroOptions.Default).

{% highlight scala %}
sealed trait Color

case object Red extends Color
case object Blue extends Color
case class Green(brightness: Int) extends Color
case class CustomColor(code: String) extends Color

object Color {
  import reactivemongo.api.bson.Macros
  import reactivemongo.api.bson.MacroOptions.{
    AutomaticMaterialization, UnionType, \/
  }

  // Use `UnionType` to define a subset of the `Color` type,
  type PredefinedColor =
    UnionType[Red.type \/ Green \/ Blue.type] with AutomaticMaterialization

  val predefinedColor = Macros.handlerOpts[Color, PredefinedColor]
}
{% endhighlight %}

As for the `UnionType` definition, `Foo \/ Bar \/ Baz` is interpreted as type `Foo` or type `Bar` or type `Baz`. The option `AutomaticMaterialization` is used there to automatically try to materialize the handlers for the sub-types (disabled by default).

The other options available to configure the typeclasses generation at compile time are the following.

- [`Verbose`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/MacroOptions$@VerboseextendsMacroOptions.Default): Print out generated code during compilation.
- [`SaveClassName`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/MacroOptions$@SaveClassNameextendsMacroOptions.Default): Indicate to the `BSONWriter` to add a "className" field in the written document along with the other properties. The value for this meta field is the fully qualified name of the class. This is the default behaviour when the target type is a sealed trait (the "className" field is used as discriminator).

**Value classes**

Specific macros are new available for [Value classes](https://docs.scala-lang.org/overviews/core/value-classes.html) (any type which complies with `<: AnyVal`).

{% highlight scala %}
package object values {
  import reactivemongo.api.bson.{ BSONHandler, BSONReader, BSONWriter, Macros }

  final class FooVal(val value: String) extends AnyVal

  val vh: BSONHandler[FooVal] = Macros.valueHandler[FooVal]
  val vr: BSONReader[FooVal] = Macros.valueReader[FooVal]
  val vw: BSONWriter[FooVal] = Macros.valueWriter[FooVal]
}
{% endhighlight %}

#### Configuration

This macro utilities offer [configuration mechanism](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroConfiguration.html).

The macro configuration can be used to specify a [field naming](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/FieldNaming.html), to customize the name of each BSON field corresponding to Scala field.

{% highlight scala %}
import reactivemongo.api.bson._

val withPascalCase: BSONDocumentHandler[Person] = {
  implicit def cfg: MacroConfiguration = MacroConfiguration(
    fieldNaming = FieldNaming.PascalCase)

  Macros.handler[Person]
}

withPascalCase.writeTry(Person(name = "Jane", age = 32))
/* Success {
  BSONDocument("Name" -> "Jane", "Age" -> 32)
} */
{% endhighlight %}

In a similar way, when using macros with sealed family/trait, the strategy to name the [discriminator field](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroConfiguration.html#discriminator:String) and to set a Scala type as [discriminator value](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/TypeNaming.html) can be configured.

{% highlight scala %}
import reactivemongo.api.bson._

sealed trait Family1
case class Foo1(bar: String) extends Family1
case class Lorem1(ipsum: Int) extends Family1

implicit val foo1Handler = Macros.handler[Foo1]
implicit val lorem1Handler = Macros.handler[Lorem1]

val family1Handler: BSONDocumentHandler[Family1] = {
  implicit val cfg: MacroConfiguration = MacroConfiguration(
    discriminator = "_type",
    typeNaming = TypeNaming.SimpleName.andThen(_.toLowerCase))

  Macros.handler[Family1]
}
{% endhighlight %}

#### Annotations

Some annotations are also available to configure the macros.

The [`@Key`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$Key.html) annotation allows to specify the field name for a class property.

For example, it is convenient to use when you'd like to leverage the MongoDB `_id` index but you don't want to actually use `_id` in your code.

{% highlight scala %}
import reactivemongo.api.bson.Macros.Annotations.Key

case class Website(@Key("_id") url: String)
// Generated handler will map the `url` field in your code to as `_id` field
{% endhighlight %}

The [`@Ignore`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$Ignore.html) can be applied on the class properties to be ignored.

{% highlight scala %}
import reactivemongo.api.bson.Macros.Annotations.Ignore

case class Foo(
  bar: String,
  @Ignore lastAccessed: Long = -1L
)
{% endhighlight %}

When a field annotated with `@Ignore` must be read (using `Macros.reader` or `Macros.handler`), then a default value must be defined for this field, either using standard Scala syntax (in previous example ` = -1`) or using `@DefaultValue` annotation (see below).

The [`@Flatten`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$Flatten.html) can be used to indicate to the macros that the representation of a property must be flatten rather than a nested document.

{% highlight scala %}
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.Macros.Annotations.Flatten

case class Range(start: Int, end: Int)

case class LabelledRange(
  name: String,
  @Flatten range: Range)

// Flattened with macro as bellow:
BSONDocument("name" -> "foo", "start" -> 0, "end" -> 1)

// Rather than:
// BSONDocument("name" -> "foo", "range" -> BSONDocument(
//   "start" -> 0, "end" -> 1))
{% endhighlight %}

The [`@DefaultValue`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$DefaultValue.html) can be used with `MacroOptions.ReadDefaultValues` to specify a default value only used when reading from BSON.

{% highlight scala %}
import reactivemongo.api.bson.{
  BSONDocument, BSONDocumentReader, Macros, MacroOptions
}
import Macros.Annotations.DefaultValue

case class FooWithDefault2(
  id: Int,
  @DefaultValue("default") title: String)

{
  val reader: BSONDocumentReader[FooWithDefault2] =
    Macros.using[MacroOptions.ReadDefaultValues].reader[FooWithDefault2]

  reader.readTry(BSONDocument("id" -> 1)) // missing BSON title
  // => Success: FooWithDefault2(id = 1, title = "default")
}
{% endhighlight %}

The [`@Reader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$Reader.html) allows to indicate a specific BSON reader that must be used for a property, instead of resolving such reader from the implicit scope.

{% highlight scala %}
import reactivemongo.api.bson.{
  BSONDocument, BSONDouble, BSONString, BSONReader
}
import reactivemongo.api.bson.Macros,
  Macros.Annotations.Reader

val scoreReader: BSONReader[Double] = BSONReader.collect[Double] {
  case BSONString(v) => v.toDouble
  case BSONDouble(b) => b
}

case class CustomFoo1(
  title: String,
  @Reader(scoreReader) score: Double)

val reader = Macros.reader[CustomFoo1]

reader.readTry(BSONDocument(
  "title" -> "Bar",
  "score" -> "1.23" // accepted by annotated scoreReader
))
// Success: CustomFoo1(title = "Bar", score = 1.23D)
{% endhighlight %}

In a similar way, the [`@Writer`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$Writer.html) allows to indicate a specific BSON writer that must be used for a property, instead of resolving such writer from the implicit scope.

{% highlight scala %}
import reactivemongo.api.bson.{ BSONString, BSONWriter }
import reactivemongo.api.bson.Macros,
  Macros.Annotations.Writer

val scoreWriter: BSONWriter[Double] = BSONWriter[Double] { d =>
  BSONString(d.toString) // write double as string
}

case class CustomFoo2(
  title: String,
  @Writer(scoreWriter) score: Double)

val writer = Macros.writer[CustomFoo2]

writer.writeTry(CustomFoo2(title = "Bar", score = 1.23D))
// Success: BSONDocument("title" -> "Bar", "score" -> "1.23")
{% endhighlight %}

**Troubleshooting:**

The mapped type can also be defined inside other classes, objects or traits but not inside functions (known macro limitation). In order to work you should have the case class in scope (where you call the macro), so you can refer to it by it's short name - without package. This is necessary because the generated implementations refer to it by the short name to support nested declarations. You can work around this with local imports.

{% highlight scala %}
object lorem {
  case class Ipsum(v: String)
}

implicit val handler = {
  import lorem.Ipsum
  reactivemongo.api.bson.Macros.handler[Ipsum]
}
{% endhighlight %}

### Provided handlers

The following handlers are provided by ReactiveMongo, to read and write the [BSON values](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/).

| BSON type    | Value type        |
| ------------ | ----------------- |
| BSONArray    | Any collection    |
| BSONBinary   | Array[Byte]       |
| BSONBoolean  | Boolean           |
| BSONDocument | Map[K, V]         |
| BSONDateTime | java.time.Instant |
| BSONDouble   | Double            |
| BSONInteger  | Int               |
| BSONLong     | Long              |
| BSONString   | String            |

#### Optional value

An optional value can be added to a document using the [`Option` type](http://www.scala-lang.org/api/current/index.html#scala.Option) (e.g. for an optional string, `Option[String]`).

Using [`BSONBooleanLike`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONBooleanLike), it is possible to read the following BSON values as boolean.

| BSON type     | Rule           |
| ------------- | -------------- |
| BSONInteger   | `true` if > 0  |
| BSONDouble    | `true` if > 0  |
| BSONNull      | always `false` |
| BSONUndefined | always `false` |

Using [`BSONNumberLike`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONNumberLike), it is possible to read the following BSON values as number.

- [`BSONInteger`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONInteger)
- [`BSONLong`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONLong)
- [`BSONDouble`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONDouble)
- [`BSONDateTime`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONDateTime): the number of milliseconds since epoch.
- [`BSONTimestamp`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/BSONTimestamp): the number of milliseconds since epoch.

#### `Map` handler

A handler is available to write and read Scala `Map` as BSON, provided the value types are supported.

{% highlight scala %}
import scala.util.Try
import reactivemongo.api.bson._

def bsonMap = {
  val input: Map[String, Int] = Map("a" -> 1, "b" -> 2)

  // Ok as key and value (String, Int) are provided BSON handlers
  val doc: Try[BSONDocument] = BSON.writeDocument(input)

  val output = doc.flatMap { BSON.readDocument[Map[String, Int]](_) }
}
{% endhighlight %}

For cases where you can to serialize a `Map` whose key type is not `String` (which is required for BSON document keys), the typeclasses [`KeyWriter`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/KeyWriter.html) and [`KeyReader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/KeyReader.html) can be used.

{% highlight scala %}
import scala.util.Try
import reactivemongo.api.bson._

final class FooKey(val value: String)

object FooKey {
  val bar = new FooKey("bar")
  val lorem = new FooKey("lorem")

  implicit val keyWriter: KeyWriter[FooKey] = KeyWriter[FooKey](_.value)

  implicit val keyReader: KeyReader[FooKey] =
    KeyReader[FooKey] { new FooKey(_) }

}

def bsonMapCustomKey = {
  val input: Map[FooKey, Int] = Map(
    FooKey.bar -> 1, FooKey.lorem -> 2)

  // Ok as key and value (String, Int) are provided BSON handlers
  val doc: Try[BSONDocument] = BSON.writeDocument(input)

  val output = doc.flatMap { BSON.readDocument[Map[FooKey, Int]](_) }
}
{% endhighlight %}

### Concrete examples

- [BigDecimal](example-bigdecimal.html)
- [Document](example-document.html)

### Troubleshooting

Make sure an instance of `KeyReader` (or `KeyWriter`) can be resolved from the implicit scope for the key type.

{% highlight text %}{% raw %}
could not find implicit value for parameter e: reactivemongo.api.bson.BSONDocumentReader[Map[..not string..,String]]
{% endraw %}{% endhighlight %}

[Previous: Overview of the ReactiveMongo BSON library](overview.html) / [Next: BSON extra libraries](extra.html)
