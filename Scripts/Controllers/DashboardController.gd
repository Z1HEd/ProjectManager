extends Control
class_name DashboardController

@onready var notifications_button = %Notifications
@onready var project_buttons : Array[NavigationButton] = [
	%Summary,
	%TaskBoard,
	%TaskList,
	%Timeline,
	%Chat,
]

@export var notifications_icon : CompressedTexture2D
@export var unread_notifications_icon : CompressedTexture2D

func _ready():
	set_project_buttons_enabled(false)
	_set_has_unread_notifications(false)
	Notifications.notifications_updated.connect(_on_notifications_updated)

func _on_notifications_updated():
	_set_has_unread_notifications(Notifications.list.size()>0)

func set_project_buttons_enabled(enabled : bool)->void:
	for button in project_buttons:
		button.disabled = !enabled

func _set_has_unread_notifications(value: bool):
	notifications_button.icon = unread_notifications_icon if value else notifications_icon
