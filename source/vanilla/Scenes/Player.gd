
extends KinematicBody

var pSpeed = 30
var pOSpeed = 30
var pDSpeed = 29
var pAgility = 5
var pAggression = 0.7
var pSmart = 10
var dSmart = 0.16
var pTSmart = 10
var pShoot = 0.75
var pCurl = 0.75
var pAcc = 3
var pBurst = 42
var dBurst = 42
var tSpeed = null
var marked = false
var myMesh = null
var myPM = null

var velocity
var acc
var aiacc
var dvel
var myHeadFix = Vector3( - 2.3, 2.3, - 2.3)
var isAI = true
var canControl = true
var canHead = false

var shooting = false
var tackled = false
var target = null
var view = null
var lastview = null
var lastlean = 0.0
var shotdir = Vector3.ZERO
var shotcharge = 0
var lowshot = false
var shotTimer
var shotcurl = Vector3.ZERO

var ball = null
var myTeam = null
var myGoal
var myGoalL
var myGoalR
var dGoal
var AI = null
var myArea = null
var myBody = null
var myRoot = null
var myATree = null
var myCaught = null
var myHead = null
onready var myHeadArea = $HeadArea / CollisionShape
onready var myTrapArea = $TrapArea
onready var myCollider = $CollisionShape
var myP = null
var myAState
var TA = null
var myID = 1
var aiFrame
var replay = false
var myfx = null
var myC = 0
var assist = false
var acomp = 0.0
var inertia = 0.94

signal posession(id)
var phys = null
var physhit = null

var cshoot = "p1_shoot"
var cpass = "p1_pass"
var cchip = "p1_chip"
var cthru = "p1_thru"
var cswitch = "p1_switch"
var cburst = "p1_burst"
var clow = "p1_low"
var cud = 1
var clr = 0
var jflip = 1


var spm = null
var sp = null

var posI = null
onready var indicator = $Indicator

var dbt = null
var tdl = null
var tdl2 = null
var headoffset = Vector3(0.0, 1.5, - 1.25)

var tackledBall = false

var foulCount = 0
var carded = 0
var yellowI = null
var playersay = null

func _ready():
	AI = $AI
	velocity = Vector3(0, 0, 0)
	acc = Vector3(0, 0, 0)
	aiacc = Vector3(0, 0, 0)
	dvel = Vector3(0, 0, 0)
	target = Vector3(0, 0, 0)
	view = Vector3(0, 0, 5)
	lastview = Vector3(0, 0, 5)
	
	
	TA = $DangerZone
	shotTimer = $ShotTimer
	
	var pm = null
	if Global.setupWomens:
		pm = load("res://Scenes/femplayer.tscn").instance()
	else:
		pm = load("res://Scenes/newPlay.tscn").instance()
	
	pm.name = "PlayerMesh"
	pm.translation.y = 0.15
	pm.rotation_degrees.y = - 180
	add_child(pm)
	myPM = pm
	myRoot = get_parent()
	
	
	
	myArea = $BallPos
	myBody = $PlayerMesh / AnimationPlayer
	myATree = $PlayerMesh / AnimationTree
	myAState = $PlayerMesh / AnimationTree.get("parameters/StateMachine/playback")
	
	
	
	aiFrame = myID
	myfx = $SlideFX / SP2
	myCaught = $PlayerMesh / QuickRigCharacter_Reference / BoneAttachmentThrow / CaughtPos
	myHead = $PlayerMesh / QuickRigCharacter_Reference / HeadAttach
	myMesh = $PlayerMesh / QuickRigCharacter_Reference / PlayerM
	dbt = get_parent().find_node("DebugTarget")
	
	
	tSpeed = $TweenSpeed
	
	if Global.moveAssist > 0:
		assist = true
		acomp = 1.0 - Global.moveAssist
	phys = $PlayerMesh / QuickRigCharacter_Reference
	physhit = $PlayerMesh / QuickRigCharacter_Reference / PhysicalHips
	playersay = $PlayerSay
	AI.rayc = $RayCast
	
	spm = $ShotPower.get_active_material(0)
	sp = $ShotPower
	
	
	
	set_process(false)
func _initP2Controls():
	cshoot = "p2_shoot"
	cpass = "p2_pass"
	cchip = "p2_chip"
	cthru = "p2_thru"
	cswitch = "p2_switch"
	cburst = "p2_burst"

