#!/usr/bin/tclsh
# A set of utility scripts to be used in VMD
# This is a work in progress
#
# Author: Edoardo Baldi
#
# Started on: 8 february 2018
#
#
package provide vmd-toolbox
# a couple of utilities requires topotools & pbctools here
package require topotools 1.7
package require pbctools 2.8

namespace eval ::Toolbox:: {
    # version & date
    variable date "08 feb 2018"
    variable version 1.0
    # maybe some fuction to export
    # export ...
}

proc ::Toolbox::usage {} {
    vmdcon -info "usage: toolbox <common flags> <subcommand> \[args...\] <flags>"
    vmdcon -info ""
    vmdcon -info "common flags:"
    vmdcon -info "  -molid     <num>|top    molecule id (default: 'top')"
    vmdcon -info "  -sel       <selection>  atom selection function or text (default: 'all')"
    vmdcon -info ""
    vmdcon -info "commands available:"
    vmdcon -info "      center_of_mass          compute the center of mass of selection"
    vmdcon -info "      weighted_com            compute the weighted center of mass"
    vmdcon -info "      load_pbc_xyz            load PBC from comment line of trajectory (only for XYZ files)"
    vmdcon -info "      get_compositions <range> com|wcom"
    vmdcon -info "          estimate the composition of the elements in the region specified by the range list"
    vmdcon -info "          With option 'com' the origin will be the normal COM, with 'wcom' a weighted COM will be used"
    return
}

proc ::Toolbox::toolbox {args} {
    for {set i 0} {$i < [llength $args]} {incr i} {
        set arg [lindex $args $i]

        if {[string match -?* $arg]} {

            set val [lindex $args [expr $i+1]]

            switch -- $arg {
                -molid {
                    if {[catch {molinfo $val get name} res]} {
                        vmdcon -err "Invalid -molid argument '$val': $res"
                        return
                    }
                    set molid $val
                    if {[string equal $molid "top"]} {
                        set molid [molinfo top]
                    }
                    incr i
                }

                -sel {
                    # check if the argument to -sel is a valid atomselect command
                    if {([info commands $val] != "") && ([string equal -length 10 $val atomselect])} {
                        #set localsel 0
                        set selmol [$val molid]
                        set sel $val
                    } else {
                        #set localsel 1
                        set seltxt $val
                    }
                    incr i
                }

                -range {
                    # range
                    if {[llength $val] < 3} {
                        vmdcon -err "Invalid -range argument '$val': 3 arguments needed"
                    } else {
                        vmdcon -info "Okay, buddy, range is '$val'"
                    }
                }
            }
        }
    }
    return
}

# stuff already written in separate files
#   - load_pbc_xyz (renamed)
#   - COM
#   - beta_color (to be included)
source "~/scripts/vmd/load_pbc_xyz.tcl"
source "~/scripts/vmd/com.tcl"

# alias
interp alias {} toolbox {} ::Toolbox::toolbox
