---
layout: default
major_version: 0.12
title: Aggregation Framework
---

## Aggregation Framework

The [MongoDB Aggregation Framework](http://docs.mongodb.org/manual/reference/operator/aggregation/) is available through ReactiveMongo.

- [`$group`](#group): [specifications](https://docs.mongodb.com/manual/reference/operator/aggregation/group/) / [API](https://reactivemongo.org/releases/0.12/api/index.html#reactivemongo.api.commands.GroupAggregation)
  - [`$sum`](#sum)
  - [`$avg`](#avg)
  - [`$first`](#first)
  - [`$last`](#last)
  - [`$max`](#max)
  - [`$min`](#min)
  - [`$push`](#push)
  - [`$addToSet`](#addToSet)
  - [`$stdDevPop`](#stdDevPop)
  - [`$stdDevSamp`](#stdDevSamp)

### ZipCodes example

Considering there is a `zipcodes` collection in a MongoDB, with the following documents.

{% highlight javascript %}
[
  { '_id': "10280", 'city': "NEW YORK", 'state': "NY",
    'population': 19746227, 'location': {'lon':-74.016323, 'lat':40.710537} },
  { '_id': "72000", 'city': "LE MANS", 'state': "FR", 
    'population': 148169, 'location': {'long':48.0077, 'lat':0.1984}},
  { '_id': "JP-13", 'city': "TOKYO", 'state': "JP", 
    'population': 13185502L, 'location': {'lon':35.683333, 'lat':139.683333} },
  { '_id': "AO", 'city': "AOGASHIMA", 'state': "JP",
    'population': 200, 'location': {'lon':32.457, 'lat':139.767} }
]
{% endhighlight %}

**Distinct state**

The [`distinct`](https://docs.mongodb.org/manual/reference/command/distinct/) command, to find the distinct values for a specified field across a single collection.

In the MongoDB shell, such command can be used to find the distinct states from the `zipcodes` collection, with results `"NY"`, `"FR"`, and `"JP"`.

{% highlight javascript %}
db.runCommand({ distinct: "state" })
{% endhighlight %}

Using the ReactiveMongo API, it can be done with the corresponding [collection operation](../../api/index.html#reactivemongo.api.collections.GenericCollection@distinct[T]%28key:String,selector:Option[GenericCollection.this.pack.Document],readConcern:reactivemongo.api.ReadConcern%29%28implicitreader:GenericCollection.this.pack.NarrowValueReader[T],implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[scala.collection.immutable.ListSet[T]]).

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

def distinctStates(col: BSONCollection)(implicit ec: ExecutionContext): Future[Set[String]] = col.distinct[String, Set]("state")
{% endhighlight %}

**States with population above 10000000**

It's possible to determine the states for which the <span id="sum">sum</span> of the population of the cities is above 10000000, by <span id="group">[grouping the documents](http://docs.mongodb.org/manual/reference/operator/aggregation/group/#pipe._S_group)</span> by their state, then for each [group calculating the sum](http://docs.mongodb.org/manual/reference/operator/aggregation/sum/#grp._S_sum) of the population values, and finally get only the grouped documents whose population sum [matches the filter](http://docs.mongodb.org/manual/reference/operator/aggregation/match/#pipe._S_match) "above 10000000".

In the MongoDB shell, such aggregation is written as bellow (see the [example](http://docs.mongodb.org/manual/tutorial/aggregation-zip-code-data-set/#return-states-with-populations-above-10-million)).

{% highlight javascript %}
db.zipcodes.aggregate([
   { $group: { _id: "$state", totalPop: { $sum: "$pop" } } },
   { $match: { totalPop: { $gte: 10000000 } } }
])
{% endhighlight %}

With ReactiveMongo, it can be done as using the [`.aggregate` operation](../../api/index.html#reactivemongo.api.collections.GenericCollection@aggregate%28firstOperator:GenericCollection.this.PipelineOperator,otherOperators:List[GenericCollection.this.PipelineOperator],explain:Boolean,allowDiskUse:Boolean,cursor:Option[GenericCollection.this.BatchCommands.AggregationFramework.Cursor]%29%28implicitec:scala.concurrent.ExecutionContext%29:scala.concurrent.Future[GenericCollection.this.BatchCommands.AggregationFramework.AggregationResult]).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.{ BSONDocument, BSONString }
import reactivemongo.api.collections.bson.BSONCollection

def populatedStates(col: BSONCollection): Future[List[BSONDocument]] = {
  import col.BatchCommands.AggregationFramework.{
    AggregationResult, Group, Match, SumField
  }

  val res: Future[AggregationResult] = col.aggregate(
    Group(BSONString("$state"))( "totalPop" -> SumField("population")),
    List(Match(BSONDocument("totalPop" -> BSONDocument("$gte" -> 10000000L)))))

  res.map(_.documents)
}
{% endhighlight %}

> The local `import col.BatchCommands.AggregationFramework._` is required, and cannot be replaced by a global static `import reactivemongo.api.collections.BSONCollection.BatchCommands.AggregationFramework._`.
> The type `.BatchCommands.AggregationFramework.AggregationResult` is a [dependent one](https://en.wikipedia.org/wiki/Dependent_type), used for the intermediary/MongoDB result, and must not be exposed as public return type in your application/API.

Then when calling `populatedStates(theZipCodeCol)`, the asynchronous result will be as bellow.

{% highlight javascript %}
[
  { "_id" -> "JP", "totalPop" -> 13185702 },
  { "_id" -> "NY", "totalPop" -> 19746227 }
]
{% endhighlight %}

> Note that for the state "JP", the population of Aogashima (200) and of Tokyo (13185502) have been summed.

As for the other commands in ReactiveMongo, it's possible to return the aggregation result as custom types (see [BSON readers](../bson/typeclasses.html)), rather than generic documents, for example considering a class `State` as bellow.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.Macros
import reactivemongo.api.collections.bson.BSONCollection

case class State(name: String, population: Long)

implicit val reader = Macros.reader[State]

def aggregate(col: BSONCollection): Future[col.BatchCommands.AggregationFramework.AggregationResult] = ???

def states(col: BSONCollection): Future[List[State]] =
  aggregate(col).map(_.result[State])
{% endhighlight %}

*Using cursor:*

The alternative [`aggregate1`](../api/index.html#reactivemongo.api.collections.GenericCollection@aggregate1[T]%28firstOperator:GenericCollection.this.PipelineOperator,otherOperators:List[GenericCollection.this.PipelineOperator],cursor:GenericCollection.this.BatchCommands.AggregationFramework.Cursor,explain:Boolean,allowDiskUse:Boolean,bypassDocumentValidation:Boolean,readConcern:Option[reactivemongo.api.ReadConcern],readPreference:reactivemongo.api.ReadPreference%29%28implicitec:scala.concurrent.ExecutionContext,implicitr:GenericCollection.this.pack.Reader[T]%29:scala.concurrent.Future[reactivemongo.api.Cursor[T]]) operation can be used, to process the aggregation result with a [`Cursor`](../api/index.html#reactivemongo.api.Cursor).

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson._
import reactivemongo.api.Cursor
import reactivemongo.api.collections.bson.BSONCollection

def populatedStatesCursor(cities: BSONCollection)(implicit ec: ExecutionContext): Future[Cursor[BSONDocument]] = {
  import cities.BatchCommands.AggregationFramework
  import AggregationFramework.{ Cursor => AggCursor, Group, Match, SumField }

  val cursor = AggCursor(batchSize = 1) // initial batch size

  cities.aggregate1[BSONDocument](Group(BSONString("$state"))(
    "totalPop" -> SumField("population")), List(
    Match(document("totalPop" -> document("$gte" -> 10000000L)))),
    cursor)
}
{% endhighlight %}

**Most populated city per stage**

The <span id="max">[`$max`](https://docs.mongodb.com/manual/reference/operator/aggregation/max/#grp._S_max)</span> can be used to get the most populated site per state.

In the MongoDB shell, it would be executed as following.

{% highlight javascript %}
db.zipcodes.aggregate([
   { $group: { _id: "$state", maxPop: { $max: "$population" } } }
])
{% endhighlight %}

It will return a result as bellow.

{% highlight javascript %}
[
  { _id: "JP", maxPop: 13185502 },
  { _id: "FR", maxPop: 148169 }
  { _id: "NY", maxPop: 19746227 }
]
{% endhighlight %}

Using ReactiveMongo:

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson._
import reactivemongo.api.collections.bson.BSONCollection

def mostPopulated(cities: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import cities.BatchCommands.AggregationFramework
  import AggregationFramework.{ Group, MaxField }

  cities.aggregate(Group(BSONString("$state"))(
    "maxPop" -> MaxField("population")
  )).map(_.firstBatch)
}
{% endhighlight %}

Similarly, the <span id="min">[`$min`](https://docs.mongodb.com/manual/reference/operator/aggregation/min/#grp._S_min)</span> accumulator can be used to get the least populated cities.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson._
import reactivemongo.api.collections.bson.BSONCollection

def leastPopulated(cities: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import cities.BatchCommands.AggregationFramework
  import AggregationFramework.{ Group, MinField }

  cities.aggregate(Group(BSONString("$state"))(
    "minPop" -> MinField("population")
  )).map(_.firstBatch)
}
{% endhighlight %}

**Gather the city names per state as a simple array**

The <span id="push">[`$push`](https://docs.mongodb.com/manual/reference/operator/aggregation/push/#grp._S_push)</span> accumulator can be used to gather some fields, so there is a computed array for each group.

In the MongoDB shell, it can be done as bellow.

{% highlight javascript %}
db.zipcodes.aggregate([
  { $group: { _id: "$state", cities: { $push: "$city" } } }
])
{% endhighlight %}

It will return the aggregation results:

{% highlight javascript %}
[
  { _id: "JP", cities: [ "TOKYO", "AOGASHIMA" ] },
  { _id: "FR", cities: [ "LE MANS" ] },
  { _id: "NY", cities: [ "NEW YORK" ] }
}
{% endhighlight %}

{% highlight javascript %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson._
import reactivemongo.api.collections.bson.BSONCollection

def citiesPerState1(cities: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import cities.BatchCommands.AggregationFramework.{ Group, PushField }

  cities.aggregate(Group(BSONString("$state"))(
    "cities" -> PushField("city"))).map(_.firstBatch)
}
{% endhighlight %}

Similarily the <span id="addToSet">[`$addToSet` accumulator](https://docs.mongodb.com/manual/reference/operator/aggregation/addToSet/#grp._S_addToSet)</span> can be applied to collect all the unique values in the array for each group (there it's equivalent to `$push`).

{% highlight javascript %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson._
import reactivemongo.api.collections.bson.BSONCollection

def citiesPerState1(cities: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import cities.BatchCommands.AggregationFramework.{ Group, AddFieldToSet }

  cities.aggregate(Group(BSONString("$state"))(
    "cities" -> AddFieldToSet("city"))).map(_.firstBatch)
}
{% endhighlight %}

**Average city population by state**

The accumulator <span id="avg">`$avg`</span> can be used to find [the average population of the cities by state](http://docs.mongodb.org/manual/tutorial/aggregation-zip-code-data-set/#return-average-city-population-by-state).

In the MongoDB shell, it can be done as following.

{% highlight javascript %}
db.zipcodes.aggregate([
   { $group: { _id: { state: "$state", city: "$city" }, pop: { $sum: "$pop" } } },
   { $group: { _id: "$_id.state", avgCityPop: { $avg: "$pop" } } }
])
{% endhighlight %}

1. Group the documents by the combination of city and state, to get intermediate documents of the form `{ "_id" : { "state" : "NY", "city" : "NEW YORK" }, "pop" : 19746227 }`.
2. Group the intermediate documents by the `_id.state` field (i.e. the state field inside the `_id` document), and get the average of population of each group (`$avg: "$pop"`).

Using ReactiveMongo, it can be written as bellow.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.{ BSONDocument, BSONString }
import reactivemongo.api.collections.bson.BSONCollection

def avgPopByState(col: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import col.BatchCommands.AggregationFramework.{
    AggregationResult, AvgField, Group, SumField
  }

  col.aggregate(Group(BSONDocument("state" -> "$state", "city" -> "$city"))(
    "pop" -> SumField("population")),
    List(Group(BSONString("$_id.state"))("avgCityPop" -> AvgField("pop")))).
    map(_.documents)
}
{% endhighlight %}

**Largest and smallest cities by state**

Aggregating the documents can be used to find the <span id="first"><span id="last">[largest and the smallest cities for each state](http://docs.mongodb.org/manual/tutorial/aggregation-zip-code-data-set/#return-largest-and-smallest-cities-by-state)</span></span>:

{% highlight javascript %}
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
{% endhighlight %}

A ReactiveMongo function can be written as bellow.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.{ BSONDocument, BSONString, Macros }
import reactivemongo.api.collections.bson.BSONCollection

case class City(name: String, population: Long)
case class StateStats(state: String, biggestCity: City, smallestCity: City)

implicit val cityReader = Macros.reader[City]
implicit val statsReader = Macros.reader[StateStats]

def stateStats(col: BSONCollection): Future[List[StateStats]] = {
  import col.BatchCommands.AggregationFramework.{
    AggregationResult, Ascending, FirstField, Group, LastField,
    Project, Sort, SumField
  }

  col.aggregate(Group(BSONDocument("state" -> "$state", "city" -> "$city"))(
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
  map(_.result[StateStats])
}
{% endhighlight %}

This function would return statistics like the following.

{% highlight scala %}
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
{% endhighlight %}

**Standard deviation of the japanese cities**

The group accumulators <span id="stdDevPop">[`$stdDevPop`](https://docs.mongodb.com/manual/reference/operator/aggregation/stdDevPop/#grp._S_stdDevPop)</span> and <span id="stdDevSamp">[`$stdDevSamp`](https://docs.mongodb.com/manual/reference/operator/aggregation/stdDevSamp/#grp._S_stdDevSamp)</span> can be used to find the standard deviation of the japanese cities.

In the MongoDB, it can be done as following.

{% highlight javascript %}
db.zipcodes.aggregate([
   { $group:
      {
        _id: "$state",
        popDev: { $stdDevPop: "$population" }
      }
   },
   { $match: { _id: "JP" } }
])
{% endhighlight %}

It will find the result:

{% highlight javascript %}
{ _id: "JP", popDev: 6592651 }
{% endhighlight %}

It can be done with ReactiveMongo as bellow.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson._
import reactivemongo.api.collections.bson.BSONCollection

def populationStdDeviation(cities: BSONCollection)(implicit ec: ExecutionContext): Future[Option[BSONDocument]] = {
  import cities.BatchCommands.AggregationFramework
  import AggregationFramework.{ StdDevPopField, Group, Match }

  cities.aggregate(Group(BSONString("$state"))(
    "popDev" -> StdDevPopField("population")),
    List(Match(document("_id" -> "JP")))).map(_.firstBatch.headOption)
}

def populationSampleDeviation(cities: BSONCollection)(implicit ec: ExecutionContext): Future[Option[BSONDocument]] = {
  import cities.BatchCommands.AggregationFramework
  import AggregationFramework.{ StdDevSampField, Group, Match }

  cities.aggregate(Group(BSONString("$state"))(
    "popDev" -> StdDevSampField("population")),
    List(Match(document("_id" -> "JP")))).map(_.firstBatch.headOption)
}
{% endhighlight %}

**Find documents using text indexing**

Consider the following [text indexes](https://docs.mongodb.org/manual/core/index-text/) is maintained for the fields `city` and `state` of the `zipcodes` collection.

{% highlight javascript %}
db.zipcodes.ensureIndex({ city: "text", state: "text" })
{% endhighlight %}

Then it's possible to find documents using the [`$text` operator](https://docs.mongodb.org/v3.0/reference/operator/query/text/#op._S_text), and also the results can be [sorted](https://docs.mongodb.org/v3.0/reference/operator/aggregation/sort/#metadata-sort) according the [text scores](https://docs.mongodb.org/v3.0/reference/operator/query/text/#text-operator-text-score).

For example to find the documents matching the text `"JP"`, and sort according the text score, the following query can be executed in the MongoDB shell.

{% highlight javascript %}
db.users.aggregate([
   { $match: { $text: { $search: "JP" } } },
   { $sort: { score: { $meta: "textScore" } } }
])
{% endhighlight %}

A ReactiveMongo function can be written as bellow.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

def textFind(coll: BSONCollection): Future[List[BSONDocument]] = {
  import coll.BatchCommands.AggregationFramework
  import AggregationFramework.{
    Cursor,
    Match,
    MetadataSort,
    Sort,
    TextScore
  }

  val firstOp = Match(BSONDocument(
    "$text" -> BSONDocument("$search" -> "JP")))

  val pipeline = List(Sort(MetadataSort("score", TextScore)))

  coll.aggregate1[BSONDocument](
    firstOp, pipeline, Cursor(1)).flatMap(_.collect[List]())
}
{% endhighlight %}

This will return the sorted documents for the cities `TOKYO` and `AOGASHIMA`.

**Random sample**

The [$sample](https://docs.mongodb.org/manual/reference/operator/aggregation/sample/) aggregation stage can be used (since MongoDB 3.2), in order to randomly selects documents.

In the MongoDB shell, it can be used as following to fetch a sample of 3 random documents.

{% highlight javascript %}
db.zipcodes.aggregate([
  { $sample: { size: 3 } }
])
{% endhighlight %}

With ReactiveMongo, the [Sample](../api/index.html#reactivemongo.api.commands.AggregationFramework@SampleextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable) stage can be used as follows.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }
import reactivemongo.bson.BSONDocument
import reactivemongo.api.collections.bson.BSONCollection

def randomZipCodes(coll: BSONCollection)(implicit ec: ExecutionContext): Future[List[BSONDocument]] = {
  import coll.BatchCommands.AggregationFramework

  coll.aggregate(AggregationFramework.Sample(3)).map(_.head[BSONDocument])
}
{% endhighlight %}

### Places examples

Let consider a collection of different kind of places (e.g. Central Park ...), with their locations indexed using [`2dsphere`](https://docs.mongodb.com/manual/core/2dsphere/#create-a-2dsphere-index).

This can be setup with the MongoDB shell as follows.

{% highlight javascript %}
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
{% endhighlight %}

The [`$geoNear`](https://docs.mongodb.com/manual/reference/operator/aggregation/geoNear/) aggregation can be used on the collection, to find the place near the  geospatial coordinates `[ -73.9667, 40.78 ]`, within 1km (1000 meters) and 5km (5000 meters)

{% highlight javascript %}
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
{% endhighlight %}

The results will be of the following form:

{% highlight javascript %}
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
{% endhighlight %}

It can be done with ReactiveMongo as follows.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson.{ array, document, Macros }
import reactivemongo.api.collections.bson.BSONCollection

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
  import places.BatchCommands.AggregationFramework.GeoNear

  places.aggregate(GeoNear(document(
    "type" -> "Point",
    "coordinates" -> array(-73.9667, 40.78)
  ), distanceField = Some("dist.calculated"),
    minDistance = Some(1000),
    maxDistance = Some(5000),
    query = Some(document("type" -> "public")),
    includeLocs = Some("dist.loc"),
    limit = 5,
    spherical = true)).map(_.head[GeoPlace])
}
{% endhighlight %}

### Forecast example

Consider a collection of forecasts with the following document.

{% highlight javascript %}
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
{% endhighlight %}

Using the [`$redact` stage](https://docs.mongodb.com/manual/reference/operator/aggregation/redact/), the MongoDB aggregation can be used to restricts the contents of the documents. It can be done in the MongoDB shell as follows:

{% highlight javascript %}
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
{% endhighlight %}

The corresponding results a redacted document.

{% highlight javascript %}
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
{% endhighlight %}

With ReactiveMongo, the aggregation framework can perform a similar redaction.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.bson._
import reactivemongo.api.collections.bson.BSONCollection

def redactForecasts(forecasts: BSONCollection)(implicit ec: ExecutionContext) = {
  import forecasts.BatchCommands.AggregationFramework.{ Match, Redact }

  forecasts.aggregate(Match(document("year" -> 2014)), List(
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
    ))))).map(_.head[BSONDocument])
}
{% endhighlight %}

**See also:**

- The operators available to define an aggregation pipeline are documented in the [API reference](../../api/index.html#reactivemongo.api.commands.AggregationFramework).
- The [Aggregation Framework tests](https://github.com/ReactiveMongo/ReactiveMongo/blob/master/driver/src/test/scala/AggregationSpec.scala)