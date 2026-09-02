
extends Spatial
const MP_SNAPSHOT_INTERVAL = 0.033
const MP_GAME_STATE_EXPRESSION = "window.slsMultiplayerGetGameState ? window.slsMultiplayerGetGameState() : '{}'"
const MP_GAME_STATE_VERSION_EXPRESSION = "window.slsMultiplayerGetGameStateVersion ? window.slsMultiplayerGetGameStateVersion() : '0'"
const MP_REMOTE_KEYS_EXPRESSION = "window.slsMultiplayerDrainRemoteKeys ? window.slsMultiplayerDrainRemoteKeys() : '[]'"


var ball
var team1
var team2
var score
var t1scorer = []
var t2scorer = []
var goalscorer
var team1Scored: bool
var half = 0
enum gameState{LINEUP, INTRO, SETUP, GAMEON, HALFTIME, GAMEOVER, GOAL, CELEBRATE, REPLAY, HIGHLIGHTS, PAUSE, FREEKICK, PENALTY, PENSETUP, FKSETUP, RESTART, RESTARTPENAI, RESTARTFK, RESTARTFKAI, GOALKICK, THROWIN, CORNER, RESTARTTHROW, RESTARTTHROWAI, SHOOTOUT, GOSHOOTOUT, T1TAKE, T2TAKE, TAKEPEN, TAKEPENAI, PICKSUB, DOSUB, SUBON, BOOKING, WINNER, LAP}
var gameFunc = {}
var state
var hud
enum shotType{SHOT, VOLLEY, FREEKICK, HEADER, DIVINGHEADER, BICYCLE, OWNGOAL, DEFLECTED}
var shottype = 0

var recording: bool
var frame: int
var fframe: float
var slowframe: int
var startframe: int
var userscrub: bool
var replayCam
var mainCam
var replayBall
var scoredGoal
var goal1Sim
var goal2Sim
var penend = 1
var fkend = 1
onready var gametimer = $Timers / GameTime

var targetgoal = null
var fkdir = Vector3.ZERO
var fkcurl = Vector3.ZERO
var fkai = false
var fkteam = 1
var shootoutCount = 0
var fkshoot = "p1_shoot"
var fkpass = "p1_pass"
var fkchip = "p1_chip"
var fktype = 1
var fktarget = null
var kickTaker = null
var kickTeam = null
var saveTeam = null
var fkzone = 1
var bs = null
var resetPos = Vector3(0, 2, 0)
var halftime = false

var rPos: PoolVector3Array
var rRot: PoolVector3Array
var rVel: PoolVector3Array


var goal1Cams = []
var goal2Cams = []
var currCam = 0
var vp = null

var pmat = null
var sprites = []
var wcount = 0
var blobs = null
var ref = null


var cplayer = 1
var splayer = 7
var needSub = false
var nextState = 0
var subteam = null

signal ballpos(pos)


var penTarget = null
var penTeam = null
var penAITeam = null
var fkmov = Vector2.ZERO
var kmov = Vector2.ZERO

var awayFans = null


var worldEnv = null
var mp_replica = false
var mp_snapshot_elapsed = 0.0
var mp_last_snapshot_version = 0
var mp_last_presented_state = -1
func initTeams():
	team1 = $VPC / VP / GameGroup / Team
	team1.opponent = $VPC / VP / GameGroup / Team2
	team1.ball = ball
	team2 = $VPC / VP / GameGroup / Team2
	team2.opponent = $VPC / VP / GameGroup / Team
	team2.ball = ball
	team1.Game = self
	team2.Game = self
	
	if ( not Global.p1alt):
		team1.shirtColor = Global.t1.Shirt1Color
		team1.shirtColor2 = Global.t1.Shirt2Color
		team1.shirtColor3 = Global.t1.Shirt3Color
		team1.shortColor = Global.t1.ShortColor
	else:
		team1.shirtColor = Global.t1.altShirt1Color
		team1.shirtColor2 = Global.t1.altShirt2Color
		team1.shirtColor3 = Global.t1.altShirt3Color
		team1.shortColor = Global.t1.altShortColor
	if ( not Global.p2alt):
		team2.shirtColor = Global.t2.Shirt1Color
		team2.shirtColor2 = Global.t2.Shirt2Color
		team2.shirtColor3 = Global.t2.Shirt3Color
		team2.shortColor = Global.t2.ShortColor
	else:
		team2.shirtColor = Global.t2.altShirt1Color
		team2.shirtColor2 = Global.t2.altShirt2Color
		team2.shirtColor3 = Global.t2.altShirt3Color
		team2.shortColor = Global.t2.altShortColor
	
	team1.numberColor = Global.t1.numberColor
	team2.numberColor = Global.t2.numberColor
	team1.keeperColor = Global.t1.KeeperColor
	team2.keeperColor = Global.t2.KeeperColor
	
	team1.tictacs = Global.t1.tictacs * 0.1
	team2.tictacs = Global.t2.tictacs * 0.1
	team1.approach = Global.t1.approach * 0.1
	team2.approach = Global.t2.approach * 0.1
	team1.aggression = Global.t1.aggression * 0.1
	team2.aggression = Global.t2.aggression * 0.1


func initStadium():
	var stad
	var camenv = "res://Res/SmallStadiumEnv.tres"

	

	
	
	
	
	

	
	
	
	
	
	
	
	
	stad = "res://Scenes/SmallStadium.tscn"

	var gs = load(stad).instance()
	gs.name = "Stadium"
	$VPC / VP / GameGroup.add_child(gs)
	awayFans = gs.find_node("AwayFans")
	
	
	var gfx = Global.config.get_value("gfx", "quality")
	var docrowd = Global.config.get_value("gfx", "docrowd")
	
	if (gfx > 0) and docrowd:
		$VPC / VP / GameGroup / Stadium._initCrowd()
		$VPC / VP / GameGroup / Stadium._applause()
	
	
	
	
	
	
	
	var ce = load(camenv)
	$VPC / VP / GameGroup / WorldEnvironment.set_environment(ce)
	$VPC / VP / GameGroup / AltCameras / WinnerCamera.set_environment(ce)
	worldEnv = ce
	penTarget = $VPC / VP / GameGroup / Goal / Target
	
	$VPC / VP / GameGroup / Stadium._setShadows()
	

