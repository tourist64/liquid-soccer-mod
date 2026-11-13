extends Spatial

# 11v11 stadium: a steep three-tier rounded bowl under a pale roof, generated in world units
# (about 3.3 units per metre; the pitch is 347 x 225). The upper tiers in the middle of the near
# side are a separate mesh, shown only while the active camera is in front of them, so the
# sideline cameras always see the pitch and every other camera sees a complete stadium.

const SEGMENTS = 120
const CORNER_POWER = 6.0
const NEAR_CUT_Z = 130.0
const NEAR_CUT_X = 190.0

const SEAT_A = Color(0.10, 0.20, 0.47)
const SEAT_B = Color(0.14, 0.27, 0.58)
const RISER = Color(0.07, 0.12, 0.27)
const FASCIA = Color(0.88, 0.89, 0.90)
const CONCOURSE = Color(0.16, 0.18, 0.22)
const ROOF = Color(0.74, 0.77, 0.80)
const ROOF_EDGE = Color(0.93, 0.94, 0.95)

# a/b = [half length, half width, height] at the front and back of each tier.
var tiers = [
	{"a": [212.0, 142.0, 3.0], "b": [254.0, 184.0, 36.0], "rows": 10, "near": true},
	{"a": [246.0, 178.0, 52.0], "b": [284.0, 216.0, 88.0], "rows": 9, "near": false},
	{"a": [278.0, 210.0, 104.0], "b": [324.0, 256.0, 158.0], "rows": 11, "near": false},
]

var ratio = 1.0
# "bernabeu": white tier edges, a silver roof over every seat, a 360 screen ring and a bigger crowd.
var style = ""
var crowdScale = 1.0
# Share of fans per tier (lower, middle, top). The Bernabeu fills every tier evenly by seating area.
var tierWeights = [0.62, 0.23, 0.15]
# Even spread (Bernabeu): fans are placed by a low-discrepancy sequence, evenly by distance around
# the stand and up its rows, instead of at random, so there are no gaps or clumps.
var evenSpread = false
var haltonIndex = 0
var arcTables = {}
const ARC_SAMPLES = 1024
var fascia = FASCIA
var roof = ROOF
var roofEdge = ROOF_EDGE
const BERNABEU_FASCIA = Color(0.97, 0.97, 0.98)
const BERNABEU_ROOF = Color(0.80, 0.82, 0.85)
const BERNABEU_ROOF_EDGE = Color(0.62, 0.65, 0.70)
# "REAL MADRID" spelled in white seats along both long sides of the lower tier (a 5x7 pixel font),
# mirrored on the near side so it reads from the pitch. Fans sitting on the letters wear the home
# shirt colour and the fans around them navy, so the crowd shows it too (a tifo).
const TEXT = "REAL MADRID"
const TEXT_TIER = 0
const TEXT_HALF = 130.0     # half the length of the lettering along the side
const TEXT_TOP = 0.95       # share of the tier's depth where the letters start (from the front)
const TEXT_BOTTOM = 0.12
const SEAT_TEXT = Color(0.95, 0.95, 0.97)
const TIFO_BG = Color(0.07, 0.11, 0.32)
const FONT = {
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"I": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
	" ": [".....", ".....", ".....", ".....", ".....", ".....", "....."]}
var paintText = false
var tifoBg = TIFO_BG
# Per fan from the last seats() call: 0 = ordinary, 1 = tifo background (navy), 2 = on a letter.
var lastTifo = []
const BERNABEU_SCREEN = [Color(0.95, 0.96, 1.0), Color(0.83, 0.68, 0.24), Color(0.95, 0.96, 1.0), Color(0.36, 0.20, 0.62)]
var st
var stMain
var stNear
var nearMesh
var nearCrowd = null
var nearShown = false

