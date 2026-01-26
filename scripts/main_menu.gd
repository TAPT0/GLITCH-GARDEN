extends Label

#label float upward then deletes itself
func start_float(text_content: String, color: Color) -> void:

	text = text_content
	modulate = color

	#tween to animate movement and fade at the same time
	var tween := create_tween()
	tween.set_parallel(true)

	#move the label up 
	tween.tween_property(
		self,
		"position:y",
		position.y - 100,
		1.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		1.5
	).set_ease(Tween.EASE_IN)

	#after animation finishes then delete this label
	await tween.finished
	queue_free()
