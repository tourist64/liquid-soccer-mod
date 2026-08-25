extends Spatial








func _ready():
	pass



func _physics_process(delta):
	$Cups / Cup5.rotation_degrees.y += 10.0 * delta
