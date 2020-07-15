---
layout: default
major_version: 1.0
title: Release details
---

## ReactiveMongo {{site._1_0_latest_minor}} – Release details

{% if site._1_0_latest_minor contains "-rc." %}
<strong style="color:red">This is a Release Candidate</strong>
{% endif %}

<!--
TODO: JSON compat ~> ~/Projects/ReactiveMongo-Play-Json/compat/src/test/scala/HandlerUseCaseSpec.scala

-->

**What's new?**

The documentation is available [online](index.html), and its code samples are compiled to make sure it's up-to-date.

- [Compatibility](#compatibility)
- [Migration](#migration)
- [Connection](#connection)
  - Support [x.509 certificate](https://docs.mongodb.com/manual/tutorial/configure-x509-client-authentication/) to authenticate.
  - Support [DNS seedlist](https://docs.mongodb.com/manual/reference/connection-string/#dns-seedlist-connection-format) in the connection URI.
  - New `heartbeatFrequencyMS` setting.
  - Add `credentials` in the [`MongoConnectionOptions`](http://reactivemongo.org/releases/0.1x/api/reactivemongo/api/MongoConnectionOptions.html)
  - [Netty native](#netty-native)
- [BSON library](#bson-library)
  - [Documents and values](#documents-and-values)
  - [Reader and writer typeclasses](#reader-and-writer-typeclasses)
  - [Macros](#macros)
    - `Option` support & [`@NoneAsNull`](#none-as-null)
    - [`@Flatten`](#a-flatten)
    - [`@DefaultValue`](#a-defaultvalue)
    - [`@Reader`](#a-reader) & [`@Writer`](#a-writer)
  - [Extra libraries](#extra-libraries)
    - [GeoJSON](#geojson)
    - [Monocle](#monocle)
    - [Specs2](#specs2)
- [Query and write operations](#query-and-write-operations),
  - Bulk operations (e.g. `.delete.many`) on [collection](../api/reactivemongo/api/collections/GenericCollection.html),
  - `arrayFilters` on update operations.
- [Play](#play)
- [Aggregation](#aggregation)
  - [`CursorOptions`](../api/reactivemongo/api/CursorOptions.html) parameter when using `.aggregatorContext`.
  - New stages: `$addFields`, `$bucketAuto`, `$count`, `$filter`, `$replaceRoot`, `$search`, `$slice`
  - [Change stream](#change-stream)
- [GridFS](#gridfs)
- [Monitoring](#monitoring)
- [Administration](#administration)
- [Breaking changes](#breaking-changes)

<!-- TODO: Slideshow -->

### Compatibility

This release is compatible with the following runtime.

- [MongoDB](https://www.mongodb.org/) from 3.0 up to 4.2.
- [Scala](https://www.scala-lang.org) from 2.11 to 2.13.
- [Akka](http://akka.io/) from 2.3.13 up to 2.5.23 (see [Setup](./tutorial/setup.html))
- [Play Framework](https://playframework.com) from 2.3.13 to 2.8.1

> MongoDB versions older than 3.0 are not longer (end of life 2018-2).

**Recommended configuration:**

The driver core and the modules are tested in a [container based environment](https://docs.travis-ci.com/user/ci-environment/#Virtualization-environments), with the specifications as bellow.

- 2 [cores](https://cloud.google.com/compute/) (64 bits)
- 4 GB of system memory, with a maximum of 2 GB for the JVM

This can be considered as a recommended environment.

### Migration

A Scalafix module is available to migrate from ReactiveMongo 0.12+ to 1.0 (not yet available for Scala 2.13).

To apply the migration rules, first [setup Scalafix](https://scalacenter.github.io/scalafix/docs/users/installation.html) in the SBT build, then configure the ReactiveMongo rules as bellow.

{% highlight ocaml %}
scalafixDependencies in ThisBuild ++= Seq(
  "org.reactivemongo" %% "reactivemongo-scalafix" % "{{site._1_0_latest_minor}}")
{% endhighlight %}

Once the rules are configured, they can be applied from SBT.

{% highlight sh %}
scalafix ReactiveMongoUpgrade
scalafix ReactiveMongoLinter --check
{% endhighlight %}

Then upgrade the appropriate `libraryDependencies` in the SBT build, and re-recompile it.

{% highlight sh %}
sbt clean compile
{% endhighlight %}

Finally, apply manually the remaining fixes due to the breaking changes.

*[Suggest an improvement](https://github.com/ReactiveMongo/ReactiveMongo-Scalafix/issues/new/choose) to these rules*

### Connection

The `MongoDriver` type is replaced by `AsyncDriver`, with asynchronous methods.

- `MongoDriver.connection` replaced by [`AsyncDriver.connect`](../api/reactivemongo/api/AsyncDriver.html#connect(uriStrict:String):scala.concurrent.Future[reactivemongo.api.MongoConnection])
- `close` is asynchronous.

The utility function `MongoConnection.parseURI` is replaced by asynchronous function [`.fromString`](../api/reactivemongo/api/MongoConnection$.html#fromString(uri:String)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.MongoConnection.ParsedURI]).

Also, the following options are deprecated:

- `authSource` replaced by `authenticationDatabase` (as the MongoShell option)
- `authMode` replaced by `authenticationMechanism` (as the MongoShell option)
- `sslEnabled` replaced by `ssl` (as the MongoShell option)
- `rm.monitorRefreshMS` replaced by `heartbeatFrequencyMS`

New options:

- `heartbeatFrequencyMS`

> [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) is now supported for the SSL connection.

The [x.509 certificate authentication](https://docs.mongodb.com/manual/tutorial/configure-x509-client-authentication/) is now supported, and can be configured by setting `x509` as `authenticationMechanism`, and with the following new options.

- **`keyStore`**: An URI to a key store (e.g. `file:///path/to/keystore.p12`)
- **`keyStorePassword`**: Provides the password to load it (if required)
- **`keyStoreType`**: Indicates the [type of the store](https://docs.oracle.com/javase/7/docs/technotes/guides/security/StandardNames.html#KeyStore)

{% highlight scala %}
import reactivemongo.api._

def connection(driver: AsyncDriver) =
  driver.connect("mongodb://server:27017/db?ssl=true&authenticationMechanism=x509&keyStore=file:///path/to/keystore.p12&keyStoreType=PKCS12")
{% endhighlight %}

The [DNS seedlist](https://docs.mongodb.com/manual/reference/connection-string/#dns-seedlist-connection-format) is now supported, using `mongodb+srv://` scheme in the connection URI.
It's also possible to specify the credential directly in the URI.

{% highlight scala %}
import reactivemongo.api._

def seedListCon(driver: AsyncDriver) =
  driver.connect("mongodb+srv://usr:pass@mymongo.mydomain.tld/mydb")
{% endhighlight %}

The option `rm.monitorRefreshMS` is renamed [`heartbeatFrequencyMS`](https://github.com/mongodb/specifications/blob/master/source/server-discovery-and-monitoring/server-discovery-and-monitoring.rst#heartbeatfrequencyms).

*[See documentation](./tutorial/connect-database.html)*

#### Netty native

The internal [Netty](http://netty.io/) dependency has been updated to the version [4.1](http://netty.io/wiki/new-and-noteworthy-in-4.1.html).

It comes with various improvements (memory consumption, ...), and also to use Netty native support (kqueue for Mac OS X and epoll for Linux, on `x86_64` arch).

> Note that the Netty dependency is [shaded](https://maven.apache.org/plugins/maven-shade-plugin/) so it won't conflict with any Netty version in your environment.

*[See documentation](./tutorial/connect-database.html#netty-native)*

### BSON library

The Biːsən is the new default BSON library, that fixes some issues ([OOM](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/memleaks002.html)), and brings multiple API and performance improvements (simpler & better).

**Highlights:**

- Simpler and more efficient API
- New [GeoJSON](./extra.html#geojson) library
- New [Monocle](./extra.html#monocle) (optics) library
- New [Specs2](./extra.html#specs) library

#### Documents and values

The API for [`BSONDocument`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDocument.html) has been slightly updated, with the function `getAs` renamed as `getAsOpt` (to be consistent with `getAsTry`).

New `getOrElse` function is also added.

{% highlight scala %}
import reactivemongo.api.bson._

def withFallback(doc: BSONDocument): String = {
  doc.getOrElse[String]("strField", "defaultValue")
  // Equivalent to: doc.getAsOpt[String]("strField").getOrElse("defaultValue")
}
{% endhighlight %}

New field utilities are provided for the most common types:

{% highlight scala %}
import reactivemongo.api.bson._

def foo(doc: BSONDocument): Unit = {
  val i: Option[Int] = doc.int("fieldNameInt")
  val d: Option[Double] = doc.double("fieldNameDouble")
  val l: Option[Long] = doc.long("fieldNameLong")
  val s: Option[String] = doc.string("fieldNameStr")
  val a: Option[Seq[BSONValue]] = doc.array("fieldNameArr")
  val b: Option[Boolean] = doc.booleanLike("fieldNameBool")
  val c: Option[BSONDocument] = doc.child("nestedDoc")
  val _: List[BSONDocument] = doc.children("arrayOfDocs")
}
{% endhighlight %}

> Note: The `BSONDocument` and `BSONArray` factories have been optimized and support more use cases.

<figure>
  <img src="./images/bison-bench-doc.png"
    style="max-width:75%" alt="Document benchmarks" />

  <figcaption style="font-size:x-small">Coefficient between new/old throughput (op/s; =1: no change, 1+: better thrpt). Source: <a rel="me external" href="https://github.com/ReactiveMongo/ReactiveMongo-BSON/blob/master/benchmarks/src/main/scala/BSONDocumentBenchmark.scala">BSONDocumentBenchmark</a>, <a rel="me external" href="https://github.com/ReactiveMongo/ReactiveMongo-BSON/blob/master/benchmarks/src/main/scala/BSONDocumentHandlerBenchmark.scala">BSONDocumentHandlerBenchmark</a></figcaption>
</figure>

<figure>
  <img src="./images/bison-bench-array.png"
    style="max-width:75%" alt="Array benchmarks" />

  <figcaption style="font-size:x-small">Coefficient between new/old throughput (op/s; =1: no change, 1+: better thrpt). Source: <a rel="me external" href="https://github.com/ReactiveMongo/ReactiveMongo-BSON/blob/master/benchmarks/src/main/scala/BSONArrayBenchmark.scala">BSONArrayBenchmark</a></figcaption>
</figure>

The Biːsən library supports [BSON Decimal128](https://github.com/mongodb/specifications/blob/master/source/bson-decimal128/decimal128.rst#bson-decimal128-type-handling-in-drivers) (MongoDB 3.4+).

*[See documentation](./bson/overview.html)*

#### Reader and writer typeclasses

The names of these typeclasses are unchanged ([`BSONReader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONReader.html) and [`BSONWriter`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONWriter.html)), except the package that is `reactivemongo.api.bson` (instead of `reactivemongo.bson`).

In the previous BSON library, `BSONReader` and `BSONWriter` are defined with two type parameters:

{% highlight ocaml %}
BSONReader[B <: BSONValue, T]

BSONWriter[T, B <: BSONValue]
{% endhighlight %}

- `B` being the type of BSON value to be read/written,
- and `T` being the Scala type to be handled.

The new API has been simplified, with only the `T` type parameter kept.

{% highlight scala %}
import reactivemongo.api.bson._

// read a String from BSON, whatever is the specific BSON value type
def stringReader: BSONReader[String] = ???
{% endhighlight %}

Not only it makes the API simpler, but it also allows to read different BSON types as a target Scala type (before only supported for numeric/boolean, using the dedicated typeclasses).
For example, the Scala numeric types (`BigDecimal`, `Double`, `Float`, `Int`, `Long`) can be directly read from any consistent BSON numeric type (e.g. `1.0` as integer `1`), without having to use `BSONNumberLike`.

Also, handler functions [`readTry`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONHandler.html#readTry(bson:reactivemongo.api.bson.BSONValue):scala.util.Try[T]) and [`writeTry`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONHandler.html#writeTry(t:T):scala.util.Try[reactivemongo.api.bson.BSONValue]) returns `Try`, for a safer representation of possible failures.

The new API is also safer, replacing `BSONReader.read` and `BSONWriter.write` respectively with `BSONReader.readTry` and `BSONWriter.writeTry`, so that serialization errors can be handle at typelevel.
In a similar way, [`BSONObjectID.parse`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONObjectID$.html#parse(bytes:Array[Byte]):scala.util.Try[reactivemongo.api.bson.BSONObjectID]) now returns `Try`.

Like the current BSON library, some specific typeclasses are available (with same names) to only work with BSON documents: `BSONDocumentReader` and `BSONDocumentWriter`.

Some new handlers are provided by default, like those for [Java Time](https://docs.oracle.com/javase/8/docs/api/java/time/package-summary.html) types.

> Note: The handler for `java.util.Date` is replaced the handler for `java.time.Instant`.

The error handling has also been improved, with more details (Note: `DocumentKeyNotFoundException` is the previous API is replaced with `BSONValueNotFoundException` in the new one).

<figure>
  <img src="./images/bison-bench-reader.png"
    style="max-width:75%" alt="Reader benchmarks" />

  <figcaption style="font-size:x-small">Coefficient between new/old throughput (op/s; =1: no change, 1+: better thrpt). Source: <a rel="me external" href="https://github.com/ReactiveMongo/ReactiveMongo-BSON/blob/master/benchmarks/src/main/scala/">BSON reader benchmarks</a></figcaption>
</figure>

**`Map` handler:**

A handler is now available to write and read Scala `Map` as BSON, provided the value types are supported.

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

For cases where you can to serialize a `Map` whose key type is not `String` (which is required for BSON document keys), new typeclasses [`KeyWriter`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/KeyWriter.html) and [`KeyReader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/KeyReader.html) have been introduced.

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

**`Iterable` factories:**

New factories to handle BSON array are provided: `{ BSONReader, BSONWriter }.{ iterable, sequence }`

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

**Tuple factories:**

New factories to create handler for tuple types (up to 5-arity) are provided.

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

**Partial function:**

There are new factories based on partial functions: `collect` and `collectFrom`.

*BSON reader:*

{% highlight scala %}
import reactivemongo.api.bson.{ BSONReader, BSONInteger }

val intToStrCodeReader = BSONReader.collect[String] {
  case BSONInteger(0) => "zero"
  case BSONInteger(1) => "one"
}

intToStrCodeReader.readTry(BSONInteger(0)) // Success("zero")

intToStrCodeReader.readTry(BSONInteger(2))
// => Failure(ValueDoesNotMatchException(..))
{% endhighlight %}

*BSON writer:*

{% highlight scala %}
import scala.util.Success
import reactivemongo.api.bson.{ BSONWriter, BSONInteger }

val strCodeToIntWriter = BSONWriter.collect[String] {
  case "zero" => BSONInteger(0)
  case "one" => BSONInteger(1)
}

strCodeToIntWriter.writeTry("zero") // Success(BSONInteger(0))

strCodeToIntWriter.writeTry("3")
// => Failure(IllegalArgumentException(..))
{% endhighlight %}

*BSON document writer:*

{% highlight scala %}
import reactivemongo.api.bson.{ BSONDocument, BSONDocumentWriter }

case class Bar(value: String)

val writer2 = BSONDocumentWriter.collectFrom[Bar] {
  case Bar(value) if value.nonEmpty =>
    scala.util.Success(BSONDocument("value" -> value))
}
{% endhighlight %}

#### Macros

The new library also provide similar macros, to easily materialized document readers and writers for Scala case classes and sealed traits.

{% highlight scala %}
case class Person(name: String, age: Int)

import reactivemongo.api.bson._

val personHandler: BSONDocumentHandler[Person] = Macros.handler[Person]

// Or only ...
val personReader: BSONDocumentReader[Person] = Macros.reader[Person]
val personWriter: BSONDocumentWriter[Person] = Macros.writer[Person]
{% endhighlight %}

This macro utilities offer new [configuration mechanism](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroConfiguration.html).

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

The nested type `Macros.Options` is replaced by similar type [`MacrosOptions`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroOptions.html).

> Note: The `Macros.Options.SaveSimpleName` of the previous BSON library has been removed in favour of a [configuration factory](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroConfiguration$.html#simpleTypeName[Opts%3C:reactivemongo.api.bson.MacroOptions](implicitevidence$2:reactivemongo.api.bson.MacroOptions.ValueOf[Opts]):reactivemongo.api.bson.MacroConfiguration.Aux[Opts]) using similar `TypeNaming`.

The compile-time option `AutomaticMaterialization` has been added, when using the macros with sealed family, to explicitly indicate when you want to automatically materialize required instances for the subtypes (if missing from the implicit scope).

{% highlight scala %}
sealed trait Color

case object Red extends Color
case object Blue extends Color
case class Green(brightness: Int) extends Color
case class CustomColor(code: String) extends Color

object Color {
  import reactivemongo.api.bson.{ Macros, MacroOptions },
    MacroOptions.{ AutomaticMaterialization, UnionType, \/ }

  // Use `UnionType` to define a subset of the `Color` type,
  type PredefinedColor =
    UnionType[Red.type \/ Green \/ Blue.type] with AutomaticMaterialization

  val predefinedColor = Macros.handlerOpts[Color, PredefinedColor]
}
{% endhighlight %}

> Note: A new option `MacroOptions.DisableWarnings` allows to specifically exclude macro warnings.

Using the new option `MacroOptions.ReadDefaultValues`, the default values can be used by BSON reader when there is no corresponding BSON value.

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

New macros for [Value classes](https://docs.scala-lang.org/overviews/core/value-classes.html) are new available.

{% highlight scala %}
package object relexamples {
  import reactivemongo.api.bson.{ BSONHandler, BSONReader, BSONWriter, Macros }

  final class FooVal(val value: String) extends AnyVal

  val vh: BSONHandler[FooVal] = Macros.valueHandler[FooVal]
  val vr: BSONReader[FooVal] = Macros.valueReader[FooVal]
  val vw: BSONWriter[FooVal] = Macros.valueWriter[FooVal]
}
{% endhighlight %}

**Annotations:**

The way `Option` is handled by the macros has been improved, also with a new annotation <span id="none-as-null">`@NoneAsNull`</span>, which write `None` values as `BSONNull` (instead of omitting field/value).

A <span id="a-flatten">new annotation [`@Flatten`](../api/reactivemongo/bson/Macros$$Annotations$$Flatten.html)</span> has been added, to indicate to the macros that the representation of a property must be flatten rather than a nested document.

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

The new <span id="a-defaultvalue">[`@DefaultValue`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$DefaultValue.html)</span> can be used with `MacroOptions.ReadDefaultValues` to specify a default value only used when reading from BSON.

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

The new <span id="a-reader">[`@Reader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$Reader.html)</span> allows to indicate a specific BSON reader that must be used for a property, instead of resolving such reader from the implicit scope.

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

In a similar way, the new <span id="a-writer">[`@Writer`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$Writer.html)</span> allows to indicate a specific BSON writer that must be used for a property, instead of resolving such writer from the implicit scope.

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

#### Extra libraries

Some [extra libraries](./bson/extra.html) are provided along the new BSON one, to improve the integration.

<strong id="geojson">[GeoJSON](./bson/extra.html#geojson):</strong>

A new [GeoJSON](https://docs.mongodb.com/manual/reference/geojson/) library is provided, with the geometry types and the corresponding handlers to read from and write them to appropriate BSON representation.

It can be configured in the `build.sbt` as below.

{% highlight ocaml %}
libraryDependencies += "org.reactivemongo" %% "reactivemongo-bson-geo" % "{{site._1_0_latest_minor}}"
{% endhighlight %}

*See [Scaladoc](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/index.html)*

<strong id="monocle">[Monocle](./bson/extra.html#monocle):</strong>

The library that provides [Monocle](http://julien-truffaut.github.io/Monocle/) based optics, for BSON values.

It can be configured in the `build.sbt` as below.

{% highlight ocaml %}
libraryDependencies += "org.reactivemongo" %% "reactivemongo-bson-monocle" % "{{site._1_0_latest_minor}}"
{% endhighlight %}

*See [Scaladoc](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-monocle_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/monocle/index.html)*

<strong id="specs2">[Specs2](./bson/extra.html#specs2):</strong>

The Specs2 library provides utilities to write tests using [specs2](https://etorreborre.github.io/specs2/) with BSON values.

It can be configured in the `build.sbt` as below.

{% highlight ocaml %}
libraryDependencies += "org.reactivemongo" %% "reactivemongo-bson-specs2" % "{{site._1_0_latest_minor}}"
{% endhighlight %}

*See [Scaladoc](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo-bson-geo_{{site._1_0_scala_major}}-{{site._1_0_latest_minor}}-javadoc.jar/!/reactivemongo/api/bson/geo/index.html)*

### Query and write operations

The [query builder](../api/reactivemongo/api/collections/GenericQueryBuilder.html) supports more options (see [`find`](https://docs.mongodb.com/v4.2/reference/command/find/#dbcmd.find)).

- **`singleBatch`**: `boolean`; Optional. Determines whether to close the cursor after the first batch. Defaults to `false`.
- **`maxScan`**: `boolean`; Optional. Maximum number of documents or index keys to scan when executing the query.
- [**`max`**](https://docs.mongodb.com/v4.2/reference/method/cursor.max): `document`; Optional. The exclusive upper bound for a specific index.
- [**`min`**](https://docs.mongodb.com/v4.2/reference/method/cursor.min/#cursor.min): `document`; Optional. The exclusive upper bound for a specific index.
- **`returnKey`**: `boolean`; Optional. If true, returns only the index keys in the resulting documents.
- **`showRecordId`**: `boolean`; Optional. Determines whether to return the record identifier for each document.
- **`collation`**: `document`; Optional; Specifies the collation to use for the operation (since 3.4).

The collection API provides new builders for write operations. This supports bulk operations (e.g. insert many documents at once).

**[`InsertBuilder`](../api/reactivemongo/api/collections/InsertOps$InsertBuilder.html)**

The new [`insert`](../api/reactivemongo/api/collections/GenericCollection.html#insert(ordered:Boolean,writeConcern:reactivemongo.api.commands.WriteConcern)(implicitevidence$2:GenericCollection.this.pack.Writer[T]):GenericCollection.this.InsertBuilder[T]) operation is providing an `InsertBuilder`, which supports,

- simple insert with [`.one`](../api/reactivemongo/api/collections/InsertOps$InsertBuilder.html#one(document:T)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.commands.WriteResult]),
- and bulk insert with [`.many`](../api/reactivemongo/api/collections/InsertOps$InsertBuilder.html#many(documents:Iterable[T])(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.commands.MultiBulkWriteResult]).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.commands.WriteResult

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

val document1 = BSONDocument(
  "firstName" -> "Stephane",
  "lastName" -> "Godbillon",
  "age" -> 29)

// Simple: .insert.one(t)
def simpleInsert(coll: BSONCollection): Future[WriteResult] =
  coll.insert.one(document1)

// Bulk: .insert.many(Seq(t1, t2, ..., tN))
def bulkInsert(coll: BSONCollection): Future[coll.MultiBulkWriteResult] =
  coll.insert(ordered = false).many(Seq(
    document1, BSONDocument(
      "firstName" -> "Foo",
      "lastName" -> "Bar",
      "age" -> 1)))
{% endhighlight %}

**[`UpdateBuilder`](../api/reactivemongo/api/collections/UpdateOps$UpdateBuilder.html)**

The new [`update`](../api/collections/GenericCollection.html#update(ordered:Boolean,writeConcern:reactivemongo.api.commands.WriteConcern):GenericCollection.this.UpdateBuilder) operation returns an `UpdateBuilder`, which can be used to perform simple or bulk update.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def update1(personColl: BSONCollection) = {
  val selector = BSONDocument("name" -> "Jack")

  val modifier = BSONDocument(
    "$set" -> BSONDocument(
      "lastName" -> "London",
      "firstName" -> "Jack"),
      "$unset" -> BSONDocument("name" -> 1))

  // Simple update: get a future update
  val futureUpdate1 = personColl.update.one(
    q = selector, u = modifier,
    upsert = false, multi = false)

  // Bulk update: multiple update
  val updateBuilder1 = personColl.update(ordered = true)
  val updates = Future.sequence(Seq(
    updateBuilder1.element(
      q = BSONDocument("firstName" -> "Jane", "lastName" -> "Doh"),
      u = BSONDocument("age" -> 18),
      upsert = true,
      multi = false),
    updateBuilder1.element(
      q = BSONDocument("firstName" -> "Bob"),
      u = BSONDocument("age" -> 19),
      upsert = false,
      multi = true)))

  val bulkUpdateRes1 = updates.flatMap { ops => updateBuilder1.many(ops) }
}
{% endhighlight %}

**[`DeleteBuilder`](../api/reactivemongo/api/collections/DeleteOps$DeleteBuilder.html)**

The [`.delete`](../api/reactivemongo/api/collections/GenericCollection.html#delete(ordered:Boolean,writeConcern:reactivemongo.api.commands.WriteConcern):GenericCollection.this.DeleteBuilder) function returns a `DeleteBuilder`, to perform simple or bulk delete.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def simpleDelete1(personColl: BSONCollection) =
  personColl.delete.one(BSONDocument("firstName" -> "Stephane"))

def bulkDelete1(personColl: BSONCollection) = {
  val deleteBuilder = personColl.delete(ordered = false)

  val deletes = Future.sequence(Seq(
    deleteBuilder.element(
      q = BSONDocument("firstName" -> "Stephane"),
      limit = Some(1), // former option firstMatch
      collation = None),
    deleteBuilder.element(
      q = BSONDocument("lastName" -> "Doh"),
      limit = None, // delete all the matching document
      collation = None)))

  deletes.flatMap { ops => deleteBuilder.many(ops) }
}
{% endhighlight %}

> The `.remove` operation is now deprecated.

**`arrayFilters`**

The [`arrayFilters`](https://docs.mongodb.com/manual/release-notes/3.6/#arrayfilters) criteria is supported for [`findAndModify` and `update`](./tutorial/write-documents.html#find-and-modify) operations.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.WriteConcern
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def findAndUpdateArrayFilters(personColl: BSONCollection) =
  personColl.findAndModify(
    selector = BSONDocument.empty,
    modifier = personColl.updateModifier(
      update = BSONDocument(f"$$set" -> BSONDocument(
        f"grades.$$[element]" -> 100)),
      fetchNewObject = true,
      upsert = false),
    sort = None,
    fields = None,
    bypassDocumentValidation = false,
    writeConcern = WriteConcern.Journaled,
    maxTime = None,
    collation = None,
    arrayFilters = Seq(
      BSONDocument("elem.grade" -> BSONDocument(f"$$gte" -> 85))))

def updateArrayFilters(personColl: BSONCollection) =
  personColl.update.one(
    q = BSONDocument("grades" -> BSONDocument(f"$$gte" -> 100)),
    u = BSONDocument(f"$$set" -> BSONDocument(
      f"grades.$$[element]" -> 100)),
    upsert = false,
    multi = true,
    collation = None,
    arrayFilters = Seq(
      BSONDocument("element" -> BSONDocument(f"$$gte" -> 100))))
{% endhighlight %}

The `.count(..)` collection operation now return a `Long` value (rather than `Int`).

**[`WriteResult`](../api/reactivemongo/api/commands/WriteResult.html)**

A new utility is provided to extract exception details from an erroneous result.

{% highlight scala %}
import reactivemongo.api.commands.WriteResult

def printExceptionIfFailed(res: WriteResult) = res match {
  case WriteResult.Exception(cause) =>
    cause.printStackTrace()

  case _ =>
    println("OK")
}
{% endhighlight %}

**More:** [Find documents](./tutorial/find-documents.html), [Write documents](./tutorial/write-documents.html)

### Play

[Play integration](./tutorial/play.html) has been upgraded, to support new versions and be compatible with the new [BSON library](#bson-library).

The `JSONCollection` and `JSONSerializationPack` (from package `reactivemongo.play.json.collection`) have been removed, and JSON compatibility can be applied using standard collection and JSON conversions.

{% highlight javascript %}
import reactivemongo.play.json.compat._,
  json2bson._,
  bson2json._
{% endhighlight %}

> The `play.modules.reactivemongo.JSONFileToSave` has also been removed.

### Aggregation

There are newly supported by the [Aggregation Framework](./advanced-topics/aggregation.html).

> An aggregation pipeline is now a list of operator(s), possibly empty.

**addFields:**

The [`$addFields`](https://docs.mongodb.com/manual/reference/operator/aggregation/addFields/) stage can now be used.

{% highlight javascript %}
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson.collection.BSONCollection

def sumHomeworkQuizz(students: BSONCollection) =
  students.aggregateWith1[BSONDocument]() { framework =>
    import framework.AddFields

    List(AddFields(document(
      "totalHomework" -> document(f"$$sum" -> f"$$homework"),
      "totalQuiz" -> document(f"$$sum" -> f"$$quiz"))), (
      AddFields(document(
        "totalScore" -> document(f"$$add" -> array(
        f"$$totalHomework", f"$$totalQuiz", f"$$extraCredit")))))
  }
{% endhighlight %}

**bucketAuto:**

The [`$bucketAuto`](https://docs.mongodb.com/manual/reference/operator/aggregation/bucketAuto/) stage introduced by MongoDB 3.4 can be used as bellow.

{% highlight scala %}
import scala.concurrent.ExecutionContext

import reactivemongo.api.Cursor

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def populationBuckets(zipcodes: BSONCollection)(implicit ec: ExecutionContext) =
  zipcodes.aggregateWith[BSONDocument]() { framework =>
    import framework.BucketAuto

    List(BucketAuto(BSONString(f"$$population"), 2, None)())
  }.collect[Set](Int.MaxValue, Cursor.FailOnError[Set[BSONDocument]]())
{% endhighlight %}

**count:**

If the goal is only to count the aggregated documents, the [`$count`](https://docs.mongodb.com/manual/reference/operator/aggregation/count/index.html) stage can be used.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.Cursor

import reactivemongo.api.bson.{ BSONDocument, BSONDocumentReader, BSONString }
import reactivemongo.api.bson.collection.BSONCollection

def countPopulatedStates1(col: BSONCollection): Future[Int] = {
  implicit val countReader = BSONDocumentReader[Int] { doc =>
    doc.getAsTry[Int]("popCount").get
  }

  col.aggregateWith[Int]() { framework =>
    import framework.{ Count, Group, Match, SumField }

    Group(BSONString("$state"))(
      "totalPop" -> SumField("population")) +: List(
        Match(BSONDocument("totalPop" -> BSONDocument("$gte" -> 10000000L))),
        Count("popCount"))
  }.head
}
{% endhighlight %}

**facet:**

The [`$facet`](https://docs.mongodb.com/manual/reference/operator/aggregation/facet/) stage is now supported, to create multi-faceted aggregations which characterize data across multiple dimensions, or facets.

{% highlight scala %}
import reactivemongo.api.bson.collection.BSONCollection

def useFacetAgg(coll: BSONCollection) = {
  import coll.AggregationFramework.{ Count, Facet, Out, UnwindField }

  Facet(Seq(
    "foo" -> List(UnwindField("bar"), Count("c")),
    "lorem" -> List(Out("ipsum"))))
  /* {
    $facet: {
      'foo': [
        { '$unwind': '$bar' },
        { '$count': 'c' }
      ],
      'lorem': [
        { '$out': 'ipsum' }
      ]
    }
  } */
}
{% endhighlight %}

**filter:**

The [`$filter`](https://docs.mongodb.com/master/reference/operator/aggregation/filter/#definition) stage is now supported.

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.Cursor

import reactivemongo.api.bson.{ BSONArray, BSONDocument, BSONString }
import reactivemongo.api.bson.collection.BSONCollection

def salesWithItemGreaterThanHundered(sales: BSONCollection) =
  sales.aggregateWith[BSONDocument]() { framework =>
    import framework._

    val sort = Sort(Ascending("_id"))

    Project(BSONDocument("items" -> Filter(
      input = BSONString(f"$$items"),
      as = "item",
      cond = BSONDocument(
        f"$$gte" -> BSONArray(f"$$$$item.price", 100))))) +: List(sort)

  }.collect[List](Int.MaxValue, Cursor.FailOnError[List[BSONDocument]]())
{% endhighlight %}

**replaceRoot:**

The [`$replaceRoot`](https://docs.mongodb.com/manual/reference/operator/aggregation/replaceRoot/#pipe._S_replaceRoot) stage is now supported.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

/* For a fruits collection:
{
   "_id" : 1,
   "fruit" : [ "apples", "oranges" ],
   "in_stock" : { "oranges" : 20, "apples" : 60 },
   "on_order" : { "oranges" : 35, "apples" : 75 }
}, ...
*/

def replaceRootTest(fruits: BSONCollection): Future[Option[BSONDocument]] = {
  fruits.aggregateWith[BSONDocument]() { framework =>
    import framework._

    List(ReplaceRootField("in_stock"))
  }.headOption
  // Results: { "oranges": 20, "apples": 60 }, ...
}
{% endhighlight %}

**search:**

In ReactiveMongo the [Atlas Search](https://docs.atlas.mongodb.com/reference/atlas-search/tutorial/) feature can be applied through the aggregation framework.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.Cursor
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def foo(col: BSONCollection)(
  implicit ec: ExecutionContext): Future[List[BSONDocument]] = {

  import col.AggregationFramework.AtlasSearch, AtlasSearch.Term

  col.aggregatorContext[BSONDocument](pipeline = List(AtlasSearch(Term(
    path = "description",
    query = "s*l*",
    modifier = Some(Term.Wildcard) // wildcard: true
  )))).prepared.cursor.collect[List]()
}
{% endhighlight %}

**slice:**

The [`$slice`](https://docs.mongodb.com/manual/reference/operator/aggregation/slice) operator is also supported as bellow.

{% highlight scala %}
import scala.concurrent.ExecutionContext

import reactivemongo.api.Cursor

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def sliceFavorites(coll: BSONCollection)(implicit ec: ExecutionContext) =
  coll.aggregateWith[BSONDocument]() { framework =>
    import framework.{ Project, Slice }

    List(Project(BSONDocument(
      "name" -> 1,
      "favorites" -> Slice(
        array = BSONString(f"$$favorites"),
        n = BSONInteger(3)))))
  }.collect[Seq](4)
{% endhighlight %}

**Miscellaneous:** Other stages are also supported.

- [`$and`](https://docs.mongodb.com/manual/reference/operator/aggregation/and)
- [`$allElementsTrue`](https://docs.mongodb.com/manual/reference/operator/aggregation/allElementsTrue)
- [`$acosh`](https://docs.mongodb.com/manual/reference/operator/aggregation/acosh)
- [`$acos`](https://docs.mongodb.com/manual/reference/operator/aggregation/acos)
- [`$abs`](https://docs.mongodb.com/manual/reference/operator/aggregation/abs)
- [`$planCacheStats`](https://docs.mongodb.com/manual/reference/operator/aggregation/planCacheStats)
- [`$collStats`](https://docs.mongodb.com/manual/reference/operator/aggregation/collStats)
- [`$bucket`](https://docs.mongodb.com/manual/reference/operator/aggregation/bucket)
- [`$merge`](https://docs.mongodb.com/manual/reference/operator/aggregation/merge)
- [`$listSessions`](https://docs.mongodb.com/manual/reference/operator/aggregation/listSessions)
- [`$listLocalSessions`](https://docs.mongodb.com/manual/reference/operator/aggregation/listLocalSessions)
- [`$currentOp`](https://docs.mongodb.com/manual/reference/operator/aggregation/currentOp)
- [`$unset`](https://docs.mongodb.com/manual/reference/operator/aggregation/unset)
- [`$sortByCount`](https://docs.mongodb.com/manual/reference/operator/aggregation/sortByCount)
- [`$set`](https://docs.mongodb.com/manual/reference/operator/aggregation/set)
- [`$replaceWith`](https://docs.mongodb.com/manual/reference/operator/aggregation/replaceWith)

<strong id="change-stream">Change stream:</strong>

Since MongoDB 3.6, it's possible to [watch the changes](https://docs.mongodb.com/manual/changeStreams/) applied on a collection.

Now ReactiveMongo can obtain a stream of changes, and aggregate it.

{% highlight scala %}
import reactivemongo.api.Cursor
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def filteredWatch(
  coll: BSONCollection,
  filter: BSONDocument): Cursor[BSONDocument] = {
  import coll.AggregationFramework.{ Match, PipelineOperator }

  coll.watch[BSONDocument](
    pipeline = List[PipelineOperator](Match(filter))).
    cursor[Cursor.WithOps]
}
{% endhighlight %}

**More:** [Aggregation Framework](./advanced-topics/aggregation.html)

### GridFS

The [GridFS API](./advanced-topics/gridfs.html) has been refactored, to be simpler and more safe.

The `DefaultFileToSave` has been moved to the factory [`fileToSave`](https://static.javadoc.io/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/gridfs/GridFS.html#fileToSave[Id<:GridFS.this.pack.Value](filename:Option[String],contentType:Option[String],uploadDate:Option[Long],metadata:GridFS.this.pack.Document,id:Id):GridFS.this.FileToSave[Id]).

Separate classes and traits `DefaultReadFile`, `ComputedMetadata`, `BasicMetadata` and `CustomMetadata` have been merged with the single class [`ReadFile`](https://static.javadoc.io/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/gridfs/ReadFile.html).

As the underlying `files` and `chunks` collections are no longer part of the public GridFS API, a new function [`update`](https://static.javadoc.io/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/gridfs/GridFS.html#update) is provided to update the file metadata (also note the `DB.gridfs` utility).

{% highlight scala %}
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson.{ BSONDocument, BSONObjectID }

import reactivemongo.api.DB
import reactivemongo.api.gridfs.GridFS

def updateFile(db: DB, fileId: BSONObjectID)(implicit ec: ExecutionContext) =
  db.gridfs.update(fileId, BSONDocument(f"$$set" ->
    BSONDocument("meta" -> "data")))
{% endhighlight %}

### Monitoring

A [new module](./advanced-topics/monitoring.html#kamon) is available to collect ReactiveMongo metrics with [Kamon](https://kamon.io/).

{% highlight ocaml %}
"org.reactivemongo" %% "reactivemongo-kamon" % "{{site._1_0_latest_minor}}"
{% endhighlight %}

Then the metrics can be configured in dashboards, according the used Kamon reporters.
For example if using [Kamon APM](https://kamon.io/docs/latest/reporters/apm/).

<img src="./images/kamon-apm-graph-view.png" alt="Graph about established connections" class="screenshot" />

**More:** [Monitoring](./advanced-topics/monitoring.html)

### Administration

The operations to manage a MongoDB instance can be executed using ReactiveMongo. This new release has new functions for DB administration.

**Ping:**

The `DB` has now a [`ping`](../api/reactivemongo/api/DB.html#ping(readPreference:reactivemongo.api.ReadPreference)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Boolean]) operation, to execute a [ping command](https://docs.mongodb.com/manual/reference/command/ping/).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.DB

def ping(admin: DB): Future[Boolean] = admin.ping()
{% endhighlight %}

### Breaking changes

The [Typesafe Migration Manager](https://github.com/typesafehub/migration-manager#migration-manager-for-scala) has been setup on the ReactiveMongo repository.
It will validate all the future contributions, and help to make the API more stable.

For the current {{site._1_0_latest_minor}} release, it has detected the following breaking changes.

[![Test coverage](https://img.shields.io/badge/coverage-60%25-yellowgreen.svg)](https://reactivemongo.github.io/ReactiveMongo/coverage/{{site._1_0_latest_minor}}/)

**Connection**

- `reactivemongo.api.ReadPreference.Taggable`

**Operations and commands**

- `reactivemongo.api.commands.DeleteCommand.DeleteElement`

**Core/internal**

- `reactivemongo.core` packages after Netty 4.1.25 upgrade.