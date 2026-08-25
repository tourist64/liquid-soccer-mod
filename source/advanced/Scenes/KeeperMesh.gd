
extends Spatial
var myk = null






func _ready():
	myk = get_parent()

func diveDone( var _cf):
	myk.diving = false
	myk.myPlayer.canControl = false
	if myk.state != myk.pstate.REPLAY:
	
	
	
		myk.forceChangeState(myk.tostate)
	
	myk.vel *= 0.1
	
	
	yield(get_tree().create_timer(0.2), "timeout")
	myk.myPlayer.canControl = true
	
func kickBall():
	myk._kickBall()
func throwBall():
	myk._throwBall()
	
func idleDone():
	myk.myPlayer.myAState.travel("idle")
	
func collectDone():
	
	
	myk.diving = false
	
	if myk.state != myk.pstate.REPLAY:
		myk.forceChangeState(myk.tostate)
	
	yield(get_tree().create_timer(0.25), "timeout")
	myk.myPlayer.canControl = true
		
		
	
	
	
	
	

func _on_AreaTest_area_entered(area):

	myk.myPlayer._on_TestSaveArea_area_entered(area)


func _on_AreaTest_area_exited(area):
	myk.myPlayer._on_SaveArea_area_exited(area)
