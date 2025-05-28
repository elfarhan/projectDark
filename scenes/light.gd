extends RigidBody2D


var picked = true
var playerNode = Player

var player_node  # A reference to the player instance
func _ready():
	  # Adjust this path based on your actual scene tree
	
	self.position = playerNode.position
