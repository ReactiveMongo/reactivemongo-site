lazy val release_0_11 = project.in((file(".") / "releases" / "0.11"))

lazy val release_0_12 = project.in((file(".") / "releases" / "0.12"))

lazy val `reactivemongo-site` = (project in file("."))
  .settings(
    excludeFilter in doc := "releases",
    highlightStartToken in ThisBuild := "{% highlight scala %}",
    highlightEndToken in ThisBuild := "{% endhighlight %}",
    scalaVersion := "2.11.8",
    scalacOptions in ThisBuild ++= Seq("-Ywarn-unused-import", "-unchecked"),
    libraryDependencies ++= Seq(
      "org.reactivemongo" %% "reactivemongo" % "0.12.0"),
    resolvers ++= Seq(
      "Typesafe releases" at "http://repo.typesafe.com/typesafe/releases/"))
  .aggregate(release_0_11, release_0_12)

organization := "org.reactivemongo"

name := "reactivemongo-site"
