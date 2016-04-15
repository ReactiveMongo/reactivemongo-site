#! /bin/bash

export PATH="$HOME/.gem/ruby/1.9.1/bin:$PATH"
gem install --no-verbose --user-install jekyll -v 2.5.3
find "$HOME/.gem" -not -path '*/specs/*' -print

SBT_VER="$1"
SBT_LAUNCHER_HOME="$HOME/.sbt/launchers/$SBT_VER"
SBT_LAUNCHER_JAR="$SBT_LAUNCHER_HOME/sbt-launch.jar"

if [ ! -r "$SBT_LAUNCHER_JAR" ]; then
  mkdir -p $SBT_LAUNCHER_HOME
  curl -L -o "$SBT_LAUNCHER_JAR" "http://dl.bintray.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/$SBT_VER/sbt-launch.jar"
else
  echo -n "SBT already set up: "
  ls -v -1 "$SBT_LAUNCHER_JAR"
fi
