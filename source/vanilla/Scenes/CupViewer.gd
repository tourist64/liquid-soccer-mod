extends Control

var ties = []
var gogoGame = false

func _ready():
	gogoGame = false
	$AcceptDialog.get_ok().text = "  ok!  "
	var tie_scene = load("res://Scenes/Tie.tscn")
	for i in range(32):
		var tie = tie_scene.instance()
		tie.visible = false
		ties.append(tie)
		$ColorRect / TieGroup.add_child(tie)
	$Transition._wipeOn()
	$ColorRect / PlayButton.grab_focus()
	_populateTies()

func _round_range():
	if Global.tournament.is_2026:
		match Global.tournament.roundp:
			0:
				return [0, 16]
			1:
				return [16, 24]
			2:
				return [24, 28]
			3:
				return [28, 30]
			4:
				return [30, 32]
		return [0, 0]
	if Global.tournament.roundp == 0:
		return [0, 8]
	if Global.tournament.roundp == 1:
		return [8, 12]
	if Global.tournament.roundp == 2:
		return [12, 14]
	if Global.tournament.roundp == 3:
		return [14, 15]
	return [0, 0]

func _round_title():
	if Global.tournament.is_2026:
		match Global.tournament.roundp:
			0:
				return "Round of 32"
			1:
				return "Round of 16"
			2:
				return "Quarter-finals"
			3:
				return "Semi-finals"
			4:
				return "Third place / Final"
		return "Tournament complete"
	return "Knockout Stage"

func _populateTies():
	$ColorRect / Title.text = "WC " + str(Global.tournament.year) + " - " + _round_title()
	for tie in ties:
		tie.visible = false
	var bounds = _round_range()
	var start = bounds[0]
	var end = bounds[1]
	for i in range(start, end):
		var teams_for_match = Global.tournament._knockout_teams(i)
		var t1 = teams_for_match[0]
		var t2 = teams_for_match[1]
		var t1p = t1 == Global.tTeam
		var t2p = t2 == Global.tTeam
		ties[i].rect_position = Vector2(40 + int(i - start) * 4, 100 + (i - start) * 58)
		ties[i]._setTie(Global.teams[t1].teamname, Global.teams[t2].teamname, Global.tournament.cround[i].x, Global.tournament.cround[i].y, t1p, t2p)
		ties[i].visible = true
	$ColorRect / PlayButton.text = _round_title()
	$ColorRect / PlayButton.disabled = Global.tournament.roundp > 4

func _on_Button_pressed():
	if gogoGame or Global.tournament.roundp > 4:
		return
	gogoGame = true
	var bounds = _round_range()
	var player_match = -1
	for i in range(bounds[0], bounds[1]):
		var teams_for_match = Global.tournament._knockout_teams(i)
		if teams_for_match[0] == Global.tTeam or teams_for_match[1] == Global.tTeam:
			player_match = i
			break
	if player_match < 0:
		Global.tournament.playertie = -1
		Global.tournament._gamePlayed(Vector2.ZERO)
		_populateTies()
		gogoGame = false
		return

	Global.tournament.playertie = player_match
	var player_teams = Global.tournament._knockout_teams(player_match)
	var t1 = player_teams[0]
	var t2 = player_teams[1]
	Global.p1human = t1 == Global.tTeam
	Global.p2human = not Global.p1human
	Global.final = Global.tournament.is_2026 and player_match == 31
	Global.team1 = Global.teamfiles[t1]
	Global.team2 = Global.teamfiles[t2]
	Global.doShootout = true
	Global._loadTeams(false, false)
	Global.toLoad = 1
	Global.stadium = 3 - int(Global.t1.level)
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")
	var cbreak = PokiSDK.commercialBreak()
	if not cbreak:
		get_tree().change_scene("res://Scenes/Game.tscn")

func _on_BackButton_pressed():
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")
	get_tree().change_scene("res://Scenes/Menu.tscn")

func _on_SaveButton_pressed():
	Global.tournament._saveState()
	$AcceptDialog.visible = true
