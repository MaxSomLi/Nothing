extends Node2D

const NUM = 10
const START = -270
const SIZE = 60
const TILE_SIZE = Vector2(52, 52)
const CAT_TILE_SIZE = Vector2(44, 44)
const CAT_SIZE = 50
const CAT_START = Vector2(-525, 0)
const CAT_NUM = 5
var tiles = []
const DIFF = 24
var removed = []
var modifiable = true
var side
var current_player = 0
var picked
@onready var pieces = [$BBishop, $WBishop, $BCat, $WCat, $BKing, $WKing, $BKnight, $WKnight, $BPawn, $WPawn, $BRook, $WRook, $BQueen, $WQueen]
@onready var play = $Button
var chosen
@onready var option = $OptionButton
var cat_moves = []
@onready var cat = $Node2D
var cat_tiles = []
var chess_position = []
var attacks = 0
const CAT_POS = Vector2(-425, 100)
const MOVE_COUNT = 20
var cat_value
const MOD = 3
const PAWN_VALUE = 1
const KING_VALUE = 4
const KNIGHT_VALUE = 3
const QUEEN_VALUE = 9
const BISHOP_VALUE = 3
const ROOK_VALUE = 5



func _ready() -> void:
	for i in range(NUM):
		var h = []
		for j in range(NUM):
			var tile = MeshInstance2D.new()
			tile.mesh = QuadMesh.new()
			tile.mesh.size = TILE_SIZE
			tile.position = Vector2(START + SIZE*i, START + SIZE*j)
			tile.z_index = -1
			add_child(tile)
			tiles.append(tile)
			h.append("empty")
		chess_position.append(h)
	for i in range(CAT_NUM):
		for j in range(CAT_NUM):
			var tile = MeshInstance2D.new()
			tile.mesh = QuadMesh.new()
			tile.mesh.size = CAT_TILE_SIZE
			tile.position = Vector2(CAT_SIZE*i, CAT_SIZE*j) + CAT_START
			tile.z_index = -1
			cat.add_child(tile)
			cat_tiles.append(tile)
	find_cat_tile(CAT_POS).modulate = Color.REBECCA_PURPLE

func _input(event: InputEvent) -> void:
	if modifiable:
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
			var ft = find_tile(get_global_mouse_position())
			if ft:
				if ft.modulate == Color.WHITE:
					removed.append(ft)
					ft.modulate = Color.WEB_PURPLE
				else:
					ft.modulate = Color.WHITE
					removed.erase(ft)
			else:
				ft = find_cat_tile(get_global_mouse_position())
				if ft:
					if ft.modulate == Color.WHITE:
						ft.modulate = Color.DARK_RED
						cat_moves.append(["attack", (ft.position - CAT_POS) / CAT_SIZE])
						attacks += 1
					elif ft.modulate == Color.DARK_GREEN:
						ft.modulate = Color.NAVY_BLUE
						cat_moves.append(["attack", (ft.position - CAT_POS) / CAT_SIZE])
						attacks += 1
					elif ft.modulate == Color.NAVY_BLUE:
						ft.modulate = Color.DARK_BLUE
						cat_moves.erase(["attack", (ft.position - CAT_POS) / CAT_SIZE])
						attacks -= 1
					elif ft.modulate == Color.DARK_RED:
						ft.modulate = Color.WHITE
						cat_moves.erase(["attack", (ft.position - CAT_POS) / CAT_SIZE])
						attacks -= 1
		elif event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			var ft = find_piece(get_global_mouse_position())
			if ft:
				chosen = ft
			else:
				ft = find_tile(get_global_mouse_position())
				if ft and chosen:
					if ft.get_child_count() > 0:
						var texture = ft.get_child(0).texture
						ft.remove_child(ft.get_child(0))
						var pos = (ft.position - Vector2(START, START)) / SIZE
						chess_position[pos.x][pos.y] = "empty"
						if texture != chosen.texture:
							var new = chosen.duplicate(2)
							ft.add_child(new)
							chess_position[pos.x][pos.y] = chosen
							new.position = Vector2.ZERO
					else:
						var new = chosen.duplicate(2)
						ft.add_child(new)
						var pos = (ft.position - Vector2(START, START)) / SIZE
						chess_position[pos.x][pos.y] = chosen
						new.position = Vector2.ZERO
				else:
					ft = find_cat_tile(get_global_mouse_position())
					if ft:
						if ft.modulate == Color.WHITE:
							ft.modulate = Color.DARK_GREEN
							cat_moves.append(["regular", (ft.position - CAT_POS) / CAT_SIZE])
						elif ft.modulate == Color.DARK_GREEN:
							ft.modulate = Color.WHITE
							cat_moves.erase(["regular", (ft.position - CAT_POS) / CAT_SIZE])
						elif ft.modulate == Color.DARK_RED:
							ft.modulate = Color.NAVY_BLUE
							cat_moves.append(["regular", (ft.position - CAT_POS) / CAT_SIZE])
						elif ft.modulate == Color.NAVY_BLUE:
							ft.modulate = Color.DARK_RED
							cat_moves.erase(["regular", (ft.position - CAT_POS) / CAT_SIZE])
	else:
		if side == current_player and event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			var tile = find_tile(get_global_mouse_position())
			if tile:
				if picked:
					if tile.modulate == Color.YELLOW:
						if tile == picked:
							for t in tiles:
								t.modulate = Color.WHITE
						else:
							make_move(picked, tile)
					else:
						highlight_moves(tile)
				else:
					highlight_moves(tile)

