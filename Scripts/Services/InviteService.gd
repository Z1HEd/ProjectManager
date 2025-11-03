extends Node
class_name InviteService


static func create_invite(
		project_id: String, 
		invitee_uid: String, 
		role: String, 
		invite_message:String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var path = "%s/invites/%s/%s.json?auth=%s" % [
		Firebase.project_db_url.trim_suffix("/"),
		invitee_uid,
		project_id,
		Session.id_token
	]

	var payload = {
		"role": role,
		"inviter_uid": Session.uid,
		"invite_message": invite_message,
		"created_at": Time.get_unix_time_from_system()
	}

	return Firebase.send_request(
			path, 
			HTTPClient.METHOD_PUT, 
			payload, 
			[], 
			on_success, 
			on_fail
	)

static func accept_invite(
		project_id: String, 
		invitee_uid: String, 
		role: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var payload = {}
	payload["projects/%s/members/%s" % [project_id, invitee_uid]] = role
	payload["users/%s/projects/%s" % [invitee_uid, project_id]] = role
	payload["invites/%s/%s" % [invitee_uid, project_id]] = null

	var root_patch_url = "%s/.json?auth=%s" % [Firebase.project_db_url.trim_suffix("/"), Session.id_token]

	return Firebase.send_request(
			root_patch_url, 
			HTTPClient.METHOD_PATCH, 
			payload, 
			[], 
			on_success, 
			on_fail
	)

static func decline_invite(
		project_id: String, 
		invitee_uid: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/invites/%s/%s.json?auth=%s" % [
		Firebase.project_db_url.trim_suffix("/"),
		invitee_uid,
		project_id,
		Session.id_token
	]
	
	return Firebase.send_request(url, 
			HTTPClient.METHOD_DELETE, 
			{}, 
			[], 
			on_success, 
			on_fail
	)


static func get_user_invites(
		invitee_uid: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/invites/%s.json?auth=%s" % [
		Firebase.project_db_url.trim_suffix("/"),
		invitee_uid,
		Session.id_token
	]
	
	var _on_success = func(result):
		if result == null:
			# normalize to empty dict for callers
			on_success.call({})
			return
		if not result is Dictionary:
			on_fail.call("Invalid response: %s" % str(result))
			return
		on_success.call(result)

	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_GET, 
			{}, 
			[], 
			_on_success, 
			on_fail
	)
