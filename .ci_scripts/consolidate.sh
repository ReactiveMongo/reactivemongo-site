#! /usr/bin/env bash

for F in `grep -rl 'java\$lang.html' _site`
do
  #echo $F
  sed -e 's/java\$lang.html/#java\$lang/g' < "$F" > "$F.tmp" && mv "$F.tmp" "$F"
done

echo "# Generated HTML normalized (for wget compat)"

wget -nv -e robots=off --follow-tags=a -r --spider \
  -Dlocalhost -Xreleases/0.12/api -Xreleases/0.10/api \
  -Xreleases/0.11/api -Xreleases/0.10.5/api http://localhost:4000
RES=$?

echo "# Documentation checked for broken links ($RES)"

rm -rf 'localhost:4000'
pkill -f jekyll

if [ $RES -ne 0 ]; then
  exit $RES
fi

echo "# Indexing to Algolia"
bundle exec jekyll algolia push || (
    echo "!! fails to push to Algolia"
    false
)
