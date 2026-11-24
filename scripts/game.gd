extends Node2D

const ARENA := Vector2(960.0, 540.0)
const PLAYER_SPEED := 285.0
const BULLET_SPEED := 650.0
const ENEMY_SPEED := 92.0

var player_pos := ARENA * 0.5
var aim_dir := Vector2.RIGHT
var move_input := Vector2.ZERO
var bullets: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var score := 0
var health := 100.0
var fire_cooldown := 0.0
var spawn_timer := 0.0
var game_over := false
var touch_points: Dictionary = {}
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var shooting := false
var screen_scale := 1.0
var screen_offset := Vector2.ZERO

func _ready() -> void:
	get_viewport().size_changed.connect(_update_view)
	_update_view()
	for i in range(5):
		_spawn_enemy()

func _update_view() -> void:
	var size := get_viewport_rect().size
	screen_scale = minf(size.x / ARENA.x, size.y / ARENA.y)
	screen_offset = (size - ARENA * screen_scale) * 0.5
	queue_redraw()

func _to_game(pos: Vector2) -> Vector2:
	return (pos - screen_offset) / screen_scale

func _process(delta: float) -> void:
	if game_over:
		queue_redraw()
		return

	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move_input = keyboard if keyboard.length() > 0.05 else joystick_vector
	if move_input.length() > 1.0:
		move_input = move_input.normalized()
	player_pos += move_input * PLAYER_SPEED * delta
	player_pos.x = clampf(player_pos.x, 22.0, ARENA.x - 22.0)
	player_pos.y = clampf(player_pos.y, 22.0, ARENA.y - 22.0)

	if not shooting and not Input.is_action_pressed("shoot"):
		var mouse_game := _to_game(get_viewport().get_mouse_position())
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			shooting = true
			if mouse_game.distance_to(player_pos) > 12.0:
				aim_dir = (mouse_game - player_pos).normalized()
	elif Input.is_action_pressed("shoot"):
		shooting = true

	if Input.is_action_pressed("aim_left"):
		aim_dir = Vector2.LEFT
	elif Input.is_action_pressed("aim_right"):
		aim_dir = Vector2.RIGHT
	elif Input.is_action_pressed("aim_up"):
		aim_dir = Vector2.UP
	elif Input.is_action_pressed("aim_down"):
		aim_dir = Vector2.DOWN

	fire_cooldown -= delta
	if (shooting or Input.is_action_pressed("shoot")) and fire_cooldown <= 0.0:
		_fire()
		fire_cooldown = 0.17
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and touch_points.is_empty():
		shooting = false

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = maxf(0.55, 1.8 - score * 0.008)

	_update_bullets(delta)
	_update_enemies(delta)
	queue_redraw()

func _fire() -> void:
	bullets.append({"pos": player_pos + aim_dir * 24.0, "vel": aim_dir * BULLET_SPEED, "life": 1.25})

func _spawn_enemy() -> void:
	var side := randi() % 4
	var pos := Vector2.ZERO
	match side:
		0: pos = Vector2(randf_range(20, ARENA.x - 20), -20)
		1: pos = Vector2(ARENA.x + 20, randf_range(20, ARENA.y - 20))
		2: pos = Vector2(randf_range(20, ARENA.x - 20), ARENA.y + 20)
		_: pos = Vector2(-20, randf_range(20, ARENA.y - 20))
	enemies.append({"pos": pos, "hp": 2 if score > 12 else 1, "radius": 17.0})

func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		bullet.pos += bullet.vel * delta
		bullet.life -= delta
		var hit := false
		for j in range(enemies.size() - 1, -1, -1):
			var enemy: Dictionary = enemies[j]
			if bullet.pos.distance_to(enemy.pos) < enemy.radius + 5.0:
				enemy.hp -= 1
				hit = true
				if enemy.hp <= 0:
					enemies.remove_at(j)
					score += 1
					if score % 10 == 0:
						health = minf(100.0, health + 8.0)
				break
		if hit or bullet.life <= 0.0 or bullet.pos.x < -30 or bullet.pos.x > ARENA.x + 30 or bullet.pos.y < -30 or bullet.pos.y > ARENA.y + 30:
			bullets.remove_at(i)
		else:
			bullets[i] = bullet

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		var direction: Vector2 = (player_pos - enemy.pos).normalized()
		enemy.pos += direction * ENEMY_SPEED * (1.0 + score * 0.002) * delta
		if enemy.pos.distance_to(player_pos) < enemy.radius + 16.0:
			health -= 24.0 * delta
			enemy.pos -= direction * 35.0 * delta
		if health <= 0.0:
			health = 0.0
			game_over = true
		enemies[i] = enemy

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var p := _to_game(event.position)
		if event.pressed and game_over:
			_restart()
			return
		if event.pressed:
			touch_points[event.index] = p
			if p.x < ARENA.x * 0.48:
				joystick_origin = p
				joystick_vector = Vector2.ZERO
			else:
				shooting = true
				var direction := p - player_pos
				if direction.length() > 8.0:
					aim_dir = direction.normalized()
		else:
			touch_points.erase(event.index)
			if touch_points.is_empty():
				joystick_vector = Vector2.ZERO
				shooting = false
	elif event is InputEventScreenDrag:
		var p := _to_game(event.position)
		touch_points[event.index] = p
		if p.x < ARENA.x * 0.48:
			var offset := p - joystick_origin
			joystick_vector = offset.limit_length(65.0) / 65.0
		else:
			var direction := p - player_pos
			if direction.length() > 8.0:
				aim_dir = direction.normalized()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and game_over:
			_restart()
			return
		if event.pressed:
			var p := _to_game(event.position)
			if p.distance_to(player_pos) > 10.0:
				aim_dir = (p - player_pos).normalized()
			shooting = true
		else:
			shooting = false

