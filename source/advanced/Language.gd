extends Control


func _ready():
	
	Global._loadConfig()
	var loc = OS.get_locale_language()
	var gotLang = checkLang(loc)
	
	if not Global.firstrun:
		
		var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")
	elif gotLang:
		goGame()
	else:
		$Transition._wipeOn()
		
func checkLang( var l):
	match l:
		"en", "fr", "de", "it", "es", "pt":
			Global.config.set_value("misc", "language", l)
			return true
	return false
func goGame():
	Global._saveConfig()
	Global._applyConfig()
	$Transition._wipeOff()
	yield($Transition.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/training.tscn")
	
func _on_EButton_pressed():
	Global.config.set_value("misc", "language", "en")
	goGame()


func _on_EspButton_pressed():
	Global.config.set_value("misc", "language", "es")
	goGame()

func _on_DeButton_pressed():
	Global.config.set_value("misc", "language", "de")
	goGame()

func _on_ITButton_pressed():
	Global.config.set_value("misc", "language", "it")
	goGame()

func _on_ScoButton_pressed():
	Global.config.set_value("misc", "language", "sco")
	goGame()


func _on_FRAButton_pressed():
	Global.config.set_value("misc", "language", "fr")
	goGame()


func _on_PTButton_pressed():
	Global.config.set_value("misc", "language", "pt")
	goGame()
