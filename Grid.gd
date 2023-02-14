extends Node2D

var general_block = preload("res://Blocks/Block.tscn")

signal award_points

onready var swap_timer = $SwapTimer
onready var drop_timer = $DropTimer

enum {
	MOVE,
	IDLE
}

var OFFSET = Vector2(255, 63)
var FALL_SPEED = 0.3

var state = MOVE
var block_array: Array = []
var block_size = 64
var block_offset = 5
var width = 8
var height = 8

var start_swipe: Vector2
var end_swipe: Vector2

func _ready():
	state = MOVE
	init_blocks()
	var matches = detect_matches()
	
	while(matches.size() > 0):
		remove_init_matches(matches)
		replace_missing_blocks()
		matches = detect_matches()
	
	state = IDLE

func _process(_delta):
	if state == IDLE:
		if Input.is_action_just_pressed("click"):
			var mouse_grid = pos_to_grid(get_global_mouse_position())
			if grid_within_bounds(mouse_grid):
				start_swipe = mouse_grid
		
		if Input.is_action_just_released("click"):
			var mouse_grid = pos_to_grid(get_global_mouse_position())
			if grid_within_bounds(mouse_grid):
				if valid_swipe(mouse_grid):
					end_swipe = mouse_grid
					handle_swipe()

func init_blocks():
	for i in range(width):
		block_array.append([])
		for j in range(height):
			var block = general_block.instance()
			block.shape = 0
			block.set_random_color()
			block.position = grid_to_pos(i, j)
			add_child(block)
			block_array[i].append(block)

func detect_and_replace_matches():
	var matches = detect_matches()
	
	if (matches.size() > 0):
		remove_matches(matches)
		fall_and_replace_blocks()
	else:
		state = IDLE

func detect_matches():
	var matches = []
	
	matches = detect_matches_in_direction(matches, true, width, height)
	matches = detect_matches_in_direction(matches, false, height, width)
	
	return matches

func detect_matches_in_direction(var matches: Array, var dir: bool, var i_size, var j_size):
	var current_nodes = []
	var current_color = 0
	var match_count = 0
	
	for i in range(i_size):
		if match_count >= 3:
			matches.append([match_count, current_nodes])
		
		current_nodes = []
		current_color = 0
		match_count = 0
		
		for j in range(j_size):
			var block
			if dir:
				block = block_array[i][j]
			else:
				block = block_array[j][i]
			
			if (block.color == current_color):
				match_count += 1
			else:
				if match_count >= 3:
					matches.append([match_count, current_nodes])
				
				current_nodes = []
				current_color = block.color
				match_count = 1
			if dir:
				current_nodes.append([i, j])
			else:
				current_nodes.append([j, i])
	
	if match_count >= 3:
			matches.append([match_count, current_nodes])
	
	return matches

func remove_init_matches(var matches: Array):
	for line in matches:
		for coords in line[1]:
			var block = block_array[coords[0]][coords[1]]
			if block:
				block.queue_free()
				block_array[coords[0]][coords[1]] = null

func remove_matches(var matches: Array):
	var score = 0
	for line in matches:
		score += line[0]
		
		if score == 4:
			# handle_four_match(line[1])
			handle_three_match(line[1])
		else:
			handle_three_match(line[1])
	
	emit_signal("award_points", score)

func handle_four_match(var line: Array):
	var reward_coord
	
	# Look for a block handled by user
	for coords in line:
		if (coords[0] == start_swipe.x and coords[1] == start_swipe.y):
			reward_coord = start_swipe
		elif (coords[0] == end_swipe.x and coords[1] == end_swipe.y):
			reward_coord = end_swipe
	
	# If none found, pick a random block
	if (!reward_coord):
		var rand_coord = line[randi() % line.size()]
		reward_coord = Vector2(rand_coord[0], rand_coord[1])
	
	

func handle_three_match(var line: Array):
	for coords in line:
		var block = block_array[coords[0]][coords[1]]
		if block:
			block.pop_block()
			block_array[coords[0]][coords[1]] = null

func replace_missing_blocks():
	for i in range(width):
		for j in range(height):
			var block = block_array[i][j]
			if !block:
				var new_block = general_block.instance()
				new_block.shape = 0
				new_block.set_random_color()
				new_block.position = grid_to_pos(i, j)
				add_child(new_block)
				block_array[i][j] = new_block

