extends Control





var table = []
var league
var fixtures = []


func _ready():
	league = Global.tournament
	
	var ts = load("res://Scenes/LeagueStanding.tscn")
	var tt = load("res://Scenes/LeagueTie.tscn")
	
	for i in range(0, league.nteams):
		var t = ts.instance()
		table.append(t)
		$ColorRect / ScrollContainer2 / TableGroup.add_child(t)
		t.rect_position.y = 36 * i
		t.setVals(league.table[i], league.cr - 1, i)
	
	
	var j = 0
	
	
	
	for i in range(0, league.nteams / 2):
		var f = tt.instance()
		$ColorRect / ScrollContainer / TieGroup.add_child(f)
		f.rect_position.y = 50 * i
		fixtures.append(f)
		var t1p = false
		var t2p = false
		
		var t1 = league.teams[league.fixtures[j]]
		var t2 = league.teams[league.fixtures[league.nteams - j - 1]]
		if (league.cr > league.nteams):
			var tmp = t2
			t2 = t1
			t1 = tmp
		if t1 == Global.tTeam:
			t1p = true
		elif t2 == Global.tTeam:
			t2p = true
		f._setTie(Global.teams[t1].teamname, Global.teams[t2].teamname, league.cround[i].x, league.cround[i].y, t1p, t2p)
		j += 2
	if league.justplayed:
		$ColorRect / PlayButton.text = "Next Round..."
		$ColorRect / FixturesLabel.text = "Results"
	else:
		$ColorRect / FixturesLabel.text = "Fixtures - Round " + str(Global.tournament.cr)
	$Transition._wipeOn()
	$ColorRect / PlayButton.grab_focus()



func displayFixtures( var clear):
	var j = 0
	var cmp = 1
	
	if clear:
		cmp = 0
	for i in range(0, league.nteams / 2):
		var f = fixtures[i]
		var t1p = false
		var t2p = false
		var t1 = league.teams[league.fixtures[j]]
		var t2 = league.teams[league.fixtures[league.nteams - j - 1]]
		if (league.cr > league.nteams):
			var tmp = t2
			t2 = t1
			t1 = tmp
			
		if t1 == Global.tTeam:
			t1p = true
		elif t2 == Global.tTeam:
			t2p = true
		if clear:
			league.cround[i].x = 0
			league.cround[i].y = 0
		f._setTie(Global.teams[t1].teamname, Global.teams[t2].teamname, league.cround[i].x, league.cround[i].y, t1p, t2p)
		j += 1

func _on_PlayButton_pressed():
	if league.cr > league.tr:
		$ColorRect / PlayButton.text = "League Complete"
		return
	if league.justplayed:
		
		
		league._rotateFixtures()
		displayFixtures(true)
		league.justplayed = false
		$ColorRect / PlayButton.text = "Play Round..."
		return
		
	var j = 0
	for _i in range(0, league.nteams / 2):
		
		var t1 = league.teams[league.fixtures[j]]
		var t2 = league.teams[league.fixtures[league.nteams - 1 - j]]
		if (league.cr > league.nteams):
			var tmp = t2
			t2 = t1
			t1 = tmp
		
		if t1 == Global.tTeam or t2 == Global.tTeam:
			if t1 == Global.tTeam:
				Global.p1human = true
				Global.p2human = false
			else:
				Global.p2human = true
				Global.p1human = false

			Global.team1 = Global.teamfiles[t1]
			Global.team2 = Global.teamfiles[t2]

			Global._loadTeams(false, false)

			Global.toLoad = 1
			$Transition._wipeOff()
			Global.stadium = 3 - int(Global.t1.level)

			yield($Transition / Tween, "tween_completed")
			var _foo = get_tree().change_scene("res://Scenes/Game.tscn")

		j += 2
	
	
	
func _on_BackButton_pressed():
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")
		



func _on_SaveButton_pressed():
	Global.tournament._saveState()
	displayFixtures(true)
	league.justplayed = false
	$ColorRect / FixturesLabel.text = "Fixtures - Round " + str(Global.tournament.cr)
	$ColorRect / PlayButton.text = "Play Round..."
