#! /usr/bin/env bash

set -e

SCRIPT_DIR=`dirname $0 | sed -e "s|^\./|$PWD/|"`
SBT_VER="$1"

export SBT_OPTS="-Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=256M"

if [ "x$JAVA_HOME" = "x" ]; then
  export JAVA_HOME=/usr/lib/jvm/java-8-oracle
  export PATH="$JAVA_HOME/bin:$PATH"
fi

for D in `ls -v -1 "$HOME/.gem/ruby" | sort -r | head -n 1`; do
  export PATH="$HOME/.gem/ruby/$D/bin:$PATH"
  export GEM_PATH="$HOME/.gem/ruby/$D:$GEM_PATH"
done

if [ "x$SBT_JAR" = "x" ]; then
  SBT_JAR="$HOME/.sbt/launchers/$SBT_VER/sbt-launch.jar"
fi

echo "[INFO] Compiling code samples ..."

java $SBT_OPTS -jar "$SBT_JAR" error test:compile || exit 1

echo "[INFO] Building documentation ..."

bundle exec jekyll build || exit 2

echo "[INFO] Spell checking ..."
./node_modules/markdown-spellcheck/bin/mdspell -r --en-gb -n `find . -not -path '*/node_modules/*' -type f -name '*.md' | perl -pe 's|^\./||;s|[A-Za-z0-9.-]+|*|g' | sort -u | sed -e 's/$/.md/'` '!**/node_modules/**/*.md' '!**/vendor/**/*.md' || exit 3

echo "[INFO] Documentation is checked"
