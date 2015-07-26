---
layout: default
title: ReactiveMongo 0.11 - The Aggregation Framework
---

## The Aggregation Framework

The [MongoDB Aggregation Framework](http://docs.mongodb.org/manual/reference/operator/aggregation/) is available through ReactiveMongo.

### ZipCodes example ###

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

**States with population above 10000000**

It's possible to determine the states for which the sum of the population of the cities is above 10000000, by [grouping the documents](http://docs.mongodb.org/manual/reference/operator/aggregation/group/#pipe._S_group) by their state, then for each [group calculating the sum](http://docs.mongodb.org/manual/reference/operator/aggregation/sum/#grp._S_sum) of the population values, and finally get only the grouped documents whose population sum [matches the filter](http://docs.mongodb.org/manual/reference/operator/aggregation/match/#pipe._S_match) "above 10000000".

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
import reactivemongo.bson.Macros

case class State(name: String, population: Long)

implicit val reader = Macros.reader[State]

// res: Future[AggregationResult]
val states: Future[List[State]] = res.map(_.result[State])
{% endhighlight %}

**Average city population by state**

The Aggregation Framework can be used to find [the average population of the cities by state](http://docs.mongodb.org/manual/tutorial/aggregation-zip-code-data-set/#return-average-city-population-by-state).

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
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.{ BSONDocument, BSONString }
import reactivemongo.api.collections.bson.BSONCollection

def avgPopByState(col: BSONCollection): Future[List[BSONDocument]] = {
  import col.BatchCommands.AggregationFramework.{
    AggregationResult, Avg, Group, Match, SumField
  }

  col.aggregate(Group(BSONDocument("state" -> "$state", "city" -> "$city"))(
    "pop" -> SumField("population")),
    List(Group(BSONString("$_id.state"))("avgCityPop" -> Avg("pop")))).
    map(_.documents)
}
{% endhighlight %}

**Largest and smallest cities by state**

Aggregating the documents can be used to find the [largest and the smallest cities for each state](http://docs.mongodb.org/manual/tutorial/aggregation-zip-code-data-set/#return-largest-and-smallest-cities-by-state):

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
    AggregationResult, Ascending, First, Group, Last, Project, Sort, SumField
  }

  col.aggregate(Group(BSONDocument("state" -> "$state", "city" -> "$city"))(
    "pop" -> SumField("population")),
    List(Sort(Ascending("population")), Group(BSONString("$_id.state"))(
        "biggestCity" -> Last("_id.city"), "biggestPop" -> Last("pop"),
        "smallestCity" -> First("_id.city"), "smallestPop" -> First("pop")),
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

The operators available to define an aggregation pipeline are documented in the [API reference](http://localhost:4000/releases/0.11/api/index.html#reactivemongo.api.commands.AggregationFramework).