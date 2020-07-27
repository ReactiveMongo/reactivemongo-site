---
layout: default
major_version: 1.0
title: Documentation
---

## ReactiveMongo {{site._1_0_latest_major}}

{% if site._1_0_latest_minor contains "-rc." %}
<strong style="color:red">This is a Release Candidate</strong>
{% endif %}

You can read the [release notes](release-details.html) to know what is new with this major release.

The latest minor release is {{site._1_0_latest_minor}}, and the core dependency can be added in your SBT project as following.

```ocaml
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "{{site._1_0_latest_minor}}")
```

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/)
[![Test coverage](https://img.shields.io/badge/coverage-60%25-yellowgreen.svg)](http://reactivemongo.github.io/ReactiveMongo/coverage/{{site._1_0_latest_minor}}/)

> MongoDB versions older than 2.6 are no longer supported by ReactiveMongo, as the End of Life for MongoDB 2.4 was reached in [April 2015](https://www.mongodb.com/support-policy).

**API documentations:**

The various API of the ReactiveMongo driver itself, and also of the related libraries, are available online.

- [Driver API](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/): Core driver, BSON
- [Play JSON API](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo-play-json_{{site._1_0_scala_major}}-{{site._1_0_latest_minor}}-javadoc.jar/!/index.html)
- [Play module API](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/play2-reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/play2-reactivemongo_{{site._1_0_scala_major}}-{{site._1_0_latest_minor}}-javadoc.jar/!/index.html)
- ReactiveMongo [AkkaStream](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-akkastream_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo-akkastream_{{site._1_0_scala_major}}-{{site._1_0_latest_minor}}-javadoc.jar/!/index.html)

**Recommended configuration:**

The driver core and the modules are tested in a [container based environment](https://docs.travis-ci.com/user/ci-environment/#Virtualization-environments), with the specifications as bellow.

- 2 [cores](https://cloud.google.com/compute/) (64 bits)
- 4 GB of system memory, with a maximum of 2 GB for the JVM

This can be considered as a recommended environment.

### Tutorials

- [Setup ReactiveMongo in your project](tutorial/setup.html)
    - [Configure the logging](tutorial/setup.html#logging)
- [Get started](tutorial/getstarted.html)
   1. [Connect to the database](tutorial/connect-database.html)
   2. [Open database and collections](tutorial/database-and-collection.html)
   3. [Write documents](tutorial/write-documents.html) (`insert`, `update`, `remove`)
   4. [Find documents](tutorial/find-documents.html)
   5. [Streaming](tutorial/streaming.html)

#### BSON Manipulation

1. [Overview of the ReactiveMongo BSON library](bson/overview.html)
2. [Readers & writers](bson/typeclasses.html)
    - [Concrete Example: BigDecimal and BigInteger De/Serialization](bson/example-bigdecimal.html)
    - [Concrete example: Documents](bson/example-document.html)

#### Play Framework

- [Overview of the Play JSON library](json/overview.html): the standalone library to support JSON serialization.
- [Integration with Play Framework](tutorial/play.html): the complete Play plugin (also using the previous JSON library).

#### Advanced Topics

- [Aggregation Framework](advanced-topics/aggregation.html)
- [FailoverStrategy](advanced-topics/failoverstrategy.html)
- [ReadPreference](advanced-topics/read-preferences.html)
- [Command API](advanced-topics/commands.html)
- [Collection API](advanced-topics/collection-api.html)
- [GridFS](advanced-topics/gridfs.html)
- [Monitoring](advanced-topics/monitoring.html)

#### Cloud

- [Alibaba Apsara](./tutorial/alibaba-apsaradb.html)
- [Amazon DocumentDB](./tutorial/amazon-documentdb.html)
- [Azure CosmosDB](./tutorial/azure-cosmos.html)
- [MongoDB Atlas](./tutorial/mongodb-atlas.html)

### Samples

{% include samples.md %}
