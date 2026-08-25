extends Control

var teams
var teamfiles
var cup = 0
var playerTeam = 0
var isLeague = false
var cups = ["beginner", "semi-pro", "professional", "international"]
var currcup = null
var cupz = []

func _ready():
	Global.teams = []
	Global.teamfiles = []
	teams = Global.teams
	teamfiles = Global.teamfiles
	
	
	readLevel(3)
	
	
	fillList()
	cupz.append($ColorRect / ViewportContainer / Viewport / Cups / Cups / Cup1)
	cupz.append($ColorRect / ViewportContainer / Viewport / Cups / Cups / Cup2)
	cupz.append($ColorRect / ViewportContainer / Viewport / Cups / Cups / Cup3)
	cupz.append($ColorRect / ViewportContainer / Viewport / Cups / Cups / Cup4)
	currcup = cupz[0]
	$ColorRect / SelectBtn.grab_focus()
func _physics_process(delta):
	
	currcup.rotation_degrees.y += 10.0 * delta
	
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
		
	
	if Global.tType == 0:
		$ColorRect / ContinueButton.disabled = not (checkSaveCup())
	else:
		$ColorRect / ContinueButton.disabled = not (checkSaveLeague())
	
func checkSaveCup():
	var fname = "user://cup" + str(cup) + ".save"
	var save_game = File.new()
	return save_game.file_exists(fname)
func checkSaveLeague():
	var fname = "user://league" + str(cup) + ".save"
	var save_game = File.new()
	return save_game.file_exists(fname)


























		

func fillList():
	
	$ColorRect / CupTeams.clear()
	for i in range(teams.size()):
		$ColorRect / CupTeams.add_item(teams[i].teamname)
	$ColorRect / CupTeams.select(0)


func _on_CupTeams_item_selected(_index):
	
	playerTeam = _index
	
	

func _on_backBtn_pressed():
	
	$ColorRect / Transition._wipeOff()
	yield($ColorRect / Transition / Tween, "tween_completed")
	
	var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")


func _on_SelectBtn_pressed():
	
	print("creating tournament")
	var i = $ColorRect / CupTeams.get_selected_items()
	
	if Global.tType == 0:
		Global.tournament = load("res://Scenes/CupTournament.tscn").instance()
		Global.tournament._initCup(4, i[0], cup)
		Global.tTeam = playerTeam
		var _foo = get_tree().change_scene("res://Scenes/CupViewer.tscn")
	else:
		Global.tournament = load("res://Scenes/LeagueTournament.tscn").instance()
		Global.tournament._initLeague(16, 15, playerTeam, cup)
		Global.tTeam = playerTeam
		var _foo = get_tree().change_scene("res://Scenes/LeagueViewer.tscn")

func _on_CupTeams_item_activated(_index):
	
	$ColorRect / SelectBtn.grab_focus()


func _on_ContinueButton_pressed():
	if Global.tType == 0:
		Global.tournament = load("res://Scenes/CupTournament.tscn").instance()
		var res = Global.tournament._continueCup(cup)
		if (res):
			Global.tTeam = Global.tournament.pteam
			var _foo = get_tree().change_scene("res://Scenes/CupViewer.tscn")
		else:
			print("no save file!")
	else:
		Global.tournament = load("res://Scenes/LeagueTournament.tscn").instance()
		Global.tournament._continueLeague(cup)
		
		Global.tTeam = Global.tournament.playerteam
		var _foo = get_tree().change_scene("res://Scenes/LeagueViewer.tscn")


func checkLocked():
	var locked = false
	if cup == 1 and Global.stats.stats_dict.amcups < 1:
		locked = true
	elif cup == 2 and Global.stats.stats_dict.procups < 1:
		locked = true
	elif cup == 3 and Global.stats.stats_dict.chumpcups < 1:
		locked = true
		
	if locked:
		$ColorRect / SelectBtn.text = "Locked"
		$ColorRect / SelectBtn.disabled = true
	else:
		$ColorRect / SelectBtn.text = "play"
		$ColorRect / SelectBtn.disabled = false
	
func _on_ButtonLeft_pressed():
	cup = (cup - 1)
	if cup < 0:
		cup = 3
	$ColorRect / ViewportContainer / Viewport / Cups._dorotate(cup)
	$ColorRect / CupName.text = cups[cup]
	currcup = cupz[cup]
	
	readLevel(3 - cup)
	fillList()
	checkLocked()


func _on_ButtonRight_pressed():
	cup = (cup + 1) % 4
	$ColorRect / ViewportContainer / Viewport / Cups._dorotate(cup)
	$ColorRect / CupName.text = cups[cup]
	currcup = cupz[cup]
	
	readLevel(3 - cup)
	fillList()
	checkLocked()
