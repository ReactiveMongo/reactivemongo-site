---
layout: default
major_version: 0.12
title: Documentation
---

## ReactiveMongo {{site._0_12_latest_minor}}

You can read the [release notes](release-details.html) to know what is new with this release.

The core dependency can be added in your SBT project as following.

{% highlight ocaml %}
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "{{site._0_12_latest_minor}}"
{% endhighlight %}

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.12/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.12/)
[![Test coverage](https://img.shields.io/badge/coverage-60%25-yellowgreen.svg)](reactivemongo.github.io/ReactiveMongo/coverage/0.12.0/)

> MongoDB versions older than 2.6 are not longer supported by ReactiveMongo, as the End of Life for MongoDB 2.4 was reached in [April 2015](https://www.mongodb.com/support-policy).

**API documentations:**

The various API of the ReactiveMongo driver itself, and also of the related libraries, are available as online.

- [Driver API](../api/index.html): Core driver, BSON
- [Play JSON API](http://reactivemongo.github.io/ReactiveMongo-Play-Json/{{page.major_version}}/api/)
- [Play module API](http://reactivemongo.github.io/Play-ReactiveMongo/{{page.major_version}}/api/)
- ReactiveMongo [AkkaStream](https://reactivemongo.github.io/ReactiveMongo-Streaming/{{page.major_version}}/akka-stream/api/)
- ReactiveMongo [Iteratees](https://reactivemongo.github.io/ReactiveMongo-Streaming/{{page.major_version}}/iteratees/api/)

**Recommanded configuration:**

The driver core and the modules are tested in [container based environment](https://docs.travis-ci.com/user/ci-environment/#Virtualization-environments), with the specs as bellow.

- 2 [cores](https://cloud.google.com/compute/) (64bits)
- 4 GB of system memory, with a maximum of 2 GB for the JVM

This can be considered as a recommanded environment.

### Tutorials

- [Setup ReactiveMongo in your project](tutorial/setup.html)
    - [Configure the logging](tutorial/setup.html#logging)
- [Get started](tutorial/getstarted.html)
   1. [Connect to the database](tutorial/connect-database.html)
   2. [Open database and collections](tutorial/database-and-collection.html)
   3. [Write documents (`insert`, `update`, `remove`)](tutorial/write-documents.html)
   4. [Find documents](tutorial/find-documents.html)
   5. [Streaming](tutorial/streaming.html)

### BSON Manipulation

1. [Overview of the ReactiveMongo BSON library](bson/overview.html)
2. [Readers & writers](bson/typeclasses.html)
    - [Concrete Example: Maps De/Serialization](bson/example-maps.html)
    - [Concrete Example: BigDecimal and BigInteger De/Serialization](bson/example-bigdecimal.html)
    - [Concrete example: Documents](bson/example-document.html)

### Play Framework

- [Overview of the Play JSON library](json/overview.html): the standalone library to support JSON serialization.
- [Integration with Play Framework](tutorial/play.html): the complete Play plugin (also using the previous JSON library).

### Advanced Topics

- [Collection API](advanced-topics/collection-api.html)
- [Command API](advanced-topics/commands.html)
- [Aggregation Framework](advanced-topics/aggregation.html)
- [FailoverStrategy](advanced-topics/failoverstrategy.html)
- [ReadPreferences](advanced-topics/read-preferences.html)
- [GridFS](advanced-topics/gridfs.html)
- [Monitoring](advanced-topics/monitoring.html)

### Samples

{% include samples.md %}
