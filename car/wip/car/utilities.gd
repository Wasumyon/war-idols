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
