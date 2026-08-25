extends Control
var p1
var p2
var p1mat
var p2mat
var teams = []
var teamfiles = []
var unlocked1 = []
var unlocked2 = []
var p1sel = 1000
var p2sel = 1000
var p1alt = false
var p2alt = false
var t1level = 0
var t2level = 0
var lc = [0, 0, 0, 0]
var gogoGame = false

func _ready():
	_readTeams()
	gogoGame = false
	p1 = $TextureRect / Team1Container / Viewport / Player / QuickRigCharacter_Reference / PlayerM
	p2 = $TextureRect / Team2Container / Viewport / Player / QuickRigCharacter_Reference / PlayerM
	p1mat = p1.get_surface_material(0)
	p2mat = p2.get_surface_material(0)
	
	
	
	
	
	$TextureRect / GoGame.text = Global.ll.menus[0]
	$TextureRect / T1Levels / T1Level.add_item("Womens")
	$TextureRect / T1Levels / T1Level.add_item("Club Teams")
	$TextureRect / T1Levels / T1Level.add_item("Top Club")
	$TextureRect / T1Levels / T1Level.add_item("National")
	
	$TextureRect / T2Levels / T2Level.add_item("Womens")
	$TextureRect / T2Levels / T2Level.add_item("Club Teams")
	$TextureRect / T2Levels / T2Level.add_item("Top Club")
	$TextureRect / T2Levels / T2Level.add_item("National")
	
	
	var ll = 3
	$TextureRect / T2Levels / T2Level.select(ll)
	$TextureRect / T1Levels / T1Level.select(ll)
	_on_T1Level_item_selected(ll)
	_on_T2Level_item_selected(ll)
	_on_RandomButton_pressed()
	
	
	
	
	$TextureRect / GoGame.grab_focus()
	
	$Transition._wipeOn()
	
	$TextureRect / P1Controller / T1C.text = Input.get_joy_name(0)
	$TextureRect / P2Controller / T2C.text = Input.get_joy_name(1)
	if not Global.p2human:
		$TextureRect / P2Controller / T2C.text = "CPU"
	if not Global.p1human:
		$TextureRect / P1Controller / T1C.text = "CPU"
	
	
	
	
		
func setWomens( var t):
	if t == 1:
		$TextureRect / Team1Container / Viewport / Player.visible = false
		$TextureRect / Team1Container / Viewport / femplayer.visible = true
		p1 = $TextureRect / Team1Container / Viewport / femplayer / QuickRigCharacter_Reference / PlayerM
		p1mat = p1.get_surface_material(0)
		
	else:
		$TextureRect / Team2Container / Viewport / Player.visible = false
		$TextureRect / Team2Container / Viewport / femplayer.visible = true
		p2 = $TextureRect / Team2Container / Viewport / femplayer / QuickRigCharacter_Reference / PlayerM
		p2mat = p2.get_surface_material(0)
func setMens( var t):
	if t == 1:
		$TextureRect / Team1Container / Viewport / Player.visible = true
		$TextureRect / Team1Container / Viewport / femplayer.visible = false
		p1 = $TextureRect / Team1Container / Viewport / Player / QuickRigCharacter_Reference / PlayerM
		p1mat = p1.get_surface_material(0)
	else:
		$TextureRect / Team2Container / Viewport / Player.visible = true
		$TextureRect / Team2Container / Viewport / femplayer.visible = false
		p2 = $TextureRect / Team2Container / Viewport / Player / QuickRigCharacter_Reference / PlayerM
		p2mat = p2.get_surface_material(0)
	
		
func readLevel( var lev):
	var dir = Directory.new()
	var l = String(lev)
	
	
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

func _readTeams():
	
	readLevel(0)
	lc[0] = teams.size()
	readLevel(1)
	lc[1] = teams.size()
	readLevel(2)
	lc[2] = teams.size()
	readLevel(3)
	lc[3] = teams.size()
	
func _addTeams1( var level):
	var from = 0
	var to = lc[0]
	var checklocked = false
	if level > 0:
		from = lc[level - 1]
		to = lc[level]
		if level < 3:
			checklocked = true
	unlocked1.clear()
	$TextureRect / HomeTeams.clear()
	for i in range(from, to):
		if checklocked:
			if Global._checkLocked(i - from, level):
				$TextureRect / HomeTeams.add_item(teams[i].teamname)
				unlocked1.append(i - from)
			
		else:
			$TextureRect / HomeTeams.add_item(teams[i].teamname)
		
	$TextureRect / HomeTeams.select(0)
	_on_HomeTeams_item_selected(0)
	
func _addTeams2( var level):
	var from = 0
	var to = lc[0]
	var checklocked = false
	if level > 0:
		from = lc[level - 1]
		to = lc[level]
		if level < 3:
			checklocked = true
	unlocked2.clear()
	$TextureRect / AwayTeams.clear()
	for i in range(from, to):
		if checklocked:
			if Global._checkLocked(i - from, level):
				$TextureRect / AwayTeams.add_item(teams[i].teamname)
				unlocked2.append(i - from)
		else:
			$TextureRect / AwayTeams.add_item(teams[i].teamname)

	$TextureRect / AwayTeams.select(0)
	_on_AwayTeams_item_selected(0)
	
