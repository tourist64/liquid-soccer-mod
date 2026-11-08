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
var st
var stMain
var stNear
var nearMesh
var nearCrowd = null
var nearShown = false

func _ready():
	# The bowl is sized for the design pitch scale; keep it the same distance from a smaller pitch.
	ratio = Global.ps / Global.ELEVEN_DESIGN_SCALE
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
	_band([a[0], a[1], a[2] - 6.0], [a[0], a[1], a[2]], FASCIA, near)
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
	_band([c[0], c[1], c[2]], [c[0] + 6.0, c[1] + 6.0, 170.0], ROOF, false)
	var edgeX = 232.0 * ratio
	var edgeZ = 162.0 * ratio
	_band([c[0] + 6.0, c[1] + 6.0, 170.0], [edgeX, edgeZ, 176.0], ROOF, false)
	_band([edgeX, edgeZ, 176.0], [edgeX, edgeZ, 169.0], ROOF_EDGE, false)

# Random crowd positions in world space. The away end sits behind the -x goal.
func seats(count, away, nearUpper = false):
	var out = []
	var guard = 0
	while out.size() < count and guard < count * 40:
		guard += 1
		# Most fans go in the lower tier, the part the sideline cameras actually see.
		var roll = randf()
		var t = 0 if roll < 0.62 else (1 if roll < 0.85 else 2)
		var d = tiers[t]
		var a = d["a"]
		var b = d["b"]
		var f = rand_range(0.03, 0.97)
		var hx = lerp(a[0], b[0], f)
		var hz = lerp(a[1], b[1], f)
		var p = _ring(hx, hz, rand_range(0.0, SEGMENTS))
		if (not d["near"] and _blocksView(p)) != nearUpper:
			continue
		var inAway = (p.x < - hx * 0.82)
		if inAway != away:
			continue
		out.append(Vector3(p.x, lerp(a[2], b[2], f) + 0.5, p.y))
	return out
