extends Node2D

"""
This temp_grid is accessed [y][x] because because it's way easier to write out
this visually to match the screen space but harder to work with, since we often
think in x, y, so we'll flip in `_ready()`
"""
var temp_grid = [
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ],
	[1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, ],
	[0, 0, 2, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 0, ],
	[0, 0, 2, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 0, ],
	[0, 0, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, ],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ],
]

var grid = []

const OCCUPIED = 0b00100 # Note, the 'b' for binary, makes flags easier
const PATH = 	 0b00010 # same as 2

var cols : int
var rows : int

var icon = preload("res://icon.png")

var dimension = icon.get_width() # Your tile size, will need to change if you can zoom
var mid = Vector2( dimension/2, dimension/2 )

var start : Vector2

var path = []

var grow = Vector2.ZERO

onready var line = $Line2D
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
	
	line.points = [ start * dimension + mid , start * dimension + mid + Vector2.RIGHT]


func is_next(x, y):
	""" Returns the direction of line growth, could be used to match the location
	of the cursor instead of filling the cell.
	"""
	if grid[x][y] & PATH and not (grid[x][y] & OCCUPIED):
		for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			if path[-1] + dir == Vector2(x, y):
				return dir
	
	return false

func update_point(point):
	line.set_point_position( line.get_point_count() - 1, point )

func _input(event):
	if event.is_action_pressed("ui_accept"):
		print(grid)
	
	if event is InputEventMouseMotion:
		var x = int( event.position.x / dimension )
		var y = int( event.position.y / dimension )

		if y < rows and x < cols:
			if is_next(x, y):
				grid[x][y] |= OCCUPIED
				var next_point = Vector2(x, y) * dimension + mid
				line.add_point( path[-1] * dimension + mid  )

				# You'll need to make sure the previous tween completed or something like that if they move too fast
				tween.interpolate_method(self, 'update_point', path[-1] * dimension + mid, next_point, .2)
				tween.start()
				
				path.append( Vector2(x, y) )
			# If is_next fails, you'd check to see if you went backwards a tile to undo the path (but not undoing the start)
