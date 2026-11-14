extends RigidBody


var player = null
var shooter = null
var isShot = false

var curl = Vector3.ZERO
var drag = Vector3.ZERO
var Game = null
var oob = false
var oobpos = Vector3.ZERO
# 11v11: a pass nobody has touched yet dies on the grass instead of running out of play.
var passGuard = false
const LINE_BRAKE_LOOK = 0.6
const LINE_STOP_GAP = 3.0
# Lobs keep more pace in the air, so long ones needn't be struck absurdly hard.
var loftFlight = false
var lobbed = false
const LOB_AIR_DAMP = 0.1
const LOB_DRAG_CANCEL = 0.2
const LOB_LANDS_AT = 0.87
# A lob is only ever eased to a stop while rolling, and gently.
const LOB_ROLL_HEIGHT = 1.2
const LOB_MAX_BRAKE = 60.0
var trail = null
var minPassSpeed = 80
var maxPassSpeed = 100


var doHit = false
var rayC = null

var shotV = Vector3.ZERO
var dirHit = Vector3.ZERO
var isUp = false
var Nn = Vector3(1, 0, 0)
var lastPlayer = null
var hitCount = 0
var canSave = true
enum bstate{OPEN, SHOOTING, TRAPPED, CAUGHT, CROSSING}
var state
var hitK = null
var offsideFlags = {}
var offsideExempt = false
var sa = null
var sas = null

func _ready():
	if Global.elevenMode and Global.ELEVEN_CUSTOM_PRESENTATION:
		# Closer to a real ball at the 11v11 pitch scale (still a touch big so it reads on screen).
		$MeshInstance.scale *= 0.9
	
	
	state = bstate.OPEN
	sa = $SaveArea / CollisionShape
	sas = $SaveArea / CollisionShape.shape
	
func _initialize():
	player = null
	shooter = null
	linear_velocity = Vector3.ZERO
	
	state = bstate.OPEN
	Game = Global.game
	
	
func _physics_process(delta):
	
	
	sa.global_transform.origin = global_transform.origin + linear_velocity * delta * 1.2
	sa.global_transform.origin.y = max(2.0, sa.global_transform.origin.y)
	
	if state == bstate.SHOOTING:
		
		var left = linear_velocity.normalized().cross(Vector3.UP)
		if (linear_velocity.x < 0.0):
			left = - left
		
		apply_central_impulse(((curl.z * left) + (curl.y * Vector3.UP)) * delta * 50.0)
		curl.z *= 0.98
		
		
		
	
	elif state == bstate.CROSSING:
		apply_central_impulse(curl * delta * 50.0)
		
		curl *= 0.98
		
		
	else:
		curl *= 0.995







			
		
		

		
		
















		
		
		
	if (Global.gameOn) and ( not oob):
		if (abs(translation.x) > 140.0 * Global.ps) or (abs(translation.z) > 90.0 * Global.ps):
			oobpos = translation
			var lst = player
			if not lst:
				lst = lastPlayer
			if not lst:
				lst = shooter
			oob = true
			yield(get_tree().create_timer(0.16), "timeout")
			Game._oob(lst)
	elif (Global.penShoot) and Global.penOn:
		if (abs(translation.x) > 140.0 * Global.ps) or (abs(translation.z) > 90.0 * Global.ps):
			yield(get_tree().create_timer(0.06), "timeout")
			Game._shootoutMissed()
	
func _integrate_forces(pstate):
	if state == bstate.TRAPPED:
		var diff = translation - (player.myArea.get_global_transform().origin)
		diff.y = 0
		if (diff.length() > 0.01):
			
			pstate.linear_velocity = - diff * 20 + Vector3(0, - 1, 0)
		
		
		
	elif state == bstate.CAUGHT:
		var pos = (player.myCaught.get_global_transform().origin)
		
		pos.y = max(0.0, pos.y)
		pstate.linear_velocity = Vector3.ZERO
		pstate.transform.origin = pos
		
		
			
		
	elif state == bstate.SHOOTING:
		pstate.linear_velocity *= drag
	elif passGuard and state == bstate.OPEN and Global.gameOn:
		if loftFlight:
			_carryLob(pstate)
		_brakeAtLines(pstate)
		
	pstate.transform.origin.y = max(0.0, pstate.transform.origin.y)
