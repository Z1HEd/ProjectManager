extends Node
class_name InviteService

static func create_invite(uid: String,pid:String, role: String, message: String, on_success: Callable, on_fail: Callable) -> int:
	# TEMPORARY: add user to the project directly instead of creating invite
	# Change that when notification system is in place
	
	return ProjectService.add_user_to_project(uid,pid,role,on_success,on_fail)
