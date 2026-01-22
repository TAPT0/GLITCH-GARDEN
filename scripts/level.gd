extends Node2D

func _on_button_pressed():
	#plantsprite node bigger
	$PlantSprite.scale = Vector2(1.5, 1.5)
	print("Plant watered! Now bigger.")
