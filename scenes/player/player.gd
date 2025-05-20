extends CharacterBody2D

@export_group("Movement")
@export var max_speed = 400
@export var acceleration = 6
@export var jump_speed = 6

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("default")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity.y += 900.081 * delta
	move_and_slide()
