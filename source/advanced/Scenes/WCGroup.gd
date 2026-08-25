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
	t = $TextureRect / TeamEntry2
	table.append(t)
	t = $TextureRect / TeamEntry3
	table.append(t)
	t = $TextureRect / TeamEntry4
	table.append(t)
	league = Global.tournament
	
func _initGroup( var g):
	ties = $Ties.get_children()
	
	$TextureRect / Label.text = g.groupName
	myG = g
	_updateTable()
	var chk = 3
	if Global.tType == 4:
		chk = 6
	if Global.tournament.cr < chk:
		_updateFixtures(g)
		
	
func _updateTable():
	
	for i in range(0, 4):
		table[i].setWCVals(myG.table[i], Global.tournament.cr, i)
	
	var f = 0
	var e = 3
	if Global.tType == 4:
		if Global.tournament.cr > 2:
			e = 6
			f = 3
	for _j in range(f, min(Global.tournament.cr, e)):
		var t1 = myG.teams[myG.games[f]]
		var t2 = myG.teams[myG.games[f + 1]]
		var t1p = false
		var t2p = false
		if t1 == Global.tTeam:
				t1p = true
		elif t2 == Global.tTeam:
				t2p = true
		if t1p or t2p:
			isPlayerGroup = true
			$TextureRect2.visible = true
		ties[ctie]._setTie(Global.teams[t1].teamname, Global.teams[t2].teamname, myG.cround[ctie].x, myG.cround[ctie].y, t1p, t2p)
		t1 = myG.teams[myG.games[f + 2]]
		t2 = myG.teams[myG.games[f + 3]]
		t1p = false
		t2p = false
		if t1 == Global.tTeam:
				t1p = true
		elif t2 == Global.tTeam:
				t2p = true
		ties[ctie + 1]._setTie(Global.teams[t1].teamname, Global.teams[t2].teamname, myG.cround[ctie + 1].x, myG.cround[ctie + 1].y, t1p, t2p)
		f += 4
		ctie += 2

func _updateFixtures( var g):
	
	var r = Global.tournament.cr * 4
	var t1 = g.teams[g.fixtures[r]]
	var t2 = g.teams[g.fixtures[r + 1]]
	var t1p = false
	var t2p = false
	if t1 == Global.tTeam:
			t1p = true
	elif t2 == Global.tTeam:
			t2p = true
	ties[ctie]._setTie(Global.teams[t1].teamname, Global.teams[t2].teamname, 0, 0, t1p, t2p)
	t1 = g.teams[g.fixtures[r + 2]]
	t2 = g.teams[g.fixtures[r + 3]]
	t1p = false
	t2p = false
	if t1 == Global.tTeam:
			t1p = true
	elif t2 == Global.tTeam:
			t2p = true
	ties[ctie + 1]._setTie(Global.teams[t1].teamname, Global.teams[t2].teamname, 0, 0, t1p, t2p)

