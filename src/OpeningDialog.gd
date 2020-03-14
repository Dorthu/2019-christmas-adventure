extends Node2D

func opening_dialog():
	var controller = get_tree().get_root().get_children()[0]
	var lines := [
		"|Ppat_sad|Dad left last night, and he's not back yet.",
		"I should go after him.",
		"",
		"|Ppat_normal|I can't leave the house without my Backpack.",
	]
	var text_pool = Clickable.DialogTextPool.new(lines)
	var tutor = controller.cur_room.get_node("Hints")
	controller.show_dialog(text_pool, tutor)
	controller.stop_camera = false
	
func _on_OpeningDialog_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		opening_dialog()
		get_parent().remove_child(self)
