extends Control

var learning = false
var udlr = "WSAD"
var butts = "MJLI"
var shoulder = "QOEU"

var ckey = 0


func _ready():
	$ColorRect / GameButton.grab_focus()
	
	Global.joypads = Input.get_connected_joypads()
	if Global.joypads.size() > 0:
		$ColorRect / Controller1 / Label.text = Input.get_joy_name(Global.joypads[0])
	if Global.joypads.size() > 1:
		$ColorRect / Controller2 / Label.text = Input.get_joy_name(Global.joypads[1])
		
	
	$ColorRect / GfxButton.text = Global.ll.setmenus[0]
	$ColorRect / GameButton.text = Global.ll.setmenus[2]
	$ColorRect / AudioButton.text = Global.ll.setmenus[1]
	$ColorRect / KeysButton.text = Global.ll.setmenus[3]
	
	
	var tim = Global.config.get_value("match", "time")
	if ( not tim):
		tim = 3
	match tim:
		1:
			$ColorRect / Game / GameLength / Button4.pressed = true
		2:
			$ColorRect / Game / GameLength / Button1.pressed = true
		3:
			$ColorRect / Game / GameLength / Button2.pressed = true
	$Transition._wipeOn()
	
			
			
	$ColorRect / Graphics / ButtonVsync.pressed = Global.config.get_value("gfx", "vsync", true)
	if $ColorRect / Graphics / ButtonVsync.pressed:
		$ColorRect / Graphics / ButtonVsync.text = "on"
	else:
		$ColorRect / Graphics / ButtonVsync.text = "off"
	$ColorRect / Graphics / ParticlesButton.pressed = Global.config.get_value("gfx", "particles", true)
	
	if $ColorRect / Graphics / ParticlesButton.pressed:
		$ColorRect / Graphics / ParticlesButton.text = "on"
	else:
		$ColorRect / Graphics / ParticlesButton.text = "off"
		
	$ColorRect / Graphics / TrailsButton.pressed = Global.config.get_value("gfx", "trails", true)
	if $ColorRect / Graphics / TrailsButton.pressed:
		$ColorRect / Graphics / TrailsButton.text = "on"
	else:
		$ColorRect / Graphics / TrailsButton.text = "off"
	
	
		
	$ColorRect / Game / MoveAssist.add_item("Off")
	$ColorRect / Game / MoveAssist.add_item("half")
	$ColorRect / Game / MoveAssist.add_item("full")
	$ColorRect / Game / MoveAssist.select(Global.config.get_value("player", "assist"))
	
	$ColorRect / Game / CameraButton.add_item("default")
	$ColorRect / Game / CameraButton.add_item("top down U/D")
	$ColorRect / Game / CameraButton.add_item("top down L/R")
	$ColorRect / Game / CameraButton.select(Global.config.get_value("gfx", "camtype"))
	
	$ColorRect / Game / PlayerSwitchButton.add_item("English")
	$ColorRect / Game / PlayerSwitchButton.add_item("Espanol")
	$ColorRect / Game / PlayerSwitchButton.add_item("Deutsch")
	$ColorRect / Game / PlayerSwitchButton.add_item("Italiano")
	$ColorRect / Game / PlayerSwitchButton.add_item("Scottish")
	$ColorRect / Game / PlayerSwitchButton.add_item("Francais")
	$ColorRect / Game / PlayerSwitchButton.add_item("Português")
	
	
	var sel = 0
	var lang = Global.config.get_value("misc", "language")
	match lang:
		"es":
			sel = 1
		"de":
			sel = 2
		"it":
			sel = 3
		"sco":
			sel = 4
		"fr":
			sel = 5
		"pt":
			sel = 6
	$ColorRect / Game / PlayerSwitchButton.select(sel)
	
	$ColorRect / Graphics / ShaderOption.add_item("none")
	$ColorRect / Graphics / ShaderOption.add_item("toon")
	$ColorRect / Graphics / ShaderOption.add_item("16-bit")
	$ColorRect / Graphics / ShaderOption.add_item("8-bit")
	$ColorRect / Graphics / ShaderOption.select(Global.config.get_value("gfx", "shadtype"))
	if Global.config.get_value("gfx", "doshadows"):
		$ColorRect / Graphics / ShadowsButton.text = "on"
		$ColorRect / Graphics / ShadowsButton.pressed = true
	else:
		$ColorRect / Graphics / ShadowsButton.text = "off"
		$ColorRect / Graphics / ShadowsButton.pressed = false
	if Global.config.get_value("gfx", "docrowd"):
		$ColorRect / Graphics / CrowdButton.text = "on"
		$ColorRect / Graphics / CrowdButton.pressed = true
	else:
		$ColorRect / Graphics / CrowdButton.text = "off"
		$ColorRect / Graphics / CrowdButton.pressed = false
	
		
	$ColorRect / Game / DifficultySlider.value = int(Global.config.get_value("game", "skillLevel") * 10)
	
	
	$ColorRect / Audio / MasterVolSlider.value = int(Global.config.get_value("audio", "volume"))
	$ColorRect / Audio / MusicVolSlider.value = int(Global.config.get_value("audio", "musicvolume"))
	$ColorRect / Audio / FXVolSlider.value = int(Global.config.get_value("audio", "fxvolume"))
	$ColorRect / Audio / CrowdVolSlider.value = int(Global.config.get_value("audio", "crowdvolume"))
	Input.get_connected_joypads()
