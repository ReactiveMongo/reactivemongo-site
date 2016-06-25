---
layout: default
title: ReactiveMongo 0.12 - Setup
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

{% highlight ocaml %}
// you may also want to add the typesafe repository
resolvers += "Typesafe repository releases" at "http://repo.typesafe.com/typesafe/releases/"

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "{{site._0_12_latest_minor}}"
)
{% endhighlight %}

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.12/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.12/)

Or if you want to be on the bleeding edge using snapshots:

{% highlight ocaml %}
resolvers += "Sonatype Snapshots" at "http://oss.sonatype.org/content/repositories/snapshots/"

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "0.13.0-SNAPSHOT"
)
{% endhighlight %}

### Logging

SLF4J is now used by the ReactiveMongo logging, so a [SLF4J binding](http://www.slf4j.org/manual.html#swapping) must be provided (e.g. slf4j-simple).

In a Play application, the [Playframework logging](https://www.playframework.com/documentation/latest/ScalaLogging) will be used.

*Example of logging configuration with the [Logback binding](http://logback.qos.ch):*

{% highlight xml %}
<configuration>
  <conversionRule conversionWord="coloredLevel"
    converterClass="play.api.Logger$ColoredLevel" />

  <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
      <pattern>%date %coloredLevel %logger - [%level] %message%n%xException</pattern>
    </encoder>
  </appender>

  <logger name="reactivemongo" level="WARN" />

  <root level="WARN">
    <appender-ref ref="STDOUT" />
  </root>
</configuration>
{% endhighlight %}

As [akka](http://akka.io) is used, so it can be useful to also configure its [logging](http://doc.akka.io/docs/akka/2.4.7/scala/logging.html).

{% highlight ocaml %}
akka {
  loglevel = "WARNING"
}
{% endhighlight %}

**Troubleshooting:**

If the following error is raised, you need to make sure to provide a [SLF4J binding](http://www.slf4j.org/manual.html#swapping) (e.g. [logback-classic](http://logback.qos.ch/)).

    NoClassDefFoundError: : org/slf4j/LoggerFactory

[Log4J](http://logging.apache.org/log4j/2.x/) is still required for backward compatibility (by deprecated code). If you see the following message, please make sure you have a Log4J framework available.

    ERROR StatusLogger No log4j2 configuration file found. Using default configuration: logging only errors to the console.

[Next: Connect to the database](./connect-database.html)