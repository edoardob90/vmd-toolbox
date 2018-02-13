#!/usr/bin/tclsh
# Script to load PBC cell size from an XYZ trajectory
# Currectly VMD ignores the 2nd header line in a XYZ trajectory
# This script is part of VMD-Toolbox
#
# Author: Edoardo Baldi
#
proc ::Toolbox::loadvarpbc {molid} {
    if { [molinfo $molid get filetype] != "xyz" } { vmdcon -err "Selected molecule is not XYZ" }
    set fname [molinfo $molid get filename]
    set nframes [molinfo $molid get numframes]
    set nat [molinfo $molid get numatoms]

    #puts "  Reading file $fname of molecule $molid"
    set myfile [open $fname r]

    # set current molecule as "top" and rewind trajectory
    mol top $molid
    animate goto start
    for {set iframe 0} {$iframe < $nframes} {incr iframe} {
        #puts "  Reading frame $iframe of $fname"
        if { [gets $myfile] != $nat } { vmdcon -err "XYZ file formatting. Check the header" }
        # this is the 2nd header line containing PBCs
        set pbcstring [gets $myfile]
        animate goto $iframe
        pbc set [format "{%s}" $pbcstring] -molid $molid
        pbc wrap -molid $molid
        # TODO: maybe next step is a bit "stupid" and for big trajectories expensive
        # skip lines until next frame
        for { set at 0 } {$at<$nat} {incr at} { gets $myfile }
    }
    pbc box -color yellow
    close $myfile
    return
}
