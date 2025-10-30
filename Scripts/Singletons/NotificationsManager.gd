extends Node
class_name NotificationsManager

signal notifications_updated

var list: Array = []

func _ready() -> void:
	Session.connect("on_authenticated", _on_user_authenticated)

func _on_user_authenticated() -> void:
	load_notifications()

func load_notifications() -> void:
	if Session.uid == null or Session.uid == "":
		list.clear()
		emit_signal("notifications_updated")
		return

	list.clear()
	
	var _on_success = func(result):
		# result is a dictionary of project_id -> invite_obj
		for project_id in result.keys():
			var invite_obj = result[project_id]
			list.append({
				"type": "project_invite",
				"project_id": project_id,
				"role": invite_obj.get("role", "member"),
				"title": "Invitation to a project",
				"description": "Role: %s\n%s" % [
					invite_obj.get("role", "member"),
					invite_obj.get("invite_message", "")
				]
			})
		# Future: load other notifications here, append to notifications array
		emit_signal("notifications_updated")
	
	var _on_fail = func(err):
		push_warning("Failed to load invites: %s" % str(err))
		emit_signal("notifications_updated")
	
	InviteService.get_user_invites(Session.uid,
		_on_success,
		_on_fail
	)