func _ready():
	# The bowl is sized for the design pitch scale; keep it the same distance from a smaller pitch.
	ratio = Global.ps / Global.ELEVEN_DESIGN_SCALE
	if style == "bernabeu":
		fascia = BERNABEU_FASCIA
		roof = BERNABEU_ROOF
		roofEdge = BERNABEU_ROOF_EDGE
		# About 25,000 fans: ~17,400 home, ~2,500 away and ~5,000 on the near-side upper tiers.
		crowdScale = 3.62
		evenSpread = true
		tierWeights = [0.25, 0.29, 0.46]
		paintText = true
	for d in tiers:
		d["a"] = [d["a"][0] * ratio, d["a"][1] * ratio, d["a"][2]]
		d["b"] = [d["b"][0] * ratio, d["b"][1] * ratio, d["b"][2]]
	var m = SpatialMaterial.new()
	m.vertex_color_use_as_albedo = true
	m.flags_unshaded = true
	m.params_cull_mode = SpatialMaterial.CULL_DISABLED
	stMain = _newSurface(m)
	stNear = _newSurface(m)
	st = stMain
	for t in range(tiers.size()):
		_buildTier(t)
	_buildRoof()
	if paintText:
		_textOverlay()
	_addMesh("BowlMesh", stMain)
	nearMesh = _addMesh("BowlNearUpper", stNear)
	nearMesh.visible = false

func _newSurface(m):
	var s = SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	s.set_material(m)
	return s

func _addMesh(n, s):
	var mi = MeshInstance.new()
	mi.name = n
	mi.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	mi.mesh = s.commit()
	add_child(mi)
	return mi

func _process(_delta):
	var cam = get_viewport().get_camera()
	var show = cam != null and cam.global_transform.origin.z < NEAR_CUT_Z * ratio
	if show != nearShown:
		nearShown = show
		nearMesh.visible = show
		if nearCrowd:
			nearCrowd.visible = show

func _ring(hx, hz, i):
	var t = TAU * float(i) / SEGMENTS
	var c = cos(t)
	var s = sin(t)
	return Vector2(hx * sign(c) * pow(abs(c), 2.0 / CORNER_POWER), hz * sign(s) * pow(abs(s), 2.0 / CORNER_POWER))

func _blocksView(p):
	return p.y > NEAR_CUT_Z * ratio and abs(p.x) < NEAR_CUT_X * ratio

func _skip(i, hx, hz, nearAllowed):
	if nearAllowed:
		return false
	return _blocksView(_ring(hx, hz, float(i) + 0.5))

# One band of the bowl between two (half length, half width, height) profiles.
func _band(p, q, col, nearAllowed):
	for i in range(SEGMENTS):
		st = stNear if _skip(i, q[0], q[1], nearAllowed) else stMain
		var c = col
		if typeof(col) == TYPE_ARRAY:
			c = col[int(i / 5) % col.size()]
		var a0 = _ring(p[0], p[1], i)
		var a1 = _ring(p[0], p[1], i + 1)
		var b0 = _ring(q[0], q[1], i)
		var b1 = _ring(q[0], q[1], i + 1)
		_tri(Vector3(a0.x, p[2], a0.y), Vector3(a1.x, p[2], a1.y), Vector3(b1.x, q[2], b1.y), c)
		_tri(Vector3(a0.x, p[2], a0.y), Vector3(b1.x, q[2], b1.y), Vector3(b0.x, q[2], b0.y), c)

func _tri(a, b, c, col):
	for v in [a, b, c]:
		st.add_color(col)
		st.add_vertex(v)

func _buildTier(t):
	var d = tiers[t]
	var a = d["a"]
	var b = d["b"]
	var near = d["near"]
	var rows = d["rows"]
	_band([a[0], a[1], a[2] - 6.0], [a[0], a[1], a[2]], fascia, near)
	var seats = [SEAT_A, SEAT_B]
	for r in range(rows):
		var f0 = float(r) / rows
		var f1 = float(r + 1) / rows
		var hx0 = lerp(a[0], b[0], f0)
		var hz0 = lerp(a[1], b[1], f0)
		var y0 = lerp(a[2], b[2], f0)
		var hx1 = lerp(a[0], b[0], f1)
		var hz1 = lerp(a[1], b[1], f1)
		var y1 = lerp(a[2], b[2], f1)
		_band([hx0, hz0, y0], [hx1, hz1, y0], seats, near)
		_band([hx1, hz1, y0], [hx1, hz1, y1], RISER, near)
	# Concourse wall up to the next tier (or a short cap on the open near side).
	var top = b[2] + 12.0
	if t + 1 < tiers.size():
		top = tiers[t + 1]["a"][2] - 6.0
	_band([b[0], b[1], b[2]], [b[0], b[1], top], CONCOURSE, near)
	if near and t + 1 < tiers.size():
		_nearCap(b)