func _ready():
	
	Global._fadeOut()
	Global.game = self
	Global.isTutorial = false
	frame = 0
	fframe = 0.0
	set_process(false)
	var rt = get_tree().get_root()
	print(rt.size.x, " ", rt.size.y)
	
	if rt.size.x != Global.vpRes[0]:
		$VPC / VP.size.x = rt.size.x
		$VPC / VP.size.y = rt.size.y
	else:
		$VPC / VP.size.x = Global.vpRes[0]
		$VPC / VP.size.y = Global.vpRes[1]
	
	
	
	
	
	vp = $VPC / VP
	
	Global.gameOn = false
	hud = $Hud
	ball = $VPC / VP / GameGroup / Ball
	
	
	
	gameFunc[gameState.LINEUP] = funcref(self, "goIntro")
	gameFunc[gameState.INTRO] = funcref(self, "goSetup")
	gameFunc[gameState.GAMEON] = funcref(self, "_noop")
	gameFunc[gameState.HALFTIME] = funcref(self, "_noop")
	
	gameFunc[gameState.SETUP] = funcref(self, "checkReady")
	gameFunc[gameState.CELEBRATE] = funcref(self, "replay")
	gameFunc[gameState.REPLAY] = funcref(self, "kickOff")
	gameFunc[gameState.GOAL] = funcref(self, "Goal")
	gameFunc[gameState.FREEKICK] = funcref(self, "freeKick")
	gameFunc[gameState.GAMEOVER] = funcref(self, "fullTime")
	gameFunc[gameState.PENALTY] = funcref(self, "penalty")
	gameFunc[gameState.PENSETUP] = funcref(self, "penSetup")
	gameFunc[gameState.FKSETUP] = funcref(self, "fkSetup")
	gameFunc[gameState.THROWIN] = funcref(self, "throwSetup")
	gameFunc[gameState.GOALKICK] = funcref(self, "goalkickSetup")
	gameFunc[gameState.CORNER] = funcref(self, "cornerSetup")
	
	gameFunc[gameState.RESTART] = funcref(self, "restartPen")
	gameFunc[gameState.RESTARTPENAI] = funcref(self, "restartPenAI")
	
	gameFunc[gameState.RESTARTFK] = funcref(self, "restartFk")
	gameFunc[gameState.RESTARTFKAI] = funcref(self, "restartFKAI")
	gameFunc[gameState.RESTARTTHROW] = funcref(self, "restartThrow")
	gameFunc[gameState.RESTARTTHROWAI] = funcref(self, "restartThrowAI")
	gameFunc[gameState.SHOOTOUT] = funcref(self, "startShootout")
	gameFunc[gameState.TAKEPEN] = funcref(self, "takePen")
	gameFunc[gameState.TAKEPENAI] = funcref(self, "takePenAI")
	gameFunc[gameState.T1TAKE] = funcref(self, "goShootoutT1")
	gameFunc[gameState.T2TAKE] = funcref(self, "goShootoutT2")
	gameFunc[gameState.PICKSUB] = funcref(self, "pickSub")
	gameFunc[gameState.DOSUB] = funcref(self, "doSub")
	gameFunc[gameState.SUBON] = funcref(self, "subOn")
	gameFunc[gameState.BOOKING] = funcref(self, "bookingPlayer")
	gameFunc[gameState.WINNER] = funcref(self, "doWinner")
	gameFunc[gameState.LAP] = funcref(self, "checkLap")
	
	Global.game = self
	
	
	rPos.resize(360)
	rRot.resize(360)
	rVel.resize(360)
	
	
	score = Vector2(0, 0)
	
	
	
	
		
	replayBall = $VPC / VP / GameGroup / ReplayBall
	
	initStadium()
	initTeams()
	
	goal1Sim = $VPC / VP / GameGroup / Goal / Nets._initNet(ball, $VPC / VP / GameGroup / Goal.translation, true)
	goal2Sim = $VPC / VP / GameGroup / Goal2 / Nets._initNet(ball, $VPC / VP / GameGroup / Goal2.translation, false)

	goal1Sim._initialize()
	goal2Sim._initialize()
	goal1Sim._setStantion($VPC / VP / GameGroup / Goal / SP1.translation, $VPC / VP / GameGroup / Goal / SP2.translation, $VPC / VP / GameGroup / Goal / ThreeDLine1, $VPC / VP / GameGroup / Goal / ThreeDLine2)
	goal2Sim._setStantion($VPC / VP / GameGroup / Goal2 / SP1.translation, $VPC / VP / GameGroup / Goal2 / SP2.translation, $VPC / VP / GameGroup / Goal2 / ThreeDLine1, $VPC / VP / GameGroup / Goal2 / ThreeDLine2)
	goal1Sim._calcNet()
	goal2Sim._calcNet()
	goal1Sim.call_deferred("_endNet")
	goal2Sim.call_deferred("_endNet")
	
	hud.team1_col = team1.shirtColor
	hud.team2_col = team2.shirtColor
	
	hud._initializeHud()
	var _foo = connect("ballpos", hud, "_updateMapBall")
	goal1Cams.append($VPC / VP / GameGroup / Replays / ReplayCamera1A)
	goal1Cams.append($VPC / VP / GameGroup / Replays / ReplayCamera1B)
	goal1Cams.append($VPC / VP / GameGroup / Replays / ReplayCamera1C)
	goal1Cams.append($VPC / VP / GameGroup / Replays / ReplayCamera1D)
	goal1Cams.append($VPC / VP / GameGroup / Replays / ReplayCamera1E)
	
	goal2Cams.append($VPC / VP / GameGroup / Replays / ReplayCamera2A)
	goal2Cams.append($VPC / VP / GameGroup / Replays / ReplayCamera2B)
	goal2Cams.append($VPC / VP / GameGroup / Replays / ReplayCamera2C)
	goal2Cams.append($VPC / VP / GameGroup / Replays / ReplayCamera2D)
	goal2Cams.append($VPC / VP / GameGroup / Replays / ReplayCamera2E)
	
	goal1Cams.shuffle()
	goal2Cams.shuffle()
	replayCam = goal1Cams
	replayCam[currCam]._setTarget(replayBall)
	userscrub = false
	
		
		
	
	$Sounds / CrowdSounds.playing = true
	$Sounds / CrowdSounds.volume_db = - 15
	ref = $VPC / VP / GameGroup / Ref
	
	
	
	Global.ballpos = ball.translation
	resetPos = Global.ballpos
	_firstHalf()
	

	
	ball.trail = $VPC / VP / GameGroup / Trailz
	$VPC / VP / GameGroup / Trailz.ball = ball
	
	
	mainCam = $VPC / VP / GameGroup / Camera
	hud._setMap(1)

	match Global.config.get_value("gfx", "camtype"):
		0:
			mainCam = $VPC / VP / GameGroup / Camera
			hud._setMap(0)
			worldEnv.dof_blur_far_distance = Global.config.get_value("gfx", "camdof")
		1:
			mainCam = $VPC / VP / GameGroup / AltCameras / CameraTopUD
			hud._setMap(1)
			worldEnv.dof_blur_far_distance = Global.config.get_value("gfx", "camUDdof")
		2:
			mainCam = $VPC / VP / GameGroup / AltCameras / CameraTopLR
			hud._setMap(0)
			worldEnv.dof_blur_far_distance = Global.config.get_value("gfx", "camLRdof")

	ref.game = self
	
	mainCam.call_deferred("_setGame", self)
	blobs = $VPC / VP / GameGroup / Blobs
	
	if Global.shadtype > 0:
		var viewmat = null
		match Global.shadtype:
			1:
				viewmat = load("res://Materials/ToonMaterial.tres")
			2:
				viewmat = load("res://Materials/retroGame.tres")
			3:
				viewmat = load("res://Materials/retroGame8.tres")
		
		$VPC.material = viewmat
	
	mainCam.current = true
	
	PokiSDK.gameplayStart()
	if _mp_is_replica():
		_mp_enable_replica()


func _mp_is_replica():
	return Global.multiplayer_mode and not Global.multiplayer_host


func _mp_enable_replica():
	mp_replica = true
	recording = false
	Global.gameOn = false
	mp_last_presented_state = -1
	mainCam.set_process(true)
	for timer in $Timers.get_children():
		if timer.has_method("stop"):
			timer.stop()
	ball.mode = RigidBody.MODE_STATIC
	ball.linear_velocity = Vector3.ZERO
	ball.set_physics_process(false)
	ref.set_physics_process(false)
	for current_team in [team1, team2]:
		for player in current_team.players:
			player.myATree.active = true
			player.set_process(false)
			player.set_physics_process(false)
			player.AI.set_process(false)
			player.AI.set_physics_process(false)
	set_process(true)
	set_physics_process(true)


func _mp_apply_remote_controls():
	if not Global.multiplayer_mode or not Global.multiplayer_host:
		return
	var raw_keys = JavaScript.eval(MP_REMOTE_KEYS_EXPRESSION, true)
	if typeof(raw_keys) != TYPE_STRING:
		return
	var keys = parse_json(raw_keys)
	if typeof(keys) != TYPE_ARRAY:
		return
	for key_event in keys:
		if typeof(key_event) != TYPE_DICTIONARY:
			continue
		var action = _mp_action_for_key(str(key_event.get("code", "")))
		if action == "":
			continue
		if bool(key_event.get("down", false)):
			Input.action_press(action)
		else:
			Input.action_release(action)


func _mp_action_for_key(code):
	match code:
		"ArrowUp": return "p2_up"
		"ArrowDown": return "p2_down"
		"ArrowLeft": return "p2_left"
		"ArrowRight": return "p2_right"
		"KeyH": return "p2_pass"
		"KeyJ": return "p2_shoot"
		"KeyK": return "p2_chip"
		"KeyL": return "p2_thru"
		"KeyU": return "p2_burst"
		"KeyI": return "p2_switch"
		"KeyO": return "p2_low"
	return ""


func _mp_publish_replica_state(delta):
	if not Global.multiplayer_mode or not Global.multiplayer_host:
		return
	mp_snapshot_elapsed += delta
	if mp_snapshot_elapsed < MP_SNAPSHOT_INTERVAL:
		return
	mp_snapshot_elapsed = 0.0
	var players = []
	var rendered_ball = replayBall if state == gameState.REPLAY else ball
	for current_team in [team1, team2]:
		for player_index in range(min(7, current_team.players.size())):
			var player = current_team.players[player_index]
			var animation = player.AI.astate
			if state == gameState.REPLAY:
				animation = player.myRoot._getState()
			players.append([player.translation.x, player.translation.y, player.translation.z, player.rotation.x, player.rotation.y, player.rotation.z, animation])
	var referee_state = [ref.translation.x, ref.translation.y, ref.translation.z, ref.rotation.x, ref.rotation.y, ref.rotation.z, ref.state, ref.myAPlayer.current_animation]
	var snapshot = {
		"ball": [rendered_ball.translation.x, rendered_ball.translation.y, rendered_ball.translation.z, rendered_ball.rotation.x, rendered_ball.rotation.y, rendered_ball.rotation.z, rendered_ball.linear_velocity.x, rendered_ball.linear_velocity.y, rendered_ball.linear_velocity.z],
		"players": players,
		"referee": referee_state,
		"score": [score.x, score.y],
		"state": state,
		"time": gametimer.time_left,
		"game_on": Global.gameOn,
		"half": half
	}
	JavaScript.eval("window.slsMultiplayerPublishGameState && window.slsMultiplayerPublishGameState(" + to_json(snapshot) + ")", true)


