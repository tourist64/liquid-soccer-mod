extends Control








func _ready():
	pass

func setVals( var dat, var r, var id):
	$ColorRect / Name.text = dat.name
	$ColorRect / Played.text = str(r)
	$ColorRect / Won.text = str(dat.w)
	$ColorRect / Drawn.text = str(dat.d)
	$ColorRect / Lost.text = str(dat.l)
	$ColorRect / For.text = str(dat.gf)
	$ColorRect / Against.text = str(dat.ga)
	$ColorRect / Points.text = str(dat.pts)
	if id % 2 == 0:
		$ColorRect.color.a = 0.8

func setWCVals( var dat, var r, var id):
	$ColorRect / Name.text = dat.name
	$ColorRect / Played.text = str(r)
	$ColorRect / For.text = str(dat.gf)
	$ColorRect / Against.text = str(dat.ga)
	$ColorRect / Points.text = str(dat.pts)
	if id % 2 == 0:
		$ColorRect.color.a = 0.8
	



