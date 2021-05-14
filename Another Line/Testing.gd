extends Node2D

"""
This temp_grid is accessed [y][x] because because it's way easier to write out
this visually to match the screen space but harder to work with, since we often
think in x, y, so we'll flip in `_ready()`
"""
var temp_grid = [
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, ],
	[1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 2, 2, 2, ],
	[0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, ],
	[0, 0, 2, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 0, ],
	[0, 0, 2, 2, 2, 2, 2, 2, 0, 2, 0, 0, 2, 0, ],
	[0, 0, 0, 2, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, ],
	[0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, ],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ],
]

var grid = []

const OCCUPIED = 0b00100 # Note, the 'b' for binary, makes flags easier
const PATH = 	 0b00010 # same as 2

var cols : int
var rows : int

var icon  = preload("res://icon.png")
var panel = preload("res://Panel.tscn")

var dimension = icon.get_width() # Your tile size, will need to change if you can zoom
var tile_offset = Vector2( dimension/2, dimension/2 )

var start : Vector2

var path = []

var grow = Vector2.ZERO

var last_dir = Vector2.RIGHT

onready var line :Line2D = $Line2D
onready var tween = $Tween

func flip(data):
	var new_data = []
	for col in len(data[0]):
		var temp = []
		for row in len(data):
			temp.append( data[row][col] )
		new_data.append( temp )
	return new_data

func _ready():

#	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	grid = flip(temp_grid)
	rows = len( grid[0] )
	cols = len( grid )
	
	for y in range( len( temp_grid ) ):
		for x in range( len(temp_grid[0]) ):
			if grid[x][y] == 1:
				start = Vector2(x, y)
				path.append( start )
				
			elif grid[x][y] == 2:
				var sprite =  Sprite.new()
				sprite.texture = icon
				sprite.centered = false
				sprite.position = Vector2( x * dimension, y * dimension )
				sprite.z_index = -10
				add_child( sprite )
	
	line.points = [ start * dimension + tile_offset , start * dimension + tile_offset + Vector2.RIGHT]

#grab the position of the mouse on the axis of the dir and snap to the center of the tile on the other axis
func get_mouse_axis_pos(x,y):
	var mouse_axis
	
	if last_dir.y == 0:
		mouse_axis = Vector2( get_global_mouse_position().x, y * dimension + 32 )
	else:
		mouse_axis = Vector2( x * dimension + 32 , get_global_mouse_position().y )
	return mouse_axis

func is_next(x, y):
	""" Returns the direction of line growth, could be used to match the location
	of the cursor instead of filling the cell.
	"""
	if grid[x][y] & PATH:
		var mouse_axis = get_mouse_axis_pos(x,y)
		
		if not (grid[x][y] & OCCUPIED):
			for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				if path[-1] + dir == Vector2(x, y):
					last_dir = dir
					return dir
		else:
			update_point(mouse_axis)

	return false

func update_point(point):
	line.set_point_position( line.get_point_count() - 1, point )
	print("update: ",point)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		print(grid)
	if event.is_action("ui_cancel"):
		get_tree().reload_current_scene()
	
	if event is InputEventMouseMotion:
		var x = int( event.position.x / dimension )
		var y = int( event.position.y / dimension )

		if y < rows and x < cols:
			if is_next(x, y):
				grid[x][y] |= OCCUPIED
				var next_point = Vector2(x, y) * dimension + tile_offset
				var point_pos = path[-1] * dimension + Vector2(32,32)
				update_point(point_pos)
				var mouse_axis = get_mouse_axis_pos(x,y)
				line.add_point( mouse_axis )
				
				#For debugging purposes 
				var new_panel = panel.instance()
				new_panel.rect_global_position = point_pos - Vector2(4,4)
				add_child(new_panel)
				
				path.append( Vector2(x, y) )
