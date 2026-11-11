extends Spatial


var myPlayer
var myGoal
var myGoalR
var myGoalL
var myTeam


var pos
var vel
var view
var target = Vector3.ZERO
var atarget = Vector3.ZERO
var avoidVec
var longpass = false

enum pstate{IDLE, PCONTROL, PLAYING, DEFEND, SUPPORT, PRESS, POSESSION, CELEBRATE, REPLAY, CONCEDED, SLIDE, FOULED, TACKLED, PENALTY, PENALTYDEFEND, KICKER, HEAD, SHOOT, PCOLLECT, PICKUP, HOLDING, THROWIN, DIVINGH, MARK, INTERCEPT, BIKE, ACTION, BENCH, SENTOFF, LAP}
var stateFunc = {}
var state
var prevstate
var slidecntr
var slidevel
var isHuman = false
var isFK = false
var isSP = false
var isShoot = 1
var fkdir = Vector3.ZERO
var fkcurl = Vector3.ZERO
var pdir = 0
var pele = 0
var xct
var yst
var threat = 0.0
var bigthreat = Vector3.ZERO
var pressure = Vector3.ZERO
var aavoid = Vector3.ZERO
var movin = false
var astate = "idle"
var marking = null
var rayc = null
var cCelebTarget = 0

func _ready():
	
	state = pstate.IDLE
	stateFunc[pstate.IDLE] = funcref(self, "idleState")
	stateFunc[pstate.SUPPORT] = funcref(self, "supportState")
	stateFunc[pstate.DEFEND] = funcref(self, "defendState")
	stateFunc[pstate.PRESS] = funcref(self, "pressState")
	stateFunc[pstate.POSESSION] = funcref(self, "posessionState")
	stateFunc[pstate.CELEBRATE] = funcref(self, "celebrateState")
	stateFunc[pstate.REPLAY] = funcref(self, "replayState")
	stateFunc[pstate.PCONTROL] = funcref(self, "checkInput")
	stateFunc[pstate.CONCEDED] = funcref(self, "concededState")
	stateFunc[pstate.SLIDE] = funcref(self, "slideState")
	stateFunc[pstate.FOULED] = funcref(self, "fouledState")
	stateFunc[pstate.TACKLED] = funcref(self, "fouledState")
	stateFunc[pstate.PENALTY] = funcref(self, "penaltyState")
	stateFunc[pstate.PENALTYDEFEND] = funcref(self, "penaltyDefendState")
	stateFunc[pstate.KICKER] = funcref(self, "kickerState")
	stateFunc[pstate.HEAD] = funcref(self, "headState")
	stateFunc[pstate.SHOOT] = funcref(self, "shootState")
	stateFunc[pstate.PCOLLECT] = funcref(self, "pcollectState")
	stateFunc[pstate.PICKUP] = funcref(self, "pickupState")
	stateFunc[pstate.HOLDING] = funcref(self, "holdingState")
	stateFunc[pstate.THROWIN] = funcref(self, "throwinState")
	stateFunc[pstate.DIVINGH] = funcref(self, "divingHState")
	stateFunc[pstate.MARK] = funcref(self, "markState")
	stateFunc[pstate.INTERCEPT] = funcref(self, "interceptState")
	stateFunc[pstate.BIKE] = funcref(self, "bikeState")
	stateFunc[pstate.ACTION] = funcref(self, "actionState")
	stateFunc[pstate.BENCH] = funcref(self, "benchState")
	stateFunc[pstate.SENTOFF] = funcref(self, "offState")
	stateFunc[pstate.PLAYING] = funcref(self, "playingState")
	stateFunc[pstate.LAP] = funcref(self, "lapState")
	
	
	slidevel = Vector3.ZERO
	
	avoidVec = Vector3.ZERO
	prevstate = pstate.IDLE
	
	
func _initialize( var team, var goal, var goalL, var goalR, var _dGoal):
	myPlayer = get_parent()
	myTeam = team
	myGoal = goal
	myGoalL = goalL
	myGoalR = goalR
	
	var theta = (myPlayer.myID / 7.0) * 2.0 * PI
	xct = cos(theta)
	yst = sin(theta)

func _inputAction(action):
	if Global.multiplayer_mode and myTeam and myTeam.teamID == 2 and action.begins_with("p1_"):
		return Input.is_action_pressed(action.replace("p1_", "p2_"))
	return Input.is_action_pressed(action)
	
	
func changeState( var toState):
	if myPlayer.carded > 1:
		return
	
	
	
	
		
	if _moving():
		
		state = toState
	else:
		prevstate = toState
		

func _quadratic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r
	


func seek( var t):
	
	# Players holding position stay onside; runs onto a pass use other states.
	if Global.elevenMode and (state == pstate.PLAYING or state == pstate.SUPPORT):
		t = myTeam._keepOnside(t, myPlayer.myID)
	var diff = (t - pos)

	var dl = diff.length()
	var speed = smoothstep(1, 6, dl)
	if dl > 0.1:
		vel = (diff / dl) * myPlayer.pAgility * speed
		
	return dl
	

func avoid( var other):
	if other == myPlayer.ball:
		
		return Vector3.ZERO
	
	
	var diff = (myPlayer.translation + myPlayer.velocity * myPlayer.dSmart) - (other.translation + other.velocity * myPlayer.dSmart)
	
	var odiff = diff
	var dl = odiff.length()
	diff = odiff / dl
	
	var dd = myPlayer.transform.basis.z.dot(diff)
	var av = - myPlayer.transform.basis.z.slerp( - diff, 0.5)
	var t = 1.0 - smoothstep(0.0, 24.0, dl)
	
	t = (t * t)
	
		
	if sign(dd) < 0:
	
		t *= 0.25
	
	av.y = 0
	av = av.normalized() * t * 4.0
	





	
	
	
	
	vel.y = 0
	if t > threat:
		threat = t
		bigthreat = av * myPlayer.pAgility
		
	
	return av * myPlayer.pAgility

func calcPressure():
	
	var pres = Vector3.ZERO
	
	var bodies = myPlayer.TA.get_overlapping_bodies()
	var bs = bodies.size()
	if bs > 0:
		for i in range(bodies.size()):
			if bodies[i] != myPlayer.ball:
				var dp = bodies[i].translation - myPlayer.translation
				var dl = dp.length()
				dp = (dp / dl) * (1.0 - smoothstep(0, 10, dl))
				pres += dp
			else:
				pres += - myPlayer.transform.basis.z
	else:
		pres = myPlayer.transform.basis.z
	
	return pres.normalized()
	
func setTarget(tgt):
	target = tgt
	atarget = tgt
	
	
func closestPointToBall():
	var bp = Global.ballpos
	var bvel = Global.ballvel
	
	
	var toBall = bp - pos
	var relHead = vel.normalized().dot(bvel.normalized())
	if toBall.dot(bvel) > 0 and relHead < - 0.95:
	
		return bp + bvel * myPlayer.pSmart * 0.01666
	var lmult = myPlayer.pSmart
	var lookAhead = toBall.length() / (myPlayer.pSpeed + bvel.length())
	
	return (bp + bvel.normalized() * lookAhead * lmult)

		

	









		
