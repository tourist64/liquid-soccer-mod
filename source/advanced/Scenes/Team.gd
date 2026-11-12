
extends Spatial


var ball
var goal
var goalL
var goalR
var dGoal
var playDir
var Game
var zone
var activePlayers = Global.squad
var passDir
var myC = 0
var jflip = 1
var cud = 1
var clr = 0
var scorer
var wescored: bool

var players = []
var formation = []
var cformation = []
var goalkeeper
var p2b = []
var d2p2b = []
var closestToGoal = 1
var opponent = null
var pplayer = null
var cplayer = null
var closest = null
var posession = false
var momentum = false
export var shirtColor: Color
export var shirtColor2: Color
export var shirtColor3: Color
export var shortColor: Color
export var keeperColor: Color
export var skin1Color: Color
export var skin2Color: Color
export var numberColor: Color
export var hairColor1: Color
export var hairColor2: Color
export var hairColor3: Color
var tdata = null
var cpdata = null
var tictacs = 0.5
var approach = 0.5
var aggression = 0.5
export var kit: int
export var teamID: int
var vptex = null
var passto = null
var AIteam = true

var pp1 = Vector3.ZERO

var lastjx = 0.0
var lastjy = 0.0
var kotarget = Vector3.ZERO
var isCorner = false

enum teamState{INTRO, LINEUP, KICKOFF, DEFEND, ATTACK, GOAL, CONCEDED, REPLAY, HALFTIME, ENDGAME, FOUL, FOULED, PENALTY, PEN, SHOOTOUT, PLAY}
var state
var stateFunc = {}

var ptarget = Vector3.ZERO
var space_state
var mymask

var throwTarget = null
var celeb = 0
var celebTarget = []

func _ready():
	
	
	state = teamState.LINEUP
	stateFunc[teamState.INTRO] = funcref(self, "noopState")
	stateFunc[teamState.KICKOFF] = funcref(self, "noopState")
	stateFunc[teamState.GOAL] = funcref(self, "noopState")
	stateFunc[teamState.CONCEDED] = funcref(self, "noopState")
	stateFunc[teamState.REPLAY] = funcref(self, "noopState")
	stateFunc[teamState.HALFTIME] = funcref(self, "noopState")
	stateFunc[teamState.ENDGAME] = funcref(self, "noopState")
	stateFunc[teamState.FOUL] = funcref(self, "noopState")
	stateFunc[teamState.FOULED] = funcref(self, "noopState")
	stateFunc[teamState.PENALTY] = funcref(self, "lineupState")
	stateFunc[teamState.PEN] = funcref(self, "lineupState")
	stateFunc[teamState.SHOOTOUT] = funcref(self, "shootoutState")
	
	stateFunc[teamState.LINEUP] = funcref(self, "lineupState")
	stateFunc[teamState.DEFEND] = funcref(self, "defendState")
	stateFunc[teamState.ATTACK] = funcref(self, "attackState")
	stateFunc[teamState.PLAY] = funcref(self, "playState")

	passDir = Vector3.ZERO
	
	
	space_state = get_world().direct_space_state
	


func loadPlayers():
	var dir = - 1.0
	if teamID > 1:
		dir = 1.0
	Global.setupWomens = false
	if (teamID == 1 and Global.isT1Womens) or (teamID == 2 and Global.isT2Womens):
		Global.setupWomens = true
	var k = preload("res://Scenes/Keeper.tscn").instance()
	k.name = "GoalKeeper"
	$Players.add_child(k)
	k.get_child(0).translation = Vector3(0.0, 0.0, 100 + dir * 7.0)
	for i in range(0, (Global.squad - 1) if Global.elevenMode else 12):
		var p = preload("res://Scenes/Player.tscn").instance()
		$Players.add_child(p)
		p.get_child(0).translation = Vector3(dir * 5.0, 0.0, 80.0 + i * 3.0)
		p.name = "Player" + str(i + 1)
	

func setupFormation():
	formation.clear()
	cformation.clear()
	tdata = Global.t1
	if (teamID != 1):
		tdata = Global.t2
	if (playDir == 1):
		
		formation.append(Vector2( - 110 * Global.ps, 0))
		for i in range(Global.squad - 1):
			formation.append(Vector2(range_lerp(tdata.def[i].y, 0, 1, 150 * Global.ps, - 150 * Global.ps), range_lerp(tdata.def[i].x, 0, 1, - 100 * Global.ps, 100 * Global.ps)))
		formation.append(Vector2( - 110 * Global.ps, 0))
		for i in range(Global.squad - 1):
			formation.append(Vector2(range_lerp(tdata.mid[i].y, 0, 1, 150 * Global.ps, - 150 * Global.ps), range_lerp(tdata.mid[i].x, 0, 1, - 100 * Global.ps, 100 * Global.ps)))
		formation.append(Vector2( - 110 * Global.ps, 0))
		for i in range(Global.squad - 1):
			formation.append(Vector2(range_lerp(tdata.att[i].y, 0, 1, 150 * Global.ps, - 150 * Global.ps), range_lerp(tdata.att[i].x, 0, 1, - 100 * Global.ps, 100 * Global.ps)))
		
	else:
		
		formation.append(Vector2(110 * Global.ps, 0))
		for i in range(Global.squad - 1):
			formation.append(Vector2(range_lerp(tdata.def[i].y, 0, 1, - 150 * Global.ps, 150 * Global.ps), range_lerp(tdata.def[i].x, 0, 1, 100 * Global.ps, - 100 * Global.ps)))
		formation.append(Vector2(110 * Global.ps, 0))
		for i in range(Global.squad - 1):
			formation.append(Vector2(range_lerp(tdata.mid[i].y, 0, 1, - 150 * Global.ps, 150 * Global.ps), range_lerp(tdata.mid[i].x, 0, 1, 100 * Global.ps, - 100 * Global.ps)))
		formation.append(Vector2(110 * Global.ps, 0))
		for i in range(Global.squad - 1):
			formation.append(Vector2(range_lerp(tdata.att[i].y, 0, 1, - 150 * Global.ps, 150 * Global.ps), range_lerp(tdata.att[i].x, 0, 1, 100 * Global.ps, - 100 * Global.ps)))
	# Corner and free-kick spots are looked up by player id, and id 0 is the keeper.
	cformation.append(Vector3.ZERO)
	for i in range(Global.squad - 1):
		cformation.append(Vector3(range_lerp(tdata.cor[i].y, 0, 1, - 150 * Global.ps, 150 * Global.ps), 0, range_lerp(tdata.cor[i].x, 0, 1, 100 * Global.ps, - 100 * Global.ps)))
		

func setPlayerParams( var p, var i):
	
	var pp = tdata.player0
	match i:
		1:
			pp = tdata.player1
		2:
			pp = tdata.player2
		3:
			pp = tdata.player3
		4:
			pp = tdata.player4
		5:
			pp = tdata.player5
		6:
			pp = tdata.player6
		7:
			pp = tdata.player7
		8:
			pp = tdata.player8
		9:
			pp = tdata.player9
		10:
			pp = tdata.player10
		11:
			pp = tdata.player11
	
	var lev = Global.config.get_value("game", "skillLevel")
	lev = floor(lerp(30, 4, lev))
	
	var sma = lev + tdata["level"]
	p.pSmart = sma + (10 - pp["smart"]) * 2
	p.dSmart = 0.016 * p.pSmart
	p.pTSmart = p.pSmart
	p.pSpeed = 23 + pp["speed"] * 0.6
	p.pBurst = p.pSpeed + lerp(12, 14, pp["speed"] * 0.1)
	p.dBurst = p.pBurst
	p.pDSpeed = p.pSpeed - 2.0
	p.pOSpeed = p.pSpeed
	p.pAggression = pp["aggression"] * 0.1
	p.pAgility = pp["agility"] * 0.8
	p.pAcc = pp["speed"] * 0.1
	p.pShoot = pp["shoot"] * 0.1
	p.pCurl = pp["curl"] * 0.1
	p.set("pStrength", pp.get("strength", 5.0) * 0.1)
	p.set("pAerial", pp.get("aerial", 5.0) * 0.1)
	p.set("pBlock", pp.get("block", 0.0))
	# Aerial ratings always count in 11v11; in the normal game only for players who have one.
	p.set("aerialRated", Global.elevenMode or pp.has("aerial"))
	p.set("blockRated", Global.elevenMode or pp.has("block"))
	# hitbox: a bigger body for blocking shots and a bigger reach for headers (1 = normal).
	var hitbox = pp.get("hitbox", 1.0)
	if p.get("myHeadArea") != null:
		var reach = lerp(0.8, 1.3, pp.get("aerial", 5.0) * 0.1) if p.get("aerialRated") else 1.0
		p.myHeadArea.scale = Vector3.ONE * reach * hitbox
	if p.has_node("BallCollider/CollisionShape"):
		p.get_node("BallCollider/CollisionShape").scale = Vector3.ONE * hitbox
	p.set("pLongShot", pp.get("longShot", 0.0))
	p.set("pPressRes", pp.get("pressRes", 0.0))
	p.set("pBallWin", pp.get("ballWin", 0.0))
	if Global.elevenMode and p.get("myTrapArea") != null:
		p.myTrapArea.scale = Vector3.ONE * lerp(1.0, 1.4, pp.get("ballWin", 0.0))
	cpdata = pp
	
	if i == 0:
		p.pAgg = p.pAggression * 0.6
		var klev = Global.config.get_value("game", "skillLevel")
		p.pDiveAgile = lerp(1.25, 3, klev)
		
		
		
		
		
		
		
		
		
	p2b.append(Vector3.ZERO)
	d2p2b.append(1.0)
