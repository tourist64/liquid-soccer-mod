extends Spatial


var myPlayer
var myGoal
var myGoalR
var myGoalL
var dGoal
var myTeam
var pos
var vel
var view
var shotview
var target = Vector3.ZERO
var atarget = null
var AIKeeper = true
var isHuman = false
var shooter
var shotDir = Vector3.UP
var shottype = 0
var diveframe
var diveUp = Vector3.UP
var isUp = false
var divedir = 1
var diving = false
var divevel = Vector3.ZERO
var dcount = 0
var flip = 1
var pen = false
var fk = false
var dview = Vector3.ZERO
var ball = null
var DZ = false
var fkdir = Vector3.ZERO
var fkcurl = Vector3.ZERO
var isFK = false
var doKick = true
var lineupcount = 0
var longTarget = Vector3.ZERO

enum pstate{IDLE, PCONTROL, DEFEND, SUPPORT, PRESS, POSESSION, CELEBRATE, REPLAY, INCOMING, LONGSHOT, DIVE, CONCEDE, PENALTY, ACTIVE, CAUGHT, CLEARING, INCROSS, KICKER, SHOOTACTIVE, SHOOTOUT, LAP}
# Where the current dive should stop sliding sideways (see Keeper.gd); off for penalties.
var diveStopOn = false
var diveStopZ = 0.0
var diveStopPoint = Vector3.ZERO
var diveStopDir = Vector3.ZERO
# Shot dives keep reading the ball and steer onto it (Keeper.gd); how far short his feet aim.
var diveTrack = false
var diveReach = 0.0
var stateFunc = {}
var state
var tostate
var cCelebTarget = 0


var debugtarget = null


func _ready():
	
	state = pstate.IDLE
	tostate = pstate.DEFEND
	stateFunc[pstate.IDLE] = funcref(self, "idleState")
	stateFunc[pstate.SUPPORT] = funcref(self, "supportState")
	stateFunc[pstate.DEFEND] = funcref(self, "defendState")
	stateFunc[pstate.PRESS] = funcref(self, "pressState")
	stateFunc[pstate.POSESSION] = funcref(self, "posessionState")
	stateFunc[pstate.CELEBRATE] = funcref(self, "celebrateState")
	stateFunc[pstate.REPLAY] = funcref(self, "replayState")
	stateFunc[pstate.DIVE] = funcref(self, "diveState")
	stateFunc[pstate.INCOMING] = funcref(self, "incomingState")
	stateFunc[pstate.INCROSS] = funcref(self, "inCrossState")
	stateFunc[pstate.LONGSHOT] = funcref(self, "longShotState")
	stateFunc[pstate.CONCEDE] = funcref(self, "replayState")
	stateFunc[pstate.PENALTY] = funcref(self, "penaltyState")
	
	stateFunc[pstate.PCONTROL] = funcref(self, "checkInput")
	stateFunc[pstate.ACTIVE] = funcref(self, "activeState")
	stateFunc[pstate.CAUGHT] = funcref(self, "caughtState")
	stateFunc[pstate.CLEARING] = funcref(self, "clearingState")
	stateFunc[pstate.KICKER] = funcref(self, "kickerState")
	stateFunc[pstate.SHOOTACTIVE] = funcref(self, "activeState")
	stateFunc[pstate.SHOOTOUT] = funcref(self, "shootoutState")
	stateFunc[pstate.LAP] = funcref(self, "lapState")
	
	
func _initialize( var team, var goal, var _goall, var _goalr, var dgoal):
	myPlayer = get_parent()
	myTeam = team
	myGoal = goal
	dGoal = dgoal
	ball = myPlayer.ball
	myPlayer.pTSmart = lerp(0.02, 0.2, myPlayer.pTSmart * 0.1)
	debugtarget = myPlayer.get_parent().get_node("DebugTarget")
	
	
	if not myTeam.AIteam:
		myPlayer.catchDistance = 13000

func _quadratic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r

func seek():
	
	
	var diff = (target - pos)

	var dl = diff.length()
	var speed = smoothstep(0, 4, dl * 1.0)
	var quick = 1.0
	# Sharp keepers (rated above 8.5) keep level with the ball: quicker feet, and they only
	# ease off right on their spot.
	if myPlayer.get_meta("sharpKeeper") if myPlayer.has_meta("sharpKeeper") else false:
		speed = smoothstep(0, 1.5, dl)
		quick = SHARP_FOOTWORK
	if dl > 0.1:
		vel = (diff / dl) * myPlayer.pAgility * speed * quick
	
	view = Global.ballpos
	return dl
	
	
func setTarget(tgt):
	target = tgt

func moveKeeperIntersect():
	if ball._isShooting():
		var hitp = intersectShot(Global.ballvel.normalized())
		hitp.y = 0.1
		hitp += ball.curl.z * Vector3(0.0, 0.0, 1.0) * - 1.75 * flip
		
		target = hitp
		view = Global.ballpos
	else:
		moveKeeper()