func _lineBrake(along, speed, line, step):
	var outward = speed * sign(along)
	var gap = line - abs(along) - LINE_STOP_GAP
	if outward <= 0.0 or gap > outward * LINE_BRAKE_LOOK:
		return speed
	if lobbed:
		var eased = max(0.0, outward - LOB_MAX_BRAKE * step)
		return eased * sign(along)
	if gap <= 0.0:
		return 0.0
	return speed * max(0.0, 1.0 - outward / (2.0 * gap) * step)

func _carryLob(pstate):
	var v = pstate.linear_velocity
	if translation.y < 1.0 and v.y < 0.0:
		loftFlight = false
		return
	var keep = exp(LOB_DRAG_CANCEL * pstate.step)
	pstate.linear_velocity = Vector3(v.x * keep, v.y, v.z * keep)

func _brakeAtLines(pstate):
	if loftFlight or (lobbed and translation.y > LOB_ROLL_HEIGHT):
		return
	var v = pstate.linear_velocity
	var before = Vector2(v.x, v.z).length()
	# Leave the goal mouth alone so a pass can still roll into an empty net.
	if abs(translation.z) > abs(Game.team1.goalL.z) + 3.0:
		v.x = _lineBrake(translation.x, v.x, 140.0 * Global.ps, pstate.step)
	v.z = _lineBrake(translation.z, v.z, 90.0 * Global.ps, pstate.step)
	var after = Vector2(v.x, v.z).length()
	if after < before:
		pstate.linear_velocity = v
		pstate.angular_velocity *= after / before

func _ballTrapped( var cplayer):
	passGuard = false
	if _callOffside(cplayer):
		return
	offsideFlags.clear()
	if (Global.gameOn):
		trail.render = false
		state = bstate.TRAPPED
		if player:
			player.AI._losePosession()
		player = cplayer
		isShot = false
		linear_velocity = player.velocity * 2.0
		
func _ballFree():
	passGuard = false
	
	
	
	state = bstate.OPEN
	player = null
	isShot = false
		
func _ballCaught( var cplayer):
	passGuard = false
	
	if not canSave:
		return false
	offsideFlags.clear()
	trail.render = false
	linear_velocity = Vector3.ZERO
		
		
	state = bstate.CAUGHT
	player = cplayer
	isShot = false
	return true
		
		
	

func _shootBall( var shootr, var direction, var curldirection):
	passGuard = false
	if state == bstate.CAUGHT or _callOffside(shootr):
		return
	_recordOffside(shootr)
	state = bstate.SHOOTING
	linear_velocity *= 0.25
	linear_velocity.y = 0.01
	lastPlayer = null
	shooter = shootr
	isShot = true
	player = null
	doHit = false
	curl = curldirection * 1.5
	if abs(curl.z) > 0.25:
		drag = Vector3(0.995, 1.0, 0.995)
	else:
		drag = Vector3.ONE
	
	trail.render = true
	apply_central_impulse(direction)
	shotV = linear_velocity
	$BallKicked.play()
	hitCount = 0
	
	
	
# maxSpeed: a higher speed cap for long through balls by good passers (0 = the normal cap).
func _passBall( var direction, var passer, var maxSpeed = 0.0):
	# Keepers pass themselves as their AI node; the rest of the game expects the player.
	if passer.get("myPlayer") != null:
		passer = passer.myPlayer
	if _callOffside(passer):
		return
	_recordOffside(passer)
	
	
	
	oob = false
	linear_velocity *= 0.1
	state = bstate.OPEN
	shooter = passer
	lastPlayer = null
	player = null
	
	var dl = direction.length()
	var dr = direction
	var ddl = max(minPassSpeed, min(dl, max(maxPassSpeed, maxSpeed)))
	
	isShot = false
	$BallPassed.play()
	apply_central_impulse(dr * (ddl / dl) + Vector3(0, 5, 0))
	passGuard = Global.elevenMode
	loftFlight = false
	lobbed = false
	
	
