#! /bin/sh

export SBT_OPTS="-Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=256M"

export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export PATH="$JAVA_HOME/bin:$PATH"

java $SBT_OPTS -jar "$HOME/.sbt/launchers/0.13.8/sbt-launch.jar" compile && \
  jekyll build

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
