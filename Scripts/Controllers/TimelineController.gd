extends Tab
class_name TimelineController

@onready var create_task_button : Button = %CreateTaskButton
@onready var months_container : HBoxContainer = %MonthsContainer
@onready var tasks_titles : VBoxContainer = %TasksTitlesContainer
@onready var tasks_bodies : VBoxContainer = %TasksRows
@onready var tasks_scroll : ScrollContainer = %TasksScrollContainer

@export var month_label_prefab := preload("res://Scenes/Elements/MonthLabel.tscn")
@export var task_title_label_prefab := preload("res://Scenes/Elements/TimelineTaskTitleLabel.tscn")
@export var task_body_prefab := preload("res://Scenes/Elements/TimelineTaskBody.tscn")

@onready var view_edit_task_popup : ViewEditTaskPopup= %ViewEditTaskPopup
@onready var create_task_popup : CreateTaskPopup= %CreateTaskPopup

const MONTH_WIDTH_PX := 200

var tasks_data := {}
# not needed for sorting here, but is required for starting a listener
var latest_updated_at := 0

var MONTHS_BEFORE := 4
var MONTHS_AFTER := 6
var month_names := ["January","February","March","April","May","June","July","August","September","October","November","December"]

var start_index : int
var end_index : int
var filter := ""

func open():
	
	create_task_button.visible = Project.user_role == "owner" ||\
			Project.user_role == "manager"
	
	var _on_success = func(tasks: Dictionary):
		update_task_data(tasks)
		TaskService.start_listening(Project.pid,latest_updated_at,update_task_data)
	
	Project.update_member_names()
	TaskService.get_all(Project.pid, _on_success)

func close():
	TaskService.stop_listening(Project.pid)


func update_task_data(updated: Dictionary):
	for task_id in updated.keys():
		var patch = updated[task_id]
		
		if patch == null:
			tasks_data.erase(task_id)
		elif tasks_data.has(task_id):
			tasks_data[task_id].merge(patch, true)
		else:
			tasks_data[task_id] = patch.duplicate(true)

		if tasks_data.has(task_id) and tasks_data[task_id].has("updatedAt"):
			var task_updated_at = tasks_data[task_id]["updatedAt"]
			if task_updated_at > latest_updated_at:
				latest_updated_at = task_updated_at
	_refresh_timeline()

func _refresh_timeline():
	
	clear_timeline()
	
	var filtered := {}
	for task in tasks_data.keys():
		if (!tasks_data[task].has("startDate") and !tasks_data[task].has("dueDate"))\
				or (filter !="" and !tasks_data[task]["title"].to_lower().contains(filter)):
			continue
		filtered[task] = tasks_data[task]
	
	update_months(filtered)
	
	for task in filtered:
		
		var new_title := task_title_label_prefab.instantiate()
		new_title.text = filtered[task]["title"]
		
		tasks_titles.add_child(new_title)
		
		var new_task_body :TimelineTask= task_body_prefab.instantiate()
		new_task_body.call_deferred("initialize", 
				task,filtered[task],start_index,on_task_pressed)
		
		tasks_bodies.add_child(new_task_body)
	
	# Not even call_deferred is enough for scrollbar's max_size to be initialized
	await Engine.get_main_loop().process_frame
	set_scroll_to_current_date()

func clear_timeline():
	for child in tasks_bodies.get_children():
		child.queue_free()
	
	for child in months_container.get_children():
		child.queue_free()
	
	for child in tasks_titles.get_children():
		child.queue_free()

func update_months(filtered: Dictionary) -> void:

	var min_index := int(ts_to_month(Time.get_unix_time_from_system()*1000))
	var max_index := int(ts_to_month(Time.get_unix_time_from_system()*1000))

	for task_id in filtered.keys():
		var task = filtered[task_id]

		var start_ts = task.get("startDate", null)
		var due_ts = task.get("dueDate", null)

		var s_index = null
		var d_index = null

		if start_ts != null:
			s_index = int(ts_to_month(start_ts))
		if due_ts != null:
			d_index = int(ts_to_month(due_ts))

		if s_index == null and d_index != null:
			s_index = d_index - 1
		if d_index == null and s_index != null:
			d_index = s_index + 1

		if s_index < min_index:
			min_index = s_index
		if d_index > max_index:
			max_index = d_index
			
	start_index = min_index - MONTHS_BEFORE
	end_index = max_index + MONTHS_AFTER

	for i in range(start_index, end_index + 1):
		@warning_ignore("integer_division")
		var year := int(i / 12)
		var month := int(i % 12) + 1
		var label := month_label_prefab.instantiate()
		label.text = "%s %d" % [month_names[month - 1], year]
		months_container.add_child(label)

func on_task_pressed(task_id:String):
	view_edit_task_popup.visible = true
	view_edit_task_popup.initialize(task_id,tasks_data[task_id],Project.user_role)

func set_scroll_to_current_date():
	var sb = tasks_scroll.get_h_scroll_bar()
	if sb == null: return
	
	var value = (ts_to_month(Time.get_unix_time_from_system()*1000)-
			start_index)*MONTH_WIDTH_PX - sb.page/2
	sb.value = value

static func ts_to_month(ts: float) -> float:
	
	@warning_ignore("narrowing_conversion")
	var sec :int= ts/1000

	var dt := Time.get_datetime_dict_from_unix_time(sec) # { "year", "month", "day", ... }
	var year := int(dt["year"])
	var month := int(dt["month"])

	var month_index := float(year * 12 + month - 1)

	var start_dt := { "year": year, "month": month, "day": 1, "hour": 0, "minute": 0, "second": 0 }
	var next_year := year
	var next_month := month + 1
	if next_month == 13:
		next_month = 1
		next_year += 1
	var next_dt := { "year": next_year, "month": next_month, "day": 1, "hour": 0, "minute": 0, "second": 0 }

	var start_sec := float(Time.get_unix_time_from_datetime_dict(start_dt))
	var next_sec := float(Time.get_unix_time_from_datetime_dict(next_dt))
	var month_len := next_sec - start_sec

	var frac = clamp((sec - start_sec) / month_len, 0.0, 1.0)
	return month_index + frac

static func month_index_to_ts(month_index: int) -> int:
	var year := month_index / 12.0
	var month := month_index % 12 + 1
	if month <= 0:
		month += 12
		year -= 1

	var dt := {
		"year": year,
		"month": month,
		"day": 1,
		"hour": 0,
		"minute": 0,
		"second": 0
	}
	var sec := Time.get_unix_time_from_datetime_dict(dt)
	return sec * 1000

func _on_create_task_button_pressed() -> void:
	create_task_popup.visible=true
	create_task_popup.initialize()

func _on_line_edit_text_changed(new_text: String) -> void:
	filter = new_text.to_lower()
	_refresh_timeline()
