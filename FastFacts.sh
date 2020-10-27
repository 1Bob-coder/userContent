#!/bin/bash
# This generates a FastFacts file which provides a quick summary of test results.

  cd $WORKSPACE

  WORKSPACE_FASTFACTS=$WORKSPACE/FastFacts${NEPTUNE_PROJECT}${BUILD_NUMBER}.txt
  SERIALLOG=$WORKSPACE/SerialLog${BUILD_NUMBER}BOX*.txt

  echo -e " --- Testing Summary Fast Facts ---" | tee $WORKSPACE_FASTFACTS
  echo -e " All Log Files located at http://dsrjenkins1:8080/job/${JOB_NAME}/ws/*${BUILD_NUMBER}* " | tee -a $WORKSPACE_FASTFACTS
  echo -e "  $(grep -m 1 -h GIT.Branch TestSummary${BUILD_NUMBER}* | head -1) " | tee -a $WORKSPACE_FASTFACTS

  echo -e "  Num Neptune Warnings (Should be 0) : "| tee -a $WORKSPACE_FASTFACTS
  echo -e "$(grep -a -c -i local1.warn ${SERIALLOG} )"| tee -a $WORKSPACE_FASTFACTS
  echo -e "$(grep -a -i local1.warn ${SERIALLOG} | sed -e 's/^.*\(warn\)/ /' | sort | uniq -c )"| tee -a $WORKSPACE_FASTFACTS

  echo -e "  Num Neptune Fatals (Should be 0) : "| tee -a $WORKSPACE_FASTFACTS
  echo -e "$(grep -a -c -i local1.crit ${SERIALLOG} )"| tee -a $WORKSPACE_FASTFACTS
  echo -e "$(grep -a -i local1.crit ${SERIALLOG} | sed -e 's/^.*\(crit\)/ /' | sort | uniq -c )"| tee -a $WORKSPACE_FASTFACTS

  echo -e "  Test Failures (Should be none) : "| tee -a $WORKSPACE_FASTFACTS
  echo -e "$(grep  -i fail TestSummary${BUILD_NUMBER}* | sed -e 's/^/    /')"| tee -a $WORKSPACE_FASTFACTS

  echo -e "  Num Channel Changes (12 for Smoke, hundreds for Endurance) : "| tee -a $WORKSPACE_FASTFACTS
  echo -e "$(grep  -i channel.changes TestSummary${BUILD_NUMBER}* | sed -e 's/^/    /')"| tee -a $WORKSPACE_FASTFACTS

  echo -e "  Num Audio/Video Locks (Should match number of channel changes) : " | tee -a $WORKSPACE_FASTFACTS
  echo -e "$(grep  -i audio.video.locks TestSummary${BUILD_NUMBER}* | sed -e 's/^/    /')"| tee -a $WORKSPACE_FASTFACTS
  
  echo -e "  Num CheckTunerAvailability Errors (Should be 0) : "| tee -a $WORKSPACE_FASTFACTS
  echo -e "$(grep -a -c -i CheckTunerAvailability ${SERIALLOG} )" | tee -a $WORKSPACE_FASTFACTS
  echo -e "$(grep -a -i CheckTunerAvailability ${SERIALLOG} | sed -e 's/^.*\(CheckTunerAvailability\)/ /' | sort | uniq -c )"| tee -a $WORKSPACE_FASTFACTS

  echo -e "  Num UBIFS Errors/Warnings (Should be 0) : "| tee -a $WORKSPACE_FASTFACTS
  echo -e "$(grep -a -i ubifs.warning ${SERIALLOG} | sed -e 's/^.*\(ubifs\)/ /' | sort | uniq -c )"| tee -a $WORKSPACE_FASTFACTS
  echo -e "$(grep -a -i ubifs.error ${SERIALLOG} | sed -e 's/^.*\(ubifs\)/ /' | sort | uniq -c )"| tee -a $WORKSPACE_FASTFACTS

  cd -
