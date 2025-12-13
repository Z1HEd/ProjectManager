extends Control
class_name ChatMessage

@onready var sender : Label = %Sender
@onready var time : Label = %Time
@onready var body : RichTextLabel = %Body

func set_data(sender_name: String, time_unix: int, message: String) -> void:
	sender.text = sender_name
	@warning_ignore("integer_division")
	time.text = Time.get_time_string_from_unix_time(time_unix / 1000)
	time.text = time.text.left(-3)
	
	var max_w := get_max_width(message)
	body.custom_minimum_size.x = min(max_w, 500)
	
	message = format_message(message)
	body.text = message
	

func format_message(message:String) -> String:
	var safe := message.replace("[", "\\[").replace("]", "\\]")
	var parts := safe.split(" ")
	
	for i in parts.size():
		var t := parts[i]
		var url := ""
		if t.begins_with("http://") or t.begins_with("https://"):
			url = t
		elif t.begins_with("www."):
			url = "http://" + t
		if url != "":
			parts[i] = "[url=%s]%s[/url]" % [url, t]
			
	return " ".join(parts)

func get_max_width(message:String) -> int:
	var result := 0
	var lines := message.split("\n", false)
	var meas := Label.new()
	meas.visible = false
	meas.add_theme_font_size_override("normal_font_size",
			get_theme_font_size("normal_font_size"))
	
	for ln in lines:
		meas.text = ln
		var w := int(meas.get_minimum_size().x)
		if w > result:
			result = w
	meas.queue_free()
	return result

func _on_body_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