func setTeamParams():
	var lev = Global.config.get_value("game", "skillLevel")
	lev = lerp(1.5, 0.0, lev)
	var ait = 1.0 + lev
	match tdata["level"]:
		1:
			ait = 1.5 + lev
		2:
			ait = 1.75 + lev
		3:
			ait = 2.0 + lev * 2.0
	if not AIteam:
		ait = 0.16
	$AITimer.wait_time = ait
	
	if teamID == 1:
		
		mymask = 4096
	else:
		
		mymask = 2048
func checkControllers():
	if Global.camrot:
		cud = 0
		clr = 1
		jflip = - 1
	else:
		cud = 1
		clr = 0
		jflip = 1
func _initializeTeam(human):
	
	
	var i = 0
	var c = 0
	setupFormation()
	AIteam = not human
	var off = - 10
	if AIteam:
		off = 10
	
	
	loadPlayers()
	
	if (teamID == 2) and (Global.p1human) and (Global.p2human):
		c = 1
	
	for N in $Players.get_children():
		var NB = N.get_child(0)
		
		setNames()
		
		N.teamID = teamID
		NB.ball = ball
		NB.myTeam = self
		
		
		
		NB.connect("posession", self, "_onPosession")
		NB.myID = i
		
		if teamID == 2 and i > 0:
			
			NB.set_collision_layer_bit(11, false)
			NB.set_collision_layer_bit(12, true)
			NB.set_collision_mask_bit(9, true)
			NB.set_collision_mask_bit(10, false)
		
			NB.TA.set_collision_layer_bit(9, false)
			NB.TA.set_collision_layer_bit(10, true)
			NB.TA.set_collision_mask_bit(11, true)
			NB.TA.set_collision_mask_bit(12, false)
			NB.AI.rayc.set_collision_mask_bit(12, true)
	
			
	
		elif teamID == 1 and i > 0:
			
			NB.set_collision_layer_bit(11, true)
			NB.set_collision_layer_bit(12, false)
			NB.set_collision_mask_bit(9, false)
			NB.set_collision_mask_bit(10, true)
		
			NB.TA.set_collision_layer_bit(9, true)
			NB.TA.set_collision_layer_bit(10, false)
			NB.TA.set_collision_mask_bit(11, false)
			NB.TA.set_collision_mask_bit(12, true)
			NB.AI.rayc.set_collision_mask_bit(11, true)
	
			
		
		setPlayerParams(NB, i)
		
		N.connect("hudpos", Global.game.hud, "_updateMap")
		if i == 0:
			N.setColors(keeperColor, keeperColor, cpdata.skin)
			NB.AI.flip = playDir
			NB.AI.AIKeeper = not human
		else:
			N.setColors(shirtColor, shirtColor2, shirtColor3, shortColor, cpdata.skin, numberColor, kit, cpdata.hair, cpdata.hairtype, cpdata.facehair)
		
		NB.AI._initialize(self, goal, goalL, goalR, dGoal)
		NB.aiFrame = i
		
	
		players.append(NB)
		
	
		if i < Global.squad:
			
			
			NB.AI.target = NB.translation
			NB.AI.atarget = NB.translation
			NB.set_process(true)
			NB.AI.setTarget(Vector3(formation[i].x, 0, formation[i].y))
			NB.AI._kickoff()
		else:
			NB.AI._setBenched(i)
			NB.set_process(false)
			NB.set_physics_process(false)
	
		NB.myC = c
		N.game = Global.game
		if c > 0:
			NB._initP2Controls()
		i += 1
	
	myC = c
	setTeamParams()
	goalkeeper = players[0]
	checkControllers()
	state = teamState.LINEUP
func setNames():
	
	
	
	





	
	
	pass
	
func _introTeam( var mul):
	
	var ppos = - 6
	for NB in players:
		NB.AI.setTarget(Vector3(ppos * mul, 0, 20))
		ppos -= 6
		
func _resetTeam(_AI, ourKick):
	
	zone = 2
	setupFormation()
	activePlayers = Global.squad
	var i = 0
	Global.teamsReady[teamID - 1] = false
	for NB in players:
		NB.myGoal = goal
		NB.dGoal = dGoal
		NB.myGoalL = goalL
		NB.myGoalR = goalR
		
		var xp = max(formation[i].x, 30 * Global.ps)
		if playDir == 1:
			xp = min(formation[i].x, - 30 * Global.ps)
		NB.AI.setTarget(Vector3(xp, 0, formation[i].y))
		NB.AI._kickoff()
		if (i == 0):
			NB.AI.flip = playDir
		NB.AI._initialize(self, goal, goalL, goalR, dGoal)
		i += 1
	if (ourKick):
		if players[5].carded < 2:
			Game.kickTaker = players[5]
		else:
			Game.kickTaker = _closestPToBall()
		Game.kickTaker.AI.setTarget(Vector3.ZERO - dGoal * 0.04)
		
	state = teamState.LINEUP
	$AITimer.start()
func _lineup( var ourKick):
	Global.teamsReady[teamID - 1] = false
	var i = 0
	for NB in players:
		
		var xp = max(formation[i].x, 30 * Global.ps)
		if playDir == 1:
			xp = min(formation[i].x, - 30 * Global.ps)
		NB.AI.setTarget(Vector3(xp, 0, formation[i].y))
		NB.AI._kickoff()
		i += 1
	if (ourKick):
		players[5].AI.setTarget(Vector3.ZERO - dGoal * 0.04)
		Game.kickTaker = players[5]
		if Game.kickTaker.carded > 1:
			Game.kickTaker = _closestPToBall()
	state = teamState.LINEUP
	$AITimer.start()
func _goGameAttack( var t):
	
	state = teamState.ATTACK
	players[0].AI._defend()
	for i in range(1, Global.squad):
		if players[i] != passto:
			players[i].AI._forceAttack()
		players[i]._shush()
	
	if passto:
		cplayer = passto
		if not AIteam:
			cplayer._controlMe()
	else:
		cplayer = _closestPToP(t)
		if cplayer:
			if not AIteam:
				cplayer._controlMe()
			else:
				cplayer.AI._receivePass(Global.ballpos, passDir, 0)
		
func _goGameDefend():
	state = teamState.DEFEND
	players[0].AI._defend()
	for i in range(1, Global.squad):
		if not players[i].AI._marking():
			players[i].AI._forceDefend()
		players[i]._shush()
	
	
	
	if AIteam:
		cplayer = _closestDPToBall()
		closest = cplayer
		cplayer.AI._press()
	
func _passTo( var p):
	
	
	if p:
		passto = p
	
# Passes stay this far inside the lines, unless the receiver is already out there.
const PASS_LINE_MARGIN = 22.0
const PASS_LINE_CLOSEST = 5.0

func _safePassSpot(spot, mate):
	var lineX = 140.0 * Global.ps
	var lineZ = 90.0 * Global.ps
	var limitX = lineX - PASS_LINE_MARGIN
	var limitZ = lineZ - PASS_LINE_MARGIN
	if mate != null:
		limitX = max(limitX, min(abs(mate.translation.x), lineX - PASS_LINE_CLOSEST))
		limitZ = max(limitZ, min(abs(mate.translation.z), lineZ - PASS_LINE_CLOSEST))
	spot.x = clamp(spot.x, - limitX, limitX)
	spot.z = clamp(spot.z, - limitZ, limitZ)
	return spot

func _findPass(pos, lookD, id):
	var diff
	var candidate = null
	var res = lookD
	var best = 1000000
	var dopass = false
	var tol = 0.05
	var dl = 0
	var dd = 0
	
	for i in range(1, Global.squad):
		if i != id:
			diff = ((players[i].translation) + (players[i].velocity * players[i].dSmart)) - Global.ballpos
			var score = diff.normalized().dot(lookD.normalized())
			if players[i].carded > 1:
				score = - 1000
			if i == 0:
				dl = score
			if score > dl:
				candidate = players[i]
				res = diff
				dl = score
				dd = diff.length_squared()
				best = dd
			elif abs(score - dl) < tol:
				dd = diff.length_squared()
				if dd < best:
					candidate = players[i]
					res = diff
					dl = score
					best = dd
	if (candidate):
		
		passDir = res
		if Global.elevenMode:
			passDir = _safePassSpot(Global.ballpos + res, candidate) - Global.ballpos
		
		passDir.y = 0
		
		
		
		
		
		
		pplayer = candidate
		dopass = true
		if candidate.myID > 0:
			candidate.AI._receivePass(pos, passDir, 0)
		opponent.pressTarget(candidate, false)
		passto = candidate
		
			
		
		
	
	return dopass
	
	