func _crossBall( var direction, var passer, var curld, var islow):
	passGuard = false
	if _callOffside(passer):
		return
	_recordOffside(passer)
	
	linear_velocity *= 0.25
	var d = direction
	
	shooter = passer
	lastPlayer = null
	player = null
	curl = curld
	
	var dl = direction.length()
	d = d / dl
	dl *= 1.1
	
	
	state = bstate.CROSSING
	$BallPassed.play()
	var high = 30
	if islow:
		high = 10
		dl *= 1.1
	isShot = false
	
	if Global.elevenMode:
		linear_velocity = Vector3.ZERO
		curl = curld * CROSS_CURL
		apply_central_impulse(_crossVelocity(direction, islow))
	else:
		var lift = high
		# Open-play crosses carry past their aim in this game; some sides play them shorter.
		var side = passer.get("myTeam") if passer != null else null
		if side != null and side.tdata.get("crossPace") != null and side.tdata.crossPace < 1.0:
			if not (abs(translation.x) > 130.0 * Global.ps and abs(translation.z) > 75.0 * Global.ps):
				dl *= side.tdata.crossPace
		# Corners come in a little slower and flatter, so there is more time to react and they still arrive at head height.
		if abs(translation.x) > 130.0 * Global.ps and abs(translation.z) > 75.0 * Global.ps:
			dl *= CORNER_PACE
		apply_central_impulse(d * dl + Vector3(0, lift, 0))


func _tapBall( var direction, var passer):
	passGuard = false
	if _callOffside(passer):
		return
	_recordOffside(passer)
	
	
	oob = false
	linear_velocity *= 0.4
	state = bstate.OPEN
	
	
	shooter = passer
	lastPlayer = null
	if player:
		player.AI._losePosession()
	$BallPassed.play()
	player = null
	isShot = false
	
	apply_central_impulse(direction)
	
func _loftBall( var flight, var passer):
	if _callOffside(passer):
		return
	_recordOffside(passer)
	oob = false
	linear_velocity = Vector3.ZERO
	state = bstate.OPEN
	shooter = passer
	lastPlayer = null
	player = null
	isShot = false
	$BallPassed.play()
	apply_central_impulse(flight)
	passGuard = Global.elevenMode
	loftFlight = Global.elevenMode
	lobbed = Global.elevenMode

func _reset():
	
	visible = true
func _replay():
	visible = false

func resetSave():
	canSave = true
func _reflectSaved( var N, var ddir, var iUp: bool):
	if state == bstate.CAUGHT:
		canSave = true
		return
	
	if canSave:
		canSave = false
		
	
	
	
		var face = sign(N.x)
		
		var bv = Vector3(rand_range(face * 0.95, face * 1.15), rand_range(0, 0.5), sign(ddir) * rand_range(1.2, 1.8))
		
		if (iUp) and translation.y > 7.5 and not (Global.isPenalties):
			bv.y = rand_range(1.1, 1.6)
			bv.x = - face
			
		linear_velocity = Vector3.ZERO
		apply_central_impulse(bv * rand_range(25.0, 30.0))
		Game._hitP()
		trail.render = false
		state = bstate.OPEN
		isShot = false
		
		if player:
			player.AI._losePosession()
			player = null

		$BallBounce.play()
		
		yield(get_tree().create_timer(0.2), "timeout")
		canSave = true
		
func _canSave():
	return canSave and (Global.gameOn or Global.penOn)
func _isOpen():
	return state == bstate.OPEN
func _isFree():
	return state == bstate.OPEN or state == bstate.CROSSING or state == bstate.SHOOTING
func _isTrapped():
	return state == bstate.TRAPPED
func _isShooting():
	return state == bstate.SHOOTING or isShot
func _isCaught():
	return state == bstate.CAUGHT
func _isCrossing():
	return state == bstate.CROSSING
