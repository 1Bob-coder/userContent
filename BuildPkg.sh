#!/bin/bash
# This builds the package.bin file.
# Exit 1 means: Failure to build.
# Exit 2 means: Did not attempt to build, no changes to branch.

# This function does a "make sdk"
function build_sdk()
{
  WORKSPACE_BUILDDATA=$WORKSPACE/BuildData${NEPTUNE_PROJECT}${BUILD_NUMBER}.txt

  echo -e " Do a make sdk. " | tee -a $WORKSPACE_BUILDDATA
  make sdk
  if [ $? -ne 0 ]; then
    echo -e " !!!make sdk failed!!" | tee -a $WORKSPACE_BUILDDATA
    exit 1
  else
    echo -e " SDK passed."
  fi
  echo -e " No errors. " | tee -a $WORKSPACE_BUILDDATA
}

# This function does a "make bld", "make tstpkg", and "make pkg".
function build_packages()
{
  PKG_DIR=/extra/tftpboot/jenkins/$NEPTUNE_PROJECT
  WORKSPACE_BUILDDATA=$WORKSPACE/BuildData${NEPTUNE_PROJECT}${BUILD_NUMBER}.txt

  echo -e " Do a make bld. " | tee -a $WORKSPACE_BUILDDATA
  make bld
  if [ $? -ne 0 ]; then
    echo -e " !!!make bld failed!!" | tee -a $WORKSPACE_BUILDDATA
    exit 1
  fi

  echo -e " Do a make tstpkg. " | tee -a $WORKSPACE_BUILDDATA
  make tstpkg
  if [ $? -ne 0 ]; then
    echo -e " !!!make tstpkg failed!!" | tee -a $WORKSPACE_BUILDDATA
    exit 1
  else
    echo -e " Copy tst package to the tftpboot directory."
    cp $WORKSPACE/neptune_release/$NEPTUNE_PROJECT/package.bin $PKG_DIR/package_tst.bin
  fi

  echo -e " Do a make pkg. " | tee -a $WORKSPACE_BUILDDATA
  make pkg
  if [ $? -ne 0 ]; then
    echo -e " !!!make pkg failed!!" | tee -a $WORKSPACE_BUILDDATA
    exit 1
  else
    echo -e " Copy package to the tftpboot directory."
    cp $WORKSPACE/neptune_release/$NEPTUNE_PROJECT/package.bin $PKG_DIR/package.bin
  fi

  echo -e " No errors. " | tee -a $WORKSPACE_BUILDDATA
}


# This function does a "make reallyclean"
function make_reallyclean() 
{
  WORKSPACE_BUILDDATA=$WORKSPACE/BuildData${NEPTUNE_PROJECT}${BUILD_NUMBER}.txt

  echo -e " Do a reallyclean. " | tee -a $WORKSPACE_BUILDDATA
  make reallyclean
  if [ $? -ne 0 ]; then
    echo -e " !!!make reallyclean failed!!" | tee -a $WORKSPACE_BUILDDATA
    exit 1
  fi
}


# This function does a "make cleanbld"
function make_cleanbld() 
{
  WORKSPACE_BUILDDATA=$WORKSPACE/BuildData${NEPTUNE_PROJECT}${BUILD_NUMBER}.txt

  echo -e " Do a cleanbld. " | tee -a $WORKSPACE_BUILDDATA
  make cleanbld
  if [ $? -ne 0 ]; then
    echo -e " !!!make cleanbld failed!!" | tee -a $WORKSPACE_BUILDDATA
    exit 1
  fi
}


