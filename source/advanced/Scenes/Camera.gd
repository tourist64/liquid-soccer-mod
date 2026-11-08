extends Camera

class_name InterpolatedCamera3D



export var translate_min: = 1
export var translate_max: = 15

var target_node = null
var game = null


export var target: NodePath
var shake = 0
var targetfov = 40
var limitX = 100
var limitZ = 65
export var mlimitx = 120
export var mlimitz = 65
export var mfov = 45
export var zoffset = 70
export var xoffset = 0
func _ready():
	
	target_node = get_node(target) as Spatial
	_setLimits()
	set_process(false)
	set_physics_process(false)
	
	_setupCamera()
	

func _setupCamera():
	
	match Global.config.get_value("gfx", "camtype"):
		0:
			zoffset = Global.config.get_value("gfx", "camoffset")
			xoffset = 0
			mfov = Global.config.get_value("gfx", "camfov")
			fov = mfov
			rotation_degrees.x = Global.config.get_value("gfx", "camtilt")
			translation.y = Global.config.get_value("gfx", "camheight")
		1:
			xoffset = Global.config.get_value("gfx", "camUDoffset")
			zoffset = 0
			mfov = Global.config.get_value("gfx", "camUDfov")
			fov = mfov
			rotation_degrees.x = Global.config.get_value("gfx", "camUDtilt")
			translation.y = Global.config.get_value("gfx", "camUDheight")
		2:
			xoffset = 0
			zoffset = Global.config.get_value("gfx", "camLRoffset")
			mfov = Global.config.get_value("gfx", "camLRfov")
			fov = mfov
			rotation_degrees.x = Global.config.get_value("gfx", "camLRtilt")
			translation.y = Global.config.get_value("gfx", "camLRheight")
	if Global.elevenMode and Global.config.get_value("gfx", "camtype") == 0:
		# 11v11 tele-broadcast view, fitted to FC footage: gantry camera ~25 m up, ~55 m
		# behind the near touchline, 17.5 deg down, ~15 deg vertical FOV. It pans along the
		# pitch but never across, so the whole width stays in view.
		zoffset = 293.0
		translation.y = 84.0
		rotation_degrees.x = - 17.5
		mfov = 15.3
		fov = mfov
		mlimitz = 50
		# The far stands are further away on the bigger pitch; don't clip them (black band).
		far = max(far, 1500.0)
		# The camera sits behind the near stand; skip drawing it (the pitch edge is ~195 away).
		near = 165.0
	targetfov = mfov

func _setTarget( var t):
	target_node = t as Spatial
	
func _setGame( var g):
	game = g
	set_process(true)
	mfov = fov
func _setCelebrate():
	limitX = min(limitX + 50, 150 * Global.ps)
	limitZ = min(limitZ + 40, 85 * Global.ps)
	
	targetfov = 28
	
func _setLimits():
	limitX = mlimitx * Global.ps
	limitZ = mlimitz * Global.ps
	fov = mfov
	targetfov = mfov
	
func _process(delta: float) -> void :
	
	
	if target == null:
		return
	var lpos = target_node.translation + Global.ballvel * delta * 4.0
	
	var nx = xoffset + min(max( - limitX, lpos.x), limitX) + (shake * (rand_range( - 6, 6)) * delta)
	var nz = zoffset + min(max( - limitZ, lpos.z), limitZ) + (shake * (rand_range( - 6, 6)) * delta)
	if Global.elevenMode:
		# Broadcast view: stop at the near touchline instead of swinging over the stands.
		nz = zoffset
	var updatedt = Vector3(nx, translation.y, nz)
	var updated = updatedt - translation
	var speed = 1.0
	if updated.length_squared() > 1.0:
		speed = lerp(0.1, 5, smoothstep(4, 10, updated.length()))
	
	translation = translation.linear_interpolate(updatedt, delta * speed)
	if fov != targetfov:
		fov -= (fov - targetfov) * delta * 2.0
	shake *= 0.95


func _updateCam( var delta):
	var lpos = target_node.translation + Global.ballvel * delta * 4.0
	
	var nx = xoffset + min(max( - limitX, lpos.x), limitX) + (shake * (rand_range( - 6, 6)) * delta)
	var nz = zoffset + min(max( - limitZ, lpos.z), limitZ) + (shake * (rand_range( - 6, 6)) * delta)
	if Global.elevenMode:
		# Broadcast view: stop at the near touchline instead of swinging over the stands.
		nz = zoffset
	var updatedt = Vector3(nx, translation.y, nz)
	var updated = updatedt - translation
	var speed = 1.0
	if updated.length_squared() > 1.0:
		speed = lerp(0.1, 5, smoothstep(4, 10, updated.length()))
	
	translation = translation.linear_interpolate(updatedt, delta * speed)
	
		
func set_target_node(node):
	target_node = node as Spatial
