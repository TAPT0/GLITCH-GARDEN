extends Node2D

enum PlantStage{
	SEED,
	SPROUT,
	HEALTHY,
	BLOOM
}
var growth_stage: PlantStage = PlantStage.SEED
enum DayCondition {
	NORMAL, 
	CLOUDY, 
	RAINY,
	HEATWAVE
	}
var anim_scale:= Vector2.ONE
var biomass: int = 0
var growth:float=0.0
var water_power: int = 25
var upgrade_cost: int =50
var shake_strength:float =0.0
var current_condition: DayCondition
var day := 1
var level := 1
var light := 50.0
var health := 100.0
var BASE_SCALE := Vector2(8,8)
var LIGHT_DRAIN_RATE := 5.0
var  HEALTH_DRAIN_RATE := 3.0

var day_duration : float = 20.0
var time_left: float = day_duration

var stage_days_required := {
	PlantStage.SEED: 0,
	PlantStage.SPROUT: 2,
	PlantStage.HEALTHY: 4,
	PlantStage.BLOOM: 6
}
@onready var floating_text_scene = preload("res://scenes/floating_text.tscn")
@onready var level_complete_panel = $CanvasLayer/LevelCompletePanel
@onready var level_complete_label = $CanvasLayer/LevelCompletePanel/VBoxContainer/TitleLabel
@onready var game_over_panel = $CanvasLayer/GameOverPanel
@onready var ui_layout = $CanvasLayer/UILayout
@onready var water_sound: AudioStreamPlayer = $WaterSound
@onready var day_label = $CanvasLayer/UILayout/HUD/HUDPanel/HUDContent/DayLabel
@onready var weather_label = $CanvasLayer/UILayout/HUD/HUDPanel/HUDContent/WeatherLabel
@onready var stage_label = $CanvasLayer/UILayout/HUD/HUDPanel/HUDContent/StageLabel
@onready var water_particles: CPUParticles2D = $CanvasLayer/UILayout/ControlsPanel/VBoxContainer/WaterButton/WaterParticles
@onready var background_rect = $BackgroundRect
@onready var plant_sprite: Sprite2D = $PlantPivot/PlantSprite
@onready var camera =$Camera
@onready var light_bar: ProgressBar = $CanvasLayer/UILayout/StatusPanel/VBoxContainer/LightBar
var is_game_active := true
var water = 20
var WATER_DRAIN_RATE := 10.0

func _ready():
	$PlantPivot/PlantSprite.region_enabled = true
	$PlantPivot/PlantSprite.region_rect = Rect2(0,0,16,16)
	#$PlantPivot.position = Vector2(576, 324)
	#$PlantPivot/PlantSprite.position = Vector2(0,0)
	$CanvasLayer/UILayout/StatusPanel/VBoxContainer/WaterBar.min_value = 0
	$CanvasLayer/UILayout/StatusPanel/VBoxContainer/WaterBar.max_value = 100 
	update_water_bar()
	update_plant_visual()
	
	light_bar.min_value = 0
	light_bar.max_value = 100
	light_bar.value = light
	update_weather_visuals()
func update_water_bar():
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($CanvasLayer/UILayout/StatusPanel/VBoxContainer/WaterBar,"value",water,0.25)
	update_water_text()
	
func update_water_text():
	if has_node("CanvasLayer/UILayout/StatusPanel/VBoxContainer/WaterBar/Label"):
		var label_node = $CanvasLayer/UILayout/StatusPanel/VBoxContainer/WaterBar/Label
		label_node.text  = "%.1f/100" % water

func _on_button_pressed():
	if not is_game_active:
		return
		
	var amount_to_add = water_power
		
	if water >= 100:
		print("Water is already full, but growing plant!!")
		growth = clamp(growth +5,0,100)
		return
		
	water = clamp(water + amount_to_add, 0,100)
	light = clamp(light - 5,0,100)
	
	
	growth = clamp(growth+10,0,100)
	print("Plant grew! Current Size:",growth)
	
	update_water_bar()
	update_plant_visual()
	
	water_sound.pitch_scale = randf_range(0.95,1.05)
	water_sound.volume_db = randf_range(-8,-6)
	water_sound.play()
	water_particles.restart()
	anim_scale = Vector2(1.2,0.8)
	var t := create_tween()
	t.tween_property($PlantPivot, "scale", BASE_SCALE * 1.5,0.08)
	t.tween_property($PlantPivot,"scale",BASE_SCALE,0.12)
	
	if growth >=100:
		spawn_floating_text("HARVEST READY!",Color.GOLD)
		
		check_win_condition()
