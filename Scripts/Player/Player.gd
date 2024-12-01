class_name Player
extends CharacterBody3D

# Constants.
const CROUCH_DEPTH = -0.5
const JUMP_VELOCITY = 3.0
const SENSITIVITY = 0.001

# Variables.
var health = 100
var level = 0

var mouse_input : Vector2
var def_weapon_holder_pos : Vector3

# Camera variables.
@export var camera_speed : float = 5
@export var camera_rotation_amount : float = 1
@export var weapon_sway_amount : float = 5
@export var weapon_rotation_amount : float = 1
@export var invert_weapon_sway : bool = false

# Speed variables.
var walk_speed = 3.0
var sprint_speed = 5.5
var crouch_speed = 2.5
var speed = walk_speed
var current_speed
var lerp_speed = 10.0

# Player states.
var walking = false
var sprinting = false
var crouching = false

# FOV variables.
const BASE_FOV = 90.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
# 9.8 is the default value
var gravity = 15.0

# Main function.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	def_weapon_holder_pos = %WeaponHolder.position


# Handle Camera Movement.
func _input(event):
	if !%Head: return
	if event is InputEventMouseMotion:
		%Head.rotation.x -= event.relative.y * camera_speed
		%Head.rotation.x = clamp(%Head.rotation.x, -1.25, 1.5)
		self.rotation.y -= event.relative.x * camera_speed
		mouse_input = event.relative


func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("MoveLeft", "MoveRight", "MoveForward", "MoveBackward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle Sprint.
	if Input.is_action_pressed("Sprint"):
		speed = sprint_speed
	else:
		speed = walk_speed

	# Handle Crouch.
	if Input.is_action_pressed("Crouch"):
		speed = crouch_speed
		
		%Head.position.y = lerp(%Head.position.y, CROUCH_DEPTH, delta * lerp_speed)
		%StandingCollisionShape.disabled = true
		%CrouchingCollisionShape.disabled = false
		
	elif !%RayCast3D.is_colliding():
		%Head.position.y = lerp(%Head.position.y, 0.0, delta * speed)
		%StandingCollisionShape.disabled = false
		%CrouchingCollisionShape.disabled = true
		
	elif %RayCast3D.is_colliding():
		speed = crouch_speed

	# Handle Attack.
	if Input.is_action_just_pressed("Attack"):
		pass

	# Handle Camera Zoom.
	if Input.is_action_pressed("Zoom"):
		#var target_fov_zoom = 0.0
		#%Camera3D.fov = lerp(%Camera3D.fov, target_fov_zoom, delta * 8.0)
		# speed = speed / 1.5
		pass

	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, sprint_speed * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	%Camera3D.fov = lerp(%Camera3D.fov, target_fov, delta * 8.0)
	
	# Start physics process.
	move_and_slide()
	cam_tilt(input_dir.x, delta)
	weapon_tilt(input_dir.x, delta)
	weapon_sway(delta)
	weapon_bob(velocity.length(), delta)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack_greatsword":
		%AnimationPlayer.play("idle")


func cam_tilt(input_x, delta):
	if %Camera3D:
		%Camera3D.rotation.z = lerp(%Camera3D.rotation.z, -input_x * camera_rotation_amount, 10 * delta)


func weapon_tilt(input_x, delta):
	if %WeaponHolder:
		%WeaponHolder.rotation.z = lerp(%WeaponHolder.rotation.z, -input_x * weapon_rotation_amount * 10, 10 * delta)


func weapon_sway(delta):
	mouse_input = lerp(mouse_input,Vector2.ZERO,10*delta)
	%WeaponHolder.rotation.x = lerp(%WeaponHolder.rotation.x, mouse_input.y * weapon_rotation_amount * (-1 if invert_weapon_sway else 1), 10 * delta)
	%WeaponHolder.rotation.y = lerp(%WeaponHolder.rotation.y, mouse_input.x * weapon_rotation_amount * (-1 if invert_weapon_sway else 1), 10 * delta)


func weapon_bob(vel : float, delta):
	if %WeaponHolder:
		if vel > 0 and is_on_floor():
			var bob_amount : float = 0.05
			var bob_freq : float = 0.01
			%WeaponHolder.position.y = lerp(%WeaponHolder.position.y, def_weapon_holder_pos.y + sin(Time.get_ticks_msec() * bob_freq) * bob_amount, 10 * delta)
			%WeaponHolder.position.x = lerp(%WeaponHolder.position.x, def_weapon_holder_pos.x + sin(Time.get_ticks_msec() * bob_freq * 0.5) * bob_amount, 10 * delta)
			
		else:
			%WeaponHolder.position.y = lerp(%WeaponHolder.position.y, def_weapon_holder_pos.y, 10 * delta)
			%WeaponHolder.position.x = lerp(%WeaponHolder.position.x, def_weapon_holder_pos.x, 10 * delta)
