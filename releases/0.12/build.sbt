organization := "org.reactivemongo"

name := "release_0_12"

version := "0.12"

scalaVersion := "2.11.7"

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "play2-reactivemongo" % "0.12.0-SNAPSHOT",
  "org.reactivemongo" %% "reactivemongo-play-json" % "0.12.0-SNAPSHOT",
  "com.typesafe.play" %% "play" % "2.4.6",
  "io.netty" % "netty" % "3.10.4.Final" % "provided")

resolvers ++= Seq(
  "Typesafe releases" at "http://repo.typesafe.com/typesafe/releases/")
