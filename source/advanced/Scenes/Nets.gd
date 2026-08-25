extends Spatial





func _ready():
	pass

func _initNet( var b, var myG, var flip):
	
	
	$Nettest.visible = true
		
		
	$Nettest.set_process(true)
	$Nettest.ball = b
	$Nettest.myGoal = myG
	$Nettest.flip = flip
	return $Nettest


