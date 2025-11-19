extends Area2D

# Güç tipleri
enum PowerType {
	MOR,      # Mor Daire - 5 kat zıplama (tek seferlik)
	KIRMIZI,  # Kırmızı Daire - 3 platform boyunca 2 kat zıplama
	PEMBE     # Pembe Daire - 1 kere ölümden kurtulma
}

# Bu gücün tipi
@export var power_type: PowerType = PowerType.MOR

# Görsel ayarları (manuel ayarlanabilir)
@export_group("Görsel Ayarları")
@export var sprite_scale: Vector2 = Vector2(0.5, 0.5)  # Görsel ölçeği
@export var sprite_offset: Vector2 = Vector2(0.0, 0.0)  # Görsel offset'i

# Görsel referansları
var sprite: Sprite2D

# Oyuncu referansı
var player: CharacterBody2D

# Çarpışma mesafesi
const COLLISION_DISTANCE = 50.0  # Güç ve oyuncu arası mesafe (Player 40x40, PowerUp 60x60)

# Oyuncuya sinyal gönder
signal power_collected(power_type: PowerType)

func _ready():
	# Sprite2D'yi bul
	sprite = $Sprite2D
	
	# Güç tipine göre texture'ı yükle
	match power_type:
		PowerType.MOR:
			if ResourceLoader.exists("res://morguc.png"):
				sprite.texture = load("res://morguc.png")
		PowerType.KIRMIZI:
			if ResourceLoader.exists("res://kirmiziguc.png"):
				sprite.texture = load("res://kirmiziguc.png")
		PowerType.PEMBE:
			if ResourceLoader.exists("res://pembeguc.png"):
				sprite.texture = load("res://pembeguc.png")
	
	# Görsel ayarlarını uygula
	sprite.scale = sprite_scale
	sprite.position = sprite_offset
	
	# Player'ı bul (PowerUpManager'dan geçirilmiş olabilir)
	# PowerUpManager Game'in altında, Player da Game'in altında
	# Yani PowerUp -> PowerUpManager -> Game -> Player
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
	
	# Debug: Çarpışma kontrolü (sadece yakınsa)
	if distance < COLLISION_DISTANCE * 2:
		print("PowerUp çarpışma kontrolü: Mesafe=", distance, " Limit=", COLLISION_DISTANCE)
	
	if distance < COLLISION_DISTANCE:
		# Oyuncu güce değdi - sinyal gönder
		print("PowerUp toplandı! Tip=", power_type)
		power_collected.emit(power_type)
		# Gücü yok et
		queue_free()