func _process(delta):
	if not is_game_active:
		return
	
	var time = Time.get_ticks_msec()/1000.0
	$PlantPivot.rotation =sin(time*2.0)*0.05
	
	anim_scale = lerp(anim_scale,Vector2.ONE,delta*10.0)
		
	update_plant_visual()
	check_win_condition()
	light = max(light - LIGHT_DRAIN_RATE * delta, 0)
	light_bar.value = light
	time_left -= delta
	
	if time_left <=0:
		end_day()
		return
		
	if water > 0 :
		water = max(water - WATER_DRAIN_RATE * delta , 0)
		update_water_bar()
		
	if water<=0 or light <=0:
		print("Resource depleted! GAME OVER.")
		game_over()
		return
		
	if water < 20 or light < 20:
		health = max(health - HEALTH_DRAIN_RATE * delta,0)
		
		var pulse=(sin(Time.get_ticks_msec()*0.01)+1.0)*0.5
		plant_sprite.modulate = Color(1.0,0.5+(0.5*pulse),0.5+(0.5*pulse))
		plant_sprite.scale = Vector2(0.96,0.95)
	else:
		plant_sprite.modulate = Color(1,1,1)
		
	if health <= 0:
		print("GAME OVER TRIGGERED")
		game_over()
		
	if shake_strength > 0:
		shake_strength = lerp(shake_strength,0.0,5.0*delta)
		camera.offset = Vector2(
			randf_range(-shake_strength,shake_strength),
			randf_range(-shake_strength,shake_strength)
		)
		
func  trigger_glitch():
	shake_strength = 10.0
	var t = create_tween()
	modulate = Color(2,0,2)
	t.tween_property(self,"modulate",Color.WHITE,0.1)
func on_plant_died():
	is_game_active = false
	game_over_panel.visible = true
		
	if health <= 0:
		is_game_active = false
		
func update_plant_visual():
	var sprite_size=16
	var frame_index= 0
	
	if growth <20:
		frame_index =1
	elif growth <40:
		frame_index = 2
	elif growth <60:
		frame_index=3
	elif growth <60:
		frame_index = 4
	else:
		frame_index = 5
		
	var curr_rect= Rect2(frame_index*sprite_size,0,16,16)
	$PlantPivot/PlantSprite.region_rect = curr_rect
	
	var scale_amount=1.0
	$PlantPivot/PlantSprite.scale=Vector2(scale_amount,scale_amount)* anim_scale
func end_day():
	
	current_condition = DayCondition.values().pick_random()
	
	print("Day" , day, "complete!")
	print("Drain rate BEFORE :", WATER_DRAIN_RATE)
	
	WATER_DRAIN_RATE += 2.0
	
	print("Drain rate AFTER:", WATER_DRAIN_RATE)
	
	day += 1
	
	time_left = day_duration
	
	water = clamp(water + 15, 0, 100)
	update_water_bar()
	update_plant_visual()
	
	roll_day_condition()

	day_label.text = "Day %d - %s" % [
		day,
		DayCondition.keys()[current_condition]
	]
	print("Starting Day", day)
	

	
	roll_random_event()
	
	var daily_income = 20 +(day*10)
	biomass += daily_income
	print("Biomass Earned:", daily_income,"Total:",biomass)
	
	spawn_floating_text("+$%d BIOMASS" % daily_income, Color.GOLD)
func _on_light_button_pressed():
	if not is_game_active:
		return
	light = clamp(light + 15, 0, 100)
	water = clamp(water - 5, 0 , 100)
	update_water_bar()
	update_plant_visual()
	light_bar.value = light

func roll_day_condition():
	current_condition = DayCondition.values().pick_random()
	
	match current_condition:
		DayCondition.NORMAL:
			LIGHT_DRAIN_RATE = 5.0
			WATER_DRAIN_RATE = 6.0
			print("Normal Day")
	
		DayCondition.CLOUDY:
			LIGHT_DRAIN_RATE = 8.0
			WATER_DRAIN_RATE = 6.0
			print(" Cloudy Day – Light drains faster")
	
		DayCondition.RAINY:
			LIGHT_DRAIN_RATE = 4.0
			WATER_DRAIN_RATE = 3.0
			print("Rainy Day – Water drains slower")
		
		DayCondition.HEATWAVE:
			LIGHT_DRAIN_RATE = 9.0
			WATER_DRAIN_RATE = 9.0
			print("Heatwave – Everything drains fast")
			
			weather_label.text = "Weather: %s" % DayCondition.keys()[current_condition]
			
			update_weather_visuals()
			
			check_win_condition()
