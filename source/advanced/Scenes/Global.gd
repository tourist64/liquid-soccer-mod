extends Node


var config = null


var gameOn = false
var penShoot = false
var penOn = false
var halfDone = false
var final = false

var stadium = 0

var isT1Womens = false
var isT2Womens = false
var setupWomens = false
var gameLength = 60
var vpRes = [853, 480]

var teamsReady = []
var ballpos = Vector3.ZERO
var ballvel = Vector3.ZERO
var toLoad = 0

var team1: String
var team2: String
var t1 = null
var t2 = null

var t1tex = null
var t2tex = null
var t1trim = null
var t2trim = null
var p1alt = false
var p2alt = false
var game = null

var joypads = []
var p1human = true
var p2human = false
var multiplayer_mode = false
var multiplayer_host = false
var vsync = true
var camtype = 0
var camrot = false


var doShootout = false

var shadtype = 0

var doTrail = false
var doParticles = false
var doPosInd = false
var pswitch = 0

var firsttime = true
var firstrun = 1
var stats = null
var theme = null
var themevol = null


var teams = null
var teamfiles = null
var tournament = null
var tTeam = 0
var tType = 0
var tT1 = 0
var tT2 = 0
var tG = 0


var xmas = false

var goalframe: int
var sfBeforeGf: bool

var moveAssist = 1
var udlrk = []
var buttsk = []
var shoulderk = []
var udlr = "WSAD"
var butts = "MJLI"
var shoulder = "QEPO"
var touchPad = null
var isTouch = false

var debugLine = null
var firstGame = true

var lang = ""
var ll = null
var doSayings = false
var isTutorial = false

var isPenalties = false


var teamprem = []
var teamnormal = []
var isUnlocking = false
var adPlaying = false

enum adfrom{GOGAME, SAVEGAME, HALFTIME}
var adsource = adfrom.GOGAME
signal adDone


func _ready():
	
	randomize()
	teamsReady.append(false)
	teamsReady.append(false)
	stats = load("res://Scenes/Stats.tscn").instance()
	
	add_child(stats)
	if stats:
		stats._loadStats()
	
	
	
	theme = AudioStreamPlayer.new()
	themevol = Tween.new()
	add_child(theme)
	add_child(themevol)
	
	var stream = load("res://Res/Football_2v3.mp3")
	if not stream:
		push_error("couldn't load music")
	theme.stream = stream
	theme.volume_db = - 4
	theme.bus = "Music"
	
		
	
	setupKeys()
	
	
	loadLocks()
	refreshMultiplayer()
	
	




	

func refreshMultiplayer():
	if not OS.has_feature("HTML5"):
		return false
	var enabled = JavaScript.eval("window.location.search.indexOf('mp=host') >= 0", true)
	if enabled:
		setMultiplayerRole(true)
	return multiplayer_mode

func setMultiplayerRole(host):
	multiplayer_mode = true
	multiplayer_host = host
	p1human = true
	p2human = true
	setupMultiplayerKeys()

func setupMultiplayerKeys():
	var keys = {
		"p2_up": 16777232,
		"p2_down": 16777234,
		"p2_left": 16777231,
		"p2_right": 16777233,
		"p2_pass": OS.find_scancode_from_string("H"),
		"p2_shoot": OS.find_scancode_from_string("J"),
		"p2_chip": OS.find_scancode_from_string("K"),
		"p2_thru": OS.find_scancode_from_string("L"),
		"p2_burst": OS.find_scancode_from_string("U"),
		"p2_switch": OS.find_scancode_from_string("I"),
		"p2_low": OS.find_scancode_from_string("O")
	}
	for action in keys:
		var event = InputEventKey.new()
		event.set_scancode(keys[action])
		InputMap.action_add_event(action, event)

func _setupPoki():
	PokiSDK.connect("commercial_break_done", self, "on_commercial_break_done")
	PokiSDK.connect("rewarded_break_done", self, "on_rewarded_break_done")



