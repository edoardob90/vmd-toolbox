#!/usr/bin/tclsh
# A set of utility scripts to be used in VMD
# This is a work in progress
#
# Huge thank goes to Axel Kohlmeyer <akohlmey@gmail.com>
# for his work with TopoTools which inspired this set of scripts
#
# Author: Edoardo Baldi
#
# Started on: 8 february 2018
#
#
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
    vmdcon -info "      com     compute the center of mass of selection"
    vmdcon -info "      wcom    compute the weighted center of mass using beta factor as weight"
    vmdcon -info "      loadvarpbc      load PBC from comment line of trajectory (only for XYZ)"
    #vmdcon -info "      betaload \[<field>\]    load the value of the extra field (default 4th) as beta parameter"
    vmdcon -info "      getcompositions \[<com|wcom>\]"
    vmdcon -info "          estimate the composition of the elements in selection"
    vmdcon -info "          with option 'com' the origin will be the normal COM; with 'wcom' a weighted COM will be used"
    vmdcon -info "      moveby  <offset>    rigid shift of the current selection by the OFFSET vector"
    return
}

proc ::Toolbox::toolbox {args} {

    # variables declaration
    set molid -1
    set seltxt all
    set localsel 1
    set selmol -1

    set newargs {}
    set sel {}
    set cmd {}

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
                        set localsel 0
                        set selmol [$val molid]
                        set sel $val
                    } else {
                        set localsel 1
                        set seltxt $val
                    }
                    incr i
                }
            }
        } else {
            lappend newargs $arg
        }
    }

    if {$molid < 0} {
        set molid $selmol
    }
    if {$molid < 0} {
        set molid [molinfo top]
    }

    # check for valid subcommands
    set retval ""
    if {[llength $newargs] > 0} {
        set cmd [lindex $newargs 0]
        set newargs [lrange $newargs 1 end]
    } else {
        set newargs {}
        set cmd help
    }

    # list of valid subcommands
    # !!! TODO: betaload removed; it doesn't work properly when asking VMD to update color every frame
    set validcmd {com wcom loadvarpbc getcompositions moveby help}
    if {[lsearch -exact $validcmd $cmd] < 0} {
        vmdcon -err "Unknown subcommand '$cmd'"
        usage
        return
    }


    # check that molid and sel are properly set
    if { ![string equal $cmd help] } {
        if {($selmol >= 0) && ($selmol != $molid)} {
            vmdcon -err "Molid from selection '$selmol' does not match -molid argument '$molid'"
            return
        }
        if {$molid < 0} {
            vmdcon -err "Cannot use '$cmd' without a molecule"
            return
        }

        if {$localsel} {
            # need to create a selection
            if {[catch {atomselect $molid $seltxt} sel]} {
                vmdcon -err "Problem with atom selection using '$seltxt': $sel"
                return
            }
        }
    }

    # the actual subcommands
    switch -- $cmd {
        com {
            set retval [com $sel]
        }

        wcom {
            if {[llength $newargs] < 1} {
                set tresh 0.0
                vmdcon -info "Zero or no treshold given. It will be 0.0"
                set retval [wcom $sel $tresh]
            } else {
                set retval [wcom $sel [lindex $newargs 0]]
            }
        }

        loadvarpbc {
            set retval [loadvarpbc $molid]
        }

        betaload {
            # check if XYZ file
            if {[molinfo $molid get filetype] != "xyz"} { vmdcon -err "Selected mol. $molid is not an XYZ file" }
            # TODO: update beta on frame change: I don't actually now if the old way works
            # array declaration here for scoping
            array set xprop {}
            array set xnfr {}
            array set xnat {}
            if {[llength $newargs] < 1} {
                set field 4
                set retval [beta_load $molid $sel $field]
            } else {
                set retval [beta_load $molid $sel [lindex $newargs 0]]
            }
            # ask VMD to update the command when the frame changes
            vmdcon -warn "To update color every frame do:\n   trace add variable vmd_frame($molid) write beta_set_all"
        }

        moveby {
            if {[llength $newargs] < 1} { 
                vmdcon -err "Command 'moveby' requires an OFFSET vector"
            } else {
                set retval [moveby $sel [lindex $newargs 0]]
            }
        }

        getcompositions {
            set style com
            # TODO : include selection relative to COM or WCOM
            #if {[llength $newargs] > 1} {
            #    set style [lindex $newargs 1]
            #    if { ![string equal $style wcom] } {
            #        vmdcon -err "Switch of 'getcompositions' can be COM (default) or WCOM"
            #        usage
            #        return
            #    }
            #}
            set retval [getcompositions $molid $sel]
        }

        help -
        default {
            usage
        }
    }
    if {$localsel && ($sel != "")} {
        $sel delete
    }

    return $retval
}

# short stuff
proc ::Toolbox::moveby { sel offset } {
    set newcoords {}
    foreach coord [$sel get {x y z}] {
      lvarpush newcoords [vecadd $coord $offset]
    }
    $sel set $newcoords
    return
}

# load actual commands' scripts
source "~/scripts/vmd/load_pbc_xyz.tcl"
source "~/scripts/vmd/com.tcl"
# TODO: module beta_color doesn't work. see above.
#source "~/scripts/vmd/beta_color.tcl"
source "~/scripts/vmd/beta_color_standalone.tcl"

# alias
interp alias {} toolbox {} ::Toolbox::toolbox

# package info
package provide vmd-toolbox $::Toolbox::version
