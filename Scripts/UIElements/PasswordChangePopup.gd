extends Control
class_name PasswordChangePopup

@onready var confirm_button = %ConfirmButton
@onready var input_current = %InputCurrent
@onready var input_new = %InputNew
@onready var error_label : RichTextLabel = %ErrorText

func _on_confirm_button_pressed() -> void:
	error_label.visible = false
	confirm_button.disabled = true

	var current_pw = input_current.text.strip_edges()
	var new_pw = input_new.text.strip_edges()

	var _on_login_success = func(_resp):
		var _on_change_success = func(_res):
			visible = false
			input_current.text = ""
			input_new.text = ""

		var _on_change_fail = func(err):
			error_label.visible = true
			error_label.bbcode_text = "Error: %s" % str(err)
			confirm_button.disabled = false

		UserService.change_password(
				new_pw, 
				_on_change_success, 
				_on_change_fail
		)

	var _on_login_fail = func(err):
		error_label.visible = true
		error_label.bbcode_text = "Re-auth failed: %s" % str(err)
		confirm_button.disabled = false

	UserService.login(
			Session.email,
			current_pw, 
			_on_login_success, 
			_on_login_fail
	)

func _on_cancel_button_pressed() -> void:
	visible = false
	input_current.text = ""
	input_new.text = ""

func _on_input_new_text_changed(new_text: String) -> void:
	confirm_button.disabled = new_text.length() < 6
