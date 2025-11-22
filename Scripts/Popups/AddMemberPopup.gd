extends Control
class_name AddMemberPopup

@onready var email_input = %EmailInput
@onready var role_picker = %RolePicker
@onready var invite_text = %InviteText
@onready var send_button = %SendButton

func _on_fail(_err_msg:String):
	send_button.disabled = false

func _on_user_found(data):
	if data.size() ==0:
		return _on_fail("No user found!")
	if data.size() > 1:
		return _on_fail("Found multiple users!") # Shouldnt happen
		
	var uid = data.keys()[0]
	
	var _on_success = func(_ret):
		send_button.disabled = false
		visible = false
	
	InviteService.create_invite(
			Project.pid,
			uid,
			role_picker.text,
			invite_text.text,
			_on_success,
			_on_fail)

func _on_button_pressed() -> void:
	send_button.disabled = true
	
	UserService.get_user_by_email(email_input.text,_on_user_found,_on_fail)

func _on_return_pressed() -> void:
	visible = false