func _findThruPass(pos, lookD, _id):
	var diff
	var candidate = null
	
	var best = 1000
	var dopass = false
	var dl = 0
	
	for i in range(1, Global.squad):
		diff = (players[i].translation) + ((players[i].velocity).normalized() * 1.0) - Global.ballpos
		
		
		var score = diff.normalized().dot(lookD.normalized())
		
		if _isOffsidePosition(players[i]):
			score = - 1000
		if score > 0.55 and (players[i].myID != _id):
			dl = diff.length()
			if (dl < best):
				candidate = players[i]
				
				best = dl
	
	if (candidate):
		
		var passPos = candidate.translation - goal
		passPos = candidate.translation - passPos * 0.2
		if Global.elevenMode:
			passPos = _safePassSpot(passPos, candidate)
		passDir = passPos - Global.ballpos
		
		
		var nohit = true
		if nohit:
			pplayer = candidate
			dopass = true
		
			if AIteam:
			
			
				candidate.AI._receivePass(pos, passDir, 2)
			opponent.pressTarget(candidate, false)
			passto = candidate
		else:
			
			dopass = false
	
	return dopass
func _checkPass( var pd, var fromP, var plength):
	
	
	var r = pd.cross(Vector3.UP)
	var t = Transform(Basis(r, Vector3.UP, pd), Global.ballpos)
	var it = t.inverse()
	
	for i in range(1, Global.squad):
		
		
		var pl = it.xform(opponent.players[i].translation)
		
		
		
		
		if pl.z > 0.0:
			var xchk = lerp(2.0, 8.0, smoothstep(0, plength, pl.z))
			
			if abs(pl.x) < xchk and pl.z * pl.z < plength:
				
				
				
				
				fromP.AI.aavoid += (Global.ballpos - opponent.players[i].translation) * (1.0 - smoothstep(1.0, 12.0, pl.z * pl.z))
				return false
	
	return true
	
	
	
func _findLongPass(pos, lookD, _id):
	var diff
	var candidate = null
	var res = lookD
	var best = 0
	var dopass = false
	var dl = 0
	for i in range(1, Global.squad):
		diff = (players[i].translation + (goal - players[i].translation) * 0.2) - pos
		
		var score = diff.normalized().dot(lookD.normalized())
		if players[i].carded > 1 or _isOffsidePosition(players[i]):
			score = - 1000
		if (players[i].myID != _id) and score > 0.55:
			dl = diff.length_squared()
			if (dl > best):
				candidate = players[i]
				res = diff
				best = dl
				
	
	if (candidate):
		
		pplayer = candidate
		dopass = true
		if AIteam:
		
		
			candidate.AI._receivePass(pos, passDir, 1)
		opponent.pressTarget(candidate, true)
		passto = candidate
		passDir = res
		if Global.elevenMode:
			passDir = _safePassSpot(pos + res, candidate) - pos
	return dopass


func _closestPToTarget( var targ):
	var dist = 2000000
	var csfd = 2000000
	var CP = null
	var CSFP = null
	var t2g = (targ.translation - dGoal).length_squared()
	for i in range(1, Global.squad):
		var P = players[i]
		var d = (P.translation - targ.translation).length_squared()
		if d < dist and (P.translation - dGoal).length_squared() < t2g:
			CP = P
			dist = d
		if d < csfd:
			CSFP = P
	if CP:
		return CP
	else:
		return CSFP

func pressTarget( var targ, var long):
	var cand = _closestPToTarget(targ)
	if cand:
		cand.AI._intercept(targ, long)

func _closestPToP( var target):
	var dist = 500000
	var CP = null
	for i in range(1, Global.squad):
		var P = players[i]
		var d = (P.translation - target).length_squared()
		if d < dist:
			CP = P
			dist = d
	return CP

func _closestPToBall():
	var dist = 300000
	var CP = null
	for i in range(1, Global.squad):
		var P = players[i]
		var d = (P.translation - (Global.ballpos + Global.ballvel * 0.3)).length_squared()
		if d < dist:
			CP = P
			dist = d
	return CP


func _closestPToBallDir():
	
	
	
	
	var dist = 300000
	var CP = null

	
	var jx = Input.get_joy_axis(myC, clr)
	var jy = Input.get_joy_axis(myC, cud) * jflip
	if Global.touchPad.isActive():
			var mov = Global.touchPad.get_force()
			jy = mov.y * jflip * - 1.0
			jx = mov.x
	
	if (Input.is_action_pressed("p1_left")):
		jx = - 1
	elif (Input.is_action_pressed("p1_right")):
		jx = 1
	if (Input.is_action_pressed("p1_up")):
		jy = - 1
	elif (Input.is_action_pressed("p1_down")):
		jy = 1
	
	
	
	
	jx = sign(jx) * smoothstep(0.2, 1, abs(jx))
	jy = sign(jy) * smoothstep(0.2, 1, abs(jy))
	
	
	
	
	
	if cplayer:
		
		if jx == 0 and jy == 0 and d2p2b[cplayer.myID] < 1600:
			return cplayer
		var dx = lastjx - jx
		var dy = lastjy - jy
		var cdiff = abs(dx) + abs(dy)
		
		if cdiff < 0.05:
			return cplayer
		
		if (ball.translation - cplayer.translation).length_squared() < 25.0:
			return cplayer
	
	var dvec = Vector3( - jx, 0, - jy).normalized()
	var bpos = Global.ballpos
	var look = 0.0
	if bpos.y > 2:
		look = 0.3
	bpos = bpos + Global.ballvel * look
	bpos.y = 0
	lastjx = jx
	lastjy = jy
	
	for i in range(1, Global.squad):
		var P = players[i]
		var d = (P.translation - bpos)
		
		var dl = d.length()
		if dl < 70:
			var dp = (d / dl).dot(dvec)
		
			dp = clamp(dp, 0.0, 1.0)
			if dp > 0.3:
				if dl < dist:
					CP = P
					dist = dl
				
	return CP

	
func _closestSPToBall():
	var dist = 2000
	var CP = null
	for i in range(1, Global.squad):
		var P = players[i]
		var d = (P.translation - (Global.ballpos + Global.ballvel * 0.2)).length()
		if d < dist:
			CP = P
			dist = d
	return CP
	
func _closestDPToBall():
	var dist = 200000
	var d2g = 200000
	var CP = closest
	var CPTG = null
	
	
	
	for i in range(1, Global.squad):
		var P = players[i]
		
		
		var lookP = (Global.ballpos + Global.ballvel * 0.3)
		lookP.y = 0.2
		var d = (P.translation - lookP).length_squared()
		
		if d < dist:
			CP = P
			dist = d
		
		
		
		if (dGoal - P.translation).length_squared() < (dGoal - lookP).length_squared():
			if d < d2g:
				CPTG = P
				d2g = d
	if zone == 3:
		return CP
	
	
	if ball._isFree():
		return CP
	
	
	
	if CP != CPTG and CPTG:
		CP = CPTG
	return CP
func _closestDPToBallNew():
	var dist = 200000
	
	var c2g = 200000
	var CP = closest
	
	
	
	
	var bscore = 0
	var score = 0
	for i in range(1, Global.squad):
		score = 0
		var P = players[i]
		var dgp = (P.translation - P.dGoal).length_squared()
		
	
		
		if d2p2b[i] < dist:
			score += 1
			dist = d2p2b[i]
		if dgp < c2g:
			score += 0.5
			c2g = dgp
		if (abs(P.translation.x) > abs(Global.ballpos.x)) and i < 4:
			score += 0.5
			c2g = abs(P.translation.x)
		
		if score > bscore:
			CP = P
			
	return CP
	
func setAttack():
	
	if state != teamState.ATTACK:
		wonBallAt = OS.get_ticks_msec()
	state = teamState.ATTACK
	
	for i in range(1, Global.squad):
		if players[i] != pplayer:
			players[i].AI._attack()
		players[i].marked = false
	if ball._isFree() and AIteam:
		var close = _closestPToBall()
		if close:
			closest = close
			close.AI._press()
	players[0].AI._defend()
	
func setDefend():
	state = teamState.DEFEND
	
	
	for i in range(1, Global.squad):
		
		players[i].marked = false
		players[i].AI.marking = null
		if (players[i].isAI):
			players[i].AI._forceDefend()
	
	
	if AIteam:
		var close = _closestDPToBall()
		if close:
			closest = close
			closest.AI._press()
	
	players[0].AI._defend()
		
func _getSupportFKPos( var pid):
	
	if Game.fkend != 0:
		return Vector3(cformation[pid].x * Game.fkend, 0, cformation[pid].z)
	elif Game.fkend == 0:
		
		momentum = true
		return _getPlayPos(pid)
func _getGoalKickPos( var pid):
	var posid = pid + Global.squad
	return Vector3(formation[posid].x, 0, formation[posid].y)


