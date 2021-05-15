organization := "org.reactivemongo"

name := "release_1_0"

version := "1.0.4"

scalaVersion := "2.12.13"

libraryDependencies ++= Seq(
  "reactivemongo-akkastream",
  "reactivemongo-iteratees",
  "reactivemongo-bson-api",
  "reactivemongo-bson-geo",
  "reactivemongo-bson-monocle",
  "reactivemongo-bson-specs2",
  "reactivemongo-bson-msb-compat"
).map(
  "org.reactivemongo" %% _ % version.value changing())

libraryDependencies ++= {
  val idx = version.value.lastIndexOf('-')
  val playVer = version.value.splitAt(idx) match {
    case ("", major) => s"${major}-play27"
    case (major, mod) => s"${major}-play27${mod}"
  }

  Seq("play2-reactivemongo", "reactivemongo-play-json-compat").map(
    "org.reactivemongo" %% _ % playVer changing())
}

libraryDependencies ++= Seq(
  "com.typesafe.play" %% "play" % "2.7.1",
  "com.typesafe.play" %% "play-iteratees" % "2.6.1"/*streaming doc*/)
