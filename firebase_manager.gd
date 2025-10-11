extends Node

func create_anonymous_user(api_key: String) -> String:
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%s" % api_key
	var body = {"returnSecureToken": true}
	var http := HTTPRequest.new()
	add_child(http)
	@warning_ignore("unused_variable")
	var err = http.request(url, [], HTTPClient.METHOD_POST, JSON.stringify(body))
	await http.request_completed
	var result = JSON.parse_string(http.get_body_as_string())
	return result["localId"] # this is the player’s unique ID
