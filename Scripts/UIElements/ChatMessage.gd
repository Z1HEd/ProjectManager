extends Control
class_name ChatMessage

@onready var sender : Label = %Sender
@onready var time : Label = %Time
@onready var body : RichTextLabel = %Body

func set_data(sender_name:String, time_unix:int, message:String):
	sender.text = sender_name
	time.text = Time.get_time_string_from_unix_time(time_unix).left(5)
	body.text = message
