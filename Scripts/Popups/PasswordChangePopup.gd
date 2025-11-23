extends Control
class_name PasswordChangePopup

@onready var confirm_button = %ConfirmButton
@onready var input_current = %InputCurrent
@onready var input_new = %InputNew

func _on_confirm_button_pressed() -> void:
	confirm_button.disabled = true

	var current_pw = input_current.text.strip_edges()
	var new_pw = input_new.text.strip_edges()
	
	var on_fail = func(_err):
		confirm_button.disabled = false
	
	var _on_login_success = func(_resp):
		var _on_change_success = func(_res):
			visible = false
			input_current.text = ""
			input_new.text = ""
			AppNotifications.push("Password has been changed")

		UserService.change_password(
				new_pw, 
				_on_change_success, 
				on_fail
		)
	UserService.login(
			Session.email,
			current_pw, 
			_on_login_success, 
			on_fail
	)

func _on_cancel_button_pressed() -> void:
	visible = false
	input_current.text = ""
	input_new.text = ""

func _on_input_new_text_changed(new_text: String) -> void:
	confirm_button.disabled = new_text.length() < 6
