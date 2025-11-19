extends Camera2D

# Oyuncu referansı (NodePath veya doğrudan referans)
@export var player_path: NodePath = NodePath("../Player")
var player: CharacterBody2D

# Kameranın ulaştığı en yüksek nokta (en küçük Y değeri)
var min_y_position: float

# Başlangıç kamera ayarları (manuel ayarlanabilir)
@export_group("Başlangıç Kamera Ayarları")
@export var initial_camera_x: float = 540.0  # Başlangıç kamera X pozisyonu
@export var initial_camera_y: float = 1100.0  # Başlangıç kamera Y pozisyonu (daha küçük = daha yukarı)
@export var initial_camera_y_offset: float = 0.0  # Başlangıç kamera Y offset'i (pozitif = aşağı, negatif = yukarı)

# Sürekli yukarı kayma ayarları
@export_group("Sürekli Yukarı Kayma")
@export var base_scroll_speed: float = 50.0  # Temel kamera kayma hızı (piksel/saniye)
@export var scroll_speed_increase_per_score: float = 0.0015  # Her skor puanı için kayma hızı artışı (piksel/saniye)

# Mevcut kayma hızı (skora göre güncellenir)
var current_scroll_speed: float = 50.0

# Game referansı (skor almak için)
var game_node: Node2D = null

func _ready():
	# Kamerayı aktif et
	enabled = true
	
	# Başlangıç pozisyonunu manuel ayarlardan al
	global_position = Vector2(initial_camera_x, initial_camera_y + initial_camera_y_offset)
	min_y_position = global_position.y
	
	# Başlangıç kayma hızını ayarla
	current_scroll_speed = base_scroll_speed
	
	# Game referansını al (skor almak için)
	game_node = get_parent()
	
	# Player referansını al (call_deferred ile bir sonraki frame'de dene)
	call_deferred("_initialize_player")

func _initialize_player():
	# Player referansını al
	player = get_node_or_null(player_path) as CharacterBody2D
	
	# Eğer player bulunamazsa, tekrar dene
	if not player:
		player = get_node_or_null("../Player") as CharacterBody2D
	
	# Başlangıç pozisyonu manuel ayarlardan geldiği için player pozisyonuna göre ayarlama yapmıyoruz
	# Sadece min_y_position'ı güncelle (eğer player daha yukarıdaysa)
	if player:
		var player_y = player.global_position.y
		if player_y < min_y_position:
			min_y_position = player_y
			global_position.y = min_y_position

func _process(delta):
	# Player referansını kontrol et
	if not player:
		player = get_node_or_null(player_path) as CharacterBody2D
		if not player:
			player = get_node_or_null("../Player") as CharacterBody2D
		if not player:
			return
	
	# Kameranın X pozisyonunu ekranın ortasında sabit tut
	var viewport = get_viewport().get_visible_rect()
	global_position.x = viewport.size.x / 2
	
	# Skora göre kayma hızını güncelle
	_update_scroll_speed_from_score()
	
	# Sürekli yukarı kayma: Kamera karakter hareketinden bağımsız olarak yavaşça yukarı kayar
	# Godot'ta Y aşağı doğru arttığı için, yukarı = daha küçük Y değeri
	var scroll_delta = current_scroll_speed * delta
	min_y_position -= scroll_delta  # Yukarı kaymak için Y değerini azaltıyoruz
	
	# Dikey takip: Oyuncunun ulaştığı en yüksek noktayı takip et
	# Ancak asla aşağı inme
	var player_y = player.global_position.y
	if player_y < min_y_position:
		min_y_position = player_y
	
	# Kamerayı güncelle (sürekli yukarı kayma + karakter takibi)
	global_position.y = min_y_position

# Skora göre kayma hızını güncelle
func _update_scroll_speed_from_score():
	# Game referansını kontrol et ve gerekirse yeniden al
	if not game_node or not is_instance_valid(game_node):
		game_node = get_parent()
	
	# Game.gd'den skoru al
	if game_node and game_node.has_method("get_score"):
		var score = game_node.get_score()
		# Kayma hızını doğrusal olarak artır: base_scroll_speed + (score * scroll_speed_increase_per_score)
		current_scroll_speed = base_scroll_speed + (score * scroll_speed_increase_per_score)
	else:
		# Game node bulunamazsa temel hızı kullan
		current_scroll_speed = base_scroll_speed
