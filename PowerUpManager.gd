extends Node

# Güç sahnesi referansı
@export var power_up_scene: PackedScene

# Kamera referansı
@export var camera_path: NodePath = NodePath("../Camera2D")
var camera: Camera2D

# Oyuncu referansı
@export var player_path: NodePath = NodePath("../Player")
var player: CharacterBody2D

# Oluşturma sıklığı ayarları (0.0 - 1.0 arası, 1.0 = her zaman, 0.0 = hiç)
@export var spawn_frequency: float = 0.001  # Güç oluşturma şansı
@export var spawn_interval: float = 200.0  # Her 200 piksel yukarı çıkınca kontrol et

# Platform referansı (güçleri platformların yakınına yerleştirmek için)
@export var platform_manager_path: NodePath = NodePath("../PlatformManager")
var platform_manager: Node

# Oluşturulan güçler
var power_ups: Array = []

# Son güç oluşturulma pozisyonu (kamera bazlı)
var last_spawn_camera_y: float = 0.0

func _ready():
	# Referansları al
	if player_path:
		player = get_node_or_null(player_path) as CharacterBody2D
	if platform_manager_path:
		platform_manager = get_node_or_null(platform_manager_path)
	if camera_path:
		camera = get_node_or_null(camera_path) as Camera2D
	
	# Başlangıç pozisyonunu ayarla
	if camera:
		last_spawn_camera_y = camera.global_position.y

func _process(delta):
	# Player referansını kontrol et
	if not player:
		if player_path:
			player = get_node_or_null(player_path) as CharacterBody2D
		if not player:
			player = get_node_or_null("../Player") as CharacterBody2D
	
	# Kamera referansını kontrol et
	if not camera:
		if camera_path:
			camera = get_node_or_null(camera_path) as Camera2D
		if not camera:
			camera = get_node_or_null("../Camera2D") as Camera2D
	
	if not camera or not power_up_scene:
		return
	
	# Kameranın mevcut Y pozisyonunu al
	var current_camera_y = camera.global_position.y
	
	# Kamera yukarı çıktıkça güç oluşturma şansını kontrol et
	if current_camera_y < last_spawn_camera_y - spawn_interval:
		# Rastgele güç oluşturma şansı
		if randf() < spawn_frequency:
			# Güç oluştur
			_spawn_power_up()
			last_spawn_camera_y = current_camera_y
	
	# Ekranın çok altına düşen güçleri temizle
	_cleanup_power_ups()

func _spawn_power_up():
	if not camera:
		return
	
	# Kameranın görüş alanını al
	var viewport = get_viewport().get_visible_rect()
	var camera_top = camera.global_position.y - viewport.size.y / 2
	var camera_bottom = camera.global_position.y + viewport.size.y / 2
	
	# Duvar pozisyonlarını al (güçler duvarların içinde olmalı)
	var left_wall_x = 50.0  # Sol duvarın sağ kenarı
	var right_wall_x = viewport.size.x - 50.0  # Sağ duvarın sol kenarı
	
	# Rastgele X pozisyonu (duvarlar arasında)
	var random_x = randf_range(left_wall_x + 30.0, right_wall_x - 30.0)
	
	# Rastgele Y pozisyonu (kameranın ÜST bölgesinde, görüş alanının dışında)
	# Kameranın görüş alanının üstünde, 1-2 ekran yüksekliği kadar yukarıda oluştur
	var spawn_top = camera_top - viewport.size.y * 1.5  # Kameranın 1.5 ekran yukarısı
	var spawn_bottom = camera_top - viewport.size.y * 0.2  # Kameranın 0.2 ekran yukarısı
	var random_y = randf_range(spawn_top, spawn_bottom)
	
	# Güç pozisyonu
	var power_up_pos = Vector2(random_x, random_y)
	
	# Güç tipini rastgele seç
	var power_type = randi() % 3  # 0: Mor, 1: Kırmızı, 2: Pembe
	
	# Güç oluştur
	var power_up = power_up_scene.instantiate()
	power_up.power_type = power_type
	power_up.global_position = power_up_pos
	# Player referansını güce ver
	if player:
		power_up.player = player
	power_up.power_collected.connect(_on_power_collected)
	add_child(power_up)
	power_ups.append(power_up)
	
	# Debug: Güç oluşturuldu
	print("PowerUp oluşturuldu: Tip=", power_type, " Pozisyon=", power_up_pos)

func _on_power_collected(power_type: int):
	# Oyuncuya güç ver
	if not player:
		if player_path:
			player = get_node_or_null(player_path) as CharacterBody2D
	
	if player:
		player.apply_power(power_type)

func _cleanup_power_ups():
	if not camera:
		return
	
	var viewport = get_viewport().get_visible_rect()
	var cleanup_y = camera.global_position.y + viewport.size.y + 500
	
	# Ekranın çok altına düşen güçleri sil
	for i in range(power_ups.size() - 1, -1, -1):
		if power_ups[i] and power_ups[i].global_position.y > cleanup_y:
			power_ups[i].queue_free()
			power_ups.remove_at(i)
