extends Node

# Platform sahnesi referansı
@export var platform_scene: PackedScene

# Coin ve Diamond sahne referansları
@export var coin_scene: PackedScene
@export var diamond_scene: PackedScene

# Kamera referansı
@export var camera: Camera2D

# Oyuncu referansı (kamera yükseldikçe platform oluşturmak için)
@export var player_path: NodePath = NodePath("../Player")
var player: CharacterBody2D

# Platform oluşturma ayarları
const PLATFORM_SPACING = 200.0  # Platformlar arası minimum mesafe
const INITIAL_PLATFORM_COUNT = 15  # Başlangıçta oluşturulacak platform sayısı
const PLATFORM_HEIGHT = 40.0  # Platform yüksekliği (2 katı)
const PLATFORMS_AHEAD = 1000.0  # Oyuncunun 1000 piksel üstünde platform olmalı

# Platform genişlik aralığı (rastgele)
const MIN_PLATFORM_WIDTH = 120.0  # Minimum platform genişliği
const MAX_PLATFORM_WIDTH = 360.0  # Maksimum platform genişliği

# Direk sınırları (platformların oluşabileceği alan)
@export_group("Direk Sınırları")
@export var left_pole_x: float = 100.0  # Sol direk X pozisyonu
@export var right_pole_x: float = 1020.0  # Sağ direk X pozisyonu

# Coin ve Diamond oluşturma ayarları
@export_group("Collectible Oluşturma")
@export var coin_spawn_chance: float = 0.75  # Platform üzerinde coin oluşturma şansı (0.0-1.0)
@export var diamond_spawn_chance: float = 0.0025  # Platform üzerinde diamond oluşturma şansı (0.0-1.0)
@export var collectible_height_offset: float = -40.0  # Platform üstünden yukarı offset (negatif = yukarı)

# Duvar pozisyonları (Game.tscn'den alınacak)
var left_wall_x: float
var right_wall_x: float

# Oluşturulan platformların en yüksek Y pozisyonu
var highest_platform_y: float = 0.0

# Oyuncunun ulaştığı en yüksek nokta (platform oluşturma için)
var player_highest_y: float = 0.0

# Ekran dışına çıkan platformları temizlemek için
var platforms: Array = []  # Public - Game.gd'den erişilebilir

func _ready():
	# Duvar pozisyonlarını al (Game.tscn'de duvarlar 50 piksel genişliğinde)
	var viewport = get_viewport().get_visible_rect()
	left_wall_x = 50.0  # Sol duvarın sağ kenarı (iç kenar)
	right_wall_x = viewport.size.x - 50.0  # Sağ duvarın sol kenarı (iç kenar)
	
	# Oyuncu referansını al
	if player_path:
		player = get_node_or_null(player_path) as CharacterBody2D
	
	# Başlangıçta oyuncunun pozisyonunu kaydet
	if player:
		player_highest_y = player.global_position.y
	
	# İlk platformları oluştur
	_create_initial_platforms()

func _process(delta):
	# Oyuncu referansını kontrol et
	if not player:
		if player_path:
			player = get_node_or_null(player_path) as CharacterBody2D
		if not player:
			player = get_node_or_null("../Player") as CharacterBody2D
		if not player:
			return
	
	# Oyuncunun mevcut Y pozisyonunu al
	var current_player_y = player.global_position.y
	
	# Oyuncu yukarı çıktıysa (daha küçük Y değeri), en yüksek noktayı güncelle
	if current_player_y < player_highest_y:
		player_highest_y = current_player_y
		
		# Oyuncunun üstünde yeterince platform yoksa, yeni platformlar oluştur
		# Oyuncunun PLATFORMS_AHEAD piksel üstünde platform olmalı
		var target_y = player_highest_y - PLATFORMS_AHEAD
		
		# Eğer en yüksek platform (en küçük Y değeri), hedef noktanın altındaysa (daha büyük Y değeri)
		# Yani platformlar yeterince yukarıda değilse, yeni platformlar oluştur
		if highest_platform_y > target_y:
			_create_platforms_above(target_y)
	
	# Ekranın çok altına düşen platformları temizle
	if camera:
		_cleanup_platforms()

