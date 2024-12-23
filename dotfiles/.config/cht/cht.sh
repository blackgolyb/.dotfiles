#!/bin/bash

topic_constraint="none"
viewer="zed"

while [[ "$#" -gt 0 ]];do
case $1 in
  l|lang)
  topic_constraint="lang"
  shift;;
esac
done

topic=""
if [[ "$topic_constraint" == "lang" ]]; then
  topic=$(printf "go\nrust\nc" | fzf)
  stty sane
else
  topic=$(curl -s cht.sh/:list | fzf)
  stty sane
fi

if [[ -z "$topic" ]]; then
  exit 0
fi

sheet=$(curl -s cht.sh/$topic/:list | fzf)

if [[ -z "$sheet" ]]; then
  request="curl -s cht.sh/$topic"
else
  request="curl -s cht.sh/$topic/$sheet"
fi

buffer=$(mktemp /tmp/cht-XXXXX)
eval $request | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' > $buffer
$viewer $buffer
rm $buffer
