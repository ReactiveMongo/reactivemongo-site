lazy val release_0_11 = project.in((file(".") / "releases" / "0.11"))

lazy val release_0_12 = project.in((file(".") / "releases" / "0.12"))

// TODO: Remove
lazy val release_0_1x = project.in((file(".") / "releases" / "0.1x"))

lazy val release_1_0 = project.in((file(".") / "releases" / "1.0"))

ThisBuild / credentials ++= sys.env.get("SONATYPE_USERNAME").toSeq.map { user =>
  Credentials(
    "", // Empty realm credential - this one is actually used by Coursier!
    "central.sonatype.com",
    user,
    sys.env("SONATYPE_PASSWORD")
  )
}

ThisBuild / resolvers ++= Seq(
  "Central Testing repository" at "https://central.sonatype.com/api/v1/publisher/deployments/download",
  "Sonatype Snapshots" at "https://central.sonatype.com/repository/maven-snapshots/",
  Resolver.typesafeRepo("releases")
)

lazy val `reactivemongo-site` = (project in file("."))
  .settings(
    doc / excludeFilter := "releases",
    scalaVersion := "2.12.20",
    ThisBuild / scalacOptions ++= Seq("-Ywarn-unused-import", "-unchecked"),
    libraryDependencies += "org.reactivemongo" %% "reactivemongo" % "1.1.0-RC21",
  ).aggregate(release_0_1x, release_1_0)

organization := "org.reactivemongo"

name := "reactivemongo-site"
