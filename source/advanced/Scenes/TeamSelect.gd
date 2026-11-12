extends Control
const MP_SYNC_INTERVAL = 0.05
const MP_STATE_EXPRESSION = "window.slsMultiplayerState ? window.slsMultiplayerState() : '{}'"

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
var lc = [0, 0, 0, 0, 0, 0]
var gogoGame = false
var mp_host = false
var mp_elapsed = 0.0
var mp_started = false
var mp_applying = false
var mp_configured = false
var mp_last_host_selection = ""
var mp_last_guest_selection = ""
var mp_guest_has_snapshot = false

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
	if Global.eightMode:
		# 8v8: only the 8-a-side squads in Teams/5.
		t1level = 5
		t2level = 5
		_addTeams1(5)
		_addTeams2(5)
		$TextureRect / T1Levels.visible = false
		$TextureRect / T2Levels.visible = false
	if Global.elevenMode:
		# 11v11: only the 11-a-side squads in Teams/4.
		t1level = 4
		t2level = 4
		_addTeams1(4)
		_addTeams2(4)
		$TextureRect / T1Levels.visible = false
		$TextureRect / T2Levels.visible = false
	if Global.multiplayer_mode:
		_select_multiplayer_defaults()
	else:
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
	if not _mp_should_sync(delta):
		return
	var state = _mp_read_state()
	if state.empty():
		return
	mp_host = bool(state.get("host", false))
	_mp_apply_shared_state(state)
	_mp_update_selection_ui(state)
	if bool(state.get("match_started", false)) and not mp_started:
		mp_started = true
		_start_multiplayer_game()


func _mp_should_sync(delta):
	if not Global.multiplayer_mode or not OS.has_feature("HTML5"):
		return false
	mp_elapsed += delta
	if mp_elapsed < MP_SYNC_INTERVAL:
		return false
	mp_elapsed = 0.0
	return true


func _mp_read_state():
	var raw_state = JavaScript.eval(MP_STATE_EXPRESSION, true)
	if typeof(raw_state) != TYPE_STRING:
		return {}
	var state = parse_json(raw_state)
	return state if typeof(state) == TYPE_DICTIONARY else {}


func _mp_has_teams(state):
	return str(state.get("team1", "")) != "" and str(state.get("team2", "")) != ""


func _mp_apply_remote_team(side, path, alt):
	var current_path = Global.team1 if side == "team1" else Global.team2
	var current_alt = p1alt if side == "team1" else p2alt
	if path == "" or (path == current_path and alt == current_alt):
		return false
	_mp_apply_team(side, path, alt)
	return true


func _mp_apply_shared_state(state):
	var team1 = str(state.get("team1", ""))
	var team2 = str(state.get("team2", ""))
	var team1_alt = bool(state.get("team1_alt", false))
	var team2_alt = bool(state.get("team2_alt", false))
	if mp_host:
		var should_publish = not _mp_has_teams(state)
		should_publish = _mp_apply_remote_team("team1", team1, team1_alt) or should_publish
		should_publish = _mp_apply_remote_team("team2", team2, team2_alt) or should_publish
		if should_publish:
			_mp_send_teams()
	else:
		_mp_apply_remote_team("team1", team1, team1_alt)
		_mp_apply_remote_team("team2", team2, team2_alt)
		if _mp_has_teams(state):
			mp_guest_has_snapshot = true
	_mp_publish_current_selection()


func _mp_update_selection_ui(state):
	var teams_received = _mp_has_teams(state)
	if mp_host:
		$TextureRect / GoGame.disabled = not teams_received
		$TextureRect / GoGame.text = "Iniciar partida" if teams_received else "Aguardando escolha do convidado"
		$TextureRect / Label2.text = "Times sincronizados" if teams_received else "Aguardando convidado"
		return
	$TextureRect / AwayTeams.disabled = not teams_received
	$TextureRect / T2Alt.disabled = not teams_received
	$TextureRect / GoGame.disabled = true
	$TextureRect / GoGame.text = "Aguardando host"
	$TextureRect / Label2.text = "Escolha seu time" if teams_received else "Recebendo time do host"


