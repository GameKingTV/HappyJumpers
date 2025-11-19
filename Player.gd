extends CharacterBody2D

# Fizik sabitleri
const BASE_SPEED = 800.0  # Temel yatay hareket hızı
const BASE_JUMP_VELOCITY = -1900.0  # Temel zıplama gücü (negatif çünkü Y aşağı doğru artar)
const BASE_GRAVITY = 3500.0  # Temel yerçekimi kuvveti

# Skor bazlı fizik artışı
const SPEED_INCREASE_PER_SCORE = 0.00039  # Her skor puanı için hız artışı (piksel/saniye)
const JUMP_INCREASE_PER_SCORE = -0.00411  # Her skor puanı için zıplama artışı (piksel/saniye)
const GRAVITY_INCREASE_PER_SCORE = 0.0041  # Her skor puanı için yerçekimi artışı (piksel/saniye²)

# Mevcut fizik değerleri (skora göre güncellenir)
var current_speed: float = BASE_SPEED  # Mevcut hız
var current_jump_velocity: float = BASE_JUMP_VELOCITY  # Mevcut zıplama gücü
var current_gravity: float = BASE_GRAVITY  # Mevcut yerçekimi

# Ekran genişliğini tutmak için
var screen_width: float

# Dokunma durumu
var touch_position: Vector2 = Vector2.ZERO
var is_touching: bool = false

# Platform geçiş takibi
var was_on_floor: bool = false

# Sprite ve animasyon referansları
@onready var sprite: Sprite2D = $Sprite2D

# Görsel durumları
enum SpriteState {
	IDLE,      # Normal duruş
	JUMP,      # Zıplama
	RIGHT,     # Sağa dönüş
	FALL,      # Düşme
	LEFT,      # Sola dönüş
	GLIDE      # Süzülme
}

var current_state: SpriteState = SpriteState.IDLE
var facing_direction: int = 1  # 1 = sağ, -1 = sol
var jump_animation_timer: float = 0.0
const JUMP_ANIMATION_DURATION = 0.15

# Görsel texture'ları
var texture_idle: Texture2D
var texture_jump: Texture2D
var texture_right: Texture2D
var texture_fall: Texture2D
var texture_left: Texture2D
var texture_glide: Texture2D

# Güç sistemi
enum PowerType {
	MOR = 0,      # Mor Daire - 5 kat zıplama (tek seferlik)
	KIRMIZI = 1,  # Kırmızı Daire - 3 platform boyunca 2 kat zıplama
	PEMBE = 2     # Pembe Daire - 1 kere ölümden kurtulma
}

var mor_power_active: bool = false  # Mor güç aktif mi (tek seferlik)
var kirmizi_power_active: bool = false  # Kırmızı güç aktif mi
var kirmizi_platform_count: int = 0  # Kırmızı güç için geçilen platform sayısı
var pembe_power_active: bool = false  # Pembe güç aktif mi (sekme hakkı)
var pembe_used: bool = false  # Pembe güç kullanıldı mı

# Normal zıplama gücü (temel değer, skora göre güncellenecek)
var base_jump_velocity: float = BASE_JUMP_VELOCITY

# Game referansı (skor almak için)
var game_node: Node2D = null

# Collision debug görseli
@export var show_collision_debug: bool = false  # Collision shape'i görünür yap (debug için)

# Oyun bittiğinde sinyal göndermek için
signal game_over

# Platform geçildiğinde sinyal gönder
signal platform_passed

func _ready():
	# Ekran genişliğini al
	screen_width = get_viewport().get_visible_rect().size.x
	
	# Game referansını al (Game, Player'ın parent'ı)
	game_node = get_parent()
	
	# Başlangıç fizik değerlerini ayarla
	base_jump_velocity = BASE_JUMP_VELOCITY
	current_jump_velocity = BASE_JUMP_VELOCITY
	current_gravity = BASE_GRAVITY
	current_speed = BASE_SPEED
	
	# VisibleOnScreenNotifier2D'nin screen_exited sinyalini bağla
	var notifier = $VisibleOnScreenNotifier2D
	if notifier:
		notifier.screen_exited.connect(_on_screen_exited)
	
	# Sprite referansını al
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	
	# Collision debug görselini oluştur
	_create_collision_debug()
	
	# Texture'ları yükle
	_load_textures()
	
	# Başlangıç durumunu ayarla
	_update_sprite_state(SpriteState.IDLE)