func _draw() -> void:
	draw_set_transform(screen_offset, 0.0, Vector2.ONE * screen_scale)
	draw_rect(Rect2(Vector2.ZERO, ARENA), Color("#0b1020"))
	for x in range(0, 961, 40):
		draw_line(Vector2(x, 0), Vector2(x, ARENA.y), Color(0.16, 0.22, 0.34, 0.35), 1.0)
	for y in range(0, 541, 40):
		draw_line(Vector2(0, y), Vector2(ARENA.x, y), Color(0.16, 0.22, 0.34, 0.35), 1.0)
	draw_rect(Rect2(Vector2(5, 5), ARENA - Vector2(10, 10)), Color("#35d9ff"), false, 3.0)

	for bullet in bullets:
		draw_circle(bullet.pos, 5.0, Color("#ffe66d"))
		draw_circle(bullet.pos, 9.0, Color(1.0, 0.9, 0.3, 0.18))
	for enemy in enemies:
		draw_circle(enemy.pos, enemy.radius + 5.0, Color(1.0, 0.2, 0.38, 0.15))
		draw_circle(enemy.pos, enemy.radius, Color("#f04462"))
		draw_circle(enemy.pos + Vector2(-5, -4), 4.0, Color("#ffd6df"))
	draw_line(player_pos, player_pos + aim_dir * 31.0, Color("#ffe66d"), 5.0)
	draw_circle(player_pos, 19.0, Color("#35d9ff"))
	draw_circle(player_pos, 10.0, Color("#e8fbff"))
	draw_circle(player_pos + aim_dir * 8.0, 5.0, Color("#12334a"))

	# HUD
	draw_rect(Rect2(22, 18, 190, 16), Color("#26334d"))
	draw_rect(Rect2(22, 18, 190.0 * health / 100.0, 16), Color("#39e6a5"))
	draw_string(ThemeDB.fallback_font, Vector2(22, 57), "HP %d" % int(health), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(ARENA.x - 170, 39), "SCORE  %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffe66d"))

	# Touch joystick hint
	if not touch_points.is_empty() and joystick_origin != Vector2.ZERO:
		draw_circle(joystick_origin, 43.0, Color(0.4, 0.8, 1.0, 0.16))
		draw_circle(joystick_origin + joystick_vector * 43.0, 17.0, Color(0.5, 0.9, 1.0, 0.7))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(35, ARENA.y - 22), "MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.65, 0.75, 0.9, 0.55))
		draw_string(ThemeDB.fallback_font, Vector2(ARENA.x - 95, ARENA.y - 22), "AIM / FIRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.65, 0.75, 0.9, 0.55))

	if game_over:
		draw_rect(Rect2(Vector2.ZERO, ARENA), Color(0.02, 0.03, 0.07, 0.82))
		draw_string(ThemeDB.fallback_font, Vector2(0, 225), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, ARENA.x, 48, Color("#ff5577"))
		draw_string(ThemeDB.fallback_font, Vector2(0, 270), "Score: %d" % score, HORIZONTAL_ALIGNMENT_CENTER, ARENA.x, 24, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(0, 325), "Tap to play again", HORIZONTAL_ALIGNMENT_CENTER, ARENA.x, 20, Color("#35d9ff"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()

func _restart() -> void:
	player_pos = ARENA * 0.5
	bullets.clear()
	enemies.clear()
	score = 0
	health = 100.0
	game_over = false
	spawn_timer = 0.0
	for i in range(5):
		_spawn_enemy()
