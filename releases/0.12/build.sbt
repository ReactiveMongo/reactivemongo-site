organization := "org.reactivemongo"

name := "release_0_12"

version := "0.12"

val Release = "0.12-RC0"

scalaVersion := "2.11.7"

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "play2-reactivemongo" % Release,
  "org.reactivemongo" %% "reactivemongo-play-json" % Release,
  "org.reactivemongo" %% "reactivemongo-iteratees" % Release,
  "org.reactivemongo" %% "reactivemongo-akkastream" % Release,
  "com.typesafe.play" %% "play" % "2.5.4")

resolvers ++= Seq(
  "Typesafe releases" at "http://repo.typesafe.com/typesafe/releases/",
  "Sonatype Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots/")
