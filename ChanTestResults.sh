#!/bin/bash
# This checks a channel change test for the following conditions:
# 1) Every channel change must have audio lock and video lock.
# 2) No warnings or fatals.
if [ $# -ne 2 ]; then
  echo -e "format is:  ChanTestResults.sh input.txt output.txt" | tee -a $2
  exit 1
else
  echo -e "*******************************" | tee -a $2
  echo -e "Channel Change Test Results:" | tee -a $2
  echo $1 | tee -a $2
  NUM_CHAN=$(grep -c TUNE.TO.CHANNEL $1)
  echo -e "  channel changes: ${NUM_CHAN}" | tee -a $2
  NUM_AUDIO=$(grep -c AUDIO_COMPONENT_START_SUCCESS $1)
  NUM_VIDEO=$(grep -c VIDEO_COMPONENT_START_SUCCESS $1)
  echo -e "  audio/video locks: ${NUM_AUDIO} / ${NUM_VIDEO}" | tee -a $2
  NUM_SVC_DENIED=$(grep -c SEND.SERVICE_DENIED $1)
  echo -e "  Svc Denied : ${NUM_SVC_DENIED}" | tee -a $2
  NUM_WARNINGS=$(grep -c warn $1)
  echo -e "  warnings: ${NUM_WARNINGS}" | tee -a $2
  NUM_FATALS=$(grep -c crit $1)
  echo -e "  fatals: ${NUM_FATALS}" | tee -a $2
  
  if [ $NUM_AUDIO -ne $NUM_VIDEO ]; then
    echo -e "  Failed on either audio or video" | tee -a $2
    echo -e "*******************************" | tee -a $2
    exit 1
  elif [ $NUM_CHAN -ne $[$NUM_VIDEO + $NUM_SVC_DENIED] ]; then
    echo -e "  Failed on not getting audio or video lock" | tee -a $2
    echo -e "*******************************" | tee -a $2
    exit 2
  elif [ $NUM_WARNINGS -ne 0 ]; then
    echo -e "  Failed on warnings" | tee -a $2
    echo -e "*******************************" | tee -a $2
    exit 3
  elif [ $NUM_FATALS -ne 0 ]; then
    echo -e "  Failed on fatals" | tee -a $2
    echo -e "*******************************" | tee -a $2
    exit 4
  elif [ $NUM_CHAN -eq 0 ]; then
    echo -e "  Failed on channel changing" | tee -a $2
    echo -e "*******************************" | tee -a $2
    exit 5
  fi
fi
echo -e "No Errors" | tee -a $2
echo -e "*******************************" | tee -a $2
