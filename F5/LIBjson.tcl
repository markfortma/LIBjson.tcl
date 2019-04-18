proc lpop {target} {
    # always call as "set end [lpop collection]"
    # removed end value from collection
    # return end value or empty list, if unable/unsuccessful
    upvar 1 ${target} collection
    set last {}
    if { [llength ${collection}] > 0 } {
        set last [lindex ${collection} end]
        set collection [lrange ${collection} 0 end-1]
    }
    return ${last}
}
proc expired {start} {
    set expired 0
    # convert seconds to microseconds
    set timeout [expr ${static::maxtime} * 1000]
    # return the boolean of the comparison
    set isexpired [expr [expr [clock clicks -milliseconds] - ${start}] > ${timeout}]
    return $isexpired
}
proc json_numeric_create {document at} {
    set numeric 0
    upvar 1 ${at} doclen
    if { [string length ${document}] > 0 } {
        if { [regexp -nocase -- {(\s*)(-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:e[+\-]?[0-9]+)?)} ${document} groups space value] != 0 } {
            incr doclen [expr [string length ${groups}] - 1]
            set numeric ${value}
        }
    }
    return ${numeric}
}
proc json_literal_create {document at} {
    set literal ""
    upvar 1 ${at} doclen
    if { [string length ${document}] > 0 } {
        if { [regexp -nocase -- {(\s*)\"(\\[\"bfnrt\\]|\\u[0-9a-f]{4}|[^\"\b\f\n\r\t\\])*\"} ${document} groups space value] != 0 } {
            incr doclen [expr [string length ${groups}] - 1]
            # Set the literal to be the substring, excluding double quotes
            set literal [string range ${groups} [expr [string length ${space}] + 1] end-1]
        }
    }
    return ${literal}
}
proc json_boolean_create {document at} {
    set boolean ""
    upvar 1 ${at} doclen
    if { [string length ${document}] > 0 } {
        if { [regexp -nocase -- {(\s*)(?![[:punct:]])(true|false|null)[[:space:],]?(?![[:punct:]])} ${document} groups space value] != 0 } {
            incr doclen [expr [string length ${groups}] - 1]
            set boolean ${value}
        }
    }
    return ${boolean}
}
proc json_parse {lexemes} {
    set json_array {}
    set stack {}
    set keystack {}
    set lastkey {}
    set count 0
    set depth 0
    set signal 0
    set now [clock clicks -milliseconds]
    set length [llength ${lexemes}]
    if { [string equal [lindex ${lexemes} 0] "\{"] == 1 && [string equal [lindex ${lexemes} end] "\}"] == 0 } {
        error "Invalid JSON object"
    } elseif { [string equal [lindex ${lexemes} 0] "\["] == 1 && [string equal [lindex ${lexemes} end] "\]"] == 0 } {
        error "Invalid JSON list"
    } else {
        incr count
        incr length -1
    }
    if { ${length} > ${static::maxlength} } {
        log local0.warn "exceeds ${static::maxlength} characters"
        return $json_array
    }
    while { ${count} < ${length} } {
        if { [call LIBjson.tcl::expired ${now}] != 0 } {
            log local0.warn "exceeded ${static::maxtime} seconds"
            set signal 1
        } elseif { ${depth} > ${static::maxdepth} } {
            log local0.warn "exceeded ${static::maxdepth} nested objects"
            set signal 1
        }
        set token [lindex ${lexemes} ${count}]
        switch -- ${token} {
            "\{" -
            "\[" {
                incr depth
                lappend stack ${json_array}
                lappend keystack [call LIBjson.tcl::lpop json_array]
                set json_array {}
            }
            "\}" -
            "\]" {
                incr depth -1
                set parent [call LIBjson.tcl::lpop stack]
                lappend parent ${json_array}
                set json_array ${parent}
                if { ${signal} != 0 } {
                    break
                }
            }
            ":" {
                set lastkey [lindex ${json_array} [expr ${count} - 1]]
            }
            "," {
                if { [string length ${lastkey}] > 0 } {
                    set value [call LIBjson.tcl::lpop json_array]
                    set key [call LIBjson.tcl::lpop json_array]
                    lappend json_array [list ${key} ${value}]
                }
                set lastkey {}
                if { ${signal} != 0 } {
                    break
                }
            }
            default {
                lappend json_array ${token}
            }
        }
        incr count
    }
    # pop any of the remaining stack before returning
    while { [llength $stack] > 0 } {
        # lpop will decrement the stack size by one
        set parent [call LIBjson.tcl::lpop stack]
        lappend parent ${json_array}
        set json_array ${parent}
    }
    return ${json_array}
}
proc json_lexer {document} {
    # Create a list of JSON tokens and values
    set json_lexemes {}
    set doclen 0
    set docend [string length ${document}]
    while { ${doclen} < ${docend} } {
        if { [regexp -nocase -start ${doclen} -- {(\s*)([\{\}\[\]\"tfn0-9:,])} ${document} groups space character] != 0 } {
            incr doclen [string length ${groups}]
            switch -- ${character} {
                "t" -
                "f" -
                "n" {
                    set json_boolean [call LIBjson.tcl::json_boolean_create [string range ${document} [expr ${doclen} - 1] end] doclen]
                    lappend json_lexemes ${json_boolean}
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
                    set json_numeric [call LIBjson.tcl::json_numeric_create [string range ${document} [expr ${doclen} - 1] end] doclen]
                    lappend json_lexemes ${json_numeric}
                }
                "\"" {
                    set json_literal [call LIBjson.tcl::json_literal_create [string range ${document} [expr ${doclen} - 1] end] doclen]
                    lappend json_lexemes ${json_literal}
                }
                "\{" -
                "\}" -
                "\[" -
                "\]" -
                "," -
                ":" {
                    lappend json_lexemes ${character}
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
    return ${json_lexemes}
}
proc parse_json {document} {
    set json_array [call LIBjson.tcl::json_parse [call LIBjson.tcl::json_lexer ${document}]]
    return ${json_array}
}
proc getxpath {ton pathspec} {
    set object {}
    if { [llength ${ton}] > 0 } {
        set object ${ton}
        if { [string length ${pathspec}] > 0 } {
            set lspec [split ${pathspec} "/"]
            if { [string equal [lindex ${lspec} 0] {}] } {
                for {set start 1} {${start} < [llength ${lspec}]} {incr start} {
                    set spec [lindex ${lspec} ${start}]
                    if { [string is integer ${spec}] && (${spec} >= 0 && ${spec} < [llength ${object}]) } {
                        set object [lindex ${object} ${spec}]
                    } elseif { [expr [llength ${object}] % 2] == 0 } {
                        array set collection ${object}
                        set object $collection(${spec})
                    } else {
                        error "invalid path element: \"${spec}\""
                    }
                }
            } else {
                error "pathspec \"${pathspec}\" not started with \"/\""
            }
        } else {
            error "pathspec \"${pathspec}\" 0 length"
        }
    } else {
        error "object ton 0 length"
    }
    return ${object}
}
when RULE_INIT {
    # How many nested levels
    set static::maxdepth 100

    # How many seconds
    set static::maxtime 2

    # How many characters of input
    set static::maxlength 4096
}