func closestPToBallDefend():
	var pvel = Global.ballvel * myPlayer.dSmart
	
	var db = (Global.ballpos - myPlayer.dGoal)
	
	if sign(db.dot(pvel)) > 0:
		
		pvel = Vector3.ZERO
		
	var pval = 0.4
	
	if myTeam.zone == 3:
		return Global.ballpos + pvel - (Global.ballpos - myPlayer.dGoal).normalized() * lerp(8.0, 1.0, myPlayer.pAggression)
	elif myTeam.zone == 1 and myTeam._ballInBox():
		return Global.ballpos + pvel
	elif myTeam.zone == 2:
		pval = 0.9
	elif not myTeam.ball._isFree():
		pval = 0.4 + myPlayer.pAggression
		
	var ls = myTeam.d2p2b[myPlayer.myID]
	if ls < 700:
		ls = smoothstep(0, 700, ls)
		pval = range_lerp(ls, 0, 1, 0.999, pval)
	
	var hp = (myPlayer.dGoal + myPlayer.pAggression * db)
	return _quadratic_bezier(pos, hp, (Global.ballpos + pvel) - db.normalized() * 4.0, pval)
func closestPToBallDefendNew():
	
	var bp = Global.ballpos + Global.ballvel * myPlayer.dSmart
	var b2g = (bp - myPlayer.dGoal).normalized()
	return bp - b2g * (lerp(8.0, 4.0, myPlayer.pAggression))
	
func closestPToBallDefendOld():
	
	var bp = Global.ballpos + 0.1 * Global.ballvel
	
	
		
	
	
		
	var db = bp - pos
	
	
	
	if myTeam.zone == 1 and abs(bp.x) > 60 * Global.ps:
		
		return bp
	var R = bp - myPlayer.dGoal
	var PR = pos - myPlayer.dGoal
	
		
	if db.length() < 15 and (R.length_squared() > PR.length_squared()):
			return bp
	
	return myPlayer.dGoal + R * 0.85
	


func idleState():
	if (target.y < 0.0):
		target.y = 0
	if marking:
		target = marking.translation
	elif myPlayer == myTeam.throwTarget:
		target = Global.ballpos - (Global.ballpos - target) * 0.75
		target.y = 0.1
		
	var _close = seek(target)
	view = target
	atarget = target
	
	if not Global.gameOn and rand_range(0.0, 1.0) > 0.99:
		var r = rand_range(0.0, 1.0)
		if r < 0.33:
			myPlayer.myAState.travel("newidleclap")
		elif r < 0.66:
			myPlayer.myAState.travel("idlepoint")
		else:
			myPlayer.myAState.travel("idlepointR")
		astate = "newidleclap"





func findMarker():
	var bodies = myPlayer.TA.get_overlapping_bodies()
	var bs = bodies.size()
	var closestd = 50000
	var player = null
	if marking:
		return marking.translation - Vector3(myTeam.playDir * 5, 0, 0)
	if bs > 0:
		for i in range(bodies.size()):
			if bodies[i] != myPlayer.ball:
				var d = (bodies[i].translation - myPlayer.translation).length_squared()
				
				
				if d < closestd and not bodies[i].AI._hasBall() and not bodies[i].marked:
					closestd = d
					player = bodies[i]
					
	if player:
	
		player.marked = true
		marking = player
		return player.translation - Vector3(myTeam.playDir * 5, 0, 0)
	else:
		return target
func playingState():
	
	target = myTeam._getPlayPos(myPlayer.myID)
	var t = target
	if myPlayer.ball._isCrossing():
		t = Global.ballpos + Global.ballvel * 0.2
	elif myTeam.zone == 1 and not myTeam.momentum:
		
		
		if myTeam.d2p2b[myPlayer.myID] < 144.0:
			
			if marking:
				marking.marked = false
				marking = null
			t = (Global.ballpos + Global.ballvel * myPlayer.dSmart) + Vector3( - 4.0, 0, 0) * myTeam.playDir
			if (t - target).length_squared() > 144:
				t = target
		elif myPlayer.myID == myTeam.closestToGoal:
			t = Helper.pointToLine(Global.ballpos + Global.ballvel * myPlayer.dSmart, myTeam.dGoal, t, 0.4)








			
		else:
			t = findMarker()
	
	
	
	
	
	elif marking:
		if myTeam.momentum:
			t = findMarker()
		else:
			marking.marked = false
			marking = null
	elif (myTeam.zone == 3) and myTeam.momentum:
		t = (t * 0.7 + (Global.ballpos + Global.ballvel * 0.3) * 0.3)
	atarget = t
	
	var _close = seek(t)


func supportState():
	
	
	
	var t = target
	if myPlayer.ball._isCrossing():
		t = Global.ballpos + Global.ballvel * 0.3
	elif (myTeam.zone == 3):
		t = (t * 0.7 + (Global.ballpos + Global.ballvel * 0.3) * 0.3)
	
	
	if (myTeam.pplayer):
		var dp = myPlayer.translation - myTeam.pplayer.translation
		if dp.length_squared() < 500:
			t += (dp * (1.0 - (dp.length_squared() / 500.0))) * 30
	
	
	atarget = t
	var _close = seek(t)




	
	
	
	
	
	

func defendState():
	
	var t = target
	if myPlayer.ball._isCrossing():
		t = Global.ballpos + Global.ballvel * 0.2
	elif myTeam.zone == 1:
		var diff = (Global.ballpos + Global.ballvel * 0.2)
		if abs(diff.x) > abs(t.x):
			diff = diff - target
			diff.z *= 0.15
			t = target + diff.normalized() * 25
	
	atarget = t
	var _close = seek(t)
	view = t
	
	if myPlayer.pSpeed <= myPlayer.pOSpeed and _close > 5:
		if (rand_range(0, 1) > 0.1):
			myPlayer._burst()
			myPlayer.myfx.emitting = Global.doParticles
	else:
		myPlayer.myfx.emitting = false
func pressState():
	
	
	
	
	
	
	if myTeam.posession:
		changeState(pstate.PLAYING)
		return
		
	if myPlayer.ball._isOpen():
		
		if myPlayer.canControl:
			if Global.ballvel.length_squared() < 20000:
	
				var bods = myPlayer.myTrapArea.get_overlapping_bodies()
				for b in bods:
					if b == myPlayer.ball:
						
						myPlayer.ball._ballTrapped(myPlayer)
						_posession()
						myTeam._onPosession(myPlayer.myID)
						return
				
		target = closestPointToBall()
	else:
		target = closestPToBallDefendNew()
		
	
	target.y = 0.05
	atarget = target
	
	var _close = seek(target)
	
	
	
	if myPlayer.pSpeed <= myPlayer.pOSpeed:
		if (rand_range(0, 1) > 0.1):
			myPlayer._burst()
			myPlayer.myfx.emitting = Global.doParticles
	else:
		myPlayer.myfx.emitting = false
	
	if myTeam.AIteam:
		var doslide = rand_range(0.0, 1.0)
		if ((pos - Global.ballpos + Global.ballvel * 0.2).length() < 10) and (doslide * 2.0 < myPlayer.pAggression) and (myTeam.opponent.posession == true):
			if myTeam.opponent.pplayer:
			
				if sign(myTeam.opponent.pplayer.velocity.dot(myPlayer.velocity)) < 0 and Global.ballpos.y < 1:
				
					if - myPlayer.transform.basis.z.dot( - myTeam.opponent.pplayer.transform.basis.z) < 0.25:
						var slidedir = (Global.ballpos + myTeam.opponent.pplayer.velocity * 0.1) - (myPlayer.translation + myPlayer.velocity * 0.1)
						slidedir = slidedir.normalized()
						_slide(false, Vector2(slidedir.x, slidedir.z))





			
