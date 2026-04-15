extends CharacterBody2D

const SPEED := 30.0
const SWITCH_DURATION = 0.15

@onready var up_raycast: RayCast2D = $UpRayCast
@onready var down_raycast: RayCast2D = $DownRayCast
@onready var track_layer: TileMapLayer = $"../TrackLayer"

var _switching_track := false

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
	var target_pos: Vector2
	
	# Jump to higher track
	if Input.is_action_just_pressed("up") and \
	is_on_floor() and up_raycast.is_colliding():
		target_pos = _get_track_position(
			up_raycast.get_collision_point())
		_switch_to_track(target_pos.y)
	
	# Drop to lower track
	if Input.is_action_just_pressed("down") and \
	is_on_floor() and down_raycast.is_colliding():
		target_pos = _get_track_position(
				down_raycast.get_collision_point())
		_switch_to_track(target_pos.y)

func _get_track_position(global_hit: Vector2) -> Vector2:
	# Get track position based on the cell
	var local_hit: Vector2 = track_layer.to_local(global_hit)
	var cell: Vector2 = track_layer.local_to_map(local_hit)
	var tile_pos: Vector2 = track_layer.map_to_local(cell)
	var global_pos: Vector2 = track_layer.to_global(tile_pos)
	var half_cart_height: float = $CollisionShape2D.shape.extents.y
	return global_pos - Vector2(0, half_cart_height + 0.8)

func _switch_to_track(target_y) -> void:
	_switching_track = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(
		self,
		"global_position:y",
		target_y,
		SWITCH_DURATION
	)
	
	# Return to normal physics on callback
	tween.tween_callback(func():
		_switching_track = false
	)
