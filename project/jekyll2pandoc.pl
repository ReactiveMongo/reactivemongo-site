#! /usr/bin/env perl

# Pre-processed Jekyll markdown to be then converted with Pandoc

if (!(defined $ARGV[0])) {
  print "Usage: $0 http://base/url/to/resolve/relative (replace)\n";
  exit 1
}

my $base_url = $ARGV[0];

my $sed = ';';

if (defined $ARGV[1]) {
  $sed = $ARGV[1];
}

my $hidden = 0;

while (<STDIN>) {
    if ($hidden == 1) {
        if (/<\!-- end_pandoc_hidden -->/) {
            s/^.*<\!-- end_pandoc_hidden -->//;
            $hidden = 0;
        }
    }

    if ($hidden == 0) {
        # Resolves relative URLs as absolute ones with online base URL
        s|\]\(\./|]($base_url|g;

        # Normalizes link attributes between jekyll GFM and pandom kramdown
        s/\)\{:/){/g;

        # Extra replacements
        eval $sed;
        
        # Materializes slide separator only for beamer
        s/<\!-- pandoc_sep:[ \t]*([^-]+)[ \t]*-->/\n\#\# $1\n/;
        s/<\!-- pandoc_sep -->/\n---\n/;
        
        s/<\!-- pandoc_hidden -->[^<]*<\!-- end_pandoc_hidden -->//g;

        if (/<\!-- pandoc_hidden -->/) {
            s/<\!-- pandoc_hidden -->.*$//;
            $hidden = 1;
        }

        print
    }
}
