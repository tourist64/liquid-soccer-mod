
extends KinematicBody


var pSpeed
var pDSpeed
var pOSpeed
var pAgility = 5
var pAggression = 22
var pDAggression = 22
var pAgg = 0.5
var pSmart = 10
var dSmart = 1.0
var pTSmart = 10

var pShoot = 1
var pCurl = 0

var pDiveAgile = 1.5
var pAcc
var pDiveSpeed = 30
const DIVE_STOP_PAST = 0.6
const DIVE_POST_EXTRA = 1.5
const ELITE_REACH = 6.5
var pBurst = 12
var dBurst = 12
var carded = 0

var acc
var aiacc
var velocity
var heading
var isAI = true

var target = null
var view = null
var lastview = null
var tackled = false
var shooting = false

var ball = null
var myTeam = null
var dGoal
var myGoal
var myGoalL
var myGoalR
var myArea = null
var myCaught = null
var myBody = null
var myRoot = null
var myMesh = null
var myPM = null
var aiFrame = 0
var myID = 0
var myATree = null
var myAState = null
var AI
var replay = false
var canControl = true
var canSave = true
var myC = 0
var gravity = Vector3(0, - 200, 0)

var collbone = null
var handbone = null

var cb = null
var cp = null
var sa = null

var catchDistance = 10000


var laststate = ""
var rflip = 1


signal posession(id)


var cshoot = "p1_shoot"
var cpass = "p1_pass"
var cchip = "p1_chip"
var cthru = "p1_thru"
var cswitch = "p1_switch"
var cburst = "p1_burst"

var cud = 1
var clr = 0
var jflip = 1


var mv = null
var mvt = null

func _ready():
	velocity = Vector3(0, 0, 0)
	heading = Vector3(1, 0, 0)
	target = Vector3(0, 0, 0)
	view = Vector3(0, 0, 1)
	lastview = Vector3(0, 0, 1)
	acc = Vector3.ZERO
	aiacc = Vector3.ZERO
	
	
	var pm = null
	if Global.setupWomens:
		pm = load("res://Scenes/FemKeeperMesh.tscn").instance()
	else:
		pm = load("res://Scenes/KeeperMesh.tscn").instance()
	pm.name = "PlayerMesh"
	add_child(pm)
	myPM = pm
	
	myRoot = get_parent()
	myRoot.myPlayer = self
	pSpeed = 20
	myArea = $BallPos
	
	myATree = $PlayerMesh / AnimationTree
	myMesh = $PlayerMesh / QuickRigCharacter_Reference / PlayerM
	
	myAState = $PlayerMesh / AnimationTree.get("parameters/StateMachine/playback")
	
	collbone = $PlayerMesh / QuickRigCharacter_Reference / BoneAttachment

	myCaught = $PlayerMesh / QuickRigCharacter_Reference / BoneAttachment2 / CatchPoint
	handbone = $PlayerMesh / QuickRigCharacter_Reference / BoneAttachment2 / 
	aiFrame = 0
	AI = $AI
	$PlayerMesh.myk = AI
	
	
	set_process(false)
	cp = collbone
	
	
	
		
func _initP2Controls():
	cshoot = "p2_shoot"
	cpass = "p2_pass"
	cchip = "p2_chip"
	cthru = "p2_thru"
	cswitch = "p2_switch"
	cburst = "p2_burst"
	
