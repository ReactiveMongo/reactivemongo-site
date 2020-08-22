---
layout: default
major_version: 0.12
title: Setup
---

## Setup your project

{% include assume-setup.md %}

### Set up your project dependencies

ReactiveMongo is available on [Maven Central](http://search.maven.org/#browse%7C1306790).

{% include sbt-dependency.md %}

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.12/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/reactivemongo_2.12/)

Or if you want to be on the bleeding edge using snapshots:

```ocaml
resolvers += "Sonatype Snapshots" at "http://oss.sonatype.org/content/repositories/snapshots/"

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "1.0.0-SNAPSHOT"
)
```

**Akka dependency:**

ReactiveMongo is internally using [Akka](http://akka.io/), so it declares a transitive dependency to.

If your project already has the Akka dependency, directly or transitively (e.g. by [Play](https://playframework.com/) dependencies), both must be compatible.

ReactiveMongo is tested against Akka from version 2.3.13 up to 2.4.x (2.4.8 for now).

### Logging

SLF4J is now used by the ReactiveMongo logging, so a [SLF4J binding](http://www.slf4j.org/manual.html#swapping) must be provided (e.g. slf4j-simple).

In a Play application, the [Play Framework logging](https://www.playframework.com/documentation/latest/ScalaLogging) will be used.

*Example of logging configuration with the [Logback binding](http://logback.qos.ch):*

```xml
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
```

As [Akka](http://akka.io) is used, so it can be useful to also configure its [logging](http://doc.akka.io/docs/akka/2.4.7/scala/logging.html).

```ocaml
mongo-async-driver {
  akka {
    loggers = ["akka.event.slf4j.Slf4jLogger"]
    loglevel = DEBUG
  }
}
```

**Troubleshooting:**

If the following error is raised, you need to make sure to provide a [SLF4J binding](http://www.slf4j.org/manual.html#swapping) (e.g. [logback-classic](http://logback.qos.ch/)).

    NoClassDefFoundError: : org/slf4j/LoggerFactory

[Log4J](http://logging.apache.org/log4j/2.x/) is still required for backward compatibility (by deprecated code). If you see the following message, please make sure you have a Log4J framework available.

    ERROR StatusLogger No log4j2 configuration file found. Using default configuration: logging only errors to the console.

[Next: Connect to the database](./connect-database.html)
