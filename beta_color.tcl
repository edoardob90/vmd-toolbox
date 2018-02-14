# module to encode in BETA information contained in the XYZ file as additional fields
# if molecule I has been loaded from file.xyz where the Jth column contains the property
# to plot, one should call beta_load J I to scan the file and store the data into a work
# array
# from there on, every time a frame is selected, the BETA value for the atoms will be set
# to the one read from the file. update can be forced with beta_set_all
#
# this version belongs to VMD-toolbox. Check the standalone version to avoid loading VMD-toolbox
#
# set beta value for a molecule (DOES NOT CHECK IF DATA ACTUALLY EXISTS!)
proc ::Toolbox::beta_set { molid sel } {
    global xprop
    global xnfr
    global xnat
    set frame [molinfo $molid get frame]
    set nat [molinfo $molid get numatoms]
    if { $frame >= $xnfr($molid) } {
      vmdcon -err "Extended data not loaded for frame $frame"
    }
    if { $nat != $xnat($molid)} {
      vmdcon -err "Atoms number in molecule and in extended properties mismatch."
    }
    vmdcon -info "Setting frame data for mol. $molid"
    $sel set beta $xprop($molid,$frame)
    #$sel delete
    return
}

# function to trace beta value upon frame change
# TODO : this doesn't seem to work with vmd trace command
proc ::Toolbox::beta_set_all {args} {
    global xnfr
    global molid
    global sel
    if {[ info exists xnfr($molid)] > 0 } {
        vmdcon -info "Re-setting beta for mol. $molid"
        beta_set $molid $sel
    }
    return
}


#loads the selected field for the given molecule id (default 4 and "top")
proc ::Toolbox::beta_load {molid sel field} {
    global xprop
    global xnfr
    global xnat

    #gets molecule info
    set fname [molinfo $molid get filename]
    set nframes [molinfo $molid get numframes]
    set nat [molinfo $molid get numatoms]
    set xnfr($molid) $nframes
    set xnat($molid) $nat

    vmdcon -info "Reading extra field $field from $fname (molecule $molid)"
    set myfile [ open $fname ]

    for {set iframe 0}  {$iframe< $nframes} { incr iframe } {
      #reads frame by frame and prepares an array with the 
      #extra property (col. 5 in XYZ file) for each frame
      set xprop($molid,$iframe) {}
      vmdcon -info "Reading frame $iframe"
      set line [ gets $myfile ]
      if { $line != $nat } {
        vmdcon -err "Format error in reading XYZ* file"
      }
      set line [ gets $myfile ]
      for { set at 0 } {$at<$nat} {incr at} {
        set line [ gets $myfile ]
        lappend xprop($molid,$iframe) [ lindex $line $field ]
      }
    }
    close $myfile
    beta_set $molid $sel
    return
}
