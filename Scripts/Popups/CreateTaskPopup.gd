extends Control
class_name CreateTaskPopup

@onready var name_input : LineEdit = %NameEdit
@onready var description_input : TextEdit = %DescriptionEdit
@onready var status_input : OptionButton = %StatusOptionButton
@onready var priority_input : OptionButton = %PriorityOptionButton
@onready var assignee_input : OptionButton = %AssigneeOptionButton

@onready var create_button : Button = %SubmitButton
@onready var cancel_button : Button = %CancelButton

@onready var start_date_button : CalendarButton = %StartDatePicker
@onready var due_date_button : CalendarButton = %DueDatePicker
@onready var clear_start_date_button : Button = %ClearStartDateButton
@onready var clear_due_date_button : Button = %ClearDueDateButton

var start_date_unix := -1
var due_date_unix := -1

func initialize(initial_status: int):
	name_input.text = ""
	description_input.text = ""
	status_input.select(initial_status)
	assignee_input.clear()
	assignee_input.add_item("")
	_on_clear_start_date_button_pressed()
	_on_clear_due_date_button_pressed()
	for member_id in Project.members_names.keys():
		if Project.members[member_id] == "viewer": continue
		assignee_input.add_item(Project.get_member_name(member_id))

func _on_submit_success(_res):
	create_button.disabled = false
	cancel_button.disabled = false
	
	visible = false
	
	AppNotifications.push("New task has been created")

func _on_submit_fail(_err_msg: String):
	create_button.disabled = false
	cancel_button.disabled = false

func _on_submit_button_pressed() -> void:
	var title = name_input.text.strip_edges()
	var description = description_input.text.strip_edges()
	if title == "":
		AppNotifications.push("Task must have a title!")
		return

	var status = _get_status()
	var priority = priority_input.selected
	var assignee_uid := _get_assignee_uid()

	var task_data: Dictionary = {
		"title": title,
		"description": description,
		"priority": priority,
		"status": status
	}
	
	if assignee_uid != "":
		task_data["assignedTo"] = assignee_uid
	if start_date_unix >= 0:
		task_data["startDate"] = start_date_unix
	if due_date_unix >= 0:
		task_data["dueDate"] = due_date_unix

	create_button.disabled = true
	cancel_button.disabled = true
	TaskService.create_task(
		Project.pid,
		task_data,
		_on_submit_success,
		_on_submit_fail
	)

func _on_cancel_button_pressed() -> void:
	visible = false

func _get_status()->String:
	match status_input.get_selected():
		0: return "to_do"
		1: return "in_progress"
		2: return "done"
		3: return "cancelled"
	return ""

func _get_priority()->String:
	match priority_input.get_selected():
		0: return "low"
		1: return "medium"
		2: return "high"
		3: return "critical"
	return ""

func _get_assignee_uid()->String:
	if assignee_input.get_selected() == -1 :
		return ""
	var assignee_name = assignee_input.get_item_text(assignee_input.get_selected())
	for uid in Project.members_names.keys():
		if Project.members_names[uid] == assignee_name:
			return uid
	return ""


func _on_clear_start_date_button_pressed() -> void:
	start_date_unix = -1
	start_date_button.clear()
	clear_start_date_button.visible = false

func _on_clear_due_date_button_pressed() -> void:
	due_date_unix = -1
	due_date_button.clear()
	clear_due_date_button.visible = false

# Other timestamps are in milliseconds, so i will make these ones too 
func _on_start_date_picker_calendar_confirmed(date: Dictionary, _time: Dictionary) -> void:
	start_date_unix = Time.get_unix_time_from_datetime_dict(date) * 1000
	clear_start_date_button.visible = true

func _on_due_date_picker_calendar_confirmed(date: Dictionary, _time: Dictionary) -> void:
	due_date_unix = Time.get_unix_time_from_datetime_dict(date) * 1000
	clear_due_date_button.visible = true
