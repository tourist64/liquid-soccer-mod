extends Control

var teams = []
var teamfiles = []
var cteam = 0
var cdir = 0
var cplayer = 0
var pl = null
var mat = null
var hmat = null
var bmat = null
var home = true
var spin = false
var last = 0

func _ready():
	Global.teams = []
	teams = Global.teams
	
	readLevel(cdir)
	print("loading teams")
	
	
	fillteams()
	$BG / KitType.add_item("plain")
	$BG / KitType.add_item("vertical Stripe")
	$BG / KitType.add_item("horizontal Stripe")
	$BG / KitType.add_item("ajax-esque")
	$BG / KitType.add_item("diagonal")
	$BG / KitType.add_item("sleeves")
	$BG / KitType.add_item("single stripe")
	$BG / KitType.add_item("horizontal")
	$BG / KitType.add_item("thin stripe")
	$BG / KitType.add_item("halves")
	$BG / KitType.add_item("colour horizontal")
	$BG / KitType.add_item("double stripe")
	$BG / KitType.add_item("checks")
	
	
	$BG / PlayerStats / BeardType.add_item("none")
	$BG / PlayerStats / BeardType.add_item("full beard")
	$BG / PlayerStats / BeardType.add_item("tash")
	$BG / PlayerStats / BeardType.add_item("goatee")
	
	$BG / PlayerStats / HairType.add_item("none")
	$BG / PlayerStats / HairType.add_item("hair1")
	$BG / PlayerStats / HairType.add_item("hair2")
	$BG / PlayerStats / HairType.add_item("hair3")
	$BG / PlayerStats / HairType.add_item("hair4")
	$BG / PlayerStats / HairType.add_item("hair5")
	$BG / PlayerStats / HairType.add_item("hair6")
	
	$BG / TeamDir.add_item("International")
	$BG / TeamDir.add_item("Chumpions")
	$BG / TeamDir.add_item("Professional")
	$BG / TeamDir.add_item("Beginner")
	$BG / TeamDir.select(0)
	
	$BG / TeamParams / LeagueButton.add_item("Eng")
	$BG / TeamParams / LeagueButton.add_item("Esp")
	$BG / TeamParams / LeagueButton.add_item("Fra")
	$BG / TeamParams / LeagueButton.add_item("Ita")
	$BG / TeamParams / LeagueButton.add_item("USA")
	$BG / TeamParams / LeagueButton.add_item("Bra")
	$BG / TeamParams / LeagueButton.add_item("Arg")
	$BG / TeamParams / LeagueButton.add_item("Europa")
	$BG / TeamParams / LeagueButton.add_item("S America")
	$BG / TeamParams / LeagueButton.add_item("World")
	
func readLevel( var lev):
	teams.clear()
	teamfiles.clear()
	var dir = Directory.new()
	var l = String(lev)
	
	teams = Global.teams
	
	if dir.open("res://Teams/" + l + "/") == OK:
		dir.list_dir_begin(true, true)
		var filen = dir.get_next()
		while (filen != ""):
			var fn = "res://Teams/" + l + "/" + filen
			var t = load(fn)
			teams.append(t)
			teamfiles.append(fn)
			
			filen = dir.get_next()
		dir.list_dir_end()

func fillteams():
	$BG / TeamList.clear()
	
	for team in teams:
		$BG / TeamList.add_item(team.teamname)
	cteam = $BG / TeamList.selected
	
	setData()
	
func setData():
	
	var ct = teams[cteam]
	$BG / TacticsEditor._initMap(ct)
	$BG / TeamParams / Aggrssion.text = str(ct.aggression)
	$BG / TeamParams / Sponsor.text = ct.sponsor
	$BG / TeamParams / Level.text = str(ct.level)
	$BG / TeamParams / Tactics.text = str(ct.tictacs)
	$BG / TeamParams / Approach.text = str(ct.approach)
	$BG / ETeamName.text = ct.teamname
	$BG / TextEdit.text = ct.shortname
	$BG / TeamParams / LeagueButton.select(ct.League)
	loadKit()
	
