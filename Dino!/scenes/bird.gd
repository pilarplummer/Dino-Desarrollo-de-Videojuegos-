extends Area2D


#llama cuando el nodo entre a escena
func _ready():
	pass
	

#llama a cada frame. delta es el tiempo desde el frame previo
func _process(delta):
	position.x -= get_parent().speed / 2 #ajusta la pos basado en speed var
