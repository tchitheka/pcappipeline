#!/usr/bin/env bash

COUNTER=1

FILE=`ls -1 |sort -r|head -4`

for FILES in $FILE
do
  echo "File number $COUNTER : $FILES"
  ((COUNTER++))
done