# Top keepers (rushClass, set in Team.setPlayerParams) come out up to 40% further and close the
# shooter down to 65% of the way instead of halfway, leaving a smaller angle.
const RUSH_EXTRA = 0.4
const RUSH_CLOSE = 0.65
const NEAR_POST_SHADE = 0.12
const NEAR_POST_MAX = 5.0
const LONG_DIVE_DIST = 45.0
const LONG_DIVE_MIN = 30.0
const HEADER_DIVE = 0.85
const SHARP_FOOTWORK = 1.35
func moveKeeper():
	
	if (AIKeeper == false) and Input.is_action_pressed(myPlayer.cthru) and not myTeam.posession:
		myPlayer.pAggression = min(abs(Global.ballpos.x + 5), myPlayer.pAggression + 0.5)
		myPlayer.pAggression = min(abs(dGoal.x - Global.ballpos.x), min(48, myPlayer.pAggression))
	elif DZ:
		var rush = myPlayer.get_meta("rushClass") if myPlayer.has_meta("rushClass") else 0.0
		myPlayer.pAggression += myPlayer.pAgg * 0.6 * (1.0 + rush)
		var toball = dGoal - (Global.ballpos + Global.ballvel * 0.02)
		myPlayer.pAggression = min(toball.length(), min(lerp(36.0, 20.0, abs(toball.normalized().z)) * (1.0 + RUSH_EXTRA * rush), myPlayer.pAggression))
		if sign(Global.ballvel.x) == sign(myTeam.playDir):
			myPlayer.pAggression -= 0.25
	elif (myPlayer.pAggression > myPlayer.pDAggression):
			myPlayer.pAggression -= 0.5
	elif myPlayer.pAggression < myPlayer.pDAggression:
			myPlayer.pAggression += 0.5
			
	
	
	
	
	var look = myPlayer.pTSmart
	if Global.ballpos.y > 3:
		look = 0.3
	
	var atme = abs((Global.ballpos - pos).normalized().dot(Global.ballvel.normalized()))
	
	
	look = lerp(look, 0.0, atme)
	
	var bpos = Global.ballpos + Global.ballvel * look
	
	if (bpos - dGoal).length_squared() < (myPlayer.pAggression * myPlayer.pAggression):
		# Close in on the ball: halfway for an ordinary keeper, closer for a top one.
		var rushIn = myPlayer.get_meta("rushClass") if myPlayer.has_meta("rushClass") else 0.0
		myPlayer.pAggression = max((bpos - dGoal).length() * lerp(0.5, RUSH_CLOSE, rushIn), 1.0)
	myPlayer.pAggression = max(1.0, myPlayer.pAggression)
	
	target = dGoal + (bpos - dGoal).normalized() * myPlayer.pAggression
	if (Global.elevenMode or myTeam.tdata.sweeperKeeper > 0.0) and _shouldSweep():
		target = Global.ballpos + Global.ballvel * 0.3
	
	# Shade towards the near post when the ball is wide, more for top keepers, so a shot
	# squeezed in at the near post has less room.
	var side = Global.ballpos.z - dGoal.z
	target.z += sign(side) * min(abs(side) * NEAR_POST_SHADE, NEAR_POST_MAX) * (0.4 + 0.6 * min(_rushClass(), 1.0))
	target.y = 0
	target.x = sign(target.x) * min(135.0 * Global.ps, abs(target.x))
	
	view = Global.ballpos




func idleState():
	var close = seek()
	view = target
		
	if (close < 5):
		view = Global.ballpos
		
		var sc = close / 5.0
		vel *= sc
		myPlayer.velocity *= sc
	view.y = 0.25
func longShotState():
	
	
	
	# Keep reading the shot as it flies (it may be curling), allowing for the swing like the
	# close-range dive does.
	var tArr = 0.0
	if ball._isShooting():
		var lt = _shotClosest(pos)
		tArr = predT
		lt.y = 0
		lt.x = clamp(lt.x, - 135.0 * Global.ps, 135.0 * Global.ps)
		longTarget = lt
	# Every keeper goes into a full dive at a long shot once it's close enough (reading the curl
	# like any dive), not just a run: from 30 units for an ordinary keeper to 45 for the best.
	# A slow one (bouncing, rolling) also has to be close in time, or he'd be down too early.
	if ball._isShooting() and (Global.ballpos - pos).length() < lerp(LONG_DIVE_MIN, LONG_DIVE_DIST, min(_rushClass(), 1.0)) and tArr <= _diveLeadTime() and not _diving():
		dcount = 1
		changeState(pstate.INCOMING)
		return
	target = longTarget
	var _close = seek()
	# Get across to a long shot quickly: 20% faster for every keeper, up to 80% for the best.
	vel *= 1.2 + 0.6 * _rushClass()
	
	view = Global.ballpos
	debugtarget.translation = longTarget
	
func penaltyState():
	var _close = seek()
	view = Global.ballpos
	view.y = 0.25


func activeState():
	
	if ( not Global.gameOn) or ( not myPlayer.canControl):
		view = Global.ballpos
		vel = Vector3.ZERO
		myPlayer.velocity *= 0.1
		
		return
	var db = (Global.ballpos + (Global.ballvel * 0.1) - pos).length()






	if not _diving():
		
		# Loose balls in the box: claim them from further away and at a higher pace than before.
		# With an attacker on the ball he stays patient (the old range), so he isn't sold diving
		# at a dribbler's feet and left on the floor for the shot.
		var loose = ball._isFree()
		var claimPace = BOX_CLAIM_PACE if loose else 30.0
		var claimDist = BOX_CLAIM_DIST if loose else 12.0
		if Global.ballvel.length() < claimPace and (db < claimDist) and (db > (3 if loose else 4)) and ( not myTeam.posession) and myTeam._ballInBox():
			
			state = pstate.DIVE
			tostate = pstate.ACTIVE
			shooter = Global.ballpos
		
			var look = 0.24
			myPlayer.canSave = true
			myPlayer.canControl = true
			if ball._isFree():
		
				look = 0.12
				target = Global.ballpos + Global.ballvel * look
			
				if sign(Global.ballvel.z) == sign(myTeam.playDir):
			
					myPlayer.myAState.travel("collectR")
				else:
			
					myPlayer.myAState.travel("collectL")
			else:
				look = 0.12
				target = Global.ballpos + Global.ballvel * look
			
				if sign(ball.player.transform.basis.z.z) == sign( - myTeam.playDir):
			
					myPlayer.myAState.travel("collectR")
				else:
			
					myPlayer.myAState.travel("collectL")
				
		
			divevel = (target - pos).normalized() * myPlayer.pDiveSpeed * 0.9
			diveTrack = false
			_setDiveStop(target)
			shotview = pos + divevel
			view = shotview
			
	
		elif Global.ballpos.y > 4 and db < 14.0 and ball._isCrossing():
		
			
			divevel = ((Global.ballpos + Global.ballvel * 0.25) - pos).normalized() * myPlayer.pDiveSpeed * 0.95
			divevel.y *= 2.0
			divevel.x *= 3.0
			diveTrack = false
			_setDiveStop(Global.ballpos + Global.ballvel * 0.25)
			diving = true
			myPlayer.canControl = true
			myPlayer.myAState.travel("diveUp")
			state = pstate.DIVE
			tostate = pstate.ACTIVE
			view = Global.ballpos
			view.y = 1.0
			shotview = view
		else:
			moveKeeperIntersect()
			var _close = seek()
			view = Global.ballpos
			view.y = 0.25

