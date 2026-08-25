extends Control








func _ready():
	
	$BackButton.grab_focus()
	
	var udlr = Global.ll.controls[0] + " :\n" + Global.ll.controls[1] + " :\n"
	udlr += Global.ll.controls[2] + " :\n" + Global.ll.controls[3] + " :"
	$TextureRect / Label.text = udlr
	var l2 = Global.ll.controls[4] + " :\n" + Global.ll.controls[5] + " :\n"
	l2 += Global.ll.controls[6] + " :\n" + Global.ll.controls[7] + " :\n"
	$TextureRect / Label2.text = l2
	var l3 = Global.ll.controls[8] + " :\n"
	$TextureRect / Label3.text = l3
	
	$Keys / Pass.text = "<" + OS.get_scancode_string(Global.config.get_value("game", "passk")) + ">"
	$Keys / Shoot.text = "<" + OS.get_scancode_string(Global.config.get_value("game", "shootk")) + ">"
	$Keys / Chip.text = "<" + OS.get_scancode_string(Global.config.get_value("game", "chipk")) + ">"
	$Keys / Thru.text = "<" + OS.get_scancode_string(Global.config.get_value("game", "thruk")) + ">"
	$Keys / Burst.text = "<" + OS.get_scancode_string(Global.config.get_value("game", "R1")) + ">"
	
	$Keys / Low.text = "<" + OS.get_scancode_string(Global.config.get_value("game", "L2")) + ">"
	if OS.has_touchscreen_ui_hint():
		$Keys / Pass.text = "(pass)"
		$Keys / Shoot.text = "(shoot)"
		$Keys / Chip.text = "(chip)"
		$Keys / Thru.text = "(thru)"
		$Keys / Switch.text = ""
		$Keys / Burst.text = "(sprint)"
		
		
		
		
	$Transition._wipeOn()
	yield($Transition / Tween, "tween_completed")





func _on_BackButton_pressed():
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")