func _loadTeams(p1a, p2a):
	t1 = load(team1)
	t2 = load(team2)
	
	p1alt = p1a
	p2alt = p2a
	var t1c = t1.Shirt1Color
	var t2c = t2.Shirt1Color
	if p1alt:
		t1c = t1.altShirt1Color
	if p2alt:
		t2c = t2.altShirt1Color
	
	var diff = t1c - t2c
	var dc = (sqrt(diff.r * diff.r + diff.g * diff.g + diff.b * diff.b))
	print(dc)
	if dc < 0.25:
		p2alt = not p2alt
	var shirt = "res://Images/player1.png"
	var t1shirt = t1.shirtType
	if p1alt:
		t1shirt = t1.shirt2Type
	if (t1shirt > 0):
		shirt = "res://Images/player" + str(t1shirt) + ".png"
	
	t1tex = load(shirt)
	var trim = "res://Images/playertrim.png"
	if t1shirt == 11 or t1shirt == 12:
		trim = "res://Images/playertrim" + str(t1shirt) + ".png"
	t1trim = load(trim)
	
	shirt = "res://Images/player1.png"
	var t2shirt = t2.shirtType
	if p2alt:
		t2shirt = t2.shirt2Type

	if (t2shirt > 0):
		shirt = "res://Images/player" + str(t2shirt) + ".png"
	t2tex = load(shirt)
	var ttrim = "res://Images/playertrim.png"
	if t2shirt == 11 or t2shirt == 12:
		ttrim = "res://Images/playertrim" + str(t2shirt) + ".png"
	t2trim = load(ttrim)
	
func createConfig():
	print("creating config file")
	config.set_value("audio", "mute", false)
	config.set_value("audio", "volume", 75)
	config.set_value("audio", "fxvolume", 75)
	config.set_value("audio", "musicvolume", 75)
	config.set_value("audio", "crowdvolume", 75)
	
	config.set_value("gfx", "quality", 2)
	config.set_value("gfx", "res", vpRes)
	config.set_value("gfx", "vsync", true)
	config.set_value("gfx", "camtype", 0)
	config.set_value("gfx", "camfov", 45.0)
	config.set_value("gfx", "camUDfov", 50.0)
	config.set_value("gfx", "camLRfov", 60.0)
	config.set_value("gfx", "camLRheight", 60.0)
	config.set_value("gfx", "camLRtilt", - 10.0)
	config.set_value("gfx", "camLRoffset", 0.0)
	config.set_value("gfx", "camLRdof", 70.0)
	config.set_value("gfx", "camUDheight", 60.0)
	config.set_value("gfx", "camUDtilt", - 10.0)
	config.set_value("gfx", "camUDoffset", 0.0)
	config.set_value("gfx", "camUDdof", 70.0)
	config.set_value("gfx", "camheight", 75.0)
	config.set_value("gfx", "camtilt", - 48.0)
	config.set_value("gfx", "camoffset", 70.0)
	config.set_value("gfx", "camdof", 90.0)
	config.set_value("gfx", "doshadows", false)
	config.set_value("gfx", "docrowd", true)
	
	config.set_value("gfx", "shadtype", 0)
	config.set_value("gfx", "particles", false)
	config.set_value("gfx", "trails", true)
	config.set_value("game", "doSayings", true)
	config.set_value("game", "lastLevel", 1)
	config.set_value("game", "skillLevel", 0.25)
	config.set_value("game", "posInd", true)
	config.set_value("game", "pswitch", 0)
	config.set_value("game", "upk", udlrk[0])
	config.set_value("game", "downk", udlrk[1])
	config.set_value("game", "leftk", udlrk[2])
	config.set_value("game", "rightk", udlrk[3])
	
	config.set_value("game", "passk", buttsk[0])
	config.set_value("game", "shootk", buttsk[1])
	config.set_value("game", "chipk", buttsk[2])
	config.set_value("game", "thruk", buttsk[3])
	
	config.set_value("game", "L1", shoulderk[0])
	config.set_value("game", "L2", shoulderk[1])
	config.set_value("game", "R1", shoulderk[2])
	config.set_value("game", "R2", shoulderk[3])
	config.set_value("game", "firstrun", 1)
	
	config.set_value("match", "time", 1)
	config.set_value("player", "assist", 2)
	config.set_value("misc", "language", "en")
	
	config.save("user://slssettings.cfg")