func pcollectState():
	
	if myTeam.posession:
		
		changeState(pstate.PLAYING)
		return
	if longpass:
		var lookahead = 0.15
		if Global.ballpos.y > 4:
			lookahead = 0.5
		target = Global.ballpos + (Global.ballvel * lookahead)
	else:
		var angle = (myPlayer.translation - Global.ballpos).normalized().dot(Global.ballvel.normalized())
		
		
		if abs(angle) > 0.95:
			
			target = Global.ballpos
		else:
			
			target = Global.ballpos + Global.ballvel * myPlayer.dSmart * 1.0
	target.y = 0
	var _close = seek(target)
	
	atarget = target
	
	view = target
	
	if myPlayer.pSpeed <= myPlayer.pOSpeed:
		if (rand_range(0, 1) > 0.1):
			myPlayer._burst()
			myPlayer.myfx.emitting = Global.doParticles
	else:
		myPlayer.myfx.emitting = false





# The earliest point on an opponent's low pass that this player can get to first.
func _laneSpot():
	var ball = myPlayer.ball
	if ball.state != ball.bstate.OPEN or ball.isShot or Global.ballpos.y > 3.0:
		return null
	var kicker = ball.shooter
	if kicker == null or kicker.get("myTeam") == myTeam:
		return null
	var flight = Vector3(Global.ballvel.x, 0.0, Global.ballvel.z)
	if flight.length() < 35.0:
		return null
	var at = 0.1
	while at <= 0.9:
		var spot = Global.ballpos + flight * at
		spot.y = myPlayer.translation.y
		if (spot - myPlayer.translation).length() - 2.5 <= myPlayer.pBurst * at * 0.9:
			return spot
		at += 0.1
	return null

func _readPassingLane():
	if not myPlayer.isAI or myTeam.posession:
		return
	if state != pstate.DEFEND and state != pstate.MARK and state != pstate.PRESS and state != pstate.SUPPORT and state != pstate.PLAYING:
		return
	if _laneSpot() != null:
		longpass = false
		changeState(pstate.INTERCEPT)

func interceptState():
	var lane = _laneSpot() if (Global.elevenMode and myPlayer.pBallWin > 0.0) else null
	if lane != null:
		var _close = seek(lane)
		atarget = lane
		view = lane
		if myPlayer.pSpeed <= myPlayer.pOSpeed:
			myPlayer._burst()
			myPlayer.myfx.emitting = Global.doParticles
		return
	if longpass:
		var lookahead = 0.1
		if Global.ballpos.y > 3:
			lookahead = 0.6
		target = Global.ballpos + Global.ballvel * lookahead
	else:
		if abs((myPlayer.translation - Global.ballpos).normalized().dot(Global.ballvel.normalized())) > 0.9:
			
			target = Global.ballpos
		else:
			target = Global.ballpos + Global.ballvel * 0.4
		
	var close = seek(target)
	
	atarget = target
	
	view = target
	
	if myPlayer.pSpeed <= myPlayer.pOSpeed:
		if (rand_range(0, 1) > 0.1):
			myPlayer._burst()
			myPlayer.myfx.emitting = Global.doParticles
	else:
		myPlayer.myfx.emitting = false
	
	if (close < 12):
		
		
		
		
		
		changeState(pstate.PRESS)
		
func pickupState():
	var close = seek(myPlayer.ball.translation)
	atarget = myPlayer.ball.translation
	if (close < 2.5):
		
		changeState(pstate.ACTION)
		movin = false
		myPlayer.velocity *= 0.05
		myPlayer.acc *= 0.05
		myPlayer.ball._initialize()
		myPlayer.myAState.travel("pickup")
		astate = "pickup"
		changeState(pstate.HOLDING)
		atarget = myPlayer.ball.translation
		
		slidevel = pos.normalized()
		
func holdingState():
	if not myPlayer.ball._isCaught():
		myPlayer.ball._ballCaught(myPlayer)
	var _close = seek(target)
	atarget = target
	
func actionState():
	pass

func throwinState():
	slidevel = - pos.normalized()
	myPlayer.pSmart = myPlayer.pTSmart
	
func kickerState():
	var close = seek(target)
	var c = 3
	if isShoot < 1:
		c = 6
	atarget = target
	
	if (close < c) and myPlayer.canControl:
		myPlayer.canControl = false
		if isFK:
			if isShoot == 0:
				tryFreeKick()
			elif isShoot == 1:
				tryFKPass()
			else:
				tryFKLongPass()
		else:
			tryPenShot()
		myPlayer.pSmart = myPlayer.pTSmart
		
		
		yield(get_tree().create_timer(0.2), "timeout")
		myPlayer.canControl = true
		changeState(pstate.PLAYING)
		
func posessionState():
	
	var ttarget = myTeam._getPosessionPos(myPlayer.myID, myPlayer.translation, false)
	
	ttarget.y = 0.15
	
	



	
	
	var newacc = ttarget - myPlayer.translation
	var itarget = myPlayer.translation + newacc * 0.5
	
	var bodies = myPlayer.TA.get_overlapping_bodies()
	
	newacc = Vector3.ZERO
	threat = 0.0
	bigthreat = Vector3.ZERO
	if bodies.size() < 1:
		var _close = seek(itarget)
		
	else:
		var a = newacc
		for i in range(bodies.size()):
			a = avoid(bodies[i])
			if a.length_squared() > newacc.length_squared():
				newacc = a
				
		if myPlayer.pSpeed <= myPlayer.pDSpeed:
			if threat > 0.0:
				myPlayer._burst()
				myPlayer.myfx.emitting = Global.doParticles
			else:
				myPlayer.myfx.emitting = false
	
		var _close = seek(itarget)
		vel *= lerp(1.0, 2.0, myTeam.aggression)
		
		
		aavoid += newacc * 0.5
		
		var tx = smoothstep(125 * Global.ps, 138 * Global.ps, abs(pos.x))
		var tz = smoothstep(80 * Global.ps, 90 * Global.ps, abs(pos.z))
		aavoid -= Vector3(tx * sign(pos.x), 0, tz * sign(pos.z)) * 30.0
		itarget += aavoid
			








		
		
	atarget = itarget
	
	
	
			
func slideState():
	
	pass
	
	
	
	
	
		
func shootState():
	vel = Vector3.ZERO
	
func headState():
	pass
	
	
	
	
	
	
func divingHState():
	
	pass
	
func fouledState():
	vel = Vector3.ZERO
	
func penaltyState():
	var _close = seek(target)
	
func penaltyDefendState():
	var _close = seek(target)
	view = target
func markState():
	target = myTeam._getMarkPosition(myPlayer.myID)
	atarget = target
	var _close = seek(target)
	
func celebrateState():
	
	if (myTeam.scorer != myPlayer.myID) and myTeam.Game.goalscorer:
		
		target = myTeam.Game.goalscorer.translation + Vector3(xct * 4.0, 0.0, yst * 4.0)
		view = myTeam.Game.goalscorer.translation
		
	atarget = target
	var _close = seek(target)
	
	aavoid = (myGoal - pos) * (1.0 - smoothstep(8, 44, (myGoal - pos).length_squared())) * 44.0
	if (_close < 6):
		
		if myTeam.celeb > 0:
			myPlayer.myATree["parameters/BlendCelebrate/blend_amount"] = 0
			if myTeam.celeb == 1:
				myPlayer.myAState.travel("celebslide")
				astate = "celebslide"
			elif myTeam.celeb == 2:
				myPlayer.myAState.travel("archer")
				astate = "archer"
			elif myTeam.celeb == 3:
				myPlayer.myAState.travel("fouled")
				astate = "celebslide"
			elif myTeam.celeb == 4:
				myPlayer.myAState.travel("somersault")
				astate = "fouled"
			
			
			state = pstate.ACTION
			prevstate = pstate.CELEBRATE
			slidevel = myPlayer.velocity
			if slidevel.length_squared() < 1.0:
				slidevel = - myPlayer.transform.basis.z * 2.0
		



		