func chipPass2( var dir):
	var h = 0.1 + smoothstep(0, 100, dir.length())
			
	ball._passBall((dir + Vector3(0, h * 34.0, 0)) * 0.8, self)
	
	
	myTeam._cross(self)
	myTeam.posession = false
	AI._losePosession()
func passBall( var dir):
	ball._passBall(dir, self)
	
	myTeam._cross(self)
	myTeam.posession = false
	AI._losePosession()

func _clearBall():
	ball._passBall(Vector3(myTeam.playDir * 3.0, 1.0, rand_range( - 0.5, 0.5)) * 5.0, self)
	
	myTeam.posession = false
	AI._losePosession()
	
func chipPass( var human):
	
	
	
	if myTeam.zone == 3:
			
			canControl = false
			var crossto = (myGoal * rand_range(0.7, 0.8))
			
			var swing = - 1
			var sw = 0
			if myTeam.AIteam:
				sw = sign(velocity.x) * myTeam.playDir
				if rand_range(0, 1) > 0.8:
					lowshot = true
			else:
				sw = sign(Input.get_joy_axis(myC, clr)) * myTeam.playDir
				if Global.touchPad.isActive():
					var mov = Global.touchPad.get_force()
					sw = sign(mov.y * jflip)
				elif Input.is_action_pressed("p1_right"):
					sw = myTeam.playDir
				elif Input.is_action_pressed("p1_left"):
					sw = myTeam.playDir * - 1.0
			
			if AI.state == AI.pstate.POSESSION:
				swing = sw
				if sw < 0:
					
					crossto.x *= 0.95
				else:
					crossto.x *= 1.0
			else:
				if sw < 0:
					
					crossto.x *= 1.05
					swing = 1.1
				else:
					swing = - 1.1
					crossto.x *= 0.95
			
			var curl = Vector3( - myTeam.playDir * swing, - 0.2, 0) * pCurl
			var cp = myTeam._closestPToP(crossto)
			
			
			
			crossto -= translation
			ball._crossBall(crossto, self, curl, lowshot)
			lowshot = false
			myTeam.posession = false
			AI._losePosession()
			myTeam.Game._cross()
			if not myTeam.AIteam and cp:
				myTeam._switchPControl(cp)
			
			yield(get_tree().create_timer(0.1), "timeout")
			canControl = true
		
			
			
			
				
			
			return true
	else:
		var passV = myTeam._findLongPass(translation, - transform.basis.z, myID)
		if (passV):
			
			var h = 0.4 + smoothstep(0, 100, myTeam.passDir.length())
			
			ball._passBall((myTeam.passDir + Vector3(0, h * 30.0, 0)) * 0.8, self)
			
			myTeam.momentum = true
			myTeam.opponent.momentum = false
			
			myTeam.posession = false
			AI._losePosession()
			
			return true
			
		elif human:
			var cdir = myGoal - translation
			ball._passBall(cdir * Vector3(1.3, 22.5, 1.4), self)
			myTeam.momentum = true
			myTeam.opponent.momentum = false
			
			myTeam.posession = false
			AI._losePosession()
			return true
	
	return false
func shoot( var targ):
	
	
	
	if not ball._canSave():
		return
	var bods = $TrapArea.get_overlapping_bodies()
	
	var canshoot = false
	for b in bods:
		if b == ball:
			canshoot = true
			break
	if not canshoot:
		return
		
	var shotV = targ - ball.translation
	
	
	myTeam.posession = false
	
	
	var coffset = smoothstep(0.0, 130.0, abs(Global.ballpos.x))
	shotV.z += - shotcurl.z * lerp(30.0, 2.0, coffset) * pCurl
	shotV = shotV.normalized()
	shotcurl.z *= 1.1
	var yadd = range_lerp(pShoot, 0.0, 1.0, 0.38, 0.075)
	if lowshot:
		yadd *= lerp(0.5, 0.01, pShoot)
		shotcurl.y *= 0.05
	shotV += Vector3(0, yadd * (1.0 - shotcharge), 0)
	
	shotV.z += rand_range( - 0.2, 0.2) * (1.0 - pShoot)
	
	if (shotcurl.y > 0):
		shotV.y += 0.05
		shotcurl.y = shotcurl.y * - 2.1
		shotcharge *= 1.1
	shotV = shotV * lerp(100, lerp(130, 165, pShoot), 1.0 - shotcharge)
	
	
	canControl = false
	ball._shootBall(self, shotV, shotcurl)
	
	lowshot = false
	myTeam._shot(myID, shotV, shotcurl, 0)
	yield(get_tree().create_timer(0.1), "timeout")
	canControl = true
	
		
