#!/usr/bin/env tclsh

#
# @author    Matt Markfort <matthew.markfort@gmail.com>
# @date      2019-04-10
# @info
# The script that follows is intended for use in a BIG-IP platform
#

# The maximum depth of recursion
# How many nested levels within a JSON structure
set ::maxdepth 100

# The maximum length in characters
# This could infer how many bytes since (generally) one byte represents
# one character in ASCII or UTF8
set ::maxlength 4096

# The maximum time the processor should work on serializing the JSON
# structure for Tcl interpretation
set ::maxtime 2

set ::actionatthreshold "return"

proc lpop {target} {
    # always call as "set end [lpop collection]"
    # removed end value from collection
    # return end value or empty list, if unable/unsuccessful
    upvar 1 $target collection
    set last {}
    if { [llength $collection] > 0 } {
	set last [lindex $collection end]
	set collection [lrange $collection 0 end-1]
    }
    return $last
}

proc json_numeric_create {document at} {
    set numeric 0
    upvar 1 $at doclen
    if { [string length $document] > 0 } {
	if { [regexp -nocase -- {(\s*)(-?(?:[0-9]*)(?:[.]?[0-9]*)(?:e?[+\-]?[0-9]+))} $document groups space value] != 0 } {
	    incr doclen [expr [string length $groups] - 1]
	    set numeric $value
	}
    }
    return $numeric
}

proc json_literal_create {document at} {
    set literal ""
    upvar 1 $at doclen
    if { [string length $document] > 0 } {
	if { [regexp -nocase -- {(\s*)\"(\\[\"bfnrt\\]|\\u[0-9a-f]{4}|[^\"\b\f\n\r\t\\])*\"} $document groups space value] != 0 } {
	    incr doclen [expr [string length $groups] - 1]
	    # Set the literal to be the substring, excluding double quotes
	    set literal [string range $groups [expr [string length $space] + 1] end-1]
	}
    }
    return $literal
}

proc json_boolean_create {document at} {
    set boolean ""
    upvar 1 $at doclen
    if { [string length $document] > 0 } {
	if { [regexp -nocase -- {(\s*)(true|false|null)} $document groups space value] != 0 } {
	    incr doclen [expr [string length $groups] - 1]
	    set boolean $value
	}
    }
    return $boolean
}

proc json_parse {lexemes} {
    set json_array {}
    set stack {}
    set keystack {}
    set lastkey {}
    set count 0
    set length [llength $lexemes]
    if { [string equal [lindex $lexemes 0] "\{"] == 1 && [string equal [lindex $lexemes end] "\}"] == 0 } {
	error "Invalid JSON object"
    } elseif { [string equal [lindex $lexemes 0] "\["] == 1 && [string equal [lindex $lexemes end] "\]"] == 0 } {
	error "Invalid JSON list"
    } else {
	incr count
	incr length -1
    }
    while { $count < $length } {
	set token [lindex $lexemes $count]
	switch -- $token {
	    "\{" -
	    "\[" {
		lappend stack $json_array
		lappend keystack [lpop json_array]
		set json_array {}
	    }
	    "\}" -
	    "\]" {
		set parent [lpop stack]
		lappend parent $json_array
		set json_array $parent

	    }
	    ":" {
		# Last element was a key
		set lastkey [lindex $lexemes [expr $count - 1]]
	    }
	    "," {
	        set lastkey {}
	    }
	    default {
		lappend json_array $token
	    }
	}
	incr count
    }
    return $json_array
}

proc json_lexer {document at} {
    # Create a list of JSON tokens and values
    set json_lexemes {}
    set docend [string length $document]
    upvar 1 $at doclen
    while { $doclen < $docend } {
	if { [regexp -nocase -start $doclen -- {(\s*)([\{\}\[\]\"tfn0-9:,])} $document groups space character] != 0 } {
	    incr doclen [string length $groups]
	    switch -- $character {
		"t" -
		"f" -
		"n" {
		    set json_boolean [json_boolean_create [string range $document [expr $doclen - 1] end] doclen]
		    lappend json_lexemes $json_boolean
		}
		"0" -
		"1" -
		"2" -
		"3" -
		"4" -
		"5" -
		"6" -
		"7" -
		"8" -
		"9" {
		    set json_numeric [json_numeric_create [string range $document [expr $doclen - 1] end] doclen]
		    lappend json_lexemes $json_numeric
		}
		"\"" {
		    set json_literal [json_literal_create [string range $document [expr $doclen - 1] end] doclen]
		    lappend json_lexemes $json_literal
		}
		"\{" -
		"\}" -
		"\[" -
		"\]" -
		"," -
		":" {
		    lappend json_lexemes $character
		}
		default {
		    # Should not occur
		    error "Unknown character"
		}
	    }
	} else {
	    incr doclen
	}
    }
    return $json_lexemes
}

proc parse_json {document} {
    set doclen 0
    set $docend [string length $document]
    set json_object {} 
    return $json_object
}