func _loadConfig():
	print("loading config")
	var cf = ConfigFile.new()
	var err = cf.load("user://slssettings.cfg")
	config = cf
	if err != OK:
		createConfig()
	_applyConfig()
	
func _applyConfig():
	
	
	
	














	
	ProjectSettings.set_setting("rendering/quality/shading/force_vertex_shading", true)
	ProjectSettings.set_setting("rendering/quality/directional_shadow/size", 2048)
	
	ProjectSettings.set_setting("rendering/quality/shadows/filter_mode", 2)
	
	
	
	
	
		
	
	var tim = config.get_value("match", "time")
	if ( not tim):
		_setTime(3)
		tim = 3
		config.set_value("match", "time", tim)
	gameLength = tim * 60
	
	var assist = config.get_value("player", "assist", null)
	if (assist == null):
		assist = 0
		config.set_value("player", "assist", assist)
	moveAssist = assist
	
	vsync = config.get_value("gfx", "vsync", null)
	if vsync == null:
		vsync = true
		config.set_value("gfx", "vsync", true)
	
	camtype = config.get_value("gfx", "camtype", null)
	if not camtype:
		camtype = 0
		config.set_value("gfx", "camtype", 0)
	if camtype == 1:
		camrot = true
	else:
		camrot = false
	var cfov = config.get_value("gfx", "camfov", null)
	if not cfov:
		config.set_value("gfx", "camfov", 45.0)
	cfov = config.get_value("gfx", "camUDfov", null)
	if not cfov:
		config.set_value("gfx", "camUDfov", 50.0)
	cfov = config.get_value("gfx", "camLRfov", null)
	if not cfov:
		config.set_value("gfx", "camLRfov", 60.0)
	cfov = config.get_value("gfx", "camLRheight", null)
	if not cfov:
		config.set_value("gfx", "camLRheight", 80.0)
	cfov = config.get_value("gfx", "camheight", null)
	if not cfov:
		config.set_value("gfx", "camheight", 75.0)
	cfov = config.get_value("gfx", "camUDheight", null)
	if not cfov:
		config.set_value("gfx", "camUDheight", 90.0)
	cfov = config.get_value("gfx", "camtilt", null)
	if not cfov:
		config.set_value("gfx", "camtilt", - 48.0)
	cfov = config.get_value("gfx", "camUDtilt", null)
	if not cfov:
		config.set_value("gfx", "camUDtilt", - 65.0)
	cfov = config.get_value("gfx", "camLRtilt", null)
	if not cfov:
		config.set_value("gfx", "camLRtilt", - 80.0)
	cfov = config.get_value("gfx", "camoffset", null)
	if not cfov:
		config.set_value("gfx", "camoffset", 70.0)
	cfov = config.get_value("gfx", "camUDoffset", null)
	if not cfov:
		config.set_value("gfx", "camUDoffset", 70.0)
	cfov = config.get_value("gfx", "camLRoffset", null)
	if not cfov:
		config.set_value("gfx", "camLRoffset", 70.0)
	cfov = config.get_value("gfx", "camdof", null)
	if not cfov:
		config.set_value("gfx", "camdof", 90.0)
	cfov = config.get_value("gfx", "camUDdof", null)
	if not cfov:
		config.set_value("gfx", "camUDdof", 110.0)
	cfov = config.get_value("gfx", "camLRdof", null)
	if not cfov:
		config.set_value("gfx", "camLRdof", 110.0)
		
	shadtype = config.get_value("gfx", "shadtype", null)
	if not shadtype:
		shadtype = 0
		config.set_value("gfx", "shadtype", 0)
	OS.set_use_vsync(true)
	config.save("user://slssettings.cfg")
	doParticles = config.get_value("gfx", "particles", null)
	if doParticles == null:
		doParticles = false
		config.set_value("gfx", "particles", false)
	doTrail = config.get_value("gfx", "trails", null)
	if doParticles == null:
		doTrail = false
		config.set_value("gfx", "trails", false)
	var crowd = config.get_value("gfx", "docrowd", null)
	if crowd == null:
		config.set_value("gfx", "docrowd", true)
	var shads = config.get_value("gfx", "doshadows", null)
	if shads == null:
		config.set_value("gfx", "doshadows", false)
	
	doSayings = config.get_value("game", "doSayings", null)
	if doSayings == null:
		doSayings = false
		config.set_value("game", "doSayings", false)
		
	lang = config.get_value("misc", "language", null)
	if not lang:
		lang = "en"
		config.set_value("misc", "language", "en")
	loadLanguage()
		
	var lal = config.get_value("game", "lastLevel", 0)
	if not lal:
		config.set_value("game", "lastLevel", 0)
		
	var skil = config.get_value("game", "skillLevel", 0)
	if not skil:
		config.set_value("game", "skillLevel", 0)
	
	doPosInd = config.get_value("game", "doPosInd", null)
	if doPosInd == null:
		doPosInd = true
		config.set_value("game", "doPosInd", true)
	
	pswitch = config.get_value("game", "pswitch", null)
	if pswitch == null:
		pswitch = 0
		config.set_value("game", "pswitch", 0)
	
	
	var vol = config.get_value("audio", "volume", - 1)
	if vol < 0:
		config.set_value("audio", "volume", 75)
	AudioServer.set_bus_volume_db(0, range_lerp(vol, 0, 100, - 24, 0))
		
	vol = config.get_value("audio", "fxvolume", - 1)
	if vol < 0:
		config.set_value("audio", "fxvolume", 75)
	AudioServer.set_bus_volume_db(1, range_lerp(vol, 0, 100, - 24, 0))
	
	vol = config.get_value("audio", "crowdvolume", - 1)
	if vol < 0:
		config.set_value("audio", "crowdvolume", 75)
	AudioServer.set_bus_volume_db(2, range_lerp(vol, 0, 100, - 24, 0))
	
	vol = config.get_value("audio", "musicvolume", - 1)
	if vol < 0:
		config.set_value("audio", "musicvolume", 75)
	AudioServer.set_bus_volume_db(3, range_lerp(vol, 0, 100, - 24, 0))
	
	
	var ctrl = config.get_value("game", "upk", - 1)
	if ctrl < 0:
		config.set_value("game", "upk", udlrk[0])
	else:
		udlrk[0] = ctrl
	ctrl = config.get_value("game", "downk", - 1)
	if ctrl < 0:
		config.set_value("game", "downk", udlrk[1])
	else:
		udlrk[1] = ctrl
	ctrl = config.get_value("game", "leftk", - 1)
	if ctrl < 0:
		config.set_value("game", "leftk", udlrk[2])
	else:
		udlrk[2] = ctrl
	ctrl = config.get_value("game", "rightk", - 1)
	if ctrl < 0:
		config.set_value("game", "rightk", udlrk[3])
	else:
		udlrk[3] = ctrl
		
	ctrl = config.get_value("game", "passk", - 1)
	if ctrl < 0:
		config.set_value("game", "passk", buttsk[0])
	else:
		buttsk[0] = ctrl
	ctrl = config.get_value("game", "shootk", - 1)
	if ctrl < 0:
		config.set_value("game", "shootk", buttsk[1])
	else:
		buttsk[1] = ctrl
	ctrl = config.get_value("game", "chipk", - 1)
	if ctrl < 0:
		config.set_value("game", "chipk", buttsk[2])
	else:
		buttsk[2] = ctrl
	ctrl = config.get_value("game", "thruk", - 1)
	if ctrl < 0:
		config.set_value("game", "thruk", buttsk[3])
	else:
		buttsk[3] = ctrl
	
	ctrl = config.get_value("game", "L1", - 1)
	if ctrl < 0:
		config.set_value("game", "L1", shoulderk[0])
	else:
		shoulderk[0] = ctrl
		
	ctrl = config.get_value("game", "L2", - 1)
	if ctrl < 0:
		config.set_value("game", "L2", shoulderk[1])
	else:
		shoulderk[1] = ctrl
	
	ctrl = config.get_value("game", "R1", - 1)
	if ctrl < 0:
		config.set_value("game", "R1", shoulderk[2])
	else:
		shoulderk[2] = ctrl
	
	ctrl = config.get_value("game", "R2", - 1)
	if ctrl < 0:
		config.set_value("game", "R2", shoulderk[3])
	else:
		shoulderk[3] = ctrl
	firstrun = config.get_value("game", "firstrun", - 1)
	if firstrun == - 1:
		config.set_value("game", "firstrun", 1)
		
	updateKeyBinding()
	
	_saveConfig()