func _on_HomeTeams_item_selected(index):
	
	var shirt = "res://Images/player1.png"
	var lev = 0
	var ti = index
	if t1level > 0:
		lev = lc[t1level - 1]
		if t1level < 3:
			ti = unlocked1[index]
	
	
	
	var t = teams[lev + ti]
	var ts = t.shirtType
	if p1alt:
		ts = t.shirt2Type
	if (ts > 0):
		shirt = "res://Images/player" + str(ts) + ".png"
	var tex = load(shirt)
	p1mat.set_shader_param("texture_albedo", tex)
	var trim = "res://Images/playertrim.png"
	if ts == 11 or ts == 12:
		trim = "res://Images/playertrim" + str(ts) + ".png"
	var ttex = load(trim)
	p1mat.set_shader_param("texture_albedo_trim", ttex)
	if ( not p1alt):
		p1mat.set_shader_param("Shirt", t.Shirt1Color)
		p1mat.set_shader_param("Shorts", t.ShortColor)
		p1mat.set_shader_param("Shirt2", t.Shirt2Color)
		p1mat.set_shader_param("Shirt3", t.Shirt3Color)
	else:
		p1mat.set_shader_param("Shirt", t.altShirt1Color)
		p1mat.set_shader_param("Shorts", t.altShortColor)
		p1mat.set_shader_param("Shirt2", t.altShirt2Color)
		p1mat.set_shader_param("Shirt3", t.altShirt3Color)
		
	p1sel = index
	Global.team1 = teamfiles[lev + ti]


func _on_AwayTeams_item_selected(index):
	
	var shirt = "res://Images/player1.png"
	var lev = 0
	var ti = index
	if t2level > 0 and t2level < 3:
		lev = lc[t2level - 1]
		ti = unlocked2[index]
	if t1level > 2:
		lev = lc[t1level - 1]
		ti = index
	var t = teams[lev + ti]
	var ts = t.shirtType
	if p2alt:
		ts = t.shirt2Type
	
	if (ts > 0):
		shirt = "res://Images/player" + str(ts) + ".png"
	var tex = load(shirt)
	p2mat.set_shader_param("texture_albedo", tex)
	var trim = "res://Images/playertrim.png"
	if ts == 11 or ts == 12:
		trim = "res://Images/playertrim" + str(ts) + ".png"
	var ttex = load(trim)
	p2mat.set_shader_param("texture_albedo_trim", ttex)
	if ( not p2alt):
		p2mat.set_shader_param("Shirt", t.Shirt1Color)
		p2mat.set_shader_param("Shorts", t.ShortColor)
		p2mat.set_shader_param("Shirt2", t.Shirt2Color)
		p2mat.set_shader_param("Shirt3", t.Shirt3Color)
	else:
		p2mat.set_shader_param("Shirt", t.altShirt1Color)
		p2mat.set_shader_param("Shorts", t.altShortColor)
		p2mat.set_shader_param("Shirt2", t.altShirt2Color)
		p2mat.set_shader_param("Shirt3", t.altShirt3Color)
	p2sel = index
	Global.team2 = teamfiles[lev + ti]
	

func _on_TextureButton_pressed():
	
	
	if not gogoGame:
		gogoGame = true
		Global._loadTeams(p1alt, p2alt)
		Global.toLoad = 1
		
		Global.stadium = 3 - int(Global.t1.level)
		
		Global._musicOff()
		
		
		Global.final = false
		$Transition._wipeOffTex()
		yield($Transition / Tween, "tween_completed")
		
		
		
		
		
		if PokiSDK.isAdBlocked():
			print("adblocked man")
		
		PokiSDK.gameplayStart()
		Global.adsource = Global.adfrom.GOGAME
		var cbreak = true
		
		
		
		cbreak = PokiSDK.commercialBreak()
			
		if not cbreak:
			print("can't do commercial")
			var _foo = get_tree().change_scene("res://Scenes/Game.tscn")
		
		
		
		
		


func _on_T2Alt_toggled(button_pressed):
	p2alt = button_pressed
	_on_AwayTeams_item_selected(p2sel)

func _on_T1Alt_toggled(button_pressed):
	p1alt = button_pressed
	_on_HomeTeams_item_selected(p1sel)
	

func _on_Tactics_pressed():
	print("loading game tactics")
	Global._loadTeams(p1alt, p2alt)
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")
	
	var _foo = get_tree().change_scene("res://Scenes/Tactics.tscn")


func _on_Button_pressed():
	Global._musicOff()
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")

	var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")
	

func _on_T1Level_item_selected(index):
	t1level = 3 - index
	_addTeams1(3 - index)
	if index == 0:
		Global.isT1Womens = true
		setWomens(1)
	else:
		Global.isT1Womens = false
		setMens(1)

func _on_T2Level_item_selected(index):
	t2level = 3 - index
	_addTeams2(3 - index)
	if index == 0:
		Global.isT2Womens = true
		setWomens(2)
	else:
		Global.isT2Womens = false
		setMens(2)


func _on_RandomButton_pressed():
	var siz1 = lc[t1level]
	var siz2 = lc[t2level]
	if t1level > 0:
		siz1 -= lc[t1level - 1]
	if t2level > 0:
		siz2 -= lc[t2level - 1]
		
	if t1level > 0 and t1level < 3:
		siz1 = unlocked1.size()
	if t2level > 0 and t2level < 3:
		siz2 = unlocked2.size()
		
	var t1 = int(rand_range(0, siz1 - 1))
	var t2 = int(rand_range(0, siz2 - 1))
	$TextureRect / HomeTeams.select(t1)
	$TextureRect / AwayTeams.select(t2)
	$TextureRect / AwayTeams.ensure_current_is_visible()
	$TextureRect / HomeTeams.ensure_current_is_visible()
	
	_on_HomeTeams_item_selected(t1)
	_on_AwayTeams_item_selected(t2)
	
func on_commercial_break_done():
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! commercial done!")
	var _foo = get_tree().change_scene("res://Scenes/Game.tscn")