func _input(event):
	# Mobil dokunma kontrolü
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_position = event.position
			is_touching = true
		else:
			is_touching = false
	# Mouse kontrolü (test için)
	elif event is InputEventMouseButton:
		if event.pressed:
			touch_position = event.position
			is_touching = true
		else:
			is_touching = false
	# Mouse hareketi (sürükleme)
	elif event is InputEventMouseMotion and is_touching:
		touch_position = event.position

func _physics_process(delta):
	# Yerçekimi uygula (skora göre artmış yerçekimi)
	if not is_on_floor():
		velocity.y += current_gravity * delta
	
	# Skora göre fizik değerlerini güncelle (hız, zıplama, yerçekimi)
	_update_physics_from_score()
	
	# Mobil kontrol: Ekranın sol yarısına dokunulursa sola, sağ yarısına dokunulursa sağa
	# Alternatif: Klavye kontrolü (test için)
	var move_direction = 0
	if Input.is_action_pressed("move_left"):
		velocity.x = -current_speed
		move_direction = -1
	elif Input.is_action_pressed("move_right"):
		velocity.x = current_speed
		move_direction = 1
	elif is_touching:
		# Ekranın sol yarısına dokunulduysa sola, sağ yarısına dokunulduysa sağa
		var viewport = get_viewport().get_visible_rect()
		var center_x = viewport.size.x / 2
		if touch_position.x < center_x:
			velocity.x = -current_speed
			move_direction = -1
		else:
			velocity.x = current_speed
			move_direction = 1
	else:
		# Dokunulmuyorsa yavaşça dur
		velocity.x = move_toward(velocity.x, 0, current_speed * 2 * delta)
	
	# Yön güncelle
	if move_direction != 0:
		facing_direction = move_direction
	
	# Platform geçiş tespiti
	var current_on_floor = is_on_floor()
	
	# Eğer bir önceki frame'de floor'daydık ve şimdi floor'da değilsek, platformu geçtik
	# (Oyuncu platformun üzerinden zıpladı ve artık platformun üzerinde değil)
	if was_on_floor and not current_on_floor:
		# Platformu geçtik - sinyal gönder
		platform_passed.emit()
		
		# Kırmızı güç takibi: Platform geçildiğinde sayacı artır
		if kirmizi_power_active:
			kirmizi_platform_count += 1
			# 3 platform geçildiyse kırmızı gücü kapat
			if kirmizi_platform_count >= 3:
				kirmizi_power_active = false
				kirmizi_platform_count = 0
	
	# Zıplama kontrolü: Icy Tower tarzı otomatik zıplama
	# Platformun üzerindeyken otomatik zıpla (Icy Tower mekaniği)
	if is_on_floor():
		# Zıplama gücünü hesapla (skora göre artmış zıplama)
		var jump_power = current_jump_velocity
		var is_special_power = false
		
		# Kırmızı güç aktifse 2.5 kat zıpla (özel güç)
		if kirmizi_power_active:
			jump_power = current_jump_velocity * 2.5
			is_special_power = true
		
		# Otomatik zıplama - platforma değdiğinde hemen zıpla
		velocity.y = jump_power
		
		# Animasyon: Özel güç varsa GLIDE, yoksa JUMP
		if is_special_power:
			_update_sprite_state(SpriteState.GLIDE)
		else:
			# Normal zıplama animasyonunu başlat
			jump_animation_timer = JUMP_ANIMATION_DURATION
			_update_sprite_state(SpriteState.JUMP)
	
	# Zıplama animasyonu zamanlayıcısını güncelle
	if jump_animation_timer > 0:
		jump_animation_timer -= delta
	
	# Sprite durumunu güncelle
	_update_sprite_state_based_on_physics()
	
	# Collision debug görselini güncelle
	_update_collision_debug()
	
	# Hareketi uygula
	move_and_slide()
	
	# Bir sonraki frame için durumu kaydet
	was_on_floor = current_on_floor