func _on_Button_pressed():
	if not learning:
		
		Global._applyConfig()

		$Transition._wipeOff()
		yield($Transition / Tween, "tween_completed")
		var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")



func _on_ButtonLow_pressed():
	Global.config.set_value("gfx", "quality", 0)
	
func _on_ButtonMid_pressed():
	Global.config.set_value("gfx", "quality", 1)
	
func _on_ButtonHigh_pressed():
	Global.config.set_value("gfx", "quality", 2)
	_setResConfig()



func _on_Button1_pressed():
	Global._setTime(2)
	_setResConfig()


func _on_Button2_pressed():
	Global._setTime(3)
	_setResConfig()


func _on_Button3_pressed():
	Global._setTime(5)
	_setResConfig()


func _on_ButtonDouble_pressed():
	Global.vpRes[0] = 1920 * 2
	Global.vpRes[1] = 1080 * 2
	_setResConfig()


func _setResConfig():
	Global.config.set_value("gfx", "res", Global.vpRes)
	
func _on_ButtonNative_pressed():
	
	var res = OS.get_screen_size()
	
	Global.vpRes[0] = min(1920, res.x)
	Global.vpRes[1] = min(1080, res.y)
	
func _on_Button75_pressed():
	Global.vpRes[0] = 1440
	Global.vpRes[1] = 810
	_setResConfig()

func _on_Button50_pressed():
	Global.vpRes[0] = 1280
	Global.vpRes[1] = 720
	_setResConfig()

func _on_Button16Bit_pressed():
	Global.vpRes[0] = 480
	Global.vpRes[1] = 270
	_setResConfig()

func _on_Button8Bit_pressed():
	Global.vpRes[0] = 240
	Global.vpRes[1] = 135
	_setResConfig()


func _on_ButtonVsync_pressed():
	if $ColorRect / Graphics / ButtonVsync.pressed:
		$ColorRect / Graphics / ButtonVsync.text = "on"
		Global.config.set_value("gfx", "vsync", true)
	else:
		$ColorRect / Graphics / ButtonVsync.text = "off"
		Global.config.set_value("gfx", "vsync", false)
		
	


func _on_OptionButton_item_selected(index):
	Global.config.set_value("player", "assist", index)
	
	


func _on_GameButton_pressed():
	if not learning:
		$ColorRect / Game.visible = true
		$ColorRect / Graphics.visible = false
		$ColorRect / Audio.visible = false
		$ColorRect / Keyboard.visible = false
	
	