func checkInput():
	var mov = Vector2.ZERO
	if (Input.is_action_pressed("ui_left")):
		velocity.x = - pSpeed
		mov.x = 1
	elif (Input.is_action_pressed("ui_right")):
		velocity.x = pSpeed
		mov.x = 1
	if (Input.is_action_pressed("ui_up")):
		velocity.z = - pSpeed
		mov.y = 1
	elif (Input.is_action_pressed("ui_down")):
		velocity.z = + pSpeed
		mov.y = 1
	if ( not AI._diving()):
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
			mov.y = - 1 * jflip
		elif (Input.is_action_pressed("p1_down")):
			mov.y = 1 * jflip
		if mov.length_squared() > 1.0:
			mov = mov.normalized()
	
	
	
	if (Input.is_action_pressed(cchip)):
		if (AI._hasBall()):
			AI._clearBall()
			
	elif (Input.is_action_pressed(cpass)):
		if (AI._hasBall()):
			
			var passD = Vector3(0, 0, 0)
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
				m.y *= jflip * - 1.0
				mov += m
			
			
			var passV = myTeam._findPass(translation, passD, myID)
			if (passV):
				print("control throwing out")
				AI._throwOut()
				
				
				
				
				
				
		else:
			var vm = (ball.translation - translation).normalized()
			mov.x = vm.x
			mov.y = vm.z
	
	
	if (AI._hasBall()):
		if abs(translation.x) < 88.0 * Global.ps or abs(translation.z) > 46.5 * Global.ps:
			
		
			AI._clearBall()

	if ( not AI._diving()):
		acc.x += mov.x * pAgility
		acc.z += mov.y * pAgility
	
		if velocity.length_squared() > 4:
			view = translation + velocity * 5
		else:
			view = myGoal - translation


func _controlMe():
	if (myTeam.AIteam):
		return
	isAI = false
	AI.divevel *= 0.05
	$Indicator.visible = true
	
func _loseControl():
	isAI = true
	$Indicator.visible = false

func _process( var delta):
	
	if not replay:
		
		
		if (isAI):
			
		
			AI._updateData(translation, velocity)
			AI._update()
			
			
		else:
			
			checkInput()
			
		
		if ( not AI._diving()):
			AI.diveStopOn = false
			AI.diveTrack = false
			velocity += acc * 60.0 * delta
			velocity.x = clamp(velocity.x, - pSpeed, pSpeed)
			velocity.z = clamp(velocity.z, - pSpeed, pSpeed)
			velocity.y = 0.0
			if (velocity.length_squared() > pSpeed * pSpeed):
				velocity = velocity.normalized() * pSpeed
			var vscale = smoothstep(0.0, 1.5, (translation - AI.target).length_squared())
			velocity *= vscale
			
			acc *= 0.1
			var vl = velocity.length()
			
			
			
			if vl > 12:
				myATree["parameters/StateMachine/sprint/RunSpeed/scale"] = (vl / pSpeed) * 1.33
				myAState.travel("sprint")
			elif vl > 2.0:
				myAState.travel("walk")
				myATree["parameters/StateMachine/walk/WalkSpeed/scale"] = (vl / 12.0) * 1.33
			else:
				if Global.gameOn or Global.penOn:
					myAState.travel("idle")
				else:
					var r = rand_range(0, 1)
					if r > 0.99:
						r = rand_range(0, 1)
						if r < 0.33:
							myAState.travel("newidleclap")
						elif r < 0.66:
							myAState.travel("newidlepoint")
						else:
							myAState.travel("newidlepointR")
					else:
						myAState.travel("idle")
			myATree["parameters/StateMachine/sprint/RunSpeed/scale"] = 0.5 + (vl / pSpeed) * 1.0
		
		else:
			velocity = AI.divevel
			# Faster divers slow down in step (see Team: diveFast), so a dive lands where it
			# always would, just sooner.
			AI.divevel *= pow(1.0 - 0.02 * (get_meta("diveFast") if has_meta("diveFast") else 1.0), (delta / 0.01666667))
			# A dive carries the keeper to where he dived for and half a body-width past it, no further:
			# without this, quick divers flew by long and curling shots and let them in behind.
			if AI.diveTrack and ball._isShooting():
				# Shot dives keep reading the ball (curl, late deflections, his slower left-side
				# dive) and steer his slide onto it, as fast as he can dive, stopping once there.
				var pr = AI._predictShot(translation.x)
				# Never slide beyond the posts: a ball heading past them is going wide anyway.
				# (Unless it's going in: off his line at an angle, the near-post ball crosses his
				# line wider than the post.)
				var gHalf = max(abs(myTeam.goalL.z - myTeam.goalR.z) * 0.5 + DIVE_POST_EXTRA, AI._shotReachZ())
				pr.z = clamp(pr.z, AI.dGoal.z - gHalf, AI.dGoal.z + gHalf)
				var gap = pr.z - translation.z
				var want = 0.0
				if abs(gap) > AI.diveReach + DIVE_STOP_PAST:
					want = gap - sign(gap) * AI.diveReach
				var tLeft = abs(translation.x - Global.ballpos.x) / max(abs(Global.ballvel.x), 20.0)
				var need = clamp(want / max(tLeft, 0.05), - pDiveSpeed, pDiveSpeed)
				if want == 0.0:
					AI.divevel.z = 0.0
					velocity.z = 0.0
				elif sign(need) != sign(AI.divevel.z) or abs(need) > abs(AI.divevel.z):
					AI.divevel.z = need
					velocity.z = need
				AI.diveStopOn = false
			elif AI.diveStopOn:
				var flat = translation - AI.diveStopPoint
				flat.y = 0.0
				if flat.dot(AI.diveStopDir) > DIVE_STOP_PAST:
					AI.divevel.x = 0.0
					AI.divevel.z = 0.0
					velocity.x = 0.0
					velocity.z = 0.0
					AI.diveStopOn = false
			
			
			
			velocity = velocity.limit_length(pDiveSpeed)
			
			
			
			acc *= 0.1
			
		view.y = translation.y + 0.05
		if (translation - view).length_squared() < 1.0:
			view = - transform.basis.z * 2.0
		
		
	myRoot.process(delta)
