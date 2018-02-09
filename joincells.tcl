#!/usr/bin/env tclsh
# read input files
mol new {solid.xyz} type xyz waitfor all
mol rename top {solid}
mol new {liquid.xyz} type xyz waitfor all
mol rename top {liquid}

# read PBC
set fp [open PBC.dat r]
set mypbc {}
set file_data [read $fp]
close $fp
lappend mypbc $file_data
pbc set $mypbc
