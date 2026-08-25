extends Spatial








func _ready():
	pass

func _dorotate( var target):
	var start = $Cups.rotation_degrees
	var e = 0
	match target:
		1:
			e = 180
		2:
			e = 270
		3:
			e = 90
	var end = Vector3(0, e, 0)
	$Tween.interpolate_property($Cups, "rotation_degrees", start, end, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()



func _showCup( var id):
	$Cups / Cup1.visible = id == 0
	$Cups / Cup2.visible = id == 1
	$Cups / Cup3.visible = id == 2
	$Cups / Cup4.visible = id == 3
	$Cups / Cup5.visible = id == 4
	$Cups / Cup6.visible = id == 5
	if (id == 5):
		$Camera.translation.z = - 25
	
