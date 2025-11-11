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
	if uid=="":
		push_error("Tried setting project with empty uid!")
	pid = uid
	is_open = true
	project_opened.emit()
	

func set_data(dict : Dictionary):
	project_name = dict.get("name")
	project_description = dict.get("description")
	creation_date = dict.get("creationDate")
	project_owner = dict.get("owner")
	members = dict.get("members")
	user_role = members.get(Session.uid)
	
	project_updated.emit()

func clear():
	project_name = ""
	project_description = ""
	pid = ""
	creation_date = 0.0
	project_owner = ""
	user_role = ""
	
	is_open = false
	project_closed.emit()

func update_member_names():
	if members.size() ==0:
		return
	
	for uid in members:
		
		var on_success = func(_name:String):
			members_names[uid] = _name
		
		UserService.get_display_name(uid,on_success,func(err):print(err))
