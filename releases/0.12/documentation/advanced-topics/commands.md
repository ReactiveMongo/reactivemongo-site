---
layout: default
major_version: 0.12
title: Command API
---

## Command API

A MongoDB Command is a special query that returns documents. It's executed at either the database level (`db.runCommand` in the MongoDB shell), or at the collection level (`db.aCol.runCommand` in the shell).

In ReactiveMongo, the database command can be executed using [`db.runCommand(<command>)`](../../api/index.html#reactivemongo.api.GenericDB@runCommand[R,C%3C:reactivemongo.api.commands.Commandwithreactivemongo.api.commands.CommandWithResult[R]]%28command:Cwithreactivemongo.api.commands.CommandWithResult[R]%29%28implicitwriter:GenericDB.this.pack.Writer[C],implicitreader:GenericDB.this.pack.Reader[R],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[R]).

The collection command can be executed with [`collection.runCommand(<command>)`](../../api/index.html#reactivemongo.api.collections.GenericCollection@runCommand[R,C%3C:reactivemongo.api.commands.CollectionCommandwithreactivemongo.api.commands.CommandWithResult[R]]%28command:Cwithreactivemongo.api.commands.CommandWithResult[R]%29%28implicitwriter:GenericCollectionWithCommands.this.pack.Writer[reactivemongo.api.commands.ResolvedCollectionCommand[C]],implicitreader:GenericCollectionWithCommands.this.pack.Reader[R],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[R]).

The return type of `.runCommand` operations depends on the kind of command you gave it as a parameter; For example, with `Count` it would return `Future[Int]`:

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

// BSON implementation of the count command
import reactivemongo.api.commands.bson.BSONCountCommand.{ Count, CountResult }

// BSON serialization-deserialization for the count arguments and result
import reactivemongo.api.commands.bson.BSONCountCommandImplicits._

def run1(collection: BSONCollection) = {
  // count the number of documents which tag equals "closed"
  val query = BSONDocument("tag" -> "closed")
  val command = Count(query)
  val result: Future[CountResult] = collection.runCommand(command)

  result.map { res =>
    val numberOfDocs: Int = res.value
    // do something with this number
  }
}
```

> The `.count` operation is now directly available on collection.

Some widely used commands, like [`Count`](../../api/index.html#reactivemongo.api.commands.CountCommand) or [`FindAndModify`](../../api/index.html#reactivemongo.api.commands.FindAndModifyCommand), are available in ReactiveMongo. But how to run commands that are not yet provided as operations?

### Run any command with `RawCommand`

It is possible to run any kind of command, even if they are not yet specifically implemented in ReactiveMongo. Since a command in MongoDB is nothing more than a query on the special collection `$cmd`, you can make your own command.

Let's take a look to the following example involving the Aggregation Framework (you can find this example in the [MongoDB documentation](http://docs.mongodb.org/manual/core/aggregation-pipeline/#aggregation-pipeline-behavior)):

```javascript
// MongoDB Console example of Aggregate command
db.orders.aggregate([
  { $match: { status: "A" } },
  { $group: { _id: "$cust_id", total: { $sum: "$amount" } } },
  { $sort: { total: -1 } }
])
```

Actually, the MongoDB console sends a document that is a little bit more complex to the server:

```javascript
// document sent to the database using the MongoDB console
var command =
  {
    "aggregate": "orders", // name of the collection on which we run this command
    "pipeline": [
      { $match: { status: "A" } },
      { $group: { _id: "$cust_id", total: { $sum: "$amount" } } },
      { $sort: { total: -1 } }
    ]
  }

// run the command
db.runCommand(command)
```

We do exactly the same thing with `RawCommand`, by making a `BSONDocument` that contains the same fields:

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.{ BSONArray, BSONDocument }
import reactivemongo.api.BSONSerializationPack
import reactivemongo.api.commands.Command

def commandResult(db: reactivemongo.api.DefaultDB)(implicit ec: ExecutionContext): Future[BSONDocument] = {
  val commandDoc = BSONDocument(
    "aggregate" -> "orders", // we aggregate on collection `orders`
    "pipeline" -> BSONArray(
      BSONDocument("$match" -> BSONDocument("status" -> "A")),
      BSONDocument(
        "$group" -> BSONDocument(
          "_id" -> "$cust_id",
          "total" -> BSONDocument("$sum" -> "$amount"))),
      BSONDocument("$sort" -> BSONDocument("total" -> -1))
    )
  )

  val runner = Command.run(BSONSerializationPack)

  runner.apply(db, runner.rawCommand(commandDoc)).one[BSONDocument]
}
```

> The MongoDB aggregation is already provided by ReactiveMongo with a [specific support](./aggregation.html).

### Defining custom commands

It's possible to define a not yet implemented or custom command using the command API.

**Database command:**

Considering a database command executed in the Shell using `db.runCommand({ "custom": name, "query": { ... } })`, with a result like `{ "count": int, "matching": [ "value1", "value2", ..., "valueN" ] }`, it can be defined as following.

```scala
package customcmd

import reactivemongo.api.SerializationPack
import reactivemongo.api.commands.{
  Command,
  CommandWithPack,
  CommandWithResult,
  ImplicitCommandHelpers
}

trait CustomCommand[P <: SerializationPack] extends ImplicitCommandHelpers[P] {
  case class Custom(
    name: String,
    query: pack.Document) extends Command
      with CommandWithPack[pack.type] with CommandWithResult[CustomResult]

  case class CustomResult(count: Int, matching: List[String])
}
```

It specifies what is the command input (arguments), and what kind of result will be deserialized from the output, using the trait [`CommandWithResult[CustomResult]`](../../api/index.html#reactivemongo.api.commands.CommandWithResult). If the command returns a document and you want to directly get that, it can be specified with `CommandWithResult[pack.Document]`.

The next step is to implement the custom command.

```scala
package customcmd
package bson1

import reactivemongo.api.BSONSerializationPack

object BSONCustomCommand extends CustomCommand[BSONSerializationPack.type] {
  val pack = BSONSerializationPack

  object Implicits {
    import reactivemongo.bson.{
      BSONDocument, BSONDocumentReader, BSONDocumentWriter, BSONNumberLike
    }

    implicit object BSONWriter extends BSONDocumentWriter[Custom] {
      def write(custom: Custom): BSONDocument = {
        // { "custom": name, "query": { ... } }
        BSONDocument("custom" -> custom.name, "query" -> custom.query)
      }
    }

    implicit object BSONReader extends BSONDocumentReader[CustomResult] {
      def read(result: BSONDocument): CustomResult = (for {
        count <- result.getAs[BSONNumberLike]("count").map(_.toInt)
        matching <- result.getAs[List[String]]("matching")
      } yield CustomResult(count, matching)).get
    }
  }
}
```

In the previous example, the custom command is implemented using the BSON serialization, providing the [writers and readers](../bson/typeclasses.html) for the command input and result.

A command can be implemented with various serialization pack (e.g. it can also be implemented using the JSON serialization provided by the [Play JSON support](../json/overview.html#run-a-raw-command)).

It's also possible to gather the command definition and implementation, if only one kind of serialization is needed.

```scala
package customcmd
package bson2

import reactivemongo.api.BSONSerializationPack

import reactivemongo.api.commands.{
  Command,
  CommandWithPack,
  CommandWithResult,
  ImplicitCommandHelpers
}

object BSONCustomCommand
    extends ImplicitCommandHelpers[BSONSerializationPack.type] {

  val pack = BSONSerializationPack

  case class Custom(
    name: String,
    query: pack.Document) extends Command
      with CommandWithPack[pack.type] with CommandWithResult[CustomResult]

  case class CustomResult(count: Int, matching: List[String])

  object Implicits {
    import reactivemongo.bson.{
      BSONDocument, BSONDocumentReader, BSONDocumentWriter, BSONNumberLike
    }

    implicit object BSONWriter extends BSONDocumentWriter[Custom] {
      def write(custom: Custom): BSONDocument = {
        // { "custom": name, "query": { ... } }
        BSONDocument("custom" -> custom.name, "query" -> custom.query)
      }
    }

    implicit object BSONReader extends BSONDocumentReader[CustomResult] {
      def read(result: BSONDocument): CustomResult = (for {
        count <- result.getAs[BSONNumberLike]("count").map(_.toInt)
        matching <- result.getAs[List[String]]("matching")
      } yield CustomResult(count, matching)).get
    }
  }
}
```

Once the command is implemented, it can be executed on the database.

```scala
package customcmd.bson2

import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.BSONDocument
import reactivemongo.api.{ BSONSerializationPack, GenericDB }

object MyRunner {
  import BSONCustomCommand._
  import BSONCustomCommand.Implicits._

  def custom(
    db: GenericDB[BSONSerializationPack.type],
    name: String,
    query: BSONDocument)(implicit ec: ExecutionContext): Future[CustomResult] =
    db.runCommand(Custom(name, query))
}
```

**Collection command:**

For a collection command `db.aCollection.runCommand({ "custom": name, "query": { ... } })`, the ReactiveMongo definition will be similar to those at the database level, but based on [`CollectionCommand`](../../api/index.html#reactivemongo.api.commands.CollectionCommand) (rather than `Command`).

```scala
import reactivemongo.api.SerializationPack
import reactivemongo.api.commands.{
  CollectionCommand,
  CommandWithPack,
  CommandWithResult,
  ImplicitCommandHelpers
}

// { "custom": name, "query": { ... } }
trait CustomCommand[P <: SerializationPack] extends ImplicitCommandHelpers[P] {
  case class Custom(
    name: String,
    query: pack.Document) extends CollectionCommand
      with CommandWithPack[pack.type] with CommandWithResult[CustomResult]

  // { "count": int, "matching": [ "value1", "value2", ..., "valueN" ] }
  case class CustomResult(count: Int, matching: List[String])
}
```

Once the input and output of a collection command are specified, it must be implemented.

```scala
import reactivemongo.api.BSONSerializationPack

object BSONCustomCommand extends CustomCommand[BSONSerializationPack.type] {
  val pack = BSONSerializationPack

  object Implicits {
    import reactivemongo.api.commands.ResolvedCollectionCommand
    import reactivemongo.bson.{
      BSONDocument, BSONDocumentReader, BSONDocumentWriter, BSONNumberLike
    }

    implicit object BSONWriter
        extends BSONDocumentWriter[ResolvedCollectionCommand[Custom]] {
        // type `Custom` inherited from the specification `CustomCommand` trait

      def write(custom: ResolvedCollectionCommand[Custom]): BSONDocument = {
        val cmd: Custom = custom.command
        val colName: String = custom.collection        

        // { "custom": name, "query": { ... } }
        BSONDocument("custom" -> cmd.name, "query" -> cmd.query)
      }
    }

    implicit object BSONReader extends BSONDocumentReader[CustomResult] {
      // type `CustomResult` inherited from the `CustomCommand` trait
      def read(result: BSONDocument): CustomResult = (for {
        count <- result.getAs[BSONNumberLike]("count").map(_.toInt)
        matching <- result.getAs[List[String]]("matching")
      } yield CustomResult(count, matching)).get
    }
  }
}
```

The writer of a collection collection must serialize a `ResolvedCollectionCommand[Custom]`, rather than directly `Custom`. The [`ResolvedCollectionCommand`](../../api/index.html#reactivemongo.api.commands.ResolvedCollectionCommand) provides the information about the collection against which the command is executed (e.g. the collection name `colName` in the previous example).

Then the collection command can be executed using `runCommand`.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection
import BSONCustomCommand._

def custom(
  col: BSONCollection,
  name: String,
  query: BSONDocument)(implicit ec: ExecutionContext): Future[CustomResult] = {

  import BSONCustomCommand.Implicits._

  col.runCommand(Custom(name, query))
}
```

**See also:**

- [The Aggregation Framework](./aggregation.html)