func supportState():
	
	moveKeeper()
	seek()
	view = Global.ballpos

func defendState():
	
	moveKeeper()
	seek()
	view = Global.ballpos
	
func pressState():
	
	target = Global.ballpos
	target.y = 0
	var _close = seek()
	if _close > 20:
		
		myTeam.setDefend()
func tryPass( var isThrow):
	
	
	
	
	var passTo = myTeam._findPass(pos, myPlayer.transform.basis.z, 0)
	if (passTo):
		myPlayer.canControl = false
		myPlayer.myATree["parameters/CaughtBall/blend_amount"] = 0
		
		var mul = 1.0
		
		if not isThrow:
			myTeam.passDir.y += 2
		else:
			myTeam.passDir.y -= 2
			mul = 0.25
		myPlayer.ball._passBall(myTeam.passDir * mul, self)
		myTeam.posession = false
		myTeam.momentum = true
		myTeam.opponent.momentum = false
		if Global.pswitch == 1:
			myTeam._switchPControl(myTeam.passto)
		
		
func _goesLong():
	return myPlayer.has_meta("longKeeper") and myPlayer.get_meta("longKeeper")

func tryLongPass():
	
	
	myTeam._findLongPass(pos, myPlayer.transform.basis.z, myPlayer.myID)
	
	myPlayer.myATree["parameters/CaughtBall/blend_amount"] = 0
	myTeam.passDir.y += rand_range(80, 100)
	myPlayer.ball._passBall(myTeam.passDir * rand_range(0.5, 0.7), self)
	
	myTeam.posession = false
	myTeam.momentum = true
	myTeam.opponent.momentum = false
	
	myTeam.opponent.setDefend()
	
	myTeam._switchPControl(myTeam.passto)
func posessionState():
	
	target = myTeam._getSupportPos(0)
	target.y = 0
	if not _diving():
		if _hasBall():
			var close = seek()
			if (close < 8) and not (diving):
				if _goesLong():
					tryLongPass()
				else:
					tryPass(false)
			view = vel
	
		
	
			
func caughtState():
	
	
	
	if not _diving() and ball._isCaught():
		var close = seek()
		if (close < 8):
			if rand_range(0.0, 1.0) > myTeam.tictacs and not _goesLong():
				
				_throwOut()
			else:
				_clearBall()
				view = divevel
		else:
			view = target
			divevel *= 0.5
	else:
		divevel *= 0.93
		view = divevel
		
func diveState():
	
	vel = divevel
	
	view = shotview
	
	
	
	
		
func celebrateState():
	if myTeam.Game.goalscorer:
		target = myTeam.Game.goalscorer.translation - Vector3(4, 0, 4)
		
	
	
	var _close = seek()
	view = target
	
	if _close < 8:
		view = myTeam.Game.goalscorer.translation



func shootoutState():
	var close = seek()
	view = target
		
	if (close < 5):
		view = Global.ballpos
		
		var sc = close / 5.0
		vel *= sc
		myPlayer.velocity *= sc
	view.y = 0.25
func inCrossState():
	
	var v = (Global.ballpos) - (myPlayer.translation)
	var R = (Global.ballvel).normalized()
	var t0 = R.dot(v)
	var intP = Global.ballpos - t0 * R
	if intP.y < 8:
		intP.y = 1
		target = intP
	else:
		target = dGoal * 0.95
	
	seek()
	view = target
func kickerState():
	var close = seek()
	
	if (close < 2.0) and myPlayer.canControl:
		myPlayer.canControl = false
		
		var r = rand_range(0, 1)
		if r > myTeam.tictacs and not _goesLong():
			tryPass(false)
		else:
			tryLongPass()
		
		yield(get_tree().create_timer(0.5), "timeout")
		myPlayer.canControl = true
		fChangeState(pstate.ACTIVE)
		
		
	
# Where a shot will actually cross the plane x = planeX, simulating the ball's own flight. The
# model was fitted to the real ball (Bullet physics, measured in a headless run of the engine):
# the curl push SmartBall applies every frame while shooting (curl.z sideways, fading 2% a frame;
# curl.y up/down), gravity (20 x gravity_scale 2), its air damping, the extra drag SmartBall puts
# on curled shots, bounces that keep half the vertical pace but scrub horizontal pace off with
# ground friction (and cut the curl, like SmartBall does on contact), and a rolling ball losing
# pace along the grass. Before, bounces and rolling were barely slowed, so low driven and
# bouncing shots arrived much later than he expected. predT is set to the seconds until then.
var predT = 0.0
var shotFrame = - 100
const BALL_REST_Y = 0.76
const SIM_FRAMES = 240
func _predictShot(planeX):
	if abs(_shotStartVel().x) < 1.0:
		predT = 0.0
		return intersectShot(Global.ballvel)
	return _simShot(planeX, null)

# The point where the shot passes closest to `near` (flat, ignoring height), up to the goal line,
# with predT the seconds until then. A shot across him from a tight angle (a near-post ball from
# beside or level with him) may never cross his own line, so reading it at x = his x sent him
# to wherever the ball was after four seconds: the wrong way, or nowhere.
func _shotClosest(near):
	return _simShot(dGoal.x, near)

func _shotStartVel():
	var v = ball.linear_velocity
	# Right as a shot is struck the kick hasn't reached the ball's velocity yet (it lands next
	# physics step), so read the shot from the kick itself; otherwise the keeper "predicted" the
	# ball where it stood and dived towards the shooter. Only then: a shot that has since slowed
	# on the grass was being read along its original line, not where it had curled to.
	if Engine.get_physics_frames() - shotFrame <= 2 and shotDir != null and typeof(shotDir) == TYPE_VECTOR3 and v.length() < shotDir.length() * 0.5:
		v = shotDir
	return v

