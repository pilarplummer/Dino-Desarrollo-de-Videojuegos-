extends CharacterBody2D #nombre dino

const GRAVITY : int = 4200 #Fuerza que empuja al dino hacia arriba.
const JUMP_SPEED : int = -1800 #Fuerza que empuja al dino hacia arriba.

#Llama a cada frame. 'delta' es el tiempo transc. desde el frame anterior
func _physics_process(delta):
	velocity.y += GRAVITY * delta #Aumenta la velocidad vertical del dino.
	if is_on_floor(): #para que no salte hasta el infinito y más allá
		if not get_parent().game_running: #no quiero que corra si no empezó
			$AnimatedSprite2D.play("idle")
		else:
			$RunCol.disabled = false #Si saco esto, el dino no se mueve. Se asume que corre.
			if Input.is_action_just_pressed("ui_accept"):
				velocity.y = JUMP_SPEED
				$JumpSound.play() #Importa el sonido de salto
			elif Input.is_action_pressed("ui_down"):
				$AnimatedSprite2D.play("duck") #Agacharse
				$RunCol.disabled = true #Activa colisión
			else: #Si ninguna tecla está pressed
				$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("jump") #Cuando el dino no esté en el piso, va a saltar.
			
	move_and_slide() #Para mover al dino
#4414