func _process(_delta: float) -> void:
	if side != current_player and not modifiable:
		var best = best_move(chess_position, current_player, MOVE_COUNT)
		if best != []:
			make_move(find_tile(Vector2(START, START) + best[0]*SIZE), find_tile(Vector2(START, START) + best[1]*SIZE))

func find_tile(vec: Vector2) -> MeshInstance2D:
	for tile in tiles:
		if abs(vec.x - tile.position.x) < DIFF and abs(vec.y - tile.position.y) < DIFF:
			return tile
	return null

func find_piece(vec: Vector2):
	for piece in pieces:
		if abs(vec.x - piece.position.x) < DIFF and abs(vec.y - piece.position.y) < DIFF:
			return piece
	return null

func find_cat_tile(vec: Vector2):
	for tile in cat_tiles:
		if abs(vec.x - tile.position.x) < DIFF and abs(vec.y - tile.position.y) < DIFF:
			return tile
	return null

func _on_button_pressed() -> void:
	while removed.size() > 0:
		var h = removed[0]
		removed.remove_at(0)
		var pos = (h.position - Vector2(START, START)) / SIZE
		chess_position[pos.x][pos.y] = "chasm"
		tiles.erase(h)
		remove_child(h)
	modifiable = false
	for piece in pieces:
		piece.visible = false
	option.visible = false
	play.visible = false
	side = option.selected
	remove_child(cat)
	@warning_ignore("integer_division")
	cat_value = attacks / MOD

func highlight_moves(tile: MeshInstance2D) -> void:
	picked = tile
	for t in tiles:
		t.modulate = Color.WHITE
	tile.modulate = Color.YELLOW
	var tile_pos = (tile.position - Vector2(START, START)) / SIZE
	for t in tiles:
		var t_pos = (t.position - Vector2(START, START)) / SIZE
		if is_legal(tile_pos, t_pos):
			t.modulate = Color.YELLOW

func make_move(t_start: MeshInstance2D, t_end: MeshInstance2D) -> void:
	if t_end.get_child_count() > 0:
		t_end.remove_child(t_end.get_child(0))
	t_start.get_child(0).reparent(t_end)
	t_end.get_child(0).position = Vector2.ZERO
	var pos_start = (t_start.position - Vector2(START, START)) / SIZE
	var pos_end = (t_end.position - Vector2(START, START)) / SIZE
	chess_position[pos_end.x][pos_end.y] = chess_position[pos_start.x][pos_start.y]
	chess_position[pos_start.x][pos_start.y] = "empty"
	for t in tiles:
		t.modulate = Color.WHITE
	current_player = 1 - current_player

