extends Tab

@onready var members_list = %MembersContainer
@onready var project_name = %ProjectName
@onready var refresh_button = %RefreshButton
@onready var project_description = %ProjectDescription
@onready var error_message = %ErrorMessage
@onready var add_member_popup = %AddMemberPopup

@export var member_control_prefab = preload("res://Scenes/Elements/ProjectMember.tscn")

func _on_open():
	refresh_project()

var pid 
func refresh_project():
	refresh_button.disabled = true
	project_name.text = "Loading..."
	project_description.text = ""
	
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
	for old_member in members_list.get_children():
		old_member.queue_free()
	
	project_name.text = CurrentProject.project_name
	project_description.text = CurrentProject.project_description
	
	for member_uid in CurrentProject.members.keys():
		var member_control = member_control_prefab.instantiate() as ProjectMember
		# Call deffered because needs to set children's properties, 
		# which can only be done after _ready()
		member_control.call_deferred(
				"set_member",
				member_uid,
				CurrentProject.members[member_uid]
		)
		members_list.add_child(member_control)
	

func _on_add_member_button_pressed() -> void:
	add_member_popup.visible = true