func _saveConfig():
	config.save("user://slssettings.cfg")

func _setTime( var tim):
	gameLength = tim * 60
	config.set_value("match", "time", tim)
	config.save("user://slssettings.cfg")
func _fadeOut():
	themevol.interpolate_property(theme, "volume_db", - 4, - 128, 3)
	themevol.interpolate_callback(self, 3, "_musicOff")
	themevol.start()
	
func _musicOff():
	theme.stop()
	themevol.stop_all()
func _musicOn():
	if not theme.playing:
		theme.volume_db = - 4
		theme.play()
	
func _eprint( var line):
	debugLine.text = line
	
func loadLanguage():
	
	var langs = "res://Languages/" + lang + ".tres"
	
	ll = load(langs)
	

func setupKeys():
	udlrk.clear()
	buttsk.clear()
	shoulderk.clear()
	for i in range(0, 4):
		udlrk.append(OS.find_scancode_from_string(udlr[i]))
		buttsk.append(OS.find_scancode_from_string(butts[i]))
		shoulderk.append(OS.find_scancode_from_string(shoulder[i]))
	updateKeyBinding()

func updateKeyBinding():
	
	InputMap.load_from_globals()
	change_action_key("p1_up", udlrk[0])
	change_action_key("p1_up", 16777232)
	
	change_action_key("p1_down", udlrk[1])
	change_action_key("p1_down", 16777234)
	
	change_action_key("p1_left", udlrk[2])
	change_action_key("p1_left", 16777231)
	
	change_action_key("p1_right", udlrk[3])
	change_action_key("p1_right", 16777233)
	
	change_action_key("p1_pass", buttsk[0])
	change_action_key("p1_shoot", buttsk[1])
	change_action_key("p1_chip", buttsk[2])
	change_action_key("p1_thru", buttsk[3])


	change_action_key("p1_burst", shoulderk[2])
	


