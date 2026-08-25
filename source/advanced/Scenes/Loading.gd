extends Control

var loader


func _ready():
	if Global.toLoad == 0:
		loadMenu()
	elif Global.toLoad == 1:
		loadGame()
	else:
		loadSelect()
func loadMenu():
	var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")
	

func loadGame():
	var _foo = get_tree().change_scene("res://Scenes/Game.tscn")
	

func loadSelect():
	var _foo = get_tree().change_scene("res://Scenes/TeamSelect.tscn")
	
	




