#!/bin/bash
# This checks a DVR Playack test for the following conditions:
# 1) Every DVR Playback have audio lock and video lock.
# 2) No warnings or fatals.
if [ $# -ne 2 ]; then
  echo -e "format is:  DvrPlayResults.sh input.txt output.txt" | tee -a $2
  exit 1
else
  echo -e "*******************************" | tee -a $2
  echo -e "DVR Playback Test Results:" | tee -a $2
  echo $1 | tee -a $2
  NUM_PLAYBACKS=$(grep -c START.PLAYBACK $1)
  echo -e "  Number of Playbacks: ${NUM_PLAYBACKS}" | tee -a $2
  NUM_STOP_PLAYBACKS=$(grep -c STOP.PLAYBACK $1)
  echo -e "  Number of Stop Playbacks: ${NUM_STOP_PLAYBACKS}" | tee -a $2
  NUM_AUDIO=$(grep -c AUDIO_COMPONENT_START_SUCCESS $1)
  NUM_VIDEO=$(grep -c VIDEO_COMPONENT_START_SUCCESS $1)
  echo -e "  audio/video locks: ${NUM_AUDIO} / ${NUM_VIDEO}" | tee -a $2
  NUM_WARNINGS=$(grep -c warn $1)
  echo -e "  warnings: ${NUM_WARNINGS}" | tee -a $2
  NUM_FATALS=$(grep -c crit $1)
  echo -e "  fatals: ${NUM_FATALS}" | tee -a $2
  
  if [ $NUM_AUDIO -ne $NUM_VIDEO ]; then
    echo -e "  Failed on either audio or video" | tee -a $2
    echo -e "*******************************" | tee -a $2
    exit 1
  elif [ $NUM_WARNINGS -ne 0 ]; then
    echo -e "  Failed on warnings" | tee -a $2
    echo -e "*******************************" | tee -a $2
    exit 3
  elif [ $NUM_FATALS -ne 0 ]; then
    echo -e "  Failed on fatals" | tee -a $2
    echo -e "*******************************" | tee -a $2
    exit 4
  fi
fi
echo -e "No Errors" | tee -a $2
echo -e "*******************************" | tee -a $2
