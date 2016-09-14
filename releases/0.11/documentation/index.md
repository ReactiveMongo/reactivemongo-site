---
layout: default
major_version: 0.11
title: Documentation
---

## ReactiveMongo {{site._0_11_latest_minor}}

* You can read the [release notes](release-details.html) to know what is included in this release.
* The Scaladoc for the Driver API can be browsed [here](../api/index.html).

The dependency can be added in your SBT project as following: `"org.reactivemongo" %% "reactivemongo" % "{{site._0_11_latest_minor}}"`

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.11/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.11/)

> MongoDB versions older than 2.6 are not longer supported by ReactiveMongo, as the End of Life for MongoDB 2.4 was reached in [April 2015](https://www.mongodb.com/support-policy).

**Play Framework**

The documentation of the module for the Play Framework can is [available online](tutorial/play2.html).

The API for this module can be [browsed online](../play-api/index.html).

The API for the standalone JSON serialization is [also available](../json-api/index.html).

### Tutorials

- [Add ReactiveMongo to your project](tutorial/setup.html)
- [Get started](tutorial/getstarted.html)
   1. [Connect to the database](tutorial/connect-database.html)
   2. [Open database and collections](tutorial/database-and-collection.html)
   3. [Write documents (`insert`, `update`, `remove`)](tutorial/write-documents.html)
   4. [Find documents](tutorial/find-documents.html)
   5. [Streaming](tutorial/consume-streams.html)

### BSON Manipulation

1. [Overview of the ReactiveMongo BSON library](bson/overview.html)
2. [Readers & writers](bson/typeclasses.html)
   - [Concrete Example: Maps De/Serialization](bson/example-maps.html)
   - [Concrete Example: BigDecimal and BigInteger De/Serialization](bson/example-bigdecimal.html)
   - [Concrete example: Documents](bson/example-document.html)

### JSON Manipulation

[Overview of the Play JSON library](json/overview.html)

### Advanced Topics

- [Collection API](advanced-topics/collection-api.html)
- [Command API](advanced-topics/commands.html)
- [Aggregation Framework](advanced-topics/aggregation.html)
- [FailoverStrategy](advanced-topics/failoverstrategy.html)
- [ReadPreferences](advanced-topics/read-preferences.html)
- [GridFS](advanced-topics/gridfs.html)

### Samples

{% include samples.md %}
