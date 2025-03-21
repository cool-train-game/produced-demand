extends Node2D

var route
var parent
var reverse: bool = false
var route_closed: bool

var last_point
var last_station

var current_station = null
var reverse_when_complete = false
var restart_when_complete = false

var time_arrived_at_station = -1
var wait_time

@export var top_speed = 200
var speed
var acceleration = 0
var max_occupancy = 8
var occupants: Array


func is_at_station():
	return time_arrived_at_station != -1

func _ready() -> void:
	speed = top_speed
	parent = get_parent()
	route = parent.get_parent()
	parent.progress = 0
	var closest_point = route.get_closest_point(global_position)
	last_point = closest_point
	current_station = Stations.get_station_at_position(closest_point.position)
	exit_station()

func _process(delta: float) -> void:
	if Game.paused:
		return

	if is_at_station():
		collect_people()
		if Time.get_ticks_msec() - time_arrived_at_station > wait_time:
			if reverse_when_complete:
				reverse = not reverse
				reverse_when_complete = false

			if reverse:
				get_node("Sprite").flip_h = 1
				get_node("Label").position.x = -1
			else:
				get_node("Sprite").flip_h = 0
				get_node("Label").position.x = -28
			exit_station()

	var new_speed = update_bus_speed(delta)
	var change = new_speed * delta
	update_bus_position(change)

# ======================================================

func entered_station_range(station):
	if current_station == null:
		if route.has_station(station):
			if is_approaching_station(station):
				current_station = station
				var distance_to_station = get_distance_to_station(station)
				acceleration = (0 - pow(speed, 2)) / (2 * distance_to_station)

func exited_station_range(station):
	if route.has_station(station) and last_station == station: # only run this if properly left last - THIS IS THE CAUSE OF NOT PICKING UP WHEN TOO CLOSE ISSUE
		acceleration = 0
		speed = top_speed

func entered_station(station):
	if station == current_station:
		time_arrived_at_station = Time.get_ticks_msec()

		# people are removed, their data should be saved
		var people_delivered = current_station.deliver_people(occupants)
		for person in people_delivered:
			var person_index = occupants.find(person, 0)
			occupants.remove_at(person_index)
			PeopleGenerator.regenerate_person(current_station.global_position, person)

		wait_time = current_station.get_wait_time(get_open_seats())
		acceleration = 0
		speed = 0

func exit_station():
	acceleration = ((pow(top_speed, 2)) / (2 * 80))
	last_station = current_station
	current_station = null
	time_arrived_at_station = -1

# ======================================================

func is_approaching_station(station):
	var next_point_with_station = route.get_next_point_with_station(last_point, reverse)
	if not Stations.stations[Stations.get_index_of_station_at_position(next_point_with_station.position)] == station:
		return false

	var radius = station.get_node("Nearby").get_node("Collider").shape.radius

	var current_point = route.get_next_point(last_point, reverse)
	while current_point != next_point_with_station:
		if not in_given_range(radius, station.global_position, current_point.position):
			return false
		current_point = route.get_next_point(current_point, reverse)

	# if it reaches here, all next points until station are in range
	return true


func get_distance_to_station(_station):
	var next_point = route.get_next_point(last_point, reverse)
	var distance_to = distance(global_position, next_point.position)
	if next_point.atStation:
		return distance_to
	var current_point = next_point
	next_point = route.get_next_point(next_point, reverse)
	
	while (not next_point.atStation):
		distance_to += distance(current_point.position, next_point.position)
		current_point = next_point
		next_point = route.get_next_point(next_point, reverse)
	distance_to += distance(current_point.position, next_point.position)

	return distance_to


func distance(pos1, pos2):
	return sqrt((pos2.x - pos1.x) ** 2 + (pos2.y - pos1.y) ** 2)

func in_given_range(radius, target, point):
	return distance(target, point) <= radius


func update_bus_speed(delta):
	speed += acceleration * delta
	if speed > top_speed:
		acceleration = 0
		speed = top_speed
	return speed

func update_bus_position(change):
	if not route_closed:
		if reverse:
			change *= -1

	var new_progress = parent.get_progress() + change
	if new_progress > parent.get_parent().curve.get_baked_length():
		new_progress = parent.get_parent().curve.get_baked_length()
		if not route_closed:
			reverse_when_complete = true
		elif restart_when_complete:
			new_progress = 0
			speed = top_speed
			restart_when_complete = false

	parent.set_progress(new_progress)

func collect_people():
	var new_occupants = current_station.get_people(get_open_seats(), route)
	for occupant in new_occupants:
		occupants.append(occupant)
	update_occupants_label()

func update_occupants_label():
	$Label.text = str(len(occupants))

func set_route_closed(value: bool):
	route_closed = value

func get_open_seats():
	return max_occupancy - len(occupants)

func on_route(given_route):
	return given_route == route

func set_last_point(point):
	last_point = point
	if route.is_end_point(point):
		if not route_closed:
			reverse_when_complete = true
		else: # route is closed
			restart_when_complete = true
