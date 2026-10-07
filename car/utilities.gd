extends Node

##Returns a combined curve2D by merging a second Curve2D at end of first Curve2D.
func merge_curves_2D(curve1: Curve2D, curve2: Curve2D) -> Curve2D:
	var new_curve: Curve2D = curve1.duplicate()
	if new_curve.get_point_count() == 0:
		return curve2.duplicate()
	
	var last_pt_1 = new_curve.get_point_position(new_curve.get_point_count() - 1)
	var first_pt_2 = curve2.get_point_position(0)
	var offset = last_pt_1 - first_pt_2
	
	for i in range(curve2.get_point_count()):
		var pt = curve2.get_point_position(i)
		var in_ctl = curve2.get_point_in(i)
		var out_ctl = curve2.get_point_out(i)
	
		new_curve.add_point(pt + offset, in_ctl, out_ctl)
		
	return new_curve
	
##Returns a combined curve3D by merging a second Curve3D at end of first Curve3D.
func merge_curves_3D(curve1: Curve3D, curve2: Curve3D) -> Curve3D:
	var new_curve: Curve3D = curve1.duplicate()
	if new_curve.get_point_count() == 0:
		return curve2.duplicate()
	
	var last_pt_1 = new_curve.get_point_position(new_curve.get_point_count() - 1)
	var first_pt_2 = curve2.get_point_position(0)
	var offset = last_pt_1 - first_pt_2
	
	for i in range(curve2.get_point_count()):
		var pt = curve2.get_point_position(i)
		var in_ctl = curve2.get_point_in(i)
		var out_ctl = curve2.get_point_out(i)
		
		new_curve.add_point(pt + offset, in_ctl, out_ctl)
		
	return new_curve

##Saves the screen displayed at subviewport as PNG at directory path.
func save_screenshot_PNG (subviewport : SubViewport, directoryPath : String) -> void:
	await  RenderingServer.frame_post_draw
	subviewport.get_texture().get_image().save_png(directoryPath)
	
##Saves the screen displayed at subviewport as JPG at directory path.
func save_screenshot_JPG (subviewport : SubViewport, directoryPath : String) -> void:
	await  RenderingServer.frame_post_draw
	subviewport.get_texture().get_image().save_jpg(directoryPath)

##Returns raycast 2D data of object mouse is hovering over. Raycast range has a default value of 1000 if no value is added.
func get_mouse_target_2D (cam : Camera2D, mask : int, rayRange : float = 1000.0) -> RayCast2D:
	var ray : RayCast2D
	ray.position = cam.position
	ray.target_position = cam.project_local_ray_normal(get_viewport().get_mouse_position()) * rayRange
	ray.set_collision_mask_value(mask, true)
	ray.force_raycast_update()
	return ray
	
##Returns raycast 3D data of object with specified collision mask mouse is hovering over. Raycast range has a default value of 1000 if no value is added.
func get_mouse_target_3D (cam : Camera3D, mask : int, rayRange : float = 1000.0) -> RayCast3D:
	var ray : RayCast3D
	ray.position = cam.position
	ray.target_position = cam.project_local_ray_normal(get_viewport().get_mouse_position()) * rayRange
	ray.set_collision_mask_value(mask, true)
	ray.force_raycast_update()
	return ray
