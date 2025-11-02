extends Node
class_name ProjectMember

@onready var display_name = %Name
@onready var role = %Role
@onready var more_button = %MoreButton

@export var uid : String

signal change_role_pressed(uid:String, name:String)
signal kick_pressed(uid:String, name:String)
signal transfer_ownership_pressed(uid:String, name:String)

enum Action{
	CHANGE_ROLE,
	KICK,
	TRANSFER_OWNERSHIP
}

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

func connect_signals(change_role:Callable,kick:Callable,transfer_ownership:Callable):
	change_role_pressed.connect(change_role)
	kick_pressed.connect(kick)
	transfer_ownership_pressed.connect(transfer_ownership)

func _on_more_button_item_selected(index: int) -> void:
	more_button.selected = -1
	match index:
		Action.CHANGE_ROLE:
			change_role_pressed.emit(uid,display_name.text,role.text)
		Action.KICK:
			kick_pressed.emit(uid,display_name.text)
		Action.TRANSFER_OWNERSHIP:
			transfer_ownership_pressed.emit(uid,display_name.text)
