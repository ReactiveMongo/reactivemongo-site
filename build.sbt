lazy val release_0_11 = project.in((file(".") / "releases" / "0.11"))

lazy val release_0_12 = project.in((file(".") / "releases" / "0.12"))

// TODO: Remove
lazy val release_0_1x = project.in((file(".") / "releases" / "0.1x"))

lazy val release_1_0 = project.in((file(".") / "releases" / "1.0"))

lazy val `reactivemongo-site` = (project in file("."))
  .settings(
    doc / excludeFilter := "releases",
    scalaVersion := "2.11.12",
    ThisBuild / scalacOptions ++= Seq("-Ywarn-unused-import", "-unchecked"),
    libraryDependencies ++= Seq(
      "org.reactivemongo" %% "reactivemongo" % "1.1.0-RC9"),
    ThisBuild / resolvers ++= Seq(
      Resolver.typesafeRepo("releases"),
      Resolver.sonatypeRepo("snapshots"),
      Resolver.sonatypeRepo("staging")))
  .aggregate(release_0_1x, release_1_0)

organization := "org.reactivemongo"

name := "reactivemongo-site"
