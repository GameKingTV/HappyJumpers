extends Area2D

# Görsel ayarları
@export_group("Görsel Ayarları")
@export var sprite_scale: Vector2 = Vector2(0.1, 0.1)  # Görsel ölçeği (0.05 * 2 = 0.1)
@export var sprite_offset: Vector2 = Vector2(0.0, 0.0)  # Görsel offset'i

# Görsel referansı
var sprite: Sprite2D

# Oyuncu referansı
var player: CharacterBody2D

# Çarpışma mesafesi
const COLLISION_DISTANCE = 30.0  # Coin ve oyuncu arası mesafe

# Oyuncuya sinyal gönder
signal coin_collected

func _ready():
	# Sprite2D'yi bul
	sprite = $Sprite2D
	
	# Coin görselini yükle
	if ResourceLoader.exists("res://coin.png"):
		sprite.texture = load("res://coin.png")
	elif ResourceLoader.exists("res://coin.PNG"):
		sprite.texture = load("res://coin.PNG")
	else:
		# Debug: Coin görseli bulunamadı
		print("Coin görseli bulunamadı: res://coin.png")
	
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
	
	# Manuel çarpışma tespiti - Player'ın pozisyonunu kontrol et
	var distance = global_position.distance_to(player.global_position)
	
	if distance < COLLISION_DISTANCE:
		# Oyuncu coine değdi - sinyal gönder
		coin_collected.emit()
		# Coini yok et
		queue_free()

