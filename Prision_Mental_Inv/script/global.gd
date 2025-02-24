extends Node

var inventory = []

signal inventory_updated

var player_node: Node = null

func _ready():
	inventory.resize(1)
	
func add_item():
	inventory_updated.emit()
	
func remove_item():
	inventory_updated.emit()


func increase_inventory_size():
	inventory_updated.emit()

func set_player_reference(player):
	player_node = player
	