func concededState():
	vel = Vector3.ZERO
func bikeState():
	pass
	
func replayState():
	pass

	
func _attack():
	
	
	if not Global.gameOn:
		return
	marking = null
	
	
	if state != pstate.POSESSION and state != pstate.PRESS:
		myPlayer.posI.visible = false
		
		target = myTeam._getPlayPos(myPlayer.myID)
		atarget = target
		
		changeState(pstate.PLAYING)
		
func _defend():
	if Global.gameOn:
		if state != pstate.POSESSION and state != pstate.PCOLLECT and state != pstate.INTERCEPT and state != pstate.PRESS:
			
			target = myTeam._getPlayPos(myPlayer.myID)
			myPlayer.posI.visible = false
			atarget = target
			
			changeState(pstate.PLAYING)

func _play():
	if Global.gameOn:
		myPlayer.posI.visible = false
		target = myTeam._getPlayPos(myPlayer.myID)
		changeState(pstate.PLAYING)
		
func _forceDefend():
	if Global.gameOn:
		
		changeState(pstate.PLAYING)
		myPlayer.posI.visible = false
	target = myTeam._getPlayPos(myPlayer.myID)
func _forceAttack():
	
	
	if Global.gameOn and state != pstate.POSESSION:
		
		changeState(pstate.PLAYING)
		target = myTeam._getPlayPos(myPlayer.myID)
		myPlayer.posI.visible = false
func _defendFK():
	
	marking = null
	target = myTeam._getDefendFKPos(myPlayer.myID)
	var rp = myTeam.Game.resetPos
	if (target - rp).length_squared() < 400:
	
		target -= rp + (rp - myPlayer.dGoal).normalized() * 20
		target.y = 0
	atarget = target
	myPlayer.posI.visible = false
	changeState(pstate.IDLE)
	

func _attackFK():
	
	marking = null
	changeState(pstate.IDLE)
		
	target = myTeam._getSupportFKPos(myPlayer.myID)
		
	if (target - myTeam.Game.resetPos).length() < 20:
		
		target -= myTeam.Game.resetPos + (myTeam.Game.resetPos - myPlayer.dGoal).normalized() * 20
	atarget = target
	myPlayer.posI.visible = false
func _corner( var end, var side):
	
	marking = null
	changeState(pstate.IDLE)
		
	var spread = 3.0 if Global.elevenMode else 12.0
	target = myTeam.cformation[myPlayer.myID] + Vector3(rand_range( - spread, spread), 0.0, rand_range( - spread, spread))
	if end < 1:
		target.x *= - 1
	if side < 1:
		target.z *= - 1
	if (target - Global.ballpos).length_squared() < 400:
		
		target -= Global.ballpos + (Global.ballpos - myPlayer.dGoal).normalized() * 20
	atarget = target
	myPlayer.posI.visible = false

	

func tryFKPass():
	
	var dir = - myPlayer.transform.basis.z
	var idir = dir
	if ( not myTeam.AIteam):
		idir.x = Input.get_joy_axis(myPlayer.myC, 0)
		idir.z = Input.get_joy_axis(myPlayer.myC, 1)
		idir.y = 0
	if (_inputAction("p1_left")):
		idir.x += - 1
	elif (_inputAction("p1_right")):
		idir.x += 1
	if (_inputAction("p1_up")):
		idir.z = - 1
	elif (_inputAction("p1_down")):
		idir.z = 1
	if abs(idir.x) < 0.2:
		idir.x = dir.x
	if abs(idir.z) < 0.2:
		idir.z = dir.z
		
	var _passTo = myTeam._findPass(Global.ballpos, idir, myPlayer.myID)
	
	if myTeam.passto:
		myTeam.passto.AI._receivePass(pos, myTeam.passDir, 0)
	myTeam.opponent.setDefend()
	myTeam.passDir.y += 1
	myTeam.posession = false
	myPlayer.ball._passBall(myTeam.passDir * 1.0, myPlayer)
	isSP = false
	
	
func tryFKPassTarget():
	
	if myTeam.throwTarget:
		var tt = myTeam.throwTarget
		myTeam.opponent.setDefend()
		myTeam.posession = false
		var pd = tt.translation + tt.velocity * tt.dSmart - myPlayer.ball.translation
		myPlayer.ball._passBall(pd, myPlayer)
		if myTeam.AIteam:
			myTeam.throwTarget.AI._receivePass(pos, pd, 0)

func tryFKLongPass():
	var dir = myGoal - Global.ballpos
	if (myTeam.zone < 3):
		if ( not myTeam.AIteam):
			dir.x = Input.get_joy_axis(myPlayer.myC, 0)
			dir.z = Input.get_joy_axis(myPlayer.myC, 1)
			if (_inputAction("p1_left")):
				dir.x = - 1
			elif (_inputAction("p1_right")):
				dir.x = 1
			if (_inputAction("p1_up")):
				dir.z = - 1
			elif (_inputAction("p1_down")):
				dir.z = 1
			dir.y = 0
		var passTo = myTeam._findLongPass(pos, dir, myPlayer.myID)
		if ( not passTo):
			
			dir = Vector3(0, 0, - abs(Global.ballpos.z) * Global.ballpos.z)
			passTo = myTeam._findLongPass(pos, dir, myPlayer.myID)
			
			
		if myTeam.passto:
			myTeam.passto.AI._receivePass(pos, myTeam.passDir, 1)
	
		
		myTeam.passDir.y += 28
		myTeam.posession = false
	
		myPlayer.ball._passBall(myTeam.passDir * 0.8, myPlayer)
		
	else:
		myPlayer.chipPass( not myTeam.AIteam)
		
	
	isSP = false
	myTeam.opponent.setDefend()
	

func _receivePass( var ppos, var dir, var ptype):
	longpass = ptype == 1
	if longpass:
		target = ppos + dir * 2.0
	elif ptype == 0:
		target = ppos + dir * 1.25
	else:
		target = ppos + dir * 3.0
		
	changeState(pstate.PCOLLECT)
	
func _thruPass( var D):
	
	if myTeam.zone == 3 and abs(Global.ballpos.z) > 30 * Global.ps:
		myPlayer.lowshot = true
		myPlayer.chipPass(true)
		return
	var passTo = myTeam._findThruPass(pos, D, myPlayer.myID)
	if (passTo):
		myTeam.passDir.y += 1
		if myPlayer.lowshot:
			myTeam.passDir *= 0.6
			myTeam.passDir.y += 14
		myPlayer.ball._passBall(myTeam.passDir * 1.5, myPlayer)
		myTeam._passTo(myTeam.passto)
		myTeam.posession = false
		myPlayer.lowshot = false
		_losePosession()
		
func _thruPassAI( var _D, var candidate):
	var passPos = candidate.translation - myGoal
	passPos = candidate.translation - (passPos * 0.3)
	if Global.elevenMode:
		passPos = myTeam._safePassSpot(passPos, candidate)
	var pd = passPos - Global.ballpos
	if rand_range(0, 1) > myPlayer.pAgility:
		pd.y += 6
		pd *= 0.5
	myPlayer.ball._passBall(pd * 0.1, myPlayer)
	myTeam._passTo(candidate)
	myPlayer.lowshot = false
	myTeam.posession = false
	_losePosession()
	

