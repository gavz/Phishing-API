#!/bin/bash

## DEFAULTS IF NOT FROM PHISHING DOCS
SlackURL="https://hooks.slack.com/services/YOUR_SLACK_INCOMING_WEBHOOK_HERE"
SlackChannel="#YOUR_SLACK_CHANNEL_HERE"
APIURL="https://YOUR_SLACK_DOMAIN_HERE"

files=$(cd /home/ubuntu/Responder/logs && ls *.txt | awk '{print $1}');

IFS='
'
count=0
for item in $files
do
  file=$item
  count=$((count+1))
  IP=$(echo $item | cut -d "-" -f 4 | cut -d "." -f 1,2,3,4);
  Module=$(echo $item | cut -d "-" -f 3);
  HashType=$(echo $item | cut -d "-" -f 2);

  Hashes=$(cat /home/ubuntu/Responder/logs/$file);

  Query=$(mysql -u root phishingdocs -se "CALL MatchHashes('$IP','$Hashes');");

  Title=$(echo $Query | cut -f 1);
  Target=$(echo $Query | cut -f 2);
  Org=$(echo $Query | cut -f 3);
  Token=$(echo $Query | cut -f 4);
  Channel=$(echo $Query | cut -f 5);
  UUID=$(echo $Query | cut -f 6);

if [ $Title = "PhishingDocs" ]
then
  message=$(echo "> *HIT!!* Captured a" $HashType "hash ("$Module") for" $Target "at" $Org "(<"$APIURL/phishingdocs/results?UUID=$UUID"|"$IP">)");
  curl -s -X POST --data-urlencode 'payload={"channel": "'$Channel'", "username": "HashBot", "text": "'$message'", "icon_emoji": ":hash:"}' $Token
fi

if [ $Title = "FakeSite" ]
then
  message=$(echo "> *HIT!!* Captured a" $HashType "hash ("$Module") for "$Target" at <"$APIURL/results?project=$Target"|"$IP">");
  curl -s -X POST --data-urlencode 'payload={"channel": "'$SlackChannel'", "username": "HashBot", "text": "'$message'", "icon_emoji": ":hash:"}' $SlackURL
fi

  if [ -z "$Title" ]
  then
  ## COMMENT THE NEXT TWO LINES OUT IF YOU DO NOT WISH TO BE NOTIFIED FOR OUT OF SCOPE HASHES
      message=$(echo "> Captured an out of scope" $HashType "hash ("$Module") at" $IP"\r\n> \`\`\`"$Hashes"\`\`\`");
      curl -s -X POST --data-urlencode 'payload={"channel": "'$SlackChannel'", "username": "HashBot", "text": "'$message'", "icon_emoji": ":hash:"}' $SlackURL
  fi

  rm /home/ubuntu/Responder/logs/$file;

done
