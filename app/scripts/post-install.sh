#!/bin/bash

HOME_PATH="/opt/codedeploy-agent/deployment-root"
SUFFIX="deployment-archive"

LOCAL_PREFIX="$HOME_PATH/$DEPLOYMENT_GROUP_ID/$DEPLOYMENT_ID/$SUFFIX"
ARTIFACT_FILE="raw_data.zip"
ARTIFACT_PATH="$LOCAL_PREFIX/$ARTIFACT_FILE"
SOURCE_FILE1="$LOCAL_PREFIX/service/raw_data.py"
SOURCE_FILE2="$LOCAL_PREFIX/raw_data/service/raw_data.py"
UBUNTU_HOME="/home/ubuntu"

if test -f $ARTIFACT_PATH; then sudo unzip -o $ARTIFACT_PATH -d $LOCAL_PREFIX; fi
if test -f $SOURCE_FILE1; then sudo cp $SOURCE_FILE1 $UBUNTU_HOME; fi
if test -f $SOURCE_FILE2; then sudo cp $SOURCE_FILE2 $UBUNTU_HOME; fi

