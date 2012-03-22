#!/bin/bash

# NOTE: the options for diff should be after the two filenames
RM_LINE=$PORT_ROOT/tools/rmline.sh

$RM_LINE $1
$RM_LINE $2
# -B -u
diff $*
$RM_LINE -r $1
$RM_LINE -r $2