func _on_GfxButton_pressed():
	if not learning:
		$ColorRect / Game.visible = false
		$ColorRect / Graphics.visible = true
		$ColorRect / Audio.visible = false
		$ColorRect / Keyboard.visible = false
	
	
func _on_AudioButton_pressed():
	if not learning:
		$ColorRect / Game.visible = false
		$ColorRect / Graphics.visible = false
		$ColorRect / Audio.visible = true
		$ColorRect / Keyboard.visible = false
	
	


func _on_CameraButton_item_selected(index):
	Global.config.set_value("gfx", "camtype", index)
	

func _on_ShaderOption_item_selected(index):
	Global.config.set_value("gfx", "shadtype", index)
	

func _on_TrailsButton_toggled(button_pressed):
	Global.config.set_value("gfx", "trails", button_pressed)
	
	if $ColorRect / Graphics / TrailsButton.pressed:
		$ColorRect / Graphics / TrailsButton.text = "on"
	else:
		$ColorRect / Graphics / TrailsButton.text = "off"
		

func _on_ParticlesButton_toggled(button_pressed):
	Global.config.set_value("gfx", "particles", button_pressed)
	
	if $ColorRect / Graphics / ParticlesButton.pressed:
		$ColorRect / Graphics / ParticlesButton.text = "on"
	else:
		$ColorRect / Graphics / ParticlesButton.text = "off"


func _on_SpeechButton_toggled(button_pressed):
	Global.config.set_value("game", "doSayings", button_pressed)
	
	if $ColorRect / Game / SpeechButton.pressed:
		$ColorRect / Game / SpeechButton.text = "on"
	else:
		$ColorRect / Game / SpeechButton.text = "off"
		


func _on_DifficultySlider_value_changed(value):
	Global.config.set_value("game", "skillLevel", value * 0.1)


func _on_MasterVolSlider_drag_ended(value_changed):
	if (value_changed):
		var val = $ColorRect / Audio / MasterVolSlider.value
		Global.config.set_value("audio", "volume", val)
	
		var b = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(b, range_lerp(val, 0, 100, - 24, 0))
		
func _on_MusicVolSlider_drag_ended(value_changed):
	if (value_changed):
		var val = $ColorRect / Audio / MusicVolSlider.value
		Global.config.set_value("audio", "musicvolume", val)
		var b = AudioServer.get_bus_index("Music")
		AudioServer.set_bus_volume_db(b, range_lerp(val, 0, 100, - 24, 0))
		

func _on_FXVolSlider_drag_ended(value_changed):
	if (value_changed):
		var val = $ColorRect / Audio / FXVolSlider.value
		Global.config.set_value("audio", "fxvolume", val)
		var b = AudioServer.get_bus_index("SFX")
		AudioServer.set_bus_volume_db(b, range_lerp(val, 0, 100, - 24, 0))
		$ColorRect / FXSound.playing = true

func _on_CrowdVolSlider_drag_ended(value_changed):
	if (value_changed):
		var val = $ColorRect / Audio / CrowdVolSlider.value
		Global.config.set_value("audio", "crowdvolume", val)
		var b = AudioServer.get_bus_index("Crowd")
		AudioServer.set_bus_volume_db(b, range_lerp(val, 0, 100, - 24, 0))
		$ColorRect / CrowdSound.playing = true

func _on_PossIndButton_toggled(button_pressed):
	Global.doPosInd = button_pressed
	Global.config.set_value("game", "doPosInd", button_pressed)
	if button_pressed:
		$ColorRect / Game / PossIndButton.text = "on"
	else:
		$ColorRect / Game / PossIndButton.text = "off"

func _on_PlayerSwitchButton_item_selected(index):
	var lan = "en"
	match (index):
		1:
			lan = "es"
		2:
			lan = "de"
		3:
			lan = "it"
		4:
			lan = "sco"
		5:
			lan = "fr"
		6:
			lan = "pt"
			
	Global.config.set_value("misc", "language", lan)
	

