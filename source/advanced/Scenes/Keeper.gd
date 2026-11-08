
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
		if abs(translation.x) < 88.0 or abs(translation.z) > 46.5:
			
		
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
			AI.divevel *= pow(0.98, (delta / 0.01666667))
			
			
			
			velocity = velocity.limit_length(pDiveSpeed)
			
			
			
			acc *= 0.1
			
		view.y = translation.y + 0.05
		if (translation - view).length_squared() < 1.0:
			view = - transform.basis.z * 2.0
		
		
	myRoot.process(delta)
func _physics_process(delta):
	
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
			














































func doSave():
	var saved = false
	
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
