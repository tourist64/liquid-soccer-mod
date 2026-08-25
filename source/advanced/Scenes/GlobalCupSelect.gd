extends Control

var teams
var teamfiles
var selteams = []
var cup = 0
var playerTeam = 0
var isLeague = false
var p1mat
var cups = ["beginner", "semi-pro", "professional", "international"]

func _ready():
	Global.teams = []
	Global.teamfiles = []
	teams = Global.teams
	teamfiles = Global.teamfiles
	
	cup = Global.tType
	
	Global.tournament = load("res://Scenes/WorldCup.tscn").instance()
	if Global.tType == 2 or Global.tType == 5:
		
		var p = load("res://Scenes/newPlay.tscn").instance()
		p.name = "Player"
		p.translation.z = - 3.5
		$ColorRect / ViewportContainer2 / Viewport.add_child(p)
		
		
		
		
		
		readLevel(0)
		Global.tournament._setCup(5)
	
	elif Global.tType == 3:
		var p = load("res://Scenes/femplayer.tscn").instance()
		p.name = "Player"
		p.translation.z = - 3.5
		$ColorRect / Label.text = "Womens World Cup 2023"
		$ColorRect / ViewportContainer2 / Viewport.add_child(p)
		$ColorRect / Button16.visible = false
		$ColorRect / Button18.visible = false
		$ColorRect / Button22.visible = false
		
		readLevel(3)
		Global.tournament._setCup(4)
		
	var p1 = $ColorRect / ViewportContainer2 / Viewport / Player / QuickRigCharacter_Reference / PlayerM
	p1mat = p1.get_surface_material(0)
	
	fillList()
	var t = int(rand_range(1, 32))
	$ColorRect / CupTeams.select(t, true)
	_on_CupTeams_item_selected(t)
	$ColorRect / CupTeams.ensure_current_is_visible()
	$ColorRect / SelectBtn.grab_focus()
	$Transition._wipeOn()
func readLevel( var lev):
	var dir = Directory.new()
	var l = String(lev)
	teams.clear()
	teamfiles.clear()
	teams = Global.teams
	
	
	if dir.open("res://Teams/" + l + "/") == OK:
		dir.list_dir_begin(true, true)
		var filen = dir.get_next()
		while (filen != ""):
			var fn = "res://Teams/" + l + "/" + filen
			var t = load(fn)
			teams.append(t)
			teamfiles.append(fn)
			
			filen = dir.get_next()
		dir.list_dir_end()
		
	
	
	$ColorRect / ContinueButton.disabled = not (checkSaveCup())
	
	
func checkSaveCup():
	var fname = "user://globalcup.save"
	if Global.tType == 3:
		fname = "user://wglobalcup.save"
	var save_game = File.new()
	return save_game.file_exists(fname)
func checkSaveLeague():
	var fname = "user://league" + str(cup) + ".save"
	var save_game = File.new()
	return save_game.file_exists(fname)


func fillList():
	
	
	$ColorRect / CupTeams.clear()
	selteams = []
	for i in range(teams.size()):
		if Global.tournament._qualified(teams[i].teamname):
			$ColorRect / CupTeams.add_item(teams[i].teamname)
			selteams.append(i)
	
	$ColorRect / CupTeams.select(0)
	

func _on_CupTeams_item_selected(index):
	
	playerTeam = selteams[index]
	var shirt = "res://Images/player1.png"
	var lev = 0
	var t = teams[lev + playerTeam]
	if (t.shirtType > 0):
		shirt = "res://Images/player" + str(t.shirtType) + ".png"
	var tex = load(shirt)
	p1mat.set_shader_param("texture_albedo", tex)
	p1mat.set_shader_param("Shirt", t.Shirt1Color)
	p1mat.set_shader_param("Shorts", t.ShortColor)
	p1mat.set_shader_param("Shirt2", t.Shirt2Color)
	p1mat.set_shader_param("Skin", t.player2.skin)

	
	

func _on_backBtn_pressed():
	
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")
	
	var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")


func _on_SelectBtn_pressed():
	
	
	
	
	Global.tTeam = playerTeam
	Global.tournament._initCup()
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")
	
	var _foo = get_tree().change_scene("res://Scenes/WCViewer.tscn")
	
func _on_CupTeams_item_activated(_index):
	
	$ColorRect / SelectBtn.grab_focus()


func _on_ContinueButton_pressed():
	
	
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")
	
	var res = Global.tournament._continueCup(cup)
	if (res):
		if Global.tournament.cr < 3:
			var _foo = get_tree().change_scene("res://Scenes/WCViewer.tscn")
		else:
			var _foo = get_tree().change_scene("res://Scenes/CupViewer.tscn")
	else:
		print("no save file!")
	


func _on_Button22_pressed():
	Global.tournament._setCup(0)
	fillList()


func _on_Button18_pressed():
	Global.tournament._setCup(1)
	fillList()


func _on_Button19_pressed():
	Global.tournament._setCup(2)
	fillList()


func _on_Button20_pressed():
	pass
