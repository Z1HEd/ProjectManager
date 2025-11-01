extends Tab

@onready var members_list = %MembersContainer
@onready var project_name = %ProjectName
@onready var project_description = %ProjectDescription
@onready var error_message = %ErrorMessage

@onready var refresh_button = %RefreshButton
@onready var leave_project_button = %LeaveButton
@onready var edit_project_button = %EditButton
@onready var delete_project_button = %DeleteButton
@onready var add_member_button = %AddMemberButton

@onready var add_member_popup = %AddMemberPopup
@onready var confirm_action_popup : ConfirmActionPopup = %ConfirmActionPopup
@onready var confirm_critical_popup : ConfirmCriticalPopup = %ConfirmCriticalPopup
@onready var edit_project_popup : EditProjectPopup = %EditProjectPopup

@export var member_control_prefab = preload("res://Scenes/Elements/ProjectMember.tscn")

func open():
	refresh_project()

var pid 
func refresh_project():
	refresh_button.disabled = true
	leave_project_button.visible = false
	edit_project_button.visible = false
	delete_project_button.visible = false
	add_member_button.visible = false
	project_name.text = "Loading..."
	project_description.text = ""
	error_message.text = ""
	for old_member in members_list.get_children():
		old_member.queue_free()
	
	pid = CurrentProject.pid
	
	var _on_success = func(project_dict : Dictionary):
		CurrentProject.set_data(project_dict)
		update_project_data()
		refresh_button.disabled = false
	
	var _on_fail = func(err_msg):
		error_message.text = err_msg
		refresh_button.disabled = false
	
	ProjectService.get_project(pid,_on_success,_on_fail)

func update_project_data():
	
	project_name.text = CurrentProject.project_name
	project_description.text = CurrentProject.project_description
	
	leave_project_button.visible = CurrentProject.user_role != "owner"
	edit_project_button.visible = CurrentProject.user_role == "owner"
	delete_project_button.visible = CurrentProject.user_role == "owner"
	add_member_button.visible =  CurrentProject.user_role == "owner"
	
	for member_uid in CurrentProject.members.keys():
		var member_control = member_control_prefab.instantiate() as ProjectMember
		# Call deffered because needs to set children's properties, 
		# which can only be done after _ready()
		member_control.call_deferred(
				"set_member",
				member_uid,
				CurrentProject.members[member_uid]
		)
		member_control.call_deferred(
			"set_more_button_visible",
			CurrentProject.user_role == "owner"
		)
		members_list.add_child(member_control)

func _on_add_member_button_pressed() -> void:
	add_member_popup.visible = true

func _on_leave_button_pressed() -> void:
	
	var _on_confirm = func():
		ProjectService.remove_member(CurrentProject.pid,Session.uid)
		CurrentProject.clear()
	
	
	confirm_action_popup.set_info("Leave Project?", 
		"You can join this project again, if the owner invites you.")
	confirm_action_popup.set_callbacks(_on_confirm)
	confirm_action_popup.visible = true

func _on_edit_button_pressed() -> void:
	edit_project_popup.set_current_info(CurrentProject.project_name,
			CurrentProject.project_description)
	edit_project_popup.visible=true

func _on_delete_button_pressed() -> void:
	var _on_confirmed = func():
		ProjectService.delete_project(CurrentProject.pid)
		CurrentProject.clear()
	confirm_critical_popup.set_info("Delete project irreversibly?", CurrentProject.project_name)
	confirm_critical_popup.set_callbacks(_on_confirmed)
	confirm_critical_popup.visible=true
