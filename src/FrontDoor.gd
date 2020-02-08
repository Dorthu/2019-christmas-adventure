extends Clickable

class_name FrontDoor

func show_dialog(_event):
	var controller = get_tree().get_root().get_children()[0]
	
	if controller.inventory.has_item('backpack'):
		if controller.inventory.has_item('honeycomb'):
			controller.show_dialog(DialogTextPool.new([
				"That's all for now!  Check back soon for updates, or",
				"click the link below for our dev blog!",
				"",
				"Thank you for playing!",
				"This game was made by: ",
				"",
				"Sara :: @PointyEarsIllustration on instagram",
				"Josh :: Josh Sager on YouTube",
				"Dorthu :: dorthu.com",
			]))
		else:
			controller.show_dialog(DialogTextPool.new([
				"|Ppat_normal|I need something to eat while I'm out there.",
				"I'm not sure when I'll be back.",
			]))
	else:
		controller.show_dialog(DialogTextPool.new([
			"|Ppat_sad|I can't leave the house without my backpack."
		]))
