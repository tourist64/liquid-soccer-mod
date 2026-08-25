extends Control

var teams
var teamfiles
var cup = 0
var playerTeam = 0
var isLeague = false
var cups = ["beginner", "semi-pro", "professional", "international", "chumpions league"]
var currcup = null
var cupz = []
var selteams = []

func _ready():
	Global.teams = []
	Global.teamfiles = []
	teams = Global.teams
	teamfiles = Global.teamfiles
	
	
	teams.clear()
	teamfiles.clear()
	readLevel(1)
	readLevel(2)
	Global.tType = 4
	
	Global.tournament = load("res://Scenes/ChumpsLg.tscn").instance()
	Global.tournament._setCup(4)
	
	fillList()
	cupz.append($ColorRect / ViewportContainer / Viewport / Cups / Cups / Cup1)
	cupz.append($ColorRect / ViewportContainer / Viewport / Cups / Cups / Cup2)
	cupz.append($ColorRect / ViewportContainer / Viewport / Cups / Cups / Cup3)
	cupz.append($ColorRect / ViewportContainer / Viewport / Cups / Cups / Cup4)
	cupz.append($ColorRect / ViewportContainer / Viewport / Cups / Cups / Cup4)
	currcup = cupz[4]
	$ColorRect / SelectBtn.grab_focus()
	$ColorRect / ViewportContainer / Viewport / Cups._showCup(3)
	$ColorRect / Transition._wipeOn()
	makeCircle()
	
func makeCircle():
	var angle = 0
	var da = TAU / 12.0
	$ColorRect / Node2D / Label3.text = "€"
	for _i in range(0, 12):
		var star = $ColorRect / Node2D / Label3.duplicate()
		$ColorRect / Node2D.add_child(star)
		star.rect_position = Vector2(440, 200) + Vector2(sin(angle) * 270.0, cos(angle) * 270)
		angle += da
	
func _physics_process(delta):
	
	currcup.rotation_degrees.y += 10.0 * delta
	
func readLevel( var lev):
	var dir = Directory.new()
	var l = String(lev)
	
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
	var fname = "user://chumps.save"
	var save_game = File.new()
	return save_game.file_exists(fname)
func checkSaveLeague():
	var fname = "user://league" + str(cup) + ".save"
	var save_game = File.new()
	return save_game.file_exists(fname)


























		

func fillList():
	
	selteams = []
	$ColorRect / CupTeams.clear()
	for i in range(teams.size()):
		if Global.tournament._qualified(teams[i].teamname):
			$ColorRect / CupTeams.add_item(teams[i].teamname)
			selteams.append(i)
	$ColorRect / CupTeams.select(0)


func _on_CupTeams_item_selected(index):
	
	playerTeam = selteams[index]
	
	

func _on_backBtn_pressed():
	
	$ColorRect / Transition._wipeOff()
	yield($ColorRect / Transition / Tween, "tween_completed")
	
	var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")


func _on_SelectBtn_pressed():
	
	print("creating tournament")
	var _i = $ColorRect / CupTeams.get_selected_items()
	
	
		
		
	Global.tTeam = playerTeam
	Global.tournament._initCup()
	
	var _foo = get_tree().change_scene("res://Scenes/WCViewer.tscn")
	
	
	
		
		
	
	

func _on_CupTeams_item_activated(_index):
	
	$ColorRect / SelectBtn.grab_focus()


func _on_ContinueButton_pressed():
	Global._musicOff()
	
	Global.tournament = load("res://Scenes/ChumpsLg.tscn").instance()
	Global.tournament._setCup(0)
	Global.tournament._initCup()
	
	var res = Global.tournament._continueCup(cup)
	if (res):
		if Global.tournament.cr < 6:
			var _foo = get_tree().change_scene("res://Scenes/WCViewer.tscn")
		else:
			var _foo = get_tree().change_scene("res://Scenes/CupViewer.tscn")
	else:
		print("no save file!")
	
		
	
	
	
	
	

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
	


func _on_ButtonRight_pressed():
	cup = (cup + 1) % 4
	$ColorRect / ViewportContainer / Viewport / Cups._dorotate(cup)
	$ColorRect / CupName.text = cups[cup]
	currcup = cupz[cup]
	
	readLevel(3 - cup)
	fillList()
	
