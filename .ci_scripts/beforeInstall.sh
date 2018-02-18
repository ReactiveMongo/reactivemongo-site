#! /bin/bash

export PATH="$HOME/.gem/ruby/2.2.5/bin:$PATH"
#gem install --no-verbose --user-install jekyll -v 2.5.3
gem install --no-verbose --user-install jekyll pygments.rb || exit 1
bundle install || exit 2
pip install --user Pygments || exit 3
npm i markdown-spellcheck -u

find $HOME/.local -type f -print

SBT_VER="$1"
SBT_LAUNCHER_HOME="$HOME/.sbt/launchers/$SBT_VER"
SBT_LAUNCHER_JAR="$SBT_LAUNCHER_HOME/sbt-launch.jar"

if [ ! -r "$SBT_LAUNCHER_JAR" ]; then
  mkdir -p $SBT_LAUNCHER_HOME
  curl -L -o "$SBT_LAUNCHER_JAR" "https://repo1.maven.org/maven2/org/scala-sbt/sbt-launch/$SBT_VER/sbt-launch-$SBT_VER.jar"
else
  echo -n "SBT already set up: "
  ls -v -1 "$SBT_LAUNCHER_JAR"
fi
