extends Control


var trans = null

var done = false


func _ready():
	
	trans = $TextureRect / Transition
	
	
	$TextureRect / TextureButton.grab_focus()
	
	Global._loadConfig()
	setButtons()
	
	if not (Global.firsttime):
		trans.color = Color(0.09, 0.22, 0.32, 1.0)
		
	else:
	
		trans.color = Color(0.09, 0.22, 0.32, 1.0)
		Global.firsttime = false
		Global._setupPoki()
	
	if Global.firstrun:
		Global.firstrun = 0
		Global.config.set_value("game", "firstrun", 0)
		Global._saveConfig()
	
	yield(get_tree().create_timer(0.5), "timeout")
	trans._wipeOn()
	yield(trans.tween, "tween_completed")
	
	trans._hideLoading()
	
	Global.joypads = Input.get_connected_joypads()
	
	if Global.tournament:
		Global.tournament.queue_free()
		Global.tournament = null
	
	
	setStats()
	
	
	
	Global._musicOn()
	Engine.set_time_scale(1.0)


func setButtons():
	
	$TextureRect / TextureButton.text = Global.ll.menus[0]
	$TextureRect / P1P2Button.text = Global.ll.menus[1]
	$TextureRect / CupButton.text = Global.ll.menus[2]
	$TextureRect / WCButton.text = Global.ll.menus[3]
	$TextureRect / MultiplayerButton.text = "Multiplayer"
	
	$TextureRect / HelpButton.text = "?"
	$TextureRect / PracticeButton.text = Global.ll.menus[6]
	
	
	
func setStats():
	$TextureRect / Stats.text = "Your Stats: "
	$TextureRect / Stats.text += " Played: " + str(Global.stats.stats_dict.games_played)
	$TextureRect / Stats.text += " Won: " + str(Global.stats.stats_dict.wins)
	$TextureRect / Stats.text += " Goals for: " + str(Global.stats.stats_dict.goals_for)
	$TextureRect / Stats.text += " Goals against: " + str(Global.stats.stats_dict.goals_against)
	
func _on_TextureButton_pressed():
	Global.toLoad = 2
	Global.p1human = true
	Global.p2human = false
	Global.isPenalties = false
	
	trans._wipeOff()
	yield(trans.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/Loading.tscn")
	trans.visible = false

func _on_SettingsButton_pressed():
	
	Global.toLoad = 1
	
	trans._wipeOff()
	yield(trans.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/Settings.tscn")
	

func _on_ExitButton_pressed():
	
	
	
	
	Global.stats._saveStats()
	trans._wipeOff()
	_on_ButtonExit_pressed()
	
	
	


func _on_ButtonWish_pressed():
	var _succss = OS.shell_open("https://store.steampowered.com/app/1705130/Super_Liquid_Soccer/")



func _on_ButtonWish2_pressed():
	var _succss = OS.shell_open("https://discord.gg/yKHyTeyfG7")


func _on_ButtonExit_pressed():
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)



func _on_ButtonDiscord_pressed():
	var _succss = OS.shell_open("https://discord.gg/yKHyTeyfG7")



func _on_ButtonSteam_pressed():
	var _succss = OS.shell_open("https://store.steampowered.com/app/1705130/Super_Liquid_Soccer/")



func _on_ButtonItch_pressed():
	var _succss = OS.shell_open("https://punyrobot.itch.io/superliquidsoccer")


func _on_P1P2Button_pressed():
	
	Global.isPenalties = true
	
	Global.p1human = true
	Global.p2human = false
	
	Global.toLoad = 2
	trans._wipeOff()
	yield(trans.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/Loading.tscn")



func _on_CupButton_pressed():
	Global.tType = 0
	Global.isPenalties = false
	
	trans._wipeOff()
	yield(trans.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/CupSelect.tscn")


func _on_LeagueButton_pressed():
	Global.tType = 5
	Global.isPenalties = false
	
	trans._wipeOff()
	Global.isPenalties = false
	yield(trans.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/GlobalCupSelect.tscn")
	

func _on_Button_pressed():
	trans._wipeOff()
	yield(trans.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/HelpPage.tscn")



func _on_EditButton_pressed():
	trans._wipeOff()
	yield(trans.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/TeamEditor.tscn")



func _on_WCButton_pressed():
	Global.tType = 3
	Global.isPenalties = false
	trans._wipeOff()
	yield(trans.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/GlobalCupSelect.tscn")


func _on_MultiplayerButton_pressed():
	trans._wipeOff()
	yield(trans.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/Multiplayer.tscn")


func _on_PracticeButton_pressed():
	trans._wipeOff()
	Global.isPenalties = false
	Global._musicOff()
	yield(trans.tween, "tween_completed")
	
	var _foo = get_tree().change_scene("res://Scenes/training.tscn")