# Unit-shape teams attack only while they have the ball or their own pass is still travelling.
func _onTheBall():
	return posession or passto != null

# Nobody has the ball and nobody's pass is travelling: the two nearest players go and win it.
func _looseBall():
	if ball.state == ball.bstate.CAUGHT or ball.state == ball.bstate.TRAPPED:
		return false
	return not posession and passto == null and not opponent.posession and opponent.passto == null

func _getPlayPos(pid):
	var p = _holdLine(_keepOnside(_getPlayPosRaw(pid), pid), pid)
	# The anchor screens the middle without the ball instead of drifting wide.
	if tdata.anchorId == pid and not _onTheBall():
		p.z = clamp(p.z, - ANCHOR_HALF_WIDTH * Global.ps, ANCHOR_HALF_WIDTH * Global.ps)
	return p

# --- Guardiola-style defending (pepLine, counterPress, anchorId) ---------------------------
const ANCHOR_HALF_WIDTH = 12.0      # anchor stays within 12 units (~3.5 m) of the centre
const COUNTER_PRESS_FRAMES = 360    # 6 seconds at 60 physics frames a second
const COUNTER_PRESSERS = 3          # the three nearest players swarm the carrier
const PEP_MAX_GAP = 75.0            # back line no more than ~22 m (75 units) behind the midfield line
const PEP_DROP = 26.0               # drop ~8 m (26 units) when the carrier has clean time in midfield
const PEP_PRESSURE_RADIUS = 10.0    # "pressured" = one of ours within 10 units (~3 m) of the carrier
const PEP_CALM_FRAMES = 45          # clean time = unpressured for 0.75 seconds
const PEP_MIDFIELD_FROM = 90.0      # midfield band: 90-200 units from our goal
const PEP_MIDFIELD_TO = 200.0
var lostBallFrame = - 100000
var calmFrames = 0

func _counterPressing():
	if tdata.counterPress <= 0.0 or _onTheBall() or opponent.pplayer == null:
		return false
	return Engine.get_physics_frames() - lostBallFrame < COUNTER_PRESS_FRAMES

# One of the three outfield players nearest the ball (the anchor holds his screen instead).
func _counterPresser(p):
	if p.myID == tdata.anchorId:
		return false
	var mine = p.translation.distance_squared_to(Global.ballpos)
	var nearer = 0
	for i in range(1, Global.squad):
		var mate = players[i]
		if mate != p and i != tdata.anchorId and mate.translation.distance_squared_to(Global.ballpos) < mine:
			nearer += 1
	return nearer < COUNTER_PRESSERS

func _pepLine(line, ids):
	# Vertical compactness: never more than PEP_MAX_GAP behind the midfield line.
	var total = 0.0
	var count = 0
	for i in range(1, Global.squad):
		if not ids.has(i):
			total += abs(_getPlayPosRaw(i).x - dGoal.x)
			count += 1
	if count > 0:
		line = max(line, total / count - PEP_MAX_GAP)
	# While counter-pressing the line holds its height; no drop-off.
	if _counterPressing():
		calmFrames = 0
		return line
	# Drop-off: an opponent with clean, unpressured time on the ball in midfield.
	var carrier = opponent.pplayer
	var calm = false
	if carrier != null and ball._isTrapped():
		var depth = abs(carrier.translation.x - dGoal.x)
		if depth > PEP_MIDFIELD_FROM and depth < PEP_MIDFIELD_TO:
			calm = true
			for i in range(1, Global.squad):
				if players[i].translation.distance_to(carrier.translation) < PEP_PRESSURE_RADIUS:
					calm = false
					break
	calmFrames = calmFrames + 1 if calm else 0
	if calmFrames > PEP_CALM_FRAMES:
		line -= PEP_DROP * tdata.pepLine
	return line

# --- Normal-game back line ---------------------------------------------------------------
# Without the ball, the deepest defenders stand level with each other, goal-side of the ball,
# so attackers who drift beyond them are offside.
const LINE_DEFENDERS = 3
# Only players nearly as deep as the deepest defender belong to the line, never a midfielder.
const LINE_DEPTH_BAND = 0.06
const LINE_BALL_GAP = 4.0
const LINE_MIN_DEPTH = 12.0
var lineFrame = - 1
var lineX = 0.0

func _lineIds():
	var ids = []
	for i in range(1, Global.squad):
		ids.append(i)
	ids.sort_custom(self, "_deeperInShape")
	var deepest = tdata.def[ids[0] - 1].y
	var line = []
	for id in ids.slice(0, LINE_DEFENDERS - 1):
		if deepest - tdata.def[id - 1].y <= LINE_DEPTH_BAND:
			line.append(id)
	return line

func _deeperInShape(a, b):
	return tdata.def[a - 1].y > tdata.def[b - 1].y

const TRAP_REACH = 14.0
const TRAP_STEP = 3.0

# Step the line up past any attacker who is just onside near it, so he is left offside.
func _springTrap(line):
	var reach = TRAP_REACH * tdata.offsideTrap
	var stepped = line
	for i in range(1, Global.squad):
		var o = opponent.players[i]
		if o == opponent.pplayer or o.carded > 1:
			continue
		var depth = abs(o.translation.x - dGoal.x)
		if depth >= line and depth <= line + reach:
			stepped = max(stepped, depth + TRAP_STEP)
	return min(stepped, line + reach + TRAP_STEP)

func _holdLine(p, pid):
	if Global.elevenMode or not Global.gameOn or isCorner or _onTheBall():
		return p
	var ids = _lineIds()
	if not ids.has(pid) or players[pid] == pplayer:
		return p
	if Engine.get_physics_frames() != lineFrame:
		lineFrame = Engine.get_physics_frames()
		var total = 0.0
		for id in ids:
			total += _keepOnside(_getPlayPosRaw(id), id).x
		var line = abs(total / ids.size() - dGoal.x)
		var ballDepth = abs(Global.ballpos.x - dGoal.x)
		if tdata.offsideTrap > 0.0:
			line = _springTrap(line)
		if tdata.pepLine > 0.0:
			line = _pepLine(line, ids)
		line = max(min(line, ballDepth - LINE_BALL_GAP), LINE_MIN_DEPTH)
		lineX = dGoal.x - sign(dGoal.x) * line
	return Vector3(lineX, p.y, p.z)

func _getPlayPosRaw(pid):
	if Global.elevenMode:
		var boxRun = _boxRun(pid)
		if boxRun != null:
			return boxRun
	
	var dp = Global.ballpos + Global.ballvel * 0.2
	var blerp = smoothstep( - 135 * Global.ps, 150 * Global.ps, dp.x * playDir)
	if tdata.unitShape > 0.0:
		if not _onTheBall():
			# Without the ball a unit-shape team drops into its deep shape wherever the ball is.
			return _getDefendPos(pid)
		blerp = max(blerp, smoothstep( - 60 * Global.ps, 30 * Global.ps, dp.x * playDir) * tdata.unitShape)
	if momentum:
		var zlerp = smoothstep(0, 80 * Global.ps, abs(dp.z))
		pp1.x = lerp(formation[pid].x + 20 * playDir, formation[pid + Global.squad].x + 10.0 * playDir, smoothstep(0.0, 0.5, blerp))
		pp1.z = lerp(formation[pid].y, formation[pid + Global.squad].y, smoothstep(0.0, 0.5, blerp))
		
		pp1.x = lerp(pp1.x, formation[pid + 2 * Global.squad].x + 10 * playDir, smoothstep(0.5, 1.0, blerp))
		pp1.z = lerp(pp1.z, formation[pid + 2 * Global.squad].y, smoothstep(0.5, 1.0, blerp))
		pp1.z += zlerp * 20.0 * sign(dp.z) * approach
		return pp1
	else:
		
		pp1.x = lerp(formation[pid].x - 5.0 * playDir, formation[pid + Global.squad].x - 25.0 * playDir, smoothstep(0.0, 0.5, bias(blerp, 0.5)))
		pp1.z = lerp(formation[pid].y, formation[pid + Global.squad].y, smoothstep(0.0, 0.5, blerp))
		pp1.x = lerp(pp1.x, formation[pid + 2 * Global.squad].x - 40.0 * playDir, smoothstep(0.5, 1.0, bias(blerp, 0.3)))
		pp1.z = lerp(pp1.z, formation[pid + 2 * Global.squad].y, smoothstep(0.5, 1.0, blerp))
		
		var zlerp = smoothstep(0, 80 * Global.ps, abs(dp.z - pp1.z))
		
		pp1.z += zlerp * 12.0 * sign(dp.z - pp1.z)
	
	
		return pp1

func _getSupportPos(pid):
	return _keepOnside(_getSupportPosRaw(pid), pid)

