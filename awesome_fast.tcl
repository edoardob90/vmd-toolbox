mol new {q4_op.xyz} type xyz waitfor all
mol delrep 0 top
mol representation CPK 1.000000 5.000000
mol color Charge
mol selection {all}
mol material Opaque
mol addrep top
mol rename top {gete}
set topmol [molinfo top]
mol top $topmol
unset topmol
pbc set { TO BE CHANGED BY HAND! e.g. 10.0 10.0 10.0 } -all
pbc box -color yellow
pbc wrap -all
set molid 0
set n [molinfo $molid get numframes]
puts "reading charges"
set fp [open "q4_op.dat" r]
for {set i 0} {$i < $n} {incr i} {
    set chrg($i) [gets $fp]
}
close $fp

proc do_charge {args} {
   global chrg molid
   set f [molinfo $molid get frame]
   set s [atomselect 0 "all"]
   $s set user $chrg($f)
   $s delete
}

trace variable vmd_frame($molid) w do_charge

mol colupdate   0 $molid on
mol scaleminmax 0 $molid 0.0 0.7
color scale method RGB
color scale midpoint 0.25
color scale min 0.0
color scale max 0.7

animate goto start
do_charge