func _create_initial_platforms():
	# İlk platformları oyuncunun başlangıç pozisyonunun üzerine yerleştir
	# Oyuncu yaklaşık Y=1800'de başlıyor, platformları yukarı doğru oluştur
	# Godot'ta Y aşağı doğru arttığı için, yukarı = daha küçük Y değeri
	var player_start_y = 1800.0  # Oyuncunun başlangıç Y pozisyonu
	var first_platform_y = player_start_y - 200.0  # İlk platform oyuncunun 200 piksel üstünde
	
	for i in range(INITIAL_PLATFORM_COUNT):
		var y_pos = first_platform_y - i * PLATFORM_SPACING
		# Önce X pozisyonunu rastgele seç (direk sınırları içinde)
		# Platform merkezi, sol direkten en az MIN_PLATFORM_WIDTH/2, sağ direkten en az MIN_PLATFORM_WIDTH/2 uzakta olmalı
		var x_pos = randf_range(left_pole_x + MIN_PLATFORM_WIDTH / 1, right_pole_x - MIN_PLATFORM_WIDTH / 0.5)
		# X pozisyonuna göre maksimum platform genişliğini hesapla
		var max_width_for_position = _calculate_max_width_for_position(x_pos)
		# Platform genişliğini hesaplanan maksimum genişlik ve MIN/MAX aralığına göre sınırla
		var random_width = randf_range(MIN_PLATFORM_WIDTH, min(MAX_PLATFORM_WIDTH, max_width_for_position))
		_create_platform(Vector2(x_pos, y_pos), random_width)
	
	# En yüksek platform pozisyonu (en küçük Y değeri)
	highest_platform_y = first_platform_y - (INITIAL_PLATFORM_COUNT - 1) * PLATFORM_SPACING

func _create_platforms_above(target_y: float):
	# Hedef Y pozisyonunun üzerinde platformlar oluştur
	# Sonsuz platform oluşturma - sınır yok
	# Her frame'de maksimum 30 platform oluştur (performans için, ama yeterince agresif)
	var max_per_frame = 30
	var created = 0
	
	# Platform oluşturma döngüsü - hedef noktaya kadar
	while highest_platform_y > target_y and created < max_per_frame:
		highest_platform_y -= PLATFORM_SPACING
		# Önce X pozisyonunu rastgele seç (direk sınırları içinde)
		var x_pos = randf_range(left_pole_x + MIN_PLATFORM_WIDTH / 1, right_pole_x - MIN_PLATFORM_WIDTH / 0.5)
		# X pozisyonuna göre maksimum platform genişliğini hesapla
		var max_width_for_position = _calculate_max_width_for_position(x_pos)
		# Platform genişliğini hesaplanan maksimum genişlik ve MIN/MAX aralığına göre sınırla
		var random_width = randf_range(MIN_PLATFORM_WIDTH, min(MAX_PLATFORM_WIDTH, max_width_for_position))
		_create_platform(Vector2(x_pos, highest_platform_y), random_width)
		created += 1

func _create_platform(position: Vector2, width: float):
	if not platform_scene:
		return
	
	# Platformun sol ve sağ kenarlarının direk sınırlarını geçmediğinden emin ol
	var platform_left = position.x - width / 2.0
	var platform_right = position.x + width / 2.0
	
	# Eğer platform sınırları geçiyorsa, pozisyonu veya genişliği ayarla
	if platform_left < left_pole_x:
		# Sol kenar sol direğin solunda, pozisyonu sağa kaydır
		position.x = left_pole_x + width / 2.0
	elif platform_right > right_pole_x:
		# Sağ kenar sağ direğin sağında, pozisyonu sola kaydır
		position.x = right_pole_x - width / 2.0
	
	var platform = platform_scene.instantiate()
	platform.global_position = position
	# Platform genişliğini ayarla (add_child'den önce)
	platform.platform_width = width
	add_child(platform)
	# _ready() çağrıldıktan sonra genişliği güncelle
	if platform.has_method("set_platform_width"):
		platform.set_platform_width(width)
	platforms.append(platform)
	
	# Platform üzerinde coin veya diamond oluşturma şansı
	# Platform eklendikten sonra _ready() çağrıldı, collision shape pozisyonu hesaplandı
	# Coin oluştururken collision'un merkezini almak için platform referansını kullan
	_spawn_collectible_on_platform(platform, position, width)

func _cleanup_platforms():
	if not camera:
		return
	
	var viewport = get_viewport().get_visible_rect()
	var cleanup_y = camera.global_position.y + viewport.size.y + 500  # Ekranın 500 piksel altı
	
	# Ekranın çok altına düşen platformları sil
	for i in range(platforms.size() - 1, -1, -1):
		if platforms[i] and platforms[i].global_position.y > cleanup_y:
			platforms[i].queue_free()
			platforms.remove_at(i)

