#!/usr/bin/env tclsh

source "../LIBjson.tcl"

proc testlexemes {} {
    set doclen 0
    puts "doclen => $doclen"
    set samfile [open "ctrl_pp.json"]
    puts "opened sample JSON file"
    set sample [read $samfile]
    puts "read sample JSON file, length: [tell $samfile]"
    close $samfile
    puts "closed"
    set lexemes [json_lexer $sample doclen]
    puts "doclen => $doclen"
    puts "lexemes=> [llength $lexemes]"

    for {set i 0} {$i < [llength $lexemes]} {incr i} {
	puts "index: $i has [lindex $lexemes $i]"
    }
}

proc testparse {} {
    set doclen 0
    set samfile [open "ctrl.json"]
    set sample [read $samfile]
    close $samfile

    set lexemes [json_lexer $sample doclen]
    for {set x 0} {$x < [llength $lexemes]} {incr x} {
	puts "lexeme index $x -> [lindex $lexemes $x]"
    }
    set doclen 0
    set json_object [json_parse $lexemes]
    puts "json_object => $json_object"
}

testparse
    
exit 0
