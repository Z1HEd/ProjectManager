extends Tab
class_name TeamChatController

@onready var title :Label = %Title
@onready var no_messages_text : Label = %NoMessagesLabel
@onready var messages_container : VBoxContainer = %MessagesContainer

@export var message_prefab := preload("res://Scenes/Elements/ChatMessage.tscn")

func open():
	title.text = "Loading messages..."

	for child in messages_container.get_children():
		child.queue_free()

	var on_success = func(res:Dictionary):
		if res.size() == 0:
			no_messages_text.visible = true
			title.text = "Team Chat"
			return

		no_messages_text.visible = false
		var arr := []
		for msg_id in res.keys():
			var m = res[msg_id]
			m["_id"] = msg_id
			arr.append(m)

		arr.sort_custom(_sort_by_ts_server)

		for m in arr:
			var item = message_prefab.instantiate()
			messages_container.add_child(item)
			var sender_name = str(m.get("authorId", ""))
			var ts = int(m.get("ts_server", 0))
			var body = str(m.get("text", ""))
			item.set_data(sender_name, ts, body)

		title.text = "Team Chat"

	var on_fail = func(err):
		no_messages_text.visible = true
		no_messages_text.text = "Error: %s" % err
		title.text = "Team Chat"

	ChatService.fetch_recent(Project.pid, 25, on_success, on_fail)
	
	ChatService.start_listening(Project.pid,_on_new_messages,on_fail)

func _on_new_messages(res):
	print(res)

func send_message(msg: String) -> void:
	
	var on_fail = func(_err):
		no_messages_text.text = "Error while sending a message: %s" %_err
	
	ChatService.send_message(
		Project.pid,
		msg,
		func(_res):pass,
		on_fail
	)

func _sort_by_ts_server(a, b) -> bool:
	var at := int(a.get("ts_server", 0))
	var bt := int(b.get("ts_server", 0))
	return at < bt
