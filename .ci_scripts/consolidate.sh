#! /usr/bin/env bash

set -e

for F in `grep -rl 'java\$lang.html' _site`
do
  #echo $F
  sed -e 's/java\$lang.html/#java\$lang/g' < "$F" > "$F.tmp" && mv "$F.tmp" "$F"
done

echo "[INFO] Generated HTML normalized (for wget compat)"

#TODO:
#wget -nv -e robots=off --follow-tags=a -r --spider \ 
#  -Dlocalhost -Xreleases/0.1x/api http://localhost:4000
#RES=$?

#echo "[INFO] Documentation checked for broken links ($RES)"

rm -rf 'localhost:4000'
pkill -f jekyll

if [ $RES -ne 0 ]; then
  exit $RES
fi
