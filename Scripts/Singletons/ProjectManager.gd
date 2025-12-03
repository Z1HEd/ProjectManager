extends Node
class_name ProjectManager

signal project_opened
signal project_updated
signal project_closed

@export var project_name := ""
@export var project_description := ""
@export var pid := ""
@export var creation_date := 0.0
@export var project_owner := ""
@export var members := {}
@export var user_role := ""
var members_names := {}

@export var is_open := false

func set_project(uid: String):
	if pid == uid:
		return
	if pid != "":
		ProjectService.stop_listening(pid)
	pid = uid
	is_open = true
	var on_error = func(msg):
		if msg == "cancel":
			AppNotifications.call_deferred("push",
					"You have been removed from the current project")
		else:
			AppNotifications.call_deferred("push",
					"Streaming error:\n%s"%msg)
		clear()
	ProjectService.start_listening(pid,update_data,on_error)
	project_opened.emit()

func update_data(dict:Dictionary):
	project_name = dict.get("name",project_name)
	project_description = dict.get("description",project_description)
	creation_date = dict.get("creationDate",creation_date)
	project_owner = dict.get("owner",project_owner)
	
	var members_update : Dictionary = dict.get("members",{})
	for member in members_update.keys():
		if members_update[member] == null:
			members.erase(member)
			return
		members[member] = members_update[member]
	
	var prev_role = user_role
	user_role = members.get(Session.uid,"")
	if user_role == "":
		AppNotifications.push("You have been removed from the current project")
		return clear()
	if prev_role != "" and prev_role != user_role:
		AppNotifications.push("Your role in this project has been changed to:\n"+
				Project.user_role)
	
	project_updated.emit()

func set_members_data(dict : Dictionary):
	members = dict
	
	project_updated.emit()

func clear():
	if pid!="":
		ProjectService.stop_listening(pid)
		pid = ""
	
	project_name = ""
	project_description = ""
	creation_date = 0.0
	project_owner = ""
	user_role = ""
	
	is_open = false
	project_closed.emit()

func update_member_names():
	if members.size() ==0:
		return
	
	# one on_fail for all users but seperate on_success because
	# on_success depends on each user's uid, and on_fail doesnt
	var on_fail = func(err:String):
		AppNotifications.push("Failed to get user displayed name:\n%s"%err)
	
	for uid in members:
		var on_success = func(_name:String):
			members_names[uid] = _name
		
		UserService.get_display_name(uid,on_success,on_fail)

func get_member_name(uid:String)->String:
	if uid == "": return ""
	return members_names.get(uid,"Unknown user")
