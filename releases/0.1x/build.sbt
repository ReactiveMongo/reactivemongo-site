organization := "org.reactivemongo"

name := "release_0_1x"

val majorVer = "0"

version := majorVer

val Release = s"${majorVer}.18.6"

scalaVersion := "2.12.10"

libraryDependencies ++= Seq(
  "reactivemongo-iteratees",
  "reactivemongo-akkastream",
  "reactivemongo-bson-api"
).map(
  "org.reactivemongo" %% _ % Release changing())

libraryDependencies ++= {
  val playVer = Release.span(_ != '-') match {
    case (major, "") => s"${major}-play27"
    case (major, mod) => s"${major}-play27${mod}"
  }

  Seq("play2-reactivemongo", "reactivemongo-play-json").map(
    "org.reactivemongo" %% _ % playVer changing())
}

libraryDependencies ++= Seq(
  "com.typesafe.play" %% "play" % "2.7.1",
  "com.typesafe.play" %% "play-iteratees" % "2.6.1"/*streaming doc*/)

resolvers ++= Seq(
  "Typesafe releases" at "http://repo.typesafe.com/typesafe/releases/",
  "Sonatype Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots/")