func tryShot():
	
	if sign(myPlayer.transform.basis.z.x) == sign(myTeam.playDir):
		
		findPass()
		return
	if _hasBall():
		isFK = false
		_shoot()
		
		var kpos = sign(myTeam.opponent.players[0].translation.z)
		var dir = rand_range(0.0, 1.0)
		if dir < 0.8:
			dir *= - kpos
		
		dir += myPlayer.pShoot * dir
		
		
		
		
		
		var t = lerp(myGoalR, myGoalL, smoothstep( - 1.0, 1.0, dir))
	
		myPlayer.lowshot = rand_range(0.0, 1.0) > 0.7
	
		myPlayer.shotcharge = rand_range(0.2, range_lerp(myPlayer.pShoot, 0.0, 1.0, 0.8, 0.5))
		
		myPlayer.shotcurl = Vector3(0.0, rand_range( - 1.0, 1.0), rand_range( - 0.5, 0.5)) * myPlayer.pCurl
		
		myPlayer.shotdir = t
		
func tryVolley():
	
	var dir = rand_range( - 1.0, 1.0)
	
	dir += myPlayer.pShoot * dir
	var t = myGoal
	
	
	
	
	dir = lerp(myGoalL, myGoalR, smoothstep( - 1.0, 1.0, dir))
	
	myPlayer.shotcharge = rand_range(0.3, range_lerp(myPlayer.pShoot, 0.0, 1.0, 0.8, 0.5))
	
	myPlayer.shoot(t)
	

func _tryHeader():
	
	if ((Global.ballpos + Global.ballvel * 0.016) - (pos + Vector3(0, 5, 0))).length_squared() < 25:
		if (myTeam.zone == 3):
			var shotV = myGoal
			var aim = 0.0
			if not myPlayer.isAI:
				aim = Input.get_joy_axis(myPlayer.myC, myPlayer.cud) * myPlayer.jflip
				aim *= myTeam.playDir
				aim = smoothstep( - 1.0, 1.0, aim)
			else:
				aim = rand_range(0.0, 1.0)
			
			shotV = lerp(myGoalL, myGoalR, aim)
			shotV = shotV - translation
			
			var headdir = (shotV.normalized() + Vector3(0, - 0.125, 0)) * 83.5
			myPlayer.ball._shootBall(myPlayer, headdir, Vector3(0, 0, 0))
			var stype = 3
			if state == pstate.DIVINGH:
				stype = 4
			myTeam._shot(myPlayer.myID, headdir, Vector3.ZERO, stype)
			
		else:
			
			myPlayer.ball._tapBall((myGoal - translation).normalized() * 50.0 + Vector3(0, 25, 0), self)
func _tryBicycleKick():
	
	if not myPlayer.ball._canHead():
		return

	if ((Global.ballpos + Global.ballvel * 0.0) - (pos + Vector3(0, 4, 0))).length_squared() < 25:
		
		var dir = rand_range(0, 1)
		
		
		var t = lerp(myGoalL, myGoalR, dir)
		
		
		
	
		var sdir = (t - pos).normalized()
		sdir.y -= 0.1
		myPlayer.shotcharge = rand_range(0.1, 0.8)
		sdir *= lerp(100, 180, 1.0 - myPlayer.shotcharge)
		myPlayer.ball._shootBall(myPlayer, sdir, Vector3(0, 0, 0))
		var stype = 5
		myTeam._shot(myPlayer.myID, sdir, Vector3.ZERO, stype)
		_losePosession()
		myPlayer.ball._ballFree()

func tryPenShot():
	
	myPlayer.myTeam.Game.penTarget.visible = false
	var t = myGoal
	
	
	if pdir < - 0.25:
		t = lerp(myGoal, myGoalL, smoothstep(0.25, 1.0, abs(pdir)))
	elif pdir > 0.25:
		t = lerp(myGoal, myGoalR, smoothstep(0.25, 1.0, abs(pdir)))
	t.y = pele * 10
	
	
	myPlayer.shotcharge = rand_range(0.1, 0.95)
	myPlayer.shotcurl = Vector3(0.0, rand_range( - 0.2, 0.2), rand_range( - 0.2, 0.2))
	
	
	myPlayer.shotdir = t - Global.ballpos
	
	_shoot()
		
func tryFreeKick():
	var dir = Vector3.ZERO
	var curl = Vector3.ZERO
	
	
	if ( not myTeam.AIteam):
		dir = fkdir
		curl = fkcurl
		myPlayer.shotcharge = rand_range(0.25, 0.4)
	else:
		var r = rand_range(0, 1)
		if r > 0.5:
			dir = myGoalL - Global.ballpos
		else:
			dir = myGoalR - Global.ballpos
		
		dir.y = 19.0
		curl = Vector3(0, rand_range( - 0.25, 0.25), rand_range( - 0.5, 0))
		myPlayer.shotcharge = rand_range(0.3, 0.4)
	
	
	
	curl.y = - 2.0 * myPlayer.pCurl
	
	curl.z *= 3.5 * myPlayer.pCurl
	myPlayer.shotcurl = curl
	myPlayer.shotdir = dir
	_shoot()

func findPass():
	
	
	
	pos = myPlayer.translation
	if not _hasBall():
		return
	var bestscore = 0.05
	var bestplayer = null
	var smallestd = 50000.0
	var largestd = 0.0
	var closest2goal = 50000.0
	
	
	
	
	
	
	for i in range(Global.squad - 1, 0, - 1):
		if i != myPlayer.myID:
			var pscore = 0
			var mdg = myGoal - pos
			var tpt = myTeam.players[i].translation + myTeam.players[i].velocity * 0.1
			var dp = tpt - myPlayer.translation
			var dg = myGoal - tpt
			if myTeam.players[i].carded > 1 or (Global.elevenMode and myTeam._isOffsidePosition(myTeam.players[i])):
				pscore = - 10000
			else:
				
				var dgl = dg.length_squared()
				var dpl = dp.length_squared()
			
				if dgl < mdg.length_squared():
					pscore += 1
	
				
				if dpl < smallestd:
					pscore += 1.0 - (myTeam.tictacs)
					smallestd = dpl
	
				if dpl > largestd:
					pscore += (myTeam.tictacs)
					largestd = dpl
				
				if dgl < closest2goal:
					pscore += 1 + myTeam._counterBonus()
					closest2goal = dgl
	
				
				if abs(tpt.z) > 35 * Global.ps:
					pscore += (1.0 - myTeam.approach)
	
				if dp.x == myTeam.playDir:
					pscore += 1
	
			
				
				
			
				
				var dpn = dp.normalized()
				var facin = (dpn.dot( - myPlayer.transform.basis.z))
				facin = smoothstep( - 0.2, 1.0, facin)
				
				
				pscore += facin * 1.1
				
				
				pscore *= (facin)
				
			
				
				
				if pscore > bestscore and myTeam._checkPass(dpn, myPlayer, dpl):
				
					bestscore = pscore
					bestplayer = myTeam.players[i]
		
				
	if bestplayer != null:
		
		
	
				
		if (myPlayer.ball._isFree()):
			
			changeState(pstate.PLAYING)
			return
		
		myTeam._passTo(bestplayer)
		
		
		var pd = (bestplayer.translation + bestplayer.velocity * 0.2) - pos
		var pdl = pd.length_squared()
		if (pdl > 4900):
			pd = (bestplayer.translation + bestplayer.velocity * bestplayer.dSmart + (myGoal - bestplayer.translation) * 0.25) - pos
			pd *= 0.85
			
			myPlayer.canControl = false
			if Global.elevenMode:
				pd = myPlayer.chipTo(bestplayer)
			else:
				myPlayer.chipPass2(pd)
			bestplayer.AI._receivePass(pos, pd, 1)
			myTeam.opponent.pressTarget(bestplayer, true)
			yield(get_tree().create_timer(0.25), "timeout")
			myPlayer.canControl = true
			changeState(pstate.PLAYING)
	
		else:
			if true:
				myPlayer.canControl = false
				
				if myTeam.zone > 2 and rand_range(0.0, 1.0) < myTeam.tictacs:
		
					_thruPassAI(pd, bestplayer)
					bestplayer.AI._receivePass(pos, pd, 2)
				
				else:
					pd = (bestplayer.translation + bestplayer.velocity * bestplayer.dSmart + (myGoal - bestplayer.translation) * 0.05) - pos
					if Global.elevenMode:
						pd = myTeam._safePassSpot(pos + pd, bestplayer) - pos
		
			
					myPlayer.passBall(pd * 0.8)
					bestplayer.AI._receivePass(pos, pd, 0)
				
				
				myTeam.opponent.pressTarget(bestplayer, false)
				yield(get_tree().create_timer(0.25), "timeout")
				myPlayer.canControl = true
				changeState(pstate.PLAYING)
			else:
			
				if myPlayer.pSpeed <= myPlayer.pDSpeed:
					myPlayer._burst()
					myPlayer.myfx.emitting = Global.doParticles
		
		
	else:
		
		
		
		
		if myPlayer.pSpeed <= myPlayer.pDSpeed:
			myPlayer._burst()
			myPlayer.myfx.emitting = Global.doParticles
		
		

