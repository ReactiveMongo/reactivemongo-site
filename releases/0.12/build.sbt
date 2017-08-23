organization := "org.reactivemongo"

name := "release_0_12"

val majorVer = "0.12"

version := majorVer

val Release = s"${majorVer}.6"

scalaVersion := "2.11.11"

libraryDependencies ++= Seq(
  "reactivemongo-iteratees", "reactivemongo-akkastream").map(
  "org.reactivemongo" %% _ % Release changing())

libraryDependencies ++= Seq(
  "play2-reactivemongo", "reactivemongo-play-json").map(
  "org.reactivemongo" %% _ % s"${Release}-play25" changing())

libraryDependencies += "com.typesafe.play" %% "play" % "2.5.12"

resolvers ++= Seq(
  "Typesafe releases" at "http://repo.typesafe.com/typesafe/releases/",
  "Sonatype Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots/")
