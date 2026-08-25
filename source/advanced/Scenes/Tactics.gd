extends Control





func _ready():
	
	$tacticsblueprint / TacticsEditor._initMap(Global.t1)
	$tacticsblueprint / TacticsEditor2._initMap(Global.t2)
	$tacticsblueprint / ButtonKickOff.grab_focus()
	$Transition._wipeOn()



func _playerSelected( var _unused):
	pass
func _subSelected( var _unused):
	pass

func _on_TextureButton_pressed():
	
	$tacticsblueprint / ButtonKickOff.release_focus()
	$Transition._wipeOffTex()
	
	Global.stadium = 3 - int(Global.t1.level)
	
	yield($Transition / Tween, "tween_completed")
	Global.toLoad = 1
	
	var _foo = get_tree().change_scene("res://Scenes/Loading.tscn")


func _on_Button_pressed():
	Global.toLoad = 2
	
	$Transition._wipeOffTex()
	yield($Transition / Tween, "tween_completed")
	
	var _foo = get_tree().change_scene("res://Scenes/Loading.tscn")

