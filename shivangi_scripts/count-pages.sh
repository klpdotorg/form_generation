#!/bin/sh

file=$(mktemp)
find . -type f -name \*pdf -exec pdfinfo {} \; | grep Pages > $file
while read l 
do 
    sum=$(($sum + $(echo $l | awk '{print $2}')))
done < $file
echo $sum pages over $(wc -l < $file) files