func _getSupportPosRaw(pid):
	if Global.elevenMode:
		var boxRun = _boxRun(pid)
		if boxRun != null:
			return boxRun
	
	var z = zone
	if tdata.unitShape > 0.0 and _onTheBall() and z < 3 and Global.ballpos.x * playDir > - 40 * Global.ps:
		z = 3
	var posid = pid + (z - 1) * Global.squad
	
	
	
	
	if z == 1:
		var posid2 = pid + Global.squad
		var mxr = 1.0 - smoothstep(40 * Global.ps, 150 * Global.ps, abs(Global.ballpos.x))
		return (Vector3(formation[posid].x, 0, formation[posid].y) * (1.0 - mxr) + Vector3(formation[posid2].x, 0, formation[posid2].y) * mxr)
	elif z == 2:
		var posid2 = pid + 2 * Global.squad
		var mxr = 0.6 + smoothstep( - 40 * Global.ps, 40 * Global.ps, (Global.ballpos.x) * - playDir) * 0.4
		return (Vector3(formation[posid].x, 0, formation[posid].y) * mxr + Vector3(formation[posid2].x, 0, formation[posid2].y) * (1.0 - mxr))
	else:
		var posid2 = pid + Global.squad
		var mxr = 0.6 + smoothstep(40 * Global.ps, 100 * Global.ps, abs(Global.ballpos.x)) * 0.4
		return Vector3(formation[posid].x, 0, formation[posid].y) * mxr + Vector3(formation[posid2].x, 0, formation[posid2].y) * (1.0 - mxr)

func _getPosessionPos( var pid, var pos, var tforce):
	
	
	
	
	
	
	
	
	
	
	if (ptarget - pos).length_squared() < 360 or tforce:
		
		var pgoal = Vector3(playDir * 130.0 * Global.ps, 0.0, formation[pid + 2 * Global.squad].y)
		pgoal = lerp(goal * 0.8, pgoal, smoothstep(12, 32, (pos.x - pgoal.x)))
		
		
		ptarget = pos - (pos - pgoal) * 0.33
		var poff = rand_range( - 1.0, 1.0)
		poff = lerp(poff, abs(poff), approach)
		ptarget.z += sign(ptarget.z) * poff * 12
		ptarget.z = max( - 90 * Global.ps, min(ptarget.z, 90 * Global.ps))
	
	return ptarget

func _getDefendPos(pid):
	
	var posid = pid + (zone - 1) * Global.squad
	var ppos
	var bp = Global.ballpos + Global.ballvel * 0.2
	if zone == 3:
		posid = pid + Global.squad
		var posid2 = posid
		var mxr = (smoothstep(100 * Global.ps, 160 * Global.ps, abs(bp.x))) * 0.25
		ppos = (Vector3(formation[posid2].x, 0, formation[posid2].y) * (1.0 - mxr) + Vector3(formation[posid].x, 0, formation[posid].y) * mxr)
	elif zone == 2:
		
		var posid2 = pid
		var mxr = smoothstep( - 40 * Global.ps, 40 * Global.ps, (bp.x) * - playDir)
		ppos = (Vector3(formation[posid].x, 0, formation[posid].y) * (1.0 - mxr)) + (Vector3(formation[posid2].x, 0.0, formation[posid2].y) * (mxr))
	else:
		
		ppos = Vector3(formation[posid].x, 0, formation[posid].y)
		
			
		
	if tdata.unitShape > 0.0:
		var unitPos = Vector3(formation[pid].x, 0, formation[pid].y)
		if tdata.midBlock > 0.0:
			unitPos = _blockByDepth(pid)
		ppos = ppos.linear_interpolate(unitPos, tdata.unitShape)
	var adjust = 10
	if sign(Global.ballpos.z) == sign(ppos.z):
		adjust = 20
	
	
	var diff = bp.z - ppos.z
	ppos.y = 0.0
	ppos.z += clamp(diff, - adjust, adjust)
	return ppos


# Where a mid-block side stands without the ball, given how far the ball is from its goal.
const BLOCK_BACK_FOUR = 4
const BLOCK_DEFENDERS_UP = 0.1
const BLOCK_OTHERS_UP = 0.3
const BLOCK_OWN_HALF = 0.52

func _blockByDepth(pid):
	var shape = tdata.def[pid - 1]
	var ballDepth = abs(Global.ballpos.x - dGoal.x)
	var far = smoothstep(80.0 * Global.ps, 200.0 * Global.ps, ballDepth) * tdata.midBlock
	var close = 1.0 - smoothstep(40.0 * Global.ps, 90.0 * Global.ps, ballDepth)
	# The four deepest in the shape (ties to whoever is listed first) are the back four.
	var deeper = 0
	for i in range(1, Global.squad):
		var other = tdata.def[i - 1].y
		if other > shape.y or (other == shape.y and i < pid):
			deeper += 1
	var up = BLOCK_DEFENDERS_UP if deeper < BLOCK_BACK_FOUR else BLOCK_OTHERS_UP
	var y = max(shape.y - up * far, BLOCK_OWN_HALF)
	y = lerp(y, y + (1.0 - y) * 0.4, close)
	var x = lerp(shape.x, 0.5 + (shape.x - 0.5) * 0.75, close)
	if playDir == 1:
		return Vector3(range_lerp(y, 0, 1, 150 * Global.ps, - 150 * Global.ps), 0, range_lerp(x, 0, 1, - 100 * Global.ps, 100 * Global.ps))
	return Vector3(range_lerp(y, 0, 1, - 150 * Global.ps, 150 * Global.ps), 0, range_lerp(x, 0, 1, 100 * Global.ps, - 100 * Global.ps))

func _getDefendFKPos(pid):
	
	var posid = pid + (zone - 1) * Global.squad
	
	if Game.fkend == playDir:
		
		match pid:
			1, 2:
				
				return _getDefendPos(pid)
				
				
			_:
				
				var cb = Game.resetPos - dGoal
				
				cb.y = 0
				return Game.resetPos - (28.0 * cb.normalized()) + (cb.normalized().cross(Vector3.UP) * 3.5 * (pid - 4.5))
	elif Game.fkend == 0:
		
		var posid2 = pid
		return Vector3(lerp(formation[posid].x, formation[posid2].x, 0.85), 0, lerp(formation[posid].y, formation[posid2].y, 0.85))
	else:
		var posid2 = pid + Global.squad
		return (Vector3(formation[posid].x, 0, formation[posid].y) * 0.25 + Vector3(formation[posid2].x, 0, formation[posid2].y) * 0.75)
	

func _getPenPosition(pid):
	match pid:
		1, 2:
			return _getSupportPos(pid)
		3:
			return Vector3(Game.penend * - 81 * Global.ps, 0, 25)
		4:
			return Vector3(Game.penend * - 66 * Global.ps, 0, 0)
		5:
			return Vector3(Game.penend * - 81 * Global.ps, 0, - 25)
		6:
			return Vector3(Game.penend * - 91 * Global.ps, 0, 0)
	
		_:
			return _getSupportPos(pid)
func _getPenDPosition( var pid):
	match pid:
		1:
			return Vector3(Game.penend * - 82 * Global.ps, 0, 23)
		2:
			return Vector3(Game.penend * - 67 * Global.ps, 0, 3)
		3:
			return Vector3(Game.penend * - 82 * Global.ps, 0, - 23)
		_:
			# Everyone else waits along the edge of the box, never in the way of the kick.
			var side = 1.0 if pid % 2 == 0 else - 1.0
			return Vector3(Game.penend * - 76 * Global.ps, 0, side * (42 + 8 * int((pid - 4) / 2)))

func _getShootoutPosition( var pid):
	var pt = 1.0
	if teamID == 2:
		pt = - 1.0
	return Vector3(0.0, 0.0, 10 + pid * 4.5) * pt
const LOCKDOWN_REACH = 40.0

func _closerToOurGoal(a, b):
	return a.translation.distance_squared_to(dGoal) < b.translation.distance_squared_to(dGoal)

func _lockdownMark(pid):
	var threats = []
	for i in range(1, Global.squad):
		var o = opponent.players[i]
		if o != Game.kickTaker and o.carded < 2:
			threats.append(o)
	if threats.empty():
		return _getDefendPos(pid)
	threats.sort_custom(self, "_closerToOurGoal")
	var slot = pid - 1
	var o = threats[slot % threats.size()]
	var toGoal = dGoal - o.translation
	toGoal.y = 0.0
	toGoal = toGoal.normalized()
	var spot = o.translation + toGoal * 3.5
	if slot >= threats.size():
		spot = o.translation + toGoal * 2.5 + toGoal.cross(Vector3.UP) * (2.5 if slot % 2 == 0 else - 2.5)
	var fromGoal = spot - dGoal
	fromGoal.y = 0.0
	if fromGoal.length() > LOCKDOWN_REACH:
		spot = dGoal + fromGoal.normalized() * LOCKDOWN_REACH
	spot.y = 0.0
	return spot

