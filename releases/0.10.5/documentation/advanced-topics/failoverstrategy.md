---
layout: default
title: ReactiveMongo 0.10.5 - FailoverStrategy
---

## Failover Strategy

A `FailoverStrategy` defines if and how many times should ReactiveMongo retry a database operation (query, insertion, command, etc.) that failed for the following reasons:

- the entire node set is not available (probably because of a network failure)
- the primary is not available, preventing to run write operations and consistent reads
- the operation could not be done because of a credentials problem (ie the application is not yet logged on to the database)

The other causes (business errors, normal database errors, fatal errors, etc.) are not handled.

`FailoverStartegy` is a case class defined as follows:

{% highlight scala %}
/**
 * A failover strategy for sending requests.
 *
 * @param initialDelay the initial delay between the first failed attempt and the next one.
 * @param retries the number of retries to do before giving up.
 * @param delayFactor a function that takes the current iteration and returns a factor to be applied to the initialDelay.
 */
case class FailoverStrategy(
  initialDelay: FiniteDuration = 500 milliseconds,
  retries: Int = 5,
  delayFactor: Int => Double = n => 1)
{% endhighlight %}

The default `FailoverStrategy` retries 5 times, with 500 ms between each attempt. Let's say that we want to define a `FailoverStrategy` that waits more time before a new attempt:

{% highlight scala %}
val strategy =
  FailoverStrategy(
    initialDelay = 500 milliseconds,
    retries = 5,
    delayFactor =
      attemptNumber => 1 + attemptNumber * 0.5
  )
{% endhighlight %}

This strategy retries at most 5 times, waiting for `initialDelay * ( 1 + attemptNumber * 0.5 )` between each attempt (attemptNumber starting from 1). Here is the way the attemps will be run:

- __#1__: 750 milliseconds (`500 * (1 + 1 * 0.5)) = 500 * 1.5 = 750`)
- __#2__: 1000 milliseconds (`500 * (1 + 2 * 0.5)) = 500 * 2 = 1000`)
- __#3__: 1250 milliseconds (`500 * (1 + 3 * 0.5)) = 500 * 2.5 = 1250`)
- __#4__: 1500 milliseconds (`500 * (1 + 4 * 0.5)) = 500 * 3 = 1500`)
- __#5__: 1750 milliseconds (`500 * (1 + 5 * 0.5)) = 500 * 3.5 = 1750`)

You can specify a strategy by giving it as a parameter to `connection.db` or `db.collection`:

{% highlight scala %}
val defaultStrategy = FailoverStrategy()

val customStrategy =
  FailoverStrategy(
    initialDelay = 500 milliseconds,
    retries = 5,
    delayFactor =
      attemptNumber => 1 + attemptNumber * 0.5
  )

// database-wide strategy
val db = connection.db("dbname", customStrategy)

// collection-wide strategy
val db = connection.db("dbname", defaultStrategy)
val collection = db.collection("collname", customStrategy)
{% endhighlight %}
