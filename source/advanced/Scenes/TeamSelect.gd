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
var mp_host = false
var mp_elapsed = 0.0
var mp_started = false
var mp_applying = false

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

	if Global.multiplayer_mode and OS.has_feature("HTML5"):
		_setup_multiplayer()


func _process(delta):
	if not Global.multiplayer_mode or not OS.has_feature("HTML5"):
		return
	mp_elapsed += delta
	if mp_elapsed < 0.25:
		return
	mp_elapsed = 0.0
	var raw_state = JavaScript.eval("window.slsMultiplayerState ? window.slsMultiplayerState() : '{}'", true)
	if typeof(raw_state) != TYPE_STRING:
		return
	var state = parse_json(raw_state)
	if typeof(state) != TYPE_DICTIONARY:
		return
	mp_host = bool(state.get("host", false))
	if not mp_host:
		var remote_team1 = str(state.get("team1", ""))
		var remote_alt1 = bool(state.get("team1_alt", false))
		var remote_team2 = str(state.get("team2", ""))
		var remote_alt2 = bool(state.get("team2_alt", false))
		if remote_team1 != "" and (remote_team1 != Global.team1 or remote_alt1 != p1alt):
			_mp_apply_team("team1", remote_team1, remote_alt1)
		if remote_team2 != "" and (remote_team2 != Global.team2 or remote_alt2 != p2alt):
			_mp_apply_team("team2", remote_team2, remote_alt2)
	else:
		var host_team1 = str(state.get("team1", ""))
		var host_team2 = str(state.get("team2", ""))
		var host_alt1 = bool(state.get("team1_alt", false))
		var host_alt2 = bool(state.get("team2_alt", false))
		if host_team1 != Global.team1 or host_team2 != Global.team2 or host_alt1 != p1alt or host_alt2 != p2alt:
			_mp_send_teams()
	var own_ready = bool(state.get("team1_ready" if mp_host else "team2_ready", false))
	var other_ready = bool(state.get("team2_ready" if mp_host else "team1_ready", false))
	var teams_received = str(state.get("team1", "")) != "" and str(state.get("team2", "")) != ""
	if mp_host:
		$TextureRect / GoGame.disabled = own_ready and not other_ready
		$TextureRect / GoGame.text = "Iniciar partida" if other_ready and own_ready else ("Aguardando adversário" if own_ready else "Confirmar time")
		$TextureRect / Label2.text = "Convidado pronto" if other_ready else "Aguardando convidado"
	else:
		$TextureRect / GoGame.disabled = own_ready or not teams_received
		$TextureRect / GoGame.text = "Pronto" if own_ready else "Confirmar time"
		$TextureRect / Label2.text = "Host pronto" if other_ready else ("Times do host recebidos" if teams_received else "Recebendo times do host")
	if bool(state.get("match_started", false)) and not mp_started:
		mp_started = true
		_start_multiplayer_game()


func _setup_multiplayer():
	var raw_state = JavaScript.eval("window.slsMultiplayerState ? window.slsMultiplayerState() : '{}'", true)
	var state = parse_json(raw_state) if typeof(raw_state) == TYPE_STRING else {}
	mp_host = bool(state.get("host", false))
	$TextureRect / T1Levels / T1Level.disabled = true
	$TextureRect / T2Levels / T2Level.disabled = true
	$TextureRect / RandomButton.disabled = not mp_host
	$TextureRect / HomeTeams.disabled = not mp_host
	$TextureRect / AwayTeams.disabled = not mp_host
	$TextureRect / T1Alt.disabled = not mp_host
	$TextureRect / T2Alt.disabled = not mp_host
	$TextureRect / GoGame.text = "Confirmar time"
	$TextureRect / Label2.text = "Aguardando host"
	if mp_host:
		$TextureRect / Label2.text = "Aguardando convidado"
		_mp_send_teams()


func _mp_send_teams():
	if not mp_applying:
		var call = "window.slsMultiplayerSetTeams && window.slsMultiplayerSetTeams(%s,%s,%s,%s)" % [_js_string(Global.team1), str(p1alt).to_lower(), _js_string(Global.team2), str(p2alt).to_lower()]
		JavaScript.eval(call, true)


func _mp_apply_team(side, path, alt):
	var team_index = teamfiles.find(path)
	if team_index < lc[2]:
		return
	var shown_index = team_index - lc[2]
	var list = $TextureRect / HomeTeams if side == "team1" else $TextureRect / AwayTeams
	if shown_index < 0 or shown_index >= list.get_item_count():
		return
	mp_applying = true
	if side == "team1":
		p1alt = alt
		$TextureRect / T1Alt.pressed = alt
		$TextureRect / HomeTeams.select(shown_index)
		_on_HomeTeams_item_selected(shown_index)
	else:
		p2alt = alt
		$TextureRect / T2Alt.pressed = alt
		$TextureRect / AwayTeams.select(shown_index)
		_on_AwayTeams_item_selected(shown_index)
	mp_applying = false


func _start_multiplayer_game():
	Global._loadTeams(p1alt, p2alt)
	Global.toLoad = 1
	Global.stadium = 3 - int(Global.t1.level)
	Global._musicOff()
	Global.final = false
	get_tree().change_scene("res://Scenes/Game.tscn")


func _js_string(value):
	return to_json(str(value))
	
	
	
	
		
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
	if Global.multiplayer_mode and mp_host:
		_mp_send_teams()


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
	if Global.multiplayer_mode and mp_host:
		_mp_send_teams()
	

func _on_TextureButton_pressed():
	if Global.multiplayer_mode:
		if not gogoGame:
			gogoGame = true
			$TextureRect / GoGame.disabled = true
			JavaScript.eval("window.slsMultiplayerReady && window.slsMultiplayerReady()", true)
		return
	
	
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
