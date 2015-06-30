---
layout: default
title: ReactiveMongo 0.11.0 - Running Commands
---

## Running Commands

A MongoDB Command is a special query that returns at most one document. It is run on a database, and may concern a given collection. In ReactiveMongo, you can run commands using `db.command(<command>)`.

The return type of `db.command()` depends on the kind of command you gave it as a parameter; for example, with `Count` it would return `Future[Int]`:

{% highlight scala %}
// BSON implementation of the count command
import reactivemongo.api.commands.bson.BSONCountCommand.{ Count, CountResult }

// BSON serialization-deserialization for the count arguments and result
import reactivemongo.api.commands.bson.BSONCountCommandImplicits._

// count the number of documents which tag equals "closed"
val query = BSONDocument("tag" -> "closed")
val command = Count("collectionName", Some(query))
val result: Future[CountResult] = bsonCollection.runCommand(command)

result.map { res =>
  val numberOfDocs: Int = res.value
  // do something with this number
}
{% endhighlight %}

> The `.count` operation is now directly available on collection.

Some widely used commands, like `Count` or `FindAndModify`, are available in ReactiveMongo. But how to run commands that are not explicitly supported?

### Run any command with `RawCommand`

It is possible to run any kind of commands, even if they are not specifically implemented in ReactiveMongo yet. Since a command in MongoDB is nothing more than a query on the special collection `$cmd` that returns a document, you can make your own command, which result type is `Future[BSONDocument]`. Let's take a look to the following example involving the Aggregation Framework (you can find this example in the [MongoDB documentation](http://docs.mongodb.org/manual/core/aggregation-pipeline/#aggregation-pipeline-behavior)):

{% highlight javascript %}
// MongoDB Console example of Aggregate command
db.orders.aggregate([
  { $match: { status: "A" } },
  { $group: { _id: "$cust_id", total: { $sum: "$amount" } } },
  { $sort: { total: -1 } }
])
{% endhighlight %}

Actually, the MongoDB console sends a document that is a little bit more complex to the server:

{% highlight javascript %}
// document sent to the database using the MongoDB console
var command =
  {
    "aggregate": "orders", // name of the collection on which we run this command
    "$pipeling": [
      { $match: { status: "A" } },
      { $group: { _id: "$cust_id", total: { $sum: "$amount" } } },
      { $sort: { total: -1 } }
    ]
  }

// run the command
db.runCommand(command)
{% endhighlight %}

We do exactly the same thing with `RawCommand`, by making a `BSONDocument` that contains the same fieds:

{% highlight scala %}
import reactivemongo.bson.{ BSONArray, BSONDocument }
import reactivemongo.api.BSONSerializationPack
import reactivemongo.api.commands.Command

val commandDoc =
  BSONDocument(
    "aggregate" -> "orders", // we aggregate on collection `orders`
    "$pipeline" -> BSONArray(
      BSONDocument("$match" -> BSONDocument("status" -> "A")),
      BSONDocument(
        "$group" -> BSONDocument(
          "_id" -> "$cust_id",
          "total" -> BSONDocument("$sum" -> "$amound"))),
      BSONDocument("$sort" -> BSONDocument("total" -> -1))
    )
  )

val runner = Command.run(BSONSerializationPack)

// we get a Future[BSONDocument]
val futureResult =
  runner.apply(db, runner.rawCommand(commandDoc)).one[BSONDocument]

futureResult.map { result => // result is a BSONDocument
  // ...
}
{% endhighlight %}
