extends StaticBody2D

# Platform görsel ve collision ayarları (manuel ayarlanabilir)
@export_group("Platform Görsel Ayarları")
@export var platform_scale: Vector2 = Vector2(0.2, 0.2)  # Platform görsel ölçeği (2 katı = 0.2)
@export var platform_sprite_offset: Vector2 = Vector2(0, -20)  # Platform görsel offset'i (2 katı)

@export_group("Platform Collision Ayarları")
@export var platform_width: float = 200.0  # Platform collision genişliği (2 katı)
@export var platform_height: float = 40.0  # Platform collision yüksekliği (2 katı)
@export var platform_collision_x_offset: float = 0.0 # Platform collision X pozisyon offset'i (pozitif = sağa, negatif = sola)
@export var platform_collision_y_offset: float = 0.0  # Platform collision Y pozisyon offset'i (pozitif = aşağı, negatif = yukarı)
@export var show_collision_debug: bool = false  # Collision shape'i görünür yap (debug için)

func _ready():
	# Platform genişliğini ve görselini ayarla
	_update_platform_size()
	
	# Collision debug görselini oluştur
	_create_collision_debug()
	
	# VisibleOnScreenNotifier2D'nin screen_exited sinyalini bağla
	var notifier = $VisibleOnScreenNotifier2D
	if notifier:
		notifier.screen_exited.connect(_on_screen_exited)

# Platform genişliğini ve görselini güncelle
func _update_platform_size():
	# Görsel ayarlarını uygula - genişliğe göre ölçekle
	var sprite = $Sprite2D as Sprite2D
	
	if sprite and sprite.texture:
		# Orijinal texture genişliğini al
		var original_texture_width = sprite.texture.get_width()
		# Platform genişliğine göre yeni X ölçeğini hesapla
		# platform_width / original_texture_width = yeni X ölçeği
		var new_scale_x = platform_width / original_texture_width
		# Y ölçeğini platform_scale'den al (değişmez)
		sprite.scale = Vector2(new_scale_x, platform_scale.y)
		sprite.offset = platform_sprite_offset
	
	# Collision shape ayarlarını uygula
	var collision_shape = $CollisionShape2D as CollisionShape2D
	if collision_shape:
		var shape = collision_shape.shape as RectangleShape2D
		if shape:
			# Collision shape genişliği platform genişliğiyle aynı olmalı
			shape.size = Vector2(platform_width, platform_height)
			
			# Collision shape pozisyonunu hesapla
			# Sprite centered=false olduğu için sol üst köşesi (0,0) + offset'te başlıyor
			if sprite and sprite.texture:
				# Sprite'ın görsel boyutları
				var sprite_visual_width = sprite.texture.get_width() * sprite.scale.x
				var sprite_visual_height = sprite.texture.get_height() * sprite.scale.y
				
				# X pozisyonu: Collision shape sprite'ın merkezinde olmalı
				# Sprite centered=false olduğu için merkezi = görsel genişliği / 2
				# Collision shape'in merkezi sprite'ın merkezinde olmalı
				# Collision shape pozisyonu = sprite merkezi - collision genişliği / 2
				var sprite_center_x = sprite_visual_width / 1.9
				var collision_x = sprite_center_x - (platform_width / 25)
				
				# Y pozisyonu: Collision shape platformun üst yüzeyinde olmalı
				# Sprite centered=false, offset=(0, -20) olduğu için:
				# - Sprite'ın üst kenarı: offset.y = -20
				# - Sprite'ın alt kenarı: offset.y + sprite_visual_height
				# One-way collision için: Collision shape'in üst kenarı sprite'ın görsel üst yüzeyinde olmalı
				# Karakter yukarıdan aşağı düşerken bu yüzeye değdiğinde platformu algılamalı
				# Collision shape'in üst kenarı = sprite üst kenarı (veya biraz altında)
				# Collision shape pozisyonu (merkez) = sprite üst kenarı + collision_height/2
				var sprite_top = platform_sprite_offset.y
				# Collision shape'in üst kenarı sprite'ın üst kenarıyla hizalanmalı
				var collision_top = sprite_top
				# Collision shape'in merkezi = üst kenar + yükseklik/2
				var collision_y = collision_top + (platform_height / 2.0)
				
				# Manuel offset'leri ekle
				collision_shape.position = Vector2(collision_x + platform_collision_x_offset, collision_y + platform_collision_y_offset)
			else:
				# Fallback: eski yöntem
				collision_shape.position = Vector2(platform_collision_x_offset, platform_collision_y_offset)
		
		# Collision debug görselini güncelle
		_update_collision_debug()

# Collision debug görselini oluştur
func _create_collision_debug():
	if not show_collision_debug:
		return
	
	# Eğer zaten varsa sil
	var existing_debug = get_node_or_null("CollisionDebug")
	if existing_debug:
		existing_debug.queue_free()
	
	# Polygon2D oluştur (collision shape'i göstermek için)
	var debug_polygon = Polygon2D.new()
	debug_polygon.name = "CollisionDebug"
	debug_polygon.color = Color(1.0, 0.0, 0.0, 0.5)  # Yarı saydam kırmızı
	add_child(debug_polygon)

# Collision debug görselini güncelle
func _update_collision_debug():
	if not show_collision_debug:
		return
	
	var debug_polygon = get_node_or_null("CollisionDebug")
	if not debug_polygon:
		return
	
	var collision_shape = $CollisionShape2D as CollisionShape2D
	if collision_shape:
		var shape = collision_shape.shape as RectangleShape2D
		if shape:
			# Collision shape'in pozisyonunu ve boyutunu al
			var collision_pos = collision_shape.position
			var collision_size = shape.size
			
			# Dikdörtgenin köşelerini hesapla (merkezden)
			var half_width = collision_size.x / 2.0
			var half_height = collision_size.y / 2.0
			
			# Dikdörtgen köşeleri (sol üst, sağ üst, sağ alt, sol alt)
			var points = [
				collision_pos + Vector2(-half_width, -half_height),  # Sol üst
				collision_pos + Vector2(half_width, -half_height),   # Sağ üst
				collision_pos + Vector2(half_width, half_height),     # Sağ alt
				collision_pos + Vector2(-half_width, half_height)     # Sol alt
			]
			
			debug_polygon.polygon = points

# Platform genişliğini dışarıdan ayarlamak için fonksiyon
func set_platform_width(width: float):
	platform_width = width
	_update_platform_size()

func _on_screen_exited():
	# Ekran dışına çıktığında platformu sil
	# Not: PlatformManager zaten temizleme yapıyor, bu ekstra güvenlik
	queue_free()
