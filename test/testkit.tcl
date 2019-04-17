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
    set simplelen [llength $simplelist]
    set testitem "d"

    puts "--- poptests ---"

    # Append (to demonstrate a "push" action)
    lappend simplelist $testitem
    if { [string compare $simplelist "a b c d"] == 0 && [llength $simplelist] == [expr $simplelen + 1]} {
	puts "push of \"$testitem\" successful"
	incr successes
    } else {
	puts "push of \"$testitem\" failed"
	incr failures
    }

    set element [lpop simplelist]
    if { [string compare $element $testitem] == 0 && [llength $simplelist] == $simplelen } {
	puts "pop of \"$testitem\" successful"
	incr successes
    } else {
	puts "pop of \"$testitem\" failed"
	incr failures
    }
    puts "--- poptests ---"
    incr ::totalsuccesses $successes
    incr ::totalfailures $failures
    puts [format "%d successes, %d failures\n" $successes $failures]
}

proc jsonlittest {} {
}

proc jsonnumtest {} {
}

proc jsonbooltest {} {
}

proc testlexemes {} {
}

proc testparse {} {
}

proc summary {} {
    puts "=== total ==="
    puts [format "%d successes, %d failures\n" $::totalsuccesses $::totalfailures]
}

poptests
summary

exit 0