var saveBoxNode = null
func _physics_process(delta):
	_eliteFingertips()
	if not replay:
		
		
		
		
		if (translation.y > 0.1):
			
			AI.divevel += gravity * delta
			velocity += gravity * delta
		elif velocity.y < 0.0:
			translation.y = 0.0
			velocity.y = 0.0
			AI.divevel.y = 0.0
		
		velocity = move_and_slide(velocity, Vector3.UP, false, 4)
		velocity *= 0.95
		var newt = transform.looking_at(translation + (translation - view), Vector3.UP)
		transform = transform.interpolate_with(newt, delta * 20)
		
		
		
	else:
		translation = get_parent()._getPos()
		var vel = get_parent()._getVel()
		view = get_parent()._getLook()
		
		
		
		
		
		
		
		
		if (view.length_squared() > 0.4):
			var newt = transform.looking_at(translation + (translation - view), Vector3.UP)
			transform = transform.interpolate_with(newt, delta * 10)
		
		var astate = myRoot._getState()
		if astate != laststate:
		
			myAState.travel(astate)
			laststate = astate
		
		
		
		
		
		
		
		
		
		
		myATree["parameters/StateMachine/sprint/RunSpeed/scale"] = 0.5 + (vel.length() / pSpeed) * 1.0
		myATree["parameters/StateMachine/walk/WalkSpeed/scale"] = 0.5 + (vel.length() / pSpeed) * 1.25
			














































# A ball already going wide or over is left alone (it goes out for a goal kick) rather than
# touched round the post for a corner. Before, the bigger save reach turned wide headers into
# corner after corner.
func _goingWide():
	if Global.penOn or not Global.gameOn or ball._isCaught():
		return false
	var lineX = sign(AI.dGoal.x) * 140.0 * Global.ps
	if sign(Global.ballvel.x) != sign(lineX) or abs(Global.ballvel.x) < 5.0:
		return false
	var cross = AI._predictShot(lineX)
	var half = abs(myTeam.goalL.z - myTeam.goalR.z) * 0.5
	return abs(cross.z) > half + 1.5 or cross.y > 10.5