func _setup_multiplayer():
	var state = _mp_read_state()
	mp_host = bool(state.get("host", false))
	$TextureRect / T1Levels / T1Level.disabled = true
	$TextureRect / T2Levels / T2Level.disabled = true
	$TextureRect / RandomButton.disabled = true
	$TextureRect / HomeTeams.disabled = not mp_host
	$TextureRect / AwayTeams.disabled = mp_host
	$TextureRect / T1Alt.disabled = not mp_host
	$TextureRect / T2Alt.disabled = mp_host
	$TextureRect / GoGame.text = "Confirmar time"
	$TextureRect / Label2.text = "Aguardando host"
	mp_configured = true
	_mp_configure_single_team_selector()
	if mp_host:
		$TextureRect / Label2.text = "Aguardando convidado"
		_mp_publish_current_selection()
	else:
		$TextureRect / AwayTeams.disabled = true
		$TextureRect / T2Alt.disabled = true


func _mp_configure_single_team_selector():
	var own_selector = $TextureRect / HomeTeams if mp_host else $TextureRect / AwayTeams
	var opponent_selector = $TextureRect / AwayTeams if mp_host else $TextureRect / HomeTeams
	var own_alt = $TextureRect / T1Alt if mp_host else $TextureRect / T2Alt
	var opponent_alt = $TextureRect / T2Alt if mp_host else $TextureRect / T1Alt
	var own_preview = $TextureRect / Team1Container if mp_host else $TextureRect / Team2Container
	var opponent_preview = $TextureRect / Team2Container if mp_host else $TextureRect / Team1Container
	own_selector.visible = true
	own_alt.visible = true
	own_preview.visible = true
	opponent_selector.visible = false
	opponent_alt.visible = false
	opponent_preview.visible = false
	$TextureRect / T1Levels.visible = false
	$TextureRect / T2Levels.visible = false


func _select_multiplayer_defaults():
	var home_teams = $TextureRect / HomeTeams
	var away_teams = $TextureRect / AwayTeams
	if home_teams.get_item_count() > 0:
		home_teams.select(0)
		_on_HomeTeams_item_selected(0)
	if away_teams.get_item_count() > 0:
		var away_index = 1 if away_teams.get_item_count() > 1 else 0
		away_teams.select(away_index)
		_on_AwayTeams_item_selected(away_index)


func _mp_send_teams():
	if not mp_applying:
		var call = "window.slsMultiplayerSetTeams && window.slsMultiplayerSetTeams(%s,%s,%s,%s)" % [_js_string(Global.team1), str(p1alt).to_lower(), _js_string(Global.team2), str(p2alt).to_lower()]
		JavaScript.eval(call, true)


func _mp_request_team(path, alt):
	if not mp_applying:
		var call = "window.slsMultiplayerRequestTeam && window.slsMultiplayerRequestTeam(%s,%s)" % [_js_string(path), str(alt).to_lower()]
		JavaScript.eval(call, true)


func _mp_host_selection_key():
	return to_json([Global.team1, p1alt, Global.team2, p2alt])


func _mp_guest_selection_key():
	return to_json([Global.team2, p2alt])


func _mp_publish_current_selection():
	if not mp_configured or mp_applying:
		return
	if mp_host:
		var host_selection = _mp_host_selection_key()
		if host_selection == mp_last_host_selection:
			return
		mp_last_host_selection = host_selection
		_mp_send_teams()
	elif mp_guest_has_snapshot:
		var guest_selection = _mp_guest_selection_key()
		if guest_selection == mp_last_guest_selection:
			return
		mp_last_guest_selection = guest_selection
		_mp_request_team(Global.team2, p2alt)


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
	if side == "team2" and not mp_host:
		mp_last_guest_selection = _mp_guest_selection_key()


func _mp_selection_changed():
	if not Global.multiplayer_mode or not mp_configured:
		return
	gogoGame = false
	$TextureRect / GoGame.disabled = false


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
	readLevel(4)
	lc[4] = teams.size()
	readLevel(5)
	lc[5] = teams.size()
	
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
	if Global.multiplayer_mode and mp_configured and mp_host:
		_mp_selection_changed()
		_mp_publish_current_selection()


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
	if Global.multiplayer_mode and mp_configured:
		_mp_selection_changed()
		_mp_publish_current_selection()
	

func _on_TextureButton_pressed():
	if Global.multiplayer_mode:
		var state = _mp_read_state()
		if not mp_host:
			return
		if not bool(state.get("started", false)) or str(state.get("team1", "")) == "" or str(state.get("team2", "")) == "":
			return
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
