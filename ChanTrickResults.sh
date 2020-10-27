#!/bin/bash
# This checks the Channel Trick Play test for the following conditions:
# 1) No warnings or fatals.
if [ $# -ne 2 ]; then
  echo -e "format is:  ChanTrickResults.sh input.txt output.txt" | tee -a $2
  exit 1
else
  echo -e "*******************************" | tee -a $2
  echo -e "Channel Trick Play Test Results:" | tee -a $2
  echo $1 | tee -a $2
  NUM_WARNINGS=$(grep -c warng $1)
  echo -e "  warnings: ${NUM_WARNINGS}" | tee -a $2
  NUM_FATALS=$(grep -c crit $1)
  echo -e "  fatals: ${NUM_FATALS}" | tee -a $2
  
  if [ $NUM_WARNINGS -ne 0 ]; then
    echo -e "  Failed on warnings" | tee -a $2
    echo -e "*******************************" | tee -a $2
    exit 1
  elif [ $NUM_FATALS -ne 0 ]; then
    echo -e "  Failed on fatals" | tee -a $2
    echo -e "*******************************" | tee -a $2
    exit 2
  fi
fi
echo -e "No Errors" | tee -a $2
echo -e "*******************************" | tee -a $2