func _mp_apply_replica_state():
	var version = int(JavaScript.eval(MP_GAME_STATE_VERSION_EXPRESSION, true))
	if version <= mp_last_snapshot_version:
		return
	var raw_state = JavaScript.eval(MP_GAME_STATE_EXPRESSION, true)
	if typeof(raw_state) != TYPE_STRING:
		return
	var snapshot = parse_json(raw_state)
	if typeof(snapshot) != TYPE_DICTIONARY:
		return
	mp_last_snapshot_version = version
	var remote_state = int(snapshot.get("state", state))
	var rendered_ball = replayBall if remote_state == gameState.REPLAY else ball
	var ball_state = snapshot.get("ball", [])
	if typeof(ball_state) == TYPE_ARRAY and ball_state.size() >= 9:
		rendered_ball.translation = Vector3(ball_state[0], ball_state[1], ball_state[2])
		rendered_ball.rotation = Vector3(ball_state[3], ball_state[4], ball_state[5])
		rendered_ball.linear_velocity = Vector3(ball_state[6], ball_state[7], ball_state[8])
	var player_states = snapshot.get("players", [])
	if typeof(player_states) == TYPE_ARRAY:
		var player_number = 0
		for current_team in [team1, team2]:
			for player_index in range(min(7, current_team.players.size())):
				if player_number >= player_states.size():
					break
				var player_state = player_states[player_number]
				if typeof(player_state) == TYPE_ARRAY and player_state.size() >= 6:
					var player = current_team.players[player_index]
					player.translation = Vector3(player_state[0], player_state[1], player_state[2])
					player.rotation = Vector3(player_state[3], player_state[4], player_state[5])
					if player_state.size() >= 7:
						player._mp_apply_visual_state(str(player_state[6]))
				player_number += 1
	_mp_apply_referee_state(snapshot.get("referee", []))
	var remote_score = snapshot.get("score", [])
	if typeof(remote_score) == TYPE_ARRAY and remote_score.size() >= 2:
		score = Vector2(remote_score[0], remote_score[1])
		hud._setScore(score.x, score.y)
	state = remote_state
	half = int(snapshot.get("half", half))
	Global.gameOn = bool(snapshot.get("game_on", false))
	_mp_apply_replica_presentation()
	Global.ballpos = rendered_ball.translation
	Global.ballvel = rendered_ball.linear_velocity
	var time_left = float(snapshot.get("time", gametimer.time_left))
	hud._updateTime(time_left / 60.0, fmod(time_left, 60.0))
	emit_signal("ballpos", rendered_ball.translation)
func _mp_apply_referee_state(referee_state):
	if typeof(referee_state) != TYPE_ARRAY or referee_state.size() < 8:
		return
	ref.translation = Vector3(referee_state[0], referee_state[1], referee_state[2])
	ref.rotation = Vector3(referee_state[3], referee_state[4], referee_state[5])
	ref.state = int(referee_state[6])
	var animation = str(referee_state[7])
	if animation != "" and ref.myAPlayer.current_animation != animation:
		ref.myAPlayer.play(animation)


func _mp_apply_replica_presentation():
	if mp_last_presented_state == state:
		return
	mp_last_presented_state = state
	if state == gameState.REPLAY:
		ball.visible = false
		replayBall.visible = true
		mainCam.current = true
		mainCam._setTarget(replayBall)
	else:
		ball.visible = true
		replayBall.visible = false
		mainCam.current = true
		mainCam._setTarget(ball)
	
func _noop():
	pass
func _firstHalf():
	hud._showTeams()
	hud._clearTrans()
	Global.stats.stats_dict.games_played += 1
	fktype = 1
	team1.playDir = 1
	Global.halfDone = false
	team1.goal = $VPC / VP / GameGroup / Goal2 / Center.get_global_transform().origin
	team1.goalL = $VPC / VP / GameGroup / Goal2 / Left.get_global_transform().origin
	team1.goalR = $VPC / VP / GameGroup / Goal2 / Right.get_global_transform().origin
	team1.dGoal = $VPC / VP / GameGroup / Goal / RefPoint.get_global_transform().origin
	
	
	team1._initializeTeam(Global.p1human)
	
	var _foo = $VPC / VP / GameGroup / Goal2 / AreaScored.connect("body_entered", self, "_on_team1_scored")
	
	team2.playDir = - 1
	team2.goal = $VPC / VP / GameGroup / Goal / Center.get_global_transform().origin
	team2.goalL = $VPC / VP / GameGroup / Goal / Left.get_global_transform().origin
	team2.goalR = $VPC / VP / GameGroup / Goal / Right.get_global_transform().origin
	team2.dGoal = $VPC / VP / GameGroup / Goal2 / RefPoint.get_global_transform().origin
	
	team2._initializeTeam(Global.p2human)
	var _fee = $VPC / VP / GameGroup / Goal / AreaScored.connect("body_entered", self, "_on_team2_scored")
	if Global.p1human:
		setControls(1)
		
		
	
	
	team1._introTeam(1)
	team2._introTeam( - 1)
	targetgoal = team1.goal
	
	state = gameState.LINEUP
	
	fkai = team1.AIteam
	half = 0
	if Global.isPenalties:
		team1._resetTeam(false, true)
		team2._resetTeam(true, false)
		state = gameState.GAMEOVER
		recording = false
		Global.gameOn = false
		half = 1
		team1.playDir = 1
		team2.playDir = 1
		$VPC / VP / GameGroup / Goal / AreaScored.disconnect("body_entered", self, "_on_team2_scored")
		$VPC / VP / GameGroup / Goal2 / AreaScored.disconnect("body_entered", self, "_on_team1_scored")
		var _fie = $VPC / VP / GameGroup / Goal / AreaScored.connect("body_entered", self, "_on_team1_scored")
		_shootout()
	else:
		
	
	
	
		$Timers / Timer.start()
	
	set_process(true)
	
func _setupSecondHalf():
	
	half = 1
	halftime = true
	fkai = team2.AIteam
	team1.playDir = - 1
	
	team1.goal = $VPC / VP / GameGroup / Goal / Center.get_global_transform().origin
	team1.goalL = $VPC / VP / GameGroup / Goal / Left.get_global_transform().origin
	team1.goalR = $VPC / VP / GameGroup / Goal / Right.get_global_transform().origin
	team1.dGoal = $VPC / VP / GameGroup / Goal2 / RefPoint.get_global_transform().origin
	ref._kickOff()
	$VPC / VP / GameGroup / Goal / AreaScored.disconnect("body_entered", self, "_on_team2_scored")
	var _foo = $VPC / VP / GameGroup / Goal / AreaScored.connect("body_entered", self, "_on_team1_scored")
	
	team2.playDir = 1
	team2.goal = $VPC / VP / GameGroup / Goal2 / Center.get_global_transform().origin
	team2.goalL = $VPC / VP / GameGroup / Goal2 / Left.get_global_transform().origin
	team2.goalR = $VPC / VP / GameGroup / Goal2 / Right.get_global_transform().origin
	team2.dGoal = $VPC / VP / GameGroup / Goal / RefPoint.get_global_transform().origin
	
	$VPC / VP / GameGroup / Goal2 / AreaScored.disconnect("body_entered", self, "_on_team1_scored")
	var _fee = $VPC / VP / GameGroup / Goal2 / AreaScored.connect("body_entered", self, "_on_team2_scored")
	
	resetPos = Vector3(0, 0.5, 0)
	ball.linear_velocity = Vector3.ZERO
	ball.translation = resetPos
	ball._initialize()
	
	fktype = 1
	state = gameState.SETUP
	team1._resetTeam(false, false)
	team2._resetTeam(true, true)
	
func _secondHalf():
	
	
	$Timers / Timer.start()
	gametimer.paused = true
	gametimer.wait_time = Global.gameLength
	gametimer.start()
	$Timers / Timer.start()
	
	
	
func checkInput():
	if state == gameState.REPLAY:
		if (Input.is_action_pressed("p1_pass") or Input.is_action_pressed("p1_chip")) or Input.is_action_pressed("p1_shoot"):
			userscrub = false
			hud._hideReplay()
			
			$Timers / Timer.wait_time = 0.25
			$Timers / Timer.start()
		
		
	elif state == gameState.WINNER:
		if (Input.is_action_just_pressed("p1_pass") or Input.is_action_just_pressed("p2_pass")):
			state = gameState.LAP
			doLap()

func _process(delta):
	if mp_replica:
		_mp_apply_replica_state()
		_mp_update_blobs()
		return
	_mp_apply_remote_controls()
	_mp_publish_replica_state(delta)

	if recording:
		frame += 1
		fframe += delta * 60.0
		team1._calcPositions()
		team2._calcPositions()
		
		frame = frame % 360
		rPos[frame] = ball.translation
		rRot[frame] = ball.rotation
		rVel[frame] = ball.linear_velocity
		emit_signal("ballpos", rPos[frame])
		Global.ballpos = ball.translation
		Global.ballvel = ball.linear_velocity
		if ball._isTrapped():
			Global.ballvel = ball.player.velocity
		if fframe > 60.0:
			fframe = 0.0
			var t = gametimer.time_left
			hud._updateTime(t / 60, fmod(t, 60))
		
		if Global.doTrail:
			ball.trail.process(delta)
		if (frame % 30 == 0):
			ref.process(delta)
		






























		
		
	elif state == gameState.WINNER:
		checkInput()
	
	
	
	
	
	
	
	
	
	
func _mp_update_blobs():
	var tt
	for m in range(0, 14):
		if m < 7:
			tt = team1.players[m].translation
			
			
			
		else:
			tt = team2.players[m - 7].translation
		tt.y = 0.1
		blobs.multimesh.set_instance_transform(m, Transform(Basis(), tt))
	var rendered_ball = replayBall if mp_replica and state == gameState.REPLAY else ball
	tt = rendered_ball.translation
	tt.y = 0.1
	blobs.multimesh.set_instance_transform(14, Transform(Basis(), tt))
	tt = ref.translation
	tt.y = 0.1
	blobs.multimesh.set_instance_transform(15, Transform(Basis(), tt))


