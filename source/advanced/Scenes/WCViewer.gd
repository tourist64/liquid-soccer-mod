extends Control

var dgroups = []
var league
var groupsDone = false
var pgx = 0
var pgy = 0
var pgrp = 0
var but = null
var gogoGame = false
var maxrounds = 2
var numGroups = 8
func _ready():
	gogoGame = false
	but = $TextureRect / AcceptDialog.get_ok()
	but.text = "  ok!  "
	league = Global.tournament
	$TextureRect / PlayTie.grab_focus()
	dgroups = $TextureRect / Groups.get_children()
	if Global.tType < 4:
		$TextureRect / Label.text += str(league.year)
		maxrounds = 2
	elif Global.tType == 5:
		$TextureRect / Label.text = str("World Cup 2026")
		numGroups = 12
		maxrounds = 2
	else:
		$TextureRect / Label.text = "Chumpions 2023-24"
		$TextureRect.color = Color(0.09, 0.17, 0.3)
		maxrounds = 5
	initGroups()

	if league.cr > maxrounds:
		
		groupsDone = true
		league._knockoutStage()
		$TextureRect / PlayTie.text = "Knockout Stage..."
	
	match pgrp:
		2, 3:
			pgx = 853
		4, 5:
			pgy = 380
		6, 7:
			pgx = 853
			pgy = 380
		8, 9:
			pgx = 853
			pgy = 480
		10, 11:
			pgx = 853
			pgy = 480
	
	$TextureRect / Groups.rect_position.x = - pgx
	$TextureRect / Groups.rect_position.y = - pgy
	$Transition._wipeOn()
	Global.connect("adDone", self, "_adSave")
func initGroups():
	for i in range(0, numGroups):
		dgroups[i]._initGroup(Global.tournament.groups[i])
		if Global.tournament.groups[i].playerteam > - 1:
			pgrp = i
func _updateTable():
	for i in range(0, numGroups):
		dgroups[i]._updateTable()
		
func _updateFixtures():
	for i in range(0, numGroups):
		dgroups[i]._updateFixtures(Global.tournament.groups[i])
	

func _on_PlayTie_pressed():
	
	Global.isPenalties = false
	
	if Global.tType == 3:
		Global.isT1Womens = true
		Global.isT2Womens = true
	else:
		Global.isT1Womens = false
		Global.isT2Womens = false
		
	if not gogoGame:
		gogoGame = true
		if not groupsDone:
			Global.final = false
			
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
			$Transition._wipeOff()
			Global.stadium = 3 - int(Global.t1.level)
		
			yield($Transition / Tween, "tween_completed")
			Global.adsource = Global.adfrom.GOGAME
			var cbreak = PokiSDK.commercialBreak()
			if not cbreak:
			
				var _foo = get_tree().change_scene("res://Scenes/Game.tscn")
		
			
		else:
			
			
			var _foo = get_tree().change_scene("res://Scenes/CupViewer.tscn")
			
	

func _on_SaveButton_pressed():
	
	var cbreak = true
	print("trying saving commercial")
	cbreak = PokiSDK.commercialBreak()
	Global.adsource = Global.adfrom.SAVEGAME
	if not cbreak:
	
		print("no commercial")
		league._saveState()
		$TextureRect / AcceptDialog.visible = true

func _adSave():
	print("callback adsave")
	league._saveState()
	$TextureRect / AcceptDialog.visible = true

func _on_BackButton_pressed():
	
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")
	
	var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")