func _simShot(planeX, near):
	var p = ball.translation
	var v = _shotStartVel()
	var shooting = ball.state == ball.bstate.SHOOTING or (Engine.get_physics_frames() - shotFrame <= 2)
	var crossing = ball.state == ball.bstate.CROSSING
	var curl = ball.curl
	var cz = curl.z
	var cy = curl.y
	var drag = ball.drag if shooting and typeof(ball.drag) == TYPE_VECTOR3 and ball.drag != Vector3.ZERO else Vector3.ONE
	var rest = min(BALL_REST_Y, p.y)
	var dt = 1.0 / 60.0
	var best = p
	var bestT = 0.0
	var bestD = 1e9
	if near != null:
		bestD = Vector2(p.x - near.x, p.z - near.z).length()
	for i in range(SIM_FRAMES):
		if shooting:
			var left = v.normalized().cross(Vector3.UP)
			if v.x < 0.0:
				left = - left
			v += (cz * left + cy * Vector3.UP) * dt * 50.0
			cz *= 0.98
		elif crossing:
			v += curl * dt * 50.0
			curl *= 0.98
		v.y -= 40.0 * dt
		v *= 1.0 - 0.3 * dt
		v.x *= drag.x
		v.z *= drag.z
		var np = p + v * dt
		if np.y <= rest:
			np.y = rest
			if v.y < - 3.0:
				var vin = - v.y
				v.y = vin * 0.5
				var hl = Vector2(v.x, v.z).length()
				if hl > 0.01:
					var k = (hl - min(vin * 1.5, hl * 2.0 / 7.0)) / hl
					v.x *= k
					v.z *= k
				cz *= 0.2
				cy *= 0.2
				curl *= 0.2
			else:
				v.y = 0.0
				var hs = Vector2(v.x, v.z).length()
				if hs > 0.01:
					var k2 = max(hs - min(0.61, hs * 0.0145), 0.0) / hs
					v.x *= k2
					v.z *= k2
		var crossed = sign(np.x - planeX) != sign(p.x - planeX)
		var kx = 1.0
		if crossed:
			kx = (planeX - p.x) / (np.x - p.x)
		if near == null:
			if crossed:
				predT = (i + kx) * dt
				return p + (np - p) * kx
		else:
			# Closest point of this step's segment (only up to the goal line).
			var a = Vector2(p.x - near.x, p.z - near.z)
			var b = Vector2(np.x - p.x, np.z - p.z) * kx
			var bl = b.length_squared()
			var t = 0.0
			if bl > 0.000001:
				t = clamp(- a.dot(b) / bl, 0.0, 1.0)
			var d = (a + b * t).length()
			if d < bestD:
				bestD = d
				best = p + (np - p) * kx * t
				bestT = (i + kx * t) * dt
			elif d > bestD + 1.0 or crossed:
				break
			if crossed:
				break
		p = np
	predT = bestT if near != null else SIM_FRAMES * dt
	return best if near != null else p

func intersectShot(shdir):
	var nvel = shdir.normalized()
	
	if abs((Global.ballpos + shdir * 0.02).x) > abs(pos.x):
		
		return Global.ballpos + shdir * 0.1
		
	
	
	
	
	var a = myPlayer.translation - Global.ballpos
	var al = a.length()
	var ca = (a / al).dot(nvel)
	
	var t = 1.0
	if ca > 0.001:
		t = al / ca
	
	
	return Global.ballpos + abs(t) * nvel
	