func _on_MasterVolSlider_value_changed(value):
	_on_MasterVolSlider_drag_ended(true)


func _on_MusicVolSlider_value_changed(value):
	_on_MusicVolSlider_drag_ended(true)


func _on_FXVolSlider_value_changed(value):
	_on_FXVolSlider_drag_ended(true)


func _on_CrowdVolSlider_value_changed(value):
	_on_CrowdVolSlider_drag_ended(true)


func _on_KeysButton_pressed():
	if not learning:
		grabKeys()
		$ColorRect / Game.visible = false
		$ColorRect / Graphics.visible = false
		$ColorRect / Audio.visible = false
		$ColorRect / Keyboard.visible = true
	
	
func buildString( var s):
	var retstring = ""
	var cs = s.rsplit(",", true, 0)
	for i in range(cs.size()):
		retstring += cs[i]
		retstring += "\n"
	
	return retstring
func _input(event):
	if learning:
		if event is InputEventKey and event.is_pressed():
			var key = (OS.get_scancode_string(event.physical_scancode))
			if ckey < 4:
				Global.udlrk[ckey] = (event.physical_scancode)
				udlr += key + ","
				ckey += 1
				$ColorRect / Keyboard / UDLRKeys.text = buildString(udlr)
			elif ckey < 8:
				Global.buttsk[ckey - 4] = (event.physical_scancode)
				butts += key + ","
				ckey += 1
				$ColorRect / Keyboard / buttonsKeys.text = buildString(butts)
			else:
				Global.shoulderk[2] = (event.physical_scancode)
				shoulder += key
				ckey += 1
				$ColorRect / Keyboard / shoulderKeys.text = buildString(shoulder)
		if ckey > 8:
			learning = false
			Global._setKeyConfig()
			Global.updateKeyBinding()
			$ColorRect / Keyboard / pressLabel.text = "keys updated!"
			
			Global._saveConfig()

func _on_setKeysButton_pressed():
	
	$ColorRect / Keyboard / UDLRKeys.text = " <"
	$ColorRect / Keyboard / buttonsKeys.text = ""
	$ColorRect / Keyboard / shoulderKeys.text = ""
	$ColorRect / Keyboard / pressLabel.visible = true
	
	$ColorRect / Keyboard / pressLabel.text = "press key for..."
	ckey = 0
	udlr = ""
	butts = ""
	shoulder = ""
	learning = true
	
	
	
	
	

func grabKeys():
	udlr = ""
	butts = ""
	shoulder = ""
	for i in range(0, 4):
		udlr += OS.get_scancode_string(Global.udlrk[i]) + ","
		butts += OS.get_scancode_string(Global.buttsk[i]) + ","
	shoulder += OS.get_scancode_string(Global.shoulderk[2])
	
	$ColorRect / Keyboard / UDLRKeys.text = buildString(udlr)
	$ColorRect / Keyboard / buttonsKeys.text = buildString(butts)
	$ColorRect / Keyboard / shoulderKeys.text = buildString(shoulder)
	
	


func _on_CrowdButton_toggled(button_pressed):
	if button_pressed:
		$ColorRect / Graphics / CrowdButton.text = "on"
	else:
		$ColorRect / Graphics / CrowdButton.text = "off"
	Global.config.set_value("gfx", "docrowd", button_pressed)


func _on_ShadowsButton_toggled(button_pressed):
	if button_pressed:
		$ColorRect / Graphics / ShadowsButton.text = "on"
	else:
		$ColorRect / Graphics / ShadowsButton.text = "off"
	Global.config.set_value("gfx", "doshadows", button_pressed)


func _on_Button4_pressed():
	Global._setTime(1)
	_setResConfig()


func _on_KeyDefaultButton_pressed():
	learning = false
	Global.setupKeys()
	grabKeys()
	Global._setKeyConfig()
	Global.updateKeyBinding()
	$ColorRect / Keyboard / pressLabel.text = "keys updated!"
	
