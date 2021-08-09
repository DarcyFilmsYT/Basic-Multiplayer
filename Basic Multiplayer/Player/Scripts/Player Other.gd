extends KinematicBody

var new_position

func _physics_process(_delta):
	self.global_transform.origin = new_position
