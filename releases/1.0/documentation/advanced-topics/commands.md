---
layout: default
major_version: 1.0
title: Command API
---

## Command API

A MongoDB Command is a special query that returns documents. It's executed at either the database level (`db.runCommand` in the MongoDB shell), or at the collection level (`db.aCol.runCommand` in the shell).

In ReactiveMongo, the database command can be executed using [`db.runCommand(<command>)`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{_1_0_scala_major}}/{{_1_0_latest_minor}}/reactivemongo/api/DB.html#runCommand(command:DB.this.pack.Document,failoverStrategy:reactivemongo.api.FailoverStrategy):reactivemongo.api.commands.CursorFetcher[DB.this.pack.type,reactivemongo.api.Cursor]).

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.DB
import reactivemongo.api.commands.{ Command, CommandKind, CommandWithResult }

object Ping extends Command with CommandWithResult[Boolean] {
  val commandKind: CommandKind = new CommandKind("ping")
}

import reactivemongo.api.bson.{
  BSONDocument, BSONDocumentReader, BSONDocumentWriter
}

implicit val pingCommandWriter: BSONDocumentWriter[Ping.type] =
  BSONDocumentWriter[Ping.type] { _: Ping.type => BSONDocument("ping" -> 1) }

implicit val pingResultReader: BSONDocumentReader[Boolean] =
  BSONDocumentReader.option[Boolean] { _.booleanLike("ok") }

def runPing(db: DB)(
  implicit ec: ExecutionContext): Future[Boolean] = db.runCommand(Ping)
```

The collection command can be executed with [`collection.runCommand(<command>)`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{_1_0_scala_major}}/{{_1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#runCommand[C%3C:reactivemongo.api.commands.CollectionCommand](command:C)(implicitwriter:GenericCollectionWithCommands.this.pack.Writer[reactivemongo.api.commands.ResolvedCollectionCommand[C]]):reactivemongo.api.commands.CursorFetcher[GenericCollectionWithCommands.this.pack.type,reactivemongo.api.Cursor]).

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.collection.BSONCollection
import reactivemongo.api.commands.{
  CollectionCommand, 
  CommandKind,
  CommandWithResult,
  ResolvedCollectionCommand
}

class CountByName(val name: String)
  extends CollectionCommand with CommandWithResult[Long] {
  val commandKind: CommandKind = new CommandKind("count")
}

import reactivemongo.api.bson.{
  BSONDocument, BSONDocumentReader, BSONDocumentWriter
}

implicit val countByNameWriter =
  BSONDocumentWriter[ResolvedCollectionCommand[CountByName]] { count =>
    BSONDocument(
      "count" -> count.collection,
      "query" -> BSONDocument("name" -> count.command.name))
  }

implicit val countByNameReader = BSONDocumentReader.option[Long](_.long("n"))

def runCount(coll: BSONCollection, name: String)(
  implicit ec: ExecutionContext): Future[Long] =
  coll.runCommand(new CountByName(name))
```

### Run a raw command

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

We do exactly the same thing with raw command, using document that contains the same fields:

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.{ BSONArray, BSONDocument }

import reactivemongo.api.{ DB, FailoverStrategy, ReadPreference }
import reactivemongo.api.commands.Command

def commandResult(db: DB)(implicit ec: ExecutionContext): Future[BSONDocument] = {
  val commandDoc = BSONDocument(
    "aggregate" -> "orders", // we aggregate on collection `orders`
    "pipeline" -> BSONArray(
      BSONDocument(f"$$match" -> BSONDocument("status" -> "A")),
      BSONDocument(
        f"$$group" -> BSONDocument(
          "_id" -> f"$$cust_id",
          "total" -> BSONDocument(f"$$sum" -> f"$$amount"))),
      BSONDocument(f"$$sort" -> BSONDocument("total" -> -1))
    )
  ) // For example, otherwise rather use `.aggregatorContext` with a collection

  db.runCommand(commandDoc, FailoverStrategy.default).
    cursor[BSONDocument](ReadPreference.primaryPreferred).head
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
  CommandKind,
  CommandWithPack,
  CommandWithResult,
}

trait CustomCommand[P <: SerializationPack] {
  val pack: P

  case class Custom(
    name: String,
    query: pack.Document) extends Command
      with CommandWithPack[pack.type] with CommandWithResult[CustomResult] {
    val commandKind: CommandKind = new CommandKind(name)
  }

  case class CustomResult(count: Int, matching: List[String])
}
```

It specifies what is the command input (arguments), and what kind of result will be deserialized from the output, using the trait [`CommandWithResult[CustomResult]`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{_1_0_scala_major}}/{{_1_0_latest_minor}}/reactivemongo/api/commands/CommandWithResult.html). If the command returns a document and you want to directly get that, it can be specified with `CommandWithResult[pack.Document]`.

The next step is to implement the custom command.

```scala
package customcmd
package bson1

import scala.util.Try
import reactivemongo.api.bson.collection.BSONSerializationPack

object BSONCustomCommand extends CustomCommand[BSONSerializationPack.type] {
  val pack = BSONSerializationPack

  object Implicits {
    import reactivemongo.api.bson.{
      BSONDocument, BSONDocumentReader, BSONDocumentWriter, BSONNumberLike
    }

