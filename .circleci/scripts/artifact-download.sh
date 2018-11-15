#!/usr/bin/env bash

# Retreive a build artifact from A circle job of the same type

ARTIFACT_PATH="$1"
DESTINATION="$2"

# Get latest artifacts (Doesn't work because it does not allow specification of job name)
# API_URL="https://circleci.com/api/v1.1/project/github/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/latest/artifacts?circle-token=$CIRCLE_TOKEN"
API_URL="https://circleci.com/api/v1.1/project/github/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME?circle-token=$CIRCLE_TOKEN&limit=25&filter=successful"

LAST_SUCCESSFUL_JOB=$(curl -s -H "Accept: application/json" "$API_URL" | jq --arg CIRCLE_JOB "$CIRCLE_JOB" 'reduce .[] as $i ([]; if ($i | .build_parameters[]) == $CIRCLE_JOB then . + [$i] else . end) | first')

if [[ $LAST_SUCCESSFUL_JOB ]]; then
  BUILD_NUMBER=$(echo "$LAST_SUCCESSFUL_JOB" | jq '.build_num')

  API_URL="https://circleci.com/api/v1.1/project/github/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$BUILD_NUMBER/artifacts?circle-token=$CIRCLE_TOKEN"
  ARTIFACT=$(curl -s -H "Accept: application/json" "$API_URL" | jq --arg ARTIFACT_PATH "$ARTIFACT_PATH" '.[] | select(.path==$ARTIFACT_PATH)')
  if [[ $ARTIFACT ]]; then
    ARTIFACT_URL=$(echo "$ARTIFACT" | jq -r '.url')

    echo "Found $ARTIFACT_PATH"
    echo "Downloading artifact to $DESTINATION"

    mkdir -p $(dirname $DESTINATION)

    curl -s $ARTIFACT_URL -o $DESTINATION
  else
    echo "No usable artifacts found"
  fi
else
  echo "No eligable jobs found"
fi
