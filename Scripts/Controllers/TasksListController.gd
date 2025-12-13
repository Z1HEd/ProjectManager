extends Tab

@onready var create_task_popup : CreateTaskPopup = %CreateTaskPopup
@onready var confirm_critical_popup : ConfirmCriticalPopup = %ConfirmCriticalPopup
@onready var view_edit_task_popup :ViewEditTaskPopup= %ViewEditTaskPopup

@onready var tasks_table : CustomDynamicTable = %TasksTable
@onready var create_task_button : Button = %CreateTaskButton

var columns_texts := \
		["Title","Assignee","Status","Priority","Last updated","Start date","Due date", "ID"]
var columns_data := \
		["title","assignedTo","status","priority","updatedAt", "startDate", "dueDate", "id"]

var last_sort_col_index := columns_data.find("updatedAt")
var last_sort_asc := false 

func _ready():
	tasks_table.edit_callback = on_edit_task_pressed
	
	tasks_table.set_data([])
	tasks_table.set_headers(columns_texts)
	
	tasks_table.column_mappers[columns_data.find("assignedTo")] = \
			func(id:String)->String:
				return Project.get_member_name(id)
	
	tasks_table.column_mappers[columns_data.find("status")] = \
			func(status:String)->String:
				match status:
					"to_do": return "To do"
					"in_progress": return "In progress"
					"done": return "Done"
					"cancelled": return "Cancelled"
				return "Unknown status"
	
	tasks_table.column_mappers[columns_data.find("priority")] = \
			func(priority:String)->String:
				match int(priority):
					0: return "Low"
					1: return "Medium"
					2: return "High"
					3: return "Critical"
				return "Unknown priority"
	
	tasks_table.column_mappers[columns_data.find("updatedAt")] = \
			func(time:String)->String:
				var time_secs := float(time)/1000
				var time_string := Time.get_datetime_string_from_unix_time(int(time_secs), true)
				return time_string.left(time_string.length()-3)
	
	tasks_table.column_mappers[columns_data.find("startDate")] = \
			func(time:String)->String:
				if time == "": return "_"
				var time_secs := float(time)/1000
				var time_string := Time.get_datetime_string_from_unix_time(int(time_secs), true)
				return time_string.left(time_string.length()-9)
	
	tasks_table.column_mappers[columns_data.find("dueDate")] = \
			func(time:String)->String:
				if time == "": return "_"
				var time_secs := float(time)/1000
				var time_string := Time.get_datetime_string_from_unix_time(int(time_secs), true)
				return time_string.left(time_string.length()-9)

func open():
	
	set_create_task_button_visible()
	
	Project.tasks_updated.connect(on_tasks_updated)
	Project.project_updated.connect(set_create_task_button_visible)
	_refresh_table()

func close():
	tasks_table.set_data([])
	Project.tasks_updated.disconnect(on_tasks_updated)
	Project.project_updated.disconnect(set_create_task_button_visible)

func set_create_task_button_visible():
	create_task_button.visible = Project.user_role == "owner" ||\
			Project.user_role == "manager"

func on_tasks_updated(_update:Dictionary):
	_refresh_table()

func _tasks_to_array(tasks_data:Dictionary) -> Array:
	var rows: Array = []
	for task_id in tasks_data.keys():
		var t = tasks_data[task_id]
		var row: Array = []
		for col_name in columns_data:
			if col_name == "id":
				row.append(task_id)
			else:
				row.append(t.get(col_name, ""))
		rows.append(row)
	return rows

func _refresh_table() -> void:
	var rows = _tasks_to_array(Project.tasks_data)
	
	tasks_table.set_data(rows)
	
	tasks_table.ordering_data(last_sort_col_index, last_sort_asc)

func _on_table_header_clicked(col_index: int) -> void:
	
	if last_sort_col_index == col_index:
		last_sort_asc = not last_sort_asc
	else:
		last_sort_col_index = col_index
		last_sort_asc = false
	
	tasks_table.ordering_data(last_sort_col_index, last_sort_asc)

func on_edit_task_pressed(row_index: int):
	var task_id = tasks_table.get_cell_value(row_index,columns_data.find("id"))
	view_edit_task_popup.visible = true
	view_edit_task_popup.initialize(task_id,
			Project.tasks_data[task_id],Project.user_role)

func _on_create_task_button_pressed() -> void:
	create_task_popup.visible = true
	create_task_popup.initialize(0)

func _on_delete_task_pressed(id: String) -> void:
	confirm_critical_popup.visible = true
	
	confirm_critical_popup.set_info("Delete task?",
			'All data related to "%s" will be deleted irreversibly.'%\
					Project.tasks_data[id]["title"]+
			' Enter "DELETE" to confirm',
			"DELETE")
	
	confirm_critical_popup.set_callbacks(func(_res):
			TaskService.delete_task(Project.pid,id))
