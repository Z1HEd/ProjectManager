extends Tab
class_name TeamChatController

@onready var title :Label = %Title
@onready var no_messages_text : Label = %NoMessagesLabel
@onready var messages_container : VBoxContainer = %MessagesContainer


func send_message(msg: String) -> void:
	pass # Replace with function body.