func setPieceShoot( var targ):
	
	var shotV = targ
	
	myTeam.posession = false
	shotV = shotV.normalized()
	shotV += Vector3(0, 0.1 * (1.0 - shotcharge), 0)
	shotV = shotV * lerp(120, 150, 1.0 - shotcharge)
	
	ball._shootBall(self, shotV, shotcurl)
	myTeam._pshot(myID, shotV, shotcurl * 2.0, 2, AI.isFK)
	yield(get_tree().create_timer(0.1), "timeout")
	
	AI.isFK = false
	myTeam._goGame()
	
	
func volleyShoot( var ai):
	if ball.state == ball.bstate.SHOOTING:
		return
		
	var aim = Input.get_joy_axis(myC, cud) * jflip
	if Global.touchPad.isActive():
			var mov = Global.touchPad.get_force()
			aim = mov.y * jflip * - 1.0
	
	if (ai):
		aim = rand_range( - 0.7, 0.7)
	shooting = false
	
	aim = smoothstep( - 1, 1, aim)
	shotdir = myGoal
	if (Input.is_action_pressed("p1_up")):
		aim = 0.2
	elif (Input.is_action_pressed("p1_down")):
		aim = 0.8
	shotdir = lerp(myGoalL, myGoalR, aim)
	shotdir = shotdir - Global.ballpos
	
	shotcharge = rand_range(0.1, 0.5)
	AI._volley()
	
	myTeam.posession = false
	shotcurl = Vector3(0, rand_range( - 0.7, - 0.5), 0) * pCurl
	shotdir = shotdir.normalized()
	var mul = 1.0
	if lowshot:
		mul = lerp(0.7, 0.01, pShoot)
	shotdir += Vector3(0, 0.6 * (1.0 - shotcharge) * (1.0 - pShoot) * mul, 0)
	
	shotdir = shotdir * lerp(100, 170, 1.0 - shotcharge)
	ball._shootBall(self, shotdir, shotcurl)
	myTeam._shot(myID, shotdir, shotcurl, 1)
	
		