func _on_screen_exited():
	# Oyuncu ekran dışına çıktığında (aşağı düştüğünde)
	# Pembe güç aktifse ve kullanılmadıysa, ölümden kurtul
	if pembe_power_active and not pembe_used:
		pembe_used = true
		pembe_power_active = false  # Gücü kullan
		# Oyuncuyu yukarı fırlat (sekme efekti - skora göre artmış)
		velocity.y = current_jump_velocity * 0.8
		# Pozisyonu biraz yukarı al
		global_position.y -= 100.0
	else:
		# Pembe güç yoksa veya kullanıldıysa oyun biter
		game_over.emit()

# Güç uygula (PowerUpManager'dan çağrılır)
func apply_power(power_type: int):
	match power_type:
		PowerType.MOR:
			# Mor güç: 5 kat zıplama (tek seferlik) - HEMEN zıpla, platforma değmeyi bekleme (skora göre artmış)
			var jump_power = current_jump_velocity * 5.0
			velocity.y = jump_power
			# Özel güç ile zıpladığı için GLIDE animasyonu
			_update_sprite_state(SpriteState.GLIDE)
			# Mor güç tek seferlik kullanıldı, aktif etme
			mor_power_active = false
		PowerType.KIRMIZI:
			# Kırmızı güç: 3 platform boyunca 2 kat zıplama
			kirmizi_power_active = true
			kirmizi_platform_count = 0
		PowerType.PEMBE:
			# Pembe güç: 1 kere ölümden kurtulma
			pembe_power_active = true
			pembe_used = false

# Texture'ları yükle
func _load_textures():
	# Texture dosyalarını yükle (eğer yoksa null kalır, hata vermez)
	if ResourceLoader.exists("res://player_idle.png"):
		texture_idle = load("res://player_idle.png") as Texture2D
	if ResourceLoader.exists("res://player_jump.png"):
		texture_jump = load("res://player_jump.png") as Texture2D
	if ResourceLoader.exists("res://player_right.png"):
		texture_right = load("res://player_right.png") as Texture2D
	if ResourceLoader.exists("res://player_fall.png"):
		texture_fall = load("res://player_fall.png") as Texture2D
	if ResourceLoader.exists("res://player_left.png"):
		texture_left = load("res://player_left.png") as Texture2D
	if ResourceLoader.exists("res://player_glide.png"):
		texture_glide = load("res://player_glide.png") as Texture2D
	
	# Eğer hiç texture yüklenmediyse, varsayılan olarak idle kullan
	if not texture_idle and ResourceLoader.exists("res://player_idle.png"):
		texture_idle = load("res://player_idle.png") as Texture2D

# Sprite durumunu güncelle (fizik durumuna göre)
func _update_sprite_state_based_on_physics():
	if not sprite:
		return
	
	# Yerdeyse
	if is_on_floor():
		# Zıplama animasyonu aktifse, devam et
		if jump_animation_timer > 0:
			return
		_update_sprite_state(SpriteState.IDLE)
		return
	
	# Havadaysa - animasyon mantığı:
	# 1. Düşerken → FALL
	# 2. Normal zıplama animasyonu aktifse → JUMP
	# 3. Özel güçlerle zıpladıysa → GLIDE
	# 4. Yükselirken normal zıplamada → JUMP (RIGHT/LEFT yok)
	
	# Düşerken (aşağı doğru hareket)
	if velocity.y > 0:
		_update_sprite_state(SpriteState.FALL)
		return
	
	# Yükselirken (yukarı doğru hareket)
	if velocity.y < 0:
		# Normal zıplama animasyonu aktifse JUMP göster
		if jump_animation_timer > 0:
			_update_sprite_state(SpriteState.JUMP)
			return
		
		# Özel güçlerle zıpladıysa GLIDE göster
		# Kırmızı güç aktifse veya çok hızlı yükseliyorsa (mor güç gibi)
		if kirmizi_power_active or velocity.y < current_jump_velocity * 3.0:
			_update_sprite_state(SpriteState.GLIDE)
			return
		
		# Normal yükselme durumunda JUMP göster (RIGHT/LEFT değil)
		_update_sprite_state(SpriteState.JUMP)

