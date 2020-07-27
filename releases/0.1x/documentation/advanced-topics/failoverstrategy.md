---
layout: default
major_version: 0.1x
title: FailoverStrategy
---

## Failover Strategy

A `FailoverStrategy` defines if and how many times ReactiveMongo should retry the operations (DB resolution, query, insertion, command, etc.) that could fail for the following reasons.

- The entire node set is not available (probably because of a network failure).
- The primary is not available, preventing to run write operations and consistent reads.
- The operation could not be done because of a credentials problem (e.g. the application is not yet logged on to the database).

The other causes (business errors, normal database errors, fatal errors, etc.) are not handled.

The default `FailoverStrategy` retries 5 times, with 500 ms between each attempt.

Let's say that we want to define a `FailoverStrategy` that waits more time before a new attempt.

```scala
import scala.concurrent.duration._

import reactivemongo.api.FailoverStrategy

val strategy =
  FailoverStrategy(
    initialDelay = 500 milliseconds,
    retries = 5,
    delayFactor =
      attemptNumber => 1 + attemptNumber * 0.5
  )
```

This strategy retries at most 5 times, waiting for `initialDelay * ( 1 + attemptNumber * 0.5 )` between each attempt (`attemptNumber` starting from 1). Here is the way the attempts will be run:

- __#1__: 750 milliseconds (`500 * (1 + 1 * 0.5)) = 500 * 1.5 = 750`)
- __#2__: 1000 milliseconds (`500 * (1 + 2 * 0.5)) = 500 * 2 = 1000`)
- __#3__: 1250 milliseconds (`500 * (1 + 3 * 0.5)) = 500 * 2.5 = 1250`)
- __#4__: 1500 milliseconds (`500 * (1 + 4 * 0.5)) = 500 * 3 = 1500`)
- __#5__: 1750 milliseconds (`500 * (1 + 5 * 0.5)) = 500 * 3.5 = 1750`)

You can specify a strategy by giving it as a parameter to `connection.database` or `database.collection`:

```scala
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.FailoverStrategy

val defaultStrategy = FailoverStrategy()

val customStrategy =
  FailoverStrategy(
    initialDelay = 500 milliseconds,
    retries = 5,
    delayFactor =
      attemptNumber => 1 + attemptNumber * 0.5
  )

def connection1: reactivemongo.api.MongoConnection = ???

// database-wide strategy
val db1 = connection1.database("dbname", customStrategy)

// collection-wide strategy
val db2 = connection1.database("dbname", defaultStrategy)

val collection = db2.map(_.collection("collname", customStrategy))
```
