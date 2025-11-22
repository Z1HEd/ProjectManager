extends Node
class_name InviteService

static func create_invite(
		project_id: String, 
		invitee_uid: String, 
		role: String, 
		invite_message:String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var path = "%s/invites/%s/%s.json?auth=" % \
			[Firebase.project_db_url, invitee_uid, project_id]

	var payload = {
		"role": role,
		"inviterUid": Session.uid,
		"inviteMessage": invite_message
	}
	
	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to create an invite:\n%s" % err_msg)
		on_fail.call(err_msg)
	
	return Firebase.send_request(
			path, 
			HTTPClient.METHOD_PUT, 
			payload, 
			[], 
			on_success, 
			_on_fail
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

	var root_patch_url = "%s/.json?auth=" % [ Firebase.project_db_url ]
	
	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to accept an invite:\n%s" % err_msg)
		on_fail.call(err_msg)
	
	return Firebase.send_request(
			root_patch_url, 
			HTTPClient.METHOD_PATCH, 
			payload, 
			[], 
			on_success, 
			_on_fail)

static func decline_invite(
		project_id: String, 
		invitee_uid: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/invites/%s/%s.json?auth=" % \
			[ Firebase.project_db_url, invitee_uid, project_id ]
	
	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to decline an invite:\n%s" % err_msg)
		on_fail.call(err_msg)
	
	return Firebase.send_request(url, 
			HTTPClient.METHOD_DELETE, 
			{}, 
			[], 
			on_success, 
			_on_fail)


static func get_user_invites(
		invitee_uid: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/invites/%s.json?auth=" % \
	[ Firebase.project_db_url, invitee_uid ]
	
	var _on_success = func(result):
		if result == null:
			# normalize to empty dict for callers
			on_success.call({})
			return
		if not result is Dictionary:
			on_fail.call("Invalid response: %s" % str(result))
			return
		on_success.call(result)
	
	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to fetch invites:\n%s" % err_msg)
		on_fail.call(err_msg)
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_GET, 
			{}, 
			[], 
			_on_success, 
			_on_fail)
