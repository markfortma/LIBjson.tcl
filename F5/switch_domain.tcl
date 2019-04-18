when HTTP_REQUEST {
    if { [HTTP::header exists "Content-Length"] && [HTTP::method] == "POST" }{
        HTTP::collect [HTTP::header "Content-Length"]
    }
}
when HTTP_REQUEST_DATA {
    set json_array [call LIBjson.tcl::parse_json [HTTP::payload]]
    if { [catch {set value [call LIBjson.tcl::getxpath $json_array /0/color]} exmesg] != 0 } {
        log local0.info "/0/color does not exist"
        HTTP::respond 200 content "<html>/0/color does not exist</html>" Content-Type text/html
    } else {
        log local0.info "/0/color exists"
        set response [format {<html>/0/color is %s</html>} $value]
        HTTP::respond 200 content $response Content-Type text/html
    }
}
