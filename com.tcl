# COM and weighted come of a sel of molecules
# This is part of VMD-Toolbox
#
proc ::Toolbox::com {sel} {
    ## $sel should be already set by the caller!
    #if { $sel == "all" } {
    #    puts "COM will be calculated for all particles of top molecule"
    #    set sel [atomselect top all]
    #}
    # set the center of mass to 0
    set com [veczero]
    # set the total mass to 0
    set mass 0
    # [$sel get {x y z}] returns the coordinates {x y z} 
    # [$sel get {mass}] returns the masses
    # so the following says "for each pair of {coordinates} and masses,
    # do the computation ..."
    foreach coord [$sel get {x y z}] m [$sel get mass] {
       # sum of the masses
       set mass [expr $mass + $m]
       # sum up the product of mass and coordinate
       set com [vecadd $com [vecscale $m $coord]]
    }
    # and scale by the inverse of the number of atoms
    if {$mass == 0} {
            error "center_of_mass: total mass is zero"
    }
    # The "1.0" can't be "1", since otherwise integer division is done
    return [vecscale [expr 1.0/$mass] $com]
}

# for the following to work, the weights must be loaded as the beta parameter (for example, with proc beta_load)
proc ::Toolbox::wcom {sel tresh} {
    #if { $tresh == {} } { vmdcon -info "Treshold empty == 0.0" ; set tresh 0.0 } else { vmdcon -info "Treshold on weight: $tresh"}
    #if { $sel == {} || $sel == "all" } {
    #    vmdcon -info "Weighted COM will be calculated for all particles of top molecule"
    #    set sel [atomselect top all]
    #}
    set com [veczero]
    set mass 0
    # the beta factor
    foreach coord [$sel get {x y z}] m [$sel get beta] {
        if { $m >= $tresh } {
        set mass [expr $mass + $m]
        set com [vecadd $com [vecscale $m $coord]]
    }
    }
    if { $mass == 0 } { vmdcon -err "Sum of weights is zero! Have you loaded the beta parameter?" }
    return [vecscale [expr 1.0/$mass] $com]
}
