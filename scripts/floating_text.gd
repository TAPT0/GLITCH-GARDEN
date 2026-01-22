extends Label

func start_float(text_content:String,color:Color):
	text = text_content
	modulate = color
	
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(self,"position:y", position.y - 100, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	t.tween_property(self,"modulate:a",0.0,1.5).set_ease(Tween.EASE_IN)
	
	await t.finished
	queue_free()
# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