func is_legal(t_start_pos: Vector2, t_end_pos: Vector2) -> bool:
	if chess_position[t_start_pos.x][t_start_pos.y] is not Sprite2D:
		return false
	if chess_position[t_end_pos.x][t_end_pos.y] is String and chess_position[t_end_pos.x][t_end_pos.y] == "chasm":
		return false
	var name = chess_position[t_start_pos.x][t_start_pos.y].texture.resource_path.split("_")
	if (name[0] == "res://pieces/W" and current_player == 1) or (name[0] == "res://pieces/B" and current_player == 0):
		return false
	var end_color = "none"
	if chess_position[t_end_pos.x][t_end_pos.y] is Sprite2D:
		end_color = chess_position[t_end_pos.x][t_end_pos.y].texture.resource_path.split("_")[0]
	var dist = t_end_pos - t_start_pos
	if name[1] == "King.png" and end_color != name[0] and abs(dist.x) <= 1 and abs(dist.y) <= 1:
		return true
	if name[1] == "Queen.png" and end_color != name[0] and (abs(dist.x) == abs(dist.y) or dist.x == 0 or dist.y == 0) and way_clear(t_start_pos, t_end_pos):
		return true
	if name[1] == "Rook.png" and end_color != name[0] and (dist.x == 0 or dist.y == 0) and way_clear(t_start_pos, t_end_pos):
		return true
	if name[1] == "Knight.png" and end_color != name[0] and ((abs(dist.x) == 2 and abs(dist.y) == 1) or (abs(dist.x) == 1 and abs(dist.y) == 2)):
		return true
	if name[1] == "Bishop.png" and end_color != name[0] and abs(dist.x) == abs(dist.y) and way_clear(t_start_pos, t_end_pos):
		return true
	if name[1] == "Pawn.png" and ((dist.y == -1 and side == current_player) or (dist.y == 1 and side != current_player)) and ((dist.x == 0 and end_color == "none") or (abs(dist.x) == 1 and end_color != "none" and end_color != name[0])):
		return true
	if name[1] == "Cat.png":
		if end_color == name[0]:
			return false
		for cm in cat_moves:
			if cm[1] == dist and ((cm[0] == "regular" and end_color == "none") or (cm[0] == "attack" and end_color != "none")):
				return true
	return false

func way_clear(t_start_pos, t_end_pos) -> bool:
	var min_x = min(t_start_pos.x, t_end_pos.x)
	var max_x = max(t_start_pos.x, t_end_pos.x)
	var min_y = min(t_start_pos.y, t_end_pos.y)
	var max_y = max(t_start_pos.y, t_end_pos.y)
	if min_x == max_x:
		var k = min_y + 1
		while k < max_y:
			if chess_position[min_x][k] is not String or chess_position[min_x][k] != "empty":
				return false
			k += 1
	elif min_y == max_y:
		var k = min_x + 1
		while k < max_x:
			if chess_position[k][min_y] is not String or chess_position[k][min_y] != "empty":
				return false
			k += 1
	else:
		min_x += 1
		min_y += 1
		while min_x < max_x:
			if chess_position[min_x][min_y] is not String or chess_position[min_x][min_y] != "empty":
				return false
			min_x += 1
			min_y += 1
	return true

func best_move(start_position: Array, current: int, new_move_count: int) -> Array:
	var possible_moves = []
	for i in range(NUM):
		for j in range(NUM):
			if start_position[i][j] is Sprite2D and ((start_position[i][j].texture.resource_path.split("_")[0] == "res://pieces/W" and current == 0) or (start_position[i][j].texture.resource_path.split("_")[0] == "res://pieces/B" and current == 1)):
				for p in range(NUM):
					for t in range(NUM):
						if is_legal(Vector2(i, j), Vector2(p, t)):
							var new = start_position.duplicate(true)
							new[p][t] = new[i][j]
							new[i][j] = "empty"
							var e = -eval(new, 1 - current, new_move_count)
							possible_moves.append([Vector2(i, j), Vector2(p, t), e])
	var s = possible_moves.size()
	if s == 0:
		return []
	var best_case = possible_moves[0][2]
	var i = 1
	var res = [possible_moves[0][0], possible_moves[0][1]]
	while i < s:
		if possible_moves[i][2] > best_case:
			best_case = possible_moves[i][2]
			res = [possible_moves[i][0], possible_moves[i][1]]
		i += 1
	return res

func eval(new_position: Array, current: int, new_move_count: int) -> int:
	if new_move_count == 0:
		var res = 0
		for row in new_position:
			for t in row:
				if t is Sprite2D:
					var name = t.texture.resource_path.split("_")
					var k = 1
					if (name[0] == "res://pieces/W" and current == 0) or (name[0] == "res://pieces/B" and current == 1):
						k = -1
					if name[1] == "King.png":
						res -= KING_VALUE*k
					elif name[1] == "Queen.png":
						res -= QUEEN_VALUE*k
					elif name[1] == "Cat.png":
						res -= cat_value*k
					elif name[1] == "Pawn.png":
						res -= PAWN_VALUE*k
					elif name[1] == "Rook.png":
						res -= ROOK_VALUE*k
					elif name[1] == "Bishop.png":
						res -= BISHOP_VALUE*k
					elif name[1] == "Knight.png":
						res -= KNIGHT_VALUE*k
		return res
	var best = best_move(new_position, current, new_move_count)
	var new = new_position.duplicate(true)
	if best != []:
		new[best[1].x][best[1].y] = new[best[0].x][best[0].y]
		new[best[0].x][best[0].y] = "empty"
		return -eval(new, 1 - current, new_move_count - 1)
	return eval(new, current, 0)
