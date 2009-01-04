# Find URLs and put them on a line of their own
s/\(http:\/\/[-$a-zA-Z0-9\/;:@&=?#_.+!*'(),%]*\)/\
\1\
/g