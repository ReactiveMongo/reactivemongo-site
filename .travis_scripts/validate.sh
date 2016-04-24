#! /bin/sh

SBT_VER="$1"

export SBT_OPTS="-Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=256M"

export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export PATH="$JAVA_HOME/bin:$HOME/.gem/ruby/2.2.0/bin:$PATH"
export GEM_PATH="$HOME/.gem/ruby/2.2.0:$GEM_PATH"

#JEKYLL_VER=`jekyll -v | sed -e 's/^jekyll[ \t]*//'`
#
#if [ ! "x$JEKYLL_VER" = "x2.5.3" ]; then
#  echo "Unexpected Jekyll version: $JEKYLL_VER"
#  exit 1
#fi

(java $SBT_OPTS -jar "$HOME/.sbt/launchers/$SBT_VER/sbt-launch.jar" compile && \
  jekyll build) || exit 2

echo "# Documentation built"

jekyll serve --detach
echo "# Jekyll local server started"

for F in `grep -rl 'java\$lang.html' _site`
do
  echo $F && sed -e 's/java\$lang.html/#java\$lang/g' < "$F" > "$F.tmp" && mv "$F.tmp" "$F"
done

echo "# Generated HTML normalized (for wget compat)"

wget -nv -e robots=off -Dlocalhost --follow-tags=a -r --spider http://localhost:4000
RES=$?

echo "# Documentation checked for broken links"

rm -rf 'localhost:4000'
pkill -f jekyll

exit $RES
