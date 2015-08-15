#! /bin/sh

export SBT_OPTS="-Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=256M"

export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export PATH="$JAVA_HOME/bin:$PATH"

java $SBT_OPTS -jar "$HOME/.sbt/launchers/0.13.8/sbt-launch.jar" compile && \
  jekyll build
