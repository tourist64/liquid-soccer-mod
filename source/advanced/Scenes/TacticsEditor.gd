extends Control





var myTeam
var players = []
var player = 0
var posedit = null
var last = 0
var own = null
var ps = []

func _ready():
	players.append($TacticsMap / P0)
	players.append($TacticsMap / P1)
	players.append($TacticsMap / P2)
	players.append($TacticsMap / P3)
	players.append($TacticsMap / P4)
	players.append($TacticsMap / P5)
	players.append($TacticsMap / P6)
	own = get_parent().get_parent()
	
func _initMap( var team):
	myTeam = team
	$ItemList.clear()
	$ItemList2.clear()
	$Midfield.pressed = true
	$ItemList.add_item(myTeam.player0.name)
	$ItemList.add_item(myTeam.player1.name)
	$ItemList.add_item(myTeam.player2.name)
	$ItemList.add_item(myTeam.player3.name)
	$ItemList.add_item(myTeam.player4.name)
	$ItemList.add_item(myTeam.player5.name)
	$ItemList.add_item(myTeam.player6.name)
	$ItemList2.add_item(myTeam.player7.name)
	$ItemList2.add_item(myTeam.player8.name)
	$ItemList2.add_item(myTeam.player9.name)
	$ItemList2.add_item(myTeam.player10.name)
	$ItemList2.add_item(myTeam.player11.name)
	
	
	_on_Midfield_pressed()
	

func _on_Defend_pressed():
	posedit = myTeam.def
	$TacticsMap / P1.anchor_left = myTeam.def[0].x
	$TacticsMap / P2.anchor_left = myTeam.def[1].x
	$TacticsMap / P3.anchor_left = myTeam.def[2].x
	$TacticsMap / P4.anchor_left = myTeam.def[3].x
	$TacticsMap / P5.anchor_left = myTeam.def[4].x
	$TacticsMap / P6.anchor_left = myTeam.def[5].x
	$TacticsMap / P1.anchor_top = myTeam.def[0].y
	$TacticsMap / P2.anchor_top = myTeam.def[1].y
	$TacticsMap / P3.anchor_top = myTeam.def[2].y
	$TacticsMap / P4.anchor_top = myTeam.def[3].y
	$TacticsMap / P5.anchor_top = myTeam.def[4].y
	$TacticsMap / P6.anchor_top = myTeam.def[5].y
		


func _on_Midfield_pressed():
	posedit = myTeam.mid
	$TacticsMap / P1.anchor_left = myTeam.mid[0].x
	$TacticsMap / P2.anchor_left = myTeam.mid[1].x
	$TacticsMap / P3.anchor_left = myTeam.mid[2].x
	$TacticsMap / P4.anchor_left = myTeam.mid[3].x
	$TacticsMap / P5.anchor_left = myTeam.mid[4].x
	$TacticsMap / P6.anchor_left = myTeam.mid[5].x
	
	$TacticsMap / P1.anchor_top = myTeam.mid[0].y
	$TacticsMap / P2.anchor_top = myTeam.mid[1].y
	$TacticsMap / P3.anchor_top = myTeam.mid[2].y
	$TacticsMap / P4.anchor_top = myTeam.mid[3].y
	$TacticsMap / P5.anchor_top = myTeam.mid[4].y
	$TacticsMap / P6.anchor_top = myTeam.mid[5].y


func _on_Attack_pressed():
	posedit = myTeam.att
	$TacticsMap / P1.anchor_left = myTeam.att[0].x
	$TacticsMap / P2.anchor_left = myTeam.att[1].x
	$TacticsMap / P3.anchor_left = myTeam.att[2].x
	$TacticsMap / P4.anchor_left = myTeam.att[3].x
	$TacticsMap / P5.anchor_left = myTeam.att[4].x
	$TacticsMap / P6.anchor_left = myTeam.att[5].x
	
	$TacticsMap / P1.anchor_top = myTeam.att[0].y
	$TacticsMap / P2.anchor_top = myTeam.att[1].y
	$TacticsMap / P3.anchor_top = myTeam.att[2].y
	$TacticsMap / P4.anchor_top = myTeam.att[3].y
	$TacticsMap / P5.anchor_top = myTeam.att[4].y
	$TacticsMap / P6.anchor_top = myTeam.att[5].y


func _input(event):
	if (player > 0):
		if (event is InputEventJoypadMotion):
			var xoff = Input.get_joy_axis(0, 0)
			var yoff = Input.get_joy_axis(0, 1)
			if (abs(xoff) < 0.3):
				xoff = 0
			if (abs(yoff) < 0.3):
				yoff = 0
			var pl = posedit[player - 1]
			posedit[player - 1].x = clamp(pl.x + xoff * 0.00251, 0, 1)
			posedit[player - 1].y = clamp(pl.y + yoff * 0.00251, 0, 1)
			players[player].anchor_left = posedit[player - 1].x
			players[player].anchor_top = posedit[player - 1].y
			
func _on_ItemList_item_selected(index):
	if (index > 0):
		players[index].modulate = Color(1.0, 1.0, 1.0, 1.0)
		player = index
		if (last > 0):
			players[last].modulate = Color(0.96, 0.8, 0.44)
		last = index
	own._playerSelected(index)


func _on_Corner_pressed():
	posedit = myTeam.cor
	$TacticsMap / P1.anchor_left = myTeam.cor[0].x
	$TacticsMap / P2.anchor_left = myTeam.cor[1].x
	$TacticsMap / P3.anchor_left = myTeam.cor[2].x
	$TacticsMap / P4.anchor_left = myTeam.cor[3].x
	$TacticsMap / P5.anchor_left = myTeam.cor[4].x
	$TacticsMap / P6.anchor_left = myTeam.cor[5].x
	
	$TacticsMap / P1.anchor_top = myTeam.cor[0].y
	$TacticsMap / P2.anchor_top = myTeam.cor[1].y
	$TacticsMap / P3.anchor_top = myTeam.cor[2].y
	$TacticsMap / P4.anchor_top = myTeam.cor[3].y
	$TacticsMap / P5.anchor_top = myTeam.cor[4].y
	$TacticsMap / P6.anchor_top = myTeam.cor[5].y


func _on_swapButton_pressed():
	var p1 = null
	if not $ItemList.is_anything_selected():
		return
	var p1s = $ItemList.get_selected_items()[0]
	match p1s:
		0:
			p1 = myTeam.player0
		1:
			p1 = myTeam.player1
		2:
			p1 = myTeam.player2
		3:
			p1 = myTeam.player3
		4:
			p1 = myTeam.player4
		5:
			p1 = myTeam.player5
		6:
			p1 = myTeam.player6
	var p2 = null
	if not $ItemList2.is_anything_selected():
		return
	var p2s = $ItemList2.get_selected_items()[0]
	
		
	match p2s:
		0:
			p2 = myTeam.player7
		1:
			p2 = myTeam.player8
		2:
			p2 = myTeam.player9
		3:
			p2 = myTeam.player10
		4:
			p2 = myTeam.player11
	
	var ptemp = p1.duplicate()
	var ptemp2 = p2.duplicate()
	
	copyDict(ptemp2, p1)
	copyDict(ptemp, p2)
	_initMap(myTeam)
	
func copyDict( var p1, var p2):
	var keys = p1.keys()
	for i in range(keys.size()):
		p2[keys[i]] = p1.get(keys[i])
	
			


func _on_ItemList2_item_selected(index):
	own._subSelected(7 + index)
