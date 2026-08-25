extends Spatial

var p = null


func _ready():
	p = get_parent()
func animDone():
	
	if p.AI.state != p.AI.pstate.REPLAY:
		p.AI.state = p.AI.prevstate
		if p.AI.isHuman and ( not p.myTeam.AIteam):
			p.isAI = false

func slideDone():
	
	if p.AI.state != p.AI.pstate.REPLAY:
	
		p.AI.state = p.AI.prevstate
	
	
		if p.AI.isHuman and ( not p.myTeam.AIteam):
			p.isAI = false
		p.myfx.emitting = false
	

func fouledDone():
	
	if p.AI.state != p.AI.pstate.REPLAY:
		p.AI.state = p.AI.prevstate
		if p.AI.isHuman and ( not p.myTeam.AIteam):
			p.isAI = false
		p.AI._fouledDone()
func celebDone():
	
	if p.AI.state != p.AI.pstate.REPLAY:
		p.AI.state = p.AI.prevstate
		
func doShot():
	
	if p.AI.state != p.AI.pstate.REPLAY:
		p._doNewShot()
	

func throwBall():
	if p.AI.state != p.AI.pstate.REPLAY:
		p.AI._throwBall()
func tryBike():
	if p.AI.state != p.AI.pstate.REPLAY:
		p.AI._tryBicycleKick()
func tryHeader():
	if p.AI.state != p.AI.pstate.REPLAY:
		p.AI._tryHeader()
func headDone():
	p.canHead = false
func idleDone():
	p.myAState.travel("idle")
