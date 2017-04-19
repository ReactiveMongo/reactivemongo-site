organization := "org.reactivemongo"

name := "release_0_12"

val majorVer = "0.12"

version := majorVer

val Release = s"${majorVer}.2"

scalaVersion := "2.11.8"

libraryDependencies ++= Seq(
  "play2-reactivemongo", "reactivemongo-play-json",
  "reactivemongo-iteratees", "reactivemongo-akkastream").map(
  "org.reactivemongo" %% _ % Release changing())

libraryDependencies += "com.typesafe.play" %% "play" % "2.5.9"

resolvers ++= Seq(
  "Typesafe releases" at "http://repo.typesafe.com/typesafe/releases/",
  "Sonatype Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots/")