func _updatePosition():
	if not (myPlayer.isAI):
		return
	elif (state == pstate.POSESSION) and (myTeam.AIteam or (Global.pswitch > 1 and myPlayer.isAI)):
		
		
		
		
		if _moving():
			if (myTeam.zone > 2):
				var pz = abs(myPlayer.translation.z)
				var px = abs(myPlayer.translation.x)
				if pz > 40 * Global.ps:
					if px > 80 * Global.ps:
						
						
						myPlayer.chipPass(false)
					else:
						findPass()
				else:
					if px > 50.0:
						var deltashot = Helper.biLerp(2.0, 0.1, 0.75, 0.25, smoothstep(0, 40 * Global.ps, pz), smoothstep(50 * Global.ps, 110 * Global.ps, px))
						var ds = rand_range(0.0, 1.0)
						deltashot = max(deltashot, 0.45 * myPlayer.pLongShot)
					
						if ds < deltashot:
							tryShot()
						else:
							findPass()
			else:
				
				
				
				
				
				if myTeam.zone == 1 and myTeam._ballInBox():
				
					myPlayer.chipPass(false)
				else:
					findPass()
			
		
		
		
		
			

func _press():
	if not Global.gameOn or myPlayer.ball.player == myPlayer or myTeam.posession:
		return
	
	if (state != pstate.PCOLLECT) and state != pstate.INTERCEPT:
	
		changeState(pstate.PRESS)
func _intercept( var _targ, var long):
	if not Global.gameOn:
		return
	longpass = long
	changeState(pstate.INTERCEPT)
	
func _posession():
	
	myPlayer.dBurst = myPlayer.pBurst
	aavoid = Vector3.ZERO
	changeState(pstate.POSESSION)
	
	if (myPlayer.isAI):
		posessionState()
	
	
	
	marking = null
	myPlayer.posI.visible = Global.doPosInd



	
	
func _losePosession():
	marking = null
	
	changeState(pstate.PLAYING)
	myPlayer.canControl = false
	yield(get_tree().create_timer(0.2), "timeout")
	myPlayer.canControl = true
	myPlayer.shooting = false
	myPlayer.sp.visible = false
	myPlayer.posI.visible = false
	
		
func _celebrate(_goalscorer):
	changeState(pstate.CELEBRATE)
	
	if (myPlayer.myID == _goalscorer.myID):
		
		target = myTeam.Game.awayFans.translation
		atarget = target
		
	myPlayer.myATree["parameters/BlendCelebrate/blend_amount"] = 1
	
func _celebratePen():
	
		
	myPlayer.myATree["parameters/BlendCelebrate/blend_amount"] = 1
	

func _slide( var isH, var sdir):
	
	if not _moving():
		
		return
	
	movin = false
	myPlayer.tackledBall = false
	Global.game._slide()
	myPlayer.myAState.travel("slide")
	astate = "slide"
	myPlayer.myfx.emitting = Global.doParticles
	
	state = pstate.SLIDE
	
	isHuman = isH
	myPlayer.isAI = true
	
	slidevel = Vector3(sdir.x, 0.0, sdir.y) * myPlayer.pOSpeed * 1.25
	myPlayer.acc = slidevel
	
func _header( var isH):
	if not _moving() or myPlayer.ball._isCaught():
		return
	myPlayer.myAState.travel("header")
	astate = "header"
	myPlayer.canHead = true
	
	
	prevstate = state
	state = pstate.HEAD
	isHuman = isH
	myPlayer.isAI = true
	
	
	var jdir = (Global.ballpos + Global.ballvel * 0.23) - myPlayer.translation
	jdir.y = 0
	
	
	slidevel = jdir * 4.0
	slidevel = slidevel.limit_length(40.0)
func _bicycleKick( var isH):
	if not _moving() or myPlayer.ball._isCaught():
		return
	myPlayer.myAState.travel("bike")
	astate = "bike"
	prevstate = state
	state = pstate.BIKE
	myPlayer.isAI = true
	isHuman = isH
	
	var jdir = myPlayer.translation - (Global.ballpos + Global.ballvel * 0.3)
	jdir.y = 0
	
	slidevel = - jdir.normalized() * myPlayer.pOSpeed
	
func _divingHeader( var isH):
	if not _moving() or myPlayer.ball._isCaught():
		return
	
	myPlayer.myAState.travel("divingH")
	astate = "divingH"
	myPlayer.canHead = true
	
	prevstate = state
	state = pstate.DIVINGH
	isHuman = isH
	myPlayer.isAI = true
	
	
	var jdir = (Global.ballpos + Global.ballvel * 0.2) - (myPlayer.translation)
	jdir.y = 0
	
	slidevel = jdir.normalized() * myPlayer.pOSpeed * 1.0

	
func _tackled():
	
	
	Global.game._oof()
	isHuman = not myPlayer.isAI
	myPlayer.isAI = true
	prevstate = pstate.PLAYING
	state = pstate.TACKLED
	
	myPlayer.ball._ballFree()
	slidevel = myGoal - myPlayer.translation
	myPlayer.myAState.travel("fouled")
	astate = "fouled"
	vel = Vector3.ZERO
	slidevel = (pos - myGoal).normalized()
	slidevel.y = 0
	myPlayer.acc = Vector3.ZERO
	myPlayer.velocity = Vector3.ZERO
	
