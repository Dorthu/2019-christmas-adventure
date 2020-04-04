extends Node2D

class_name MasterController

var dialog_controller # a DialogController
var cur_room # a Room, but it's circular dependency to declare that
var camera # a Camera
var inventory # an Inventory
var hint_icon # a HintIcon
var room_map: Dictionary
var active_item: InventoryItem = null
var clear_active_item := false
var game_state := Dictionary()
var stop_camera := true
var on_dialog_finished

var HINT_ICON_TEMPLATE = ResourceLoader.load("res://scenes/ui/ClickHint.tscn")

var is_mobile := false

func _ready():
	for s in ["living_room","bedroom","kitchen","cellar"]:
		room_map[s] = ResourceLoader.load('res://scenes/rooms/'+s+'.tscn').instance()
		room_map[s].controller = self
	dialog_controller = get_node('DialogController')
	dialog_controller.controller = self
	camera = get_node("Camera")
	camera.controller = self
	inventory = get_node("Inventory")
	inventory.controller = self
	hint_icon = get_node("HintIcon")
	
	# initial room
	change_rooms('bedroom', -400)
	
	# setup for mobile support
	# this all assumes we're only doing export for web, which
	# is true for now.  Wrap this in a platform check if we decide
	# to export to other platforms later
	var value = JavaScript.eval("""
		// this might need to be changed, I hear it's deprecated
		var result = (typeof window.orientation !== 'undefined');
		result;
	""")
	if value:
		# flag that this is a mobile session so we can handle it
		# accordingly elsewhere
		is_mobile = true
		JavaScript.eval("""
			alet('were in mobile mode now!');
		""")
		# what are the screen dimensions in this mobile browser?
		var screen_width = JavaScript.eval("screen.width")
		var screen_height = JavaScript.eval("screen.height")
		var width_scale = screen_width/1024
		var height_scale = screen_height/600
		var use_scale = width_scale if width_scale < height_scale else height_scale
		JavaScript.eval("""
			var canvas = document.getElementById('canvas');
			canvas.width = %s;
			canvas.height = %s;
		""" % [screen_width, screen_height])
		get_viewport().set_size_override(true, Vector2(512, 300))
		get_tree().set_screen_stretch(
			SceneTree.STRETCH_MODE_2D,
			SceneTree.STRETCH_ASPECT_KEEP,
			Vector2(512, 300),
			.228
		)
		camera.VIEWPORT_WIDTH = screen_width

func show_dialog(text_pool, on_finished=null): # Clickable.DialogTextPool
	if dialog_active():
		return
	inventory.hide()
	hint_icon.hide()
	dialog_controller.new_dialog(text_pool)
	on_dialog_finished = on_finished

func dialog_finished():
	inventory.show()
	hint_icon.show()
	if on_dialog_finished:
		on_dialog_finished.dialog_finished()
		on_dialog_finished = null

func dialog_active():
	return dialog_controller.cur_box != null

func should_pan_camera():
	if stop_camera:
		return false
	return active_item == null and not dialog_active()

func should_allow_doors():
	return (active_item == null and not dialog_active() 
			and game_state_active("showed_opening_dialog"))

func get_room_width():
	return cur_room.room_width

func change_rooms(to_room: String, camera_x: float):
	var active_scene = get_node('ActiveScene')
	while len(active_scene.get_children()) > 0:
		active_scene.remove_child(active_scene.get_child(0))
	cur_room = room_map[to_room]
	active_scene.add_child(cur_room)
	
	if camera:
		camera.pan_position = camera_x

func collect_item(item_id, item_texture):
	var item = inventory.make_item(item_id, item_texture)
	inventory.add_item(item)
	
func set_active_item(item: InventoryItem):
	if active_item and item == null:
		active_item.stop_being_active()
	active_item = item
	
func set_game_state(state: String):
	game_state[state] = true

func game_state_active(state: String):
	return state in game_state
	
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and active_item != null:
		# don't mark this as handled!
		clear_active_item = true # clear this nomatter what happens
		update()
	
	if is_mobile and event is InputEventMouseButton:
		# i can't warp_mouse in a browser, so we've got to find another
		# way to ignore idle pointers toward the edges of the screen
		# on mobile
		camera.ignore_mouse = not event.pressed

func _process(_delta):
	if active_item:
		if clear_active_item:
			set_active_item(null)
			clear_active_item = false
		update()

func _draw():
	if active_item:
		draw_texture(active_item.my_texture, get_global_mouse_position())

func show_click_hints():
	# when called, this function adds and makes visible a "click hint"
	# on each clickable element on the screen.  This is intended to
	# help players find what is interactable and help avoid pixel-
	# hunting.
	for node in cur_room.get_children():
		if not node is Clickable or not node.visible:
			continue
		
		var existing_hint_node = node.get_node("ClickHint")
		if existing_hint_node:
			existing_hint_node.show()
		else:
			if not node.before_backpack:
				if not inventory.has_item("backpack"):
					continue
			var new_hint_node = HINT_ICON_TEMPLATE.instance()
			new_hint_node.name = "ClickHint"
			new_hint_node.z_index = 15
			node.add_child(new_hint_node)

func hide_click_hints():
	# when called, this function hides all click hitns
	for node in cur_room.get_children():
		var existing_hint_node = node.get_node("ClickHint")
		if existing_hint_node:
			existing_hint_node.hide()
