extends Spatial


enum rstate{IDLE, KICKOFF, GAMEON, WHISTLE, CARD, PENALTY}
var state
var stateFunc = {}
var anim = false
var tostate = 0
var myAState = null
var myAPlayer = null

var target = null
var velocity = Vector3.ZERO
var gametarget = Vector3.ZERO
var la = Vector3.ZERO
var offender = null
var card = null
var game = null
var cardshad = null
var carded = false
var foulTolerance = 2
const HARD_BOOK_CHANCE = 0.5
func _ready():
	stateFunc[rstate.IDLE] = funcref(self, "idleState")
	stateFunc[rstate.GAMEON] = funcref(self, "gameOnState")
	stateFunc[rstate.KICKOFF] = funcref(self, "kickoffState")
	stateFunc[rstate.WHISTLE] = funcref(self, "whistleState")
	stateFunc[rstate.CARD] = funcref(self, "cardPlayer")
	myAState = $referee / AnimationTree.get("parameters/playback")
	myAPlayer = $referee / AnimationPlayer
	
	
	gametarget = Vector3( - 80, 0, 40) * Global.ps
	target = Vector3(0, 0, - 30)
	state = rstate.IDLE
	$referee._setRef(self)
	card = $referee / QuickRigCharacter_Reference / BoneAttachment / Card
	cardshad = card.get_active_material(0)
	foulTolerance = floor(rand_range(1, 4))
	
	
func process( var _delta):
	stateFunc[state].call_func()

func _physics_process( var delta):
	
	
	
	
	var pbs = - 1.33
	var dl = seek(target)
	
	if dl < 4.0:
		velocity *= dl / 4.0
	
	translation += velocity * delta
	var face = sign(velocity.dot(translation - target))
	pbs *= face
	translation.y = 0
	var vl = velocity.length()
	if not anim:
		if vl > 10:
			myAPlayer.playback_speed = pbs
			myAPlayer.play("refrun")
			
		elif vl > 1.2:
			myAPlayer.playback_speed = - 1.0 * face
		
			myAPlayer.play("refwalk")

		else:
			myAPlayer.playback_speed = 1.0
		
			myAPlayer.play("refidle")

			
	
	
	la.y = 0.0
	look_at(la, Vector3.UP)
	
	
func changeState( var s):
	if not anim:
		state = s
	else:
		tostate = s

func seek( var t):
	
	var diff = (t - translation)

	var dl = diff.length()
	var speed = smoothstep(2, 4, dl)
	var acc = (diff / dl) * 1.5 * speed
	if dl < 4:
		acc *= dl / 4.0
	velocity += acc
	
	velocity.y = 0
	if velocity.length() > 26:
		velocity = velocity.normalized() * 26
		
	return dl
	

func idleState():
	
	pass
func whistleState():
	pass
func gameOnState():
	
	
	var bl = smoothstep( - 100 * Global.ps, 100 * Global.ps, Global.ballpos.x)
	target = lerp(gametarget, - gametarget, bl)
	var close = seek(target)
	if close > 5:
		la = target
	else:
		la = Global.ballpos
		
func kickoffState():
	target = Vector3(0, 0, - 20)
	var _close = seek(target)
	la = Global.ballpos
	
func cardPlayer():
	if carded:
		return
	target = offender.translation + Vector3(0, 0, - 10)
	var close = seek(target)
	la = offender.translation
	# Yellows are quick: shown from where the ref is, card animation at double speed.
	# Reds keep the long walk over and the full animation.
	if close < (30.0 if offender.carded == 1 else 5.0):
		card.visible = true
		if offender.carded == 1:
			carded = true
			game.hud._yellowCard()
			anim = true
			offender._say(3)
			myAPlayer.play("refcard", -1, 2.0)
		else:
			carded = true
			game.hud._redCard()
			anim = true
			offender._say(3)
			myAPlayer.play("refcard")
			offender.AI._sentOff()
func _blowWhistle():
	
	changeState(rstate.WHISTLE)
	anim = true
	myAPlayer.play("refwhistle")
	
func _gameOn():
	changeState(rstate.GAMEON)
func _kickOff():
	changeState(rstate.KICKOFF)
func _animDone():
	anim = false
	changeState(tostate)
	
		
# lastMan: the offender was his side's last outfield defender, which is always a booking.
func _bookPlayer( var p, var lastMan = false):
	
	
	p.foulCount += 1
	# Hard tackles: half are booked on the spot, the rest count as two fouls.
	if p.get("hardFoul"):
		p.hardFoul = false
		if randf() < HARD_BOOK_CHANCE:
			lastMan = true
		else:
			p.foulCount += 1
	if lastMan or p.foulCount > foulTolerance:
		offender = p
		# The computer's players are booked so rarely that their first card is a straight red.
		if p.carded == 0 and p.myTeam.AIteam:
			p.foulCount = 0
			_sendOffPlayer(p)
			return true
		if p.carded == 0:
			cardshad.set_shader_param("albedo_color", Color(1, 1, 0))
			target = p.translation + Vector3(0, 0, - 5)
			carded = false
			changeState(rstate.CARD)
			tostate = rstate.GAMEON
		
			p.foulCount = 0
			p.carded = 1
		
		
		
			return true
		elif p.carded == 1:
			_sendOffPlayer(p)
		
			return true
	else:
		return false
func _sendOffPlayer( var p):
	offender = p
	cardshad.set_shader_param("albedo_color", Color(1, 0, 0))
	
	target = p.translation + Vector3(0, 0, - 5)
	carded = false
	changeState(rstate.CARD)
	tostate = rstate.GAMEON
	p.carded = 2
	
	
func _cardDone():
	anim = false
	changeState(tostate)
	if offender.carded == 1:
		game._doneBooking()
		offender.AI._defendFK()
	offender._loseControl()
	card.visible = false
	offender._shush()
	offender = null
func _blowWhistleSound():
	game._blowWhistle()
	