func checkInput():
	var mov = Vector2.ZERO
	if not canControl:
		return
	
	
	
	
	var ismov = AI._moving()
	if (ismov):
		mov.x = Input.get_joy_axis(myC, clr)
		mov.y = Input.get_joy_axis(myC, cud) * jflip
		if Global.touchPad.isActive():
			mov += Global.touchPad.get_force()
			mov.y *= jflip * - 1.0
		if (abs(mov.x) < 0.2):
			mov.x = 0
		if (abs(mov.y) < 0.2):
			mov.y = 0
		if (Input.is_action_pressed("p1_left")):
			mov.x = - 1
		elif (Input.is_action_pressed("p1_right")):
			mov.x = 1
		if (Input.is_action_pressed("p1_up")):
			mov.y = - 1
		elif (Input.is_action_pressed("p1_down")):
			mov.y = 1
		
		
		if mov.length_squared() > 1:
			mov = mov.normalized()
			
		if (abs(mov.x) > 0 or abs(mov.y) > 0) and Global.gameOn and assist:
		
			if not myTeam.posession:
				var db = (Global.ballpos + Global.ballvel * 0.16) - translation
				db = db.normalized()
				var df = db.dot(Vector3(mov.x, 0.0, mov.y))
				
				if df > acomp:
					mov = Vector2(db.x, db.z)
		
		
		
	if (Input.is_action_just_pressed(cshoot)):
		if (AI._hasBall()):
			
			spm.set_shader_param("progress", 0.0)
			sp.visible = true
			shotcharge = - 1.0
			shooting = true
			
			shotTimer.start(0.3)
			AI._shoot()
			AI.isFK = false
			
			
			var shotV = myGoal
			var aim = Input.get_joy_axis(myC, cud) * jflip
			if Global.touchPad.isActive():
				var m = Global.touchPad.get_force()
				aim += m.y * jflip * - 1.0
			if (Input.is_action_pressed("p1_up")):
				aim += - 1
			elif (Input.is_action_pressed("p1_down")):
				aim += 1
			
			aim *= myTeam.playDir
			shotV = lerp(myGoalL, myGoalR, smoothstep( - 1.0, 1.0, aim))
			
			
			
			
			
			shotdir = shotV
			
	elif (Input.is_action_pressed(cshoot)):
		if not shooting and (AI.state != AI.pstate.SHOOT) and not AI._hasBall() and not ball._isShooting():
			shooting = false
			AI.isFK = false
			
			var db = (translation - Global.ballpos).length_squared()
			
			var bp = Global.ballpos + (Global.ballvel * 0.1)
			if bp.y > 8.0:
				if db < 300.0:
					AI._header(true)
				else:
					AI._divingHeader(true)
			elif bp.y > 4.0 and db > 25.0:
				
				AI._divingHeader(true)
					
			elif db < 16.0:
				
				lowshot = Input.is_action_pressed(clow)
				volleyShoot(false)
			
		elif shooting:
			shotcharge += 0.048
			spm.set_shader_param("progress", shotcharge + 1.0)
	elif (Input.is_action_just_released(cshoot)):
		
		lowshot = Input.is_action_pressed(clow)
		AI.isFK = false
		
		if shooting:
			sp.visible = false
			shotcharge = shotTimer.time_left * 2.0
			
			shotTimer.stop()
			
			
			var m = Vector2(Input.get_joy_axis(myC, clr), Input.get_joy_axis(myC, cud))
			if Global.touchPad.isActive():
				m += Global.touchPad.get_force()
				m.y *= jflip * - 1.0
			if (Input.is_action_pressed("p1_up")):
				m.y += - 0.9
			elif (Input.is_action_pressed("p1_down")):
				m.y += 0.9
		
			shotcurl.y = range_lerp(m.x, - 1, 1, 1, - 1) * pCurl
			shotcurl.z = - m.y * 3.25 * pCurl * jflip
			
			
			shotcurl.y *= myTeam.playDir
			shooting = false
			
		
	elif (Input.is_action_just_pressed(cchip)):
		if (AI._hasBall()):
			shooting = false
			lowshot = Input.is_action_pressed(clow)
			chipPass(true)
		elif ismov and Global.gameOn:
			isAI = true
			shooting = false
			AI._updateData(translation, velocity)
			if mov.length_squared() < 0.1:
				mov = - transform.basis.z
			AI._slide(true, mov)
	elif (Input.is_action_just_pressed(cpass)):
		if (AI._hasBall()):
			shooting = false
			
			var passD = Vector3.ZERO
			if (Input.is_action_pressed("p1_left")):
				passD.x = - 1
			elif (Input.is_action_pressed("p1_right")):
				passD.x = 1
			if (Input.is_action_pressed("p1_up")):
				passD.z = - 1
			elif (Input.is_action_pressed("p1_down")):
				passD.z = 1
			passD.x += Input.get_joy_axis(myC, clr)
			passD.z += Input.get_joy_axis(myC, cud) * jflip
			if Global.touchPad.isActive():
				var m = Global.touchPad.get_force()
				passD.x += m.x
				passD.z += m.y * jflip * - 1.0
			
			myTeam.posession = false
			var passV = myTeam._findPass(translation, passD, myID)
			if (passV):
				
				
				
				
				ball._passBall(myTeam.passDir * 1.5, self)
			else:
				
				ball._passBall(velocity, self)
			
			AI._losePosession()
				
	elif (Input.is_action_pressed(cpass)):
		if ( not AI._hasBall()):
			var vm = ball.translation - translation
			mov.x = vm.x
			mov.y = vm.z
			mov = mov.normalized()
			
	elif (Input.is_action_just_pressed(cswitch)):
		var cp = myTeam._closestSPToBall()
		myTeam._switchPControl(cp)
		
	elif (Input.is_action_just_pressed(cburst)):
		if pSpeed <= pOSpeed:
			_burst()
			inertia = 0.999
			myfx.emitting = Global.doParticles
			
	elif Input.is_action_just_pressed(cthru):
		
		if AI._hasBall():
			var passD = Vector3(0, 0, 0)
			passD.x += Input.get_joy_axis(myC, clr)
			passD.z += Input.get_joy_axis(myC, cud) * jflip
			if Global.touchPad.isActive():
				var m = Global.touchPad.get_force()
				passD.x += m.x
				passD.z += m.y * jflip * - 1.0
			if (Input.is_action_pressed("p1_left")):
				passD.x = - 1
			elif (Input.is_action_pressed("p1_right")):
				passD.x = 1
			if (Input.is_action_pressed("p1_up")):
				passD.z = - 1
			elif (Input.is_action_pressed("p1_down")):
				passD.z = 1
			lowshot = Input.is_action_pressed(clow)
			AI._thruPass(passD)
		elif (Global.ballpos.y > 2):
				AI._bicycleKick(true)
	if ismov:
		acc.x += mov.x * pAgility
		acc.z += mov.y * pAgility
		
	if AI._celebrating():
		if Input.is_action_just_pressed(cshoot):
			AI._celebrateAnim(0)
		elif Input.is_action_just_pressed(cpass):
			AI._celebrateAnim(1)
		elif Input.is_action_just_pressed(cchip):
			AI._celebrateAnim(2)
		elif Input.is_action_just_pressed(cthru):
			AI._celebrateAnim(3)