func _physics_process(delta):
	if mp_replica:
		return
	_mp_update_blobs()
	if state == gameState.REPLAY:
		
		checkInput()
		
		
		if (slowframe % 2 == 0):
		
			frame += 1
			frame = frame % 360
			replayBall.translation = rPos[frame]
			replayBall.rotation = rRot[frame]
			replayBall.linear_velocity = rVel[frame]
			if frame == (startframe - 32) % 360:
				
				$VPC / VP / GameGroup / Trailz.render = false
				$VPC / VP / GameGroup / Trailz._clear()
				
			if frame == startframe:
				var lastcam = replayCam[currCam]
				currCam = (currCam + 1) % 5
				replayCam[currCam].target = replayBall
				replayCam[currCam]._pickCamera()
				lastcam._endCamera()
				$VPC / VP / GameGroup / Trailz.ball = replayBall
				$VPC / VP / GameGroup / Trailz.render = true
			
		else:
			replayBall.translation = (rPos[frame] + rPos[(frame + 1) % 360]) * 0.5
			replayBall.rotation = (rRot[frame] + rRot[(frame + 1) % 360]) * 0.5
			replayBall.linear_velocity = (rVel[frame] + rVel[(frame + 1) % 360]) * 0.5
		slowframe += 1
		ball.trail.process(delta)
	
func kickOff():
	Engine.set_time_scale(1.0)
	
	mainCam._setLimits()
	$VPC / VP / GameGroup / Stadium._relax()
	scoredGoal._endNet()
	
	scoredGoal.ball = ball
	replayBall.visible = false
	ball._reset()
	$VPC / VP / GameGroup / Trailz.render = false
	recording = true
	resetPos = Vector3(0, 2, 0)
	ball._initialize()
	ball.translation = resetPos
	
	replayCam[currCam]._endCamera()
	mainCam.current = true
	mainCam.set_target_node(ball)
	team1._lineup( not team1Scored)
	team2._lineup(team1Scored)
	if team1Scored:
		fkai = team2.AIteam
		if not fkai:
			setControls(2)
	else:
		fkai = team1.AIteam
		if not fkai:
			setControls(1)
	fktype = 1
	state = gameState.SETUP
	ref._kickOff()
	
	$VPC / VP / GameGroup / Trailz.ball = ball
	
	checkSub(state)
	$Timers / Timer.wait_time = 1
	$Timers / Timer.start()
	
func freeKick():
	$VPC / VP / GameGroup / Stadium._relax()
	ball._reset()
	
	recording = true
	
	state = gameState.FKSETUP
	$Timers / Timer.wait_time = 1
	
	
	$Timers / Timer.start()
	
func penalty():
	
	ball._reset()
	
	recording = true
	state = gameState.PENSETUP
	
	$Timers / Timer.wait_time = 1
	$Timers / Timer.start()
	
func fullTime():
	recording = false
	Global.gameOn = false
	
	
func goIntro():
	_applause()
	team1._introTeam(1)
	team2._introTeam( - 1)
	
	Global.ballpos = Vector3(0, 0, 1000)
	yield(get_tree().create_timer(5), "timeout")
	$VPC / VP / GameGroup / Replays / ReplayCamera2A._pickCamera()
	team1._resetTeam(false, true)
	team2._resetTeam(true, false)
	
	Global.ballpos = Vector3.ZERO
	
	state = gameState.SETUP
	
	gametimer.wait_time = Global.gameLength
	gametimer.paused = true
	gametimer.start()
	$Timers / Timer.start()
	
	
func goSetup():
	
	$Stadium._applause()
	yield(get_tree().create_timer(5), "timeout")
	team1._resetTeam(false, true)
	team2._resetTeam(true, false)
	
	state = gameState.SETUP
func replay():
	hud._hideScorer()
	hud._hideExclaim()
	hud._showReplay()
	state = gameState.REPLAY
	team1._replay()
	team2._replay()
	ball._replay()
	hud._pressToQuit()
	
	scoredGoal._isReplay()
	var ts = 30.0 / Engine.get_frames_per_second()
	ts = max(0.5, min(ts, 0.75))
	
	Engine.set_time_scale(ts)
	
	replayBall.visible = true
	scoredGoal.ball = replayBall
	$VPC / VP / GameGroup / Trailz.ball = replayBall
	$VPC / VP / GameGroup / Trailz.render = true
	slowframe = 0
	frame = startframe
	replayCam[currCam]._pickCamera()
	mainCam.current = false
	
func _switchCamera( var cam):
	frame = startframe
	if cam == 0:
		mainCam.current = true
		
	else:
		var lastcam = replayCam[currCam]
		currCam = cam - 1
		replayCam[currCam]._pickCamera()
		lastcam._endCamera()
		replayCam[currCam].target = replayBall
func _renderVid():
	frame = startframe
	$VPC / VP.size = Vector2(638, 338)
func _renderFinish():
	$VPC / VP.size = Vector2(1920, 1080)
	
func Goal():
	
	ball._ballFree()
	hud._setScore(score.x, score.y)
	recording = false
	startframe = frame
	if startframe < Global.goalframe:
		Global.sfBeforeGf = true
	else:
		Global.sfBeforeGf = false
		
	$VPC / VP / GameGroup / Trailz.render = false
	state = gameState.CELEBRATE
	mainCam.set_target_node(goalscorer)
	mainCam._setCelebrate()
	hud._showScorer(team1Scored, goalscorer.myID)
	if team1Scored:
		t1scorer.append(goalscorer.myID)
	else:
		t2scorer.append(goalscorer.myID)
	
	$Timers / Timer.wait_time = 6
	$Timers / Timer.start()
	ref._kickOff()

















func goGamePen():
	
	$VPC / VP / GameGroup / Stadium._relax()
	ref._gameOn()
	ball.oob = false
	gametimer.paused = false
	Global.gameOn = true
	recording = true
	mainCam.set_target_node(ball)
	
	state = gameState.GAMEON
	
	var ft = ball.translation
	if fktarget:
		ft = fktarget.translation
	
	if fkteam == 1:
		team1._goGameAttack(ft)
		team2._goGameDefend()
	else:
		team1._goGameDefend()
		team2._goGameAttack(ft)
	
func goGameThrow():
	
	gametimer.paused = false
	Global.gameOn = true
	ball.oob = false
	recording = true
	mainCam.set_target_node(ball)
	state = gameState.GAMEON
	if fkteam == 1:
		team1._goGameAttack(ball.translation)
		team2._goGameDefend()
	else:
		team1._goGameDefend()
		team2._goGameAttack(ball.translation)


func checkReady():
	
	var wait = 2.0
	if halftime:
		wait = 7.0
		
	if Global.teamsReady[0] and Global.teamsReady[1]:
		halftime = false
		yield(get_tree().create_timer(wait), "timeout")
		
		ref._blowWhistle()
		ball.linear_velocity = Vector3.ZERO
		ball.translation = resetPos
		ball._initialize()
		
		mainCam.current = true
		if fkai:
			
			state = gameState.RESTARTFKAI
			$Timers / Timer.wait_time = 0.75
			$Timers / Timer.start()
		else:
			hud._pressToRestart()
			state = gameState.RESTARTFK
			$Timers / Timer.wait_time = 0.5
			$Timers / Timer.start()
	else:
		$Timers / Timer.start()
		
func restartPen():
	
	
	if Input.is_action_pressed(fkshoot):
		mainCam.current = true
		
		saveTeam = kickTaker.myTeam.opponent
		saveTeam.players[0].AI._defendPen(saveTeam.AIteam)
		
		kickTaker._loseControl()
		kickTaker.isAI = true
		
		
		kickTaker.AI.fkdir = fkdir
		saveTeam = kickTaker.myTeam.opponent
		saveTeam.players[0].AI.DZ = true
	
		
		kickTaker.AI._freeKickTaker(0, false)
		hud._hideScorer()
		yield(get_tree().create_timer(0.5), "timeout")
		
		kickTaker.canControl = true
		penTarget.visible = false
	else:
		var mov = Vector2(0, 0)
		mov.x = Input.get_joy_axis(kickTaker.myC, 0)
		mov.y = Input.get_joy_axis(kickTaker.myC, 1)
		if Global.touchPad.isActive():
			var m = Global.touchPad.get_force()
			mov.x += - m.y
			mov.y += m.x
			
		if (Input.is_action_pressed("p1_left")):
			fkmov.y -= 0.2
		elif (Input.is_action_pressed("p1_right")):
			fkmov.y += 0.2
		if (Input.is_action_pressed("p1_up")):
			fkmov.x += 0.2
		elif (Input.is_action_pressed("p1_down")):
			fkmov.x -= 0.2
		
		mov += fkmov
		penTarget.translation = Vector3(0.0, max(2.0, mov.x * 8), - mov.y * 14.0)
		
		fkmov *= 0.98
		
		
		fkdir = Vector3(0, - mov.x, mov.y)
		
		
		$Timers / Timer.wait_time = 0.15
		$Timers / Timer.start()