func _fouled():
	Global.game._oof()
	myTeam.Game.kickTaker = myPlayer
	prevstate = pstate.IDLE
	state = pstate.FOULED
	myPlayer.isAI = true
	myPlayer._say(1)
	
	myPlayer.phys.physical_bones_start_simulation()
	var fvel = myPlayer.velocity
	fvel.y = 0.1
	
	
	
	
	
	
	

	
	vel = Vector3.ZERO
	myPlayer.acc = Vector3.ZERO
	myPlayer.velocity = Vector3.ZERO
	slidevel = (myGoal - pos).normalized()
	slidevel.y = 0
	
	myPlayer.pOSpeed = max(10, myPlayer.pOSpeed - 1)
	yield(get_tree().create_timer(4), "timeout")
	myPlayer._say(2)
	state = pstate.IDLE
	myPlayer.phys.physical_bones_stop_simulation()
	
	
func _penalty():
	
	changeState(pstate.PENALTY)
	
	target = myTeam._getPenPosition(myPlayer.myID)
	
func _penaltyDefend():
	marking = null
	changeState(pstate.PENALTYDEFEND)
		
	target = myTeam._getPenDPosition(myPlayer.myID)
	
func _fouledDone():
	myPlayer.tackled = false
	state = prevstate
func _conceded():
	changeState(pstate.CONCEDED)
	if rand_range(0.0, 1.0) > 0.1:
		myPlayer.myAState.set("parameters/StateMachine/concede/concedeSeek/seek_position", rand_range(0.0, 3.0))
		myPlayer.myAState.travel("concede")
		astate = "concede"
	else:
		myPlayer.myAState.travel("idle")
		astate = "idle"
	slidevel = - myPlayer.transform.basis.z
func _missed():
	state = pstate.CONCEDED
	slidevel = - myPlayer.transform.basis.z
	myPlayer.myAState.travel("concede")
	astate = "concede"

func _moving():
	
	if state == pstate.HEAD or state == pstate.SHOOT or state == pstate.SLIDE or state == pstate.TACKLED or state == pstate.FOULED or state == pstate.THROWIN or state == pstate.DIVINGH or state == pstate.BIKE or state == pstate.ACTION or state == pstate.CONCEDED:
		return false
	else:
		return true
func _canControl():
	
	if state == pstate.HEAD or state == pstate.SHOOT or state == pstate.TACKLED or state == pstate.FOULED or state == pstate.THROWIN or state == pstate.DIVINGH or state == pstate.BIKE or state == pstate.ACTION:
		return false
	return true

func _shoot():
	
	
	if not _moving():
		return
	
	slidevel = myPlayer.velocity * 0.5
	prevstate = pstate.PLAYING
	state = pstate.SHOOT
	myPlayer.myAState.travel("shot")
	astate = "shot"
	
func _volley():
	if not _moving():
		return
	
	slidevel = myPlayer.velocity
	prevstate = pstate.PLAYING
	state = pstate.SHOOT
	myPlayer.myAState.travel("scissor")
	astate = "scissor"
	
func _kickoff():
	myPlayer.myATree["parameters/BlendCelebrate/blend_amount"] = 0
	if (myPlayer.carded < 2):
		changeState(pstate.IDLE)
		prevstate = pstate.IDLE
	myPlayer.isAI = true
	myPlayer.replay = false
	marking = false
	
func _mark():
	changeState(pstate.MARK)
	myPlayer.isAI = true


func _kickTaker( var ktype, var ifk):
	
	isShoot = ktype
	isFK = ifk
	target = Global.ballpos
	atarget = target
	myPlayer.pSmart = 1
	
	
	
	
	
	
	
	
	
	state = pstate.KICKER
func _freeKickTaker( var ktype, var ifk):
	
	isShoot = ktype
	isFK = ifk
	isSP = true
	
	
	myPlayer.pSmart = 1
	
	myPlayer.shotdir = fkdir
	myPlayer.shotcurl = fkcurl
	if not isFK:
		if ( not myTeam.AIteam):
			
			
			pdir = fkdir.z
			pele = fkdir.y
		else:
			pdir = rand_range( - 1, 1)
			pele = rand_range(0, 1)
		
		myPlayer.myTeam.Game.penTarget.translation = Vector3(0.0, max(2.0, pele * 8), - pdir * 14.0)
	else:
		fkdir.y *= 1.1
	
	yield(get_tree().create_timer(0.5), "timeout")
	target = Global.ballpos
	atarget = target
	
	state = pstate.KICKER
	
	
	

func _throwTaker( var _ktype, _ifk):
	
	changeState(pstate.THROWIN)
	movin = false
	myPlayer.myAState.travel("throw")
	astate = "throw"
	

func _takeThrow( var ppos):
	target = ppos
	myPlayer.pSmart = 1
	changeState(pstate.PICKUP)
	
	
func _throwBall():

	myPlayer.canControl = false
	tryFKPassTarget()
	changeState(pstate.PLAYING)
	myTeam.throwTarget = null
	yield(get_tree().create_timer(0.4), "timeout")
	
	myPlayer.canControl = true

func intersectShot(dir):
	var N = pos - Global.ballpos
	N = - N.normalized()
	var t = (pos - Global.ballpos).dot(N) / (dir.dot(N))
	
	return Global.ballpos + t * dir
	
func _blockShot( var _bpos, var dir):
	
	
	
	var dp = myPlayer.translation - Global.ballpos
	var bv = dir.normalized()
	var sp = Global.ballpos + Global.ballvel * 0.2 + (dp.dot(bv) * bv)
	
	sp = pos - sp
	
	var blockRange = lerp(10.0, 20.0, myPlayer.pBlock) if myPlayer.blockRated else 10.0
	if (sp.length_squared() < blockRange * blockRange):
		sp = - sp.normalized()
		_slide(false, Vector2(sp.x, sp.z))
	
func _pause():
	changeState(pstate.IDLE)
	myPlayer.isAI = true
	myPlayer.replay = false
	
func _replay():
	if state == pstate.SENTOFF:
		return
	myPlayer.posI.visible = false
	state = pstate.REPLAY
	prevstate = pstate.REPLAY
	myPlayer.isAI = true
	myPlayer.replay = true
	myPlayer.myATree["parameters/BlendCelebrate/blend_amount"] = 0


func _checkLineup():
	if state == pstate.KICKER or state == pstate.HOLDING or state == pstate.PICKUP or state == pstate.THROWIN or state == pstate.MARK or state == pstate.ACTION or state == pstate.SLIDE:
		return
	if state != pstate.IDLE and myPlayer.carded < 2:
		changeState(pstate.IDLE)


func _updateData(p, v):
	pos = p
	vel = v
	
	

func _setData():
	
	myPlayer.acc += vel
	myPlayer.target = target
	
	
func _update():
	atarget = target
	if Global.elevenMode and myPlayer.pBallWin > 0.0:
		_readPassingLane()
	stateFunc[state].call_func()
	vel += aavoid
	_setData()
	
	aavoid *= 0.98
	
	
	
		
func _updateVel():
	
	var _close = seek(atarget)

	if state == pstate.POSESSION:
		vel += aavoid
	_setData()
	aavoid *= 0.98
	

	
	
func _isThrow():
	return state == pstate.HOLDING
func _hasBall():
	return state == pstate.POSESSION
func _marking():
	return state == pstate.MARK
	
func _on_ThreatArea_body_entered(_body):
	
	if not Global.gameOn:
		return
		
	if _body == myPlayer.ball and myPlayer.ball._isFree():
		target = Global.ballpos + Global.ballvel * 0.1