func _controlMe():
	
	if (myTeam.AIteam):
		return
	canControl = false
	isAI = false
	indicator.visible = true
	
func _loseControl():
	isAI = true
	indicator.visible = false
	

func _burst():
	var fromspeed = dBurst
	var tospeed = pOSpeed
	if AI._hasBall():
		fromspeed = pDSpeed + (dBurst - pOSpeed)
		tospeed = pDSpeed
		dBurst -= 1.0
	tSpeed.interpolate_property(self, "pSpeed", fromspeed, tospeed, 0.6, Tween.TRANS_QUAD, Tween.EASE_IN)
	tSpeed.start()
	

func _process(delta):
	
	
	var rspeed = 1.0
	if not replay:
		
		aiFrame += 60.0 * delta
		if aiFrame > pSmart:
			aiFrame = 0.0
		
		
		if (isAI):
			if aiFrame < 1.0:
		
				
				AI._updateData(translation, velocity)
				AI._update()
				
			else:
				
				
				
				AI._updateData(translation, velocity)
				AI._updateVel()
				
		else:
			
			checkInput()
			canControl = true
		
		var ismov = AI._moving()
		if ismov:
			
			velocity += 60.0 * delta * acc * (lerp(0.35, 1.0, pAcc))
			velocity.y = 0
			
			
			velocity = velocity.limit_length(pSpeed)
			var vl = velocity.length()
			
			
			
			
			
			if isAI and AI.state == AI.pstate.IDLE:
				var close = (target - translation).length()
				if close < 2.0:
					velocity *= 0.75 + 0.125 * close
					vl *= 0.75 + 0.125 * close
				
			if (vl > 1.5):
				
				
				view = lastview.normalized().slerp(velocity / vl, 0.33) * vl
				
				
				
				lastview = view
			else:
				view = lastview
				
				
			lastview.y = 0.5
			if vl > 1.5:
				rspeed = (vl / pOSpeed) * 1.33
				if vl > 18:
					
					
					if pSpeed > pOSpeed:
						myAState.travel("sprinthard")
						AI.astate = "sprinthard"
						myATree["parameters/StateMachine/sprinthard/sprintspeed/scale"] = rspeed
						myfx.emitting = vl > pOSpeed and Global.doParticles
					
					else:
						myAState.travel("sprint")
						AI.astate = "sprint"
						myATree["parameters/StateMachine/sprint/RunSpeed/scale"] = rspeed
						
						myfx.emitting = false
		
				else:
					myAState.travel("walk")
					AI.astate = "walk"
					
					
			else:
				if not Global.gameOn and rand_range(0.0, 1.0) > 0.995:
					var r = rand_range(0.0, 1.0)
					if r < 0.33:
						myAState.travel("newidleclap")
					elif r < 0.66:
						myAState.travel("idlepoint")
					else:
						myAState.travel("idlepointR")
					AI.astate = "newidleclap"
				else:
					myAState.travel("idle")
					AI.astate = "idle"
				if not AI._hasBall():
					if not AI._isThrow():
						
						view = (Global.ballpos - translation)
						view = lastview.normalized().slerp(view.normalized(), 0.33) * 5.0
				
						lastview = view
					else:
						if myTeam.throwTarget:
							view = myTeam.throwTarget.translation - translation
						else:
							view = myGoal - translation
						
						lastview = view
					
				myfx.emitting = false
				pSpeed = pOSpeed
				
			acc *= 0.2
		else:
			
			velocity = AI.slidevel
			
			AI.slidevel *= pow(0.99, (delta / 0.01666667))
			if velocity.length_squared() > 1:
				view = AI.slidevel
				lastview = view
			else:
				view = lastview
			pSpeed = pOSpeed
			myfx.emitting = false
			
			if AI.state == AI.pstate.CONCEDED:
				view = - transform.basis.z
				lastview = view
		
			









		
		
		
		
		
		if AI._hasBall():
			if pSpeed > pDSpeed:
				pSpeed -= 0.2
		elif pSpeed < pOSpeed:
			pSpeed += 0.2
			
		
		if pSpeed <= pOSpeed:
			myfx.emitting = false
				
		if inertia > 0.94:
			inertia *= 0.999
		elif inertia < 0.94:
				inertia = 0.94
	
	if dBurst < pBurst:
		dBurst += 0.25 * delta
	myRoot.process(delta)