func _getMarkPosition( var pid):
	if isCorner and not Global.elevenMode and tdata.cornerLockdown > 0.0:
		return _lockdownMark(pid)
	
	if Global.elevenMode and isCorner:
		if cornerMark.has(pid):
			return opponent.players[cornerMark[pid]].translation + Vector3(playDir * - 4, 0, 0)
		return _getDefendPos(pid)
	
	var op = pid + 1
	
	if not isCorner:
		op = pid + 3
		
	if opponent.players[op] == Game.kickTaker or opponent.players[op].carded > 1:
		return _getDefendPos(pid)
		
	return opponent.players[op].translation + Vector3(playDir * - 4, 0, 0)
	
	
func _ballFree():
	
	pass
	
func _lostPosession( var moment):
	
	
	posession = false
	pplayer = null
	passto = null
	
	momentum = moment
	lostBallFrame = Engine.get_physics_frames()
	
	setDefend()
	

func _onPosession(id):
	
	if not Global.gameOn:
		return
		
	posession = true
	momentum = true
	passto = null
	
	
	Game._setCurrentPlayer(teamID, id)
	if ( not AIteam):
		_switchPControl(players[id])
	pplayer = players[id]
	closest = pplayer
	if AIteam:
		_getPosessionPos(id, pplayer.translation, true)
	setAttack()
	opponent._lostPosession(false)
	
func _switchPControl( var p):

	if AIteam or p == null:
		return
	
	for i in range(0, Global.squad):
		if (i != p.myID):
			players[i]._loseControl()
			players[i].AI.isHuman = false

	if not Global.gameOn:
		return
	
	cplayer = p
	closest = p
	cplayer._controlMe()
	Game._setCurrentPlayer(teamID, p.myID)
	
func _goal_scored():
	
	state = teamState.GOAL
	
	wescored = true
	if scorer == null:
		scorer = ball.shooter.myID
	celeb = int(rand_range(0, 5))
	pplayer = players[scorer]
	for i in range(0, players.size()):
		players[i].AI._celebrate(pplayer)
	
	if ( not AIteam):
		_switchPControl(pplayer)
	
		
	return pplayer
	
func _goal_conceded():
	state = teamState.CONCEDED
	
	for i in range(0, Global.squad):
		players[i].AI._conceded()
	wescored = false
func _setZone(z):
	zone = z
	


func noopState():
	pass
	
func lineupState():
	var pready = 0
	if Global.teamsReady[teamID - 1]:
		return
	for i in range(0, Global.squad):
		
		if (players[i].translation - players[i].AI.target).length() < 6:
			pready += 1
		if not players[i].isAI and players[i] != Game.ref.offender:
			players[i]._loseControl()
		if players[i].carded > 1:
			pready += 1
		
		players[i].AI._checkLineup()
	
			
		
	if pready > Global.squad - 1:
		Global.teamsReady[teamID - 1] = true
	
	if (Game.kickTaker.translation - Game.kickTaker.AI.target).length() < 6.0:
		Global.teamsReady[teamID - 1] = true
		
	
		
		
		
	
	
func defendState():
	
	if ( not Global.gameOn) or ball._isCaught():
		return
	var close = null






	if AIteam:
		
		close = _closestDPToBall()
		
		
	elif Global.pswitch < 1:
		close = _closestPToBallDir()
	else:
		close = closest
	
	if close != closest and closest and close:
		closest.AI._forceDefend()
	closest = close
	
	if (closest) and closest != cplayer:
		if ( not AIteam):
			_switchPControl(closest)
		else:
			closest.AI._press()
	
	elif cplayer and cplayer.isAI:
		if not AIteam:
			cplayer._controlMe()
			closest = cplayer
		else:
			cplayer.AI._press()
	
	
	for i in range(1, Global.squad):
		players[i].AI._updatePosition()
		
func attackState():
	if not Global.gameOn:
		return
	for i in range(1, Global.squad):
		players[i].AI._updatePosition()
		
	if (ball._isFree()):
		var close = null
		if AIteam:
			close = _closestPToBall()
		elif Global.pswitch < 1:
			close = _closestPToBallDir()
		else:
			close = closest
		if (close != closest) and close:
			if closest and closest.myID != 0:
				closest.AI._forceAttack()
		
		closest = close
		if closest:
			if ( not AIteam):
				if closest != cplayer or closest.isAI:
					_switchPControl(closest)
			else:
				closest.AI._press()
			
func playState():
	if not Global.gameOn:
		return
	for i in range(1, Global.squad):
		players[i].AI._updatePosition()
	print("WTF!")
	if (ball._isFree()):
		var close = null
		if AIteam:
			close = _closestPToBall()
		elif Global.pswitch < 1:
			close = _closestPToBallDir()
		else:
			close = closest
		if (close != closest) and close:
			if closest and closest.myID != 0:
				closest.AI._forceAttack()
		
		closest = close
		if closest:
			if ( not AIteam):
				if closest != cplayer or closest.isAI:
					_switchPControl(closest)
			else:
				closest.AI._press()


func _halfTime():
	state = teamState.HALFTIME
	posession = false
	for player in players:
		player.AI._pause()
		
func _fullTime( var wewon):
	state = teamState.ENDGAME
	if wewon:
		scorer = players[0].myID
		Game.goalscorer = players[0]
		for player in players:
			player.AI._celebrate(players[0])
			player.set_process(true)
			player.set_physics_process(true)
		if not AIteam:
			_switchPControl(players[0])
			players[0]._controlMe()
		activePlayers = players.size()
	else:
		for player in players:
			player.AI._conceded()
			
func _replay():
	state = teamState.REPLAY
	for i in range(0, Global.squad):
		players[i].AI._replay()


func isPenalty( var pos):
	if abs(pos.x) > 89 and abs(pos.z) < 46.5:
		
		
		if (pos.x < 0):
			Game.penend = 1
		else:
			Game.penend = - 1
		if Game.penend == playDir:
			return true
		else:
			return false
	else:
		return false
	
func _foul( var position, var offender):
	if not Global.gameOn:
		return
	
	
	
	momentum = false
	isCorner = false
	Game.resetPos = position
	Game.resetPos.y = 0.25
	
	Global.gameOn = false
	if isPenalty(Game.resetPos):
		
		state = teamState.PENALTY
		opponent.state = teamState.PEN
		
		Game._penalty(opponent.AIteam, opponent.teamID)
		Global.teamsReady[teamID - 1] = false
		for i in range(0, Global.squad):
			players[i].AI._penaltyDefend()
			players[i].isAI = true
			
		offender._say(0)
		opponent._penalty()
	
		
	else:
		
		state = teamState.FOUL
		
		ball._initialize()
		ball.translation = Game.resetPos
		
		opponent.state = teamState.FOULED
		
		offender._say(0)
		
		var d2g = abs(position.x)
		
		if sign(playDir) != sign(position.x) and d2g > 40 * Global.ps:
			Game.fkend = playDir
		else:
			Game.fkend = 0
		
		Game.fkzone = zone
		
		Game._foul(Game.resetPos, opponent, offender)
		
	
		Global.teamsReady[teamID - 1] = false
		
		
		for i in range(0, Global.squad):
			
			if players[i] != Game.ref.offender:
				if i > 0 and i < 3 and Game.fkend != 0:
					players[i].AI._mark()
				else:
					players[i].AI._defendFK()
				players[i].isAI = true
			else:
				Game.ref.offender._controlMe()
		
		opponent._fouled(Game.resetPos)
		state = teamState.LINEUP

func _ballInBox():
	
	if abs(Global.ballpos.x) > 91 * Global.ps and abs(Global.ballpos.z) < 45 * Global.ps:
		return true
	return false
	

func _fouled( var position):
	
	
	momentum = true
	Global.teamsReady[teamID - 1] = false
	
	for i in range(0, Global.squad):
		players[i].AI._attackFK()
		players[i].isAI = true
		
		players[i]._loseControl()
		
		
	
	
	# A fouled goalkeeper (AIKeeper._fouled does nothing) leaves Game.kickTaker pointing at
	# whoever took the last restart, possibly on the other team, and the free kick never
	# gets set up. Fall back to our closest available outfield player.
	if not _isValidKickTaker(Game.kickTaker):
		Game.kickTaker = _closestFreeKickTaker()
	Game.kickTaker.AI.isSP = true
	Game.kickTaker.AI.setTarget(position + dGoal * 0.06)
	state = teamState.LINEUP
	pplayer = Game.kickTaker


func _throwin( var side, var position):
	Global.teamsReady[teamID - 1] = false
	position.y = 0.1
	momentum = true
	
	Global.ballpos = position
	ball._initialize()
	for i in range(0, Global.squad):
		
		players[i].AI.target = _getPlayPos(i)
		players[i].isAI = true
		players[i].AI._kickoff()
		if i > 0:
			players[i].indicator.visible = false
		
		
	ball.translation = position
	if playDir > 0:
		side = 1 - side
	if side == 0:
		Game.kickTaker = players[2]
	else:
		Game.kickTaker = players[1]
	if Game.kickTaker.carded > 1:
		Game.kickTaker = _closestPToBall()
	pplayer = Game.kickTaker
	Game.kickTaker.AI._takeThrow(position)
	state = teamState.LINEUP
	