# The lettering: white quads laid just on top of the lower tier's seat steps (tread and riser),
# placed by distance along each long side so every letter pixel is the same size.
func _textOverlay():
	var d = tiers[TEXT_TIER]
	var a = d["a"]
	var b = d["b"]
	var rows = d["rows"]
	var cols = TEXT.length() * 6 - 1
	var half = TEXT_HALF * ratio
	var colW = 2.0 * half / cols
	st = stMain
	for r in range(rows):
		var f0 = float(r) / rows
		var f1 = float(r + 1) / rows
		var prow = int(floor((TEXT_TOP - (f0 + f1) * 0.5) / ((TEXT_TOP - TEXT_BOTTOM) / 7.0)))
		if prow < 0 or prow > 6:
			continue
		var hx0 = lerp(a[0], b[0], f0)
		var hz0 = lerp(a[1], b[1], f0)
		var y0 = lerp(a[2], b[2], f0)
		var hx1 = lerp(a[0], b[0], f1)
		var hz1 = lerp(a[1], b[1], f1)
		var y1 = lerp(a[2], b[2], f1)
		for col in range(cols):
			if _pixel(col, prow) != 2:
				continue
			for side in [-1.0, 1.0]:
				# Far side (z < 0) reads left to right along +x; the near side is mirrored.
				var xa = - half + col * colW if side < 0 else half - (col + 1) * colW
				var xb = xa + colW
				var t0a = Vector3(xa, y0 + 0.15, side * _sideZ(hx0, hz0, xa))
				var t0b = Vector3(xb, y0 + 0.15, side * _sideZ(hx0, hz0, xb))
				var t1a = Vector3(xa, y0 + 0.15, side * _sideZ(hx1, hz1, xa) * 0.998)
				var t1b = Vector3(xb, y0 + 0.15, side * _sideZ(hx1, hz1, xb) * 0.998)
				_tri(t0a, t0b, t1b, SEAT_TEXT)
				_tri(t0a, t1b, t1a, SEAT_TEXT)
				var r1a = Vector3(xa, y1, t1a.z)
				var r1b = Vector3(xb, y1, t1b.z)
				_tri(t1a, t1b, r1b, SEAT_TEXT)
				_tri(t1a, r1b, r1a, SEAT_TEXT)

# The long side of a ring: z for a given x (the ring is |x/hx|^6 + |z/hz|^6 = 1).
func _sideZ(hx, hz, x):
	return hz * pow(max(0.0, 1.0 - pow(abs(x) / hx, CORNER_POWER)), 1.0 / CORNER_POWER)

func _pixel(col, row):
	if col % 6 == 5:
		return 1
	var glyph = FONT.get(TEXT[col / 6], FONT[" "])
	return 2 if glyph[row][col % 6] == "#" else 1

# 0 = away from the lettering, 1 = in its band but between letters, 2 = on a letter.
# p: point on the ring (x, z); hz: the ring's half width there; f: share of the tier's depth.
func _textAt(p, hz, f):
	if abs(p.y) < hz * 0.82:
		return 0
	var cols = TEXT.length() * 6 - 1
	var x = p.x if p.y < 0.0 else - p.x
	var col = int(floor((x + TEXT_HALF * ratio) / (2.0 * TEXT_HALF * ratio / cols)))
	var row = int(floor((TEXT_TOP - f) / ((TEXT_TOP - TEXT_BOTTOM) / 7.0)))
	if col < 0 or col >= cols or row < 0 or row > 6:
		return 0
	return _pixel(col, row)

func _nearCap(b):
	st = stMain
	for i in range(SEGMENTS):
		if not _skip(i, b[0], b[1], false):
			continue
		var a0 = _ring(b[0], b[1], i)
		var a1 = _ring(b[0], b[1], i + 1)
		_tri(Vector3(a0.x, b[2] + 12.0, a0.y), Vector3(a1.x, b[2] + 12.0, a1.y), Vector3(a1.x * 1.08, b[2] + 12.0, a1.y * 1.08), CONCOURSE)
		_tri(Vector3(a0.x, b[2] + 12.0, a0.y), Vector3(a1.x * 1.08, b[2] + 12.0, a1.y * 1.08), Vector3(a0.x * 1.08, b[2] + 12.0, a0.y * 1.08), CONCOURSE)

