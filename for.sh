#!/usr/bin/env bash

NAME=$@

for names in $NAME
do
    if [ "$names" == "Alice" ]; then
        echo "Welcome back, Alice!"
        
    fi
  echo "Hello, $names"
done        