func _physics_process(delta):
		
	if not replay:
		
		
		var up = Vector3.UP
		if (acc.length_squared() > 0.05) and AI._moving():
			var lean = acc.normalized().dot(transform.basis.x)
			up += ((lastlean + lean) * 0.5) * transform.basis.x * 0.4 * smoothstep(5.0, 36.0, velocity.length_squared())
			lastlean = (lastlean + lean) * 0.5
		else:
			lastlean *= 0.5
			
		view.y = 0.0
		
		myHeadArea.translation = myHead.translation * myHeadFix + headoffset
		velocity = move_and_slide(velocity, up, false, 4)
		
		var newt = transform.looking_at(translation + view * 5.0, up.normalized())
		transform = transform.interpolate_with(newt, delta * 18)
		translation.y = - 0.2
		velocity *= inertia
		posI.translation = translation
		posI.translation.y = 0.1
		
	else:
		
		
		translation = myRoot._getPos()
		var vel = myRoot._getVel() * 60.0 * delta
		view = myRoot._getLook()
		acc = myRoot._getAcc()
		var up = Vector3.UP
		if (acc.length_squared() > 1):
			up += acc.normalized() * 0.3 * (pSpeed / pDSpeed)
		view.y = 0.05
		var newt = transform.looking_at(translation + view * 5, up.normalized())
		transform = transform.interpolate_with(newt, delta * 10)
		
		var astate = myRoot._getState()
		if myAState.get_current_node() != astate:
			if astate == "concede":
				myAState.set("parameters/StateMachine/concede/concedeSeek/seek_position", rand_range(0.0, 3.0))
			myAState.stop()
			myAState.travel(astate)
			
		var vl = vel.length() / pSpeed
		
		myATree["parameters/StateMachine/sprint/RunSpeed/scale"] = vl * 1.33
		myATree["parameters/StateMachine/sprinthard/sprintspeed/scale"] = vl * 1.33
		if myTeam.wescored:
					
		
			if Global.sfBeforeGf:
				if myTeam.Game.frame > myTeam.Game.startframe and myTeam.Game.frame < Global.goalframe:
					myATree["parameters/BlendCelebrate/blend_amount"] = 0
				else:
					myATree["parameters/BlendCelebrate/blend_amount"] = 1
			else:
				if myTeam.Game.frame < myTeam.Game.startframe and myTeam.Game.frame > Global.goalframe:
					myATree["parameters/BlendCelebrate/blend_amount"] = 1
				else:
					myATree["parameters/BlendCelebrate/blend_amount"] = 0
