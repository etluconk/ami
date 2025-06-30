extends CharacterBody2D

@export var idle_voice_lines : Array[Resource]
@export var wandering_voice_lines : Array[Resource]
@export var pondering_voice_lines : Array[Resource]
@export var chance_of_new_sound_on_state_change := 1.0

@export var idle_texture : Resource
@export var walk_texture_1 : Resource
@export var walk_texture_2 : Resource
@export var walk_texture_3 : Resource

@export var run_speed := 300.0

@onready var walking_loop = $WalkingLoopTimer
@onready var sprite = $SpriteContainer/Sprite2D

enum {STATE_IDLE, STATE_PONDERING, STATE_WANDERING}
var state := STATE_IDLE

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	if $AnimationPlayer.current_animation == "run":
		if walking_loop.time_left > walking_loop.wait_time * 0.6:
			sprite.texture = walk_texture_1
		elif walking_loop.time_left > walking_loop.wait_time * 0.3:
			sprite.texture = walk_texture_2
		elif walking_loop.time_left >= 0:
			sprite.texture = walk_texture_3
	else:
		sprite.texture = idle_texture

	update()
	move_and_slide()

func update() -> void:
	match state:
		STATE_IDLE:
			$AnimationPlayer.play("idle")
			velocity.x = 0
		STATE_WANDERING:
			$AnimationPlayer.play("run")
			if !is_falling_off_edge(get_direction_facing_sign()):
				velocity.x = get_direction_facing_sign() * run_speed
			else:
				velocity.x = 0
		STATE_PONDERING:
			$AnimationPlayer.play("breathing")
			velocity.x = 0

	$TalkingIndicator.visible = $VoiceLineSound.playing

func _on_rand_state_change_timer_timeout() -> void:

	var will_play_new_sound := randf_range(0, 1) <= chance_of_new_sound_on_state_change

	match randi_range(1, 3):
		1:
			state = STATE_IDLE
			if idle_voice_lines.size() > 0 and will_play_new_sound:
				$VoiceLineSound.stream = idle_voice_lines[randi_range(0, idle_voice_lines.size() - 1)]
		2:
			state = STATE_PONDERING
			if pondering_voice_lines.size() > 0 and will_play_new_sound:
				$VoiceLineSound.stream = pondering_voice_lines[randi_range(0, pondering_voice_lines.size() - 1)]
		3:
			state = STATE_WANDERING
			sprite.flip_h = (randi_range(0, 1) == 1)
			if wandering_voice_lines.size() > 0 and will_play_new_sound:
				$VoiceLineSound.stream = wandering_voice_lines[randi_range(0, wandering_voice_lines.size() - 1)]

	if will_play_new_sound: $VoiceLineSound.play()

	$RandStateChangeTimer.wait_time = randf_range(0.1, 3)
	$RandStateChangeTimer.start()

func get_direction_facing_sign() -> int:
	if sprite.flip_h:
		return -1
	else:
		return 1

func is_falling_off_edge(dir : int) -> bool:
	if (!$LeftGroundDetector.is_colliding() and dir == -1) \
	or (!$RightGroundDetector.is_colliding() and dir == 1):
		return true
	else:
		return false
