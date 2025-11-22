extends Control
class_name ViewEditTaskPopup

@onready var title : Label = %Title
@onready var created :Label = %CreatedLabel
@onready var last_modified : Label = %LastModifiedLabel

@onready var name_input : LineEdit = %NameEdit
@onready var description_input : TextEdit = %DescriptionEdit
@onready var status_input : OptionButton = %StatusOptionButton
@onready var priority_input : OptionButton = %PriorityOptionButton
@onready var assignee_input : OptionButton = %AssigneeOptionButton

@onready var submit_button : Button = %SubmitButton
@onready var delete_button : Button = %DeleteButton
@onready var cancel_button : Button = %CancelButton

@onready var error_label := %ErrorLabel

signal delete_pressed(id:String)
var current_id :String
var data :Dictionary

func initialize(task_id:String, task_data: Dictionary,user_role:String):
	current_id = task_id
	data = task_data
	title.text = "Task %s" % task_id
	
	@warning_ignore("integer_division")
	var creation_time = Time.get_datetime_string_from_unix_time(
			int(task_data["createdAt"])/1000).replace("T"," ")
	creation_time = creation_time.left(creation_time.length()-3)
	
	@warning_ignore("integer_division")
	var edited_time = Time.get_datetime_string_from_unix_time(
			int(task_data["updatedAt"])/1000).replace("T"," ")
	edited_time = edited_time.left(edited_time.length()-3)
	
	created.text = "Created by: %s at %s" % \
			[Project.get_member_name(task_data["creatorId"]), creation_time]
	last_modified.text = "Last modified by: %s at %s" % \
			[Project.get_member_name(task_data["lastModifiedBy"]), edited_time]
	
	name_input.text = task_data["title"]
	description_input.text = task_data["description"]
	_set_status(task_data["status"])
	priority_input.select(task_data["priority"])
	
	assignee_input.clear()
	assignee_input.add_item("")
	for member_id in Project.members_names.keys():
		if Project.members[member_id] == "viewer": continue
		assignee_input.add_item(Project.get_member_name(member_id))
		if member_id == task_data.get("assignedTo",""):
			assignee_input.select(assignee_input.item_count-1)
	
	var is_manager := user_role == "owner" or user_role == "manager"
	var is_assignee = Session.uid == task_data.get("assignedTo","")
	var can_edit = is_manager or is_assignee
	
	name_input.editable = can_edit
	description_input.editable = can_edit
	assignee_input.disabled = !is_manager
	delete_button.disabled = !is_manager
	priority_input.disabled = !can_edit
	status_input.disabled = !can_edit
	submit_button.disabled = !can_edit

func _on_submit_success(_res):
	submit_button.disabled = false
	cancel_button.disabled = false
	
	visible = false

func _on_submit_fail(err_msg: String):
	error_label.text = err_msg
	error_label.visible = true
	submit_button.disabled = false
	cancel_button.disabled = false

func _on_submit_button_pressed() -> void:
	error_label.visible = false
	
	var new_data = {}
	var task_name = name_input.text.strip_edges()
	if task_name == "":
		error_label.text = "Task must have a title!"
		error_label.visible = true
		return
	
	if task_name !=data["title"]: new_data["title"] = task_name
	var description = description_input.text.strip_edges()
	if description !=data["description"]: new_data["description"] = description
	var priority = priority_input.selected
	if priority !=data["priority"]: new_data["priority"] = priority
	
	var status = _get_status()
	if status !=data["status"]: 
		new_data["status"] = status
	var assignee_uid := _get_assignee_uid()
	if assignee_uid != data.get("assignedTo",""):
		new_data["assignedTo"] = assignee_uid
	
	if new_data == {}: return
	
	submit_button.disabled = true
	cancel_button.disabled = true
	
	
	TaskService.modify_task(
			Project.pid, 
			current_id,
			new_data, 
			_on_submit_success, 
			_on_submit_fail)

func _on_cancel_button_pressed() -> void:
	visible = false

func _on_delete_button_pressed() -> void:
	visible = false
	delete_pressed.emit(current_id)

func _get_status()->String:
	match status_input.get_selected():
		0: return "to_do"
		1: return "in_progress"
		2: return "done"
		3: return "cancelled"
	return ""

func _set_status(status:String):
	match status:
		"to_do": status_input.select(0)
		"in_progress": status_input.select(1)
		"done": status_input.select(2)
		"cancelled": status_input.select(3)

func _get_assignee_uid()->String:
	if assignee_input.get_selected() == -1 :
		return ""
	var assignee_name = assignee_input.get_item_text(assignee_input.get_selected())
	for uid in Project.members_names.keys():
		if Project.members_names[uid] == assignee_name:
			return uid
	return ""
