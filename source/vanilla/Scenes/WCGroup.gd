extends Control

var league = null
var table = []
var myG = null
var ties = []
var ctie = 0
var isPlayerGroup = false

func _ready():
	var t = $TextureRect / TeamEntry
	table.append(t)
	table.append($TextureRect / TeamEntry2)
	table.append($TextureRect / TeamEntry3)
	table.append($TextureRect / TeamEntry4)
	league = Global.tournament

func _initGroup(var g):
	ties = $TextureRect / Ties.get_children()
	ctie = 0
	isPlayerGroup = false
	$TextureRect / Label.text = g.groupName
	myG = g
	_updateTable()
	if Global.tournament.cr < 3:
		_updateFixtures(g)

func _updateTable():
	ctie = 0
	for i in range(4):
		table[i].setWCVals(myG.table[i], Global.tournament.cr, i)
	for j in range(min(Global.tournament.cr, 3)):
		var f = j * 4
		_setTie(ctie, myG.games[f], myG.games[f + 1], myG.cround[j * 2])
		_setTie(ctie + 1, myG.games[f + 2], myG.games[f + 3], myG.cround[j * 2 + 1])
		ctie += 2

func _setTie(var index, var local_t1, var local_t2, var score):
	if index >= ties.size():
		return
	var t1 = myG.teams[local_t1]
	var t2 = myG.teams[local_t2]
	var t1p = t1 == Global.tTeam
	var t2p = t2 == Global.tTeam
	if t1p or t2p:
		isPlayerGroup = true
		$TextureRect2.visible = true
	ties[index]._setTie(Global.teams[t1].teamname, Global.teams[t2].teamname, score.x, score.y, t1p, t2p)

func _updateFixtures(var g):
	var r = Global.tournament.cr * 4
	ctie = Global.tournament.cr * 2
	if r + 3 >= g.fixtures.size():
		return
	_setTie(ctie, g.fixtures[r], g.fixtures[r + 1], Vector2.ZERO)
	_setTie(ctie + 1, g.fixtures[r + 2], g.fixtures[r + 3], Vector2.ZERO)
