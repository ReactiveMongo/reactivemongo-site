organization := "org.reactivemongo"

name := "release_1_0"

version := "1.1.0-RC16"

scalaVersion := "2.12.20"

libraryDependencies ++= Seq(
  "reactivemongo-akkastream",
  "reactivemongo-pekkostream",
  "reactivemongo-iteratees",
  "reactivemongo-bson-api",
  "reactivemongo-bson-geo",
  "reactivemongo-bson-monocle",
  "reactivemongo-bson-specs2",
  "reactivemongo-bson-msb-compat"
).map { d =>
  ("org.reactivemongo" %% d % version.value changing()).
    exclude("org.scala-lang.modules", "scala-java8-compat_2.12")
}

libraryDependencies ++= {
  val idx = version.value.lastIndexOf('-')
  val playVer = version.value.splitAt(idx) match {
    case ("", major) => s"${major}-play27"
    case (major, mod) => s"${major}-play27.${mod stripPrefix "-"}"
  }

  Seq("play2-reactivemongo", "reactivemongo-play-json-compat").map(
    "org.reactivemongo" %% _ % playVer changing())
}

libraryDependencies ++= Seq(
  "com.typesafe.play" %% "play" % "2.7.1",
  "com.typesafe.play" %% "play-iteratees" % "2.6.1"/*streaming doc*/)
