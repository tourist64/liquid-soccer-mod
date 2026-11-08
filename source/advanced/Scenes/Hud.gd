extends Control





var team1 = []
var team2 = []
var team1_col
var team2_col
var map = []
var mapball
var pnames = []
var ballspeed
var game = null
var cplayer = 1
var splayer = 7
var cplayerS = ""
var doSubs = false
var pickReplacement = false
var last = 0
var canChange = 0
var pstate = ["idle", "pcontrol", "playing", "defend", "support", "press", "posession", "celebrate", "replay", "conceded", "slide", "foul", "Tackled", "Penalty", "penagainst", "kicktaker", "head", "shoot", "pcollect", "pickup", "holding", "throw", "divingh", "mark", "intercept", "bike", "action", "subbed", "off", "lap"]
var kstate = ["IDLE", "PCONTROL", "DEFEND", "SUPPORT", "PRESS", "POSESSION", "CELEBRATE", "REPLAY", "INCOMING", "DIVE", "CONCEDE", "PENALTY", "ACTIVEDEF", "CAUGHT", "CLEARING", "INCCROSS", "KICKER", "SHOOTACTIVE", "SHOOTOUT", "LAP"]

var teamState = ["DEFENDING", "MOMENTUM", "DEFEND", "ATTACK", "GOAL", "CONCEDED", "REPLAY", "HALFTIME", "ENDGAME", "FREEKICK", "PENALTY", "PENAGAINST", "PENANANA", "SHOOTOUT", "SHOOTOUT", "WINNER"]
var bpass = "(pass)"
var bshoot = "(shoot)"
var bchip = "(chip)"
var canPressButton = true

var tween = null

var tryRewarded = false

func _ready():
	
	canPressButton = true
	var lab = $Debug / Label
	for i in range(0, 12):

		team1.append(lab.duplicate())
		$Debug.add_child(team1[i])
		team1[i].margin_top += 40 * i
		team1[i].text = "idle"
		team2.append(lab.duplicate())
		$Debug.add_child(team2[i])
		team2[i].margin_left = lab.margin_left + 1500
		team2[i].margin_top += 40 * i
		team2[i].text = "idle"
	mapball = $Map / P0
	ballspeed = $Debug / BallVel
	$Transition._wipeOnTex()
	Global.debugLine = $Debug / DebugLabel
	game = get_parent()
	tween = $UITween
	Global.touchPad = $ViewportContainer / GamePad / leftPad / JoyStickLeft
	$DialogSettings / CamButton.add_item("default")
	$DialogSettings / CamButton.add_item("topdown - Up/Down")
	$DialogSettings / CamButton.add_item("topdown - Left/Right")
	if not OS.has_touchscreen_ui_hint():
		$Control.visible = false
		Global.isTouch = false
		bpass = "<" + OS.get_scancode_string(Global.config.get_value("game", "passk")) + ">"
		bshoot = "<" + OS.get_scancode_string(Global.config.get_value("game", "shootk")) + ">"
		bchip = "<" + OS.get_scancode_string(Global.config.get_value("game", "chipk")) + ">"
		
	else:
		Global.isTouch = true
	setupPauseControls()
	
	if Global.tournament and Global.tournament.leg == 2:
		$Aggregate.visible = true
		
	Global.connect("adDone", self, "_adDone")
	
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
			
			if game.state != game.gameState.WINNER and game.state != game.gameState.LAP:
				
				if not $DialogPause.visible:
					showDialog($DialogPause)
					PokiSDK.gameplayStop()
				
					if Global.isTutorial:
						$DialogPause / ButtonSubs.visible = false
						$DialogPause / SettingsButton.visible = false
					
					$DialogPause / ButtonResume.grab_focus()
					get_tree().paused = true
				else:
					_on_ButtonResume_pressed()
			else:
				
				_showFullTime(game.score, false, true)
	if doSubs:
		if Input.is_action_just_pressed("ui_cancel"):
			doSubs = false
			pickReplacement = false
			$goalscorer.visible = false
			game._cancelSub()
			return
		if canChange <= 0:
			if not pickReplacement:
				cplayer = pickPlayer(1, 6, cplayer)
			else:
				splayer = pickPlayer(7, 11, splayer)
			
		canChange -= 1
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("p1_pass"):
			
			if not pickReplacement:
				pickReplacement = true
				canChange = 30
				cplayerS = pnames[cplayer] + " <<<< "
				game._pickSub(splayer)
				$goalscorer.text = cplayerS + pnames[splayer]
				$goalscorer.visible = true
	
			elif canChange < 0:
				game._setSub(cplayer, splayer, 1)
				canChange = 30
				
				
				get_tree().paused = false
				$goalscorer.visible = false
				doSubs = false
				pickReplacement = false
	

