extends Tab

@onready var title = %Title
@onready var name_edit = %NameEdit
@onready var email_edit = %EmailEdit
@onready var session_persist_toggle : CheckButton = %SessionPersistToggle

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
		AccountService.login(Session.email,password,_on_relogin_success,_on_relogin_fail)
	
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
	
	AccountService.delete_user(Session.uid, projects, on_success,on_fail)
		
