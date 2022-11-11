extends Spatial

export var speed = 5.0
export var gravity = 9.8
export var jump_force = 5.0
export(NodePath) var head = null

# Not used in this script, but might be useful for child nodes because
# this controller will most likely be on the root
export(NodePath) var terrain_path = null

var _velocity = Vector3()
var _grounded = false
var _head = null
var _box_mover = VoxelBoxMover.new()
var _is_jumping = false
var _terrain: VoxelTerrain = null
var _terrain_tool = null


func _ready():
	_box_mover.set_collision_mask(1) # Excludes rails
	_head = get_node(head)
	_terrain = get_node(terrain_path)
	_terrain_tool = _terrain.get_voxel_tool()

func _physics_process(delta):
	var forward = _head.get_transform().basis.z.normalized()
	forward = Plane(Vector3(0, 1, 0), 0).project(forward)
	var right = _head.get_transform().basis.x.normalized()
	var motor = Vector3()
	
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W):
		motor -= forward
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		motor += forward
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A):
		motor -= right
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		motor += right
	
	motor = motor.normalized() * speed
	
	_velocity.x = motor.x
	_velocity.z = motor.z
	_velocity.y -= gravity * delta
	
	if _grounded and Input.is_key_pressed(KEY_SPACE):
		_is_jumping = true
		_velocity.y = jump_force
		_grounded = false
	
	var motion = _velocity * delta
	
	if has_node(terrain_path):
		var aabb = AABB(Vector3(-0.4, -0.9, -0.4), Vector3(0.8, 1.8, 0.8))
		var terrain_node = get_node(terrain_path)
		var prev_motion = motion
		motion = _box_mover.get_motion(translation, motion, aabb, terrain_node)
		if abs(motion.y) < 0.001 and prev_motion.y < -0.001:
			_grounded = true
		if abs(motion.y) > 0.001:
			_grounded = false
		
		global_translation += motion
		#global_translate(motion)

	assert(delta > 0)
	_velocity = motion / delta


func _get_pointed_voxel():
	var origin = get_global_transform().origin
	var forward = -get_transform().basis.y.normalized()
	var hit = _terrain_tool.raycast(origin, forward, 2, 2)
	return hit


func _on_Timer_timeout():
	var hit = _get_pointed_voxel()
	var pos = null
	if hit:
		pos = hit.position
		print(pos)
		#print(_terrain_tool.get_voxel(pos))
		#print(global_translation.y < -43.8)
		if global_translation.y < -43.8 and _terrain_tool.get_voxel(pos):
			$Camera/wate.show()
			gravity = .25
			speed = 4
			jump_force = 3
			_grounded = true
#		if _terrain_tool.get_voxel(pos):
#			$Camera/wate.hide()
#			gravity = 40
#			speed = 6
#			jump_force = 10
		else:
			gravity = 40
			speed = 6
			jump_force = 13
			$Camera/wate.hide()