func restartPenAI():
	
	
	
	
	saveTeam = kickTaker.myTeam.opponent
	saveTeam.players[0].AI._defendPen(saveTeam.AIteam)
	Global.ballpos = resetPos
	
	$Sounds / WhistleSounds.play()
	kickTaker._loseControl()
	kickTaker.isAI = true
	kickTaker.AI._freeKickTaker(0, false)
	hud._hideScorer()
	yield(get_tree().create_timer(0.5), "timeout")
	
	mainCam.current = true
	penTarget.visible = false
	kickTaker.canControl = true
	
func restartFKAI():
	
	
	kickTaker._loseControl()
	kickTaker.isAI = true
	
	kickTaker.AI._kickTaker(fktype, true)
	
	hud._hideScorer()
	yield(get_tree().create_timer(0.5), "timeout")
	goGamePen()
	
	
func restartFk():
	
	
	fktarget = null
	
		
	if Input.is_action_pressed(fkshoot):
		
		
		kickTaker._loseControl()
		kickTaker.isAI = true
		
		kickTaker.AI.fkdir = fkdir
		kickTaker.AI.fkcurl = fkcurl
		kickTaker.AI.isFK = true
		
		kickTaker.AI._freeKickTaker(0, true)
		
		$VPC / VP / GameGroup / ThreeDLine._clean()
		$VPC / VP / GameGroup / ThreeDLine.drawP = false
		mainCam.current = true
		hud._hideScorer()
		
		
		
	
	elif Input.is_action_pressed(fkpass):
		
		mainCam.current = true
		kickTaker._loseControl()
		kickTaker.isAI = true
		kickTaker.AI._kickTaker(1, true)
		$VPC / VP / GameGroup / ThreeDLine._clean()
		$VPC / VP / GameGroup / ThreeDLine.drawP = false
		hud._hideScorer()
		yield(get_tree().create_timer(0.5), "timeout")
		goGamePen()
		kickTaker.canControl = true
	
	elif Input.is_action_pressed(fkchip):
		mainCam.current = true
		kickTaker._loseControl()
		kickTaker.isAI = true
	
		kickTaker.AI._kickTaker(2, true)
		$VPC / VP / GameGroup / ThreeDLine._clean()
		$VPC / VP / GameGroup / ThreeDLine.drawP = false
		
		hud._hideScorer()
		yield(get_tree().create_timer(0.5), "timeout")
		goGamePen()
		kickTaker.canControl = true
	else:
		
		fkmov.x = Input.get_joy_axis(kickTaker.myC, 0) * - fkend
		fkmov.y = Input.get_joy_axis(kickTaker.myC, 1)
		if Global.touchPad.isActive():
			var m = Global.touchPad.get_force()
			m.x *= - fkend
			fkmov = m
		if (Input.is_action_pressed("p1_left")):
			kmov.x += - 0.1 * - fkend
		elif (Input.is_action_pressed("p1_right")):
			kmov.x += 0.1 * - fkend
		if (Input.is_action_pressed("p1_up")):
			kmov.y += - 0.1
		elif (Input.is_action_pressed("p1_down")):
			kmov.y += 0.1
		fkmov.x = clamp(fkmov.x + kmov.x, - 1.0, 1.0)
		fkmov.y = clamp(fkmov.y + kmov.y, - 1.0, 1.0)
		
		if (fkend != 0):
			fkdir = (targetgoal + Vector3(0, lerp(4.0, 30.0, smoothstep( - 1.0, 1.0, fkmov.y)), fkmov.x * 35.0)) - resetPos
			fkcurl = Vector3(0, 1.0 + fkmov.y * 0.65, - fkmov.x * 0.66)
			$VPC / VP / GameGroup / ThreeDLine.calcPath(resetPos, fkdir, fkcurl * (0.5 + 0.5 * kickTaker.pCurl))
			$VPC / VP / GameGroup / ThreeDLine.process(1.0)
		$Timers / Timer.wait_time = 0.1
		$Timers / Timer.start()


func restartThrow():
	
	
	
	if Input.is_action_pressed(fkpass):
		mainCam.current = true
		kickTaker._loseControl()
		kickTaker.isAI = true
		kickTaker.AI._throwTaker(1, true)
		hud._hideScorer()
		yield(get_tree().create_timer(0.8), "timeout")
		goGamePen()
	else:
		$Timers / Timer.wait_time = 0.1
		$Timers / Timer.start()
		
func restartThrowAI():
	
	kickTaker._loseControl()
	kickTaker.isAI = true
	kickTaker.AI._throwTaker(1, true)
	hud._hideScorer()
	yield(get_tree().create_timer(0.8), "timeout")
	goGamePen()

func penSetup():
	
	ball._initialize()
	if (penend > 0):
		replayCam = $VPC / VP / GameGroup / PenaltyCams / CameraP1
		penTarget = $VPC / VP / GameGroup / Goal / Target
	else:
		replayCam = $VPC / VP / GameGroup / PenaltyCams / CameraP2
		penTarget = $VPC / VP / GameGroup / Goal2 / Target
	if fkai:
		hud._pressToRestartPenDefend()
	else:
		hud._pressToRestartPen()
	replayCam.current = true
	if Global.teamsReady[0] and Global.teamsReady[1]:
		
		$Sounds / WhistleSounds.play()
		if fkai:
			state = gameState.RESTARTPENAI
		else:
			state = gameState.RESTART
		ball.linear_velocity = Vector3.ZERO
		ball.translation = resetPos
		$Timers / Timer.wait_time = 1.0
		$Timers / Timer.start()
		penTarget.visible = true
	else:
		$Timers / Timer.start()

func fkSetup():
	
	ball.translation = resetPos
	ball._initialize()
	Global.ballpos = ball.translation
	kickTaker._shush()
	fkdir = targetgoal - resetPos
	
	if (fkend == 1) and not fkai:
		replayCam = $VPC / VP / GameGroup / PenaltyCams / CameraFK
		var campos = ($VPC / VP / GameGroup / Goal.translation - resetPos).normalized()
		replayCam.translation = resetPos - campos * 30 + Vector3(0, 12, 0)
		replayCam.look_at($VPC / VP / GameGroup / Goal.translation, Vector3.UP)
		targetgoal = $VPC / VP / GameGroup / Goal.translation
		
		replayCam.current = true
		$VPC / VP / GameGroup / ThreeDLine.drawP = true
		$VPC / VP / GameGroup / ThreeDLine.calcPath(resetPos, targetgoal - resetPos, Vector3.ZERO)
	elif (fkend == - 1) and not fkai:
		replayCam = $VPC / VP / GameGroup / PenaltyCams / CameraFK
		var campos = ($VPC / VP / GameGroup / Goal2.translation - resetPos).normalized()
		replayCam.translation = resetPos - campos * 30 + Vector3(0, 12, 0)
		replayCam.look_at($VPC / VP / GameGroup / Goal2.translation, Vector3.UP)
		targetgoal = $VPC / VP / GameGroup / Goal2.translation
		$VPC / VP / GameGroup / ThreeDLine.drawP = true
		$VPC / VP / GameGroup / ThreeDLine.calcPath(resetPos, targetgoal - resetPos, Vector3.ZERO)
		replayCam.current = true
		
	
	if Global.teamsReady[0] and Global.teamsReady[1]:
		
		$Sounds / WhistleSounds.play()
		if fkai:
			
			fktype = 1
			if fkzone == 1:
				fktype = 0
			if fkzone < 3:
				if abs(resetPos.z) > 30:
					fktype = 2
			state = gameState.RESTARTFKAI
			$Timers / Timer.wait_time = 0.5
			$Timers / Timer.start()
		else:
			hud._pressToRestartFK()
			state = gameState.RESTARTFK
			$Timers / Timer.wait_time = 0.1
			
		ball.linear_velocity = Vector3.ZERO
		ball.translation = resetPos
		
		$Timers / Timer.start()
	else:
		$Timers / Timer.start()

func throwSetup():
	ball._reset()
	
	
	recording = true
	
	
	if kickTaker.AI.state == kickTaker.AI.pstate.HOLDING:
		
		
		yield(get_tree().create_timer(0.5), "timeout")
		if fkai:
			kickTaker.myTeam._activateThrow(kickTaker)
			state = gameState.RESTARTTHROWAI
			$Timers / Timer.wait_time = 0.8
			$Timers / Timer.start()
		else:
			hud._pressToRestartThrow()
			
			kickTaker.myTeam._activateThrow(kickTaker)
			state = gameState.RESTARTTHROW
			$Timers / Timer.wait_time = 0.1
			$Timers / Timer.start()
	elif kickTaker.AI.state == kickTaker.AI.pstate.IDLE:
		
		kickTaker.AI._takeThrow(resetPos)
		$Timers / Timer.wait_time = 0.5
	
		$Timers / Timer.start()
	else:
		$Timers / Timer.wait_time = 0.5
	
		$Timers / Timer.start()
func goalkickSetup():
	
	
	
	recording = true
	
	
	if Global.teamsReady[0] and Global.teamsReady[1]:
		
		ball.oob = false
		$Sounds / WhistleSounds.play()
		ball._initialize()
		ball.translation = resetPos
		if fkai:
			fktype = 2
			state = gameState.RESTARTFKAI
			$Timers / Timer.wait_time = 1
			$Timers / Timer.start()
		else:
			hud._pressToRestart()
			state = gameState.RESTARTFK
			$Timers / Timer.wait_time = 0.1
			$Timers / Timer.start()
			
	else:
		$Timers / Timer.wait_time = 0.25
	
		$Timers / Timer.start()
		
