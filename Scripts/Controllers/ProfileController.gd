extends Tab

@onready var title = %Title
@onready var name_edit = %NameEdit
@onready var email_edit = %EmailEdit
@onready var session_persist_toggle : CheckButton = %SessionPersistToggle
@onready var save_button = %SaveButton
@onready var revert_button = %RevertButton

@onready var confirm_action_popup : ConfirmActionPopup = %ConfirmActionPopup
@onready var confirm_critical_popup : ConfirmCriticalPopup = %ConfirmCriticalPopup

@onready var account_view = %AccountView
@onready var error_message = %ErrorMessage

var current_name : String
var current_email : String
var projects : Dictionary

func open():
	error_message.visible = false
	account_view.visible = false
	
	title.text = "Loading..."
	
	var on_success = func(user_data : Dictionary):
		title.text = "Your Account"
		account_view.visible = true
		
		current_name = user_data["displayName"]
		name_edit.text = current_name
		
		current_email = user_data["email"]
		email_edit.text = current_email
		
		save_button.visible = false
		revert_button.visible = false
		
		projects =  user_data.get("projects",{})
		
		session_persist_toggle.button_pressed = Session.session_persist
	
	var on_fail = func(err_msg):
		error_message.visible = true
		error_message.text = "Error: %s" % err_msg
	
	UserService.get_user(Session.uid,on_success,on_fail)

func _on_sign_out_button_pressed() -> void:
	
	var _on_confirm = func():
		Session.clear()
		get_tree().change_scene_to_file("res://Scenes/Screens/WelcomeScreen.tscn")
	
	confirm_action_popup.set_info("Sign out?",
		"Password will be required to sign in again.")
	confirm_action_popup.set_callbacks(_on_confirm)
	confirm_action_popup.visible = true


func _on_delete_account_button_pressed() -> void:
	error_message.visible = false
	
	var _on_relogin_success = func(_uid:String):
		delete_account()
	
	var _on_relogin_fail = func(err_msg:String):
		error_message.visible = true
		error_message.text = err_msg
	
	var _on_confirm = func(password):
		UserService.login(Session.email,password,_on_relogin_success,_on_relogin_fail)
	
	confirm_critical_popup.set_info("Delete your account?",
		"Account %s will be deleted irreversibly. "%current_name+
		"Delete or transfer ownership of your projects before deleting.\n"+
		'Enter your password to confirm:'
		)
	confirm_critical_popup.set_callbacks(_on_confirm)
	confirm_critical_popup.visible = true
	confirm_critical_popup.input.secret = true

func delete_account():
	var on_success = func(_res):
		Session.clear()
		get_tree().change_scene_to_file("res://Scenes/Screens/WelcomeScreen.tscn")
	
	var on_fail = func(err_msg):
		error_message.visible = true
		error_message.text = "Error: %s" % err_msg
	
	UserService.delete_user(Session.uid, projects, on_success,on_fail)
		

func _on_email_edit_text_changed(new_text: String) -> void:
	save_button.visible = new_text != current_email
	revert_button.visible = new_text != current_email
	
	name_edit.editable = new_text == current_email


func _on_name_edit_text_changed(new_text: String) -> void:
	save_button.visible = new_text != current_name
	revert_button.visible = new_text != current_name
	
	email_edit.editable = new_text == current_name

func _on_save_button_pressed() -> void:
	error_message.visible = false

	var new_name = name_edit.text
	var new_email = email_edit.text
	
	save_button.disabled = true
	revert_button.disabled = true
	save_button.text = "Saving..."
	
	if new_email != current_email:
		change_email(new_email)
	elif new_name != current_name:
		change_name(new_name)

func change_email(new_email: String):
	var _on_fail = func(err_msg):
		error_message.visible = true
		error_message.text = "Error: %s" % err_msg
		
		save_button.text = "Save changes"
		save_button.disabled = false
		revert_button.disabled = false
	
	var _on_success = func(_res):
		Session.email = new_email
		current_email = new_email
		
		save_button.text = "Save changes"
		name_edit.editable = true
		
		save_button.visible = false
		revert_button.visible = false
		save_button.disabled = false
		revert_button.disabled = false
	
	var _on_relogin_success = func(_uid:String):
		UserService.change_email(
				Session.uid, 
				new_email,
				_on_success,
				_on_fail
		)
	
	var _on_confirm = func(password):
		UserService.login(Session.email,password,_on_relogin_success,_on_fail)
	
	confirm_critical_popup.set_info("Change email?",
		'Your email will be set to "%s". ' % new_email+
		"You will need to use this email when signing up.\n"+
		'Enter your password to confirm:'
		)
	confirm_critical_popup.set_callbacks(_on_confirm)
	confirm_critical_popup.visible = true
	confirm_critical_popup.input.secret = true

func change_name(new_name:String):
	
	var _on_fail = func(err_msg):
		error_message.visible = true
		error_message.text = "Error: %s" % err_msg
		
		save_button.text = "Save changes"
		save_button.disabled = false
		revert_button.disabled = false
	
	var _on_success = func(_res):
		save_button.text = "Save changes"
		email_edit.editable = true
		
		save_button.visible = false
		revert_button.visible = false
		save_button.disabled = false
		revert_button.disabled = false
		
	UserService.change_name(
			Session.uid, 
			new_name,
			_on_success, 
			_on_fail
	)

func _on_revert_button_pressed() -> void:
	name_edit.text = current_name
	email_edit.text = current_email
	name_edit.editable = true
	email_edit.editable = true
	
	save_button.visible = false
	revert_button.visible = false
	save_button.disabled = false
	revert_button.disabled = false


func _on_session_persist_toggle_toggled(toggled_on: bool) -> void:
	Session.set_session_persist(toggled_on)
