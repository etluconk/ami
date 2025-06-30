extends CharacterBody2D

@export var bonk_velocity := 400.0
@export var slide_x_velocity := 1000.0
@export var slide_y_velocity := 700.0
@export var slide_jump_velocity := 3000.0
@export var time_travel_frames := 30
@export var zorp_offset := 200.0

var sliding := false
var air_sliding := false
var slide_dir := 1

var can_zorp := false

var slide_mult := 1.0
@export var slide_mult_rate := 0.1

var cam_rotation_sign := 1

# Trackers

var prev_pos = []

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	handle_anim()
	handle_sliding()
	# handle_zorp()

	move_and_slide()
	handle_slide_mult()

	handle_camera()

func handle_camera() -> void:
	var zoom = lerpf($Camera2D.zoom.x, 1.3 - slide_mult * 0.35, 0.05)
	$Camera2D.zoom.x = zoom
	$Camera2D.zoom.y = zoom

func handle_zorp() -> void:
	if is_on_floor():
		can_zorp = true

	if can_zorp and Input.is_action_just_pressed("zorp"):
		zorp()

func zorp() -> void:
	can_zorp = false
	position.y -= zorp_offset
	$ZorpSound.stream = load("res://assets/audio/ami/zorp/" + str(randi_range(1, 8)) + ".wav")
	$ZorpSound.play()
	$ZorpSprite.show()
	$ZorpTimer.start()

func _on_zorp_timer_timeout() -> void:
	$ZorpSprite.hide()

func handle_slide_mult() -> void:
	$HUD/SlideJumpMultRange.value = slide_mult
	$HUD/SlideTimerRange.value = $SlideTimer.time_left / $SlideTimer.wait_time

	if (is_on_floor() and !sliding) or is_on_wall():
		slide_mult = 1
	if is_on_wall():
		sliding = false
		velocity.x = get_wall_normal().x * bonk_velocity
		velocity.y = max(-500, velocity.y)
		$BonkSound.play()
		$AnimationPlayer.play("bonk")

func handle_sliding() -> void:
	if Input.is_action_just_pressed("slide") and !sliding:
		if is_on_floor():
			if $SlideCooldownTimer.is_stopped():
				slide()
		else:
			slide()

	if sliding:
		velocity.x = slide_x_velocity * slide_dir
		if air_sliding:
			velocity.y = slide_y_velocity
			if is_on_floor():
				air_sliding = false
			$AnimationPlayer.play("down air")
		else:
			$AnimationPlayer.play("slide")

func slide() -> void:
	$SlideSound.stream = load("res://assets/audio/ami/slide/" + str(randi_range(1, 15)) + ".wav")
	$SlideSound.play()
	$SlideSound/AnimationPlayer.stop()
	$SlideSound/AnimationPlayer.play("pan")
	$WhooshSound.play()

	slide_dir = get_forward_direction_sign()
	sliding = true
	$SlideTimer.start()

	air_sliding = !is_on_floor()

func _on_slide_timer_timeout() -> void:
	sliding = false
	$SlideCooldownTimer.start()

func handle_anim() -> void:
	if get_input_direction():
		$Sprite2D.flip_h = (velocity.x < 0)
	$Toe1.rotation += velocity.x / (360 * 4)
	$Toe2.rotation -= velocity.x / (360 * 4)

	if is_on_floor() and !sliding:
		$AnimationPlayer.play("idle")

func _on_jumped() -> void:
	$AnimationPlayer.play("jump")
	$JumpSound.stream = load("res://assets/audio/ami/jump/" + str(randi_range(1, 17)) + ".wav")
	$JumpSound.play()
	$SlideCooldownTimer.stop()

	if sliding:
		sliding = false
		$SlideSound.stop()
		velocity.x = slide_jump_velocity * get_forward_direction_sign() * slide_mult

		slide_mult += slide_mult_rate
		slide_mult = min(2, slide_mult)

func _on_rotation_switch_timer_timeout() -> void:
	cam_rotation_sign *= -1
	$RotationSwitchTimer.wait_time = randf_range(0.1, 3)
	$RotationSwitchTimer.start()

# Getters!!!

func get_direction_facing_sign() -> int:
	if $Sprite2D.flip_h:
		return -1
	else:
		return 1

func get_forward_direction_sign() -> int:
	if Input.is_action_pressed("move_left") == Input.is_action_pressed("move_right"):
		return get_direction_facing_sign()

	if Input.is_action_pressed("move_left"):
		return -1
	elif Input.is_action_pressed("move_right"):
		return 1

	return get_direction_facing_sign()

func get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right")
