extends Node
class_name NotificationsManager

signal notifications_updated

var list: Array = []

func start_listening() -> void:
	list.clear()
	InviteService.stop_listening_all()
	InviteService.start_listening(Session.uid,_update_invites)

func _update_invites(update: Dictionary) -> void:
	for project_id in update.keys():
		var invite_obj = update[project_id]

		if invite_obj == null:
			for i in range(list.size() - 1, -1, -1):
				var _notification = list[i]
				if _notification.get("type", "") == "project_invite" and \
						_notification.get("project_id", "") == project_id:
					list.remove_at(i)
			continue

		var role = invite_obj.get("role", "member")
		var entry = {
			"type": "project_invite",
			"project_id": project_id,
			"role": role,
			"title": "Invitation to a project",
			"description": "Role: %s\n%s" % [
				role,
				invite_obj.get("inviteMessage", "")
			]
		}

		var replaced := false
		for i in range(list.size()):
			var _notification = list[i]
			if _notification.get("type", "") == "project_invite" and \
					_notification.get("project_id", "") == project_id:
				list[i] = entry
				replaced = true
				break
		if not replaced:
			list.append(entry)
	
	notifications_updated.emit()
	if update.size()==1 and update[update.keys()[0]] != null:
		AppNotifications.push("You have recieved a new invite!")
	if update.size()>1:
		AppNotifications.push("You have recieved new invites!")
