extends Node2D

# Başlangıç zemin görselleri
@export var start1_texture: Texture2D = preload("res://start1.png")
@export var start2_texture: Texture2D = preload("res://start2.png")

# Sprite referansları
var sprite1: Sprite2D
var sprite2: Sprite2D

# Animasyon zamanlayıcısı
var animation_timer: float = 0.0
const ANIMATION_DURATION = 1.0  # 2 saniyede bir değişir
var current_sprite: int = 1  # 1 = start1, 2 = start2

# Görsel ayarları (manuel ayarlanabilir)
@export_group("Görsel Ayarları")
@export var floor_scale: Vector2 = Vector2(0.418, 0.40)  # Görsel ölçeği
@export var start1_x_offset: float = -600.0  # Start1 görselinin X pozisyon offset'i
@export var start1_y_offset: float = -200.0  # Start1 görselinin Y pozisyon offset'i
@export var start2_x_offset: float = -600.0  # Start2 görselinin X pozisyon offset'i
@export var start2_y_offset: float = -215.0  # Start2 görselinin Y pozisyon offset'i

func _ready():
	# Sprite'ları oluştur
	_create_sprites()
	
	# İlk görseli göster
	_switch_sprite()

func _process(delta):
	# Animasyon zamanlayıcısını güncelle
	animation_timer += delta
	
	# 2 saniyede bir görseli değiştir
	if animation_timer >= ANIMATION_DURATION:
		animation_timer = 0.0
		_switch_sprite()

func _create_sprites():
	# Sprite1 oluştur (start1)
	sprite1 = Sprite2D.new()
	sprite1.name = "Sprite1"
	sprite1.texture = start1_texture
	sprite1.centered = false
	sprite1.scale = floor_scale
	sprite1.position = Vector2(start1_x_offset, start1_y_offset)
	sprite1.visible = true
	add_child(sprite1)
	
	# Sprite2 oluştur (start2) - manuel pozisyon
	sprite2 = Sprite2D.new()
	sprite2.name = "Sprite2"
	sprite2.texture = start2_texture
	sprite2.centered = false
	sprite2.scale = floor_scale
	sprite2.position = Vector2(start2_x_offset, start2_y_offset)
	sprite2.visible = false
	add_child(sprite2)

func _switch_sprite():
	# Görselleri değiştir
	if current_sprite == 1:
		current_sprite = 2
		if sprite1:
			sprite1.visible = false
		if sprite2:
			sprite2.visible = true
	else:
		current_sprite = 1
		if sprite1:
			sprite1.visible = true
		if sprite2:
			sprite2.visible = false
