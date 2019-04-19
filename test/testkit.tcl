#!/usr/bin/env tclsh

source "../LIBjson.tcl"

# A collection of JSON objects
set ::ctrlsample {{
    "booleans": [
        true,
        false,
        null
    ],
    "control": {
        "cr": "\r",
        "crlf": "\r\n",
        "lf": "\n",
        "tab": "\t"
    },
    "floating": [
        0.98,
        9000000.0,
        0.0009
    ],
    "integers": [
        1,
        2,
        3
    ],
    "legal": "\u00a7108",
    "nested": {
        "age": 15,
        "name": "Atreyu",
        "steed": "Falcor",
        "story": [
            "Neverending Story"
        ]
    },
    "string": [
        "Matthew",
        "Mark",
        "Luke",
        "John"
    ]
}}
set ::ctrlsampleton [list booleans {true false null} control {cr {\r} crlf {\r\n} lf {\n} tab {\t}} floating {0.98 9000000.0 0.0009} integers {1 2 3} legal {\u00a7108} nested {age 15 name Atreyu steed Falcor story {{Neverending Story}}} string {Matthew Mark Luke John}]

# A list of JSON objects
set ::listsample {[
    {
        "color": "white",
        "value": "#ffffff"
    },
    {
        "color": "grey",
        "value": "#0f0f0f"
    },
    {
        "color": "black",
        "value": "#000000"
    }
]}
set ::listsampleton [list {color white value #ffffff} {color grey value #0f0f0f} {color black value #000000}]
set ::totalfailures 0
set ::totalsuccesses 0

proc poptests {} {
    set failures 0
    set successes 0
    set simplelist [list a b c]
    set simplelen [llength ${simplelist}]
    set testitem "d"

    puts "--- poptests ---"

    # Append (to demonstrate a "push" action)
    lappend simplelist ${testitem}
    if { [string compare ${simplelist} "a b c d"] == 0 && [llength ${simplelist}] == [expr ${simplelen} + 1]} {
        puts "\"lappend\" passed"
        incr successes
    } else {
        puts "\"lappend\" failed"
        incr failures
    }

    set element [lpop simplelist]
    if { [string compare ${element} ${testitem}] == 0 && [llength ${simplelist}] == ${simplelen} } {
        puts "\"lpop\" passed"
        incr successes
    } else {
        puts "\"lpop\" failed"
        incr failures
    }
    puts "--- poptests ---"
    procsummary ${successes} ${failures}
}

proc jsonlittest {} {
    set failures 0
    set successes 0
    # An associative array of test values and their expected results
    array set littests [list {: "element",} {element} {null} {} {: 123,} {} {"\u00a7108"} {\u00a7108}]

    puts "--- jsonlittest ---"
    foreach test [array names littests] {
        set doclen 0
        set result [json_literal_create ${test} doclen]
        if { [string compare ${result} $littests(${test})] == 0 } {
            puts "\"json_literal_create\" passed"
            incr successes
        } else {
            puts "${result} <!> ${littests}(${test})"
            puts "\"json_literal_create\" failed"
            incr failures
        }
    }
    puts "--- jsonlittest ---"
    procsummary ${successes} ${failures}
}

proc jsonnumtest {} {
    set failures 0
    set successes 0
    # An associative array of test values and their expected results
    array set numtests [list {:   0.998,} {0.998} {  "$88.76",} {88.76} {:  "0.98%",} {0.98} {:99e-5,} {99e-5} {99} {99}]

    # NOTE: It is understandable that the decimal values within quotes (with punctuation/symbols) *should not* match; however,
    # the numbers are of valid form. Be advised - during lexing, those would normally be diverted to
    # json_literal_create

    puts "--- jsonnumtest ---"
    foreach test [array names numtests] {
        set doclen 0
        set result [json_numeric_create ${test} doclen]
        if { [string compare ${result} $numtests(${test})] == 0 } {
            puts "\"json_numeric_create\" passed"
            incr successes
        } else {
            puts "${result} <!> $numtests(${test})"
            puts "\"json_numeric_create\" failed"
            incr failures
        }
    }
    puts "--- jsonnumtest ---"
    procsummary ${successes} ${failures}
}

proc jsonbooltest {} {
    set failures 0
    set successes 0
    # An associative array of test values and their expected results
    array set booltests [list {:    false,} {false} {:   "true",} {} {"null"} {}]

    puts "--- jsonbooltest ---"
    foreach test [array names booltests] {
        set doclen 0
        set result [json_boolean_create ${test} doclen]
        if { [string compare ${result} $booltests(${test})] == 0 } {
            puts "\"json_boolean_create\" passed"
            incr successes
        } else {
            puts "${result} <!> $booltests(${test})"
            puts "\"json_boolean_create\" failed"
            incr failures
        }
    }
    puts "--- jsonbooltest ---"
    procsummary ${successes} ${failures}
}

proc testlexemes {} {
    set successes 0
    set failures 0

    # Tokenized array containing the expected results
    set template [list \[ \{ color : white , value : "#ffffff" \} , \{ color : grey , value : "#0f0f0f" \} , \{ color : black , value : "#000000" \} \]]
    puts "--- testlexemes ---"
    set tokens [json_lexer ${::listsample}]
    if { [llength ${tokens}] == [llength ${template}] } {
        puts "Length phase:  passed"
        incr successes
    } else {
        puts "Length phase:  failed"
        incr failures
    }
    set compares 0
    set lesslen [expr [llength ${tokens}] ? [llength ${tokens}] <= [llength ${template}] : [llength ${template}]]
    for {set i 0} {${i} < ${lesslen}} {incr i} {
        if { [string compare [lindex ${tokens} ${i}] [lindex ${template} ${i}]] == 0 } {
            incr compares
        }
    }
    if { ${compares} == ${lesslen} } {
        puts "Compare phase: passed"
        incr successes
    } else {
        puts "Compare phase: failed"
        incr failures
    }

    # Tokenized array containing the expected results
    set template [list \{ booleans : \[ true , false , null \] , control : \{ cr : \\r , crlf : \\r\\n , lf : \\n , tab : \\t \} , floating : \[ 0.98 , 9000000.0 , 0.0009 \] , integers : \[ 1 , 2 , 3 \] , legal \\u00a7108 , nested : \{ age : 15 , name : Atreyu , steed : Falcor , story : \[ "Neverending Story" \] \} , "string" : \[ Matthew , Mark , Luke, John \] \}]
    set tokens [json_lexer ${::ctrlsample}]
    if { [llength ${tokens}] == [llength ${template}] } {
        puts "Length phase:  passed"
        incr successes
    } else {
        puts "Length phase:  failed"
        incr failures
    }
    set compares 0
    set lesslen [expr [llength ${tokens}] ? [llength ${tokens}] <= [llength ${template}] : [llength ${template}]]
    for {set i 0} {${i} < ${lesslen}} {incr i} {
        if { [string compare [lindex ${tokens} ${i}] [lindex ${template} ${i}]] == 0 } {
            incr compares
        }
    }
    if { ${compares} == ${lesslen} } {
        puts "Compare phase: passed"
        incr successes
    } else {
        puts "Compare phase: failed"
        incr failures
    }
    puts "--- testlexemes ---"
    procsummary ${successes} ${failures}
}

proc testparse {} {
    set successes 0
    set failures 0

    puts "--- testparse ---"
    set jdoc [json_parse [json_lexer ${::ctrlsample}]]
    if { [string compare ${jdoc} ${::ctrlsampleton}] == 0 } {
        puts "\"ctrlsample\" passed"
        incr successes
    } else {
        puts "\"\${jdoc}\" <!> \"\${ctrlsample}\" failed"
        incr failures
    }
    unset jdoc

    set jdoc [parse_json $::listsample]
    if { [string compare ${jdoc} ${::listsampleton}] == 0 } {
        puts "\"listsample\" passed"
        incr successes
    } else {
        puts "\"\${jdoc}\" <!> \"\${listsample}\" failed"
        incr failures
    }
    unset jdoc
    puts "--- testparse ---"
    procsummary ${successes} ${failures}
}

proc testxpath {} {
    set successes 0
    set failures 0

    array set testitems [list {/nested/story/0} {Neverending Story} {/string/0} {Matthew} {/control/cr} {\r}]
    array set testitems2 [list {/0/color} {white} {/1/value} {#0f0f0f}]
    set failitems [list {/booleans/true}]
    set failitems2 [list {/color}]

    puts "--- testxpath ---"
    set jdoc [parse_json ${::ctrlsample}]
    foreach test [array names testitems] {
        set nested [getxpath ${jdoc} ${test}]
        set valid $testitems(${test})
        if { [string compare ${valid} ${nested}] == 0 } {
	    puts [format "found: \"%-20s\", passed" ${test}]
            incr successes
        } else {
            puts "${nested} <!> ${valid}"
            incr failures
        }
    }

    for {set i 0} {${i} < [llength ${failitems}]} {incr i} {
        set test [lindex ${failitems} ${i}]
        if { [catch {set element [getxpath ${jdoc} ${test}]} mesg] == 0 } {
            # This is expected to fail, should not execute
            puts "found: \"${test}\" as \"${element}\""
            incr failures
        } else {
            puts "caught exception, as expected"
            incr successes
        }
    }
    unset jdoc

    set jdoc [parse_json ${::listsample}]
    foreach test [array names testitems2] {
        set nested [getxpath ${jdoc} ${test}]
        set valid $testitems2(${test})
        if { [string compare ${valid} ${nested}] == 0 } {
	    puts [format "found: \"%-20s\", passed" ${test}]
            incr successes
        } else {
            puts "${nested} <!> ${valid}"
            incr failures
        }
    }

    for {set i 0} {${i} < [llength ${failitems2}]} {incr i} {
        set test [lindex ${failitems2} ${i}]
        if { [catch {set element [getxpath ${jdoc} ${test}]} mesg] == 0 } {
            # This is expected to fail, should not execute
            puts "found: \"${test}\" as \"${element}\""
            incr failures
        } else {
            puts "caught exception, as expected"
            incr successes
        }
    }
    unset jdoc
    puts "--- testxpath ---"
    procsummary ${successes} ${failures}
}

proc procsummary {successes failures} {
    incr ::totalsuccesses ${successes}
    incr ::totalfailures ${failures}
    puts [format "%d successes, %d failures\n" ${successes} ${failures}]
}

proc summary {} {
    puts "=== total ==="
    puts [format "%d successes, %d failures\n" ${::totalsuccesses} ${::totalfailures}]
}

poptests
jsonlittest
jsonnumtest
jsonbooltest
testparse
testlexemes
testxpath
summary

exit 0
