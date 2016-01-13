lazy val release_0_11 = project.in((file(".") / "releases" / "0.11"))

lazy val `reactivemongo-site` = (project in file("."))
  .settings(
    excludeFilter in doc := "releases",
    highlightStartToken in ThisBuild := "{% highlight scala %}",
    highlightEndToken in ThisBuild := "{% endhighlight %}",
    scalaVersion := "2.11.7",
    scalacOptions in ThisBuild ++= Seq("-Ywarn-unused-import", "-unchecked"),
    libraryDependencies ++= Seq(
      "org.reactivemongo" %% "reactivemongo" % "0.11.9",
      "com.typesafe.play" %% "play-iteratees" % "2.3.5"),
    resolvers ++= Seq(
      "Typesafe releases" at "http://repo.typesafe.com/typesafe/releases/"))
  .aggregate(release_0_11)

organization := "org.reactivemongo"

name := "reactivemongo-site"