function create_builddata() 
{
  PKG_DIR=/extra/tftpboot/jenkins/$NEPTUNE_PROJECT

  PKG_BUILD_TAG=$(git describe) 

  # Create BuildData file with useful info
  echo -e "*******************************" | tee -a $WORKSPACE_BUILDDATA
  echo -e "BuildData for Code Under Test: " | tee -a $WORKSPACE_BUILDDATA
  echo -e "  Product = ${NEPTUNE_PROJECT}" | tee -a $WORKSPACE_BUILDDATA
  echo -e "  GIT Tag = ${PKG_BUILD_TAG}" | tee -a $WORKSPACE_BUILDDATA
  echo -e "  GIT Branch = ${GIT_BRANCH}" | tee -a $WORKSPACE_BUILDDATA
  echo -e "  Build URL = ${BUILD_URL}" | tee -a $WORKSPACE_BUILDDATA
  echo -e "  All Log Files located at http://dsrjenkins1:8080/job/${JOB_NAME}/ws/*${BUILD_NUMBER}* " | tee -a $WORKSPACE_BUILDDATA
  echo -e "*******************************" | tee -a $WORKSPACE_BUILDDATA

  rm -f $PKG_DIR/BuildData*.txt 
  cp $WORKSPACE_BUILDDATA $PKG_DIR/BuildData.txt
}

if [ $# -ne 1 ]; then
  echo "format is:  BuildPkg.sh SourceFile"
  exit 1
fi


  echo "Remove files older than 25 days"
  find -f $WORKSPACE -mtime +25 -exec rm {} \;

  cd $WORKSPACE
  source $1

  # Log the key build data results in the following file.
  WORKSPACE_BUILDDATA=$WORKSPACE/BuildData${NEPTUNE_PROJECT}${BUILD_NUMBER}.txt
  echo -e " Building NEPTUNE_PROJECT = ${NEPTUNE_PROJECT}" | tee -a $WORKSPACE_BUILDDATA
  
  # Check if this is the /genesis branch.  
  if [[ ${GIT_BRANCH} = *"/genesis"* ]]; then
    echo -e "This is a /genesis Branch, rebuild everything." | tee -a $WORKSPACE_BUILDDATA
    make_reallyclean
    build_packages
    make_cleanbld
    build_packages
    build_sdk
    create_builddata
    exit 0
  fi

  # Check if this is the /int branch.  
  if [[ ${GIT_BRANCH} = *"/int"* ]]; then
    echo -e "This is a /int Branch, rebuild everything." | tee -a $WORKSPACE_BUILDDATA
    make_reallyclean
    build_packages
    make_cleanbld
    build_packages
    build_sdk
    create_builddata
    exit 0
  fi

  # Check if this has any changes in the stream.
  if [ "$GIT_COMMIT" = "$GIT_PREVIOUS_COMMIT" ]; then
    #echo -e " No Changes in Stream ${GIT_BRANCH}." | tee -a $WORKSPACE_BUILDDATA
    echo -e " No Changes in Stream ${GIT_BRANCH}. Rebuilding anyway." | tee -a $WORKSPACE_BUILDDATA
    make_cleanbld
    build_packages
    build_sdk
    create_builddata
    exit 0
  else
    echo -e " Git Changes in Stream ${GIT_BRANCH}. Rebuilding ..." | tee -a $WORKSPACE_BUILDDATA
    make_cleanbld
    build_packages
    build_sdk
    create_builddata
    exit 0
  fi

  # Check if file package.bin does not exist.  If it does not exist, rebuild.
  if [ ! -f $WORKSPACE/neptune_release/${NEPTUNE_PROJECT}/package.bin ]; then
    echo -e " No package.bin in ${NEPTUNE_PROJECT}." | tee -a $WORKSPACE_BUILDDATA
    make_cleanbld
    build_packages
    build_sdk
    create_builddata
    exit 0
  fi

  echo -e " Not building ${NEPTUNE_PROJECT}, just copying package.bin and build data." | tee -a $WORKSPACE_BUILDDATA
  create_builddata
  PKG_DIR=/extra/tftpboot/jenkins/$NEPTUNE_PROJECT
  cp $WORKSPACE/neptune_release/$NEPTUNE_PROJECT/package.bin $PKG_DIR/package.bin
