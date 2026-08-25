extends Spatial





enum gameState{INTRO, SETUP, GAMEON, HALFTIME, GAMEOVER, GOAL, CELEBRATE, REPLAY, HIGHLIGHTS, PAUSE, FREEKICK, PENALTY, PENSETUP, FKSETUP, RESTART, RESTARTFK, RESTARTFKAI, GOALKICK, THROWIN, CORNER, RESTARTTHROW, RESTARTTHROWAI, SHOOTOUT, GOSHOOTOUT, T1TAKE, T2TAKE, TAKEPEN, TAKEPENAI, PICKSUB, DOSUB, SUBON, BOOKING, WINNER, LAP}
var state
enum task{MOVE, COLLECT, BURST, PASS, CHIP, SHOOT, AIM, SCORE, DONE, WAIT}
var ctask
var ntask
var hud = null
var teams = []
var teamfiles = []
var recording = false
var frame = 0
var ball = null
var team1 = null
var team2 = null
var teamID = 0
var playDir = 1
var posession = false
var AIteam = false
var instructions = []
var currI = - 1

func _ready():
	Global.game = self
	Global.isTutorial = true
	hud = $Hud
	Global.gameOn = false
	ball = $Ball




	
	
	
	setupTut()
	
	$Players / PlayerRoot / Player.ball = $Ball
	$Players / PlayerRoot.game = Global.game
	$Players / PlayerRoot2 / Player.ball = $Ball
	$Players / PlayerRoot2.game = Global.game
	
	Global.gameOn = true
	
	
	Global.halfDone = false
	$Players.ball = $Ball
	$Players / PlayerRoot / Player.AI._initialize($Players, $Goal2.translation, $Goal2 / Left.translation, $Goal / Right.translation, $Goal.translation)
	$Players / PlayerRoot / Player.set_process(true)
	$Players / PlayerRoot / Player.assist = false
	$Players / PlayerRoot2 / Player.AI._initialize($Players, $Goal2.translation, $Goal2 / Left.translation, $Goal / Right.translation, $Goal.translation)
	$Players / PlayerRoot2 / Player.set_process(true)
	$Players / PlayerRoot2 / Player.assist = false
	$Players / PlayerRoot / Player.myGoalR = $Goal2 / Right.get_global_transform().origin
	$Players / PlayerRoot2 / Player.myGoalR = $Goal2 / Right.get_global_transform().origin
	$Players / PlayerRoot / Player.myGoalL = $Goal2 / Left.get_global_transform().origin
	$Players / PlayerRoot2 / Player.myGoalL = $Goal2 / Left.get_global_transform().origin
	$Players / PlayerRoot / Player.myGoal = $Goal2 / Center.get_global_transform().origin
	$Players / PlayerRoot2 / Player.myGoal = $Goal2 / Center.get_global_transform().origin
	
	
	
	$Camera.set_target_node($Ball)
	ball.trail = $Trailz
	ball.Game = Global.game
	for child in $Info.get_children():
		instructions.append(child)
	$Goal2 / Nets / Nettest.ball = $Ball
	$Goal2 / Nets / Nettest._initialize()
	$Goal2 / Nets / Nettest._calcNet()
	$Players.Game = self
	hud._tutorial()
	ctask = task.MOVE
	ntask = task.MOVE
	_on_Timer_timeout()
func setupTut():
	
	var udlr = Global.udlr
	var kburst = OS.get_scancode_string(Global.config.get_value("game", "R1"))
	var kpass = OS.get_scancode_string(Global.config.get_value("game", "passk"))
	var kchip = OS.get_scancode_string(Global.config.get_value("game", "chipk"))
	var kshoot = OS.get_scancode_string(Global.config.get_value("game", "shootk"))
	var kthru = OS.get_scancode_string(Global.config.get_value("game", "thruk"))
	if OS.has_touchscreen_ui_hint():
		udlr = "joystick"
		kburst = "(sprint)"
		kpass = "(pass)"
		kchip = "(chip)"
		kshoot = "(shoot)"
		kthru = "(thru)"
	$Info / Label.text = "<" + udlr + "> " + Global.ll.tut[0]
	$Info / Label2.text = Global.ll.tut[1]
	$Info / Label3.text = "<" + kburst + "> " + Global.ll.tut[2]
	$Info / Label4.text = "<" + kpass + "> " + Global.ll.tut[3]
	$Info / Label5.text = "<" + kchip + "> " + Global.ll.tut[4]
	$Info / Label6.text = "<" + kshoot + "> " + Global.ll.tut[5]
	$Info / Label7.text = Global.ll.tut[6]
	$Info / Label8.text = Global.ll.tut[7]
	$exit.text = $exit.text + Global.ll.toexit
	PokiSDK.gameplayStart()
	
	
func checkInput():
	if ctask == task.MOVE:
		if Input.is_action_just_pressed("p1_left") or Input.is_action_just_pressed("p1_right"):
				$AudioPlayer.play()
				$Timer.start()
				ctask = task.WAIT
				ntask = task.COLLECT
		if Global.touchPad.isActive():
			var m = Global.touchPad.get_force()
			if abs(m.x) > 0.1 or abs(m.y) > 0.1:
				$AudioPlayer.play()
				$Timer.start()
				ctask = task.WAIT
				ntask = task.COLLECT
		
	elif ctask == task.COLLECT:
		if ball._isTrapped():
			
				$AudioPlayer.play()
				$Timer.start()
				ctask = task.WAIT
				ntask = task.BURST
	elif ctask == task.BURST:
		if Input.is_action_just_pressed("p1_burst"):
			$AudioPlayer.play()
			$Timer.start()
			ctask = task.WAIT
			ntask = task.PASS
			
	elif ctask == task.PASS:
		if Input.is_action_pressed("p1_pass") and ball._isTrapped():
			$AudioPlayer.play()
			$Timer.start()
			ctask = task.WAIT
			ntask = task.CHIP
	elif ctask == task.CHIP:
		if Input.is_action_just_pressed("p1_chip") and ball._isTrapped():
			$AudioPlayer.play()
			$Timer.start()
			ctask = task.WAIT
			ntask = task.SHOOT
	elif ctask == task.SHOOT:
		if Input.is_action_just_pressed("p1_shoot") and ball._isTrapped():
			$AudioPlayer.play()
			$Timer.start()
			ctask = task.WAIT
			ntask = task.AIM
	elif ctask == task.AIM:
		if Input.is_action_just_pressed("p1_shoot"):
			
			$Timer.start()
			ctask = task.WAIT
			ntask = task.SCORE
			
	
func _process(_delta):
	checkInput()
func _physics_process(_delta):
	Global.ballpos = $Ball.translation
	Global.ballvel = $Ball.linear_velocity
	
func _oob( var _foo):
	
	if $Ball.oob:
		yield(get_tree().create_timer(1.0), "timeout")
		$Players / PlayerRoot / Player.AI._losePosession()
		$Players / PlayerRoot2 / Player.AI._losePosession()
		$Ball.translation = Vector3(80, 20, 0)
		$Ball.oob = false
		$Ball._ballFree()
		if ctask == task.SCORE:
			$AudioPlayer.play()
			ctask = task.DONE
			yield(get_tree().create_timer(4.0), "timeout")
			PokiSDK.gameplayStop()
			hud._on_ButtonExit_pressed()
		
		
		
		

func _hitP():
	pass
func _slide():
	pass
func _oof():
	pass
func _catch():
	pass
func _cross():
	pass

func _on_Timer_timeout():
	ctask = ntask
	instructions[currI].visible = false
	currI = (currI + 1) % 8
	instructions[currI].visible = true
	
