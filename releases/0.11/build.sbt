organization := "org.reactivemongo"

name := "release_0_11"

version := "0.11"

scalaVersion := "2.11.7"

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "play2-reactivemongo" % "0.11.7.play24",
  "com.typesafe.play" %% "play" % "2.4.2",
  "io.netty" % "netty" % "3.10.4.Final" % "provided")

resolvers ++= Seq(
  "Typesafe releases" at "http://repo.typesafe.com/typesafe/releases/")