func _canHead():
	return state == bstate.OPEN or state == bstate.CROSSING
	
func _on_Ball_body_entered(body):
	# A deflection off anyone but the passer is a new ball: it can go out like any other.
	if passGuard and body.get_collision_layer_bit(7) and body.get_parent() != shooter:
		passGuard = false
	if (state == bstate.SHOOTING):
		
		
		
		
		hitCount += 1
		curl *= 0.2
		if body.get_collision_layer_bit(7):
			
			
			if linear_velocity.normalized().dot(shotV.normalized()) < 0.1:
				trail.render = false
				$BallBounce.play()
				
				state = bstate.OPEN
				
				
				
				Game._hitP()
			
			lastPlayer = body.get_parent()
		elif body.get_collision_layer_bit(22):
			$PostSounds.play()
			trail.render = false
			
			state = bstate.OPEN
			Game._catch()
			Game._hitP()
			
		elif not (body.get_collision_layer_bit(14)) or hitCount > 1:
			trail.render = false
			$BallBounce.play()
			
			state = bstate.OPEN
			Game._hitP()
	elif (state == bstate.CROSSING):
		
		
		if body.get_collision_layer_bit(7):
			lastPlayer = body.get_parent()
			
				
			linear_velocity *= 0.85
		state = bstate.OPEN
		Game._hitP()
	elif (state == bstate.OPEN) and body.get_collision_layer_bit(7):
		lastPlayer = body.get_parent()
		
		lastPlayer._ballHit()
		
		linear_velocity *= 0.75
		
		apply_central_impulse(Vector3(0, - 5, 0))
			
		
		Game._hitP()


func _on_Ball_input_event(_camera, _event, _click_position, _click_normal, _shape_idx):
	pass

# --- 11v11 offside --------------------------------------------------------------------
# Offside is judged the moment the ball is played and called if a flagged player touches it.
# Corners, throw-ins and goal kicks set offsideExempt so their first kick cannot be offside.
func _recordOffside(kicker):
	offsideFlags.clear()
	if kicker == null or kicker.get("myTeam") == null:
		return
	if offsideExempt:
		offsideExempt = false
		return
	offsideFlags = kicker.myTeam._offsidePlayers(kicker)

func _callOffside(toucher):
	if not (Global.gameOn and offsideFlags.has(toucher)):
		return false
	offsideFlags.clear()
	toucher.myTeam._offsideCalled(toucher)
	return true

# --- 11v11 lofted balls ---------------------------------------------------------------
# Launch velocity that lands the ball at a horizontal offset after the given hang time.
# Air damping measured on the real ball is cancelled by a higher launch speed.
const CORNER_PACE = 0.9
const LOFT_DAMP = 0.39
const CROSS_CURL = 0.4
const LOW_CROSS_MIN = 90.0
const LOW_CROSS_MAX = 112.0

func _lobVelocity(offset, hang):
	var airborne = hang * LOB_LANDS_AT
	var damped = LOB_AIR_DAMP * airborne
	var flight = Vector3(offset.x, 0.0, offset.z) / airborne * (damped / (1.0 - exp( - damped)))
	flight.y = 0.5 * 20.0 * gravity_scale * hang
	return flight

func _loftVelocity(offset, hang):
	var damped = LOFT_DAMP * hang
	var flight = Vector3(offset.x, 0.0, offset.z) / hang * (damped / (1.0 - exp( - damped)))
	flight.y = 0.5 * 20.0 * gravity_scale * hang
	return flight

func _crossVelocity(direction, islow):
	var flat = Vector3(direction.x, 0.0, direction.z)
	# A little quicker than a lob over the same distance.
	var hang = clamp(0.95 + flat.length() / 95.0, 1.4, 2.9)
	if islow:
		# Driven along the ground: quicker than a through ball, well below shot pace.
		return flat.normalized() * clamp(flat.length() * 1.2, LOW_CROSS_MIN, LOW_CROSS_MAX) + Vector3(0, 6.0, 0)
	return _loftVelocity(flat, hang)
