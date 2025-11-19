extends Node2D

# Arkaplan görselleri
@export var bg1_texture: Texture2D = preload("res://bg1.png")
@export var bg2_texture: Texture2D = preload("res://bg2.png")
@export var bg3_texture: Texture2D = preload("res://bg3.png")

# Kamera referansı (kamera ile birlikte hareket etmek için)
@export var camera_path: NodePath = NodePath("../Camera2D")
var camera: Camera2D

# Arkaplan sprite referansı
var background_sprite: Sprite2D

# Zamanlayıcılar
var time_elapsed: float = 0.0
const BG1_DURATION = 10.0  # bg1'in gösterilme süresi (saniye)
const BG2_DURATION = 0.5  # bg2'nin gösterilme süresi (parlama efekti için kısa)
const BG3_DURATION = 0.5  # bg3'ün gösterilme süresi (parlama efekti için kısa)

# Mevcut arkaplan durumu
enum BackgroundState { BG1, BG2, BG3 }
var current_state: BackgroundState = BackgroundState.BG1

# Fade efekti kaldırıldı - anında geçiş

func _ready():
	# Kamera referansını al
	if camera_path:
		camera = get_node_or_null(camera_path) as Camera2D
	
	# Arkaplan sprite'ını bul veya oluştur
	background_sprite = get_node_or_null("BackgroundSprite") as Sprite2D
	if not background_sprite:
		# Eğer yoksa oluştur
		background_sprite = Sprite2D.new()
		background_sprite.name = "BackgroundSprite"
		add_child(background_sprite)
	
	# İlk arkaplanı ayarla (bg1)
	if background_sprite and bg1_texture:
		background_sprite.texture = bg1_texture
		background_sprite.centered = true
		# Arkaplanı ekran boyutuna göre ayarla
		_update_background_size()
		background_sprite.modulate = Color(1, 1, 1, 1)  # Tam opak başla
	
	# Başlangıç pozisyonunu kameraya göre ayarla
	if camera:
		global_position = Vector2(540, camera.global_position.y)

func _process(delta):
	# Kamerayı takip et (kamera ile birlikte hareket et - sadece Y ekseni)
	# X pozisyonu sabit kalır (ekranın ortası)
	if camera:
		global_position = Vector2(540, camera.global_position.y)
	
	time_elapsed += delta
	
	# Arkaplan durumuna göre geçiş yap (anında geçiş)
	match current_state:
		BackgroundState.BG1:
			if time_elapsed >= BG1_DURATION:
				# bg2'ye geç (parlama efekti)
				_change_background(BackgroundState.BG2, bg2_texture)
				time_elapsed = 0.0
		
		BackgroundState.BG2:
			if time_elapsed >= BG2_DURATION:
				# bg3'e geç (parlama efekti)
				_change_background(BackgroundState.BG3, bg3_texture)
				time_elapsed = 0.0
		
		BackgroundState.BG3:
			if time_elapsed >= BG3_DURATION:
				# bg1'e geri dön
				_change_background(BackgroundState.BG1, bg1_texture)
				time_elapsed = 0.0

func _change_background(new_state: BackgroundState, new_texture: Texture2D):
	if not background_sprite or not new_texture:
		return
	
	# Anında geçiş (fade efekti yok)
	current_state = new_state
	
	# Yeni arkaplanı ayarla
	background_sprite.texture = new_texture
	_update_background_size()
	background_sprite.modulate = Color(1, 1, 1, 1)  # Tam opak

func _update_background_size():
	if not background_sprite or not background_sprite.texture:
		return
	
	# Viewport boyutunu al (gerçek ekran boyutu)
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	
	# Arkaplan görselinin boyutunu al
	var texture_size = background_sprite.texture.get_size()
	
	# Ölçeklendirme hesapla (ekranı tamamen kaplayacak şekilde)
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	
	# Daha büyük ölçeği kullan (ekranı tamamen kaplamak için)
	var scale = max(scale_x, scale_y)
	background_sprite.scale = Vector2(scale, scale)
	
	# Arkaplan sprite'ı centered = true olduğu için pozisyon (0, 0) ekranın ortasını temsil eder
	# BackgroundManager'ın pozisyonu kameraya bağlı olduğu için sprite pozisyonu (0, 0) kalabilir
	background_sprite.position = Vector2(0, 0)

