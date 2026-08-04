extends Node

signal rotation_changed(value: float)
signal active_index_changed(index: int)
signal snap_completed(index: int)

var item_count := 1
var angle_step := TAU
var rotation := 0.0
var velocity := 0.0
var active_index := 0

var _idle_time := 0.0
var _snapping := false
var _snap_target := 0.0

const MAX_VELOCITY := 5.4
const WHEEL_IMPULSE := 3.1
const FRICTION := 6.2
const SNAP_DELAY := 0.16
const SNAP_SPEED := 11.5

func configure(count: int) -> void:
	item_count = maxi(count, 1)
	angle_step = TAU / float(item_count)
	active_index = 0
	set_process(true)

func set_index_immediate(index: int) -> void:
	active_index = wrapi(index, 0, item_count)
	rotation = -float(active_index) * angle_step
	_snap_target = rotation
	velocity = 0.0
	_idle_time = 0.0
	_snapping = false
	rotation_changed.emit(rotation)

func push_wheel(direction: float) -> void:
	velocity = clampf(velocity - direction * WHEEL_IMPULSE, -MAX_VELOCITY, MAX_VELOCITY)
	_idle_time = 0.0
	_snapping = false

func step_by(offset: int) -> void:
	snap_to_index(wrapi(active_index + offset, 0, item_count))

func snap_to_index(index: int) -> void:
	var wanted := -float(wrapi(index, 0, item_count)) * angle_step
	_snap_target = _nearest_equivalent(wanted, rotation)
	velocity = 0.0
	_idle_time = 0.0
	_snapping = true

func _process(delta: float) -> void:
	if _snapping:
		var blend := 1.0 - exp(-SNAP_SPEED * delta)
		rotation = lerpf(rotation, _snap_target, blend)
		if absf(rotation - _snap_target) < 0.0008:
			rotation = _snap_target
			_snapping = false
			_update_active_index()
			snap_completed.emit(active_index)
	else:
		rotation += velocity * delta
		velocity *= exp(-FRICTION * delta)
		_idle_time += delta
		if absf(velocity) < 0.045 and _idle_time >= SNAP_DELAY:
			_snap_target = roundf(rotation / angle_step) * angle_step
			velocity = 0.0
			_snapping = true

	_update_active_index()
	rotation_changed.emit(rotation)

func _update_active_index() -> void:
	var nearest := wrapi(int(roundf(-rotation / angle_step)), 0, item_count)
	if nearest == active_index:
		return
	active_index = nearest
	active_index_changed.emit(active_index)

func _nearest_equivalent(target: float, reference: float) -> float:
	while target - reference > PI:
		target -= TAU
	while target - reference < -PI:
		target += TAU
	return target