func handle_swipe():
	var start_block = block_array[start_swipe.x][start_swipe.y]
	var end_block = block_array[end_swipe.x][end_swipe.y]
	
	# Swap blocks
	block_array[start_swipe.x][start_swipe.y] = end_block
	block_array[end_swipe.x][end_swipe.y] = start_block
	
	# Check if any matches occured
	var valid_swap = match_at_grid(start_swipe, end_block.color) or match_at_grid(end_swipe, start_block.color)
	
	# Swap back to original
	block_array[start_swipe.x][start_swipe.y] = start_block
	block_array[end_swipe.x][end_swipe.y] = end_block
	
	if valid_swap:
		state = MOVE
		block_array[start_swipe.x][start_swipe.y] = end_block
		block_array[end_swipe.x][end_swipe.y] = start_block
		
		start_block.swap_block(end_block.global_position, swap_timer.wait_time)
		end_block.swap_block(start_block.global_position, swap_timer.wait_time)
		
		swap_timer.start()
	else:
		start_block.invalid_swap((end_block.global_position - start_block.global_position)/4 + start_block.global_position)
		end_block.invalid_swap((start_block.global_position - end_block.global_position)/4 + end_block.global_position)

func match_at_grid(var grid: Vector2, var color: int):
	return (match_in_dir(grid, color, Vector2.LEFT) or match_in_dir(grid, color, Vector2.UP) or 
	match_in_dir(grid, color, Vector2.RIGHT) or match_in_dir(grid, color, Vector2.DOWN) or
	center_match_at(grid, color))

func match_in_dir(var grid: Vector2, var color: int, var dir: Vector2):
	var end_grid = grid + 2 * dir
	if (grid_within_bounds(end_grid) and block_array[end_grid.x][end_grid.y].color == color):
		var middle_grid = grid + dir
		if block_array[middle_grid.x][middle_grid.y].color == color:
			return true
	
	return false

func center_match_at(var grid: Vector2, var color: int):
	if grid_within_bounds(grid + Vector2.LEFT) and grid_within_bounds(grid + Vector2.RIGHT):
		var left_grid = grid + Vector2.LEFT
		var right_grid = grid + Vector2.RIGHT
		var left_block = block_array[left_grid.x][left_grid.y]
		var right_block = block_array[right_grid.x][right_grid.y]
		
		if left_block.color == color and right_block.color == color:
			return true
	
	if grid_within_bounds(grid + Vector2.UP) and grid_within_bounds(grid + Vector2.DOWN):
		var up_grid = grid + Vector2.UP
		var down_grid = grid + Vector2.DOWN
		var up_block = block_array[up_grid.x][up_grid.y]
		var down_block = block_array[down_grid.x][down_grid.y]
		
		if up_block.color == color and down_block.color == color:
			return true
	
	return false

func fall_and_replace_blocks():
	var longest_drop = 0.0
	
	for x in range(width):
		# Fall blocks
		for y in range(height - 2, -1, -1):
			var block = block_array[x][y]
			var below_grid = Vector2(x, y+1)
			
			if (block) and (!block_array[below_grid.x][below_grid.y]):
				for k in range(y+2, height):
					var next_block = block_array[x][k]
					if (next_block):
						break
					else:
						below_grid.y = k
				
				block_array[below_grid.x][below_grid.y] = block
				block_array[x][y] = null
				
				block.fall_block(grid_to_pos(below_grid.x, below_grid.y), (below_grid.y - y) * FALL_SPEED)
		
		# Spawn blocks
		var spawn_height = -1
		for y in range(height - 1, -1, -1):
			var block = block_array[x][y]
			
			if (!block):
				var new_block = general_block.instance()
				new_block.shape = 0
				new_block.set_random_color()
				new_block.position = grid_to_pos(x, spawn_height)
				add_child(new_block)
				block_array[x][y] = new_block
				
				var drop = (y - spawn_height)
				if (drop > longest_drop):
					longest_drop = drop
				new_block.fall_block(grid_to_pos(x, y), drop * FALL_SPEED)
				
				spawn_height -= 1
		
	drop_timer.start((longest_drop + 1) * FALL_SPEED)

func grid_to_pos(var x, var y):
	return Vector2(x * (block_size + block_offset), y * (block_size + block_offset)) + OFFSET

func pos_to_grid(var pos: Vector2):
	pos -= OFFSET
	var x = int(round(pos.x / (block_size + block_offset)))
	var y = int(round(pos.y / (block_size + block_offset)))
	
	return Vector2(x, y)

func grid_within_bounds(var pos: Vector2) -> bool:
	return ((pos.x >= 0) and (pos.x < width) and (pos.y >= 0) and (pos.y < height))

func valid_swipe(var pos: Vector2):
	return (((abs(pos.x - start_swipe.x) == 1) and (pos.y - start_swipe.y == 0))
	or ((abs(pos.y - start_swipe.y) == 1) and (pos.x - start_swipe.x == 0)))

func _on_SwapTimer_timeout():
	detect_and_replace_matches()

func _on_DropTimer_timeout():
	detect_and_replace_matches()
