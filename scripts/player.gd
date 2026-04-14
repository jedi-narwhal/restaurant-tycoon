extends CharacterBody2D

const SPEED := 50.0
const SWITCH_DURATION = 0.15

@onready var up_raycastL: RayCast2D = $UpRayCastL
@onready var up_raycastR: RayCast2D = $UpRayCastR
@onready var down_raycastL: RayCast2D = $DownRayCastL
@onready var down_raycastR: RayCast2D = $DownRayCastR
@onready var track_layer = $"../TrackLayer"

var _switching_track := false
var target_pos: Vector2

func _ready() -> void:
	$AnimatedSprite2D.play("rolling")
	velocity.x = SPEED

func _physics_process(delta: float) -> void:
	# Ignore physics if currently tweening
	if _switching_track:
		position.x += SPEED * delta
		velocity.y = 0.0
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	_handle_jumps()
	move_and_slide()

func _handle_jumps() -> void:
	# Jump to higher track
	if Input.is_action_just_pressed("up") and is_on_floor():
		if up_raycastL.is_colliding():
			target_pos = _get_track_position(
				up_raycastL.get_collision_point())
		elif up_raycastR.is_colliding():
			target_pos = _get_track_position(
				up_raycastR.get_collision_point())
		_switch_to_track(target_pos.y)
	
	# Drop to lower track
	if Input.is_action_just_pressed("down") and is_on_floor():
		if down_raycastL.is_colliding():
			target_pos = _get_track_position(
				down_raycastL.get_collision_point())
		elif down_raycastR.is_colliding():
			target_pos = _get_track_position(
				down_raycastR.get_collision_point())
		_switch_to_track(target_pos.y)

func _get_track_position(global_hit: Vector2) -> Vector2:
	var local_hit: Vector2 = track_layer.to_local(global_hit)
	var cell: Vector2 = track_layer.local_to_map(local_hit)
	var tile_pos: Vector2 = track_layer.map_to_local(cell)
	return tile_pos

func _switch_to_track(target_y) -> void:
	_switching_track = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(
		self,
		"position:y",
		target_y, 
		SWITCH_DURATION
	)
	
	# Return to normal physics on callback
	tween.tween_callback(func():
		_switching_track = false
	)
