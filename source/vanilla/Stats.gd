extends Node

var stats_dict = {"games_played": 0, 
				"games_completed": 0, 
				"wins": 0, 
				"defeats": 0, 
				"draws": 0, 
				"goals_for": 0, 
				"goals_against": 0, 
				"penalties": 0, 
				"sessions": 0, 
				"amcups": 0, 
				"procups": 0, 
				"chumpcups": 0, 
				"intcups": 0, 
				"globalcups": 0, 
				"amlg": 0, 
				"prolg": 0, 
				"chumplg": 0, 
				"intlg": 0, 
				}

func _loadStats():
	
	var statfile = File.new()
	
	if statfile.file_exists("user://slsstats.stat"):
		statfile.open("user://slsstats.stat", File.READ)
		
		stats_dict = parse_json(statfile.get_line())
		
	else:
		statfile.open("user://slsstats.stat", File.WRITE)
		
		statfile.store_line(to_json(stats_dict))
	statfile.close()
	stats_dict.sessions += 1
func _saveStats():
	var statfile = File.new()
	
	statfile.open("user://slsstats.stat", File.WRITE)
	statfile.store_line(to_json(stats_dict))
	statfile.close()
	




