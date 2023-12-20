Using SBT, you just have to edit `build.sbt` and add the driver dependency:

```ocaml
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "{{page.major_version}}"
)
```

for Pekko based projects, add the following dependency:

```ocaml
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo-pekko" % "{{page.major_version}}"
)
```