# Sprite durumunu ayarla
func _update_sprite_state(state: SpriteState):
	if not sprite:
		return
	
	current_state = state
	
	# Texture'ı duruma göre ayarla
	match state:
		SpriteState.IDLE:
			if texture_idle:
				sprite.texture = texture_idle
		SpriteState.JUMP:
			if texture_jump:
				sprite.texture = texture_jump
		SpriteState.RIGHT:
			if texture_right:
				sprite.texture = texture_right
			sprite.scale.x = abs(sprite.scale.x)  # Sağa bak
		SpriteState.FALL:
			if texture_fall:
				sprite.texture = texture_fall
		SpriteState.LEFT:
			if texture_left:
				sprite.texture = texture_left
			sprite.scale.x = -abs(sprite.scale.x)  # Sola bak (flip)
		SpriteState.GLIDE:
			if texture_glide:
				sprite.texture = texture_glide
	
	# Yön kontrolü (LEFT ve RIGHT dışında)
	if state != SpriteState.LEFT and state != SpriteState.RIGHT:
		if facing_direction > 0:
			sprite.scale.x = abs(sprite.scale.x)
		else:
			sprite.scale.x = -abs(sprite.scale.x)

# Skora göre tüm fizik değerlerini güncelle (hız, zıplama, yerçekimi)
func _update_physics_from_score():
	# Game referansını kontrol et ve gerekirse yeniden al
	if not game_node or not is_instance_valid(game_node):
		game_node = get_parent()
	
	# Game.gd'den skoru al
	if game_node and game_node.has_method("get_score"):
		var score = game_node.get_score()
		# Hızı doğrusal olarak artır: base_speed + (score * speed_increase_per_score)
		current_speed = BASE_SPEED + (score * SPEED_INCREASE_PER_SCORE)
		# Zıplama gücünü doğrusal olarak artır: base_jump + (score * jump_increase_per_score)
		current_jump_velocity = BASE_JUMP_VELOCITY + (score * JUMP_INCREASE_PER_SCORE)
		# Yerçekimini doğrusal olarak artır: base_gravity + (score * gravity_increase_per_score)
		current_gravity = BASE_GRAVITY + (score * GRAVITY_INCREASE_PER_SCORE)
		# base_jump_velocity'yi de güncelle (güç sistemi için)
		base_jump_velocity = current_jump_velocity
	else:
		# Game node bulunamazsa temel değerleri kullan
		current_speed = BASE_SPEED
		current_jump_velocity = BASE_JUMP_VELOCITY
		current_gravity = BASE_GRAVITY
		base_jump_velocity = BASE_JUMP_VELOCITY

# Skor değiştiğinde çağrılır (Game.gd'den)
func update_speed_from_score(score: int):
	# Tüm fizik değerlerini doğrusal olarak artır
	current_speed = BASE_SPEED + (score * SPEED_INCREASE_PER_SCORE)
	current_jump_velocity = BASE_JUMP_VELOCITY + (score * JUMP_INCREASE_PER_SCORE)
	current_gravity = BASE_GRAVITY + (score * GRAVITY_INCREASE_PER_SCORE)
	# base_jump_velocity'yi de güncelle (güç sistemi için)
	base_jump_velocity = current_jump_velocity

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
	debug_polygon.color = Color(0.0, 1.0, 0.0, 0.5)  # Yarı saydam yeşil (karakter için)
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