func incomingState():
	
	
	var velval = myPlayer.pDiveAgile * 0.6 * (myPlayer.get_meta("diveFast") if myPlayer.has_meta("diveFast") else 1.0)
	# Headers (shot types 3 and 4) are close and sudden: every keeper is a step slower to them,
	# so a good corner header is a real chance even against Neuer.
	if shottype == 3 or shottype == 4:
		velval *= HEADER_DIVE
	
	isUp = false
	dview = Global.ballpos
	myPlayer.canSave = true
	
	
	
	var R = Global.ballvel
	if pen:
		R = shotDir
		
	
	
	
	
	var shotvel = R.length()
	if pen:
		if shotvel < 90 and (dcount > 0):
			changeState(pstate.ACTIVE)
			return
	elif dcount > 0 and (shotvel < BOX_CLAIM_PACE or (shotvel < 90 and not _onTarget())):
		# Picked up late (into his area, or a long shot getting close): only a ball slow enough
		# to claim, or a soft one going wide, is left to the ordinary play. Before, anything
		# under 90 was, and low, bouncing and placed shots lose a lot of pace on the grass: they
		# came in at 50 to 90, too quick to claim, and he just watched them go past him.
		changeState(pstate.ACTIVE)
		return
	
	var intP = intersectShot(R)
	var left = myPlayer.transform.basis.x
	
	if pen:
		if dcount > 0:
			intP += ball.curl.z * left * - 1.75 * flip
			intP += ball.curl.y * Vector3.UP
		else:
			intP += ball.curl.z * left * - 1.85 * flip
	else:
		# Read the real flight, curl, dip and bounces included: where it passes closest to him.
		intP = _shotClosest(pos)
	var tArr = predT
	intP.y = max(intP.y, 0.1)
	# A slow (bouncing, rolling) shot still a long way off: keep going across and dive when it's
	# close in time, as for a long shot. Diving at once left him down on the grass before it got
	# there.
	if not pen and tArr > _diveLeadTime():
		longTarget = intP
		longTarget.y = 0
		state = pstate.LONGSHOT
		return
	
	divedir = 0
	
	if (pen):
		if rand_range(0.0, 18.0) > myPlayer.pAgility:
			intP.z *= rand_range( - 1, 1)
	
	if pen:
		intP.y *= 0.5 + 0.5 * smoothstep(90, 180, shotDir.length())
	
	intP.x = clamp(intP.x, - 135.0 * Global.ps, 135.0 * Global.ps)
	var zLim = 20.0 if pen else max(20.0, _shotReachZ())
	intP.z = clamp(intP.z, dGoal.z - zLim, dGoal.z + zLim)
	
	
	
	
		
	
	var dif = intP - myPlayer.translation
	var test = (myPlayer.translation - Global.ballpos).normalized().cross(Vector3.UP)
	
	var dp = test.dot(dif.normalized())
	
	
	dif.y = 0
	var noYdif = intP * Vector3(1.0, 0.0, 1.0) - myPlayer.translation
	var dz = noYdif.length()
	if intP.y > 3.0:
		isUp = true
	
	
	
	
	
	
	# A low ball a couple of steps away gets a proper low dive: the short "close" lean barely
	# moves his body and keeps it at waist height, so low shots into the corner slipped by.
	if dz > 5.0 or (not pen and dz > BLOCK_GAP and intP.y < LOW_DIVE_HEIGHT):
		divedir = sign(dp)
		
		if (divedir > 0):
			if (intP.y > 5):
				myPlayer.myAState.travel("diveHF")
				
			elif (intP.y > 3):
				myPlayer.myAState.travel("diveMF")
				
			else:
				
				myPlayer.myAState.travel("diveLF")
		else:
			if (intP.y > 5):
				myPlayer.myAState.travel("diveHFR")
			
			elif (intP.y > 3):
				myPlayer.myAState.travel("diveMFR")
			
			else:
				
				myPlayer.myAState.travel("diveLFR")
		diving = true
		state = pstate.DIVE
		
		tostate = pstate.ACTIVE
		
		# His dive to the left (diveLF*) stretches out later than the one to the right, so his
		# body has to slide nearly all the way to the ball's line on that side.
		var reachF = LEFT_DIVE_REACH if divedir > 0 else DIVE_HAND_REACH
		# Low balls: his body stretches along the ground more slowly, so he slides most of the way.
		if intP.y < LOW_DIVE_HEIGHT:
			reachF = min(reachF, LOW_DIVE_REACH)
		if not pen:
			reachF *= _reachScale(tArr)
		var aimF = intP if pen else _handAim(intP, reachF)
		diveTrack = not pen
		diveReach = reachF
		vel = (aimF - pos) * Vector3(velval, velval * 3.0, velval)
		vel.y = (intP - pos).y * velval * 3.0
		
		
		
		
		
		vel *= rand_range(0.95, 1.0)
		
		
		
			
		if not pen:
			_quickDive(aimF, tArr)
		# Stop the slide once his head and hands are on the ball's line (Keeper.gd), not his feet.
		diveStopOn = false
		if not pen:
			_setDiveStop(aimF)
		divevel = vel
	else:
		var reachC = CLOSE_HAND_REACH if pen else CLOSE_HAND_REACH * _reachScale(tArr)
		var aimC = intP if pen else _handAim(intP, reachC)
		diveTrack = not pen
		diveReach = CLOSE_HAND_REACH
		vel = (aimC - pos) * Vector3(1.5, 4.5, 4.5)
		vel.y = (intP - pos).y * 4.5
		divedir = 0
		if (fk):
			vel *= rand_range(0.9, 1.0)
			fk = false
		if not pen:
			_quickDive(aimC, tArr)
		# Stop the slide once his head and hands are on the ball's line (Keeper.gd), not his feet.
		diveStopOn = false
		if not pen:
			_setDiveStop(aimC)
		divevel = vel
		# A shot straight at him: stand his ground and take it (jumping only for one over his
		# head) rather than lean off to one side and let it in where he was standing.
		if not pen and dz < BLOCK_GAP and intP.y <= 5.0:
			vel = Vector3.ZERO
			divevel = vel
			diveStopOn = false
			divedir = 0.0
			diving = true
			isUp = intP.y > 3.0
			if isUp:
				myPlayer.myAState.travel("diveUp")
			elif sign(Global.ballvel.z) == sign(myTeam.playDir):
				myPlayer.myAState.travel("collectR")
			else:
				myPlayer.myAState.travel("collectL")
			state = pstate.DIVE
			tostate = pstate.ACTIVE
			view = dview
			shotview = view
			return
		if (intP.y > 5.0):
			divedir = 0.0
			diving = true
			isUp = true
			myPlayer.myAState.travel("diveUp")
			state = pstate.DIVE
			
			divevel.x *= 0.5
			tostate = pstate.ACTIVE
			
			
		else:
			divedir = sign(dp)
			
			
			
			
			
			
				
			
			
			if divedir > 0:
				
				myPlayer.myAState.travel("closeleft")
			else:
				myPlayer.myAState.travel("closeright")
			state = pstate.DIVE
			
			tostate = pstate.ACTIVE
			
			
			
			
				
	view = dview
	shotview = view
	
	
# A dive's push was set in proportion to the gap, so a short dive to the near post was slow
# exactly when the ball arrives soonest, and long shots squeezed in there. Each dive is now at
# least quick enough to reach the ball's line as it gets there (Keeper.gd still caps it at the
# keeper's dive speed, so lesser keepers can be beaten, and stops it just past the line).
const DIVE_DECAY = 0.02
# In a full dive his body stretches out ahead of his feet: spine about 3.5, neck 6.7, hands 8.5.
# Saves happen when the ball meets the save box on his spine, so the feet are aimed this far short
# of the ball's line and the middle of his body (with his arms beyond it) arrives on it.
const DIVE_HAND_REACH = 3.5
const CLOSE_HAND_REACH = 1.5
const LEFT_DIVE_REACH = 0.8
const LOW_DIVE_REACH = 1.2
# Shots coming within this of his body are stood up to and taken, never dived away from.
const BLOCK_GAP = 2.0
const LOW_DIVE_HEIGHT = 2.5
const BOX_CLAIM_PACE = 50.0
const BOX_CLAIM_DIST = 18.0
# How far across his own line (from the middle of the goal) a shot's crossing point may be
# taken. Off his line at an angle, a shot inside the near post crosses his line wider than the
# post, so capping it at the goal's width made him pull back inside, away from the ball.
const ON_TARGET_MARGIN = 2.0
const ON_TARGET_REACH = 45.0
func _shotReachZ():
	if _onTarget():
		return ON_TARGET_REACH
	return abs(myTeam.goalL.z - myTeam.goalR.z) * 0.5 + 1.5

func _onTarget():
	var keepT = predT
	var half = abs(myTeam.goalL.z - myTeam.goalR.z) * 0.5
	var atGoal = _predictShot(dGoal.x)
	predT = keepT
	return abs(atGoal.z - dGoal.z) < half + ON_TARGET_MARGIN and atGoal.y < 10.5

