extends Control

var dgroups = []
var league
var groupsDone = false
var pgrp = 0
var but = null
var gogoGame = false

func _ready():
	gogoGame = false
	but = $TextureRect / AcceptDialog.get_ok()
	but.text = "  ok!  "
	league = Global.tournament
	$TextureRect / PlayTie.grab_focus()
	_ensureGroupViews()
	$TextureRect / Label.text = "WC " + str(league.year)
	initGroups()
	if league.cr > 2:
		groupsDone = true
		if league.balls.size() == 0:
			league._knockoutStage()
		$TextureRect / PlayTie.text = "Knockout Stage..."
	else:
		$TextureRect / PlayTie.text = "Play group round..."
	var col = pgrp % 4
	var row = int(pgrp / 4)
	$TextureRect / Groups.rect_position = Vector2(-col * 500, -row * 390)
	$Transition._wipeOn()

func _ensureGroupViews():
	dgroups = $TextureRect / Groups.get_children()
	while dgroups.size() < Global.tournament.group_count:
		var group_view = load("res://Scenes/WCGroup.tscn").instance()
		$TextureRect / Groups.add_child(group_view)
		dgroups.append(group_view)
	for i in range(dgroups.size()):
		dgroups[i].anchor_left = 0
		dgroups[i].anchor_top = 0
		dgroups[i].anchor_right = 0
		dgroups[i].anchor_bottom = 0
		dgroups[i].rect_position = Vector2((i % 4) * 500 + 20, int(i / 4) * 390 + 70)

func initGroups():
	for i in range(Global.tournament.group_count):
		dgroups[i]._initGroup(Global.tournament.groups[i])
		if Global.tournament.groups[i].playerteam > -1:
			pgrp = i

func _updateTable():
	for i in range(Global.tournament.group_count):
		dgroups[i]._updateTable()

func _updateFixtures():
	for i in range(Global.tournament.group_count):
		dgroups[i]._updateFixtures(Global.tournament.groups[i])

func _on_PlayTie_pressed():
	Global.isPenalties = false
	if Global.tType == 3:
		Global.isT1Womens = true
		Global.isT2Womens = true
	if gogoGame:
		return
	gogoGame = true
	if not groupsDone:
		league._setupPlayerTie()
		if Global.tTeam == Global.tT1:
			Global.p1human = true
			Global.p2human = false
		else:
			Global.p2human = true
			Global.p1human = false
		Global.team1 = Global.teamfiles[Global.tT1]
		Global.team2 = Global.teamfiles[Global.tT2]
		Global.doShootout = false
		Global._loadTeams(false, false)
		Global.toLoad = 1
		Global.stadium = 3 - int(Global.t1.level)
		$Transition._wipeOff()
		yield($Transition / Tween, "tween_completed")
		var cbreak = PokiSDK.commercialBreak()
		if not cbreak:
			get_tree().change_scene("res://Scenes/Game.tscn")
	else:
		get_tree().change_scene("res://Scenes/CupViewer.tscn")

func _on_SaveButton_pressed():
	league._saveState()
	$TextureRect / AcceptDialog.visible = true

func _on_BackButton_pressed():
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")
	get_tree().change_scene("res://Scenes/GlobalCupSelect.tscn")
