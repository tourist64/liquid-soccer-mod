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
# 11v11 style: counter = how hard the team looks forward right after winning the ball (0-1);
# cornerOutlets = players left upfield when defending a corner (0 = everyone back).
export (float) var counter = 0.0
export (int) var cornerOutlets = 1
# How much the team attacks from wide with crosses, and how dangerous its set pieces are (0-1).
export (float) var crossing = 0.3
export (float) var setPieces = 0.3
# Unit shape (0-1): without the ball the whole team holds its deep shape wherever the ball is;
# on the attack the whole team moves up into its attacking shape from around halfway.
export (float) var unitShape = 0.0
# Corner lockdown: every outfield player marks at defending corners, nearest attackers first,
# spare defenders doubling up, all staying close to the keeper.
export (float) var cornerLockdown = 0.0
# Mid-block (0-1): a unit-shape team defends higher and wider when the ball is far from its goal,
# drops back as the ball comes into its half and squeezes into a tight low block near the box.
export (float) var midBlock = 0.0
# Offside trap (0-1): the back line steps up past attackers who are just onside near it.
export (float) var offsideTrap = 0.0
# Possession-and-pressure back line (0-1), Guardiola style: compact with midfield, drops off when an
# opponent has clean time in midfield. Replaces the offside trap for the sides that use it.
export (float) var pepLine = 0.0
# Counter-press (0-1): for 6 seconds after losing the ball the three nearest players swarm the carrier.
export (float) var counterPress = 0.0
# Holding midfielder who screens centrally and never man-marks wide (player number, 0 = none).
export (int) var anchorId = 0
# Keeper comes out to sweep loose balls in his box in normal matches too (0-1).
export (float) var sweeperKeeper = 0.0
# How far open-play crosses carry in normal matches (1 = the game's usual cross, lower = shorter).
export (float) var crossPace = 1.0
# Comeback (0-1): the further behind, the harder the team presses, tackles and counters.
export (float) var comeback = 0.0


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




