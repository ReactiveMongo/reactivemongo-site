---
layout: default
major_version: 0.1x
title: Aggregation Framework
---

## Aggregation Framework

The [MongoDB Aggregation Framework](http://docs.mongodb.org/manual/reference/operator/aggregation/) is available through ReactiveMongo.

- **[`$addFields`](#addFields)**: [Adds new fields](https://docs.mongodb.com/manual/reference/operator/aggregation/addFields/) to documents.
- **[`$bucketAuto`](#bucketAuto)**: [Categorizes incoming documents into a specific number of groups](https://docs.mongodb.com/manual/reference/operator/aggregation/bucketAuto/), called buckets, based on a specified expression.
- **[`$count`](#count)**: [Count](https://docs.mongodb.com/manual/reference/operator/aggregation/count/) the input documents.
- **[`$facet`](#facet)**: Create [multi-faceted aggregations](https://docs.mongodb.com/manual/reference/operator/aggregation/facet/).
- **[`$filter`](#filter)**: Selects a subset of an array to return based on the [specified condition](https://docs.mongodb.com/master/reference/operator/aggregation/filter/#definition).
- **[`$limit`](#limit)**: Passes the first *n* documents unmodified to the pipeline where *n* is the specified [limit](https://docs.mongodb.com/manual/reference/operator/aggregation/limit/#pipe._S_limit) ([API](../../api/reactivemongo/api/commands/AggregationFramework#LimitextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)).
- **[`$match`](#match)**: Filters the document stream to allow only [matching documents](https://docs.mongodb.com/manual/reference/operator/aggregation/match/#pipe._S_match) ([API](../../api/reactivemongo/api/commands/AggregationFramework#MatchextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)).
- **[`$project`](#project)**: Reshapes each document in the stream, such as by [adding new fields or removing](https://docs.mongodb.com/manual/reference/operator/aggregation/project/#pipe._S_project) existing fields ([API](../../api/reactivemongo/api/commands/AggregationFramework#ProjectextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)).
- **[`$redact`](#redact)**: Reshapes each document in the stream by [restricting the content](https://docs.mongodb.com/manual/reference/operator/aggregation/redact/) for each document based on information stored in the documents themselves ([API](../../api/reactivemongo/api/commands/AggregationFramework#RedactextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)).
- **[`$skip`](#skip)**: Skips the first *n* documents where *n* is the specified [skip number](https://docs.mongodb.com/manual/reference/operator/aggregation/skip/#pipe._S_skip) and passes the remaining documents unmodified to the pipeline ([API](../../api/reactivemongo/api/commands/AggregationFramework#SkipextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)).
- **[`$unwind`](#unwind)**: Deconstructs an array field from the input documents to [output a document for *each* element](https://docs.mongodb.com/manual/reference/operator/aggregation/unwind/#pipe._S_unwind) ([API](../../api/reactivemongo/api/commands/AggregationFramework#UnwindextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)).
- **[`$group`](#group)**: Groups the input documents by a specified [identifier expression](https://docs.mongodb.com/manual/reference/operator/aggregation/group/) and possibly applies some accumulators ([API](../../api/reactivemongo/api/commands/GroupAggregation)).
  - **[`$sum`](#sum)**: [Sum](https://docs.mongodb.com/manual/reference/operator/aggregation/sum/#grp._S_sum) of numerical values.
  - **[`$avg`](#avg)**: [Average](https://docs.mongodb.com/manual/reference/operator/aggregation/avg/#grp._S_avg) of numerical values.
  - **[`$first`](#first)**: Value from the [first document](https://docs.mongodb.com/manual/reference/operator/aggregation/first/#grp._S_first) for each group.
  - **[`$last`](#last)**: Value from the [last document](https://docs.mongodb.com/manual/reference/operator/aggregation/last/#grp._S_last) for each group.
  - **[`$max`](#max)**: [Highest](https://docs.mongodb.com/manual/reference/operator/aggregation/max/#grp._S_max) expression value for each group.
  - **[`$min`](#min)**: [Lowest](https://docs.mongodb.com/manual/reference/operator/aggregation/min/#grp._S_min) expression value for each group.
  - **[`$push`](#push)**: [Array of expression](https://docs.mongodb.com/manual/reference/operator/aggregation/push/#grp._S_push) values for each group.
  - **[`$addToSet`](#addToSet)**: [Array of *unique* expression](https://docs.mongodb.com/manual/reference/operator/aggregation/addToSet/#grp._S_addToSet) values for each group.
  - **[`$stdDevPop`](#stdDevPop)**: [Population standard deviation](https://docs.mongodb.com/manual/reference/operator/aggregation/stdDevPop/#grp._S_stdDevPop) of the input values.
  - **[`$stdDevSamp`](#stdDevSamp)**: [Sample standard deviation](https://docs.mongodb.com/manual/reference/operator/aggregation/stdDevSamp/#grp._S_stdDevSamp) of the input values.
- **[`$sample`](#sample)**: [Randomly](https://docs.mongodb.com/manual/reference/operator/aggregation/sample/#pipe._S_sample) selects the specified number of documents from its input ([API](../../api/reactivemongo/api/commands/AggregationFramework#SampleextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)).
- **[`$sort`](#sort)**: Reorders the document stream by a specified [sort](https://docs.mongodb.com/manual/reference/operator/aggregation/sort/#pipe._S_sort) key ([API](../../api/reactivemongo/api/commands/AggregationFramework#SortextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)).
- **[`$geoNear`](#geoNear)**: Returns an ordered stream of documents based on the [proximity to a geospatial point](https://docs.mongodb.com/manual/reference/operator/aggregation/geoNear/#pipe._S_geoNear) ([API](../../api/reactivemongo/api/commands/AggregationFramework#GeoNearextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)).
- **[`$lookup`](#lookup)**: Performs a left outer [join to another collection](https://docs.mongodb.com/manual/reference/operator/aggregation/lookup/#pipe._S_lookup) in the *same* database ([API](../../api/reactivemongo/api/commands/AggregationFramework#LookupextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)).
- **[`$out`](#out)**: Writes the resulting documents of the aggregation [pipeline to a collection](https://docs.mongodb.com/manual/reference/operator/aggregation/out/#pipe._S_out) ([API](../../api/reactivemongo/api/commands/AggregationFramework#OutextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)).
- **[`$indexStats`](#indexStats)**: Returns statistics regarding the use of [each index for the collection](https://docs.mongodb.com/manual/reference/operator/aggregation/indexStats/#pipe._S_indexStats) ([API](../../api/reactivemongo/api/commands/AggregationFramework#IndexStats)).
- **[`$replaceRoot`](#replaceRoot)**: Promotes a specified document to the top level and replaces all other fields.
- **[`$slice`](#slice)**: Returns a subset of an array.

### Zip codes

Considering there is a `zipcodes` collection in a MongoDB, with the following documents.

```javascript
[
  { '_id': "10280", 'city': "NEW YORK", 'state': "NY",
    'population': 19746227, 'location': {'lon':-74.016323, 'lat':40.710537} },
  { '_id': "72000", 'city': "LE MANS", 'state': "FR", 
    'population': 148169, 'location': {'long':48.0077, 'lat':0.1984}},
  { '_id': "JP-13", 'city': "TOKYO", 'state': "JP", 
    'population': 13185502, 'location': {'lon':35.683333, 'lat':139.683333} },
  { '_id': "AO", 'city': "AOGASHIMA", 'state': "JP",
    'population': 200, 'location': {'lon':32.457, 'lat':139.767} }
]
```

**Distinct state**

The [`distinct`](https://docs.mongodb.org/manual/reference/command/distinct/) command is available to find the distinct values for a specified field across a single collection.

In the MongoDB shell, such command can be used to find the distinct states from the `zipcodes` collection, with results `"NY"`, `"FR"`, and `"JP"`.

```javascript
db.runCommand({ distinct: "state" })
```

Using the ReactiveMongo API, it can be done with the corresponding [collection operation](../../api/reactivemongo/api/collections/GenericCollection.GenericCollection#distinct[T]%28key:String,selector:Option[GenericCollection.this.pack.Document],readConcern:reactivemongo.api.ReadConcern%29%28implicitreader:GenericCollection.this.pack.NarrowValueReader[T],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[scala.collection.immutable.ListSet[T]]).

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.collection.BSONCollection

def distinctStates(col: BSONCollection)(implicit ec: ExecutionContext): Future[Set[String]] = col.distinct[String, Set]("state")
```

**States with population above 10000000**

It's possible to determine the states for which the <span id="sum">sum</span> of the population of their cities is above 10000000, by <span id="group">[grouping the documents](http://docs.mongodb.org/manual/reference/operator/aggregation/group/#pipe._S_group)</span> by their state, then for each [group calculating the sum](http://docs.mongodb.org/manual/reference/operator/aggregation/sum/#grp._S_sum) of the population values, and finally get only the grouped documents whose population sum [matches the filter](http://docs.mongodb.org/manual/reference/operator/aggregation/match/#pipe._S_match) "above 10000000".

In the MongoDB shell, such aggregation is written as bellow (see the [example](http://docs.mongodb.org/manual/tutorial/aggregation-zip-code-data-set/#return-states-with-populations-above-10-million)).

```javascript
db.zipcodes.aggregate([
   { $group: { _id: "$state", totalPop: { $sum: "$pop" } } },
   { $match: { totalPop: { $gte: 10000000 } } }
])
```

With ReactiveMongo, it <span id="match">can be done</span> using the [`.aggregatorContext`](../../api/reactivemongo/api/collections/GenericCollection.html#aggregatorContext%5BT%5D(firstOperator:GenericCollection.this.PipelineOperator,otherOperators:List%5BGenericCollection.this.PipelineOperator%5D,explain:Boolean,allowDiskUse:Boolean,bypassDocumentValidation:Boolean,readConcern:Option%5Breactivemongo.api.ReadConcern%5D,readPreference:reactivemongo.api.ReadPreference,batchSize:Option%5BInt%5D)(implicitreader:GenericCollection.this.pack.Reader%5BT%5D):GenericCollection.this.AggregatorContext%5BT%5D).

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.{ BSONDocument, BSONString }

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def populatedStates1(coll: BSONCollection): Future[List[BSONDocument]] = {
  import coll.aggregationFramework.{ Group, Match, SumField }

  coll.aggregatorContext[BSONDocument](
    Group(BSONString("$state"))( "totalPop" -> SumField("population")),
    List(Match(BSONDocument("totalPop" -> BSONDocument("$gte" -> 10000000L))))).
    prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())

}
```

> The local `import col.aggregationFramework._` is required, and cannot be replaced by a global static `import reactivemongo.api.collections.BSONCollection.aggregationFramework._`.

Then when calling `populatedStates(theZipCodeCol)`, the asynchronous result will be as bellow.

```javascript
[
  { "_id" -> "JP", "totalPop" -> 13185702 },
  { "_id" -> "NY", "totalPop" -> 19746227 }
]
```

> Note that for the state "JP", the population of Aogashima (200) and of Tokyo (13185502) have been summed.

If the goal is only to count the populated states, the <span id="count">[`$count`](https://docs.mongodb.com/manual/reference/operator/aggregation/count/index.html)</span> stage can be used.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.{ BSONDocument, BSONDocumentReader, BSONString }

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def countPopulatedStates1(coll: BSONCollection): Future[Int] = {
  implicit val countReader = BSONDocumentReader[Int] { doc =>
    doc.getAsTry[Int]("popCount").get
  }

  coll.aggregateWith[Int]() { framework =>
    import framework.{ Count, Group, Match, SumField }

    Group(BSONString("$state"))(
      "totalPop" -> SumField("population")) -> List(
        Match(BSONDocument("totalPop" -> BSONDocument("$gte" -> 10000000L))),
        Count("popCount"))
  }.head
}
```

As for the other commands in ReactiveMongo, it's possible to return the aggregation result as custom types (see [BSON readers](../bson/typeclasses.html)), rather than generic documents, for example considering a class `State` as bellow.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson._

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

case class State(name: String, population: Long)

implicit val reader = Macros.reader[State]

def populatedStates2(coll: BSONCollection): Future[List[State]] = {
  import coll.aggregationFramework.{ Group, Match, SumField }

  coll.aggregatorContext[State]( // <--
    Group(BSONString("$state"))( "totalPop" -> SumField("population")),
    List(Match(BSONDocument("totalPop" -> BSONDocument("$gte" -> 10000000L))))).
    prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[State]]())

}
```

*Using cursor:*

The alternative [`.aggregateWith1`](../../api/reactivemongo/api/collections/GenericCollection.html#aggregateWith1[T](explain:Boolean,allowDiskUse:Boolean,bypassDocumentValidation:Boolean,readConcern:Option[reactivemongo.api.ReadConcern],readPreference:reactivemongo.api.ReadPreference,batchSize:Option[Int])(f:GenericCollection.this.AggregationFramework=>(GenericCollection.this.PipelineOperator,List[GenericCollection.this.PipelineOperator]))(implicitec:scala.concurrent.ExecutionContext,implicitreader:GenericCollection.this.pack.Reader[T],implicitcf:reactivemongo.api.CursorFlattener[reactivemongo.api.Cursor],implicitcp:reactivemongo.api.CursorProducer[T]):cp.ProducedCursor) builder can be used, to process the aggregation result with a [`Cursor`](../../api/reactivemongo/api/Cursor).

```scala
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson._
import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def populatedStatesCursor(cities: BSONCollection)(implicit ec: ExecutionContext): Cursor[BSONDocument] =
  cities.aggregateWith1[BSONDocument]() { framework =>
    import framework.{ Group, Match, SumField }

    Group(BSONString("$state"))("totalPop" -> SumField("population")) -> List(
      Match(document("totalPop" -> document("$gte" -> 10000000L)))
    )
  }
```

The [`GroupField`](../../api/reactivemongo/api/commands/AggregationFramework#GroupFieldextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable) operator can be used instead of the `Group` one, to simply work with a single field.

> In the previous example the dependent import `myCol.aggregationFramework._` are replaced by a simpler import using the instance of the aggregation framework provided by the builder: `import framework.{ Group, Match, SumField }`

**Most populated city per state**

The <span id="max">[`$max`](https://docs.mongodb.com/manual/reference/operator/aggregation/max/#grp._S_max)</span> can be used to get the most populated site per state.

In the MongoDB shell, it would be executed as following.

```javascript
db.zipcodes.aggregate([
   { $group: { _id: "$state", maxPop: { $max: "$population" } } }
])
```

It will return a result as bellow.

```javascript
[
  { _id: "JP", maxPop: 13185502 },
  { _id: "FR", maxPop: 148169 }
  { _id: "NY", maxPop: 19746227 }
]
```

Using ReactiveMongo:

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson._

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def mostPopulated(cities: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import cities.aggregationFramework
  import aggregationFramework.{ Group, MaxField }

  cities.aggregatorContext[BSONDocument](Group(BSONString("$state"))(
    "maxPop" -> MaxField("population")
  )).prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())
}
```

Similarly, the <span id="min">[`$min`](https://docs.mongodb.com/manual/reference/operator/aggregation/min/#grp._S_min)</span> accumulator can be used to get the least populated cities.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson._

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def leastPopulated(cities: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import cities.aggregationFramework
  import aggregationFramework.{ Group, MinField }

  cities.aggregatorContext[BSONDocument](Group(BSONString("$state"))(
    "minPop" -> MinField("population")
  )).prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())
}
```

> The [`Min`](../../api/reactivemongo/api/commands/GroupAggregation#MinextendsGroupAggregation.this.GroupFunctionwithProductwithSerializable) and the [`Max`](../../api/reactivemongo/api/commands/GroupAggregation#MaxextendsGroupAggregation.this.GroupFunctionwithProductwithSerializable) operators can be used instead of `MinField` and `MaxField`, to use expressions in place of single fields.

**Gather the city names per state as a simple array**

The <span id="push">[`$push`](https://docs.mongodb.com/manual/reference/operator/aggregation/push/#grp._S_push)</span> accumulator can be used to gather some fields, so there is a computed array for each group.

In the MongoDB shell, it can be done as bellow.

```javascript
db.zipcodes.aggregate([
  { $group: { _id: "$state", cities: { $push: "$city" } } }
])
```

It will return the aggregation results:

```javascript
[
  { _id: "JP", cities: [ "TOKYO", "AOGASHIMA" ] },
  { _id: "FR", cities: [ "LE MANS" ] },
  { _id: "NY", cities: [ "NEW YORK" ] }
}
```

```javascript
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson._

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def citiesPerState1(cities: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import cities.aggregationFramework.{ Group, PushField }

  cities.aggregatorContext[BSONDocument](Group(BSONString("$state"))(
    "cities" -> PushField("city"))).prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())
}
```

Similarly the <span id="addToSet">[`$addToSet` accumulator](https://docs.mongodb.com/manual/reference/operator/aggregation/addToSet/#grp._S_addToSet)</span> can be applied to collect all the unique values in the array for each group (there it's equivalent to `$push`).

```javascript
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson._

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def citiesPerState1(cities: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import cities.aggregationFramework.{ Group, AddFieldToSet }

  cities.aggregatorContext[BSONDocument](Group(BSONString("$state"))(
    "cities" -> AddFieldToSet("city"))).prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())
}
```

> The [`AddToSet`](../../api/reactivemongo/api/commands/GroupAggregation#AddToSetextendsGroupAggregation.this.GroupFunctionwithProductwithSerializable) and the [`Push`](../../api/reactivemongo/api/commands/GroupAggregation#PushextendsGroupAggregation.this.GroupFunctionwithProductwithSerializable) operators can be used instead of `AddFieldToSet` and `PushField`, to use expressions in place of single fields.

**Average city population by state**

The accumulator <span id="avg">`$avg`</span> can be used to find [the average population of the cities by state](http://docs.mongodb.org/manual/tutorial/aggregation-zip-code-data-set/#return-average-city-population-by-state).

In the MongoDB shell, it can be done as following.

```javascript
db.zipcodes.aggregate([
   { $group: { _id: { state: "$state", city: "$city" }, pop: { $sum: "$pop" } } },
   { $group: { _id: "$_id.state", avgCityPop: { $avg: "$pop" } } }
])
```

1. Group the documents by the combination of city and state, to get intermediate documents of the form `{ "_id" : { "state" : "NY", "city" : "NEW YORK" }, "pop" : 19746227 }`.
2. Group the intermediate documents by the `_id.state` field (i.e. the state field inside the `_id` document), and get the average of population of each group (`$avg: "$pop"`).

Using ReactiveMongo, it can be written as bellow.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.{ BSONDocument, BSONString }

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def avgPopByState(col: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import col.aggregationFramework.{ AvgField, Group, SumField }

  col.aggregatorContext[BSONDocument](
    Group(BSONDocument("state" -> "$state", "city" -> "$city"))(
    "pop" -> SumField("population")),
    List(Group(BSONString("$_id.state"))("avgCityPop" -> AvgField("pop")))).
    prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())
}
```

> The [`Avg`](../../api/reactivemongo/api/commands/GroupAggregation#AvgextendsGroupAggregation.this.GroupFunctionwithProductwithSerializable) operator can be used instead of `AvgField`, to use an expression in place of a single field.

**Largest and smallest cities by state**

Aggregating the documents can be used to find the <span id="project"><span id="first"><span id="last">[largest and the smallest cities for each state](http://docs.mongodb.org/manual/tutorial/aggregation-zip-code-data-set/#return-largest-and-smallest-cities-by-state)</span></span></span>:

```javascript
db.zipcodes.aggregate([
   { $group:
      {
        _id: { state: "$state", city: "$city" },
        pop: { $sum: "$pop" }
      }
   },
   { $sort: { pop: 1 } },
   { $group:
      {
        _id : "$_id.state",
        biggestCity:  { $last: "$_id.city" },
        biggestPop:   { $last: "$pop" },
        smallestCity: { $first: "$_id.city" },
        smallestPop:  { $first: "$pop" }
      }
   },

  // the following $project is optional, and
  // modifies the output format.

  { $project:
    { _id: 0,
      state: "$_id",
      biggestCity:  { name: "$biggestCity",  pop: "$biggestPop" },
      smallestCity: { name: "$smallestCity", pop: "$smallestPop" }
    }
  }
])
```

A ReactiveMongo function can be written <span id="sort">as bellow</span>.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.{ BSONDocument, BSONString, Macros }

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

case class City(name: String, population: Long)

object City {
  implicit val reader = Macros.reader[City]
}

case class StateStats(state: String, biggestCity: City, smallestCity: City)

object StateStats {
  implicit val reader = Macros.reader[StateStats]
}

def stateStats(col: BSONCollection): Future[List[StateStats]] = {
  import col.aggregationFramework.{
    Ascending, FirstField, Group, LastField, Project, Sort, SumField
  }

  col.aggregatorContext[StateStats](
    Group(BSONDocument("state" -> "$state", "city" -> "$city"))(
    "pop" -> SumField("population")),
    List(Sort(Ascending("population")), Group(BSONString("$_id.state"))(
        "biggestCity" -> LastField("_id.city"),
        "biggestPop" -> LastField("pop"),
        "smallestCity" -> FirstField("_id.city"),
        "smallestPop" -> FirstField("pop")),
      Project(BSONDocument("_id" -> 0, "state" -> "$_id",
        "biggestCity" -> BSONDocument("name" -> "$biggestCity",
          "population" -> "$biggestPop"),
        "smallestCity" -> BSONDocument("name" -> "$smallestCity",
          "population" -> "$smallestPop"))))).
    prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[StateStats]]())

}
```

This function would return statistics like the following.

```scala
List(
  StateStats(state = "NY",
    biggestCity = City(name = "NEW YORK", population = 19746227L),
    smallestCity = City(name = "NEW YORK", population = 19746227L)),
  StateStats(state = "FR",
    biggestCity = City(name = "LE MANS", population = 148169L),
    smallestCity = City(name = "LE MANS", population = 148169L)),
  StateStats(state = "JP",
    biggestCity = City(name = "TOKYO", population = 13185502L),
    smallestCity = City(name = "AOGASHIMA", population = 200L)))
```

> The [`First`](../../api/reactivemongo/api/commands/GroupAggregation#FirstextendsGroupAggregation.this.GroupFunctionwithProductwithSerializable) and the [`Last`](../../api/reactivemongo/api/commands/GroupAggregation#LastextendsGroupAggregation.this.GroupFunctionwithProductwithSerializable) operators can be used instead of `FirstField` and `LastField`, to use expressions in place of single fields.

The <span id="limit">[`$limit`](https://docs.mongodb.com/manual/reference/operator/aggregation/limit/#pipe._S_limit)</span> or the <span id="skip">[`$skip`](https://docs.mongodb.com/manual/reference/operator/aggregation/skip/#pipe._S_skip)</span> stages can be used to consider only some states:

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson._

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def paginatedStats(col: BSONCollection, max: Int, offset: Int = 0): Future[List[StateStats]] = {
  import col.aggregationFramework.{
    Ascending, FirstField, Group, LastField, Limit,
    Project, Skip, Sort, SumField
  }

  col.aggregatorContext[StateStats](
    Group(BSONDocument("state" -> "$state", "city" -> "$city"))(
    "pop" -> SumField("population")),
    List(
      Skip(offset), // <-- skip some states if offset > 0
      Limit(max), // <-- limit the state groups
      Sort(Ascending("population")), 
      Group(BSONString("$_id.state"))(
        "biggestCity" -> LastField("_id.city"),
        "biggestPop" -> LastField("pop"),
        "smallestCity" -> FirstField("_id.city"),
        "smallestPop" -> FirstField("pop")),
      Project(BSONDocument("_id" -> 0, "state" -> "$_id",
        "biggestCity" -> BSONDocument("name" -> "$biggestCity",
          "population" -> "$biggestPop"),
        "smallestCity" -> BSONDocument("name" -> "$smallestCity",
          "population" -> "$smallestPop"))))).
    prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[StateStats]]())
}
```

**Standard deviation of the japanese cities**

The group accumulators <span id="stdDevPop">[`$stdDevPop`](https://docs.mongodb.com/manual/reference/operator/aggregation/stdDevPop/#grp._S_stdDevPop)</span> and <span id="stdDevSamp">[`$stdDevSamp`](https://docs.mongodb.com/manual/reference/operator/aggregation/stdDevSamp/#grp._S_stdDevSamp)</span> can be used to find the standard deviation of the japanese cities.

In the MongoDB, it can be done as following.

```javascript
db.zipcodes.aggregate([
   { $group:
      {
        _id: "$state",
        popDev: { $stdDevPop: "$population" }
      }
   },
   { $match: { _id: "JP" } }
])
```

It will find the result:

```javascript
{ _id: "JP", popDev: 6592651 }
```

It can be done with ReactiveMongo as bellow.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def populationStdDeviation(cities: BSONCollection)(implicit ec: ExecutionContext): Future[Option[BSONDocument]] = {
  import cities.aggregationFramework
  import aggregationFramework.{ StdDevPopField, Group, Match }

  cities.aggregatorContext[BSONDocument](Group(BSONString("$state"))(
    "popDev" -> StdDevPopField("population")),
    List(Match(document("_id" -> "JP")))).prepared.cursor.headOption
}

def populationSampleDeviation(cities: BSONCollection)(implicit ec: ExecutionContext): Future[Option[BSONDocument]] = {
  import cities.aggregationFramework
  import aggregationFramework.{ StdDevSampField, Group, Match }

  cities.aggregatorContext[BSONDocument](Group(BSONString("$state"))(
    "popDev" -> StdDevSampField("population")),
    List(Match(document("_id" -> "JP")))).prepared.cursor.headOption
}
```

> The [`StdDevPop`](../../api/reactivemongo/api/commands/GroupAggregation#StdDevPopextendsGroupAggregation.this.GroupFunctionwithProductwithSerializable) and the [`StdDevSamp`](../../api/reactivemongo/api/commands/GroupAggregation#StdDevSampextendsGroupAggregation.this.GroupFunctionwithProductwithSerializable) operators can be used instead of `StdDevPopField` and `StdDevSampField`, to use expressions in place of single fields.

**Find documents using text indexing**

Consider the following [text indexes](https://docs.mongodb.org/manual/core/index-text/) is maintained for the fields `city` and `state` of the `zipcodes` collection.

```javascript
db.zipcodes.ensureIndex({ city: "text", state: "text" })
```

Then it's possible to find documents using the [`$text` operator](https://docs.mongodb.org/v3.0/reference/operator/query/text/#op._S_text), and also the results can be [sorted](https://docs.mongodb.org/v3.0/reference/operator/aggregation/sort/#metadata-sort) according the [text scores](https://docs.mongodb.org/v3.0/reference/operator/query/text/#text-operator-text-score).

For example to find the documents matching the text `"JP"`, and sort according the text score, the following query can be executed in the MongoDB shell.

```javascript
db.users.aggregate([
   { $match: { $text: { $search: "JP" } } },
   { $sort: { score: { $meta: "textScore" } } }
])
```

A ReactiveMongo function can be written as bellow.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def textFind(coll: BSONCollection): Future[List[BSONDocument]] = {
  import coll.aggregationFramework
  import aggregationFramework.{ Match, MetadataSort, Sort, TextScore }

  val firstOp = Match(BSONDocument(
    "$text" -> BSONDocument("$search" -> "JP")))

  val pipeline = List(Sort(MetadataSort("score", TextScore)))

  coll.aggregatorContext[BSONDocument](firstOp, pipeline).prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())
}
```

This will return the sorted documents for the cities `TOKYO` and `AOGASHIMA`.

**Random sample**

The [`$sample`](https://docs.mongodb.org/manual/reference/operator/aggregation/sample/) aggregation stage can be used (since MongoDB 3.2), in order to randomly selects documents.

In the MongoDB shell, it can be used as following to fetch a sample of 3 random documents.

```javascript
db.zipcodes.aggregate([
  { $sample: { size: 3 } }
])
```

With ReactiveMongo, the <span id="sample">[`$sample`](../../api/reactivemongo/api/commands/AggregationFramework#SampleextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)</span> operator can be used as follows.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def randomZipCodes(coll: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import coll.aggregationFramework

  coll.aggregatorContext[BSONDocument](aggregationFramework.Sample(3)).
    prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())
}
```

**Population buckets**

Since MongoDB 3.4, Using the [`$bucketAuto`](https://docs.mongodb.com/manual/reference/operator/aggregation/bucketAuto/) stage can be used in the MongoShell, to group the cities according their population, in an expected number of group so called 'buckets' (bellow 2).

```javascript
db.zipcodes.aggregate([
  { $bucketAuto: { groupBy: '$population', buckets: 2 } }
])
```

Such aggregation with return the following results.

```javascript
{ "_id" : { "min" : 200, "max" : 13185502 }, "count" : 2 }
{ "_id" : { "min" : 13185502, "max" : 19746227 }, "count" : 2 }
```

This stage <span id="bucketAuto">[`$bucketAuto`](../../api/commands/AggregationFramework.html#BucketAutoextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable)</span> can be used in ReactiveMongo as bellow.

```scala
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson._
import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def populationBuckets(zipcodes: BSONCollection)(implicit ec: ExecutionContext) =
  zipcodes.aggregateWith1[BSONDocument]() { framework =>
    import framework.BucketAuto

    BucketAuto(BSONString(f"$$population"), 2, None)() -> List.empty
  }.collect[Set](Int.MaxValue, Cursor.FailOnError[Set[BSONDocument]]())
```

### Places

Let consider a collection of different kinds of place (e.g. Central Park ...), with their locations indexed using [`2dsphere`](https://docs.mongodb.com/manual/core/2dsphere/#create-a-2dsphere-index).

This can be setup with the MongoDB shell as follows.

```javascript
db.place.createIndex({'loc':"2dsphere"});

db.place.insert({
  "type": "public",
  "loc": {
    "type": "Point", "coordinates": [-73.97, 40.77]
  },
  "name": "Central Park",
  "category": "Parks"
});
db.place.insert({
  "type": "public",
  "loc": {
    "type": "Point", "coordinates": [-73.88, 40.78]
  },
  "name": "La Guardia Airport",
  "category": "Airport"
});
```

The <span id="geoNear">[`$geoNear`](https://docs.mongodb.com/manual/reference/operator/aggregation/geoNear/)</span> aggregation can be used on the collection, to find the place near the geospatial coordinates `[ -73.9667, 40.78 ]`, within 1 km (1000 meters) and 5 km (5000 meters)

```javascript
db.places.aggregate([{
  $geoNear: {
    near: { type: "Point", coordinates: [ -73.9667, 40.78 ] },
    distanceField: "dist.calculated",
    minDistance: 1000,
    maxDistance: 5000,
    query: { type: "public" },
    includeLocs: "dist.location",
    num: 5,
    spherical: true
  }
}])
```

The results will be of the following form:

```javascript
{
  "type": "public",
  "loc": {
    "type": "Point",
    "coordinates": [ -73.97, 40.77 ]
  },
  "name": "Central Park",
  "category": "Parks",
  "dist": {
    "calculated": 1147.4220523120696,
    "loc": {
      "type": "Point",
      "coordinates": [ -73.97, 40.77 ]
    }
  }
}
```

It can be done with ReactiveMongo as follows.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.{ array, document, Macros }

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

case class GeoPoint(coordinates: List[Double])
case class GeoDistance(calculated: Double, loc: GeoPoint)

case class GeoPlace(
  loc: GeoPoint,
  name: String,
  category: String,
  dist: GeoDistance
)

object GeoPlace {
  implicit val pointReader = Macros.reader[GeoPoint]
  implicit val distanceReader = Macros.reader[GeoDistance]
  implicit val placeReader = Macros.reader[GeoPlace]
}

def placeArround(places: BSONCollection)(implicit ec: ExecutionContext): Future[List[GeoPlace]] = {
  import places.aggregationFramework.GeoNear

  places.aggregatorContext[GeoPlace](GeoNear(document(
    "type" -> "Point",
    "coordinates" -> array(-73.9667, 40.78)
  ), distanceField = Some("dist.calculated"),
    minDistance = Some(1000),
    maxDistance = Some(5000),
    query = Some(document("type" -> "public")),
    includeLocs = Some("dist.loc"),
    limit = Some(5),
    spherical = true)).prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[GeoPlace]]())
}
```

### Forecast

Consider a collection of forecasts with the following document.

```javascript
{
  _id: 1,
  title: "123 Department Report",
  tags: [ "G", "STLW" ],
  year: 2014,
  subsections: [
    {
      subtitle: "Section 1: Overview",
      tags: [ "SI", "G" ],
      content:  "Section 1: This is the content of section 1."
    },
    {
      subtitle: "Section 2: Analysis",
      tags: [ "STLW" ],
      content: "Section 2: This is the content of section 2."
    },
    {
      subtitle: "Section 3: Budgeting",
      tags: [ "TK" ],
      content: {
        text: "Section 3: This is the content of section3.",
        tags: [ "HCS" ]
      }
    }
  ]
}
```

Using the <span id="redact">[`$redact` stage](https://docs.mongodb.com/manual/reference/operator/aggregation/redact/)</span>, the MongoDB aggregation can be used to restricts the contents of the documents. It can be done in the MongoDB shell as follows:

```javascript
db.forecasts.aggregate([
  { $match: { year: 2014 } },
  { 
    $redact: {
      $cond: {
        if: { $gt: [ { $size: { 
          $setIntersection: [ "$tags", [ "STLW", "G" ] ] } }, 0 ]
        },
        then: "$$DESCEND",
        else: "$$PRUNE"
      }
    }
  }
])
```

The corresponding results a redacted document.

```javascript
{
  "_id" : 1,
  "title" : "123 Department Report",
  "tags" : [ "G", "STLW" ],
  "year" : 2014,
  "subsections" : [
    {
      "subtitle" : "Section 1: Overview",
      "tags" : [ "SI", "G" ],
      "content" : "Section 1: This is the content of section 1."
    },
    {
      "subtitle" : "Section 2: Analysis",
      "tags" : [ "STLW" ],
      "content" : "Section 2: This is the content of section 2."
    }
  ]
}
```

With ReactiveMongo, the aggregation framework can perform a similar redaction.

```scala
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson._

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def redactForecasts(forecasts: BSONCollection)(implicit ec: ExecutionContext) = {
  import forecasts.aggregationFramework.{ Match, Redact }

  forecasts.aggregatorContext[BSONDocument](
    Match(document("year" -> 2014)), List(
    Redact(document("$cond" -> document(
      "if" -> document(
        "$gt" -> array(document(
          "$size" -> document("$setIntersection" -> array(
            "$tags", array("STLW", "G")
          ))
        ), 0)
      ),
      "then" -> "$$DESCEND",
      "else" -> "$$PRUNE"
    ))))).prepared.cursor.
      collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())
}
```

### Inventory

Consider an `inventory` collection, with the following document.

```javascript
{ "_id" : 1, "item" : "ABC1", "sizes": [ "S", "M", "L"] }
```

The <span id="unwind">[`$unwind`](https://docs.mongodb.com/manual/reference/operator/aggregation/unwind/#pipe._S_unwind)</span> stage can be used as bellow in the MongoDB shell, to return a document for each size.

```javascript
db.inventory.aggregate( [ { $unwind : "$sizes" } ] )
```

It will return results as bellow.

```javascript
{ "_id" : 1, "item" : "ABC1", "sizes" : "S" }
{ "_id" : 1, "item" : "ABC1", "sizes" : "M" }
{ "_id" : 1, "item" : "ABC1", "sizes" : "L" }
```

With ReactiveMongo, it can be done using [`Unwind`](../../api/reactivemongo/api/commands/AggregationFramework#UnwindextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable).

```scala
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def sized(inventory: BSONCollection) = {
  import inventory.aggregationFramework.UnwindField

  inventory.aggregatorContext[BSONDocument](UnwindField("sizes")).
    prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())
}
```

If there is a second `price` collection, with the following document.

```javascript
{ "_id" : 10, "item" : "ABC1", "price" : 12.34 }
```

This can be joined using the MongoDB shell, with the <span id="lookup">[`$lookup`](https://docs.mongodb.com/manual/reference/operator/aggregation/lookup/#pipe._S_lookup)</span> stage.

```javascript
db.inventory.aggregate([{
  $lookup: {
    from: "prices",
    localField: "item",
    foreignField: "item",
    as: "prices"
  }
}])
```

It will result in the document thereafter.

```javascript
{
  "_id" : 1,
  "item" : "ABC1",
  "sizes": [ "S", "M", "L" ],
  "prices": [
    { "_id" : 10, "item" : "ABC1", "price" : 12.34 }
  ]
}
```

It can be done with ReactiveMongo using the [`Lookup`](../../api/reactivemongo/api/commands/AggregationFramework#LookupextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable) operator.

```scala
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def priced(inventory: BSONCollection, prices: BSONCollection) = {
  import prices.aggregationFramework.Lookup

  prices.aggregatorContext[BSONDocument](
    Lookup(inventory.name, "item", "item", "prices")
  ).prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())
}
```

The [`$facet`](https://docs.mongodb.com/manual/reference/operator/aggregation/facet/) allow to create multi-faceted aggregations, which characterize data across multiple dimensions (or facets); e.g.

```javascript
db.inventory.aggregate([{
  $facet: {
    'foo': [
      { '$unwind': '$sizes' },
      { '$count': 'c' }
    ],
    'lorem': [
      { '$out': 'item_stats' }
    ]
  }
}])
```

Such aggregation can be executed with ReactiveMongo as bellow.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.Cursor
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.collection.BSONCollection

def useFacetAgg(inventory: BSONCollection)(
  implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import inventory.aggregationFramework.{ Count, Facet, Out, UnwindField }

  val facet = Facet(Seq(
    "foo" -> (UnwindField("bar"), List(Count("c"))),
    "lorem" -> (Out("ipsum"), List.empty)))

  inventory.aggregatorContext[BSONDocument](facet).
    prepared.cursor.
    collect[List](-1, Cursor.FailOnError[List[BSONDocument]]())

}
```

### Book library

Consider a collection *books* that contains the following documents.

```javascript
{ "_id" : 8751, "title" : "The Banquet", "author" : "Dante", "copies" : 2 }
{ "_id" : 8752, "title" : "Divine Comedy", "author" : "Dante", "copies" : 1 }
{ "_id" : 8645, "title" : "Eclogues", "author" : "Dante", "copies" : 2 }
{ "_id" : 7000, "title" : "The Odyssey", "author" : "Homer", "copies" : 10 }
{ "_id" : 7020, "title" : "Iliad", "author" : "Homer", "copies" : 10 }
```

Then its documents can be aggregated and outputted to another collection, using the <span id="out">[`$out`](https://docs.mongodb.com/manual/reference/operator/aggregation/out/#pipe._S_out)</span> stage.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.{ BSONDocument, BSONString }
import reactivemongo.api.bson.collection.BSONCollection

def outputBooks(books: BSONCollection, outColl: String): Future[Unit] = {
  import books.aggregationFramework
  import aggregationFramework.{ Ascending, Group, PushField, Out, Sort }

  books.aggregatorContext[BSONDocument](Sort(Ascending("title")), List(
    Group(BSONString("$author"))("books" -> PushField("title")),
    Out(outColl))).prepared.cursor.head.map(_ => {})
}
```

For the current example, the result collection will contain the following documents.

```javascript
{ "_id" : "Homer", "books" : [ "Iliad", "The Odyssey" ] }
{ "_id" : "Dante", "books" : [ "Divine Comedy", "Eclogues", "The Banquet" ] }
```

### Fruits

The <span id="replaceRoot">[`$replaceRoot`](https://docs.mongodb.com/manual/reference/operator/aggregation/replaceRoot/#pipe._S_replaceRoot)</span> promotes a specified document to the top level and replaces all other fields.

Consider a a collection of fruits as bellow.

```javascript
{
   "_id" : 1,
   "fruit" : [ "apples", "oranges" ],
   "in_stock" : { "oranges" : 20, "apples" : 60 },
   "on_order" : { "oranges" : 35, "apples" : 75 }
}
{
   "_id" : 2,
   "vegetables" : [ "beets", "yams" ],
   "in_stock" : { "beets" : 130, "yams" : 200 },
   "on_order" : { "beets" : 90, "yams" : 145 }
}
```

The stage can be used in aggregation with MongoShell:

```javascript
db.produce.aggregate([
   { $replaceRoot: { newRoot: "$in_stock" } }
])
```

It will return the following documents:

```javascript
{ "oranges": 20, "apples": 60 }
{ "beets": 130, "yams": 200 }
```

It can be done using ReactiveMongo.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.BSONDocument

import reactivemongo.api.bson.collection.BSONCollection

def replaceRootTest(fruits: BSONCollection): Future[Option[BSONDocument]] = {
  fruits.aggregateWith1[BSONDocument]() { framework =>
    import framework._

    ReplaceRootField("in_stock") -> List.empty
  }.headOption
}
```

### Sales

Consider a collection of sales as bellow.

```javascript
{
   _id: 0,
   items: [
     { item_id: 43, quantity: 2, price: 10 },
     { item_id: 2, quantity: 1, price: 240 }
   ]
}
{
   _id: 1,
   items: [
     { item_id: 23, quantity: 3, price: 110 },
     { item_id: 103, quantity: 4, price: 5 },
     { item_id: 38, quantity: 1, price: 300 }
   ]
}
{
    _id: 2,
    items: [
       { item_id: 4, quantity: 1, price: 23 }
    ]
}
```

Using the aggregate stages `$project` and <span id="filter">[`$filter`](https://docs.mongodb.com/master/reference/operator/aggregation/filter/#definition)</span> (since 3.2), in the MongoShell it's possible to filters the *items* array to only include documents that have a *price* greater than or equal to 100:

```javascript
db.sales.aggregate([ {
  $project: {
    items: {
      $filter: {
        input: "$items",
        as: "item",
        cond: { $gte: [ "$$item.price", 100 ] }
      }
    }
  }
} ])
```

The same can be done using ReactiveMongo:

```scala
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.bson.{ BSONArray, BSONDocument, BSONString }

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def salesWithItemGreaterThanHundered(sales: BSONCollection) =
  sales.aggregateWith1[BSONDocument]() { framework =>
    import framework._

    val sort = Sort(Ascending("_id"))

    Project(BSONDocument("items" -> Filter(
      input = BSONString(f"$$items"),
      as = "item",
      cond = BSONDocument(
        f"$$gte" -> BSONArray(f"$$$$item.price", 100))))) -> List(sort)

  }.collect[List](Int.MaxValue, Cursor.FailOnError[List[BSONDocument]]())
```

### Database indexes aggregation

The <span id="indexStats">[`$indexStats`](https://docs.mongodb.com/manual/reference/operator/aggregation/indexStats/#pipe._S_indexStats)</span> stage returns statistics regarding the use of each index for a collection.

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def aggregateIndexes(coll: BSONCollection) = {
  import coll.aggregationFramework.{ Ascending, IndexStats, Sort }
  import reactivemongo.api.commands.{ bson => bsoncommands }
  import bsoncommands.BSONAggregationFramework.IndexStatsResult
  import bsoncommands.BSONAggregationResultImplicits.BSONIndexStatsReader

  val result: Future[List[IndexStatsResult]] =
    coll.aggregatorContext[IndexStatsResult](
      IndexStats, List(Sort(Ascending("name")))).
      prepared.cursor.
      collect[List](-1, Cursor.FailOnError[List[IndexStatsResult]]())

  result
}
```

### Students

Considering the following collection of students:

```javascript
{
  _id: 1,
  student: "Maya",
  homework: [ 10, 5, 10 ],
  quiz: [ 10, 8 ],
  extraCredit: 0
}
{
  _id: 2,
  student: "Ryan",
  homework: [ 5, 6, 5 ],
  quiz: [ 8, 8 ],
  extraCredit: 8
}
```

Then it's possible to sum the `homework` and `quiz` arrays using the <span id="addFields">[`$addFields`](https://docs.mongodb.com/manual/reference/operator/aggregation/addFields/)</span> as bellow in the MongoShell.

```javascript
db.scores.aggregate([
  {
    $addFields: {
      totalHomework: { $sum: "$homework" } ,
      totalQuiz: { $sum: "$quiz" }
    }
  },
  {
    $addFields: { totalScore:
      { $add: [ "$totalHomework", "$totalQuiz", "$extraCredit" ] } }
  }
])
```

It can be done using ReactiveMongo:

```javascript
import scala.concurrent.ExecutionContext

import reactivemongo.api.collections.BSONCollection

def sumHomeworkQuizz(students: BSONCollection) =
  students.aggregateWith1[BSONDocument]() { framework =>
    import framework.AddFields

    AddFields(document(
      "totalHomework" -> document(f"$$sum" -> f"$$homework"),
      "totalQuiz" -> document(f"$$sum" -> f"$$quiz"))) -> List(
      AddFields(document(
        "totalScore" -> document(f"$$add" -> array(
        f"$$totalHomework", f"$$totalQuiz", f"$$extraCredit")))))
  }
```

### Users

Consider the following user collection.

```javascript
{ "_id" : 1, "name" : "dave123", favorites: [ "chocolate", "cake", "butter", "apples" ] }
{ "_id" : 2, "name" : "li", favorites: [ "apples", "pudding", "pie" ] }
{ "_id" : 3, "name" : "ahn", favorites: [ "pears", "pecans", "chocolate", "cherries" ] }
{ "_id" : 4, "name" : "ty", favorites: [ "ice cream" ] }
```

The favorites of each user can be [sliced](https://docs.mongodb.com/manual/reference/operator/aggregation/slice/#example) to keep only the 3 top favorites:

```javascript
db.users.aggregate([
   { $project: { name: 1, favorites: { $slice: [ "$favorites", 3 ] } } }
])
```

It's also supported by ReactiveMongo as bellow.

```scala
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson._
import reactivemongo.api.Cursor
import reactivemongo.api.bson.collection.BSONCollection

def sliceFavorites(coll: BSONCollection)(implicit ec: ExecutionContext) =
  coll.aggregateWith1[BSONDocument]() { framework =>
    import framework.{ Project, Slice }

    Project(BSONDocument(
      "name" -> 1,
      "favorites" -> Slice(
        array = BSONString(f"$$favorites"),
        n = BSONInteger(3)).makePipe)) -> List.empty
  }.collect[Seq](4, Cursor.FailOnError[Seq[BSONDocument]]())
```

**See also:**

- The operators available to define an aggregation pipeline are documented in the [API reference](../../api/reactivemongo/api/collections/GenericCollection.html#AggregationFramework=GenericCollection.this.aggregationFramework.type).
- The [Aggregation Framework tests](https://github.com/ReactiveMongo/ReactiveMongo/blob/master/driver/src/test/scala/AggregationSpec.scala)

[Next: Custom stage](./agg-custom-stage.html)

<script src="//ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script>
<script src="/javascripts/highlight.min.js"></script>
<script>
function hl(txt){
  var b = $('body p, body figure');
  b.removeHighlight();
  b.highlight(txt);
}

$("#main ul a[href^='#']").each(function(i,x){
  var e=$(x),t=e.text();
  if (t.startsWith("$")){
    e.click(function(){ hl(t.substring(1)) })
  }
})
</script>
