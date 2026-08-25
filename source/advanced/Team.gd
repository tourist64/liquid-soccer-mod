extends Resource

export (String) var teamname
export (String) var shortname
export (Color) var Shirt1Color
export (Color) var Shirt2Color
export (Color) var Shirt3Color
export (Color) var ShortColor
export (Color) var KeeperColor
export (Color) var altShirt1Color
export (Color) var altShirt2Color
export (Color) var altShirt3Color
export (Color) var altShortColor
export (Color) var numberColor
export (String) var sponsor
export (int) var shirtType = 0
export (int) var shirt2Type = 0
export (int) var level = 1
export (float) var tictacs = 5.0
export (int) var aggression = 2
export (float) var approach = 0.5
export (int) var League = 0


export var player0 = {
	"name": "P Smeckle", 
	"speed": 3, 
	"aggression": 5, 
	"agility": 4, 
	"shoot": 5, 
	"smart": 10, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}
export var player1 = {
	"name": "G Nebille", 
	"speed": 3, 
	"aggression": 7.5, 
	"agility": 4, 
	"shoot": 5, 
	"smart": 10, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}
export var player2 = {
	"name": "J Stim", 
	"speed": 3, 
	"aggression": 5, 
	"agility": 4, 
	"shoot": 5, 
	"smart": 10, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}
export var player3 = {
	"name": "B Bobson", 
	"speed": 3, 
	"aggression": 5, 
	"agility": 4, 
	"shoot": 5, 
	"smart": 10, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}
export var player4 = {
	"name": "E Cantina", 
	"speed": 3, 
	"aggression": 5, 
	"agility": 4, 
	"shoot": 5, 
	"smart": 8, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}
export var player5 = {
	"name": "M Hoos", 
	"speed": 3, 
	"aggression": 5, 
	"agility": 4, 
	"shoot": 7.5, 
	"smart": 9, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}
export var player6 = {
	"name": "M Newplayer", 
	"speed": 3, 
	"aggression": 5, 
	"shoot": 7.5, 
	"agility": 4, 
	"smart": 10, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}
export var player7 = {
	"name": "M Newplayer", 
	"speed": 3, 
	"aggression": 5, 
	"shoot": 7.5, 
	"agility": 4, 
	"smart": 10, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}
export var player8 = {
	"name": "M Newplayer", 
	"speed": 3, 
	"aggression": 5, 
	"shoot": 7.5, 
	"agility": 4, 
	"smart": 10, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}
export var player9 = {
	"name": "M Newplayer", 
	"speed": 3, 
	"aggression": 5, 
	"shoot": 7.5, 
	"agility": 4, 
	"smart": 10, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}
export var player10 = {
	"name": "M Newplayer", 
	"speed": 3, 
	"aggression": 5, 
	"shoot": 7.5, 
	"agility": 4, 
	"smart": 10, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}
export var player11 = {
	"name": "M Newplayer", 
	"speed": 3, 
	"aggression": 5, 
	"shoot": 7.5, 
	"agility": 4, 
	"smart": 10, 
	"curl": 5, 
	"skin": Color(1.0, 1.0, 1.0), 
	"hair": Color(1.0, 1.0, 1.0), 
	"hairtype": 0, 
	"facehair": 0
}

export var def = [Vector2(0.35, 0.82743), Vector2(0.592117, 0.834043), Vector2(0.468157, 0.663929), Vector2(0.25, 0.6), Vector2(0.7, 0.6), Vector2(0.470395, 0.786494)]
export var mid = [Vector2(0.3, 0.68), Vector2(0.65, 0.68), Vector2(0.56573, 0.545717), Vector2(0.25, 0.35), Vector2(0.7, 0.35), Vector2(0.384668, 0.545014)]
export var att = [Vector2(0.3, 0.46), Vector2(0.65, 0.5), Vector2(0.456011, 0.189642), Vector2(0.25, 0.16), Vector2(0.7, 0.15), Vector2(0.504884, 0.312707)]
export var cor = [Vector2(0.451, 0.258), Vector2(0.472, 0.456), Vector2(0.62, 0.165), Vector2(0.308, 0.155), Vector2(0.522, 0.138), Vector2(0.473, 0.15)]




