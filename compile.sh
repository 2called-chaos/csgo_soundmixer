#!/bin/bash
set -e
FILES="csgo_soundmixer csgo_smix_test"

for SPFILE in $FILES
do
  echo -e "\n>>>>>>>>COMP>>>>>>>> $SPFILE.sp"
  ../scripting/spcomp \
    -i addons/sourcemod/scripting/include \
    -i ../scripting/include \
    -o addons/sourcemod/plugins/$SPFILE.smx \
    addons/sourcemod/scripting/$SPFILE.sp
done
