#!/bin/bash -ix
#
# CMD Line Arguments
# ------------------
# $1 : workflow mode
#
# name of DUT
FILENAME="INTR_CTRL"

#tcbn65gplus absolute path
TCBN65GPLUS_PATH=/afs/ee.cooper.edu/dist/cadence-tools/tsmc65/TSMCHOME/digital/Front_End/verilog/tcbn65gplus_200a/tcbn65gplus.v

# vcs cmd flags
VCS_FLAGS=(+compsdf +neg_tchk)

SRC=./src
RES=./results
source ~/.bashrc

case $1 in 
    "PRE_SYN")
        printf '\n\t\t\e[1;35m%s\e[m\n' "========== PRE-SYNTHESIS =========="
        vcs $SRC/testbench.v $SRC/${FILENAME}.v ${VCS_FLAGS[@]: 1}
        ./simv
        ;;

    "POST_SYN")
        printf '\n\t\t\e[1;35m%-6s\e[m\n' "========== POST-SYNTHESIS =========="
        dc_shell-xg-t -topographic -x "source ./synthesis.tcl; exit"
        vcs $SRC/testbench.v $RES/${FILENAME}.syn.v $TCBN65GPLUS_PATH ${VCS_FLAGS[@]}
        ./simv
        ;;
    
    "ICC")
        icc2_shell -x "source top_ic_layout.tcl; source optimization.tcl"
        ;;
esac