# His body takes time to stretch out in a dive (low ones most of all). With the ball only a
# moment away there isn't that time, so his body itself has to get across onto its line: the
# reach he leaves to his stretch shrinks with the time left. Close near-post shots got a dive
# that barely moved him, his arms still on the way out as the ball went by.
const DIVE_STRETCH_TIME = 0.35
const MIN_REACH_SCALE = 0.3
func _reachScale(t):
	return clamp(t / DIVE_STRETCH_TIME, MIN_REACH_SCALE, 1.0)

# A shot is dived for once it's this close in time (or, for a quick one, LONG_DIVE distance).
const DIVE_LEAD_TIME = 0.4
const DIVE_LEAD_TOP = 0.45
func _diveLeadTime():
	return lerp(DIVE_LEAD_TIME, DIVE_LEAD_TOP, min(_rushClass(), 1.0))

func _handAim(intP, reach):
	var d = intP - pos
	d.y = 0.0
	var l = d.length()
	if l < 0.01:
		return Vector3(pos.x, intP.y, pos.z)
	var go = max(l - reach, 0.0)
	var aim = pos + d / l * go
	aim.y = intP.y
	return aim

# Every dive (shots, smothering a loose ball, claiming a cross) stops once the keeper is
# just past the point he dived for (Keeper.gd), so nobody flies by the ball.
func _setDiveStop(pt):
	var d = pt - pos
	d.y = 0.0
	diveStopOn = d.length() > 0.3
	diveStopPoint = pt
	diveStopZ = pt.z
	diveStopDir = d.normalized() if diveStopOn else Vector3.ZERO

func _quickDive(intP, t):
	var fast = myPlayer.get_meta("diveFast") if myPlayer.has_meta("diveFast") else 1.0
	var k = DIVE_DECAY * fast
	# Time from the ball's own predicted flight: right at the strike Global.ballvel is still the
	# dribble (or the player's run), which made a close shot look slow and his push tiny.
	var n = max(t * 60.0, 1.0)
	var covered = (1.0 - pow(1.0 - k, n)) / k / 60.0
	var gap = intP - pos
	gap.y = 0.0
	var need = gap / covered
	# Never ask for more than the keeper's dive speed: Keeper.gd caps the speed each frame but
	# not the push itself, so an oversized push kept him sliding flat out past the ball.
	need = need.limit_length(myPlayer.pDiveSpeed)
	var cur = Vector3(vel.x, 0.0, vel.z)
	if need.length() > cur.length():
		vel.x = need.x
		vel.z = need.z

func _penaltyDive( var ddir):
	diveStopOn = false
	diveTrack = false
	
	var velval = myPlayer.pDiveAgile * 0.6
	
	var intP = Vector3(myTeam.dGoal.x * 0.98, ddir.y * 13, ddir.x * myTeam.goalL.z)
	debugtarget.translation = intP
	
	divedir = 0
	var dif = intP - pos
	var test = (pos - Global.ballpos).normalized().cross(Vector3.UP)
	
	var dp = test.dot(dif.normalized())
	
	dif.y = 0
	var noYdif = intP * Vector3(1.0, 0.0, 1.0) - pos
	var dz = noYdif.length()

	
	if (abs(dp) > 0.4) and dz > 4.0:
		if (dp > 0):
			divedir = 1
		else:
			divedir = - 1
	
		if (divedir > 0):
			if (intP.y > 5):
				myPlayer.myAState.travel("diveHF")
				
			elif (intP.y > 3):
				myPlayer.myAState.travel("diveMF")
				
			else:
				
				myPlayer.myAState.travel("diveLF")
		else:
			if (intP.y > 5):
				myPlayer.myAState.travel("diveHFR")
				
			elif (intP.y > 3):
				myPlayer.myAState.travel("diveMFR")
			
			else:
			
				myPlayer.myAState.travel("diveLFR")
		diving = true
		state = pstate.DIVE
		
		tostate = pstate.ACTIVE
		vel = (intP - pos) * Vector3(velval, velval * 1.75, velval)
		vel *= rand_range(0.95, 1.0)
		divevel = vel
	else:
		vel = (intP - pos) * Vector3(1.5, 4.5, 4.5)
		divedir = 0
		if (fk):
			vel *= rand_range(0.9, 1.0)
			fk = false
		divevel = vel
		if (intP.y > 5):
			divedir = 0
			diving = true
			isUp = true
			myPlayer.myAState.travel("diveUp")
			state = pstate.DIVE
			
			divevel.x *= 0.1
			tostate = pstate.ACTIVE
		else:
			divedir = sign(dp)
			if abs(dp) > 0.4:
				if divedir > 0:
					myPlayer.myAState.travel("collectL")
				
				else:
					myPlayer.myAState.travel("collectR")
				
				diving = true
			else:
				myPlayer.myAState.travel("closeright")
			state = pstate.DIVE
			tostate = pstate.ACTIVE
	view = dview
	shotview = view
	
func clearingState():
	
	vel = divevel
	divevel *= 0.991
	view = divevel
	
func _diving():
	return state == pstate.DIVE or state == pstate.CLEARING
func replayState():
	vel = divevel
	divevel *= 0.05
	
	

func canChange():
	return ( not _diving()) and (state != pstate.CAUGHT) and (Global.gameOn or Global.penShoot)
func _attack():
	
	
	
	pass
	
	
	
	
	
func _defend():
	
	changeState(pstate.DEFEND)
func _checkLineup():
	if state == pstate.KICKER or state == pstate.SHOOTOUT or Global.isPenalties:
		return
	if state != pstate.IDLE:
		fChangeState(pstate.IDLE)
	lineupcount += 1
	if lineupcount > 5 and state != pstate.IDLE:
		lineupcount = 0
		forceChangeState(pstate.IDLE)
func _press():
	
	if not _diving():
		state = pstate.PRESS
		myPlayer.myAState.travel("sprint")
	else:
		tostate = pstate.PRESS
func _pause():
	
	changeState(pstate.IDLE)
	myPlayer.isAI = true
	myPlayer.replay = false
	