func _buildRoof():
	var c = tiers[2]["b"]
	_band([c[0], c[1], c[2]], [c[0] + 6.0, c[1] + 6.0, 170.0], roof, false)
	var edgeX = 232.0 * ratio
	var edgeZ = 162.0 * ratio
	if style == "bernabeu":
		# The roof reaches over the front rows.
		edgeX = 214.0 * ratio
		edgeZ = 144.0 * ratio
	_band([c[0] + 6.0, c[1] + 6.0, 170.0], [edgeX, edgeZ, 176.0], roof, false)
	_band([edgeX, edgeZ, 176.0], [edgeX, edgeZ, 169.0], roofEdge, false)
	if style == "bernabeu":
		# 360 video ring hanging under the roof edge.
		_band([edgeX, edgeZ, 169.0], [edgeX, edgeZ, 158.0], BERNABEU_SCREEN, false)

# Random crowd positions in world space. The away end sits behind the -x goal.
func seats(count, away, nearUpper = false):
	var out = []
	lastTifo = []
	var guard = 0
	while out.size() < count and guard < count * 40:
		guard += 1
		# By default most fans go in the lower tier, the part the sideline cameras actually see.
		var roll = randf()
		var u = randf()
		var v = randf()
		if evenSpread:
			haltonIndex += 1
			roll = _halton(haltonIndex, 5)
			u = _halton(haltonIndex, 2)
			v = _halton(haltonIndex, 3)
		var t = 0 if roll < tierWeights[0] else (1 if roll < tierWeights[0] + tierWeights[1] else 2)
		var d = tiers[t]
		var a = d["a"]
		var b = d["b"]
		var f = _evenDepth(t, v) if evenSpread else lerp(0.03, 0.97, v)
		var hx = lerp(a[0], b[0], f)
		var hz = lerp(a[1], b[1], f)
		var p = _ring(hx, hz, _evenAngle(t, u) if evenSpread else u * SEGMENTS)
		if (not d["near"] and _blocksView(p)) != nearUpper:
			continue
		var inAway = (p.x < - hx * 0.82)
		if inAway != away:
			continue
		out.append(Vector3(p.x, lerp(a[2], b[2], f) + 0.5, p.y))
		lastTifo.append(_textAt(p, hz, f) if paintText and t == TEXT_TIER else 0)
	return out

func _halton(i, base):
	var f = 1.0
	var r = 0.0
	while i > 0:
		f /= base
		r += f * (i % base)
		i = int(i / base)
	return r

# Ring position for a share u of the distance around tier t (the ring parameter alone bunches
# points into the corners).
func _evenAngle(t, u):
	var cum = _arcTable(t)
	var k = int(clamp(cum.bsearch(u), 1, ARC_SAMPLES))
	var lo = cum[k - 1]
	var hi = cum[k]
	var frac = (u - lo) / max(hi - lo, 0.000001)
	return (float(k - 1) + frac) * SEGMENTS / ARC_SAMPLES

func _arcTable(t):
	if arcTables.has(t):
		return arcTables[t]
	var a = tiers[t]["a"]
	var b = tiers[t]["b"]
	var hx = (a[0] + b[0]) * 0.5
	var hz = (a[1] + b[1]) * 0.5
	var cum = [0.0]
	var total = 0.0
	var prev = _ring(hx, hz, 0.0)
	for k in range(1, ARC_SAMPLES + 1):
		var q = _ring(hx, hz, float(k) * SEGMENTS / ARC_SAMPLES)
		total += prev.distance_to(q)
		cum.append(total)
		prev = q
	for k in range(cum.size()):
		cum[k] /= total
	arcTables[t] = cum
	return cum

# Depth into tier t for a share v of its seats: back rows are longer, so they get more fans.
func _evenDepth(t, v):
	var a = tiers[t]["a"]
	var b = tiers[t]["b"]
	var p0 = a[0] + a[1]
	var p1 = b[0] + b[1]
	var f = v
	if abs(p1 - p0) > 0.001:
		f = (- p0 + sqrt(p0 * p0 + (p1 * p1 - p0 * p0) * v)) / (p1 - p0)
	return lerp(0.03, 0.97, f)
