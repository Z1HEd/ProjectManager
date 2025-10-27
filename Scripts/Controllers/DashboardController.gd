extends Control
class_name DashboardController

@onready var project_buttons : Array[NavigationButton] = [
	%Summary,
	%TaskBoard,
	%TaskList,
	%Timeline,
	%Chat,
]

func _ready():
	set_project_buttons_enabled(false)

func set_project_buttons_enabled(enabled : bool)->void:
	for button in project_buttons:
		button.disabled = !enabled
