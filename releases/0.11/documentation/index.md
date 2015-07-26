---
layout: default
title: ReactiveMongo 0.11 - Documentation
---

## ReactiveMongo {{site._0_11_latest_minor}}

* You can read the [release notes](release-details.html) to know what is included in this release.
* The [Scaladoc for the API](../api/index.html) can be browsed [here](../api/index.html).

The dependency can be added in your SBT project as following: `"org.reactivemongo" %% "reactivemongo" % "{{site._0_11_latest_minor}}"`

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.11/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.11/)

The documentation of the plugin for the **Play Framework** can is [available online](tutorial/play2.html).

### Tutorial

1. [Add ReactiveMongo to your project](tutorial/setup.html)
2. [Connect to the database](tutorial/connect-database.html)
3. [Open database and collections](tutorial/database-and-collection.html)
4. [Write documents (`insert`, `update`, `remove`)](tutorial/write-documents.html)
5. [Find documents](tutorial/find-documents.html)
6. [BSON readers & writers](bson/typeclasses.html)
7. [Consume streams of documents](tutorial/consume-streams.html)

### BSON Manipulation

1. [Overview of the ReactiveMongo BSON library](bson/overview.html)
2. [Using the ReactiveMongo BSON library](bson/usage.html)
3. [Concrete Example: Maps De/Serialization](bson/example-maps.html)
4. [Concrete Example: BigDecimal and BigInteger De/Serialization](bson/example-bigdecimal.html)

### Advanced Topics

- [The Collection API](advanced-topics/collection-api.html)
- [The Command API](advanced-topics/commands.html)
- [The Aggregation Framework](advanced-topics/aggregation.html)
- [FailoverStrategy](advanced-topics/failoverstrategy.html)
- [ReadPreferences](advanced-topics/read-preferences.html)
- [GridFS](advanced-topics/gridfs.html)

### Contribute

ReactiveMongo is getting better with every release thanks to its [contributors](https://github.com/ReactiveMongo/ReactiveMongo/graphs/contributors). Feel free to browse [the GitHub repository](https://github.com/ReactiveMongo), to report any bug, feature request or make pull requests!

The project guidelines are available [online](https://github.com/ReactiveMongo/ReactiveMongo/blob/master/CONTRIBUTING.md#reactivemongo-developer--contributor-guidelines).

You can also help improve this documentation by making pull request on this website [GitHub repository](https://github.com/ReactiveMongo/reactivemongo-site).