func change_action_key( var action, var keycode):
	var nevent = InputEventKey.new()
	nevent.set_scancode(keycode)
	InputMap.action_add_event(action, nevent)
	
func _setKeyConfig():
	
	config.set_value("game", "upk", udlrk[0])
	config.set_value("game", "downk", udlrk[1])
	config.set_value("game", "leftk", udlrk[2])
	config.set_value("game", "rightk", udlrk[3])
	
	config.set_value("game", "passk", buttsk[0])
	config.set_value("game", "shootk", buttsk[1])
	config.set_value("game", "chipk", buttsk[2])
	config.set_value("game", "thruk", buttsk[3])
	
	
	
	config.set_value("game", "R1", shoulderk[2])
	
	
func on_commercial_break_done( var _response):
	
	
	if adsource == adfrom.GOGAME:
		var _foo = get_tree().change_scene("res://Scenes/Game.tscn")
	else:
		emit_signal("adDone")
		
func on_rewarded_break_done( var response):
	
	
	if not isUnlocking:
		if response:
			var _foo = get_tree().change_scene("res://Scenes/Game.tscn")
		else:
			game.hud._unlockUI()
	else:
		game.hud._unlockRewarded(response)
	
	

func loadLocks():
	var f = File.new()
	var err = f.open("user://slsteams.cfg", File.READ)
	if err:
		print("no file: ", err)
		teamprem.clear()
		teamnormal.clear()
		for _i in range(0, 38):
			teamprem.append(0)
		for _i in range(0, 59):
			teamnormal.append(0)
		f.close()
		teamprem[0] = 1
		teamnormal[0] = 1
		_saveLocks()
	else:
		teamprem = f.get_var()
		teamnormal = f.get_var()
		teamprem.resize(38)
		teamnormal.resize(59)
		f.close()
		