    implicit val writer: BSONDocumentWriter[Custom] =
      BSONDocumentWriter[Custom] { custom =>
        // { "custom": name, "query": { ... } }
        BSONDocument("custom" -> custom.name, "query" -> custom.query)
      }

    implicit object BSONReader extends BSONDocumentReader[CustomResult] {
      def readDocument(result: BSONDocument): Try[CustomResult] = for {
        count <- result.getAsTry[BSONNumberLike]("count").flatMap(_.toInt)
        matching <- result.getAsTry[List[String]]("matching")
      } yield CustomResult(count, matching)
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

import scala.util.Try
import reactivemongo.api.bson.collection.BSONSerializationPack

import reactivemongo.api.commands.{
  Command,
  CommandKind,
  CommandWithPack,
  CommandWithResult
}

object BSONCustomCommand {
  val pack = BSONSerializationPack

  case class Custom(
    name: String,
    query: pack.Document) extends Command
      with CommandWithPack[pack.type] with CommandWithResult[CustomResult] {
    val commandKind: CommandKind = new CommandKind(name)
  }

  case class CustomResult(count: Int, matching: List[String])

  object Implicits {
    import reactivemongo.api.bson.{
      BSONDocument, BSONDocumentReader, BSONDocumentWriter, BSONNumberLike
    }

    implicit val writer: BSONDocumentWriter[Custom] =
      BSONDocumentWriter[Custom] { custom =>
        // { "custom": name, "query": { ... } }
        BSONDocument("custom" -> custom.name, "query" -> custom.query)
      }

    implicit object BSONReader extends BSONDocumentReader[CustomResult] {
      def readDocument(result: BSONDocument): Try[CustomResult] = for {
        count <- result.getAsTry[BSONNumberLike]("count").flatMap(_.toInt)
        matching <- result.getAsTry[List[String]]("matching")
      } yield CustomResult(count, matching)
    }
  }
}
```

Once the command is implemented, it can be executed on the database.

```scala
package customcmd.bson2

import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.{ DB, FailoverStrategy }
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONSerializationPack

object MyRunner {
  import BSONCustomCommand._
  import BSONCustomCommand.Implicits._

  def custom(
    db: DB,
    name: String,
    query: BSONDocument)(implicit ec: ExecutionContext): Future[CustomResult] =
    db.runCommand(Custom(name, query), FailoverStrategy())
}
```

**Collection command:**

For a collection command `db.aCollection.runCommand({ "custom": name, "query": { ... } })`, the ReactiveMongo definition will be similar to those at the database level, but based on [`CollectionCommand`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{_1_0_scala_major}}/{{_1_0_latest_minor}}/reactivemongo/api/commands/CollectionCommand.html) (rather than `Command`).

```scala
import reactivemongo.api.SerializationPack
import reactivemongo.api.commands.{
  CollectionCommand,
  CommandKind,
  CommandWithPack,
  CommandWithResult
}

// { "custom": name, "query": { ... } }
trait CustomCommand[P <: SerializationPack] {
  val pack: P

  case class Custom(
    name: String,
    query: pack.Document) extends CollectionCommand
      with CommandWithPack[pack.type] with CommandWithResult[CustomResult] {
    val commandKind: CommandKind = new CommandKind(name)
  }

  // { "count": int, "matching": [ "value1", "value2", ..., "valueN" ] }
  case class CustomResult(count: Int, matching: List[String])
}
```

Once the input and output of a collection command are specified, it must be implemented.

```scala
import scala.util.Try
import reactivemongo.api.bson.collection.BSONSerializationPack

object BSONCustomCommand extends CustomCommand[BSONSerializationPack.type] {
  val pack = BSONSerializationPack

  object Implicits {
    import reactivemongo.api.commands.ResolvedCollectionCommand
    import reactivemongo.api.bson.{
      BSONDocument, BSONDocumentReader, BSONDocumentWriter, BSONNumberLike
    }

    // type `Custom` inherited from the specification `CustomCommand` trait
    implicit val BSONWriter =
      BSONDocumentWriter[ResolvedCollectionCommand[Custom]] { custom =>
        val cmd: Custom = custom.command
        val colName: String = custom.collection        

        // { "custom": name, "query": { ... } }
        BSONDocument("custom" -> cmd.name, "query" -> cmd.query)
      }

    implicit object BSONReader extends BSONDocumentReader[CustomResult] {
      // type `CustomResult` inherited from the `CustomCommand` trait
      def readDocument(result: BSONDocument): Try[CustomResult] = for {
        count <- result.getAsTry[BSONNumberLike]("count").flatMap(_.toInt)
        matching <- result.getAsTry[List[String]]("matching")
      } yield CustomResult(count, matching)
    }
  }
}
```

The writer of a collection collection must serialize a `ResolvedCollectionCommand[Custom]`, rather than directly `Custom`. The [`ResolvedCollectionCommand`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{_1_0_scala_major}}/{{_1_0_latest_minor}}/reactivemongo/api/commands/ResolvedCollectionCommand.html) provides the information about the collection against which the command is executed (e.g. the collection name `colName` in the previous example).

Then the collection command can be executed using `runCommand`.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection
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
