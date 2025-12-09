extends Tab

@onready var members_list = %MembersContainer
@onready var project_name = %ProjectName
@onready var project_description = %ProjectDescription

@onready var leave_project_button = %LeaveButton
@onready var edit_project_button = %EditButton
@onready var delete_project_button = %DeleteButton
@onready var add_member_button = %AddMemberButton

@onready var add_member_popup = %AddMemberPopup
@onready var confirm_action_popup : ConfirmActionPopup = %ConfirmActionPopup
@onready var confirm_critical_popup : ConfirmCriticalPopup = %ConfirmCriticalPopup
@onready var edit_project_popup : EditProjectPopup = %EditProjectPopup
@onready var option_popup : OptionPopup = %OptionPopup

@export var member_control_prefab = \
		preload("res://Scenes/Elements/ProjectMember.tscn")

func open(): pass

func close(): pass

func on_project_updated():
	for member in members_list.get_children():
		member.queue_free()
	
	project_name.text = Project.project_name
	project_description.text = Project.project_description
	
	leave_project_button.visible = Project.user_role != "owner"
	edit_project_button.visible = Project.user_role == "owner"
	delete_project_button.visible = Project.user_role == "owner"
	add_member_button.visible =  Project.user_role == "owner"
	
	for member_uid in Project.members.keys():
		var member_control = member_control_prefab.instantiate() as ProjectMember
		# Call deffered because needs to set children's properties, 
		# which can only be done after _ready()
		member_control.call_deferred(
				"set_member",
				member_uid,
				Project.members[member_uid])
		member_control.call_deferred(
				"set_more_button_visible",
				Project.user_role == "owner" && member_uid != Session.uid)
		member_control.connect_signals(
			_on_change_role_pressed,
			_on_kick_pressed,
			_on_transfer_ownership_pressed)
		members_list.add_child(member_control)
	
	call_deferred("_sort_member_list")

func _on_add_member_button_pressed() -> void:
	add_member_popup.visible = true

func _on_leave_button_pressed() -> void:
	
	var _on_confirm = func():
		ProjectService.remove_member(Project.pid,Session.uid)
		Project.clear()
	
	confirm_action_popup.set_info("Leave Project?", 
		"You can join this project again, if the owner invites you.")
	confirm_action_popup.set_callbacks(_on_confirm)
	confirm_action_popup.visible = true

func _on_edit_button_pressed() -> void:
	
	edit_project_popup.set_current_info(Project.project_name,
			Project.project_description)
	
	edit_project_popup.visible=true

func _on_delete_button_pressed() -> void:
	
	var _on_confirmed = func():
		ProjectService.delete_project(Project.pid)
		Project.clear()
	
	confirm_critical_popup.set_info("Delete project?",
			"All data associated with that project will be lost forever.\n"+
			'Enter "%s" to confirm:'%Project.project_name, 
			Project.project_name)
	confirm_critical_popup.set_callbacks(_on_confirmed)
	confirm_critical_popup.visible=true

func _on_change_role_pressed(uid:String,_name:String,current_role:String):
	var _on_confirm = func(role: String):
		if role == current_role:
			return
		ProjectService.set_role(Project.pid,uid,role,func(_res):pass,func(err):print(err))
	
	option_popup.set_info("Change role for %s?"%_name, 
		(
			"Select a role from the list:\n"+
			"Managers can create, assign and edit any task,\n"+
			"Members can only create new tasks and edit those assigned to them,\n"+
			"Viewers can only view tasks and messages.\n"
		)
	)
	var roles :Array[String]= ["manager","member","viewer"]
	option_popup.set_items(roles,roles.find(current_role))
	option_popup.set_callbacks(_on_confirm)
	
	option_popup.visible=true

func _on_kick_pressed(uid:String, _name:String):
	var _on_confirm = func():
		ProjectService.remove_member(Project.pid,uid)
		Project.members.erase(uid)
	
	confirm_action_popup.set_info("Kick %s?"%_name, 
		"This action will remove them from project.\n"+
		"They can rejoin later if you invite them.")
	confirm_action_popup.set_callbacks(_on_confirm)
	confirm_action_popup.visible = true

func _on_transfer_ownership_pressed(uid:String,_name:String):
	var _on_confirm = func():
		ProjectService.transfer_ownership(Project.pid,Session.uid,uid)
	
	confirm_critical_popup.set_info("Transfering ownership", 
			"This will make %s a new owner of the project.\n"%_name+
			'Your role will be set to member. Enter "%s" to confirm:'%
			Project.project_name,
			Project.project_name)
	confirm_critical_popup.set_callbacks(_on_confirm)
	confirm_critical_popup.visible = true

func _sort_member_list():
	var list := members_list.get_children() 
	list.sort_custom(_compare_members)
	
	for child in members_list.get_children():
		members_list.remove_child(child)
		
	for member in list:
		members_list.add_child(member)

func _compare_members(a:ProjectMember,b:ProjectMember):
	if _get_role_value(a.role.text)>_get_role_value(b.role.text):
		return true
	if _get_role_value(a.role.text)<_get_role_value(b.role.text):
		return false
	return a.display_name.text.naturalnocasecmp_to(b.display_name.text)

func _get_role_value(role:String):
		match role:
			"owner": return 3
			"manager": return 2
			"member": return 1
			"viewer": return 0
		return -1
