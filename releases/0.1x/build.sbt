organization := "org.reactivemongo"

name := "release_0_1x"

val majorVer = "0"

version := majorVer

val Release = s"${majorVer}.17.0"

scalaVersion := "2.12.8"

libraryDependencies ++= Seq(
  "reactivemongo-iteratees", "reactivemongo-akkastream").map(
  "org.reactivemongo" %% _ % Release changing())

libraryDependencies ++= {
  val playVer = Release.span(_ != '-') match {
    case (major, "") => s"${major}-play27"
    case (major, mod) => s"${major}-play27${mod}"
  }

  Seq("play2-reactivemongo", "reactivemongo-play-json").map(
    "org.reactivemongo" %% _ % playVer changing())
}

libraryDependencies += "com.typesafe.play" %% "play" % "2.7.0"

resolvers ++= Seq(
  "Typesafe releases" at "http://repo.typesafe.com/typesafe/releases/",
  "Sonatype Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots/")
