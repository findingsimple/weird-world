class_name Strawberry
extends CharacterBody2D
## A ghost strawberry: the goomba. Walks back and forth, turning at walls and ledges. Land on
## it from above and it is squished; walk into it and the blob pays a fine.
##
## The walking maths is [PlatformerMotion] (it never jumps), the turning is [Patrol], and the
## stomp-or-touch call is [EnemyContact], so all three are unit-tested; this node only senses
## and moves. It emits signals up to [Level], which decides what money changes hands.

## The blob landed on this strawberry. It squishes itself right after.
signal stomped(strawberry: Strawberry)
## The blob walked into this strawberry.
signal blob_touched(strawberry: Strawberry)

## Walking speed in pixels per second.
@export_range(0.0, 300.0, 1.0) var speed: float = 40.0
## Which way it walks first.
@export_enum("Left:-1", "Right:1") var start_direction: int = -1
## Same gravity as the blob, so they fall alike.
@export_range(1.0, 3000.0, 1.0) var gravity: float = 980.0
@export_range(1.0, 2000.0, 1.0) var max_fall_speed: float = 400.0

var _patrol: Patrol
var _motion: PlatformerMotion

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collider: CollisionShape2D = $CollisionShape2D
@onready var _ledge_ray: RayCast2D = $LedgeRay
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	_patrol = Patrol.new(start_direction)
	_motion = PlatformerMotion.new(speed, 0.0, gravity, max_fall_speed)
	_hitbox.body_entered.connect(_on_hitbox_body_entered)


func _physics_process(delta: float) -> void:
	if is_on_floor():
		# The ray may have just moved to the other side; its cached hit is from the old spot,
		# so re-cast before reading it.
		_ledge_ray.position.x = absf(_ledge_ray.position.x) * _patrol.direction
		_ledge_ray.force_raycast_update()
		_patrol.step(is_on_wall(), _ledge_ray.is_colliding())
	_sprite.flip_h = _patrol.direction > 0
	velocity = _motion.next_velocity(velocity, _patrol.direction, false, is_on_floor(), delta)
	move_and_slide()


## Which way it is walking right now: -1 left, 1 right.
func get_direction() -> int:
	return _patrol.direction


## The y of this strawberry's top edge, in global coordinates.
func top_y() -> float:
	var box := _collider.shape as RectangleShape2D
	if box == null:
		push_error("Strawberry's collider is not a RectangleShape2D; using its centre as the top")
		return _collider.global_position.y
	return _collider.global_position.y - box.size.y * 0.5


func _on_hitbox_body_entered(body: Node2D) -> void:
	var blob := body as Player
	if blob == null:
		return
	var delta := get_physics_process_delta_time()
	if EnemyContact.is_stomp(blob.feet_y(), blob.velocity.y, top_y(), delta):
		blob.bounce()
		stomped.emit(self)
		queue_free()
	else:
		blob_touched.emit(self)