func _posession():
	
	print("keeper Posession???!??!?!?!")
	changeState(pstate.POSESSION)
func _losePosession():
	changeState(pstate.DEFEND)
func _caught():
	
	changeState(pstate.CAUGHT)
	target = Vector3(rand_range(90, 105) * Global.ps * - myTeam.playDir, 0, rand_range( - 30, 30))
	
func _celebrate(_goalscorer):
	forceChangeState(pstate.CELEBRATE)
	
func _conceded():
	forceChangeState(pstate.CONCEDE)
func _kickoff():
	if not _diving():
		state = pstate.IDLE
		tostate = pstate.IDLE
	else:
		tostate = pstate.IDLE
	myPlayer.replay = false
	
func _replay():
	state = pstate.REPLAY
	myPlayer.isAI = true
	myPlayer.replay = true
	

func _updateData(p, v):
	pos = p
	vel = v
	





	
func _update():
	
	_checkGoalThreat()
	stateFunc[state].call_func()
	
	myPlayer.acc += vel
	myPlayer.target = target
	myPlayer.view = view
	
func _shotIncoming( var A, var shotV, var _curl, var stype):
	
	myPlayer._loseControl()
	myPlayer.canSave = true
	myPlayer.canControl = true
	shotDir = shotV
	shotFrame = Engine.get_physics_frames()
	shooter = A
	pen = (state == pstate.PENALTY) or Global.penOn
	
	shottype = stype
	
	if state == pstate.SHOOTOUT:
		
		myPlayer._savePenalty()
	elif DZ and not _diving():
		dcount = 0
		
		call_deferred("changeState", pstate.INCOMING)
	else:
		call_deferred("longshotCalcTarget")

func _rushClass():
	return myPlayer.get_meta("rushClass") if myPlayer.has_meta("rushClass") else 0.0

func longshotCalcTarget():
		# Top keepers read a long shot almost at once.
		yield(get_tree().create_timer(lerp(0.1, 0.03, _rushClass())), "timeout")
		longTarget = intersectShot(Global.ballvel)
		
		
		
		
		longTarget.y = 0
		changeState(pstate.LONGSHOT)
		
func _penShotIncoming( var A, var shotV, var _curl, var stype):
	
	myPlayer._loseControl()
	myPlayer.canSave = true
	myPlayer.canControl = true
	shotDir = shotV
	shotFrame = Engine.get_physics_frames()
	shooter = A
	pen = not stype
	if state == pstate.SHOOTOUT:
		
		myPlayer._savePenalty()
		return
	
	
	dcount = 0
		
	if pen:
		call_deferred("fChangeState", pstate.INCOMING)
	else:
		call_deferred("changeState", pstate.INCOMING)

func _crossIncoming():
	
	if not _diving():
		state = pstate.ACTIVE
	else:
		tostate = pstate.ACTIVE
func _penalty():
	pass
func _penaltyDefend():
	
	pen = true
	
	
	forceChangeState(pstate.PENALTY)
	target = Vector3(dGoal.x * 0.98, 0, dGoal.z)

func _defendCorner():
	
	target = Vector3(dGoal.x * 0.97, 0, dGoal.z)
	fChangeState(pstate.IDLE)
func _corner( var _e, var _side):
	target = target
	
func _defendFK():
	
	target = Vector3(dGoal.x * 0.97, 0, dGoal.z - sign(myTeam.Game.resetPos.z) * 6.0)
	fk = true
	fChangeState(pstate.IDLE)
func _attackFK():
	forceChangeState(pstate.IDLE)

func _fouled():
	pass
func _kickTaker( var _ktype, var _ifk):
	
	
	myPlayer.canControl = true
	
	target = Global.ballpos
	state = pstate.KICKER
func _freeKickTaker( var ktype, var ifk):
	_kickTaker(ktype, ifk)
	yield(get_tree().create_timer(0.6), "timeout")
	myTeam.Game.goGamePen()
func fChangeState(newState):
	
	if not _diving():
		state = newState
		if newState != pstate.CAUGHT:
			myPlayer.myATree["parameters/CaughtBall/blend_amount"] = 0
	
	else:
		tostate = newState
			
func forceChangeState(newState):
	
	
	var nstate = newState
	if newState == pstate.ACTIVE or newState == pstate.DEFEND:
		if DZ:
			nstate = pstate.ACTIVE
	if ball._isCaught():
		if ball.player == myPlayer:
			nstate = pstate.CAUGHT
		
		
	state = nstate
	tostate = nstate
	
	if state != pstate.CAUGHT:
		myPlayer.myATree["parameters/CaughtBall/blend_amount"] = 0
	else:
		myPlayer.myATree["parameters/CaughtBall/blend_amount"] = 1

func changeState(newState):
	
	
	
	
	
		
	if state == newState:
		return
	
	
		
	var nstate = newState
	
	if newState == pstate.DEFEND:
		if DZ:
			nstate = pstate.ACTIVE
	if canChange():
		
		
		state = nstate
		
		
		if state != pstate.CAUGHT:
			myPlayer.myATree["parameters/CaughtBall/blend_amount"] = 0
		
	else:
		tostate = nstate

	
func _tackled():
	pass

func _hasBall():
	return (state == pstate.CAUGHT)
func _clearBall():
	if _diving():
		return
	doKick = true
	myPlayer.myAState.travel("kick")
	divevel = myPlayer.velocity * 0.5
	state = pstate.CLEARING
	if DZ:
		tostate = pstate.ACTIVE
	else:
		tostate = pstate.DEFEND
	
func _kickBall():
	
	
	if state == pstate.CLEARING and Global.gameOn and doKick:
		_losePosession()
		tryLongPass()
	
	
	
func _bootBall():
	if _diving():
		return
	
	
	
	shotview = myPlayer.view
	
	doKick = false
	
	divevel = myPlayer.velocity * 0.5
	_losePosession()
	tryLongPass()
	yield(get_tree().create_timer(0.3), "timeout")
	myPlayer.canControl = true
func _throwBall():
	
	
	
	
	
	
	tryPass(true)
	yield(get_tree().create_timer(0.3), "timeout")
	myPlayer.canControl = true
	
	
	
