---
layout: default
title: ReactiveMongo 0.11 - Setup
---

## Setup your project

We assume that you got a running MongoDB instance. If not, get [the latest MongoDB binaries](http://www.mongodb.org/downloads) and unzip the archive. Then you can launch the database:

{% highlight sh %}
$ mkdir /path/to/data
$ /path/to/bin/mongod --dbpath /path/to/data
{% endhighlight %}

This will start a standalone MongoDB instance that stores its data in the ```data``` directory and listens on the TCP port 27017.

### Set up your project dependencies (SBT)

ReactiveMongo is available on [Maven Central](http://search.maven.org/#browse%7C1306790).

If you use SBT, you just have to edit `build.sbt` and add the following:

{% highlight scala %}
// you may also want to add the typesafe repository
resolvers += "Typesafe repository releases" at "http://repo.typesafe.com/typesafe/releases/"

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "{{site._0_11_latest_minor}}"
)
{% endhighlight %}

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.11/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.11/)

Or if you want to be on the bleeding edge using snapshots:

{% highlight scala %}
resolvers += "Sonatype Snapshots" at "http://oss.sonatype.org/content/repositories/snapshots/"

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "0.12.0-SNAPSHOT"
)
{% endhighlight %}
