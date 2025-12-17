extends Tab

@onready var members_list = %MembersContainer
@onready var project_name = %ProjectName
@onready var project_description = %ProjectDescription
@onready var member_count_label = %MemberCountLabel
@onready var tasks_summary_table: CustomDynamicTable = %TasksSummaryTable

@onready var overdue_tasks_container: VBoxContainer = %OverdueTasksContainer
@onready var no_overdue_label: Label = %NoOverdueLabel
@onready var deadlines_container: VBoxContainer = %DeadlinesContainer
@onready var no_deadlines_label: Label = %NoDeadlinesLabel


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

func open():
	
	update_project_info()
	update_members_info()
	update_tasks_summary({})
	update_overdue_tasks({})
	update_deadlines({})
	
	Project.project_updated.connect(update_project_info)
	Project.project_updated.connect(update_members_info)
	Project.tasks_updated.connect(update_tasks_summary)
	Project.tasks_updated.connect(update_overdue_tasks)
	Project.tasks_updated.connect(update_deadlines)

func close(): 
	Project.project_updated.disconnect(update_project_info)
	Project.project_updated.disconnect(update_members_info)
	Project.tasks_updated.disconnect(update_tasks_summary)
	Project.tasks_updated.disconnect(update_overdue_tasks)
	Project.tasks_updated.disconnect(update_deadlines)

func update_project_info():
	project_name.text = Project.project_name
	project_description.text = Project.project_description
	
	leave_project_button.visible = Project.user_role != "owner"
	edit_project_button.visible = Project.user_role == "owner"
	delete_project_button.visible = Project.user_role == "owner"

func update_members_info():
	member_count_label.text = "(%s)" % Project.members.size()
	add_member_button.visible =  Project.user_role == "owner"
	
	for member in members_list.get_children():
		member.queue_free()
	
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

func update_tasks_summary(_update:Dictionary):
	tasks_summary_table.set_headers(["Status","Assigned to you",
			"Unassigned","Overall"])
	
	var data := []
	data.append(["To Do",
			_count_tasks(_task_filter.bind("to_do",Session.uid)),
			_count_tasks(_task_filter.bind("to_do","")),
			_count_tasks(_task_filter.bind("to_do","ANY"))])
	data.append(["In Progress",
			_count_tasks(_task_filter.bind("in_progress",Session.uid)),
			_count_tasks(_task_filter.bind("in_progress","")),
			_count_tasks(_task_filter.bind("in_progress","ANY"))])
	data.append(["Done",
			_count_tasks(_task_filter.bind("done",Session.uid)),
			_count_tasks(_task_filter.bind("done","")),
			_count_tasks(_task_filter.bind("done","ANY"))])
	data.append(["Cancelled",
			_count_tasks(_task_filter.bind("cancelled",Session.uid)),
			_count_tasks(_task_filter.bind("cancelled","")),
			_count_tasks(_task_filter.bind("cancelled","ANY")),])
	data.append(["Total",
			_count_tasks(_task_filter.bind("",Session.uid)),
			_count_tasks(_task_filter.bind("","")),
			_count_tasks(_task_filter.bind("","ANY")),])
	tasks_summary_table.set_data(data)

func update_overdue_tasks(_update:Dictionary):
	for child in overdue_tasks_container.get_children():
		child.queue_free()
	
	await Engine.get_main_loop().process_frame
	
	for id in Project.tasks_data.keys():
		var task :Dictionary= Project.tasks_data[id]
		
		if !task.has("dueDate"):
			continue
		if task["status"] != "to_do" and task["status"] != "in_progress": 
			continue
		if task["dueDate"]/1000>= Time.get_unix_time_from_system():
			continue
		
		var date_string := Time.get_date_string_from_unix_time(task["dueDate"]/1000)
		
		var label = RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.text = "[color=red]%s[/color] %s" % [date_string,task["title"]]
		
		overdue_tasks_container.add_child(label)
	
	no_overdue_label.visible = overdue_tasks_container.get_child_count()==0

func update_deadlines(_update:Dictionary):
	for child in deadlines_container.get_children():
		child.queue_free()
	
	await Engine.get_main_loop().process_frame
	
	var deadlines_strings := []
	
	for id in Project.tasks_data.keys():
		var task : Dictionary = Project.tasks_data[id]
		
		if !task.has("dueDate"):
			continue
		if task["status"] != "to_do" and task["status"] != "in_progress": 
			continue
		if task["dueDate"]/1000 < Time.get_unix_time_from_system():
			continue
		
		var date_string := Time.get_date_string_from_unix_time(task["dueDate"]/1000)
		
		deadlines_strings.append("[color=yellow]%s[/color] %s" % \
				[date_string,task["title"]])
	
	deadlines_strings.sort()
	
	for deadline in deadlines_strings:
	
		var label = RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.text = deadline
		
		deadlines_container.add_child(label)
	
	no_deadlines_label.visible = deadlines_container.get_child_count()==0


#region callbacks
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
#endregion

#region helper functions

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

func _task_filter(task:Dictionary,status:="",assignee := "ANY")->bool:
	return (task["status"] == status or status == "")\
			and (task.get("assignedTo","") == assignee or assignee == "ANY")

func _count_tasks(predicate : Callable = func(_task:Dictionary)->bool:return true):
	var count := 0
	for task in Project.tasks_data.keys():
		if predicate.call(Project.tasks_data[task]):
			count += 1
	return count

#endregion
