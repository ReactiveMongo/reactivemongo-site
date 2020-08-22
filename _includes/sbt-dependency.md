Using SBT, you just have to edit `build.sbt` and add the driver dependency:

```ocaml
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "{{page.major_version}}"
)
```
