#!/bin/bash
# This runs all tests on the specified box.  The input parameter is a specified
# Jenkins test box (1-4).  This runs the following Drip tests:
# 1) Reboot the box.
# 2) Get Diag A info on hardware type and Neptune version.
# 3) Perform a channel change test.

if [ $# -ne 1 ]; then
  echo "format is:  SmokeTest.sh BOXn -- where n is a number 1,2,3,or 4"
  exit 1
else
  echo "box is ${1}"
  if [ "$1" = "BOX1" ]; then
    IPADDR=$IP_DSR830_1
    NEPTUNE_PROJECT_DIR=_DSR830_
    SERIAL_PORT=/dev/ttyUSB0
    REBOOT_BOX=1
  elif [ "$1" = "BOX2" ]; then
    IPADDR=$IP_DSR830_2
    NEPTUNE_PROJECT_DIR=_DSR830_
    SERIAL_PORT=/dev/ttyUSB1
    REBOOT_BOX=2
  elif [ "$1" = "BOX3" ]; then
    IPADDR=$IP_DSR830_3
    NEPTUNE_PROJECT_DIR=_DSR830_
    SERIAL_PORT=/dev/ttyUSB2
    REBOOT_BOX=3
  elif [ "$1" = "BOX4" ]; then
    IPADDR=$IP_DSR800_4
    NEPTUNE_PROJECT_DIR=_DSR800_
    SERIAL_PORT=/dev/ttyUSB3
    REBOOT_BOX=4
  elif [ "$1" = "BOX5" ]; then
    IPADDR=$IP_DSR800_5
    NEPTUNE_PROJECT_DIR=_DSR800_
    SERIAL_PORT=/dev/ttyUSB4
    REBOOT_BOX=5
  elif [ "$1" = "BOX6" ]; then
    IPADDR=$IP_DSR800_6
    NEPTUNE_PROJECT_DIR=_DSR800_
    SERIAL_PORT=/dev/ttyUSB5
    REBOOT_BOX=6
  else 
    echo " ERROR - boxn : ${1} not understood"
    exit 1
  fi

  DIR_COPY_FROM=/extra/tftpboot/jenkins/$NEPTUNE_PROJECT_DIR
  DIR_COPY_BOXN=/extra/tftpboot/jenkins/$1/$NEPTUNE_PROJECT_DIR

  # copy package.bin from the tftpboot directory to the boxn directory.
  rm -f $DIR_COPY_BOXN/package.bin
  cp $DIR_COPY_FROM/package.bin $DIR_COPY_BOXN/package.bin
  cp $DIR_COPY_FROM/package_tst.bin $DIR_COPY_BOXN/package_tst.bin

  WORKSPACE_BUILDDATA=$WORKSPACE/BuildData${NEPTUNE_PROJECT_DIR}${BUILD_NUMBER}.txt

  # copy BuildData.txt to boxn directory and workspace
  rm -f $DIR_COPY_BOXN/BuildData.txt
  rm -f $WORKSPACE/BuildData.txt
  cp $DIR_COPY_FROM/BuildData.txt $DIR_COPY_BOXN/BuildData.txt
  cp $DIR_COPY_FROM/BuildData.txt $WORKSPACE_BUILDDATA

  # Are there any branches that we don't want to test?  Temporary hard-coded value.
  SKIP_TEST=$(grep -c OKDSR8XX-1147 BuildData${NEPTUNE_PROJECT_DIR}${BUILD_NUMBER}.txt)
  if [ $SKIP_TEST -ne 0 ]; then
    echo -e " Special branch to skip testing." | tee -a $WORKSPACE/ChanTestSummary${BUILD_NUMBER}${1}.txt 
  fi

  # Check to see if the BuildData_DSRxxx_nn.txt file said "Not building".
  NOT_BUILDING_COUNT=$(grep -c Not.building BuildData${NEPTUNE_PROJECT_DIR}${BUILD_NUMBER}.txt)
  if [ $NOT_BUILDING_COUNT -ne 0 ]; then 
    echo " Branch was not built." | tee -a $WORKSPACE/ChanTestSummary${BUILD_NUMBER}${1}.txt 
    # For now, force a "Not Building" branch to perform tests.
    NOT_BUILDING_COUNT=1
  fi

  TEST_DIR=$JENKINS_HOME/userContent

  # If it said "Not building", or "Skip Test", then don't run the tests.
  if [ $NOT_BUILDING_COUNT -ne 0 ] || [ $SKIP_TEST -ne 0 ] ; then 
    echo -e " Skip tests for this branch." | tee -a $WORKSPACE/ChanTestSummary${BUILD_NUMBER}${1}.txt 
  else
    # Reboot the box
    { echo "/Boot ${REBOOT_BOX},Y"; sleep 8; } | telnet 192.168.1.17
    echo -e "Reboot Box ${REBOOT_BOX} "
    echo -e "Box ${REBOOT_BOX} rebooted."

    # Capture serial port data to a log file.
    stty -F $SERIAL_PORT 115200 
    echo -e "cat $SERIAL_PORT > $WORKSPACE/SerialLog${BUILD_NUMBER}${1}.txt &"
    cat $SERIAL_PORT > $WORKSPACE/SerialLog${BUILD_NUMBER}${1}.txt &
 
    # Wait two minutes
    sleep 120

    # remove package.bin from the boxn directory.
    echo -e "Remove file, ${DIR_COPY_BOXN}/package.bin"
    rm -f $DIR_COPY_BOXN/package.bin
    echo -e "And copy test package file, ${DIR_COPY_BOXN}/package.bin"
    cp $DIR_COPY_BOXN/package_tst.bin $DIR_COPY_BOXN/package.bin

    ERROR_ALL_TESTS=0

    # Get Diagnostics information.
    TEST=$TEST_DIR/DiagInfo.drip
    OUT=$WORKSPACE/DIAGTEST${BUILD_NUMBER}${1}.TXT
    python ${JENKINS_HOME}/userContent/DripClient.py /I $IPADDR /F $TEST >> $OUT
    echo -e "Diagnostics , ${DRIP_CLIENT} ${IPADDR} ${BINDADDR} ${TEST}  ${OUT} "

    # Analyze DiagInfo output file from Drip and post summary.
    $TEST_DIR/DiagInfoResults.sh $OUT $WORKSPACE/DiagInfo${BUILD_NUMBER}${1}.txt
    DIAG_INFO_ERROR=$?
    if [ $DIAG_INFO_ERROR -eq 1 ]; then
      # If this returns a Failure To Connect error, then do nothing.
      echo "Error reported by DiagInfoResults.sh analysis."
      echo -e " No Channel Change Tests Run" | tee -a $WORKSPACE/ChanTestSummary${BUILD_NUMBER}${1}.txt 
      ERROR_ALL_TESTS=$DIAG_INFO_ERROR
    else
      # Turn on small closed captions.
      TEST=$TEST_DIR/cc_on.drip
      python ${JENKINS_HOME}/userContent/DripClient.py /I $IPADDR /F $TEST 

      # Run the channel change test.
      TEST=$TEST_DIR/ChanChangeTest.drip
      OUT=$WORKSPACE/CHANNELTEST${BUILD_NUMBER}${1}.TXT
      echo -e "Channel Test , ${DRIP_CLIENT} ${IPADDR} ${BINDADDR} ${TEST}  ${OUT} "
      python ${JENKINS_HOME}/userContent/DripClient.py /I $IPADDR /F $TEST >> $OUT

      # Analyze channel change test for errors and post Summary.
      $TEST_DIR/ChanTestResults.sh $OUT $WORKSPACE/ChanTestSummary${BUILD_NUMBER}${1}.txt
      CHAN_TEST_ERROR=$?
      echo $CHAN_TEST_ERROR
      if [ $CHAN_TEST_ERROR -ne 0 ]; then
        # If this returns an error, log the error and continue with tests.
        echo "Error reported by ChanTestResults.sh analysis."
        #ERROR_ALL_TESTS=$CHAN_TEST_ERROR
      fi
    fi
  fi

  # Analyze serial output for SIGSEGV
  SIGSEGV_ERROR=$(grep -c SIGSEGV $WORKSPACE/SerialLog${BUILD_NUMBER}${1}.txt)
  if [ $SIGSEGV_ERROR -ne 0 ]; then
    echo -e " Got a SIGSEGV.  Test Failure!" | tee -a $WORKSPACE/ChanTestSummary${BUILD_NUMBER}${1}.txt 
    ERROR_ALL_TESTS=$SIGSEGV_ERROR
  fi

  # Analyze serial output for SIGABRT
  SIGABRT_ERROR=$(grep -c SIGABRT $WORKSPACE/SerialLog${BUILD_NUMBER}${1}.txt)
  if [ $SIGABRT_ERROR -ne 0 ]; then
    echo -e " Got a SIGABRT.  Test Failure!" | tee -a $WORKSPACE/ChanTestSummary${BUILD_NUMBER}${1}.txt 
    ERROR_ALL_TESTS=$SIGABRT_ERROR
  fi

  # Print out any Reboot Information
  sed -n '/General Information/,/Register Information/p' $WORKSPACE/SerialLog${BUILD_NUMBER}${1}.txt > temp
  sed -i 's/Register Information/Done/g' temp
  cat temp >>  $WORKSPACE/ChanTestSummary${BUILD_NUMBER}${1}.txt 

  # Colate all summaries into a single summary.
  cat $WORKSPACE_BUILDDATA | tee >> $WORKSPACE/TestSummary${BUILD_NUMBER}${1}.txt
  cat $WORKSPACE/DiagInfo${BUILD_NUMBER}${1}.txt | tee >> $WORKSPACE/TestSummary${BUILD_NUMBER}${1}.txt
  cat $WORKSPACE/ChanTestSummary${BUILD_NUMBER}${1}.txt | tee >> $WORKSPACE/TestSummary${BUILD_NUMBER}${1}.txt

  # Continue with further tests, and don't report back the error.  This is so
  # Jenkins will keep building and testing the next branch and not halt.
  exit $ERROR_ALL_TESTS
fi