func cornerSetup():
	
	recording = true
	
	
	if Global.teamsReady[0] and Global.teamsReady[1]:
		
		
		$Sounds / WhistleSounds.play()
		ball._initialize()
		ball.translation = resetPos
		if fkai:
			fktype = 2
			state = gameState.RESTARTFKAI
			$Timers / Timer.wait_time = 1
			$Timers / Timer.start()
		else:
			hud._pressToRestart()
			state = gameState.RESTARTFK
			$Timers / Timer.wait_time = 0.1
			$Timers / Timer.start()
			
	else:
		$Timers / Timer.wait_time = 1
	
		$Timers / Timer.start()

func _on_Timer_timeout():
	gameFunc[state].call_func()


func goalScored():
	
	scoredGoal._isNormal()
	scoredGoal._calcNet()
	Global.gameOn = false
	state = gameState.GOAL
	var gs = ball.shooter
	
	Global.goalframe = frame
	
	goalscorer = ball.shooter
	if ball.lastPlayer != null:
		if ball.lastPlayer != ball.shooter:
			ball.lastPlayer.myTeam.pplayer = ball.lastPlayer
			if ball.lastPlayer.myTeam.teamID != ball.shooter.myTeam.teamID:
				shottype = 7
				gs = ball.lastPlayer
				goalscorer = ball.shooter
			else:
				shottype = 6
				goalscorer = ball.lastPlayer
				gs = goalscorer
	mainCam.shake = 10
	hud._checkGoal(ball, gs)
	$Sounds / NetSounds.play()
	$Sounds / GoalSounds.play()
	currCam = 0
	replayCam[currCam]._setTarget(replayBall)
	$Timers / Timer.wait_time = 2
	$Timers / Timer.start()

func _on_team1_scored(_body):

	gametimer.paused = true
	
	if (state != gameState.GOAL) and (Global.gameOn):
		if (half == 1):
			scoredGoal = goal1Sim
			replayCam = goal2Cams
		else:
			scoredGoal = goal2Sim
			replayCam = goal1Cams
		
		score.x += 1
		goalscorer = team1._goal_scored()
		team2._goal_conceded()
		$VPC / VP / GameGroup / Stadium._celebrate()
		$VPC / VP / GameGroup / Stadium._awayConceded()
		
		team1Scored = true
		goalScored()
	elif Global.penShoot:
		
		goal1Sim._calcNet()
		$VPC / VP / GameGroup / Stadium._celebrate()
		$VPC / VP / GameGroup / Stadium._awayConceded()
		
		_shootoutScored()
		$Sounds / NetSounds.play()
		$Sounds / GoalSounds.play()

func _on_team2_scored(_body):
	gametimer.paused = true
	
	if (state != gameState.GOAL) and (Global.gameOn):
		if (half == 0):
			scoredGoal = goal1Sim
			replayCam = goal2Cams
		else:
			scoredGoal = goal2Sim
			replayCam = goal1Cams
		scoredGoal._calcNet()
		
		score.y += 1
		goalscorer = team2._goal_scored()
		$VPC / VP / GameGroup / Stadium._awayCelebrate()
		$VPC / VP / GameGroup / Stadium._conceded()
		
		team1._goal_conceded()
	
		team1Scored = false
		goalScored()
	
func _on_Zone1_body_entered(body):
	if body != ball:
		return
	if (half > 0):
		team1._setZone(3)
		team2._setZone(1)
	else:
		team1._setZone(1)
		team2._setZone(3)

func _on_Zone2_body_entered(body):
	if body != ball:
		return
	team1._setZone(2)
	team2._setZone(2)
	

func _on_Zone3_body_entered(body):
	
	if body != ball:
		return
	if (half > 0):
		team1._setZone(1)
		team2._setZone(3)
	else:
		team1._setZone(3)
		team2._setZone(1)
	
func setControls( var t):
	fkpass = "p1_pass"
	fkchip = "p1_chip"
	fkshoot = "p1_shoot"
	if t == 2 and Global.p1human:
		fkpass = "p2_pass"
		fkchip = "p2_chip"
		fkshoot = "p2_shoot"
		

func _foul( var _position, var victim, var offender):
	$Sounds / WhistleSounds.play()
	$Sounds / CrowdFoul.playing = true
	mainCam.shake = 10
	gametimer.paused = true
	
	hud._foul()
	fkteam = victim.teamID
	
	fkai = victim.AIteam
	targetgoal = victim.goal
	if not fkai:
		setControls(fkteam)
	state = gameState.FREEKICK
	
	
	
	
	
	checkBooking(state, offender)
	$Timers / Timer.wait_time = 1
	$Timers / Timer.start()
	
func _penalty( var offender, var fteam):
	$Sounds / WhistleSounds.play()
	$Sounds / CrowdFoul.playing = true
	hud._penalty()
	$VPC / VP / GameGroup / Stadium._celebrate()
	gametimer.paused = true
	mainCam.shake = 10
	
	state = gameState.PENALTY
	ball._initialize()
	resetPos = Vector3( - 100 * penend, 1, 0)
	fkai = offender
	
	fkteam = fteam
	
	if ( not fkai):
		setControls(fkteam)
	$Timers / Timer.wait_time = 2
	$Timers / Timer.start()
	
func _shootout():
	
	
	Global.isPenalties = true
	team1.goal = $VPC / VP / GameGroup / Goal / Center.get_global_transform().origin
	team1.goalL = $VPC / VP / GameGroup / Goal / Left.get_global_transform().origin
	team1.goalR = $VPC / VP / GameGroup / Goal / Right.get_global_transform().origin
	team2.goal = $VPC / VP / GameGroup / Goal / Center.get_global_transform().origin
	team2.goalL = $VPC / VP / GameGroup / Goal / Left.get_global_transform().origin
	team2.goalR = $VPC / VP / GameGroup / Goal / Right.get_global_transform().origin
	team1.dGoal = $VPC / VP / GameGroup / Goal / Center.get_global_transform().origin
	team2.dGoal = $VPC / VP / GameGroup / Goal / Center.get_global_transform().origin
	hud._penaltyShootout()
	team1._shootout()
	team2._shootout()
	shootoutCount = 0
	if not team1.AIteam:
		fkteam = 1
	else:
		fkteam = 2
	state = gameState.SHOOTOUT
	resetPos = Vector3( - 100, 0.5, 0.0)
	ball._initialize()
	$Timers / Timer.wait_time = 2
	$Timers / Timer.start()
	targetgoal = team1.goal
	

func _on_GameTime_timeout():
	
	
	if Global.halfDone:
		gametimer.stop()
		_halfOver()
	else:
		hud._injuryTime()
		Global.halfDone = true
	
		gametimer.wait_time = 15 + rand_range(0, 8)
		gametimer.start()
	
	
	
func _halfOver():
	
	$Sounds / WhistleSounds.play()
	
	if half == 0:
		Global.gameOn = false
		$Sounds / CrowdApplause.playing = true
		state = gameState.HALFTIME
		hud._showHalfTime()
		ball._initialize()
		team1._halfTime()
		team2._halfTime()
		Global.halfDone = false
		_setupSecondHalf()
		
		
	else:
		Global.gameOn = false
		state = gameState.GAMEOVER
		
		var pts = 0
		
		if Global.tournament and Global.tournament.leg == 2:
			score.x += Global.tournament.aggscore.y
			score.y += Global.tournament.aggscore.x

		
		if score.x != score.y or not Global.doShootout or Global.tournament.leg == 1:
			
			_gameOver()
			ball._initialize()
			if score.x > score.y:
				$VPC / VP / GameGroup / Stadium._celebrate()
				$Sounds / GoalSounds.play()
				team1._fullTime(true)
				team2._fullTime(false)
				if not team1.AIteam:
					Global.stats.stats_dict.wins += 1
					Global.stats.stats_dict.goals_for += score.x
					Global.stats.stats_dict.goals_against += score.y
					pts = 3
				else:
					if Global.tournament:
						hud._showReplayButton()
					Global.stats.stats_dict.defeats += 1
					Global.stats.stats_dict.goals_against += score.x
					Global.stats.stats_dict.goals_for += score.y
			elif score.y > score.x:
				$VPC / VP / GameGroup / Stadium._awayCelebrate()
				team1._fullTime(false)
				team2._fullTime(true)
				if not team1.AIteam:
					Global.stats.stats_dict.defeats += 1
					Global.stats.stats_dict.goals_against += score.y
					Global.stats.stats_dict.goals_for += score.x
					if Global.tournament:
						hud._showReplayButton()
				else:
					Global.stats.stats_dict.wins += 1
					Global.stats.stats_dict.goals_for += score.y
					Global.stats.stats_dict.goals_against += score.x
					$Sounds / GoalSounds.play()
					pts = 3
			else:
				
				team1._fullTime(false)
				team2._fullTime(false)
				if not team1.AIteam:
					Global.stats.stats_dict.goals_against += score.y
					Global.stats.stats_dict.goals_for += score.x
				else:
					Global.stats.stats_dict.goals_for += score.y
					Global.stats.stats_dict.goals_against += score.x
				pts = 1
				Global.stats.stats_dict.draws += 1
				
			Global.stats.stats_dict.games_completed += 1
			
			if Global.final:
				state = gameState.WINNER
				$Timers / Timer.wait_time = 4
				$Timers / Timer.start()
			
			elif Global.tType == 1:
				if Global.tournament:
					if Global.tournament._didWeWin(pts):
						state = gameState.WINNER
						$Timers / Timer.wait_time = 4
						$Timers / Timer.start()
					else:
						hud._showFullTime(score, team1.AIteam, false)
			else:
				var tg = false
				if Global.tournament:
					tg = true
				hud._showFullTime(score, team1.AIteam, tg)
		
		else:
			_shootout()
		
