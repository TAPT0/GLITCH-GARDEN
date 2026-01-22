extends Control
@onready var start_button = $Button
	

## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func _on_button_pressed():
	get_tree().change_scene_to_file("res://scenes/level.tscn")
	


func _on_button_mouse_entered():
	var t = create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(start_button, "scale",Vector2(1.1,1.1),0.1)
	t.tween_property(start_button,"modulate", Color(0.5,1,0.5),0.1)

func _on_button_mouse_exited():
	var t =create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(start_button,"scale",Vector2.ONE,0.1)
	t.tween_property(start_button,"modulate",Color.WHITE,0.1)
