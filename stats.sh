#!/bin/sh

echo "\n[ Perl Modules ]"
find lib -name '*.pm' | xargs wc

echo "\n[ Web App ]"
wc coma

echo "\n[ Templates ]"
find templates -name '*.ep' | xargs wc

echo "\n[ Tests ]"
find t -name '*.t' | xargs wc

echo "\n[ Non-executable test files ]"
find t -type f -not -name '*.t' | xargs wc

echo "\n[ Summary ]"
echo 'Productive code: '
{ find . -name '*.pm' & find templates -name '*.ep' & echo 'coma'; } | xargs wc | tail -1
echo 'Tests:           '
{ find t -name '*.t' & find t -type f -not -name '*.t'; } | xargs wc | tail -1
