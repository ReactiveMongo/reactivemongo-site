---
layout: default
major_version: 1.0
title: Release details
date: \today
fontsize: 11pt
#monofont: Menlo
#mainfont: Source Sans Pro
monofont: Inconsolata
mainfont: Helvetica

header-includes:
- \input{releases/1.0/documentation/beamer-includes}
---

## Release details

This is the release details for ReactiveMongo {{site._1_0_latest_minor}}.

{% if site._1_0_latest_minor contains "-rc." %}
<strong style="color:red">This is a Release Candidate</strong>
{% endif %}

The documentation is available [online](./index.html), and its code samples are compiled to make sure it's up-to-date.

### What's new?

- [Compatibility](#compatibility)
- [Migration](#migration)
- [Connection](#connection) <!-- pandoc_hidden -->
  - Support [x.509 certificate](https://docs.mongodb.com/manual/tutorial/configure-x509-client-authentication/) to authenticate.
  - Support [DNS seedlist](https://docs.mongodb.com/manual/reference/connection-string/#dns-seedlist-connection-format) in the connection URI.
  - New `heartbeatFrequencyMS` setting.
  - Add `credentials` in the [`MongoConnectionOptions`](https://javadoc.io/doc/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/MongoConnectionOptions.html)
  - Support [Netty native](#netty-native) <!-- end_pandoc_hidden -->
- [BSON library](#bson-library) <!-- pandoc_hidden -->
  - [Documents and values](#documents-and-values)
  - [Reader and writer typeclasses](#reader-and-writer-typeclasses)
  - [Macros](#macros)
  - [Extra libraries](#extra-libraries)
    - [GeoJSON](#geojson)
    - [Monocle](#monocle)
    - [Specs2](#specs2) <!-- end_pandoc_hidden -->
- [Query and write operations](#query-and-write-operations)
- [Play](#play) <!-- pandoc_hidden -->
  - [JSON compatibility](#json-compatibility) <!-- end_pandoc_hidden -->
- [Aggregation](#aggregation)
  - [`CursorOptions`](https://javadoc.io/doc/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/CursorOptions.html) <!-- pandoc_hidden -->parameter when using `.aggregatorContext`<!-- end_pandoc_hidden -->
  - [New stages](#addfields)
  - [Change stream](#change-stream)
- [GridFS](#gridfs)
- [Monitoring](#monitoring) <!-- pandoc_hidden -->
- [Administration](#administration)
- [Breaking changes](#breaking-changes) <!-- end_pandoc_hidden -->

### Compatibility

This release is compatible with the following runtime.

- [MongoDB](https://www.mongodb.org/) from 3.0 up to 4.2.
- [Scala](https://www.scala-lang.org) from 2.11 to 2.13.
- [Akka](http://akka.io/) from 2.3.13 up to 2.6.5 (see [Setup](./tutorial/setup.html))
- [Play Framework](https://playframework.com) from 2.3.13 to 2.8.1

> MongoDB versions older than 3.0 are not longer (end of life 2018-2).

**Recommended configuration:**

The driver core and the modules are tested in a [container based environment](https://docs.travis-ci.com/user/ci-environment/#Virtualization-environments), with the specifications as bellow.

- 2 [cores](https://cloud.google.com/compute/) (64 bits)
- 4 GB of system memory, with a maximum of 2 GB for the JVM

This can be considered as a recommended environment.

### Migration

A Scalafix module is available to migrate from ReactiveMongo 0.12+ to 1.0 (not yet available for Scala 2.13).

To apply the migration rules, first [setup Scalafix](https://scalacenter.github.io/scalafix/docs/users/installation.html) in the SBT build, then configure the ReactiveMongo rules as bellow.

```ocaml
scalafixDependencies in ThisBuild ++= Seq(
  "org.reactivemongo" %% "reactivemongo-scalafix" % "{{site._1_0_latest_minor}}")
```

Once the rules are configured, they can be applied from SBT.

```sh
scalafix ReactiveMongoUpgrade
scalafix ReactiveMongoLinter --check
```

<!-- pandoc_sep: Migration (upgrade dependencies) -->
Then upgrade the appropriate `libraryDependencies` in the SBT build, and re-recompile it.

```sh
sbt clean compile
```

Finally, apply manually the remaining fixes due to the breaking changes.

*[Suggest an improvement](https://github.com/ReactiveMongo/ReactiveMongo-Scalafix/issues/new/choose) to these rules*

### Connection

The `MongoDriver` type is replaced by `AsyncDriver`, with asynchronous methods.

- `MongoDriver.connection` replaced by [`AsyncDriver.connect`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/AsyncDriver.html#connect[T](parsedURI:reactivemongo.api.MongoConnection.URI[T]):scala.concurrent.Future[reactivemongo.api.MongoConnection])
- `close` is asynchronous.

The utility function `MongoConnection.parseURI` is replaced by asynchronous function [`.fromString`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/MongoConnection$.html#fromString(uri:String)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.MongoConnection.ParsedURI]).

<!-- pandoc_sep: Deprecated options -->
Also, the following options are deprecated:

- `authSource` replaced by [`authenticationDatabase`](https://javadoc.io/doc/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/MongoConnectionOptions.html#authenticationDatabase:Option[String]) (as the MongoShell option)
- `authMode` replaced by [`authenticationMechanism`](https://javadoc.io/doc/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/MongoConnectionOptions.html#authenticationMechanism:reactivemongo.api.AuthenticationMode) (as the MongoShell option)
- `sslEnabled` replaced by `ssl` (as the MongoShell option)
- `rm.monitorRefreshMS` replaced by `heartbeatFrequencyMS`
The option `rm.monitorRefreshMS` is renamed [`heartbeatFrequencyMS`](https://github.com/mongodb/specifications/blob/master/source/server-discovery-and-monitoring/server-discovery-and-monitoring.rst#heartbeatfrequencyms) for the interval (in milliseconds) used to refresh the node set (default: 10s).

> [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) is now supported for the SSL connection.

<!-- pandoc_sep: x509 authentication -->
The [x.509 certificate authentication](https://docs.mongodb.com/manual/tutorial/configure-x509-client-authentication/) is now supported, and can be configured by setting `x509` as `authenticationMechanism`, and with the following new options.

- **`keyStore`**: An URI to a key store (e.g. `file:///path/to/keystore.p12`)
- **`keyStorePassword`**: Provides the password to load it (if required)
- **`keyStoreType`**: Indicates the [type of the store](https://docs.oracle.com/javase/7/docs/technotes/guides/security/StandardNames.html#KeyStore)

```scala
import reactivemongo.api._

def connection(driver: AsyncDriver) = driver.connect(
  "mongodb://server:27017/db?ssl=true"
  + "&authenticationMechanism=x509"
  + "&keyStore=file:///path/to/keystore.p12"
  + "&keyStoreType=PKCS12")
```

<!-- pandoc_sep: DNS seedlist -->
The [DNS seedlist](https://docs.mongodb.com/manual/reference/connection-string/#dns-seedlist-connection-format) is now supported, using `mongodb+srv://` scheme in the connection URI.
It's also possible to specify the credential directly in the URI.

```scala
import reactivemongo.api._

def seedListCon(driver: AsyncDriver) = driver.connect(
  "mongodb+srv://usr:pass@mymongo.mydomain.tld/mydb")
```

*[See documentation](./tutorial/connect-database.html)*

#### Netty native

The internal [Netty](http://netty.io/) dependency has been updated to the version [4.1](http://netty.io/wiki/new-and-noteworthy-in-4.1.html).

It comes with various improvements (memory consumption, ...), and also to use Netty native support (kqueue for MacOS X and epoll for Linux, on `x86_64` arch).

> *Note:* The Netty dependency is [shaded](https://maven.apache.org/plugins/maven-shade-plugin/) so it won't conflict with any Netty version in your environment.

*[See documentation](./tutorial/connect-database.html#netty-native)*

### BSON library

The Biːsən is the new default BSON library, that fixes some issues<!-- pandoc_hidden --> ([OOM](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/memleaks002.html))<!-- end_pandoc_hidden -->, and brings multiple API and performance improvements (simpler & better).

**Highlights:**

- Simpler and more efficient API
- New [GeoJSON](./bson/extra.html#geojson) library
- New [Monocle](./bson/extra.html#monocle) (optics) library
- New [Specs2](./bson/extra.html#specs) library

#### Documents and values

The API for [`BSONDocument`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONDocument.html) has been slightly updated, with the function `getAs` renamed as `getAsOpt` (to be consistent with `getAsTry`).

New `getOrElse` function is also added.

```scala
import reactivemongo.api.bson._

def withFallback(doc: BSONDocument): String = {
  doc.getOrElse[String]("NAME", "defaultValue")
  // Equivalent to:
  //   doc.getAsOpt[String]("NAME").getOrElse("defaultValue")
}
```

<!-- pandoc_sep -->
New field utilities are provided for the most common types:

```scala
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
```

The Biːsən library supports [BSON Decimal128](https://github.com/mongodb/specifications/blob/master/source/bson-decimal128/decimal128.rst#bson-decimal128-type-handling-in-drivers) (MongoDB 3.4+).

*[See documentation](./bson/overview.html)*

<!-- pandoc_sep -->
> *Note:* The `BSONDocument` and `BSONArray` factories have been optimized and support more use cases.

![Coefficient between new/old throughput (op/s; =1: no change, 1+: better thrpt)](./images/bison-bench-doc.png){:width="75%"}

<!-- pandoc_hidden -->
<small>Source: <a rel="me external" href="https://github.com/ReactiveMongo/ReactiveMongo-BSON/blob/master/benchmarks/src/main/scala/BSONDocumentBenchmark.scala">BSONDocumentBenchmark</a>, <a rel="me external" href="https://github.com/ReactiveMongo/ReactiveMongo-BSON/blob/master/benchmarks/src/main/scala/BSONDocumentHandlerBenchmark.scala">BSONDocumentHandlerBenchmark</a></small>
<!-- end_pandoc_hidden -->

<!-- pandoc_sep -->
![Coefficient between new/old throughput (op/s; =1: no change, 1+: better thrpt)](./images/bison-bench-array.png){:width="75%"}

<!-- pandoc_hidden -->
<small>Source: <a rel="me external" href="https://github.com/ReactiveMongo/ReactiveMongo-BSON/blob/master/benchmarks/src/main/scala/BSONArrayBenchmark.scala">BSONArrayBenchmark</a></small>
<!-- end_pandoc_hidden -->

#### Reader and writer typeclasses

The names of these typeclasses are unchanged ([`BSONReader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONReader.html) and [`BSONWriter`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONWriter.html)), except the package that is `reactivemongo.api.bson` (instead of `reactivemongo.bson`).

In the previous BSON library, `BSONReader` and `BSONWriter` are defined with two type parameters:

```ocaml
BSONReader[B <: BSONValue, T]

BSONWriter[T, B <: BSONValue]
```

- `B` being the type of BSON value to be read/written,
- and `T` being the Scala type to be handled.

<!-- pandoc_sep: Simpler BSON API -->
The new API has been simplified, with only the `T` type parameter kept.

```scala
import reactivemongo.api.bson._

// Read a String from BSON,
// whatever is the specific BSON value type
def stringReader: BSONReader[String] = ???
```

<!-- pandoc_sep: BSON compatible types -->
Not only it makes the API simpler, but it also allows to read different BSON types as a target Scala type<!-- pandoc_hidden -->(before it only supported for numeric/boolean, using the dedicated typeclasses)<!-- end_pandoc_hidden -->.

For example, the Scala numeric types (`BigDecimal`, `Double`, `Float`, `Int`, `Long`) can be directly read from any consistent BSON numeric type (e.g. `1.0` as integer `1`)<!-- pandoc_hidden -->, without having to use `BSONNumberLike`<!-- end_pandoc_hidden -->.

```scala
import reactivemongo.api.bson._

BSONDouble(1.0D).asTry[Int]
// => Success(1)
```

<!-- pandoc_sep: Safer BSON API -->
Also, handler functions [`readTry`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONHandler.html#readTry(bson:reactivemongo.api.bson.BSONValue):scala.util.Try[T]) and [`writeTry`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONHandler.html#writeTry(t:T):scala.util.Try[reactivemongo.api.bson.BSONValue]) returns `Try`, for a safer representation of possible failures.

The new API is also safer, replacing `BSONReader.read` and `BSONWriter.write` respectively with `BSONReader.readTry` and `BSONWriter.writeTry`, so that serialization errors can be handle at typelevel.

In a similar way, [`BSONObjectID.parse`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONObjectID$.html#parse(bytes:Array[Byte]):scala.util.Try[reactivemongo.api.bson.BSONObjectID]) now returns `Try`, and `BSONValue.as` is replaced by [`asOpt`](https://www.javadoc.io/static/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONValue.html#asOpt[T](implicitreader:reactivemongo.api.bson.BSONReader[T]):Option[T]) and [`asTry`](https://www.javadoc.io/static/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/BSONValue.html#asTry[T](implicitreader:reactivemongo.api.bson.BSONReader[T]):scala.util.Try[T]).

<!-- pandoc_sep: Document typeclasses -->
Like the current BSON library, some specific typeclasses are available (with same names) to only work with BSON documents: `BSONDocumentReader` and `BSONDocumentWriter`.

Some new handlers are provided by default, like those for [Java Time](https://docs.oracle.com/javase/8/docs/api/java/time/package-summary.html) types.

> *Note:* The handler for `java.util.Date` is replaced the handler for `java.time.Instant`.

<!-- pandoc_sep -->
The error handling has also been improved, with more details.

> *Note:* `DocumentKeyNotFoundException` in the previous API is replaced with `BSONValueNotFoundException` in the new one.

![Coefficient between new/old throughput (op/s; =1: no change, 1+: better thrpt)](./images/bison-bench-reader.png){:width="75%"}

<!-- pandoc_hidden -->
<small>Source: <a rel="me external" href="https://github.com/ReactiveMongo/ReactiveMongo-BSON/blob/master/benchmarks/src/main/scala/">BSON reader benchmarks</a></small>
<!-- end_pandoc_hidden -->

##### `Map` handler

A handler is now available to write and read Scala `Map` as BSON, provided the value types are supported.

```scala
import scala.util.Try
import reactivemongo.api.bson._

def bsonMap = {
  val input: Map[String, Int] = Map("a" -> 1, "b" -> 2)

  // Ok as key and value (String, Int) are provided BSON handlers
  val doc: Try[BSONDocument] = BSON.writeDocument(input)

  val output = doc.flatMap { BSON.readDocument[Map[String, Int]](_) }
}
```

You can to serialize a `Map` whose key type is not `String`, using the new typeclasses [`KeyWriter`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/KeyWriter.html) and [`KeyReader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/KeyReader.html).

<!-- pandoc_sep: Map handler example -->
```scala
import scala.util.Try
import reactivemongo.api.bson._

final class FooKey(val value: String)

object FooKey {
  val bar = new FooKey("bar")
  val lorem = new FooKey("lorem")

  implicit val kw: KeyWriter[FooKey] = KeyWriter[FooKey](_.value)
  implicit val kr: KeyReader[FooKey] = KeyReader[FooKey] { new FooKey(_) }
}

def bsonMapCustomKey = {
  val input: Map[FooKey, Int] = Map(FooKey.bar -> 1, FooKey.lorem -> 2)

  // Ok as key and value (String, Int) are provided handlers
  val doc: Try[BSONDocument] = BSON.writeDocument(input)

  val output = doc.flatMap { BSON.readDocument[Map[FooKey, Int]](_) }
}
```

##### `Iterable` factories

New factories to handle BSON array are provided.

Considering the `Element` type as below:

```scala
import reactivemongo.api.bson.Macros

case class Element(str: String, v: Int)

val elementHandler = Macros.handler[Element]
```

<!-- pandoc_sep: Sequence factories -->
The `{ BSONReader, BSONWriter }.sequence` factories can be used to represent sequence of `Element` in BSON.

```scala
import reactivemongo.api.bson.BSONWriter

val seqWriter: BSONWriter[Seq[Element]] =
  BSONWriter.sequence[Element](elementHandler writeTry _)

// ---

seqWriter.writeTry(Seq(Element("foo", 1), Element("bar", 2)))
// Success: [ { 'str': 'foo', 'v': 1 }, { 'str': 'bar', 'v': 2 } ]
```

<!-- pandoc_sep: Iterable factories -->
The `{ BSONReader, BSONWriter }.iterable` factories can also be used (for example to work with `Set`).

```scala
import reactivemongo.api.bson.{ BSONArray, BSONDocument, BSONReader }

val setReader: BSONReader[Set[Element]] =
  BSONReader.iterable[Element, Set](elementHandler readTry _)

// ---

val itFixture2 = BSONArray(
  BSONDocument("str" -> "foo", "v" -> 1),
  BSONDocument("str" -> "bar", "v" -> 2))

setReader.readTry(itFixture2)
// Success: Set(Element("foo", 1), Element("bar", 2))
```

##### Tuple factories

New factories to create handler for tuple types (up to 5-arity) are provided.

If an array is the wanted BSON representation:

```scala
import reactivemongo.api.bson.{ BSONArray, BSONReader, BSONWriter }

val readerArrAsStrInt = BSONReader.tuple2[String, Int]
val writerStrIntToArr = BSONWriter.tuple2[String, Int]

val arr = BSONArray("Foo", 20)

readerArrAsStrInt.readTry(arr) // => Success(("Foo", 20))

writerStrIntToArr.writeTry("Foo" -> 20)
// => Success: arr = ['Foo', 20]
```

<!-- pandoc_sep: Tuple factories (as document) -->
If a document representation is wanted: 

```scala
import reactivemongo.api.bson.{
  BSONDocument, BSONDocumentReader, BSONDocumentWriter
}

val writerStrIntToDoc =
  BSONDocumentWriter.tuple2[String, Int]("name", "age")

writerStrIntToDoc.writeTry("Foo" -> 20)
// => Success: {'name': 'Foo', 'age': 20}

val readerDocAsStrInt =
  BSONDocumentReader.tuple2[String, Int]("name", "age")

readerDocAsStrInt.readTry(BSONDocument("name" -> "Foo", "age" -> 20))
// => Success(("Foo", 20))
```

##### Partial function

There are new factories based on partial functions: `collect` and `collectFrom`.

*BSON reader:*

```scala
import reactivemongo.api.bson.{ BSONReader, BSONInteger }

val intToStrCodeReader = BSONReader.collect[String] {
  case BSONInteger(0) => "zero"
  case BSONInteger(1) => "one"
}

intToStrCodeReader.readTry(BSONInteger(0)) // Success("zero")

intToStrCodeReader.readTry(BSONInteger(2))
// => Failure(ValueDoesNotMatchException(..))
```

<!-- pandoc_sep -->
*BSON writer:*

```scala
import reactivemongo.api.bson.{ BSONWriter, BSONInteger }

val strCodeToIntWriter = BSONWriter.collect[String] {
  case "zero" => BSONInteger(0)
  case "one" => BSONInteger(1)
}

strCodeToIntWriter.writeTry("zero") // Success(BSONInteger(0))

strCodeToIntWriter.writeTry("3")
// => Failure(IllegalArgumentException(..))
```

*BSON document writer:*

```scala
import reactivemongo.api.bson.{ BSONDocument, BSONDocumentWriter }

case class Bar(value: String)

val writer2 = BSONDocumentWriter.collectFrom[Bar] {
  case Bar(value) if value.nonEmpty =>
    scala.util.Success(BSONDocument("value" -> value))
}
```

#### Macros

The new library also provides similar macros, to materialized document readers and writers for case classes and sealed traits.

```scala
case class Person(name: String, age: Int)

import reactivemongo.api.bson._

val personHandler: BSONDocumentHandler[Person] =
  Macros.handler[Person]

// Or only ...
val personReader: BSONDocumentReader[Person] =
  Macros.reader[Person]

val personWriter: BSONDocumentWriter[Person] =
  Macros.writer[Person]
```

<!-- pandoc_sep: Macro configuration -->
There is a new [configuration mechanism](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroConfiguration.html), to specify a [field naming](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/FieldNaming.html) and customize the name of each BSON field corresponding to Scala.

```scala
import reactivemongo.api.bson._

val withPascalCase: BSONDocumentHandler[Person] = {
  implicit def cfg: MacroConfiguration = MacroConfiguration(
    fieldNaming = FieldNaming.PascalCase)

  Macros.handler[Person]
}

withPascalCase.writeTry(Person(name = "Jane", age = 32))
// Success { "Name": "Jane", "Age": 32) }
```

<!-- pandoc_sep: Macro trait discriminator -->
With sealed family/trait, it's also possible to configure the [discriminator field](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroConfiguration.html#discriminator:String) and [discriminator values](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/TypeNaming.html) according Scala types.

```scala
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
```

<!-- pandoc_sep: Macro options -->
The nested type `Macros.Options` is replaced by similar type [`MacrosOptions`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroOptions.html).

> *Note:* The `Macros.Options.SaveSimpleName` of the previous BSON library has been removed in favour of a [configuration factory](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroConfiguration$.html#simpleTypeName[Opts%3C:reactivemongo.api.bson.MacroOptions](implicitevidence$2:reactivemongo.api.bson.MacroOptions.ValueOf[Opts]):reactivemongo.api.bson.MacroConfiguration.Aux[Opts]) using similar `TypeNaming`.

The compile-time option [`AutomaticMaterialization`](https://javadoc.io/static/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroOptions$$AutomaticMaterialization.html) has been added, when using the macros with sealed family, to indicate when you want to automatically materialize instances for the subtypes (if missing from the implicit scope).

<!-- pandoc_sep: AutomaticMaterialization option -->
```scala
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
    UnionType[Red.type \/ Green \/ Blue.type]
    with AutomaticMaterialization

  val predefinedColor = Macros.handlerOpts[Color, PredefinedColor]
}
```

<!-- pandoc_sep: ReadDefaultValues option -->
Using the new option [`ReadDefaultValues`](https://javadoc.io/static/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroOptions$$ReadDefaultValues.html), the default values can be used by readers when there is no BSON value.

```scala
import reactivemongo.api.bson.{
  BSONDocument, BSONDocumentReader, Macros, MacroOptions
}

case class FooWithDefault1(id: Int, title: String = "default")

{
  val reader: BSONDocumentReader[FooWithDefault1] =
    Macros.using[MacroOptions.ReadDefaultValues].
      reader[FooWithDefault1]

  reader.readTry(BSONDocument("id" -> 1)) // missing BSON title
  // => Success: FooWithDefault1(id = 1, title = "default")
}
```

> *Note:* A new option [`DisableWarnings`](https://javadoc.io/static/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/MacroOptions$$DisableWarnings.html) allows to specifically exclude macro warnings.

<!-- pandoc_sep: Value classes -->
New macros for [Value classes](https://docs.scala-lang.org/overviews/core/value-classes.html) are new available.

```scala
package object relexamples {
  import reactivemongo.api.bson.{
    BSONHandler, BSONReader, BSONWriter, Macros
  }

  final class FooVal(val value: String) extends AnyVal

  val vh: BSONHandler[FooVal] = Macros.valueHandler[FooVal]
  val vr: BSONReader[FooVal] = Macros.valueReader[FooVal]
  val vw: BSONWriter[FooVal] = Macros.valueWriter[FooVal]
}
```

##### Annotations

The way `Option` is handled by the macros has been improved, also with a new annotation <span id="none-as-null">[`@NoneAsNull`](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/Macros$$Annotations$$NoneAsNull.html)</span>, which write `None` values as `BSONNull` (instead of omitting field/value).

```scala
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.Macros, Macros.Annotations.NoneAsNull

case class WithNull(
  name: String,
  @NoneAsNull score: Option[Int])

Macros.writer[WithNull].writeTry(WithNull("foo", None))

// Serialized with null: {'name': 'foo', 'score': null}
// Rather than: {'name': 'foo'}
```

<!-- pandoc_sep: @Flatten -->
Also, a <span id="a-flatten">new annotation [`@Flatten`](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/Macros$$Annotations$$Flatten.html)</span> has been added, to indicate to the macros that the representation of a property must be flatten rather than a nested document.

```scala
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
```

<!-- pandoc_sep: @DefaultValue -->
The new <span id="a-defaultvalue">[`@DefaultValue`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$DefaultValue.html)</span> can be used with `ReadDefaultValues` to specify a default value only used when reading from BSON.

```scala
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
```

<!-- pandoc_sep: @Reader -->
The new <span id="a-reader">[`@Reader`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$Reader.html)</span> allows to indicate a BSON reader to be used for a property, not using the implicit scope.

```scala
import reactivemongo.api.bson.{ BSONDocument, BSONReader }
import reactivemongo.api.bson.Macros, Macros.Annotations.Reader

val scoreReader: BSONReader[Double] = BSONReader.collect[Double] {
  case reactivemongo.api.bson.BSONString(v) => v.toDouble
  case reactivemongo.api.bson.BSONDouble(b) => b
}

case class CustomFoo1(
  title: String,
  @Reader(scoreReader) score: Double)

Macros.reader[CustomFoo1].readTry(BSONDocument(
  "title" -> "Bar",
  "score" -> "1.23" // accepted by annotated scoreReader
))
// Success: CustomFoo1(title = "Bar", score = 1.23D)
```

<!-- pandoc_sep: @Writer -->
Also the new <span id="a-writer">[`@Writer`](https://static.javadoc.io/org.reactivemongo/reactivemongo-bson-api_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/bson/Macros$$Annotations$$Writer.html)</span> specifies the BSON writer to be used for a property, instead of the implicit scope.

```scala
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
```

#### Extra libraries

Some [extra libraries](./bson/extra.html) are provided along the new BSON one, to improve the integration.

<!-- pandoc_hidden -->
<strong id="geojson">[GeoJSON](./bson/extra.html#geojson):</strong>
<!-- end_pandoc_hidden -->

A new [GeoJSON](https://docs.mongodb.com/manual/reference/geojson/) library is provided, with the geometry types and the corresponding handlers to read from and write them to appropriate BSON representation.

It can be configured in the `build.sbt` as below.

```ocaml
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo-bson-geo" % "{{site._1_0_latest_minor}}")
```

*See [Scaladoc](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/index.html)*

<!-- pandoc_sep: Monocle -->
<!-- pandoc_hidden -->
<strong id="monocle">[Monocle](./bson/extra.html#monocle):</strong>
<!-- end_pandoc_hidden -->

The library that provides [Monocle](http://julien-truffaut.github.io/Monocle/) based optics, for BSON values.

It can be configured in the `build.sbt` as below.

```ocaml
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo-bson-monocle" % "{{site._1_0_latest_minor}}")
```

*See [Scaladoc](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-monocle_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/monocle/index.html)*

<!-- pandoc_sep: Specs2 -->
<!-- pandoc_hidden -->
<strong id="specs2">[Specs2](./bson/extra.html#specs2):</strong>
<!-- end_pandoc_hidden -->

The Specs2 library provides utilities to write tests using [specs2](https://etorreborre.github.io/specs2/) with BSON values.

It can be configured in the `build.sbt` as below.

```ocaml
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo-bson-specs2" % "{{site._1_0_latest_minor}}")
```

*See [Scaladoc](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo-bson-geo_{{site._1_0_scala_major}}-{{site._1_0_latest_minor}}-javadoc.jar/!/reactivemongo/api/bson/geo/index.html)*

### Query and write operations

The [query builder](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/QueryBuilderFactory$QueryBuilder.html) supports more options (see [`find`](https://docs.mongodb.com/v4.2/reference/command/find/#dbcmd.find)).

- **`singleBatch`**: `boolean`; Optional. Determines whether to close the cursor after the first batch. Defaults to `false`.
- **`maxScan`**: `boolean`; Optional. Maximum number of documents or index keys to scan when executing the query.
- [**`max`**](https://docs.mongodb.com/v4.2/reference/method/cursor.max): `document`; Optional. The exclusive upper bound for a specific index.
- [**`min`**](https://docs.mongodb.com/v4.2/reference/method/cursor.min/#cursor.min): `document`; Optional. The exclusive upper bound for a specific index.
- **`returnKey`**: `boolean`; Optional. If true, returns only the index keys in the resulting documents.
- **`showRecordId`**: `boolean`; Optional. Determines whether to return the record identifier for each document.
- **`collation`**: `document`; Optional; Specifies the collation to use for the operation (since 3.4).

<!-- pandoc_sep: Collection API -->
The collection API provides new builders for write operations. This supports bulk operations (e.g. insert many documents at once).

#### [`InsertBuilder`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/InsertOps.html#InsertBuilderextendsAnyRef)

The new [`insert`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#insert:GenericCollection.this.InsertBuilder) operation is providing an `InsertBuilder`.

It supports simple insert with [`.one`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/InsertOps$InsertBuilder.html#one[T](document:T)(implicitec:scala.concurrent.ExecutionContext,implicitwriter:InsertOps.this.pack.Writer[T]):scala.concurrent.Future[reactivemongo.api.commands.WriteResult]).

```scala
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
```

<!-- pandoc_sep: Bulk insert-->
Bulk insert is supported by [`.many`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/InsertOps$InsertBuilder.html#many[T](documents:Iterable[T])(implicitec:scala.concurrent.ExecutionContext,implicitwriter:InsertOps.this.pack.Writer[T]):scala.concurrent.Future[InsertOps.this.MultiBulkWriteResult]) function.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

// Bulk: .insert.many(Seq(t1, t2, ..., tN))
def bulkInsert(
  coll: BSONCollection): Future[coll.MultiBulkWriteResult] =
  coll.insert(ordered = false).many(Seq(
    document1, BSONDocument(
      "firstName" -> "Foo",
      "lastName" -> "Bar",
      "age" -> 1)))
```

#### [`UpdateBuilder`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/UpdateOps$UpdateBuilder.html)

The new [`update`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#update:GenericCollection.this.UpdateBuilder) operation returns an `UpdateBuilder`. It supports simple update.

```scala
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def simpleUpdate(personColl: BSONCollection) = {
  val selector = BSONDocument("name" -> "Jack")

  val modifier = BSONDocument(
    "$set" -> BSONDocument(
      "lastName" -> "London",
      "firstName" -> "Jack"),
      "$unset" -> BSONDocument("name" -> 1))

  personColl.update.one(
    q = selector, u = modifier,
    upsert = false, multi = false)
}
```

<!-- pandoc_sep: Bulk update -->

It also allows to perform bulk update using the [`.many`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/UpdateOps$UpdateBuilder.html#many(firstUpdate:UpdateOps.this.UpdateElement,updates:Iterable[UpdateOps.this.UpdateElement])(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[UpdateOps.this.MultiBulkWriteResult]) function.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.document
import reactivemongo.api.bson.collection.BSONCollection

def bulkUpdate(personColl: BSONCollection) = {
  val updateBuilder1 = personColl.update(ordered = true)
  val updates = Future.sequence(Seq(
    updateBuilder1.element(
      q = document("firstName" -> "Jane", "lastName" -> "Doh"),
      u = document("age" -> 18),
      upsert = true, multi = false),
    updateBuilder1.element(
      q = document("firstName" -> "Bob"),
      u = document("age" -> 19),
      upsert = false, multi = true)))

  updates.flatMap { updateBuilder1.many(_) }
}
```

#### [`DeleteBuilder`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/DeleteOps$DeleteBuilder.html)

The [`.delete`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#delete:GenericCollection.this.DeleteBuilder) function returns a `DeleteBuilder`.
It supports simple deletion.

> The `.remove` operation is now deprecated.

```scala
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def simpleDelete1(personColl: BSONCollection) =
  personColl.delete.one(BSONDocument("firstName" -> "Stephane"))
```

<!-- pandoc_sep: Bulk delete -->

Bulk deletion is supported with the [`.many`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/DeleteOps$DeleteBuilder.html#many(deletes:Iterable[DeleteOps.this.DeleteElement])(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[DeleteOps.this.MultiBulkWriteResult]) function.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

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
```

#### [`arrayFilters`](https://docs.mongodb.com/manual/release-notes/3.6/#arrayfilters)

The `arrayFilters` criteria is supported by the [`findAndModify`](./tutorial/write-documents.html#find-and-modify) operation.

```scala
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.WriteConcern
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def findAndUpdateArrayFilters(personColl: BSONCollection) =
  personColl.findAndModify(
    selector = BSONDocument.empty,
    modifier = personColl.updateModifier(
      update = BSONDocument(f"$$set" -> BSONDocument(
        f"grades.$$[element]" -> 100))),
    sort = None, fields = None,
    bypassDocumentValidation = false,
    writeConcern = WriteConcern.Journaled,
    maxTime = None, collation = None,
    arrayFilters = Seq(BSONDocument(
      "elem.grade" -> BSONDocument(f"$$gte" -> 85))))
```

<!-- pandoc_sep: arrayFilters (update) -->

`arrayFilters` is also supported on update.

```scala
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def updateArrayFilters(personColl: BSONCollection) =
  personColl.update.one(
    q = BSONDocument(
      "grades" -> BSONDocument(f"$$gte" -> 100)),
    u = BSONDocument(f"$$set" -> BSONDocument(
      f"grades.$$[element]" -> 100)),
    upsert = false,
    multi = true,
    collation = None,
    arrayFilters = Seq(BSONDocument(
      "element" -> BSONDocument(f"$$gte" -> 100))))
```

<!-- pandoc_sep: Count -->

The [`.count`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#count(selector:Option[GenericCollection.this.pack.Document],limit:Option[Int],skip:Int,hint:Option[GenericCollection.this.Hint],readConcern:reactivemongo.api.ReadConcern,readPreference:reactivemongo.api.ReadPreference)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Long]) operation now returns a `Long` value (rather than `Int`).

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.collection.BSONCollection

def countPerson(personColl: BSONCollection): Future[Long] =
  personColl.count(None/* all */)
```

#### [`WriteResult`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/commands/WriteResult.html)

A new utility is provided to extract exception details from an erroneous result.

```scala
import reactivemongo.api.commands.WriteResult

def printExceptionIfFailed(res: WriteResult) = res match {
  case WriteResult.Exception(cause) =>
    cause.printStackTrace()

  case _ =>
    println("OK")
}
```

> *Reminder:* There is no need to check failure inside a `Future[WriteResult]` as soon as the `Future` is successful.

**More:** [Find documents](./tutorial/find-documents.html), [Write documents](./tutorial/write-documents.html)

### Play

[Play integration](./tutorial/play.html) has been upgraded, to support versions up to 2.8 and be compatible with the new [BSON library](#bson-library).

The `JSONCollection` and `JSONSerializationPack` (from package `reactivemongo.play.json.collection`) have been removed, and JSON compatibility can be applied using standard collection and JSON conversions.

> The `play.modules.reactivemongo.JSONFileToSave` has also been removed.

#### JSON compatibility

The JSON/BSON compatibility has been refactored. The main import is:

```scala
import reactivemongo.play.json.compat._
```

<!-- pandoc_sep: JSON example -->
Considering the following `User` class:

```scala
package object jsonexamples1 {
  import reactivemongo.api.bson._

  case class User(
    _id: BSONObjectID, // Rather use UUID or String
    username: String,
    role: String,
    created: BSONTimestamp, // Rather use Instant
    lastModified: BSONDateTime,
    sym: Option[BSONSymbol]) // Rather use String

  object User {
    implicit val bsonWriter: BSONDocumentWriter[User] =
      Macros.writer[User]

    implicit val bsonReader: BSONDocumentReader[User] =
      Macros.reader[User]
  }
}
```

<!-- pandoc_sep: JSON convertions (1) -->
Then specific imports are available to enable conversions, according the use cases.

```scala
import reactivemongo.play.json.compat._

// Conversions from BSON to JSON extended syntax
import bson2json._

// Override conversions with lax syntax
import lax._

// Conversions from JSON to BSON
import json2bson._
```

##### Convert BSON to JSON extended syntax

*Scala:*

```scala
import _root_.play.api.libs.json._

import _root_.reactivemongo.api.bson._

// Global compatibility import:
import reactivemongo.play.json.compat._

// Import BSON to JSON extended syntax (default)
import bson2json._ // Required import

import jsonexamples1.User

val userJs = Json.toJson(User(
  BSONObjectID.generate(), "lorem", "ipsum",
  created = BSONTimestamp(987654321L),
  lastModified = BSONDateTime(123456789L),
  sym = Some(BSONSymbol("foo"))))
```

<!-- pandoc_sep: Convert BSON to JSON extended syntax (output) -->
*JSON output:* (`userJs`)

```javascript
{
  "_id": {"$oid":"..."},
  "username": "lorem",
  "role": "ipsum",
  "created": {
    "$timestamp": {"t":0,"i":987654321}
  },
  "lastModified": {
    "$date": {"$numberLong":"123456789"}
  },
  "sym": {
    "$symbol":"foo"
  }
}
```

##### Convert BSON to JSON lax syntax

*Scala:*

```scala
import _root_.play.api.libs.json._
import _root_.reactivemongo.api.bson._

// Global compatibility import:
import reactivemongo.play.json.compat._

// Import BSON to JSON extended syntax (default)
import bson2json._ // Required import

// Import lax overrides
import lax._

import jsonexamples1.User

// Overrides BSONWriters for OID/Timestamp/DateTime
// so that the BSON representation matches the JSON lax one
implicit val bsonWriter: BSONDocumentWriter[User] =
  Macros.writer[User]

// Resolved from bsonWriter
val laxJsonWriter: OWrites[User] = implicitly[OWrites[User]]
```
<!-- pandoc_sep: Convert BSON to JSON lax syntax (result) -->
```scala
import _root_.reactivemongo.api.bson._
import jsonexamples1.User

val laxUserJs = laxJsonWriter.writes(User(
  BSONObjectID.generate(), "lorem", "ipsum",
  created = BSONTimestamp(987654321L),
  lastModified = BSONDateTime(123456789L),
  sym = Some(BSONSymbol("foo"))))
```

*JSON output:* (`userLaxJs`)

```javascript
{
  "_id": "...",
  "username": "lorem",
  "role": "ipsum",
  "created": 987654321,
  "lastModified": 123456789,
  "sym": "foo"
}
```

##### Convert JSON to BSON

Considering the `Street` class:

```scala
package object jsonexamples2 {
 case class Street(
   number: Option[Int],
   name: String)
}
```

<!-- pandoc_sep: Convert JSON to BSON (2) -->
The BSON representation can be derived from the JSON.

```scala
import _root_.play.api.libs.json._
import _root_.reactivemongo.api.bson._

// Global compatibility import:
import reactivemongo.play.json.compat._

// Import JSON to BSON conversions
import json2bson._ // Required import

import jsonexamples2.Street

implicit val jsonFormat: OFormat[Street] =
  Json.format[Street]

// Resolved from jsonFormat
val bsonStreetWriter =
  implicitly[BSONDocumentWriter[Street]]

bsonStreetWriter.writeTry(
  Street(Some(1), "rue de la lune"))
// Success: {'number':1, 'name':'rue de la lune'}
```

##### Value converters

Using the provided value conversions, a JSON object can be passed wherever a BSON document is expected.

```scala
import reactivemongo.api.bson.BSONDocument

def expectDoc(document: BSONDocument) =
  println(s"doc = ${BSONDocument pretty document}")

// ---

import _root_.play.api.libs.json._
import _root_.reactivemongo.api.bson._

// Global compatibility import:
import reactivemongo.play.json.compat._

// Import JSON to BSON conversions
import json2bson._ // Required import

expectDoc(document = Json.obj("age" -> Json.obj(f"$$gt" -> 1)))
  // doc = { 'age': { '$gt': 1 } }
```

*[See documentation](./json/overview.html)*

### Aggregation

The [Aggregation Framework](./advanced-topics/aggregation.html) supports more stages.

> An aggregation pipeline is now a list of stage operator(s), possibly empty.

#### addFields

The [`$addFields`](https://docs.mongodb.com/manual/reference/operator/aggregation/addFields/) stage can now be used.

```scala
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def sumHomeworkQuizz(students: BSONCollection) =
  students.aggregateWith[BSONDocument]() { framework =>
    import framework.AddFields

    List(AddFields(document(
      "totalHomework" -> document(f"$$sum" -> f"$$homework"),
      "totalQuiz" -> document(f"$$sum" -> f"$$quiz"))), 
      AddFields(document(
        "totalScore" -> document(f"$$add" -> array(
        f"$$totalHomework", f"$$totalQuiz", f"$$extraCredit")))))
  }
```

#### bucketAuto

The [`$bucketAuto`](https://docs.mongodb.com/manual/reference/operator/aggregation/bucketAuto/) stage introduced by MongoDB 3.4 can be used as bellow.

```scala
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def populationBuckets(zipcodes: BSONCollection)(
  implicit ec: ExecutionContext) =
  zipcodes.aggregateWith[BSONDocument]() { framework =>
    import framework.BucketAuto

    List(BucketAuto(
      BSONString(f"$$population"), 2, None)())
  }.collect[Set]()
```

#### count

The [`$count`](https://docs.mongodb.com/manual/reference/operator/aggregation/count/index.html) stage counts the aggregated documents.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def countPopulatedStates1(col: BSONCollection): Future[Int] = {
  implicit val countReader = BSONDocumentReader.from[Int] { doc =>
    doc.getAsTry[Int]("popCount")
  }

  col.aggregateWith[Int]() { framework =>
    import framework.{ Count, Group, Match, SumField }

    Group(BSONString(f"$$state"))(
      "totalPop" -> SumField("population")) +: List(
        Match(BSONDocument(
          "totalPop" -> BSONDocument(f"$$gte" -> 10000000L))),
        Count("popCount"))
  }.head
}
```

#### facet

The [`$facet`](https://docs.mongodb.com/manual/reference/operator/aggregation/facet/) stage create multi-faceted aggregations, which characterize data across multiple dimensions (or facets).

```scala
import reactivemongo.api.bson.collection.BSONCollection

def useFacetAgg(coll: BSONCollection) = {
  import coll.AggregationFramework.{
    Count, Facet, Out, UnwindField
  }

  Facet(Seq(
    "foo" -> List(UnwindField("bar"), Count("c")),
    "lorem" -> List(Out("ipsum"))))
  /* {
    $facet: {
      'foo': [
        { '$unwind': '$bar' },
        { '$count': 'c' }
      ],
      'lorem': [ { '$out': 'ipsum' } ]
    }
  } */
}
```

#### filter

The [`$filter`](https://docs.mongodb.com/master/reference/operator/aggregation/filter/#definition) stage is now supported.

```scala
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.{ BSONArray, BSONDocument, BSONString }
import reactivemongo.api.bson.collection.BSONCollection

def salesWithItemGreaterThanHundered(sales: BSONCollection) =
  sales.aggregateWith[BSONDocument]() { framework =>
    import framework._

    val sort = Sort(Ascending("_id"))

    Project(BSONDocument("items" -> Filter(
      input = BSONString(f"$$items"),
      as = "item",
      cond = BSONDocument(f"$$gte" -> BSONArray(
        f"$$$$item.price", 100))))) +: List(sort)

  }.collect[List]()
```

#### replaceRoot

The [`$replaceRoot`](https://docs.mongodb.com/manual/reference/operator/aggregation/replaceRoot/#pipe._S_replaceRoot) stage is now supported.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

/* For a fruits collection: {
   "_id" : 1,
   "fruit" : [ "apples", "oranges" ],
   "in_stock" : { "oranges" : 20, "apples" : 60 },
   "on_order" : { "oranges" : 35, "apples" : 75 }
}, ... */

def replaceRootTest(
  fruits: BSONCollection): Future[Option[BSONDocument]] =
  fruits.aggregateWith[BSONDocument]() { framework =>
    import framework._

    List(ReplaceRootField("in_stock"))
  }.headOption // Result: { "oranges": 20, "apples": 60 }
```

#### search

In ReactiveMongo the [Atlas Search](https://docs.atlas.mongodb.com/reference/atlas-search/tutorial/) feature can be applied through the aggregation framework.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def foo(col: BSONCollection)(
  implicit ec: ExecutionContext): Future[List[BSONDocument]] = {

  import col.AggregationFramework.AtlasSearch, AtlasSearch.Term

  col.aggregatorContext[BSONDocument](
    pipeline = List(AtlasSearch(Term(
      path = "description",
      query = "s*l*",
      modifier = Some(Term.Wildcard) // wildcard: true
    )))).prepared.cursor.collect[List]()
}
```

#### slice

The [`$slice`](https://docs.mongodb.com/manual/reference/operator/aggregation/slice) operator is also supported as bellow.

```scala
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def sliceFavorites(coll: BSONCollection)(
  implicit ec: ExecutionContext) =
  coll.aggregateWith[BSONDocument]() { framework =>
    import framework.{ Project, Slice }

    List(Project(BSONDocument(
      "name" -> 1,
      "favorites" -> Slice(
        array = BSONString(f"$$favorites"),
        n = BSONInteger(3)))))
  }.collect[Seq](4)
```

#### Miscellaneous

Other stages are also supported.

- [`$and`](https://docs.mongodb.com/manual/reference/operator/aggregation/and)
- [`$allElementsTrue`](https://docs.mongodb.com/manual/reference/operator/aggregation/allElementsTrue)
- [`$acosh`](https://docs.mongodb.com/manual/reference/operator/aggregation/acosh) and [`$acos`](https://docs.mongodb.com/manual/reference/operator/aggregation/acos)
- [`$abs`](https://docs.mongodb.com/manual/reference/operator/aggregation/abs)
- [`$planCacheStats`](https://docs.mongodb.com/manual/reference/operator/aggregation/planCacheStats) and [`$collStats`](https://docs.mongodb.com/manual/reference/operator/aggregation/collStats)
- [`$bucket`](https://docs.mongodb.com/manual/reference/operator/aggregation/bucket)
- [`$merge`](https://docs.mongodb.com/manual/reference/operator/aggregation/merge)
- [`$listSessions`](https://docs.mongodb.com/manual/reference/operator/aggregation/listSessions) and [`$listLocalSessions`](https://docs.mongodb.com/manual/reference/operator/aggregation/listLocalSessions)
- [`$currentOp`](https://docs.mongodb.com/manual/reference/operator/aggregation/currentOp)
- [`$unset`](https://docs.mongodb.com/manual/reference/operator/aggregation/unset)
- [`$sortByCount`](https://docs.mongodb.com/manual/reference/operator/aggregation/sortByCount)
- [`$set`](https://docs.mongodb.com/manual/reference/operator/aggregation/set)
- [`$replaceWith`](https://docs.mongodb.com/manual/reference/operator/aggregation/replaceWith)

##### Change stream

Since MongoDB 3.6, it's possible to [watch the changes](https://docs.mongodb.com/manual/changeStreams/) applied on a collection.

Now ReactiveMongo can obtain a stream of changes, and aggregate it.

```scala
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
```

**More:** [Aggregation Framework](./advanced-topics/aggregation.html)

### GridFS

The [GridFS API](./advanced-topics/gridfs.html) has been refactored, to be simpler and more safe.

<!-- pandoc_hidden -->
The `DefaultFileToSave` has been moved to the factory [`fileToSave`](https://static.javadoc.io/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/gridfs/GridFS.html#fileToSave[Id<:GridFS.this.pack.Value](filename:Option[String],contentType:Option[String],uploadDate:Option[Long],metadata:GridFS.this.pack.Document,id:Id):GridFS.this.FileToSave[Id]).

Separate classes and traits `DefaultReadFile`, `ComputedMetadata`, `BasicMetadata` and `CustomMetadata` have been merged with the single class [`ReadFile`](https://static.javadoc.io/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/gridfs/ReadFile.html).
<!-- end_pandoc_hidden -->

As the underlying `files` and `chunks` collections are no longer part of the public API, a new function [`update`](https://static.javadoc.io/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/gridfs/GridFS.html#update) is provided to update the file metadata.
Also note the `DB.gridfs` utility.

```scala
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.{ BSONDocument, BSONObjectID }

import reactivemongo.api.DB

def updateFile(db: DB, fileId: BSONObjectID) =
  db.gridfs.update(fileId, BSONDocument(f"$$set" ->
    BSONDocument("meta" -> "data")))
```

### Monitoring

A [new module](./advanced-topics/monitoring.html#kamon) is available to collect ReactiveMongo metrics with [Kamon](https://kamon.io/).

```ocaml
"org.reactivemongo" %% "reactivemongo-kamon" % "{{site._1_0_latest_minor}}"
```

Then dashboards can be configured, for example if using [Kamon APM](https://kamon.io/docs/latest/reporters/apm/).

![Graph about established connections](./images/kamon-apm-graph-view.png){:width="75%"}

**More:** [Monitoring](./advanced-topics/monitoring.html)

<!-- pandoc_hidden -->
### Administration

The operations to manage a MongoDB instance can be executed using ReactiveMongo. This new release has new functions for DB administration.

**Ping:**

The `DB` has now a [`ping`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/DB.html#ping(readPreference:reactivemongo.api.ReadPreference)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[Boolean]) operation, to execute a [ping command](https://docs.mongodb.com/manual/reference/command/ping/).

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.DB

def ping(admin: DB): Future[Boolean] = admin.ping()
```

### Breaking changes

The [Typesafe Migration Manager](https://github.com/typesafehub/migration-manager#migration-manager-for-scala) has been setup on the ReactiveMongo repository.
It will validate all the future contributions, and help to make the API more stable.

For the current {{site._1_0_latest_minor}} release, it has detected the following breaking changes.

**Connection**

- `reactivemongo.api.ReadPreference.Taggable`

**Operations and commands**

- `reactivemongo.api.commands.DeleteCommand.DeleteElement`

**Core/internal**

- `reactivemongo.core` packages after Netty 4.1.25 upgrade.
<!-- end_pandoc_hidden -->