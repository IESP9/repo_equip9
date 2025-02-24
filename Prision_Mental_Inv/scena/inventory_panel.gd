extends Panel

var inventory : Node  # Reference to the Inventory script
var is_inventory_open : bool = false
onready var inventory_panel = $InventoryPanel  # Full inventory panel

func _ready():
	inventory = get_node("/root/Inventory")  # Reference to the Inventory script
	inventory_panel.visible = false  # Hide the full inventory initially

func _input(event):
	if event is InputEventKey and event.pressed and event.scancode == KEY_TAB:
		toggle_inventory()

# Function to toggle between showing and hiding the full inventory
func toggle_inventory():
	is_inventory_open = !is_inventory_open
	inventory_panel.visible = is_inventory_open
	# Update the UI when the inventory is toggled
	update_full_inventory_screen()

# Function to update the full inventory UI
func update_full_inventory_screen():
	for child in get_children():
		child.queue_free()  # Clear current UI elements
	
	# Loop through the inventory and add buttons or icons for each item
	for i in range(inventory.inventory.size()):
		var item = inventory.inventory[i]

		# Create a button or icon for each item
		var item_button = Button.new()
		item_button.text = item.name
		item_button.rect_min_size = Vector2(200, 50)
		item_button.rect_position = Vector2(0, i * 60)  # Stack buttons vertically

		item_button.connect("pressed", self, "_on_item_pressed", [item])

		add_child(item_button)

# When an item is selected in the full inventory
func _on_item_pressed(item: Item):
	print("Item selected: ", item.name)