func _on_DangerZone_body_entered(body):
	if ( not _moving()) or (body != myPlayer.ball) or not (Global.gameOn) or not myPlayer.ball._canHead() or not myTeam.AIteam or not myPlayer.canControl:
		return
	
	var p = Global.ballpos + Global.ballvel * 0.1
	var pd = (p - myPlayer.translation).length_squared()
	var bdot = Global.ballvel.normalized().dot( - myPlayer.transform.basis.z.normalized())

















	var clp = Helper.pointToLine(Global.ballpos, Global.ballpos + Global.ballvel * 0.3, pos, 1.0)
	var headReach = lerp(7.4, 5.0, myPlayer.pAerial) if myPlayer.aerialRated else 6.0
	if clp.y > headReach and bdot < 0.7:
		
		if (myTeam.AIteam) and (state != pstate.PCOLLECT) and state != pstate.INTERCEPT:
			_header(false)
	elif myTeam.zone == 3:
		if clp.y > 4 and clp.y < 5 and pd < 500 and bdot < 0.7:
			if (state != pstate.PCOLLECT) and state != pstate.INTERCEPT:
				_divingHeader(false)
		elif (p - myPlayer.translation).length_squared() < 9:
			print("dz first time shot!")
			tryVolley()
	


	
	
			
	elif state == pstate.PLAYING and not myTeam.momentum:
		changeState(pstate.PRESS)

func _shootout():
	
	
	marking = null
	state = pstate.IDLE
	myPlayer.myATree["parameters/BlendCelebrate/blend_amount"] = 0
	
	
	target = myTeam._getShootoutPosition(myPlayer.myID)
	
	myGoal = myTeam.goal
	myGoalL = myTeam.goalL
	myGoalR = myTeam.goalR
	
	
func _penaltyTaker():
	
	var random = RandomNumberGenerator.new()
	random.seed = myTeam.teamID + myPlayer.myID
	target = Vector3( - 90 * Global.ps, 0, random.randf_range( - 5, 5))
	
func _setBenched( var i):
	state = pstate.BENCH
	prevstate = pstate.BENCH
	var pli = i - 7
	myPlayer.canControl = false
	myPlayer.set_physics_process(false)
	myPlayer.set_process(false)
	myPlayer.myAState.travel("bench")
	astate = "bench"
	var offset = 1.0
	if myTeam.teamID > 1:
		offset = - 1
	myPlayer.translation = Vector3((15 * offset) + offset * (pli * 4), 0, - 98)
	
	myPlayer.look_at(Vector3(0, 1, 0), Vector3.UP)
	
	myPlayer.myRoot._bibOn()
func _subOff( var pid):
	
	var offset = 1.0
	if myTeam.teamID > 1:
		offset = - 1
	
	changeState(pstate.IDLE)
	var pli = pid - 7
	
	target = Vector3((15 * offset) + offset * (pli * 4), 0, - 98)
	
func _subOn( var _pid):
	
	myPlayer.myRoot._bibOff()
	
	changeState(pstate.IDLE)
	target = Vector3(0, 0, - 60 * Global.ps)
	myPlayer.set_process(true)
	myPlayer.set_physics_process(true)
func _offField( var pid):
	
	if (myPlayer.translation - target).length() < 6:
		
		_setBenched(pid)
		return true
	return false
func _onField():
	if (myPlayer.translation - target).length() < 4:
		return true
func benchState():
	pass
	
func offState():
	var c = seek(target)
	if c < 3:
		changeState(pstate.BENCH)
		myPlayer.set_physics_process(false)
		myPlayer.translation = Vector3(1000, 1000, 1000)
		myPlayer.visible = false
		myPlayer.set_process(false)
	
		myPlayer.myTeam.Game._doneBooking()
func _sentOff():
	state = pstate.ACTION
	myPlayer.myAState.travel("concede")
	astate = "concede"
	slidevel = Vector3.ZERO
	yield(get_tree().create_timer(3), "timeout")
	state = pstate.SENTOFF
	target = Vector3(0, 0, 100 * Global.ps)
func _winner():
	state = pstate.IDLE
	var off = 0
	if myPlayer.myID > Global.squad - 1:
		off = 5
	target = Vector3(55 + (myPlayer.myID % 6) * 4.0, 0, 45 - off)
	
func _firstTimeShot():
	isFK = false
	if state == pstate.SLIDE:
		var sdir = (Vector3(0, 0.25, 0) - transform.basis.z + 0.1 * (myGoal - Global.ballpos)) * 30
		myPlayer.ball._tapBall(sdir, myPlayer)
		myTeam._shot(myPlayer.myID, sdir, Vector3.ZERO, 0)
		return true
	elif myTeam.AIteam:
		
		if _moving() and sign(myPlayer.transform.basis.z.x) != sign(myTeam.playDir):
			var pz = abs(myPlayer.translation.z)
			var px = abs(myPlayer.translation.x)
			var deltashot = Helper.biLerp(1.5, 0.0, 0.25, 0.25, smoothstep(0, 40 * Global.ps, pz), smoothstep(65 * Global.ps, 130 * Global.ps, px))
			if rand_range(0, 1) < deltashot:
				changeState(pstate.POSESSION)
				tryVolley()
				
				return true
			return false
	return false
func _firstTimeClearance():
	if myTeam.AIteam:
		
		if _moving():
			
			var sdir = sign( - myPlayer.transform.basis.z.z)
			myPlayer.ball._tapBall((Vector3(0, 0.5, 0) + (sdir * myPlayer.transform.basis.x * rand_range(0.5, 1.0))) * 40, self)
			
			
			changeState(pstate.PRESS)
			return true
		return false
	return false
func _bookMe():
	if myTeam.AIteam:
		return
	else:
		myPlayer._controlMe()
func _markThrowtarget( var t):
	marking = t
	myPlayer.indicator.visible = true

func _lapOfHonour():



	state = pstate.LAP
	target = myTeam._getLapTarget(cCelebTarget) + Vector3(xct * 10.0, 0.0, yst * 10.0)
func lapState():
	
	var close = seek(target)
	if close < 20:
		cCelebTarget = (cCelebTarget + 1) % 4
		target = myTeam._getLapTarget(cCelebTarget) + Vector3(xct * 10.0, 0.0, yst * 10.0)
	view = target
	atarget = target
func _celebrating():
	return state == pstate.CELEBRATE
func _celebrateAnim( var a):
	
	myPlayer.myATree["parameters/BlendCelebrate/blend_amount"] = 0
	var s = ""
	match a:
		0:
			s = "celebslide"
		1:
			s = "archer"
		2:
			s = "fouled"
		3:
			s = "somersault"
	myPlayer.myAState.travel(s)
	astate = s
	myTeam.celeb = min(a + 1, 3)
	state = pstate.ACTION
	prevstate = pstate.CELEBRATE
	slidevel = myPlayer.velocity
func _idle():
	if astate == "idle" or astate == "newidleclap":
		return
	else:
		astate = "idle"
		myPlayer.myAState.travel("idle")

# Used by Game.throwSetup when the thrower never reaches the ball: put him on the
# spot holding it, exactly as pickupState does when he arrives.
func _forcePickup(ppos):
	var inward = Vector3(0, 0, - sign(ppos.z)) * 1.5
	myPlayer.translation = Vector3(ppos.x, myPlayer.translation.y, ppos.z) + inward
	myPlayer.velocity = Vector3.ZERO
	myPlayer.acc = Vector3.ZERO
	movin = false
	myPlayer.ball._initialize()
	myPlayer.myAState.travel("pickup")
	astate = "pickup"
	state = pstate.HOLDING
	target = ppos
	atarget = myPlayer.ball.translation
	slidevel = pos.normalized()
