#! /usr/bin/env bash

set -e

for D in `ls -v -1 "$HOME/.gem/ruby"`; do
  export PATH="$HOME/.gem/ruby/$D/bin:$PATH"
done

if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if [ `which pip | wc -l` -eq 0 ]; then
  curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
  python /tmp/get-pip.py
fi

gem install --no-verbose --user-install jekyll pygments.rb || exit 1
bundle install --path "$HOME/.bundle" || exit 2
pip install --user Pygments || exit 3

cat > package.json << EOF
{
  "name": "",
  "description": "",
  "version": "0.1.0",
  "dependencies": {},
  "devDependencies": {}
}
EOF
npm i markdown-spellcheck -u || exit 4

#find $HOME/.local -type f -print

SBT_VER="$1"
SBT_LAUNCHER_HOME="$HOME/.sbt/launchers/$SBT_VER"
SBT_LAUNCHER_JAR="$SBT_LAUNCHER_HOME/sbt-launch.jar"

if [ ! -r "$SBT_LAUNCHER_JAR" ]; then
  mkdir -p $SBT_LAUNCHER_HOME
  curl -L -o "$SBT_LAUNCHER_JAR" "https://repo1.maven.org/maven2/org/scala-sbt/sbt-launch/$SBT_VER/sbt-launch-$SBT_VER.jar"
else
  echo -n "[INFO] SBT already set up: "
  ls -v -1 "$SBT_LAUNCHER_JAR"
fi