# Platform üzerinde coin veya diamond oluştur
func _spawn_collectible_on_platform(platform_node: Node2D, platform_position: Vector2, platform_width: float):
	# Rastgele coin veya diamond oluşturma şansı
	var random_value = randf()
	
	# Diamond öncelikli (daha nadir)
	if random_value < diamond_spawn_chance and diamond_scene:
		_create_collectible(platform_node, platform_position, platform_width, diamond_scene, "diamond")
	elif random_value < (coin_spawn_chance + diamond_spawn_chance) and coin_scene:
		_create_collectible(platform_node, platform_position, platform_width, coin_scene, "coin")

# Collectible (coin veya diamond) oluştur
func _create_collectible(platform_node: Node2D, platform_position: Vector2, platform_width: float, collectible_scene: PackedScene, type: String):
	# Coin için: Platformun collision'unun tam ortasında oluştur
	# Diamond için: Rastgele pozisyon (efekt için)
	var collectible_x: float
	var collectible_y: float
	
	if type == "coin":
		# Coin platformun collision'unun tam ortasında
		# Platform'un collision shape'inin merkez pozisyonunu al
		var collision_center_x = platform_position.x
		var collision_center_y = platform_position.y
		
		# Platform node'unun collision shape'ini kontrol et
		if platform_node and platform_node.has_node("CollisionShape2D"):
			var collision_shape = platform_node.get_node("CollisionShape2D") as CollisionShape2D
			if collision_shape:
				var shape = collision_shape.shape as RectangleShape2D
				if shape:
					# Collision shape'in pozisyonu platform node'una göre offset'lenmiş
					# Godot'ta RectangleShape2D için position merkezi temsil eder
					# Collision shape'in global merkezi = platform.global_position + collision_shape.position
					collision_center_x = platform_position.x + collision_shape.position.x
					collision_center_y = platform_position.y + collision_shape.position.y
		
		collectible_x = collision_center_x
		collectible_y = collision_center_y + collectible_height_offset
	else:
		# Diamond için rastgele pozisyon (platform genişliği içinde)
		var margin = 20.0
		collectible_x = randf_range(
			platform_position.x - platform_width / 2.0 + margin,
			platform_position.x + platform_width / 2.0 - margin
		)
		collectible_y = platform_position.y + collectible_height_offset
	
	# Collectible oluştur
	var collectible = collectible_scene.instantiate()
	collectible.global_position = Vector2(collectible_x, collectible_y)
	
	# Player referansını ver
	if player:
		if collectible.has_method("set_player"):
			collectible.set_player(player)
		elif "player" in collectible:
			collectible.player = player
	
	# Sinyal bağlantısı (eğer varsa)
	if type == "coin" and collectible.has_signal("coin_collected"):
		collectible.coin_collected.connect(_on_coin_collected)
	elif type == "diamond" and collectible.has_signal("diamond_collected"):
		collectible.diamond_collected.connect(_on_diamond_collected)
	
	add_child(collectible)

# Coin toplandığında çağrılır
func _on_coin_collected():
	# Game.gd'den skor artırma veya başka bir şey yapılabilir
	var game_node = get_parent()
	if game_node and game_node.has_method("on_coin_collected"):
		game_node.on_coin_collected()

# Diamond toplandığında çağrılır
func _on_diamond_collected():
	# Game.gd'den skor artırma veya başka bir şey yapılabilir
	var game_node = get_parent()
	if game_node and game_node.has_method("on_diamond_collected"):
		game_node.on_diamond_collected()

# Belirli bir X pozisyonu için maksimum platform genişliğini hesapla
func _calculate_max_width_for_position(x_pos: float) -> float:
	# Platform'un merkezi = x_pos
	# Platform'un sol kenarı = x_pos - platform_width / 2
	# Platform'un sağ kenarı = x_pos + platform_width / 2
	
	# Sol kenarın sol direğe kadar gidebileceği mesafe (sol kenar left_pole_x'den küçük olamaz)
	var max_left_distance = x_pos - left_pole_x
	# Sağ kenarın sağ direğe kadar gidebileceği mesafe (sağ kenar right_pole_x'den büyük olamaz)
	var max_right_distance = right_pole_x - x_pos
	
	# Maksimum genişlik = min(sol mesafe, sağ mesafe) * 2
	# (çünkü platform merkezden her iki yöne eşit uzaklıkta genişler)
	var max_width = min(max_left_distance, max_right_distance) * 2.0
	
	# Negatif olamaz ve minimum genişlikten küçük olamaz
	return max(max_width, MIN_PLATFORM_WIDTH)