func _saveLocks():
	var f = File.new()
	var err = f.open("user://slsteams.cfg", File.WRITE)
	if not err:
		f.store_var(teamprem)
		f.store_var(teamnormal)
		f.close()
	else:
		print("can't save teams")
		f.close()
func unlockPrem():
	var t = randi() % 38
	var ut = - 1
	for _i in range(0, 38):
		if teamprem[t] == 0:
			teamprem[t] = 1
			ut = t
			break
		t = (t + 1) % 38
	return ut
func unlockNormal():
	var t = randi() % 59
	var ut = - 1
	for _i in range(0, 59):
		if teamnormal[t] == 0:
			teamnormal[t] = 1
			ut = t
			break
		t = (t + 1) % 59
	return ut
	
func _unlockTeam( var isPrem):
	# All teams start unlocked, so there is never anything new to unlock.
	return "false"
	var t = - 1
	var uteam = null
	var udir = "res://Teams/1/"
	if isPrem:
		t = unlockPrem()
	else:
		t = unlockNormal()
		udir = "res://Teams/2/"
	if t < 0:
		return "false"
	var tc = 0
	
	var tdir = Directory.new()
	if tdir.open(udir) == OK:
		print("opened dir ")
		tdir.list_dir_begin(true, true)
		var filen = tdir.get_next()
		while (filen != ""):
			if tc == t:
				var fn = udir + filen
				var tt = load(fn)
				print(tt.teamname)
				uteam = tt
				break
			tc += 1
			filen = tdir.get_next()
			
		tdir.list_dir_end()
	if uteam:
		_saveLocks()
		return uteam.teamname
	else:
		return "false"
	
func _checkLocked( var tm, var lev):
	# Every club team is unlocked from the start (no need to win matches or watch ads).
	return true
	var lt = teamprem
	if lev == 2:
		lt = teamnormal
	if lt[tm] == null or lt[tm] == 0:
		lt[tm] = 0
		return false
	else:
		return true

# --- Full-window gameplay ----------------------------------------------------
# Menus are laid out for a fixed 1031x580 screen, so the project keeps the
# "keep" stretch aspect (letterboxed). Gameplay scenes (Game, training) call
# enterFullWindow() so the 3D view fills the browser window; the fixed-size HUD
# stays centred. exitFullWindow() restores "keep" when the scene is left.
const FULLWINDOW_BASE = Vector2(1031, 580)
var _fwScene = null

func enterFullWindow(scene):
	_fwScene = scene
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_EXPAND, FULLWINDOW_BASE)
	if not get_viewport().is_connected("size_changed", self, "_fitFullWindow"):
		get_viewport().connect("size_changed", self, "_fitFullWindow")
	_fitFullWindow()

func _fitFullWindow():
	if _fwScene == null or not is_instance_valid(_fwScene):
		return
	var vs = get_viewport().get_visible_rect().size
	if _fwScene.has_node("VPC"):
		var vpc = _fwScene.get_node("VPC")
		vpc.rect_position = Vector2.ZERO
		vpc.rect_size = vs
		# The container resizes its viewport to the 2D size; render at window resolution instead.
		var rt = get_tree().get_root()
		if rt.size.x != vpRes[0]:
			vpc.get_node("VP").size = rt.size
		else:
			vpc.get_node("VP").size = Vector2(vpRes[0], vpRes[1])
	if _fwScene.has_node("Hud"):
		_fwScene.get_node("Hud").rect_position = ((vs - FULLWINDOW_BASE) * 0.5).floor()

func exitFullWindow(scene):
	if scene != _fwScene:
		return
	_fwScene = null
	if get_viewport().is_connected("size_changed", self, "_fitFullWindow"):
		get_viewport().disconnect("size_changed", self, "_fitFullWindow")
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, FULLWINDOW_BASE)

# --- 11v11 mode -------------------------------------------------------------------
# squad = players on the pitch per team (keeper included); ps = pitch scale.
var elevenMode = false
var squad = 7
var ps = 1.0

func setElevenMode(on):
	elevenMode = on
	squad = 11 if on else 7
	ps = 1.25 if on else 1.0
