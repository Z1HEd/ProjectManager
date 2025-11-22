extends Node
class_name AppNotificationControl

@onready var _label = %Label
@onready var _progress = %ProgressBar

func start(msg: String, dur := 5.0) -> void:
	_label.text = msg
	
	_progress.max_value = dur
	_progress.value = dur
	
	process_mode = Node.PROCESS_MODE_INHERIT

func _process(delta: float) -> void:
	_progress.value -= delta
	if _progress.value <= 0.0:
		_close()

func _close() -> void:
	queue_free()
