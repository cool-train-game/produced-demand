extends Path2D

var stations: Array
var visual_line
var is_closed
var points: Array

func initilize(visual_line_element):
	self.visual_line = visual_line_element

func set_is_closed(is_closed_input):
	self.is_closed = is_closed_input

func get_is_closed():
	return is_closed

func add_station(station):
	#if not station in stations:
	stations.append(station)

func add_bus(bus):
	add_child(bus)

func has_station(station):
	return stations.has(station)

func get_station_count():
	return len(stations)

func add_point_at_position(point, atStation):
	points.append({
		"position": point,
		"atStation": atStation
	})

	#var marker = Sprite2D.new()
	#marker.texture = load("res://assets/icon.svg")
	#marker.global_position = point
	#add_child(marker)
	#marker.scale = Vector2(.25, .25)
	#
	# add collider
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 20

	var area = Area2D.new()
	add_child(area)

	var area_collision_shape = CollisionShape2D.new()
	area_collision_shape.shape = circle_shape
	area.global_position = point
	area.add_child(area_collision_shape)
	
	area.connect("area_entered", _on_bus_entered.bind(len(points) - 1))

func _on_bus_entered(area, point_index):
	if area.name == "BusCollider":
		var bus = area.get_parent()
		if bus.on_route(self):
			if self.get_next_point(bus.last_point, bus.reverse) == points[point_index]:
				bus.set_last_point(points[point_index])


func get_closest_point(bus):
	var closest = points[0]
	var target_distance = get_distance(points[0].position, bus.get_global_position())
	for point in points:
		var distance = get_distance(point.position, bus.get_global_position())
		if distance < target_distance:
			closest = point
			target_distance = distance
	return closest

func get_distance(first_position, second_position):
	return abs(first_position.distance_to(second_position))
	#return abs(sqrt((second_position.y - first_position.y) * (second_position.y - first_position.y) + (second_position.x - first_position.x) * (second_position.x - first_position.x))) 

func get_next_point(point, reverse: bool):
	var index = points.find(point, 0)
	var next_index = (index + 1) if not reverse else (index - 1)
	if next_index >= len(points):
		next_index = 0
	if next_index < 0:
		next_index = len(points) - 1
	return points[next_index]

func get_next_point_with_station(point, reverse: bool):
	var index = points.find(point, 0)
	var next_index = (index + 1) if not reverse else (index - 1)
	if next_index >= len(points):
		next_index = 0
	if next_index < 0:
		next_index = len(points) - 1
	while not points[next_index].atStation:
		next_index = (next_index + 1) if not reverse else (next_index - 1)
		
		if next_index >= len(points):
			next_index = 0
		if next_index < 0:
			next_index = len(points) - 1

	return points[next_index]

func get_point_at_position(given_position):
	for point in points:
		if point.position == given_position:
			return point
	return null