func loadPlayerData():
	
	var myTeam = teams[cteam]
	pl = myTeam.player0
	match cplayer:
		1:
			pl = myTeam.player1
		2:
			pl = myTeam.player2
		3:
			pl = myTeam.player3
		4:
			pl = myTeam.player4
		5:
			pl = myTeam.player5
		6:
			pl = myTeam.player6
		7:
			pl = myTeam.player7
		8:
			pl = myTeam.player8
		9:
			pl = myTeam.player9
		10:
			pl = myTeam.player10
		11:
			pl = myTeam.player11
			
			
			
	$BG / PlayerStats / PName.text = pl.name
	$BG / PlayerStats / PAggression.text = str(pl.aggression)
	$BG / PlayerStats / PAgility.text = str(pl.agility)
	$BG / PlayerStats / PShoot.text = str(pl.shoot)
	$BG / PlayerStats / PSmart.text = str(pl.smart)
	$BG / PlayerStats / PSpeed.text = str(pl.speed)
	$BG / PlayerStats / PCurl.text = str(pl.curl)
	mat.set_shader_param("Skin", pl.skin)
	$BG / PlayerStats / SkinColor.color = pl.skin
	$BG / PlayerStats / HairColor.color = pl.hair
	$BG / PlayerStats / HairType.selected = pl.hairtype
	$BG / PlayerStats / BeardType.selected = pl.facehair
	
	
	var fh1 = false
	var fh2 = false
	var fh3 = false
	
	match pl.facehair:
		1:
			fh1 = true
			bmat = $BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / FacialHairMesh.get_surface_material(0)
		2:
			fh2 = true
			bmat = $BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / FacialHairMesh2.get_surface_material(0)
		3:
			fh3 = true
			bmat = $BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / FacialHairMesh3.get_surface_material(0)
	
	$BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / FacialHairMesh.visible = fh1
	$BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / FacialHairMesh2.visible = fh2
	$BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / FacialHairMesh3.visible = fh3
	if bmat:
		bmat.set_shader_param("albedo_color", pl.hair)
	fh1 = false
	fh2 = false
	fh3 = false
	var fh4 = false
	var fh5 = false
	var fh6 = false
	hmat = null
	match pl.hairtype:
		1:
			fh1 = true
			hmat = $BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair1.get_surface_material(0)
		2:
			fh2 = true
			hmat = $BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair2.get_surface_material(0)
		
		3:
			fh3 = true
			hmat = $BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair3.get_surface_material(0)
		4:
			fh4 = true
			hmat = $BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair4.get_surface_material(0)
		5:
			fh5 = true
			hmat = $BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair5.get_surface_material(0)
		6:
			fh6 = true
			hmat = $BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair6.get_surface_material(0)
		
	
	$BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair1.visible = fh1
	$BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair2.visible = fh2
	$BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair3.visible = fh3
	$BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair4.visible = fh4
	$BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair5.visible = fh5
	$BG / VPC / VP / Player / QuickRigCharacter_Reference / HeadAttach / Hair6.visible = fh6
	
	if hmat:
		hmat.set_shader_param("albedo_color", pl.hair)
	
func loadKit():
	mat = $BG / VPC / VP / Player / QuickRigCharacter_Reference / PlayerM.get_surface_material(0)
	
	var kit = teams[cteam].shirtType
	if not home:
		kit = teams[cteam].shirt2Type
	var kitn = "res://Images/player1.png"
	if kit > 0:
		kitn = "res://Images/player" + str(kit) + ".png"
	var tex = load(kitn)
	mat.set_shader_param("texture_albedo", tex)
	if kit == 11 or kit == 12:
		var kittrim = "res://Images/playertrim" + str(kit) + ".png"
		var ttex = load(kittrim)
		mat.set_shader_param("texture_albedo_trim", ttex)
	
	
	
	if (home):
		$BG / S1.color = teams[cteam].Shirt1Color
		$BG / S2.color = teams[cteam].Shirt2Color
		$BG / S3.color = teams[cteam].Shirt3Color
		$BG / Short.color = teams[cteam].ShortColor
		$BG / Keeper.color = teams[cteam].KeeperColor
		mat.set_shader_param("Shirt", teams[cteam].Shirt1Color)
		mat.set_shader_param("Shorts", teams[cteam].ShortColor)
		mat.set_shader_param("Shirt2", teams[cteam].Shirt2Color)
		mat.set_shader_param("Shirt3", teams[cteam].Shirt3Color)
	else:
		$BG / S1.color = teams[cteam].altShirt1Color
		$BG / S2.color = teams[cteam].altShirt2Color
		$BG / S3.color = teams[cteam].altShirt3Color
		$BG / Short.color = teams[cteam].altShortColor
		$BG / Keeper.color = teams[cteam].KeeperColor
		mat.set_shader_param("Shirt", teams[cteam].altShirt1Color)
		mat.set_shader_param("Shorts", teams[cteam].altShortColor)
		mat.set_shader_param("Shirt2", teams[cteam].altShirt2Color)
		mat.set_shader_param("Shirt3", teams[cteam].altShirt3Color)
	$BG / Number.color = teams[cteam].numberColor
	$BG / KitType.selected = max(0, kit - 1)

func _playerSelected( var sel):
	cplayer = sel
	loadPlayerData()

func _subSelected( var sel):
	cplayer = sel
	loadPlayerData()

func _on_TeamList_item_selected(index):
	cteam = index
	setData()
	_playerSelected(0)
	


