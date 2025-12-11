extends Tab
class_name TeamChatController

@onready var no_messages_text : Label = %NoMessagesLabel
@onready var messages_container : VBoxContainer = %MessagesContainer
@onready var scroll : ScrollContainer = %ScrollContainer
@onready var message_input_panel = %MessageInputPanel

@export var message_prefab := preload("res://Scenes/Elements/ChatMessage.tscn")
@export var date_label_prefab := preload("res://Scenes/Elements/DateLabel.tscn")

var oldest : String
var oldest_date: String
var newest_date: String
var _connected_vb : VScrollBar = null
var message_ids := []
var user_role := ""
var is_busy := false

func _ready():
	_clear()

func open():
	message_input_panel.visible = Project.user_role != "viewer"
	user_role = Project.user_role
	
	oldest = ""
	oldest_date = ""
	newest_date = ""
	message_ids = []
	
	Project.update_member_names()
	Project.chat_updated.connect(append_messages)
	Project.project_updated.connect(on_project_updated)
	append_messages(Project.chat_messages)

func close():
	_clear()
	Project.chat_updated.disconnect(append_messages)
	Project.project_updated.disconnect(on_project_updated)

func _clear():
	for child in messages_container.get_children():
		child.queue_free()
	no_messages_text.visible = true

func on_project_updated():
	if Project.user_role != user_role:
		open()

func append_messages(arr:Array, from_top := false):
	if arr.size() == 0: return
	no_messages_text.visible = false
	var sb = scroll.get_v_scroll_bar()
	
	var was_at_bottom : bool = sb == null or \
			sb.value >= sb.max_value - sb.page
	
	var candidate_id = arr[-1]["id"] if from_top else arr[0]["id"]
	if oldest == "" or candidate_id < oldest:
		oldest = candidate_id
	
	if oldest_date == "":
		oldest_date = Time.get_date_string_from_unix_time(arr[0]["ts_server"]/1000)
		newest_date = oldest_date
		add_date_label(oldest_date)
	
	for m in arr:
		if message_ids.count(m["id"])>0:
			continue
		message_ids.append(m["id"])
		var item := message_prefab.instantiate()
		messages_container.add_child(item)
		
		var current_date = Time.get_date_string_from_unix_time(m["ts_server"]/1000)
		if from_top:
			if current_date < oldest_date:
				oldest_date = current_date
				add_date_label(oldest_date,true)
			messages_container.move_child(item,1)
		elif current_date > newest_date:
			newest_date = current_date
			add_date_label(newest_date)
			messages_container.move_child(item,messages_container.get_child_count()-1)
		
		var sender_id = str(m.get("authorId", ""))
		var sender_name = Project.get_member_name(sender_id)
		var ts = int(m.get("ts_server", 0))
		var body = str(m.get("text", ""))
		item.set_data(sender_name, ts, body)
	
	if was_at_bottom and sb:
		await get_tree().process_frame
		sb.value = sb.max_value
	
	call_deferred("_ensure_vscroll_connected")

func send_message(msg: String) -> void:
	
	var on_fail = func(_err):
		no_messages_text.text = "Error while sending a message: %s" %_err
	
	ChatService.send_message(
		Project.pid,
		msg,
		func(_res):pass,
		on_fail)

func add_date_label(date:String,from_top = false):
	var label : Label = date_label_prefab.instantiate()
	label.text = date
	messages_container.add_child(label)
	if from_top:
		messages_container.move_child(label,0)

func _on_scrolled_to_top() -> void:
	if oldest == "" or is_busy: return
	
	var on_success = func(res:Dictionary):
		is_busy = false
		if res.size()>0:
			var arr = to_sorted_array(res)
			arr.reverse()
			append_messages(arr,true)
	
	is_busy = true
	ChatService.fetch_before(Project.pid,oldest,25,on_success)

# Needed to connect scroll callback for old messages loading
func _ensure_vscroll_connected() -> void:
	var vb = scroll.get_v_scroll_bar()
	if vb == _connected_vb:
		return
		
	if _connected_vb and is_instance_valid(_connected_vb):
		_connected_vb.value_changed.disconnect(_on_vscroll_changed)
	_connected_vb = null
	
	if vb:
		vb.value_changed.connect(_on_vscroll_changed)
	_connected_vb = vb

func _on_vscroll_changed(value: float) -> void:
	if value <= 1.0:
		_on_scrolled_to_top()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_ensure_vscroll_connected")

func to_sorted_array(messages:Dictionary) ->Array:
	var arr :=[]
	
	for msg_id in messages.keys():
		var m = messages[msg_id]
		m["id"] = msg_id
		arr.append(m)
	
	arr.sort_custom(_sort_by_ts_server)
	
	return arr

func _sort_by_ts_server(a, b) -> bool:
	var at := int(a.get("ts_server", 0))
	var bt := int(b.get("ts_server", 0))
	return at < bt
