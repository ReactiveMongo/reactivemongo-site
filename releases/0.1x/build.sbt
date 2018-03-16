organization := "org.reactivemongo"

name := "release_0_1x"

val majorVer = "0"

version := majorVer

val Release = s"${majorVer}.13.0"

scalaVersion := "2.12.4"

libraryDependencies ++= Seq(
  "reactivemongo-iteratees", "reactivemongo-akkastream").map(
  "org.reactivemongo" %% _ % Release changing())

libraryDependencies ++= Seq(
  "play2-reactivemongo", "reactivemongo-play-json").map(
  "org.reactivemongo" %% _ % s"${Release}-play26" changing())

libraryDependencies += "com.typesafe.play" %% "play" % "2.6.7"

resolvers ++= Seq(
  "Typesafe releases" at "http://repo.typesafe.com/typesafe/releases/",
  "Sonatype Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots/")
