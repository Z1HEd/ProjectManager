extends Tab

@onready var item_list = %NotificationsList
@onready var notification_title = %Title
@onready var notification_description = %Description
@onready var accept_button = %AcceptButton
@onready var decline_button = %DeclineButton

var selected_id := -1

func open():
	refresh_notification_list()
	
	Notifications.notifications_updated.connect(refresh_notification_list)

func close():
	Notifications.notifications_updated.disconnect(refresh_notification_list)

func refresh_notification_list():
	
	item_list.clear()
	selected_id = -1
	_reset_notification_details()
	
	for _notification in Notifications.list: 
		item_list.add_item(_notification["title"])

func _on_notifications_list_item_selected(index: int) -> void:
	selected_id = index
	
	notification_title.text = Notifications.list[index]["title"]
	notification_description.text = Notifications.list[index]["description"]
	decline_button.visible = Notifications.list[index]["type"] == "project_invite"
	accept_button.visible = true

func _on_accept_button_pressed() -> void:
	if Notifications.list[selected_id]["type"] == "project_invite":
		_accept_invite()

func _on_decline_button_pressed() -> void:
	if Notifications.list[selected_id]["type"] == "project_invite":
		_decline_invite()

func _accept_invite():
	accept_button.disabled = true
	decline_button.disabled = true
	
	var _on_success = func(_result):
		accept_button.disabled = false
		decline_button.disabled = false
		_reset_notification_details()
	
	var _on_fail = func(_err_msg):
		accept_button.disabled = false
		decline_button.disabled = false
	
	InviteService.accept_invite(
			Notifications.list[selected_id]["project_id"],
			Session.uid,
			Notifications.list[selected_id]["role"],
			_on_success,
			_on_fail)

func _decline_invite():
	accept_button.disabled = true
	decline_button.disabled = true
	
	var _on_success = func(_result):
		accept_button.disabled = false
		decline_button.disabled = false
		_reset_notification_details()
		
	
	var _on_fail = func(_err_msg):
		accept_button.disabled = false
		decline_button.disabled = false
	
	InviteService.decline_invite(
				Notifications.list[selected_id]["project_id"],
				Session.uid,
				_on_success,
				_on_fail)

func _reset_notification_details():
	accept_button.disabled = false
	decline_button.disabled = false
	notification_title.text = ""
	notification_description.text = ""
	decline_button.visible = false
	accept_button.visible = false
