#! /bin/sh

set -e

MAJOR="1.0"

./project/jekyll2pandoc.sh \
    -c _config.yml \
    -b "http://reactivemongo.org/releases/$MAJOR/documentation/" \
    -i "releases/$MAJOR/documentation/release-details.md" \
    -s 's/^\#\#[\#]+/\#\#/' \
    -f beamer -o ~/Desktop/slides.pdf \
    -p '--pdf-engine=xelatex'
