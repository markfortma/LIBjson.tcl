#!/usr/bin/env tclsh

source "../LIBjson.tcl"

set doclen 0
puts "doclen => $doclen"
set samfile [open "ctrl.json"]
puts "opened sample JSON file"
set sample [read $samfile]
puts "read sample JSON file, length: [tell $samfile]"
close $samfile
puts "closed"
set ::docend [string length $sample]
set lexemes [json_lexer $sample doclen]
puts "doclen => $doclen"
puts "lexemes=> [llength $lexemes]"

for {set i 0} {$i < [llength $lexemes]} {incr i} {
    puts "index: $i has [lindex $lexemes $i]"
}

exit 0
