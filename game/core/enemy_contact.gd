class_name EnemyContact
extends RefCounted
## Was that a stomp or a touch? The one rule that decides whether the blob earns or pays.
##
## Pure logic, unit-tested in tests/unit/core/test_enemy_contact.gd. Godot's y axis points
## DOWN: the blob's feet are its bottom edge, and falling is a positive vertical velocity.

## Extra slack (pixels) on top of the one-frame rewind below.
const STOMP_TOLERANCE: float = 4.0


## A stomp is the blob FALLING (velocity y > 0) onto the enemy from above. The physics server
## reports an overlap a frame late — measured: 4 px of sinking at 163 px/s, and up to ~7 px at
## the fall cap — so the feet are rewound by one frame of travel (`delta` is the physics step)
## before comparing with the enemy's top edge. Walking into the side (no vertical speed, feet
## well below the top), rising past it, or standing next to it is a touch.
static func is_stomp(
	blob_feet_y: float, blob_velocity_y: float, enemy_top_y: float, delta: float
) -> bool:
	if blob_velocity_y <= 0.0:
		return false
	var feet_a_frame_ago := blob_feet_y - blob_velocity_y * delta
	return feet_a_frame_ago <= enemy_top_y + STOMP_TOLERANCE