func _on_KitType_item_selected(index):
	if home:
		teams[cteam].shirtType = index + 1
	else:
		teams[cteam].shirt2Type = index + 1
	loadKit()

func _on_S1_color_changed(color):
	
	if home:
		teams[cteam].Shirt1Color = color
		mat.set_shader_param("Shirt", teams[cteam].Shirt1Color)
	else:
		teams[cteam].altShirt1Color = color
		mat.set_shader_param("Shirt", teams[cteam].altShirt1Color)

func _on_S2_color_changed(color):
	if home:
		teams[cteam].Shirt2Color = color
		mat.set_shader_param("Shirt2", teams[cteam].Shirt2Color)
	else:
		teams[cteam].altShirt2Color = color
		mat.set_shader_param("Shirt2", teams[cteam].altShirt2Color)

func _on_Short_color_changed(color):
	if home:
		teams[cteam].ShortColor = color
		mat.set_shader_param("Shorts", teams[cteam].ShortColor)
	else:
		teams[cteam].altShortColor = color
		mat.set_shader_param("Shorts", teams[cteam].altShortColor)
		
func _on_Keeper_color_changed(color):
	teams[cteam].KeeperColor = color
	

func _on_HomeButton_pressed():
	home = true
	loadKit()


func _on_AwayButton_pressed():
	home = false
	loadKit()


func _on_VPC_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if not spin and event.pressed:
			spin = true
			last = event.position.x
		if not event.pressed:
			spin = false
	if event is InputEventMouseMotion and spin:
		var add = 4
		if last > event.position.x:
			add = - 4
		$BG / VPC / VP / Player.rotation_degrees.y += add
		last = event.position.x
		


func _on_BackButton_pressed():
	
	$Transition._wipeOff()
	yield($Transition / Tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")



func _on_Number_color_changed(color):
	teams[cteam].numberColor = color
	mat.set_shader_param("Numbers", teams[cteam].numberColor)

func _on_SaveButton_pressed():
	
	
	var f = teamfiles[cteam]
	var t = teams[cteam]
	var _res = ResourceSaver.save(f, t)
	

func _on_player_data_exited():
	
	pl.aggression = $BG / PlayerStats / PAggression.text.to_float()
	pl.agility = $BG / PlayerStats / PAgility.text.to_float()
	pl.shoot = $BG / PlayerStats / PShoot.text.to_float()
	pl.smart = $BG / PlayerStats / PSmart.text.to_float()
	pl.speed = $BG / PlayerStats / PSpeed.text.to_float()
	pl.curl = $BG / PlayerStats / PCurl.text.to_float()
	
func _on_PName_focus_exited():
	pl.name = $BG / PlayerStats / PName.text
	loadPlayerData()
	var ct = teams[cteam]
	$BG / TacticsEditor._initMap(ct)


func _on_HairColor_color_changed(color):
	pl.hair = color
	loadPlayerData()
	

func _on_SkinColor_color_changed(color):
	pl.skin = color
	mat.set_shader_param("Skin", pl.skin)


func _on_SaveAsButton_pressed():
	
	
	var l = String(cdir)
	
	var f = "res://Teams/" + l + "/" + $BG / ETeamName.text + ".tres"
	var t = teams[cteam].duplicate()
	print(f)
	var res = ResourceSaver.save(f, t)
	
	print(res)
	readLevel(cdir)
	fillteams()

func _on_HairType_item_selected(index):
	pl.hairtype = index
	loadPlayerData()


func _on_BeardType_item_selected(index):
	pl.facehair = index
	loadPlayerData()


func _on_Sponsor_focus_exited():
	var ct = teams[cteam]
	ct.aggression = $BG / TeamParams / Aggrssion.text.to_float()
	ct.sponsor = $BG / TeamParams / Sponsor.text
	ct.level = $BG / TeamParams / Level.text.to_float()
	ct.tictacs = $BG / TeamParams / Tactics.text.to_float()
	ct.approach = $BG / TeamParams / Approach.text.to_float()
	


func _on_ETeamName_focus_exited():
	var ct = teams[cteam]
	ct.teamname = $BG / ETeamName.text
	


func _on_TeamDir_item_selected(index):
	cdir = index
	readLevel(index)
	fillteams()


func _on_TextEdit_focus_exited():
	var ct = teams[cteam]
	ct.shortname = $BG / TextEdit.text


func _on_S3_color_changed(color):
	if home:
		teams[cteam].Shirt3Color = color
		mat.set_shader_param("Shirt3", teams[cteam].Shirt3Color)
	else:
		teams[cteam].altShirt3Color = color
		mat.set_shader_param("Shirt3", teams[cteam].altShirt3Color)



func _on_LeagueButton_item_selected(index):
	teams[cteam].League = index
