#! /usr/bin/env bash

for F in `grep -rl 'java\$lang.html' _site`
do
  #echo $F
  sed -e 's/java\$lang.html/#java\$lang/g' < "$F" > "$F.tmp" && mv "$F.tmp" "$F"
done

echo "[INFO] Generated HTML normalized (for wget compat)"

wget -nv -e robots=off --follow-tags=a -r --spider \
  -Dlocalhost -Xreleases/0.1x/api http://localhost:4000
RES=$?

echo "[INFO] Documentation checked for broken links ($RES)"

rm -rf 'localhost:4000'
pkill -f jekyll

if [ $RES -ne 0 ]; then
  exit $RES
fi

echo "$ALGOLIA_API_KEY" | sed -e 's/[a-z0-9][a-z0-9][a-z0-9][a-z0-9]$//'

if [ "x$CI_BRANCH" = "xgh-pages" ]; then
  echo "[INFO] Indexing to Algolia"
  bundle exec jekyll algolia push || (
    echo "!! fails to push to Algolia"
    false
  )
else
  echo "[WARN] Skip the Algolia stage: branch = $CI_BRANCH"
fi