func _setCurrentPlayer( var team, var id):
	hud._setCPlayer(team, id)
	
func throwin( var las):
	
	
	gametimer.paused = true
	$Sounds / WhistleSounds.play()
	Global.gameOn = false
	resetPos = Global.ballpos
	resetPos.z = sign(resetPos.z) * 92
	resetPos.y = 0.1
	state = gameState.THROWIN
	hud._throwin()
	
	var side = 1
	if abs(Global.ballpos.z) > Global.ballpos.z:
		side = 0
	var lastteam = las.myTeam.teamID
	if lastteam == 1:
		team1._defendThrowin()
		team2._throwin(side, resetPos)
		fkai = team2.AIteam
		fkteam = 2
	else:
		fkteam = 1
		team2._defendThrowin()
		team1._throwin(side, resetPos)
		fkai = team1.AIteam
	
	if ( not fkai):
			setControls(fkteam)
	
	
	
	
	ball.linear_velocity = Vector3.ZERO
	
	checkSub(state)
	$Timers / Timer.wait_time = 1
	$Timers / Timer.start()
	
func checkCorner( var las):
	
	
		
	
	gametimer.paused = true
	Global.gameOn = false
	$Sounds / WhistleSounds.play()
	ball.trail.render = false
	
	var side = 1
	if abs(Global.ballpos.z) > Global.ballpos.z:
		side = 0
	
	var lastteam = las.myTeam.teamID
	var cstate = 0
	var e = 0
	
	if Global.ballpos.x < 0:
		e = 1
		if lastteam != 2:
				
			cstate = 1
			if half > 0:
				cstate = 3
		else:
				
			cstate = 2
			if half > 0:
				cstate = 0
	else:
		if lastteam != 2:
			cstate = 3
			if half > 0:
				cstate = 1
		else:
			cstate = 0
			if half > 0:
				cstate = 2
	
	if lastteam == 2 and ( not team1.AIteam):
		setControls(1)
	if lastteam == 1 and ( not team2.AIteam):
		setControls(2)
	
	match cstate:
		0:
			team1._corner(side, e)
			team2._defendCorner()
			state = gameState.CORNER
			hud._corner()
			targetgoal = team1.goal
			fkai = team1.AIteam
			fkteam = 1
		1:
			team2._corner(side, e)
			team1._defendCorner()
			hud._corner()
			state = gameState.CORNER
			targetgoal = team2.goal
			fkai = team2.AIteam
			fkteam = 2
		2:
			team1._goalkick(side, e)
			team2._defendGoalkick()
			state = gameState.GOALKICK
			targetgoal = team1.goal
			fkai = team1.AIteam
			hud._goalkick()
			_applause()
			fkteam = 1
		3:
			team2._goalkick(side, e)
			team1._defendGoalkick()
			state = gameState.GOALKICK
			targetgoal = team2.goal
			hud._goalkick()
			_applause()
			fkai = team2.AIteam
			fkteam = 2
	
	checkSub(state)
	$Timers / Timer.wait_time = 1
	$Timers / Timer.start()
	
	
func _oob( var lst):
	
	
	
	if state != gameState.GAMEON:
		return
	
	
	
	
	
	
	if abs(ball.oobpos.z) > 90.0:
		throwin(lst)
	
	else:
		checkCorner(lst)

func _oof():
	$Sounds / OofSound.playing = true
func _slide():
	if rand_range(0, 1) > 0.5:
		$Sounds / SlideSound.playing = true
	else:
		$Sounds / SlideSound2.playing = true
func _hitP():
	$VPC / VP / GameGroup / HitFX.translation = Global.ballpos
	$VPC / VP / GameGroup / HitFX / Particles.emitting = Global.doParticles
	
	team1.pplayer = null
	team2.pplayer = null
	team1._rebound()
	team2._rebound()
	
func _catch():
	$Sounds / CrowdBigOOH.playing = true
	_applause()
func _crowdooh():
	$Sounds / CrowdBigOOH.playing = true
	_applause()
func _cross():
	$Sounds / CrowdCross.playing = true
func _applause():
	$Sounds / CrowdApplause.playing = true
	$VPC / VP / GameGroup / Stadium._applause()
func setupWeather():

	$ViewportContainer / Viewport.set_update_mode(Viewport.UPDATE_ONCE)
	
	sprites.append($ViewportContainer / Viewport / TextureRect / P0)
	for i in range(1, 14):
		var s = $ViewportContainer / Viewport / TextureRect / P0.duplicate()
		sprites.append(s)
		$ViewportContainer / Viewport / TextureRect.add_child(sprites[i])

func doWeather():
	
	var x = 0
	var y = 0
	for i in range(0, 7):
		
		x = range_lerp(team1.players[i].translation.x, - 150, 150, 0, 2048)
		y = range_lerp(team1.players[i].translation.z, - 100, 100, 0, 1024)
		sprites[i].position.x = x
		sprites[i].position.y = y
		sprites[i].rotation_degrees = - team1.players[i].rotation_degrees.y
		x = range_lerp(team2.players[i].translation.x, - 150, 150, 0, 2048)
		y = range_lerp(team2.players[i].translation.z, - 100, 100, 0, 1024)
		sprites[i + 7].position.x = x
		sprites[i + 7].position.y = y
		sprites[i + 7].rotation_degrees = - team2.players[i].rotation_degrees.y
		
		
		
	if Global.ballpos.y < 0.5:
		$ViewportContainer / Viewport / TextureRect / Ball.visible = true
		
		x = range_lerp(Global.ballpos.x, - 150, 150, 0, 2048)
		y = range_lerp(Global.ballpos.z, - 100, 100, 0, 1024)
		$ViewportContainer / Viewport / TextureRect / Ball.position = Vector2(x, y)
		
	else:
		$ViewportContainer / Viewport / TextureRect / Ball.visible = false
		
	$ViewportContainer / Viewport.set_update_mode(Viewport.UPDATE_ONCE)
	$ViewportContainer / Viewport / TextureRect / TextureRect.visible = false
	
func goShootoutT1():
	
	hud._setCPlayer(1, kickTaker.myID)
	if kickTaker:
		kickTaker.AI._shootout()
	var kp = shootoutCount / 2
	if kp > 5:
		kp = 0
	kickTaker = kickTeam._shootoutKick(kp)
	saveTeam._shootoutDefend()
	if Global.teamsReady[0] and Global.teamsReady[1]:
		
		ball._initialize()
		ball.translation = resetPos
		Global.penOn = true
		$VPC / VP / GameGroup / Goal / Target.visible = true
		$Sounds / WhistleSounds.play()
		if kickTeam.AIteam:
			state = gameState.TAKEPENAI
		else:
			state = gameState.TAKEPEN
		$Timers / Timer.wait_time = 1.0
		$Timers / Timer.start()
	else:
		$Timers / Timer.start()
	

func goShootoutT2():
	if kickTaker:
		kickTaker.AI._shootout()

	
	var kp = shootoutCount / 2
	if kp > 5:
		kp = 0
	kickTaker = team2._shootoutKick(kp)
	
	hud._setCPlayer(2, kickTaker.myID)
	
	team1._shootoutDefend()
	kickTeam = team2
	saveTeam = team1
	if Global.teamsReady[0] and Global.teamsReady[1]:
		
		ball._initialize()
		ball.translation = resetPos
		Global.penOn = true
		
		
		
		$Sounds / WhistleSounds.play()
		if team2.AIteam:
			state = gameState.TAKEPENAI
		else:
			state = gameState.TAKEPEN
		$Timers / Timer.wait_time = 1.0
		$Timers / Timer.start()
	else:
	
		$Timers / Timer.start()
	

func startShootout():
	
	
	if Global.teamsReady[0] and Global.teamsReady[1]:
		goal1Sim._endNet()
		Global.penShoot = true
		Global.teamsReady[0] = false
		Global.teamsReady[1] = false
		
		$VPC / VP / GameGroup / PenaltyCams / CameraP1.current = true
		penTarget = $VPC / VP / GameGroup / Goal / Target
		$Sounds / WhistleSounds.play()
		if shootoutCount % 2 == 0:
			kickTeam = team1
			saveTeam = team2
			state = gameState.T1TAKE
		else:
			kickTeam = team2
			saveTeam = team1
			state = gameState.T1TAKE
		$Timers / Timer.wait_time = 0.25
		$Timers / Timer.start()
	else:
		$Timers / Timer.wait_time = 0.25
		$Timers / Timer.start()
