extends Control
class_name TimelineTask

@onready var button_container :=$Panel
@onready var button : Button = $Panel/Button

var _task_id: String
var on_pressed: Callable

const MONTH_MS := 30*24*60*60*1000

func initialize(task_id:String,
		task_data:Dictionary,
		timeline_start_month:int,
		pressed_cb:Callable):
	
	_task_id = task_id
	on_pressed = pressed_cb
	
	var start_date = task_data.get("startDate",null)
	var due_date = task_data.get("dueDate",null)
	
	if start_date == null:
		start_date = due_date - MONTH_MS
		button.tooltip_text = "Due date: %s" % \
				Time.get_datetime_string_from_unix_time(due_date/1000, true)
		button.tooltip_text = button.tooltip_text.left(button.tooltip_text.length()-9)
		button.theme_type_variation = "TimelineTaskDueOnly"
	elif due_date == null:
		due_date = start_date + MONTH_MS
		button.tooltip_text = "Start date: %s" % \
				Time.get_datetime_string_from_unix_time(start_date/1000, true)
		button.tooltip_text = button.tooltip_text.left(button.tooltip_text.length()-9)
		button.theme_type_variation = "TimelineTaskStartOnly"
	else:
		var start_string := Time.get_datetime_string_from_unix_time(start_date/1000, true)
		start_string = start_string.left(start_string.length()-9)
		var due_string := Time.get_datetime_string_from_unix_time(due_date/1000, true)
		due_string = due_string.left(due_string.length()-9)
		button.tooltip_text = "%s • %s" % [start_string,due_string]
		button.theme_type_variation = "TimelineTask"
	
	button_container.position.x = get_button_x(start_date,timeline_start_month)
	button_container.size.x = get_button_x(due_date,timeline_start_month) - button_container.position.x
	
	

func get_button_x(start_date, timeline_start_month) -> float:
	
	var month_index_f := TimelineController.ts_to_month(start_date)

	var offset_months := month_index_f - float(timeline_start_month)

	return offset_months * TimelineController.MONTH_WIDTH_PX

func _on_button_pressed() -> void:
	on_pressed.call(_task_id)
