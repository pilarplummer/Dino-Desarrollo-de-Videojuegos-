extends Node

#PRELOAD obstaculos
var stump_scene = preload("res://scenes/stump.tscn")
var rock_scene = preload ("res://scenes/rock.tscn")
var barrel_scene = preload ("res://scenes/barrel.tscn")
var bird_scene = preload ("res://scenes/bird.tscn")
var obstacle_types := [stump_scene, rock_scene, barrel_scene]
var obstacles : Array
var bird_heights := [200, 390]

#VARIABLES DEL JUEGO
const DINO_START_POS := Vector2i(150, 485) #posicion que empiezan
const CAM_START_POS := Vector2i(576, 324)
var difficulty #dificultad actual - puede aumentar con el progreso
const MAX_DIFFICULTY : int = 2 #limite
var score : int #el score aumenta a partir de cuanto hayas corrido
const SCORE_MODIFIER : int = 10 #para que no sea tan alto el score
var high_score : int #puntaje, guarda el mas alto
var speed : float #variables de velocidad
const START_SPEED : float = 10.0 #qué tan rapido se mueve el dino en pantalla
const MAX_SPEED : int = 25 #limito la velocidad del dino
const SPEED_MODIFIER : int = 5000
var screen_size : Vector2i #piso
var ground_height : int
var game_running : bool
var last_obs #trackea el ultimo obstaculo creado

#Llama cuando el nodo entra a la escena del arbol.
func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$GameOver.get_node("Button").pressed.connect(new_game) #lo que permite el reset
	new_game()

func new_game():
	#resetea las variables
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false #esto hace que el juego se reinicie completamente con ayuda del game over
	difficulty = 0 #inicializo en 0 la dificultad
	#a la vez, tengo que reiniciar todos los objetos (sino siguen corriendo. e.g. un pajaro volando en la pantalla de inicio)
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
		
	#resetea los nodos
	$Dino.position = DINO_START_POS
	$Dino.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)	
	#resetea el hud y la screen de GAME OVER
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()

#Llama cada frame. 'delta´es el tiempo desde el frame anterior.
func _process(delta):
	if game_running:
		#aumenta y ajusta la dificultad
		speed = START_SPEED + score/SPEED_MODIFIER #aumenta la velocidad en la medida que aumenta el score
		if speed > MAX_SPEED:
			speed = MAX_SPEED #LIMITO la velocidad al maximo
		adjust_difficulty()
		
		#GENERAR OBSTACULOS
		generate_obs() #funcion
		
		#MOVER AL DINO Y LA CAMARA
		$Dino.position.x += speed
		$Camera2D.position.x += speed
		
		#ACTUALIZAR PUNTAJE (SCORE)
		score += speed
		show_score()
		
		#ACTUALIZAR POSICION DEL PISO
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
			
		#eliminar obstaculos off screen
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x): #si se va para la izq de la pantalla
				remove_obs(obs)
		
	else: #estoy esperando que el jugador presione ESPACIO
		if Input.is_action_just_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

func generate_obs():
	#Genero obstaculos del piso en orden aleatorio
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1 #el maximo siempre va a ser 3 (1-3)
		for i in range(randi() % max_obs + 1): #entre 1 y 3
			obs = obs_type.instantiate() #instancia cualquier escena
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100) #aparece a la derecha de la pantalla
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 5
			last_obs = obs #guardo la instancia de arriba acá
			add_obs(obs, obs_x, obs_y)
		#chance aleatoria de que aparezca un pájaro
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0: #0 o 1 - 50% chance de que haya un bird
				#generar obtaculo pájaro
				obs = bird_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100 #se basa en pantalla y puntuacion
				var obs_y : int = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs) #para que el dino reaccione al objeto (sino, solo pasa por encima, sin trigger)
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs): #esto es lo que remueve la instancia del nodo en pantalla para objetos que ya pasaron
	obs.queue_free()
	obstacles.erase(obs) #lo saca del array

func hit_obs(body): #para la reaccion al contacto del dino con los obs
	if body.name == "Dino": #dino = game character, jugador main
		game_over()	

func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)

func check_high_score(): #guarda el score mas alto
	if score > high_score: #score actual 
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(high_score / SCORE_MODIFIER)

func adjust_difficulty(): #necesito poder ir aumentando la dificultad
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false #esto es lo que reconoce que la partida corta una vez que se cruza un obstaculo
	$GameOver.show() #muestra la pantalla cuando se pierde
