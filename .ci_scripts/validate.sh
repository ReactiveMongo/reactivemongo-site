#! /usr/bin/env bash

set -e

SCRIPT_DIR=`dirname $0 | sed -e "s|^\./|$PWD/|"`
SBT_VER="$1"

export SBT_OPTS="-Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=256M"

export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export PATH="$JAVA_HOME/bin:$HOME/.gem/ruby/2.2.5/bin:$PATH"
export GEM_PATH="$HOME/.gem/ruby/2.2.5:$GEM_PATH"

# Sonatype staging (avoid Central sync delay)
perl -pe "s|resolvers |resolvers in ThisBuild += \"Sonatype Staging\" at \"https://oss.sonatype.org/content/repositories/staging/\",\r\nresolvers |" < "$SCRIPT_DIR/../build.sbt" > /tmp/build.sbt && mv /tmp/build.sbt "$SCRIPT_DIR/../build.sbt"

R=0
for REPO in `curl -s https://oss.sonatype.org/content/repositories/ | grep 'href="https://oss.sonatype.org/content/repositories/orgreactivemongo' | cut -d '"' -f 2`; do
  perl -pe "s|resolvers |resolvers += \"Staging $R\" at \"$REPO\",\r\nresolvers |" < "$SCRIPT_DIR/../build.sbt" > /tmp/build.sbt && mv /tmp/build.sbt "$SCRIPT_DIR/../build.sbt"
done

SBT_JAR="$HOME/.sbt/launchers/$SBT_VER/sbt-launch.jar"

(java $SBT_OPTS -jar "$SBT_JAR" compile && \
  bundle exec jekyll build) || exit 2

echo "# Spell checking"
./node_modules/markdown-spellcheck/bin/mdspell -r --en-gb -n `find . -not -path '*/node_modules/*' -type f -name '*.md' | perl -pe 's|^\./||;s|[A-Za-z0-9.-]+|*|g' | sort -u | sed -e 's/$/.md/'` '!**/node_modules/**/*.md' '!**/vendor/**/*.md' || exit 3

echo "# Documentation built"
