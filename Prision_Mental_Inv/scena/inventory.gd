extends Node

# Define the Item class to represent items in the inventory
class Item:
	var name: String
	var description: String
	var icon: Texture

	func _init(name: String, description: String, icon: Texture):
		self.name = name
		self.description = description
		self.icon = icon

# The inventory will hold multiple items (an array of Item objects)
var inventory : Array = []

# Function to add an item to the inventory
func add_item(item : Item):
	inventory.append(item)
	print("Item added: ", item.name)

# Function to remove an item from the inventory
func remove_item(item : Item):
	inventory.erase(item)
	print("Item removed: ", item.name)

# Function to check if the inventory is empty
func is_empty() -> bool:
	return inventory.size() == 0