func _defendThrowin():
	momentum = false
	
	Global.teamsReady[teamID - 1] = false
		
	ball._ballFree()
	for i in range(0, Global.squad):
		players[i].AI._kickoff()
		players[i].AI.target = _getPlayPos(players[i].myID)
		if i < 0:
			players[i].indicator.visible = false

	state = teamState.LINEUP




func _penalty():
	
	Global.teamsReady[teamID - 1] = false
	ball._initialize()
	ball.translation = Vector3(Game.penend * - 100 * Global.ps, 1.0, 0.0)
	
	
	for i in range(0, Global.squad):
		players[i].AI._penalty()
		players[i].isAI = true
		
		players[i]._loseControl()
		if players[i].carded < 2:
			Game.kickTaker = players[i]
	pplayer = Game.kickTaker

func _corner( var side, var e):
	var posi = Vector3(138.0, 0.0, 88.0) * Global.ps
	ball._ballFree()
	if side == 0:
		posi.z = - 88.0 * Global.ps
	if e == 1:
		posi.x = - 138 * Global.ps
	Game.resetPos = posi
	Global.teamsReady[teamID - 1] = false
	
	for i in range(0, Global.squad):
		players[i].AI._corner(e, side)
		players[i].isAI = true
		
		players[i]._loseControl()
		if players[i].carded < 2:
			Game.kickTaker = players[i]
	
	# 11v11 sides and strong set-piece sides send their best crosser of the ball to the flag.
	if Global.elevenMode or tdata.setPieces > 0.5:
		Game.kickTaker = _bestCornerTaker(Game.kickTaker)
	
	Game.kickTaker.AI.setTarget(posi + posi * 0.04)
	state = teamState.LINEUP
	pplayer = Game.kickTaker
	
func _defendCorner():
	Global.teamsReady[teamID - 1] = false
	ball._ballFree()
	isCorner = true
	if Global.elevenMode:
		_elevenDefendCorner()
		state = teamState.LINEUP
		return
	for i in range(0, Global.squad):
		if i > 0 and tdata.cornerLockdown > 0.0:
			players[i].AI._mark()
			players[i].indicator.visible = false
			continue
		match i:
			0:
				players[i].AI._defendCorner()
			1, 2, 3, 4:
				players[i].AI._mark()
				players[i].indicator.visible = false
			_:
				players[i].AI._kickoff()
				players[i].AI.target = _getDefendPos(players[i].myID)
				players[i].indicator.visible = false
	state = teamState.LINEUP
	
func _goalkick( var side, var e):
	ball._ballFree()
	momentum = true
	var posi = Vector3(119.0, 0.0, 25.0)
	if side == 0:
		posi.z = - 25.0
	if e == 1:
		posi.x = - 119
	Game.resetPos = posi
	Global.teamsReady[teamID - 1] = false
	
	for i in range(0, Global.squad):
		players[i].AI._kickoff()
		if i > 0:
			players[i].AI.target = _getGoalKickPos(i)
		
		players[i].isAI = true
		
		players[i]._loseControl()
	
	Game.kickTaker = players[0]
	players[0].AI.setTarget(posi + Vector3( - 6, 0, 0) * playDir)
	state = teamState.LINEUP
	pplayer = Game.kickTaker
	
func _defendGoalkick():
	ball._ballFree()
	momentum = false
	for i in range(0, Global.squad):
		players[i].AI._kickoff()
		players[i].AI.target = _getPlayPos(players[i].myID) - Vector3(30.0 * Global.ps * playDir, 0, 0)
		

	state = teamState.LINEUP
func _defendCaught():
	momentum = false
	for i in range(1, Global.squad):
		players[i].AI._kickoff()
		Game.fkzone = 2
		players[i].AI.target = _getPlayPos(players[i].myID)
		

func _on_AITimer_timeout():
	
	stateFunc[state].call_func()

func _caughtBall():
	
	for i in range(1, Global.squad):
		players[i].AI._losePosession()
	momentum = true
	setAttack()
	opponent._defendCaught()

func _shotIncoming( var pos, var dir):
	if AIteam or Global.elevenMode:
		for i in range(1, Global.squad):
			if abs(players[i].translation.x) > abs(pos.x) and abs(players[i].translation.x) > 70 * Global.ps:
				if dir.y < 35 and players[i].isAI:
					players[i].AI._blockShot(pos, dir)
				
				

func _shot( var id, var shotV, var curl, var stype):
	
	
	
	Game.shottype = stype
	scorer = id
	opponent.players[0].AI._shotIncoming(Global.ballpos, shotV, curl, stype)
	opponent._shotIncoming(Global.ballpos, shotV)
func _pshot( var id, var shotV, var curl, var stype, var isfk):
	
	
	
	Game.shottype = stype
	scorer = id
	opponent.players[0].AI._penShotIncoming(Global.ballpos, shotV, curl, isfk)
	opponent._shotIncoming(Global.ballpos, shotV)

func _cross( var _id):
	
	
	
	pass
	
	
	
func shootoutState():
	var pready = 0
	for p in players:
		if (p.translation - p.target).length() < 6:
			pready += 1
		if not p.isAI:
			p._loseControl()
		
		p.AI._checkLineup()
	if pready > Global.squad - 1:
		Global.teamsReady[teamID - 1] = true

func _shootout():
	
	Global.teamsReady[teamID - 1] = false
	ball._initialize()
	playDir = 1
	state = teamState.SHOOTOUT
	for i in range(0, Global.squad):
		players[i].AI._shootout()
		players[i].isAI = true
		
		players[i]._loseControl()
	
func _shootoutKick( var kn):
	
	players[0].AI._shootout()
	
	players[6 - kn].AI._penaltyTaker()
	return players[6 - kn]
func _shootoutDefend():
	
	players[0].AI._defendPen(AIteam)
func _savedPen():
	
	yield(get_tree().create_timer(0.5), "timeout")
	Game._shootoutMissed()
	
func _ballHit():
	
	if not Global.gameOn or not ball._isFree():
		return
	
	if posession:
		_lostPosession(zone > 2)
	else:
		momentum = zone > 2
		closest = null
	
		closest = _closestPToBall()
		if closest and AIteam:
			closest.AI._press()
func _goGame():
	if not Global.penOn:
		Game.goGamePen()
	
func _defendRebound():
	
	
	momentum = false
	var p = _closestDPToBall()
	if p and AIteam:
		closest = p
		p.AI._press()
	
func _attackRebound():
	
	momentum = true
	var p = _closestPToBall()
	if p and AIteam:
		closest = p
		p.AI._press()
	
		
	
func _winners():
	for player in players:
		player.AI._winner()
	
func _rebound():
	if not Global.gameOn:
		return
	
	
	
	
	if zone > 1:
		momentum = true
		setAttack()
	else:
		momentum = false
		setDefend()
	

func _calcPositions():
	var c = 100000
	var dg = 0
	for i in range(1, Global.squad):
		p2b[i] = players[i].translation - Global.ballpos + Global.ballvel * players[i].dSmart
		d2p2b[i] = p2b[i].length_squared()
		dg = (dGoal - players[i].translation).length_squared()
		if dg < c:
			c = dg
			closestToGoal = i
func bias( var x, var a):
	return x / ((1.0 / a - 2) * (1.0 - x) + 1.0)
	
func _activateThrow( var thrower):
	var cl = 500000
	var clp = null
	for i in range(1, Global.squad):
		if d2p2b[i] < cl and players[i] != thrower:
			cl = d2p2b[i]
			clp = players[i]
	
	if clp:
		if not AIteam:
			clp._controlMe()
		
		throwTarget = clp
	
	
	cl = 500000
	clp = null
	for i in range(1, Global.squad):
		if opponent.d2p2b[i] < cl:
			cl = opponent.d2p2b[i]
			clp = opponent.players[i]
	if clp:
		clp.AI._markThrowtarget(throwTarget)

func _lapOfHonour():
	celebTarget.append(Vector3(135, 0, 90) * Global.ps)
	celebTarget.append(Vector3(135, 0, - 90) * Global.ps)
	celebTarget.append(Vector3( - 135, 0, - 90) * Global.ps)
	celebTarget.append(Vector3( - 135, 0, 90) * Global.ps)
	for player in players:
		player.AI._lapOfHonour()
		player.pSpeed = rand_range(5, 10)
		player.pOSpeed = player.pSpeed
	
func _getLapTarget( var i):
	return celebTarget[i]

func _updateCamChange():
	cud = 1
	clr = 0
	jflip = 1
	if Global.camrot:
		cud = 0
		clr = 1
		jflip = - 1
	for player in players:
		player.cud = cud
		player.clr = clr
		player.jflip = jflip

func _isValidKickTaker(p):
	if p == null or not is_instance_valid(p):
		return false
	if p.myTeam != self or p == players[0]:
		return false
	return p.carded < 2

func _closestFreeKickTaker():
	var best = null
	var dist = INF
	for i in range(1, Global.squad):
		var p = players[i]
		if p.carded > 1:
			continue
		var d = (p.translation - Game.resetPos).length_squared()
		if d < dist:
			best = p
			dist = d
	if best == null:
		best = players[1]
	return best

