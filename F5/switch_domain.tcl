when HTTP_REQUEST {
    if { [HTTP::header exists "Content-Length"] && [HTTP::method] eq "POST" }{
	HTTP::collect [HTTP::header "Content-Length"]
    }
}
when HTTP_REQUEST_DATA {
    set path "/web-app/servlet/1/servlet-name"
    if { [catch {set json_array [call LIBjson.tcl::parse_json [HTTP::payload]]} badparse] != 0 } {
	log local0.err "Invalid JSON document"
	HTTP::respond 403 content "<html>Invalid JSON document</html>" Content-Type text/html
    } else {
	if { [catch {set value [call LIBjson.tcl::getxpath $json_array $path]} exmesg] != 0 } {
	    log local0.info "$path does not exist"
	    HTTP::respond 200 content "<html>$path does not exist</html>" Content-Type text/html
	} else {
	    log local0.info "$path exists"
	    set response [format {<html>%s is %s</html>} $path $value]
	    HTTP::respond 200 content $response Content-Type text/html
	}
    }
}
