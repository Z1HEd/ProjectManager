extends Node
class_name ProjectMember

@onready var display_name = %Name
@onready var role = %Role
@onready var more_button = %MoreButton

@export var uid : String

func set_member(_uid:String, _role : String):
	
	uid = _uid
	
	display_name.text = "Loading..."
	role.text = _role
	
	var _on_success = func(user_name:String):
		display_name.text = user_name
	
	var _on_fail = func(err_msg:String):
		display_name.text = err_msg
	
	UserService.get_display_name(uid,_on_success,_on_fail)

func set_more_button_visible(value: bool):
	more_button.visible = value
