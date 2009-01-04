#!/bin/bash
#
# Extracts URLs from standard in and outputs these to standard out.
#
# Matching is fairly basic. URLs are assumed to start with "http://" and
# end when a character is encountered that cannot appear anywhere in a 
# URL. So, it matches all valid URLs, but it can match invalid URLs such
# as "http://", "http://#?", and "http://foo.bar/%".
#
# It copes with multiple URLs on a single line, as well as URLs that
# contain other URLs, such as "http://www.redirect.com?to=http://foo.bar".
# In these cases, only the "outer" URLs are reported.

sed -f extract-urls.sed | grep "http://"