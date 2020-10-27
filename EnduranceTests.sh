#!/bin/bash
# This runs all tests on the specified box.  The input parameter is a specified
# Jenkins test box (1-4).  This runs the following Drip tests:
# 1) Reboot the box.
# 2) Get Diag A info on hardware type and Neptune version.
# 3) Perform a channel change test.

if [ $# -ne 1 ]; then
  echo "format is:  AllTests.sh BOXn -- where n is a number 1,2,3,or 4"
  exit 1
else
  echo "box is ${1}"
  if [ "$1" = "BOX1" ]; then
    IPADDR=$IP_DSR830_1
    NEPTUNE_PROJECT_DIR=_DSR830_
    SERIAL_PORT=/dev/ttyUSB0
    REBOOT_BOX=1
    REBOOT_DELAY=10
  elif [ "$1" = "BOX2" ]; then
    IPADDR=$IP_DSR830_2
    NEPTUNE_PROJECT_DIR=_DSR830_
    SERIAL_PORT=/dev/ttyUSB1
    REBOOT_BOX=2
    REBOOT_DELAY=30
  elif [ "$1" = "BOX3" ]; then
    IPADDR=$IP_DSR830_3
    NEPTUNE_PROJECT_DIR=_DSR830_
    SERIAL_PORT=/dev/ttyUSB2
    REBOOT_BOX=3
    REBOOT_DELAY=50
  elif [ "$1" = "BOX4" ]; then
    IPADDR=$IP_DSR800_4
    NEPTUNE_PROJECT_DIR=_DSR800_
    SERIAL_PORT=/dev/ttyUSB3
    REBOOT_BOX=4
    REBOOT_DELAY=10
  elif [ "$1" = "BOX5" ]; then
    IPADDR=$IP_DSR800_5
    NEPTUNE_PROJECT_DIR=_DSR800_
    SERIAL_PORT=/dev/ttyUSB4
    REBOOT_BOX=5
    REBOOT_DELAY=30
  elif [ "$1" = "BOX6" ]; then
    IPADDR=$IP_DSR800_6
    NEPTUNE_PROJECT_DIR=_DSR800_
    SERIAL_PORT=/dev/ttyUSB5
    REBOOT_BOX=6
    REBOOT_DELAY=50
  else 
    echo " ERROR - boxn : ${1} not understood"
    exit 1
  fi

  ERROR_ALL_TESTS=0

  DIR_COPY_FROM=/extra/tftpboot/jenkins/$NEPTUNE_PROJECT_DIR
  DIR_COPY_BOXN=/extra/tftpboot/jenkins/$1/$NEPTUNE_PROJECT_DIR

  # copy package.bin from the tftpboot directory to the boxn directory.
  rm -f $DIR_COPY_BOXN/package.bin
  cp $DIR_COPY_FROM/package.bin $DIR_COPY_BOXN/package.bin

  WORKSPACE_BUILDDATA=$WORKSPACE/BuildData${NEPTUNE_PROJECT_DIR}${BUILD_NUMBER}.txt
  CHANTEST_SUMMARY=$WORKSPACE/ChanTestSummary${BUILD_NUMBER}${1}.txt 

  # copy BuildData.txt to boxn directory and workspace
  rm -f $DIR_COPY_BOXN/BuildData.txt
  rm -f $WORKSPACE/BuildData.txt
  cp $DIR_COPY_FROM/BuildData.txt $DIR_COPY_BOXN/BuildData.txt
  cp $DIR_COPY_FROM/BuildData.txt $WORKSPACE_BUILDDATA

  echo "Remove files older than 25 days"
  find -f $WORKSPACE -mtime +25 -exec rm {} \;
  TEST_DIR=$JENKINS_HOME/userContent
  DRIP_CLIENT=$JENKINS_HOME/userContent/DripClient.py

  # Check to see if the BuildData_DSRxxx_nn.txt file said "Not building".
  NOT_BUILDING_COUNT=$(grep -c Not.building BuildData${NEPTUNE_PROJECT_DIR}${BUILD_NUMBER}.txt)
  echo -e " Not Building Count = ${NOT_BUILDING_COUNT}" 
  if [ $NOT_BUILDING_COUNT -ne 0 ]; then 
    echo "No changes in code.  Run tests anyway."
    NOT_BUILDING_COUNT=0
  fi

  # If it said "Not building", don't run the tests.
  if [ $NOT_BUILDING_COUNT -eq 0 ]; then 
    # Stagger the boxes before rebooting.
    sleep $REBOOT_DELAY
 
    # Capture serial port data to a log file.
    stty -F $SERIAL_PORT 115200 
    echo -e "cat $SERIAL_PORT > $WORKSPACE/SerialLog${BUILD_NUMBER}${1}.txt &"
    cat $SERIAL_PORT > $WORKSPACE/SerialLog${BUILD_NUMBER}${1}.txt &

    # Reboot the box
    #echo -e "Reboot box $REBOOT_BOX"
    { echo "/Boot ${REBOOT_BOX},Y"; sleep 8; } | telnet 192.168.1.17
    echo -e "Box ${REBOOT_BOX} rebooted."

    # Wait two minutes
    sleep 120
 
    # Get Diagnostics information.
    TEST=$TEST_DIR/DiagInfo.drip
    OUT=$WORKSPACE/DIAGTEST${BUILD_NUMBER}${1}.TXT
    python $DRIP_CLIENT /I $IPADDR /F $TEST >> $OUT
    echo -e "Diagnostics , ${IPADDR} ${BINDADDR} ${TEST}  ${OUT} "

    echo -e "  TEST SUMMARY" | tee -a $CHANTEST_SUMMARY
    echo -e "  All Log Files located at http://dsrjenkins1:8080/job/${JOB_NAME}/ws/*${BUILD_NUMBER}* " | tee -a $CHANTEST_SUMMARY
    echo -e "  Serial Log File at http://dsrjenkins1:8080/job/${JOB_NAME}/ws/SerialLog${BUILD_NUMBER}${1}.txt " | tee -a $CHANTEST_SUMMARY

    # Analyze DiagInfo output file from Drip and post summary.
    $TEST_DIR/DiagInfoResults.sh $OUT $WORKSPACE/DiagInfo_${BUILD_NUMBER}${1}.txt
    DIAG_INFO_ERROR=$?
    if [ $DIAG_INFO_ERROR -eq 1 ]; then
      # If this returns a Failure To Connect error, then do nothing.
      echo "Error reported by DiagInfoResults.sh analysis."
      echo -e " Failed to connect to DRIP" | tee -a $CHANTEST_SUMMARY
      echo -e " No Channel Change Tests Run" | tee -a $CHANTEST_SUMMARY
      ERROR_ALL_TESTS=$DIAG_INFO_ERROR
    else
      # Turn off closed captions.
      TEST=$TEST_DIR/cc_off.drip
      python $DRIP_CLIENT /I $IPADDR /F $TEST 

      # Run the channel change test.
      TEST=$TEST_DIR/ChanChangeTest.drip
      OUT=$WORKSPACE/CHANNELTEST${BUILD_NUMBER}${1}.TXT
      echo -e "Channel Test , ${IPADDR} ${BINDADDR} ${TEST}  ${OUT} "

      if [ "$NEPTUNE_PROJECT_DIR" = "_DSR800_" ]; then
        # If this is an 800, perform this test 100 times
        python $DRIP_CLIENT /I $IPADDR /L 100 /F $TEST >> $OUT
      else 
        # Else, perform this test 30 times.
        python $DRIP_CLIENT /I $IPADDR /L 30 /F $TEST >> $OUT
      fi

      # Analyze channel change test for errors and post Summary.
      $TEST_DIR/ChanTestResults.sh $OUT $CHANTEST_SUMMARY
      CHAN_TEST_ERROR=$?
      echo $CHAN_TEST_ERROR
      if [ $CHAN_TEST_ERROR -eq 5 ]; then
        # If this returns an error of 5 (Num Chan Changes = 0), 
        # report failure.  Else, continue and ignore.
        echo "Error reported by ChanTestResults.sh analysis."
        echo "Num Chan Changes = 0"
        ERROR_ALL_TESTS=$CHAN_TEST_ERROR
      fi

      # If this is an 830, perform DVR Tests
      if [ "$NEPTUNE_PROJECT_DIR" = "_DSR830_" ]; then
        # Turn on closed captions.
        TEST=$TEST_DIR/cc_on.drip
        python $DRIP_CLIENT /I $IPADDR /F $TEST 

        # Record five programs on channel 356.
        TEST=$TEST_DIR/Record.drip
        OUT=$WORKSPACE/RECORD${BUILD_NUMBER}${1}.TXT
        echo -e "Record 5 shows on chan 356 , ${IPADDR} ${BINDADDR} ${TEST}  ${OUT} "
        python $DRIP_CLIENT /I $IPADDR /F $TEST >> $OUT

        # Run the channel change / trick mode combined test.
        TEST=$TEST_DIR/ChanTrick.drip
        OUT=$WORKSPACE/CHANTRICK${BUILD_NUMBER}${1}.TXT
        echo -e "Trick Play Test , ${IPADDR} ${BINDADDR} ${TEST}  ${OUT} "
        python $DRIP_CLIENT /I $IPADDR /L 5 /F $TEST >> $OUT

        # Analyze Channel Trick Play test for errors and post Summary.
        $TEST_DIR/ChanTrickResults.sh $OUT $WORKSPACE/ChanTrick_${BUILD_NUMBER}${1}.txt
        CHAN_TRICK_TEST_ERROR=$?
        echo $CHAN_TRICK_TEST_ERROR
        if [ $CHAN_TRICK_TEST_ERROR -ne 0 ]; then
          # If this returns an error, log the error and continue with tests.
          echo "Error reported by ChanTrickResults.sh analysis."
          # ERROR_ALL_TESTS=$CHAN_TRICK_TEST_ERROR
        fi

        # Perform a STOP, EXIT, DVR.  This will put up the DVR list
        TEST=$TEST_DIR/StopExitDvr.drip
        OUT=$WORKSPACE/STOP_EXIT_DVR${BUILD_NUMBER}${1}.TXT
        echo -e "Stop, Exit, DVR  ${IPADDR} ${BINDADDR} ${TEST}  ${OUT} "
        python $DRIP_CLIENT /I $IPADDR /F $TEST >> $OUT

        # Run the DVR Playback test.
        TEST=$TEST_DIR/DvrPlay.drip
        OUT=$WORKSPACE/DVR_PLAY_TEST${BUILD_NUMBER}${1}.TXT
        echo -e "DVR Playback Test , ${IPADDR} ${BINDADDR} ${TEST}  ${OUT} "
        python $DRIP_CLIENT /I $IPADDR /L 5 /F $TEST >> $OUT

        # Analyze DVR Playback test for errors and post Summary.
        $TEST_DIR/DvrPlayResults.sh $OUT $WORKSPACE/DvrPlay_${BUILD_NUMBER}${1}.txt
        DVR_TEST_ERROR=$?
        echo $DVR_TEST_ERROR
        if [ $DVR_TEST_ERROR -ne 0 ]; then
          # If this returns an error, log the error and continue with tests.
          echo "Error reported by DvrPlayResults.sh analysis."
          # ERROR_ALL_TESTS=$DVR_TEST_ERROR
        fi

        # Perform a STOP, EXIT.  This will put up the normal screen.
        TEST=$TEST_DIR/StopExit.drip
        OUT=$WORKSPACE/STOP_EXIT${BUILD_NUMBER}${1}.TXT
        echo -e "Stop, Exit  ${IPADDR} ${BINDADDR} ${TEST}  ${OUT} "
        python $DRIP_CLIENT /I $IPADDR /F $TEST >> $OUT

      fi

    fi
  else
    echo -e " The ${NEPTUNE_PROJECT_DIR} did not build.  No Tests Run" | tee -a $CHANTEST_SUMMARY
  fi

  # Analyze serial output for SIGSEGV
  SIGSEGV_ERROR=$(grep -c SIGSEGV $WORKSPACE/SerialLog${BUILD_NUMBER}${1}.txt)
  if [ $SIGSEGV_ERROR -ne 0 ]; then
    echo -e " Got a SIGSEGV.  Test Failure!" | tee -a $CHANTEST_SUMMARY
    ERROR_ALL_TESTS=$SIGSEGV_ERROR
  fi

  # Analyze serial output for SIGABRT
  SIGABRT_ERROR=$(grep -c SIGABRT $WORKSPACE/SerialLog${BUILD_NUMBER}${1}.txt)
  if [ $SIGABRT_ERROR -ne 0 ]; then
    echo -e " Got a SIGABRT.  Test Failure!" | tee -a $CHANTEST_SUMMARY
    ERROR_ALL_TESTS=$SIGABRT_ERROR
  fi

  # Print out any Reboot Information
  sed -n '/General Information/,/Register Information/p' $WORKSPACE/SerialLog${BUILD_NUMBER}${1}.txt > temp
  sed -i 's/Register Information/Done/g' temp
  cat temp >>  $CHANTEST_SUMMARY

  # Colate all summaries into a single summary.
  cat $WORKSPACE_BUILDDATA | tee >> $WORKSPACE/TestSummary${BUILD_NUMBER}${1}.txt
  cat $WORKSPACE/DiagInfo_${BUILD_NUMBER}${1}.txt | tee >> $WORKSPACE/TestSummary${BUILD_NUMBER}${1}.txt
  cat $CHANTEST_SUMMARY | tee >> $WORKSPACE/TestSummary${BUILD_NUMBER}${1}.txt
  if [ "$NEPTUNE_PROJECT_DIR" = "_DSR830_" ]; then
    cat $WORKSPACE/ChanTrick_${BUILD_NUMBER}${1}.txt | tee >> $WORKSPACE/TestSummary${BUILD_NUMBER}${1}.txt
    cat $WORKSPACE/DvrPlay_${BUILD_NUMBER}${1}.txt | tee >> $WORKSPACE/TestSummary${BUILD_NUMBER}${1}.txt
  fi

  if [ $ERROR_ALL_TESTS -ne 0 ]; then
    # If any errors, call FastFacts.sh.  The FastFacts.sh is normally called as the last
    # step before Jenkins sends out the e-mail.  But if we exit here with an error, the
    # FastFacts.sh won't get called.  So we call it before exiting with the error.  
    echo -e " Before exiting with the error, run the Fast Facts." 
    $TEST_DIR/FastFacts.sh
  fi

  # Continue with further tests.  Minor errors won't be reported, but major ones will exit with 
  # an error code, and Jenkins will report the test failed.
  exit $ERROR_ALL_TESTS
fi

