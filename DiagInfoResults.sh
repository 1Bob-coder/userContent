#!/bin/bash
# This prints out the DRIP Diag Info results to a more readable file.
if [ $# -ne 2 ]; then
  echo "format is:  DiagInfoResults.sh input.txt output.txt" | tee >> $2
  exit 1
else
  echo "*******************************" | tee >> $2
  echo "Diagnostics Data:" | tee >> $2
  # Report on just the product string and the Neptune Version from Diag A.
  grep ProdStr $1 | awk '{print $2 " " $3 " " $4}' | tee >> $2
  grep NepVer $1 | awk '{print $2 $3 $4 " " $5 " " $6}' | tee >> $2
  NEP_VER=$(grep -c NepVer $1)
  if [ $NEP_VER -eq 0 ]; then
    echo "  Failed to connect" | tee >> $2
    echo "*******************************" | tee >> $2
    exit 1
  fi
fi
echo "*******************************" | tee >> $2