func _swapPNames():
	var tmp = pnames[cplayer]
	pnames[cplayer] = pnames[splayer]
	pnames[splayer] = tmp



func pickPlayer( var mi, var ma, var cur):
	
	var curr = cur
	var dx = Input.get_joy_axis(0, 0)
	if Global.touchPad.isActive():
		dx += Global.touchPad.get_force().x
	if Input.is_action_just_pressed("p1_right") or Input.is_action_just_pressed("ui_right"):
		dx += 1
	elif Input.is_action_just_pressed("p1_left") or Input.is_action_just_pressed("ui_left"):
		dx -= 1
	
	if dx > 0.2:
		curr += 1
		if curr > ma:
			curr = mi
	elif dx < - 0.2:
		curr = curr - 1
		if curr < mi:
			curr = ma
	if curr != last:
		var canSub = game._pickSub(curr)
		if canSub:
			$goalscorer.text = cplayerS + pnames[curr]
			$goalscorer.visible = true
		canChange = 30
		last = curr
	return curr
	
	
func showDialog( var d):
	tween.interpolate_property(d, "rect_scale", Vector2(0.9, 0.9), Vector2(1, 1), 0.66, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	d.visible = true
	$Control.visible = false
	$ViewportContainer.visible = false
func hideDialog( var d):
	tween.interpolate_property(d, "rect_scale", Vector2(1.0, 1.0), Vector2(0.6, 0.6), 0.66, Tween.TRANS_BACK, Tween.EASE_OUT_IN)
	tween.start()
	yield(tween, "tween_completed")
	d.visible = false
	if OS.has_touchscreen_ui_hint():
		$Control.visible = true
	$ViewportContainer.visible = true
	
func _initializeHud():
		
	pnames.clear()
	var col = team1_col
	$Team1.text = Global.t1.shortname
	$Team2.text = Global.t2.shortname
	pnames.append(Global.t1.player0.name)
	pnames.append(Global.t1.player1.name)
	pnames.append(Global.t1.player2.name)
	pnames.append(Global.t1.player3.name)
	pnames.append(Global.t1.player4.name)
	pnames.append(Global.t1.player5.name)
	pnames.append(Global.t1.player6.name)
	pnames.append(Global.t1.player7.name)
	pnames.append(Global.t1.player8.name)
	pnames.append(Global.t1.player9.name)
	pnames.append(Global.t1.player10.name)
	pnames.append(Global.t1.player11.name)
	
	pnames.append(Global.t2.player0.name)
	pnames.append(Global.t2.player1.name)
	pnames.append(Global.t2.player2.name)
	pnames.append(Global.t2.player3.name)
	pnames.append(Global.t2.player4.name)
	pnames.append(Global.t2.player5.name)
	pnames.append(Global.t2.player6.name)
	pnames.append(Global.t2.player7.name)
	pnames.append(Global.t2.player8.name)
	pnames.append(Global.t2.player9.name)
	pnames.append(Global.t2.player10.name)
	pnames.append(Global.t2.player11.name)
	
	for i in range(0, 2 * Global.squad):
		
		map.append($Map / P0.duplicate())
		$Map.add_child(map[i])
		map[i].modulate = col
		if (i > Global.squad - 2):
			col = team2_col
	if Global.tournament and Global.tournament.leg == 2:
		setAggregateScore()
func _clearTrans():
	$Transition.visible = false
func _goTrans():
	
	$Transition.visible = true
	$Transition._wipeOff()
	yield($Transition.tween, "tween_completed")
	_clearTrans()
	
func _setState( var id, var team, var state, var teamstate):
	
	if team == 1:
		if id == 0:
			team1[id].text = (str(id) + ":" + kstate[state])
		
		else:
			team1[id].text = (str(id) + ":" + pstate[state])
		$Debug / team1state.text = teamState[teamstate]
	else:
		if id == 0:
			team2[id].text = kstate[state]
		else:
			team2[id].text = pstate[state]
			
		$Debug / team2state.text = teamState[teamstate]
		

func _updateMap(tid, id, pos):
	if id > Global.squad - 1:
		return
	var upid = tid * Global.squad + id
	map[upid].position.x = range_lerp(pos.x, - 145 * Global.ps, 145 * Global.ps, 0, 512)
	map[upid].position.y = range_lerp(pos.z, - 100 * Global.ps, 100 * Global.ps, 0, 363)
	
func _updateMapBall(pos):
	mapball.position.x = range_lerp(pos.x, - 145 * Global.ps, 145 * Global.ps, 0, 512)
	mapball.position.y = range_lerp(pos.z, - 100 * Global.ps, 100 * Global.ps, 0, 363)

func _updateTime(mins, secs):
	$GameTime.text = "%02d:%02d" % [mins, secs]
func _checkGoal( var ball, var scorer):
	var bp = ball.translation
	var sp = scorer.translation
	var gp = scorer.myGoal
	var txt = Global.ll.commentary[0]
	var rt = rand_range(0, 1)
	
	if abs(bp.z) > 6.5 and abs(bp.y) > 12:
		txt = Global.ll.commentary[1]
	elif game.shottype == 1:
		if rt < 0.25:
			txt = Global.ll.commentary[2]
		elif rt < 0.5:
			txt = Global.ll.commentary[3]
		elif rt < 0.75:
			txt = Global.ll.commentary[4]
		else:
			txt = Global.ll.commentary[5]
	elif game.shottype == 2:
		txt = Global.ll.spcommentary[int(rand_range(0, 6))]
	elif game.shottype == 3:
		txt = Global.ll.headcommentary[int(rand_range(0, 4))]
	elif game.shottype == 4:
		txt = Global.ll.headcommentary[5]
	elif game.shottype == 7:
		txt = Global.ll.deflcommentary[int(rand_range(0, 6))]
	elif game.shottype == 6:
		txt = Global.ll.deflcommentary[int(rand_range(0, 6))]
	
	elif ((gp - sp).length() > 100):
		txt = Global.ll.longcommentary[1]
	elif ((gp - sp).length() > 80):
		txt = Global.ll.longcommentary[0]
	elif ((ball.linear_velocity).length() > 110):
		if rt < 0.25:
			txt = Global.ll.longcommentary[2]
		elif rt < 0.5:
			txt = Global.ll.longcommentary[3]
		elif rt < 0.75:
			txt = Global.ll.longcommentary[4]
		else:
			txt = Global.ll.longcommentary[5]
	$AnimationPlayer / Exclaim.text = txt
	

	$AnimationPlayer / Exclaim.visible = true
	$AnimationPlayer.play("WipeOnOff")
func _tutorial():
	$AnimationPlayer / Exclaim.text = Global.ll.menus[6]
	$AnimationPlayer / Exclaim.visible = true
	$AnimationPlayer.play("WipeOnOff")
func _substitution():
	$AnimationPlayer / Exclaim.text = "substitution"
	$AnimationPlayer / Exclaim.visible = true
	$AnimationPlayer.play("WipeOnOff")
	
func _injuryTime():
	
	$AnimationPlayer / Exclaim.text = Global.ll.ingame[11]
	$AnimationPlayer / Exclaim.visible = true
	$AnimationPlayer.play("WipeOnOff")

func _showTeams():
	$AnimationPlayer / Exclaim.text = (Global.t1.teamname) + " vs " + (Global.t2.teamname)
	$AnimationPlayer / Exclaim.visible = true
	$AnimationPlayer.play("WipeOnOff")
	
func _penaltyShootout():
	$AnimationPlayer / Exclaim.text = Global.ll.ingame[9]
	$AnimationPlayer / Exclaim.visible = true
	$AnimationPlayer.play("WipeOnOff")
	$PenaltiesUI._initShootout()
	$PenaltiesUI.visible = true
	
func _updateShootout( var r, var scored):
	
	var t = 0
	var ro = (r) / 2
	if r % 2 == 1:
		t = 1
		ro = r / 2
	
	$PenaltiesUI._setIcon(t, ro, scored)
func _checkScores():
	return $PenaltiesUI._checkScores()
func _getFinalScore():
	return $PenaltiesUI._getFinalScore()

func _suddenDeath():
	$PenaltiesUI._suddenDeath()
	$AnimationPlayer / Exclaim.text = Global.ll.ingame[10]
	$AnimationPlayer / Exclaim.visible = true
	$AnimationPlayer.play("WipeOnOff")

func _yellowCard():
	$AnimationPlayer / Exclaim.visible = true
	$AnimationPlayer / Exclaim.text = Global.ll.ingame[4]
	$AnimationPlayer.play("WipeOnOff")
func _redCard():
	$AnimationPlayer / Exclaim.visible = true
	$AnimationPlayer / Exclaim.text = Global.ll.ingame[5]
	$AnimationPlayer.play("WipeOnOff")

func _hideExclaim():
	$AnimationPlayer / Exclaim.visible = false



func _showHalfTime():
	$Dialog / T1.text = Global.t1.teamname
	$Dialog / T2.text = Global.t2.teamname
	$Dialog / TS1.text = str(game.score[0])
	$Dialog / TS2.text = str(game.score[1])
	PokiSDK.gameplayStop()
	for s in game.t1scorer:
		$Dialog / t1scorer.text += pnames[s] + "\n"
		
	for s2 in game.t2scorer:
		$Dialog / t2scorer.text += pnames[12 + s2] + "\n"
		
	
	showDialog($Dialog)
	$Dialog / TextureButton.grab_focus()

func _showFullTime( var sc, var t1AI, var wonCup):
	$PenaltiesUI.visible = false
	
	$DialogLarge / T1.text = Global.t1.teamname
	$DialogLarge / T2.text = Global.t2.teamname
	$DialogLarge / Score.text = (str(sc.x) + ":" + str(sc.y))
	PokiSDK.gameplayStop()
	showDialog($DialogLarge)
	$DialogLarge / exit.grab_focus()
	
	
	if ( not t1AI and sc[0] > sc[1]) or (t1AI and sc[1] > sc[0]):
		canPressButton = false
		var ut = Global._unlockTeam(wonCup)
		if ut != "false":
			tryRewarded = true
			
			$UnlockDialog / Label.text = Global.ll.unlockteam
			$UnlockDialog / Label2.text = ut
			$UnlockDialog / Label3.text = Global.ll.unlockask
			$UnlockDialog.visible = true
			$UnlockDialog / ButtonOK.grab_focus()
		else:
			canPressButton = true
		
		
		
func _hideFullTime():
	hideDialog($DialogLarge)
	
func _showScorer( var t1s, var id):
	var i = id
	if not t1s:
		i += 12
	$goalscorer.text = Global.ll.ingame[6] + pnames[i]
	$goalscorer.visible = true
func _hideScorer():
	$goalscorer.visible = false
	
func _showFouler( var t1s, var id):
	var i = id
	if not t1s:
		i += 12
	$goalscorer.text = Global.ll.ingame[7] + pnames[i]
	$goalscorer.visible = true
func _penalty():
	$goalscorer.text = Global.ll.ingame[2]
	$goalscorer.visible = true
func _foul():
	$goalscorer.text = Global.ll.ingame[8]
	$goalscorer.visible = true

func _throwin():
	$goalscorer.text = Global.ll.ingame[3]
	$goalscorer.visible = true
func _goalkick():
	$goalscorer.text = Global.ll.ingame[0]
	$goalscorer.visible = true
func _corner():
	$goalscorer.text = Global.ll.ingame[1]
	$goalscorer.visible = true

	
	
func _on_Button_pressed():
	
	
	var cbreak = false
	if Global.gameLength > 60:
		cbreak = true
		Global.adsource = Global.adfrom.HALFTIME
		cbreak = PokiSDK.commercialBreak()
		
	if not cbreak:
		print("can't do commercial")
		hideDialog($Dialog)
		$Dialog / TextureButton.grab_focus()
		get_parent()._secondHalf()
		PokiSDK.gameplayStart()

func _adDone():
	if Global.adsource == Global.adfrom.HALFTIME:
		hideDialog($Dialog)
		$Dialog / TextureButton.grab_focus()
		get_parent()._secondHalf()
		PokiSDK.gameplayStart()
func _setCPlayer( var t, var id):
	if t == 1:
		$T1Player.text = pnames[id]
	else:
		$T2Player.text = pnames[id + 12]
		

func _on_exit_pressed():
	
	if not canPressButton:
		return
		
	Global.stats._saveStats()
	
	_goTrans()
	yield($Transition / Tween, "tween_completed")
	if Global.tournament == null:
		var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")
	else:
		
		Global.tournament._gamePlayed(game.score)
		if Global.tType == 0:
			var _foo = get_tree().change_scene("res://Scenes/CupViewer.tscn")
		elif Global.tType == 1:
			var _foo = get_tree().change_scene("res://Scenes/LeagueViewer.tscn")
		else:
			if Global.tournament.knockoutStage:
				var _foo = get_tree().change_scene("res://Scenes/CupViewer.tscn")
			else:
				var _foo = get_tree().change_scene("res://Scenes/WCViewer.tscn")
	
func _on_replay_pressed():
	
	if not canPressButton:
		return
	canPressButton = false
	
	_goTrans()
	yield($Transition / Tween, "tween_completed")
	
	game._shushCrowd()
	var cbreak = PokiSDK.rewardedBreak()
	if not cbreak:
		canPressButton = true
		print("can't do commercial")
		
		
func _on_teams_pressed():
	
	_goTrans()
	yield($Transition / Tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/TeamSelect.tscn")


func _on_ButtonExit_pressed():
	
	if canPressButton:
		hideDialog($DialogPause)
		Engine.set_time_scale(1.0)
	
		get_tree().paused = false
		_goTrans()
		yield($Transition / Tween, "tween_completed")
		var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")


func _on_ButtonResume_pressed():
	
	
	hideDialog($DialogPause)
	PokiSDK.gameplayStart()
	get_tree().paused = false



func _on_ButtonWish_pressed():
	
	var _succss = OS.shell_open("https://store.steampowered.com/app/1705130/Super_Liquid_Soccer/")


func _on_ButtonItch_pressed():
	
	var _succss = OS.shell_open("https://punyrobot.itch.io/superliquidsoccer")



func _on_ButtonSubs_pressed():
	hideDialog($DialogPause)
	game._doSubs()
	cplayerS = ""
	
	
	last = cplayer
	$goalscorer.text = "<left> <right> to choose player"
	$goalscorer.visible = true
	doSubs = true
	
func _setMap( var mtype):
	if mtype == 0:
		$Map.rect_position = Vector2(429, 425)
		$Map.rect_rotation = 0
	else:
		$Map.rect_position = Vector2(220, 410)
		$Map.rect_rotation = 90
		


func _on_SettingsButton_pressed():
	_updateCamUI()
	showDialog($DialogSettings)
	hideDialog($DialogPause)
	$DialogSettings / OkButton.grab_focus()
func _on_OkButton_pressed():
	hideDialog($DialogSettings)
	showDialog($DialogPause)
	Global._saveConfig()

func _on_HSlider_value_changed(value):
	
	game.mainCam.fov = value
	game.mainCam.mfov = value
	$DialogSettings / CamFovValue.text = str(value)
	match Global.camtype:
		0:
			Global.config.set_value("gfx", "camfov", value)
		1:
			Global.config.set_value("gfx", "camUDfov", value)
		2:
			Global.config.set_value("gfx", "camLRfov", value)

func _on_HeightSlider_value_changed(value):
	game.mainCam.translation.y = value
	$DialogSettings / CamHeightValue.text = str(value)
	match Global.camtype:
		0:
			Global.config.set_value("gfx", "camheight", value)
		1:
			Global.config.set_value("gfx", "camUDheight", value)
		2:
			Global.config.set_value("gfx", "camLRheight", value)


func _on_TiltSlider_value_changed(value):
	game.mainCam.rotation_degrees.x = value
	$DialogSettings / CamTiltValue.text = str(value)
	match Global.camtype:
		0:
			Global.config.set_value("gfx", "camtilt", value)
		1:
			Global.config.set_value("gfx", "camUDtilt", value)
		2:
			Global.config.set_value("gfx", "camLRtilt", value)


func _on_CamButton_item_selected(index):
	match index:
		0:
			_setMap(0)
		1:
			_setMap(1)
		2:
			_setMap(0)
	Global.config.set_value("gfx", "camtype", index)
	game._setCam(index)
	
	_updateCamUI()

func _on_OffsetSlider_value_changed(value):
	
	match Global.camtype:
		0:
			game.mainCam.zoffset = value
			Global.config.set_value("gfx", "camoffset", value)
		1:
			game.mainCam.xoffset = value
			Global.config.set_value("gfx", "camUDoffset", value)
		2:
			game.mainCam.zoffset = value
			Global.config.set_value("gfx", "camLRoffset", value)
			
	game.mainCam._updateCam(0.1)
	$DialogSettings / CamOffsetValue.text = str(value)


func _on_DOFSlider_value_changed(value):
	game.worldEnv.dof_blur_far_distance = value
	$DialogSettings / CamDOFValue.text = str(value)
	match Global.camtype:
		0:
			Global.config.set_value("gfx", "camdof", value)
		1:
			Global.config.set_value("gfx", "camUDdof", value)
		2:
			Global.config.set_value("gfx", "camLRdof", value)

func _on_ResetButton_pressed():
	
	match Global.camtype:
		0:
			$DialogSettings / CamDOFValue.text = str(90)
			$DialogSettings / DOFSlider.value = 90
			Global.config.set_value("gfx", "camfov", 45)
			Global.config.set_value("gfx", "camheight", 75)
			Global.config.set_value("gfx", "camtilt", - 48)
			Global.config.set_value("gfx", "camoffset", 70)
			
		1:
			$DialogSettings / CamDOFValue.text = str(90)
			$DialogSettings / DOFSlider.value = 90
			Global.config.set_value("gfx", "camUDfov", 50)
			Global.config.set_value("gfx", "camUDheight", 90)
			Global.config.set_value("gfx", "camUDtilt", - 65)
			Global.config.set_value("gfx", "camUDoffset", 70)
			
		2:
			$DialogSettings / CamDOFValue.text = str(90)
			$DialogSettings / DOFSlider.value = 90
			$DialogSettings / OffsetSlider.value = 70
			Global.config.set_value("gfx", "camLRfov", 60)
			Global.config.set_value("gfx", "camLRheight", 80)
			Global.config.set_value("gfx", "camLRtilt", - 80)
			Global.config.set_value("gfx", "camLRoffset", 70)
	_updateCamUI()

func _updateCamUI():
	match Global.config.get_value("gfx", "camtype"):
		0:
			$DialogSettings / OffsetSlider.value = Global.config.get_value("gfx", "camoffset")
			$DialogSettings / CamOffsetValue.text = str(Global.config.get_value("gfx", "camoffset"))
			$DialogSettings / TiltSlider.value = Global.config.get_value("gfx", "camtilt")
			$DialogSettings / CamTiltValue.text = str(Global.config.get_value("gfx", "camtilt"))
			$DialogSettings / HeightSlider.value = Global.config.get_value("gfx", "camheight")
			$DialogSettings / CamHeightValue.text = str(Global.config.get_value("gfx", "camheight"))
			$DialogSettings / HSlider.value = Global.config.get_value("gfx", "camfov")
			$DialogSettings / CamFovValue.text = str(Global.config.get_value("gfx", "camfov"))
			$DialogSettings / CamDOFValue.text = str(Global.config.get_value("gfx", "camdof"))
			$DialogSettings / DOFSlider.value = Global.config.get_value("gfx", "camdof")
			
		1:
			$DialogSettings / OffsetSlider.value = Global.config.get_value("gfx", "camUDoffset")
			$DialogSettings / CamOffsetValue.text = str(Global.config.get_value("gfx", "camUDoffset"))
			$DialogSettings / TiltSlider.value = Global.config.get_value("gfx", "camUDtilt")
			$DialogSettings / CamTiltValue.text = str(Global.config.get_value("gfx", "camUDtilt"))
			$DialogSettings / HeightSlider.value = Global.config.get_value("gfx", "camUDheight")
			$DialogSettings / CamHeightValue.text = str(Global.config.get_value("gfx", "camUDheight"))
			$DialogSettings / HSlider.value = Global.config.get_value("gfx", "camUDfov")
			$DialogSettings / CamFovValue.text = str(Global.config.get_value("gfx", "camUDfov"))
			$DialogSettings / CamDOFValue.text = str(Global.config.get_value("gfx", "camUDdof"))
			$DialogSettings / DOFSlider.value = Global.config.get_value("gfx", "camUDdof")
			
		2:
			$DialogSettings / OffsetSlider.value = Global.config.get_value("gfx", "camLRoffset")
			$DialogSettings / CamOffsetValue.text = str(Global.config.get_value("gfx", "camLRoffset"))
			$DialogSettings / TiltSlider.value = Global.config.get_value("gfx", "camLRtilt")
			$DialogSettings / CamTiltValue.text = str(Global.config.get_value("gfx", "camLRtilt"))
			$DialogSettings / HeightSlider.value = Global.config.get_value("gfx", "camLRheight")
			$DialogSettings / CamHeightValue.text = str(Global.config.get_value("gfx", "camLRheight"))
			$DialogSettings / HSlider.value = Global.config.get_value("gfx", "camLRfov")
			$DialogSettings / CamFovValue.text = str(Global.config.get_value("gfx", "camLRfov"))
			$DialogSettings / CamDOFValue.text = str(Global.config.get_value("gfx", "camLRdof"))
			$DialogSettings / DOFSlider.value = Global.config.get_value("gfx", "camLRdof")
	$DialogSettings / CamButton.selected = Global.config.get_value("gfx", "camtype")


func _showReplay():
	$ReplayLabel.visible = true
func _hideReplay():
	$ReplayLabel.visible = false
	$goalscorer.visible = false
	
func _pressToRestart():
	
	$goalscorer.text = bpass + " or " + bchip + Global.ll.toplay
	$goalscorer.visible = true
func _pressToRestartFK():
	$goalscorer.text = bpass + "," + bchip + "," + bshoot + Global.ll.toplay
	$goalscorer.visible = true
func _pressToRestartThrow():
	$goalscorer.text = bpass + Global.ll.toplay
	$goalscorer.visible = true
func _pressToRestartPen():
	$goalscorer.text = bshoot + Global.ll.toplay
	$goalscorer.visible = true
func _pressToRestartPenDefend():
	if Global.isTouch:
		$goalscorer.text = "move (joystick)  to save"
	else:
		$goalscorer.text = "hold <" + Global.udlr + "> to save"
	$goalscorer.visible = true

func _pressToQuit():
	$goalscorer.text = bpass + Global.ll.toexit
	$goalscorer.visible = true
func setupPauseControls():
	$DialogPause / Control / Label.text = ""
	for i in range(0, 9):
		$DialogPause / Control / Label.text += Global.ll.controls[i] + " :\n"
	$DialogPause / Control / Controls.text = "<" + OS.get_scancode_string(Global.udlrk[0]) + ">\n"
	$DialogPause / Control / Controls.text += "<" + OS.get_scancode_string(Global.udlrk[1]) + ">\n"
	$DialogPause / Control / Controls.text += "<" + OS.get_scancode_string(Global.udlrk[2]) + ">\n"
	$DialogPause / Control / Controls.text += "<" + OS.get_scancode_string(Global.udlrk[3]) + ">\n"
	$DialogPause / Control / Controls.text += "<" + OS.get_scancode_string(Global.buttsk[0]) + ">\n"
	$DialogPause / Control / Controls.text += "<" + OS.get_scancode_string(Global.buttsk[1]) + ">\n"
	$DialogPause / Control / Controls.text += "<" + OS.get_scancode_string(Global.buttsk[2]) + ">\n"
	$DialogPause / Control / Controls.text += "<" + OS.get_scancode_string(Global.buttsk[3]) + ">\n"
	$DialogPause / Control / Controls.text += "<" + OS.get_scancode_string(Global.shoulderk[2]) + ">\n"

func _pressToExit():
	$goalscorer.text = "<esc> (Pause) " + Global.ll.toexit
	$goalscorer.visible = true
	
func _lostFocus():
	$goalscorer.text = Global.ll.lostfocus
	$goalscorer.visible = true
func _gotFocus():
	$goalscorer.visible = false
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		_lostFocus()
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		_gotFocus()
func _showReplayButton():
	$DialogLarge / replay.visible = true

func _unlockRewarded( var doit):
	canPressButton = true
	if doit:
		var t = Global._unlockTeam(true)
		if t != "false":
			$UnlockDialog / Label.text = Global.ll.unlockteam
			$UnlockDialog / Label2.text = t
			$UnlockDialog / Label3.text = ""
			$UnlockDialog.visible = true
			
func _on_UnlockDialog_confirmed():
	
	
	
	$UnlockDialog.visible = false
	if tryRewarded:
		game._shushCrowd()
		canPressButton = false
		Global.isUnlocking = true
		if PokiSDK.isAdBlocked():
			canPressButton = true
		if not PokiSDK.rewardedBreak():
			canPressButton = true
		tryRewarded = false
	else:
		canPressButton = true
	
func _unlockUI():
	canPressButton = true
	
func _on_ButtonOK_pressed():
	_on_UnlockDialog_confirmed()
	$DialogLarge / exit.grab_focus()
	

func _on_ButtonCancel_pressed():
	if canPressButton:
		$UnlockDialog.visible = false
		canPressButton = true
		$DialogLarge / exit.grab_focus()
	
func setAggregateScore():
	$Aggregate.text = "(" + str(game.score[0] + Global.tournament.aggscore.y) + "-" + str(game.score[1] + Global.tournament.aggscore.x) + ")"
func _setScore( var x, var y):
	$Score1.set_text(str(x))
	$Score2.set_text(str(y))
	if Global.tournament and Global.tournament.leg == 2:
		setAggregateScore()