func update_weather_visuals():
	var target_color = Color.WHITE
	match current_condition:
		DayCondition.NORMAL:
			target_color = Color("3a3a3a")
		DayCondition.CLOUDY:
			target_color = Color("5e6872")
		DayCondition.RAINY:
			target_color = Color("214035")
		DayCondition.HEATWAVE:
			target_color = Color("5e2f2f")
	var t = create_tween()
	t.tween_property(background_rect, "color", target_color,1.5)
	

func _on_retry_button_pressed():
	game_over_panel.visible = false
	reset_day()

func reset_day():
	is_game_active = true
	water = 50
	light = 50
	time_left = day_duration
	update_water_bar()
	update_plant_visual()
	shake_strength = 0.0
	if camera:
		camera.offset = Vector2.ZERO

func restart_game():
	is_game_active = true
	
	day = 1
	water = 50.0
	light = 50.0
	growth_stage = PlantStage.SEED
	
	update_water_bar()
	light_bar.value = light
	update_plant_visual()
	
	shake_strength = 0.0
	if camera:
		camera.offset = Vector2.ZERO
	
	
	$CanvasLayer/GameOverPanel.visible = false
	ui_layout.visible = true
	print("Game Restarted")
	
func game_over():
	is_game_active = false
	$CanvasLayer/GameOverPanel.visible = true
	game_over_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.4)
	
func roll_random_event():
	var roll = randi() %100
	print("Rolled a event number:",roll)
	if roll < 25:
		print("Pests attacked! Water lost")
		water = max(water - 15,0)
		trigger_glitch()
		spawn_floating_text("PESTS! -15 Water",Color(1,0.2,0.2))
		$BadSound.play()
		
	elif roll < 40:
		print("Bonus Rain! Water increased")
		water = min(water + 20, 100)
		spawn_floating_text("RAIN! +20 Water",Color(0.2,0.5,1))
		$GoodSound.play()
	
	elif roll < 60:
		print("Power outrage! Light reduced")
		light = max(light - 15, 0)
		trigger_glitch()
		spawn_floating_text("OUTAGE! -15 light",Color(1,1,0.2))
		$BadSound.play()
	
	elif roll < 75:
		print("Growth boost!")

		update_water_bar()
		light_bar.value = light
		spawn_floating_text("GROWTH SURGE!",Color(0.2,1,0.2))
		$GoodSound.play()
		
	else:
		print("Peaceful day. No events.")
		
func show_level_complete_popup():
	level_complete_label.text = "Level %d Complete!" % level
	level_complete_panel.visible = true

func _on_next_button_pressed():
	level_complete_panel.visible = false
	start_next_level()

func start_next_level():
	level += 1
	print("Starting Level", level)
	
	growth = 0.0
	water = 20
	light = 50
	shake_strength = 0.0
	
	if camera:
		camera.offset = Vector2.ZERO
	
	update_water_bar()
	light_bar.value = light
	update_plant_visual()
	
	WATER_DRAIN_RATE += 1.0
	LIGHT_DRAIN_RATE += 1.0
	
	roll_day_condition()
	
	is_game_active = true

func on_plant_evolved():
	is_game_active = false
	show_level_complete_popup()
	print("Plant Evolved")
	
func spawn_floating_text(msg:String,color:Color):
	var float_txt = floating_text_scene.instantiate()
	add_child(float_txt)
	
	var random_offset = Vector2(randf_range(-50,50),randf_range(-50,100))
	float_txt.position = $PlantPivot.position + random_offset
	float_txt.start_float(msg,color)


func _on_shop_button_pressed():
	$CanvasLayer/ShopPanel.visible =true
	$CanvasLayer/ShopPanel/UpgradeWaterButton.text="Turbo Hose ($%d)" %upgrade_cost
	get_tree().paused = true


func _on_upgrade_water_button_pressed():
	if biomass >= upgrade_cost:
		biomass -= upgrade_cost
		water_power += 10
		print("Upgrade purchased! New Water Power:", water_power)
		upgrade_cost +=50
		
		$CanvasLayer/ShopPanel/UpgradeWaterButton.text ="Turbo Hose ($%d)" % upgrade_cost
		spawn_floating_text("UPGRADE INSTALLED", Color.GREEN)
		$GoodSound.play()
	else:
		print("Too Poor!")
		$BadSound.play()
		$CanvasLayer/ShopPanel/UpgradeWaterButton.text = "NEED $%d!" %upgrade_cost
	


func _on_close_shop_button_pressed():
	$CanvasLayer/ShopPanel.visible = false
	get_tree().paused = false
	
func check_win_condition():
	if water >=100 and light >=50:
		
		print("Comditions Met! Level Up!")
		show_level_complete_popup()
		is_game_active = false
		
	elif water >= 100 and light <50:
		print("Water is full,but it's too dark to win! Light: &s" ,light)