func takePen():
	
	
	
	
	if Input.is_action_pressed(fkshoot):
		
		
		Global.ballpos = resetPos
		saveTeam.players[0].AI._defendPen(saveTeam.AIteam)
		
		kickTaker._loseControl()
		kickTaker.isAI = true
		kickTaker.AI.fkdir = fkdir
		kickTaker.AI._freeKickTaker(0, false)
		hud._hideScorer()
		yield(get_tree().create_timer(0.5), "timeout")
		$Timers / ShootoutTimer.start()
		kickTaker.canControl = true
		
	else:
		
		var mov = Vector2(0, 0)
		mov.x = Input.get_joy_axis(kickTaker.myC, 1)
		mov.y = Input.get_joy_axis(kickTaker.myC, 0)
		if Global.touchPad.isActive():
			var m = Global.touchPad.get_force()
			mov.y += m.x
			mov.x -= m.y
			
		if (Input.is_action_pressed("p1_left")):
			fkmov.y -= 0.2
		elif (Input.is_action_pressed("p1_right")):
			fkmov.y += 0.2
		if (Input.is_action_pressed("p1_up")):
			fkmov.x += - 0.2
		elif (Input.is_action_pressed("p1_down")):
			fkmov.x += 0.2
		mov += fkmov
		fkmov *= 0.95
		if ( not kickTeam.AIteam):
			penTarget.translation = Vector3(0.0, max(2.0, - mov.x * 8), - mov.y * 14.0)
		fkdir = Vector3(0, - mov.x, mov.y)
		
		$Timers / Timer.wait_time = 0.1
		$Timers / Timer.start()
func takePenAI():
	
	
	
	
	saveTeam.players[0].AI._defendPen(saveTeam.AIteam)
	Global.ballpos = resetPos
	
	$Sounds / WhistleSounds.play()
	kickTaker._loseControl()
	kickTaker.isAI = true
	
	kickTaker.AI.fkdir = fkdir
	kickTaker.AI._freeKickTaker(0, false)

	hud._hideScorer()
	yield(get_tree().create_timer(0.6), "timeout")
	$Timers / ShootoutTimer.start()
	kickTaker.canControl = true
	
func resetKick():
	
	
	if kickTeam.AIteam:
		hud._pressToRestartPen()
	else:
		hud._pressToRestartPenDefend()
	penTarget.visible = true
	kickTeam.players[0].AI._defendPen(kickTeam.AIteam)
	saveTeam.players[0].AI._shootout()
	kickTaker.AI._shootout()
	shootoutCount += 1
	if shootoutCount > 9 and shootoutCount % 2 == 0:
		hud._suddenDeath()
	
	
	state = gameState.SHOOTOUT
	$Timers / Timer.start()
func _shootoutScored():
	
	if not Global.penOn:
		return
	Global.penOn = false
	hud._updateShootout(shootoutCount, true)
	
	var winner = hud._checkScores()
	if winner > 0:
		_shootoutOver(winner)
		return
	
	kickTaker.AI._celebratePen()
	
	
	
	yield(get_tree().create_timer(2.0), "timeout")
	resetKick()
func _shootoutMissed():
	
	if not Global.penOn:
		return
	
	Global.penOn = false
	kickTaker.AI._missed()
	saveTeam.players[0].AI._resetKeeper()
	hud._updateShootout(shootoutCount, false)
	var winner = hud._checkScores()
	if winner > 0:
		_shootoutOver(winner)
		return
	
	
	
	
	
	yield(get_tree().create_timer(2.0), "timeout")
	resetKick()
func _shootoutOver( var winner):
	mainCam.current = true
	$Sounds / GoalSounds.play()
	state = gameState.GAMEOVER
	Global.penShoot = false
	Global.penOn = false
	if winner == 1:
		team1._fullTime(true)
		team2._fullTime(false)
		mainCam._setTarget(team1.players[0])
	else:
		team1._fullTime(false)
		team2._fullTime(true)
		mainCam._setTarget(team2.players[0])
	
	score += hud._getFinalScore()
	
	
	yield(get_tree().create_timer(6), "timeout")
	
	_halfOver()

func _on_ShootoutTimer_timeout():
	
	if (Global.penOn):
		_shootoutMissed()


func checkSub( var cstate):
	
	
	if needSub:
		nextState = cstate
		state = gameState.DOSUB
		mainCam._setTarget(subteam.players[cplayer])
		
		hud._substitution()
		
		subteam.players[cplayer].AI._subOff(splayer)
	
		

		

func doSub():
	
	
	
	if subteam.players[cplayer].AI._offField(splayer):
		subteam.players[splayer].AI._subOn(cplayer)
		
		var tmp = subteam.players[cplayer]
		subteam.players[cplayer] = subteam.players[splayer]
		subteam.players[splayer] = tmp
		state = gameState.SUBON
		subteam.players[cplayer].myID = cplayer
		mainCam._setTarget(subteam.players[splayer])
		hud._swapPNames()
	$Timers / Timer.wait_time = 0.5
	$Timers / Timer.start()
		
func subOn():
	
		
	if subteam.players[cplayer].AI._onField():
		
		state = nextState
		needSub = false
		mainCam._setTarget(ball)
		
	$Timers / Timer.wait_time = 0.5
	$Timers / Timer.start()
	

func _doSubs():
	
	
	if team1.AIteam:
		subteam = team2
	else:
		subteam = team1
	mainCam._setTarget(subteam.players[1])
	mainCam.fov = 25
	mainCam.limitZ = 100
func _pickSub( var i):
	
	
	mainCam._setTarget(subteam.players[i])
	return true
func _setSub( var cp, var sp, var _te):
	needSub = true
	cplayer = cp
	splayer = sp
	mainCam._setLimits()
	mainCam._setTarget(ball)
	if not Global.gameOn and state != gameState.REPLAY:
		checkSub(state)
		$Timers / Timer.wait_time = 1
		$Timers / Timer.start()
	
func _cancelSub():
	mainCam._setLimits()
	mainCam._setTarget(ball)
	



func checkBooking( var cstate, var offender):
		
	
	if ref._bookPlayer(offender):
		nextState = cstate
		offender.AI._bookMe()
		state = gameState.BOOKING
		mainCam._setTarget(offender)
		mainCam.fov = 35
	
	
func _doneBooking():
	
	state = nextState
	mainCam._setLimits()
	mainCam._setTarget(ball)
	$Timers / Timer.wait_time = 0.5
	$Timers / Timer.start()
	
func bookingPlayer():
	
	
	$Timers / Timer.wait_time = 0.5
	$Timers / Timer.start()
func doWinner():
	hud._hideFullTime()
	$VPC / VP / Particles.emitting = true
	$VPC / VP / Particles.visible = true
	
	
	var wteam = team1
	if score.y > score.x:
		wteam = team2
	ball._initialize()
	recording = false
	ball.translation = Vector3(65, 0, 80)
	Global.ballpos = ball.translation
	
	var tourney = Global.tournament.cup
	
	
	match tourney:
		0:
			Global.stats.stats_dict.amcups += 1
		1:
			Global.stats.stats_dict.procups += 1
		2:
			Global.stats.stats_dict.chumpcups += 1
		3:
			Global.stats.stats_dict.intcups += 1
		4:
			Global.stats.stats_dict.globalcups += 1
	$VPC / VP / ChampBanner.get_active_material(0).uv1_offset = Vector3(0.0, tourney * 0.2, 0.0)
	$VPC / VP / Cups._showCup(tourney)
	if Global.tType == 4:
		$VPC / VP / ChampBanner.get_active_material(0).uv1_offset = Vector3(0.0, 0.4, 0.0)
		$VPC / VP / Cups._showCup(3)
	$VPC / VP / ChampBanner.visible = true
	$VPC / VP / GameGroup / AltCameras / WinnerCamera.current = true
	
	$VPC / VP / Cups.visible = true
	wteam._winners()
	
func doLap():
	
	var wteam = team1
	if score.y > score.x:
		wteam = team2
	hud._pressToExit()
	wteam._lapOfHonour()
	replayCam = goal1Cams
	_switchCamera(1 + ((currCam + 1) % 4))
	state = gameState.LAP
	$Timers / Timer.wait_time = 5.0
	$Timers / Timer.start()
	
func checkLap():
	currCam = 1 + ((currCam + 1) % 4)
	
	_switchCamera(currCam)
	$Timers / Timer.wait_time = 5.0
	$Timers / Timer.start()
func _setCam( var index):
	match index:
		0:
			mainCam = $VPC / VP / GameGroup / Camera
			Global.camrot = false
			Global.config.get_value("gfx", "camdof")
		1:
			mainCam = $VPC / VP / GameGroup / AltCameras / CameraTopUD
			Global.camrot = true
			Global.config.get_value("gfx", "camUDdof")
		2:
			mainCam = $VPC / VP / GameGroup / AltCameras / CameraTopLR
			Global.camrot = false
			Global.config.get_value("gfx", "camLRdof")
			
	mainCam._setupCamera()
	mainCam.current = true
	team1._updateCamChange()
	team2._updateCamChange()
	Global.camtype = index
func _blowWhistle():
	$Sounds / WhistleSounds.play()
func _gameOver():
	$Sounds / Winner.play()
func _shushCrowd():
	$Sounds / CrowdSounds.playing = false
	$Sounds / CrowdSounds.volume_db = - 92