# --- 11v11 tactics --------------------------------------------------------------------
const CORNER_MARKERS = [3, 4, 6, 8, 7, 1, 2, 5, 9, 10]
const CORNER_OUTLET_POOL = [5, 9, 10]
# Zonal spots as [distance from the goal line, distance toward the corner taker's side].
const CORNER_ZONES = [[3.0, 11.0], [3.0, - 11.0], [18.0, 0.0], [18.0, 16.0], [18.0, - 16.0], [36.0, 8.0], [36.0, - 8.0], [58.0, 14.0], [58.0, - 14.0], [46.0, 0.0]]
const COUNTER_WINDOW_MS = 6000

var wonBallAt = 0
var cornerMark = {}

# Extra pull toward the most advanced runner in the seconds after winning the ball.
func _counterBonus():
	var counter = tdata.counter + COMEBACK_COUNTER * _comebackBoost()
	if counter <= 0.0 or OS.get_ticks_msec() - wonBallAt > COUNTER_WINDOW_MS:
		return 0.0
	return counter * 2.5

# --- Comeback ---------------------------------------------------------------------------
const COMEBACK_PRESS = 0.3      # team aggression rises by up to 0.3 (on a 0-1 scale)
const COMEBACK_TACKLE = 0.3     # each player's tackling eagerness rises by up to 0.3
const COMEBACK_COUNTER = 0.6    # the counter-attack setting rises by up to 0.6

# 0 when level or ahead, 0.5 one goal down, 1 when two or more down.
func _comebackBoost():
	if tdata.get("comeback") == null or tdata.comeback <= 0.0 or Game == null or Game.get("score") == null:
		return 0.0
	var mine = Game.score.x if teamID == 1 else Game.score.y
	var theirs = Game.score.y if teamID == 1 else Game.score.x
	return tdata.comeback * min(max(theirs - mine, 0.0), 2.0) * 0.5

func _aggressionNow():
	return min(aggression + COMEBACK_PRESS * _comebackBoost(), 1.0)

# Best delivery among the players not assigned to the box.
func _bestCornerTaker(fallback):
	var best = null
	for i in range(1, Global.squad):
		var p = players[i]
		if p.carded < 2 and tdata.cor[i - 1].y >= 0.2 and (best == null or p.pCurl > best.pCurl):
			best = p
	return best if best else fallback

func _cornerOutletIds():
	var pool = []
	for id in CORNER_OUTLET_POOL:
		if players[id].carded < 2:
			pool.append(id)
	pool.sort_custom(self, "_fasterFirst")
	return pool.slice(0, tdata.cornerOutlets - 1) if tdata.cornerOutlets > 0 else []

func _fasterFirst(a, b):
	return players[a].pSpeed > players[b].pSpeed

func _elevenDefendCorner():
	var attackers = []
	for i in range(1, Global.squad):
		var o = opponent.players[i]
		if o != Game.kickTaker and o.carded < 2 and opponent.tdata.cor[i - 1].y < 0.2:
			attackers.append(i)
	var outlets = _cornerOutletIds()
	var inward = - sign(dGoal.x)
	var kickSide = sign(Game.resetPos.z)
	var zone = 0
	var outlet = 0
	cornerMark.clear()
	players[0].AI._defendCorner()
	for pid in CORNER_MARKERS:
		var p = players[pid]
		p.indicator.visible = false
		if outlets.has(pid):
			p.AI._kickoff()
			p.AI.target = Vector3(sign(dGoal.x) * 8.0, 0.0, 40.0 * (1 - 2 * outlet))
			p.AI.atarget = p.AI.target
			outlet += 1
		elif attackers.size() > 0:
			cornerMark[pid] = attackers.pop_front()
			p.AI._mark()
		else:
			p.AI._kickoff()
			if zone < CORNER_ZONES.size():
				p.AI.target = Vector3(dGoal.x + inward * CORNER_ZONES[zone][0] * Global.ps / Global.ELEVEN_DESIGN_SCALE, 0.0, kickSide * CORNER_ZONES[zone][1])
			else:
				p.AI.target = _getDefendPos(pid)
			p.AI.atarget = p.AI.target
			zone += 1

# --- 11v11 crossing -------------------------------------------------------------------
# [distance from the goal line, distance toward the ball's side] for players attacking a cross.
const BOX_RUN_SLOTS = [[14.0, 10.0], [18.0, - 2.0], [16.0, - 12.0], [34.0, 4.0], [40.0, - 12.0]]

var boxRunFrame = - 1
var boxRunners = []

func _boxRunActive():
	if tdata.crossing < 0.35 or not posession or zone != 3:
		return false
	return abs(Global.ballpos.z) > 38.0 * Global.ps or ball._isCrossing()

func _aerialFirst(a, b):
	return a.pAerial > b.pAerial

func _boxRun(pid):
	if pid == 0 or players.size() <= pid or not _boxRunActive():
		return null
	var frame = Engine.get_idle_frames()
	if frame != boxRunFrame:
		boxRunFrame = frame
		boxRunners.clear()
		for i in range(1, Global.squad):
			if players[i] != pplayer and players[i].carded < 2:
				boxRunners.append(players[i])
		boxRunners.sort_custom(self, "_aerialFirst")
		boxRunners.resize(min(boxRunners.size(), int(round(lerp(2.0, 5.0, tdata.crossing)))))
	var slot = boxRunners.find(players[pid])
	if slot < 0:
		return null
	var inward = - sign(goal.x)
	return Vector3(goal.x + inward * BOX_RUN_SLOTS[slot][0], 0.0, sign(Global.ballpos.z) * BOX_RUN_SLOTS[slot][1])

# Picks the best header of the ball in the box; better teams find him more often.
func _crossTarget(crosser, low = false):
	var quality = lerp(0.25, 0.95, max(tdata.crossing, tdata.setPieces))
	if randf() > quality:
		return null
	var best = null
	for i in range(1, Global.squad):
		var p = players[i]
		if p == crosser or p.carded > 1 or _isOffsidePosition(p):
			continue
		if abs(p.translation.x - goal.x) < 53.0 * Global.ps and abs(p.translation.z) < 50.0 * Global.ps:
			if best == null:
				best = p
			elif low and p.translation.distance_squared_to(goal) < best.translation.distance_squared_to(goal):
				best = p
			elif not low and p.pAerial > best.pAerial:
				best = p
	if best == null:
		return null
	var miss = lerp(9.0, 2.5, max(tdata.crossing, tdata.setPieces))
	return best.translation + Vector3(rand_range( - miss, miss), 0.0, rand_range( - miss, miss))

# --- 11v11 offside --------------------------------------------------------------------
# Supporting attackers stay level with the second-last opponent, or the ball if it is further
# forward. Runs onto a pass use their own states, so through balls can still beat the line.
const ONSIDE_MARGIN = 2.0

var onsideFrame = - 1
var onsideLine = 0.0

func _onsideLine():
	var frame = Engine.get_idle_frames()
	if frame != onsideFrame:
		onsideFrame = frame
		var depths = []
		for o in opponent.players:
			depths.append(o.translation.x * playDir)
		depths.sort()
		var secondLast = depths[depths.size() - 2]
		onsideLine = max(max(secondLast, Global.ballpos.x * playDir), 0.0)
	return onsideLine

func _keepOnside(p, pid):
	if not Global.gameOn or players[pid] == pplayer:
		return p
	var limit = _onsideLine() - ONSIDE_MARGIN
	if p.x * playDir > limit:
		p = Vector3(limit * playDir, p.y, p.z)
	return p

# Offside position, judged when the ball is played: in the opponents' half, ahead of the
# ball, and ahead of the second-last opponent.
func _isOffsidePosition(p):
	var depth = p.translation.x * playDir
	if depth <= 0.0 or depth <= ball.translation.x * playDir:
		return false
	var depths = []
	for o in opponent.players:
		if o.carded < 2:
			depths.append(o.translation.x * playDir)
	depths.sort()
	return depths.size() >= 2 and depth > depths[depths.size() - 2]

func _offsidePlayers(kicker):
	var flagged = {}
	for i in range(1, Global.squad):
		if players[i] != kicker and _isOffsidePosition(players[i]):
			flagged[players[i]] = true
	return flagged

func _offsideCalled(offender):
	if not Global.gameOn:
		return
	momentum = false
	isCorner = false
	Game.resetPos = offender.translation
	Game.resetPos.y = 0.25
	Global.gameOn = false
	state = teamState.FOUL
	ball._initialize()
	ball.translation = Game.resetPos
	opponent.state = teamState.FOULED
	Game.fkend = playDir if sign(playDir) != sign(Game.resetPos.x) and abs(Game.resetPos.x) > 40 * Global.ps else 0
	Game.fkzone = zone
	Game._offsideCall(opponent)
	Global.teamsReady[teamID - 1] = false
	for i in range(0, Global.squad):
		players[i].AI._defendFK()
		players[i].isAI = true
	opponent._fouled(Game.resetPos)
	state = teamState.LINEUP
