extends Control



var icons = []
var totals = [0, 0]
var rleft = [5, 5]
var sDeath = false

func _ready():
	
	icons = $ColorRect / Icons.get_children()
	
func _initShootout():
	$ColorRect / Team1.text = Global.t1.shortname
	$ColorRect / Team2.text = Global.t2.shortname
func resetIcons():
	for ic in icons:
		ic.modulate = Color(0.6, 0.1, 0.1)
func _setIcon( var team, var id, var scored):
	var i = team * 5 + id
	if sDeath:
		i = team
	if scored:
		icons[i].modulate = Color(0.1, 0.9, 0.0)
		totals[team] += 1
	else:
		icons[i].modulate = Color(0.9, 0.1, 0.0)

	rleft[team] -= 1

func _checkScores():
	if totals[0] > totals[1] + rleft[1]:
		return 1
	elif totals[1] > totals[0] + rleft[0]:
		return 2
	else:
		return 0
func _getFinalScore():
	return Vector2(totals[0], totals[1])
func _suddenDeath():
	
	rleft[0] = 1
	rleft[1] = 1
	sDeath = true
	resetIcons()
	
