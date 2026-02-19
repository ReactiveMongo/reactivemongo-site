#! /usr/bin/env bash
  
set -e

if [ `which pandoc | wc -l` -lt 1 ]; then
  echo "Pandoc is not available: https://pandoc.org/" >> /dev/stderr
  exit 1
fi

if [ `which readlink | wc -l` -eq 1 ]; then
  S=`readlink -f $0`
  SDIR=`dirname $S`
fi

EXTRA_SED=';' # no replacement

usage() {
  cat >> /dev/stdout <<EOF

Usage:
  $0 \\
    -c /path/to/config.yml \\
    -b http://base/url \\
    -i /path/to/input.md \\
    -o /path/to/output.ext \\
    -f pandoc_output_format \\
    [ -s 'perl replacement' ] \\
    [ -p 'pandoc output options' ]

Convert a Jekyll markdown file using Pandoc.

Arguments to following options are mandatory.
  -c  Path to configuration file (YAML format)
  -b  Base URL to resolve the relative URL in the markdown input
  -i  Path to input markdown file
  -o  Path to output file
  -f  Pandoc output format (see 'pandoc --list-output-formats'):
EOF

  for F in `pandoc --list-output-formats`; do
    echo "      - $F"
  done

  cat >> /dev/stdout <<EOF

Arguments to following options are optional.
  -s  Perl replace expression (e.g. 's/Foo/Bar/')
  -p  Pandoc output options (e.g. '--pdf-engine=xelatex')

EOF

  exit 2
}

missing_arg() {
  echo "missing option -- $1" >> /dev/stderr
}

unset CONFIG_YML BASE_URL MD_INPUT OUTPUT_FORMAT OUTPUT_PATH OUTPUT_OPTIONS

while getopts 'c:b:i:s:f:o:p:' c
do
  case $c in
    c) CONFIG_YML=$OPTARG ;;
    b) BASE_URL=$OPTARG ;;
    i) MD_INPUT=$OPTARG ;;
    f) OUTPUT_FORMAT=$OPTARG ;;
    o) OUTPUT_PATH=$OPTARG ;;
    s) EXTRA_SED=$OPTARG ;;
    p) OUTPUT_OPTIONS=$OPTARG ;;
  esac
done

ERRORS=0

if [ -z "$CONFIG_YML" ]; then
  missing_arg 'c'
  ERRORS=`expr $ERRORS + 1`
fi

if [ -z "$BASE_URL" ]; then
  missing_arg 'b'
  ERRORS=`expr $ERRORS + 1`
fi

if [ -z "$MD_INPUT" ]; then
  missing_arg 'i'
  ERRORS=`expr $ERRORS + 1`
fi

if [ -z "$OUTPUT_FORMAT" ]; then
  missing_arg 'f'
  ERRORS=`expr $ERRORS + 1`
fi

if [ -z "$OUTPUT_PATH" ]; then
  missing_arg 'o'
  ERRORS=`expr $ERRORS + 1`
fi

[ $ERRORS -ne 0 ] && usage

"$SDIR/jekyll2pandoc.pl" "$BASE_URL" "$EXTRA_SED" < "$MD_INPUT" | \
    "$SDIR/liquid_render.rb" "$CONFIG_YML" /dev/stdin | \
    pandoc -t "$OUTPUT_FORMAT" $OUTPUT_OPTIONS /dev/stdin -o "$OUTPUT_PATH"
