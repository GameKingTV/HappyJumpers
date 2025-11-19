extends Area2D

# Görsel ayarları
@export_group("Görsel Ayarları")
@export var sprite_scale: Vector2 = Vector2(0.3, 0.3)  # Görsel ölçeği (0.15 * 2 = 0.3)
@export var sprite_offset: Vector2 = Vector2(0.0, 0.0)  # Görsel offset'i

# Görsel referansı
var sprite: Sprite2D

# Diamond görselleri
var texture_dia1: Texture2D
var texture_dia2: Texture2D

# Animasyon ayarları
var animation_timer: float = 0.0
const ANIMATION_INTERVAL: float = 0.4  # 0.4 saniye aralıklarla değişim
var current_texture_index: int = 0  # 0 = dia1, 1 = dia2

# Oyuncu referansı
var player: CharacterBody2D

# Çarpışma mesafesi
const COLLISION_DISTANCE = 30.0  # Diamond ve oyuncu arası mesafe

# Oyuncuya sinyal gönder
signal diamond_collected

func _ready():
	# Sprite2D'yi bul
	sprite = $Sprite2D
	
	# Diamond görsellerini yükle
	if ResourceLoader.exists("res://dia1.png"):
		texture_dia1 = load("res://dia1.png")
	elif ResourceLoader.exists("res://dia1.PNG"):
		texture_dia1 = load("res://dia1.PNG")
	
	if ResourceLoader.exists("res://dia2.png"):
		texture_dia2 = load("res://dia2.png")
	elif ResourceLoader.exists("res://dia2.PNG"):
		texture_dia2 = load("res://dia2.PNG")
	
	# İlk görseli ayarla
	if texture_dia1:
		sprite.texture = texture_dia1
		current_texture_index = 0
	else:
		print("Diamond görseli bulunamadı: res://dia1.png")
	
	# Görsel ayarlarını uygula
	sprite.scale = sprite_scale
	sprite.position = sprite_offset
	
	# Player'ı bul
	if not player:
		player = get_node_or_null("../../Player") as CharacterBody2D

func _process(delta):
	# Player referansını kontrol et
	if not player:
		player = get_node_or_null("../../Player") as CharacterBody2D
		if not player:
			return
	
	# Diamond görsel animasyonu (dia1 ve dia2 arasında 0.4 saniye aralıklarla)
	if texture_dia1 and texture_dia2:
		animation_timer += delta
		if animation_timer >= ANIMATION_INTERVAL:
			animation_timer = 0.0
			# Görseli değiştir
			current_texture_index = 1 - current_texture_index  # 0 <-> 1 arasında değiş
			if current_texture_index == 0:
				sprite.texture = texture_dia1
			else:
				sprite.texture = texture_dia2
	
	# Manuel çarpışma tespiti - Player'ın pozisyonunu kontrol et
	var distance = global_position.distance_to(player.global_position)
	
	if distance < COLLISION_DISTANCE:
		# Oyuncu diamonda değdi - sinyal gönder
		diamond_collected.emit()
		# Diamond'ı yok et
		queue_free()