func _on_TrapArea_body_entered(_body):
	if not (Global.gameOn) or (ball._isCaught()) or not canControl or not AI._canControl() or AI._hasBall():
		return
	if Global.ballvel.length_squared() > 20000:
	
		return
	if (_body == ball):
		if AI.state == AI.pstate.KICKER or AI.prevstate == AI.pstate.KICKER:
			
			return
		elif ball._canHead():
			if myTeam._ballInBox():
				if myTeam.zone == 3:
			
					if not AI._firstTimeShot():
						ball._ballTrapped(self)
						AI._posession()
						emit_signal("posession", myID)
				elif myTeam.zone == 1 and ball._isCrossing():
					if not AI._firstTimeClearance():
						ball._ballTrapped(self)
						AI._posession()
						emit_signal("posession", myID)
				else:
						ball._ballTrapped(self)
						AI._posession()
						emit_signal("posession", myID)
				
			else:
				ball._ballTrapped(self)
				AI._posession()
				emit_signal("posession", myID)
		elif ball._isTrapped() and myTeam.opponent.posession:
			
			var r = rand_range(0.0, 9.0)
			if r > ball.player.pAgility:
				ball._tapBall((Vector3(0, 0.5, 0) + ( - transform.basis.z + rand_range( - 0.5, 0.5) * transform.basis.x)) * 30, self)
			
			
				myTeam.opponent._lostPosession(myTeam.opponent.zone > 2)
			
				canControl = false
			
			
			
			
				tackledBall = true
				yield(get_tree().create_timer(0.1), "timeout")
				canControl = true
	else:
		
		
		if AI.state == AI.pstate.SLIDE:
			var bods = myTrapArea.get_overlapping_bodies()
			var fouled = false
			if not tackledBall:
				for b in bods:
					if b == ball:
						fouled = false
						break
					if b.get_parent().myTeam.teamID != myTeam.teamID and not ball._isShooting():
						fouled = true
						b.get_parent().AI._fouled()
			
				
			
			if not (fouled):
				for b in bods:
					if b != ball:
						if b != myCollider and b.get_parent().AI._hasBall():
							b.get_parent().AI._tackled()
							
				
				
			else:
				myTeam._foul(translation, self)


func _on_HeadArea_body_entered(_body):
	if (_body != ball) or ( not Global.gameOn) or not ball._isFree() or not canHead:
		return
	if (AI.state == AI.pstate.HEAD) or (AI.state == AI.pstate.DIVINGH):
		if (myTeam.zone == 3):
			var shotV = myGoal
			var aim = 0.0
			if not isAI:
				
				aim = Input.get_joy_axis(myC, cud) * jflip
				if Global.touchPad.isActive():
					var mov = Global.touchPad.get_force()
					aim += mov.y * jflip * - 1.0
				aim *= myTeam.playDir
			else:
				aim = rand_range( - 1.0, 1.0)
			
			
			
			
			shotV = lerp(myGoalL, myGoalR, smoothstep( - 1, 1, aim))
			shotV = shotV - translation
			
			var headdir = (shotV.normalized() + Vector3(0, lerp( - 0.1, - 0.425, pShoot), 0)) * 83.5
			ball._shootBall(self, headdir, Vector3(0, 0, 0))
			var stype = 3
			if AI.state == AI.pstate.DIVINGH:
				stype = 4
			myTeam._shot(myID, headdir, Vector3.ZERO, stype)
			myTeam.posession = false
	
		else:
			
			var todir = (myGoal - translation).normalized()
			
			
			ball._tapBall(todir * 50.0 + Vector3(0, 25, 0), self)
			myTeam.momentum = (myTeam.zone > 2)
			myTeam.opponent.momentum = (myTeam.opponent.zone > 2)
		



		
	
	
	
	
	
	
func _ballHit():
	myTeam._ballHit()
	myTeam.opponent._ballHit()
func _say( var saying):
	if not Global.doSayings:
		return
		
	var s = Global.ll.fouls
	match saying:
		1:
			s = Global.ll.fouled
		2:
			s = Global.ll.recovered
		3:
			s = Global.ll.remorse
	playersay.text = s[int(rand_range(0, 6))]
	playersay.visible = true
func _shush():
	playersay.visible = false
	

func _doNewShot():
	
	if AI.isSP:
		
		
		setPieceShoot(shotdir)
		AI.isSP = false
		return
	
	elif shooting:
		shooting = false
		
		var m = Vector2(Input.get_joy_axis(myC, clr), Input.get_joy_axis(myC, cud))
		if Global.touchPad.isActive():
			m += Global.touchPad.get_force()
			m.y *= - 0.5
		if (Input.is_action_pressed("p1_left")):
			m.x += - 0.5
		elif (Input.is_action_pressed("p1_right")):
			m.x += 0.5
		if (Input.is_action_pressed("p1_up")):
			m.y += - 0.5
		elif (Input.is_action_pressed("p1_down")):
			m.y += 0.5
		shotcurl.y = range_lerp(m.x, - 1, 1, 1, - 1) * pCurl
	
		shotcurl.y *= myTeam.playDir
		shotcurl.z = - m.y * 3.25 * pCurl * jflip
		if shotcharge < 0.0:
			shotcharge = shotTimer.time_left * 2.0
	posI.visible = false
	sp.visible = false
	
	if Global.gameOn or Global.penOn:
		shoot(shotdir)

