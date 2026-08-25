extends Control








func _ready():
	pass

func _setTie( var t1, var t2, var s1, var s2, var isP, var isP2):
	$T1.text = t1
	$T2.text = t2
	$S1.text = str(s1)
	$S2.text = str(s2)
	if isP:
		$T1.modulate = Color.white
	elif isP2:
		$T2.modulate = Color.white




