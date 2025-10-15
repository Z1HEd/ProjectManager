extends Button
class_name AnimationButton
# A button that starts an animation when pressed

@export var player : AnimationPlayer
@export var animation_name : String

func _ready() -> void:
	pressed.connect(_start_animation)

func _start_animation() -> void:
	player.play(animation_name)
