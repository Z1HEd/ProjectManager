extends Object
class_name Project

signal project_opened
signal project_closed

@export var name := ""
@export var description := ""
@export var uid := ""
@export var creation_date := 0.0
@export var owner := ""
@export var user_role := ""

@export var is_open := false

func open(_uid: String, _user_role: String, dict : Dictionary):
	uid = _uid
	name = dict.get("name")
	description = dict.get("description")
	creation_date = dict.get("creationDate")
	owner = dict.get("owner")
	user_role = _user_role
	
	is_open = true
	project_opened.emit()

func close():
	name = ""
	description = ""
	uid = ""
	creation_date = 0.0
	owner = ""
	user_role = ""
	
	is_open = false
	project_closed.emit()
