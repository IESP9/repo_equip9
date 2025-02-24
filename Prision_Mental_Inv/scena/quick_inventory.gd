extends Panel

onready var inventory : Node  # Reference to the Inventory script
var slot_size = 50  # Size of each item slot

# Function to update the quick inventory bar to show items
func update_inventory_bar():
	# Clear the current icons (if any)
	for child in get_children():
		child.queue_free()

	# Loop through the inventory and create icons for each item
	for i in range(inventory.inventory.size()):
		var item = inventory.inventory[i]

		# Create a new icon for each item
		var icon = TextureRect.new()
		icon.texture = item.icon
		icon.rect_min_size = Vector2(slot_size, slot_size)
		icon.rect_position = Vector2(i * slot_size, 0)  # Position the icons next to each other

		add_child(icon)

# Reference to inventory in the _ready() function
func _ready():
	inventory = get_node("/root/Inventory")  # Reference to the Inventory script
	update_inventory_bar()