func doSave():
	var saved = false
	if _goingWide():
		return saved
	
	var dc = (Global.ballpos - cp.global_transform.origin)
	if (dc.length() < 4.5) and Global.ballvel.length_squared() < catchDistance and ( not Global.penOn) and AI._diving():
			
			
		
		
		canControl = false
		canSave = false
		if ball._ballCaught(self):
			AI._caught()
			if not AI._diving():
				myATree["parameters/CaughtBall/blend_amount"] = 1.0
		
			if Global.gameOn:
				
				emit_signal("posession", myID)
				myTeam._caughtBall()
				myTeam.Game._catch()
			saved = true
		
	elif ball._canHead() and not AI._diving() and Global.ballpos.y < 2:
		
		
		canControl = false
		canSave = false
		ball.lastPlayer = self
		view = transform.basis.z
		AI._bootBall()
		saved = true
		yield(get_tree().create_timer(0.2), "timeout")
		canSave = true
		canControl = true
	else:
		
		
		canSave = false
		ball.lastPlayer = self
		ball._reflectSaved(global_transform.basis.z, - AI.flip * AI.divedir, AI.isUp)
		
		if Global.gameOn:
			myTeam._defendRebound()
			myTeam.opponent._attackRebound()
		saved = true
		myTeam.Game._crowdooh()
		yield(get_tree().create_timer(0.2), "timeout")
		canSave = true
		canControl = true
	if saved and Global.penShoot:
		myTeam._savedPen()

	
	
	
	

	
	
	
# Good keepers (fingerReach, set in Team.gd; Neuer most of all): a shot at his goal that comes
# within that reach of his body is saved, fingertips or a strong hand, whether set or mid-dive.
func _eliteFingertips():
	var reach = get_meta("fingerReach") if has_meta("fingerReach") else 0.0
	if reach <= 0.0:
		return
	if not Global.gameOn or Global.penOn or not canSave or not canControl or not ball._isShooting():
		return
	var sh = ball.shooter
	if sh == null or sh.get("myTeam") == myTeam:
		return
	if sign(Global.ballvel.x) != sign(AI.dGoal.x):
		return
	if saveBoxNode == null:
		saveBoxNode = find_node("AreaTest", true, false)
		if saveBoxNode == null:
			return
	if (Global.ballpos - saveBoxNode.global_transform.origin).length() < reach:
		doSave()

func _on_TestSaveArea_area_entered(_area):
	
	if ((Global.gameOn) or ((Global.penShoot) and Global.penOn)) and (canControl) and canSave:
		
		if ball._isTrapped() and myTeam.posession:
			return
		doSave()
		myTeam.isCorner = false

func _on_SaveArea_area_exited(_area):
	
	if not ball._isCaught():
		
		
		canSave = true
	
func _savePenalty():
	
	
	var mov = Vector2.ZERO
	mov.x = - Input.get_joy_axis(myC, clr)
	mov.y = Input.get_joy_axis(myC, cud) * jflip
	
	if Global.touchPad.isActive():
		var m = Global.touchPad.get_force()
		m.y *= jflip * - 1.0
		m.x *= - 1.0
		mov += m * 2.0
	if (Input.is_action_pressed("p1_left")):
		mov.x += 1
	elif (Input.is_action_pressed("p1_right")):
		mov.x -= 1
	if (Input.is_action_pressed("p1_up")):
		mov.y -= 1
	elif (Input.is_action_pressed("p1_down")):
		mov.y += 1
	mov.y = smoothstep(1.0, - 1.0, mov.y)
	AI.dview = ball.translation
	AI.view = AI.dview
	AI.shotview = AI.view
	AI._penaltyDive(mov)

# --- Crash guards --------------------------------------------------------------
# This web build uses a release engine, where calling a method that doesn't
# exist crashes the whole game ("RuntimeError: null function" = the freeze).
# Several outfield-only methods can be reached on the goalkeeper, so give him
# harmless versions of them.
func _burst():
	pass

func _say(_saying):
	pass

func _shush():
	pass

func _push(_v):
	pass