func _throwOut():
	
	if _diving():
		return
	
	
	
	
	
	myPlayer.canControl = false
	state = pstate.CLEARING
	tostate = pstate.DEFEND
	
	divevel = myPlayer.transform.basis.z * 10
	myPlayer.myATree["parameters/CaughtBall/blend_amount"] = 0
	myPlayer.myAState.travel("gkthrow")
		


func _shootout():
	pen = true
	fChangeState(pstate.IDLE)
	var mt = 1
	if myTeam.teamID == 2:
		mt = - 1
		myPlayer.myGoalR.z = - myPlayer.myGoalR.z
		
	target = Vector3( - 110 * Global.ps, 0, 40 * mt)
	dGoal = myTeam.dGoal
	
	ball._ballFree()

func _defendPen( var ai):
	target = Vector3( - 138.0 * Global.ps, 0.0, 0.0) * myTeam.playDir
	if ai:
		DZ = true
	else:
		state = pstate.SHOOTOUT
	
func _resetKeeper():
	fChangeState(pstate.IDLE)
	if ball._isCaught():
		ball._ballFree()
		ball._initialize()

	
func _savePen():
	fChangeState(pstate.INCOMING)
func _on_CollectArea_body_entered(body):
	
	if (body != ball):
		return
	
	DZ = true
	if not Global.gameOn:
		return
	
	if ball._isShooting():
		
		dcount = 1
		changeState(pstate.INCOMING)
	else:
		changeState(pstate.ACTIVE)
		
func _on_CollectArea_body_exited(body):
		
	if (body != ball):
		return
	
	myPlayer.pAggression = myPlayer.pDAggression
	DZ = false
	if not Global.gameOn:
		return
	changeState(pstate.DEFEND)
func _forceDefend():
	pass
	
	
func _winner():
	state = pstate.IDLE
	myPlayer._loseControl()
	target = Vector3(45 + myPlayer.myID * 3.5, 0, 50)

func _lapOfHonour():



	state = pstate.LAP
	target = myTeam._getLapTarget(cCelebTarget)
func lapState():
	
	var close = seek()
	if close < 10:
		cCelebTarget = (cCelebTarget + 1) % 4
		target = myTeam._getLapTarget(cCelebTarget)
	view = target
	atarget = target


# --- Goal-bound loose balls -----------------------------------------------------
# The keeper only dives for balls flagged as shots (Team._shot -> _shotIncoming).
# Slow back-passes, long free kicks, deflections and crosses that drift towards
# goal were never flagged, so he ignored them and they rolled in. Treat any loose
# ball whose path crosses our goal mouth as a shot so the normal save logic runs.
var threatCooldownUntil = 0

func _checkGoalThreat():
	if not Global.gameOn or Global.penOn or Global.penShoot:
		return
	if not (state == pstate.DEFEND or state == pstate.ACTIVE or state == pstate.IDLE):
		return
	if OS.get_ticks_msec() < threatCooldownUntil:
		return
	if not ball._isFree() or ball._isShooting() or ball._isCaught():
		return
	if dGoal == null:
		return
	var bp = Global.ballpos
	var bv = Global.ballvel
	var dx = dGoal.x - bp.x
	# Only balls in our half that are actually travelling towards our goal line.
	if abs(dx) > 90.0 * Global.ps or abs(bv.x) < 1.0 or sign(bv.x) != sign(dx):
		return
	var t = dx / bv.x
	if t > 5.0:
		return
	# Only slow balls along the ground (back-passes, scuffed shots). Real shots already
	# alert the keeper through Team._shot, and reacting to crosses/fast passes pulled
	# him out of position, so leave those to the original save logic.
	if bv.length() > 40.0 or bp.y > 2.0:
		return
	var zAtLine = bp.z + bv.z * t
	var halfWidth = abs(myTeam.goalL.z) + 2.0
	if abs(zAtLine) > halfWidth:
		return
	threatCooldownUntil = OS.get_ticks_msec() + 1500
	_shotIncoming(bp, bv, Vector3.ZERO, 0)

# --- Crash guards --------------------------------------------------------------
# This web build uses a release engine, where calling a method that doesn't
# exist crashes the whole game ("RuntimeError: null function" = the freeze).
# Several outfield-only methods can be reached on the goalkeeper, so give him
# harmless versions of them.
func _blockShot(_bpos, _dir):
	pass

func _bookMe():
	pass

func _celebratePen():
	pass

func _forceAttack():
	pass

func _mark():
	pass

func _markThrowtarget(_t):
	pass

func _marking():
	return false

func _missed():
	pass

func _moving():
	return true

func _offField(_pid):
	return false

func _onField():
	return true

func _penaltyTaker():
	pass

func _receivePass(_ppos, _dir, _ptype):
	pass

func _sentOff():
	pass

func _setBenched(_i):
	pass

func _subOff(_pid):
	pass

func _subOn(_pid):
	pass

func _takeThrow(_ppos):
	pass

func _throwTaker(_ktype, _ifk):
	pass

func _updatePosition():
	pass

func _forcePickup(_ppos):
	pass

# --- 11v11 sweeping -------------------------------------------------------------------
# Comes off the line for a loose ball in the box when he will clearly get there first.
const SWEEP_MARGIN = 0.25

func _shouldSweep():
	if myTeam.posession or not myPlayer.isAI or not ball._isFree() or ball._isShooting():
		return false
	if Global.ballpos.y > 3.0 or Global.ballvel.length() > 55.0:
		return false
	var spot = Global.ballpos + Global.ballvel * 0.3
	if sign(spot.x) != sign(dGoal.x) or abs(spot.x) < 88.0 * Global.ps or abs(spot.z) > 46.5 * Global.ps:
		return false
	var keeperTime = (spot - pos).length() / max(myPlayer.pSpeed, 1.0)
	for i in range(1, Global.squad):
		var o = myTeam.opponent.players[i]
		if o.carded < 2 and (spot - o.translation).length() / max(o.pSpeed, 1.0) < keeperTime + SWEEP_MARGIN:
			return false
	return true
