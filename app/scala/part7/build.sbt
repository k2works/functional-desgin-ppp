ThisBuild / scalaVersion := "3.3.1"
ThisBuild / organization := "com.example"

lazy val root = (project in file("."))
  .settings(
    name := "functional-design-part7",
    libraryDependencies ++= Seq(
      "org.scalatest" %% "scalatest" % "3.2.17" % Test
    )
  )
