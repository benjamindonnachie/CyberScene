#!/bin/bash

CREDS=`gshuf -n 1 /Users/benjamindonnachie/Library/CloudStorage/GoogleDrive-benjamin.donnachie@googlemail.com/My\ Drive/Research/Objective\ 1\ -\ datasets/activeDirectory_user_pass_only.csv`

USER=`echo $CREDS | awk ' { print $1 } '`
PASSWORD=`echo $CREDS | awk ' { print $2 } '`
DOMAIN=`echo $CREDS | awk ' { print $3 } '`

#VBoxManage controlvm Win10-Ghosts-4 setcredentials $USER $PASSWORD $DOMAIN

