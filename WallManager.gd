extends Node

# Duvar referansları
@export var left_wall: NodePath
@export var right_wall: NodePath
@export var camera_path: NodePath = NodePath("../Camera2D")

# Kule görselleri
@export var left_tower_body_texture: Texture2D = preload("res://solgovde_png.png")
@export var left_tower_extension_texture: Texture2D = preload("res://solek_png.png")
@export var right_tower_body_texture: Texture2D = preload("res://saggovde_png.png")
@export var right_tower_extension_texture: Texture2D = preload("res://sagek_png.png")

# Kule ölçeklendirme ve pozisyon ayarları
@export_group("Sol Kule Ayarları")
@export var left_tower_scale: Vector2 = Vector2(1.75, 1.75)  # Sol kulenin ölçeği
@export var left_tower_x_offset: float = -120.0  # Sol kulenin gövde X pozisyon offset'i (negatif = sola)
@export var left_extension_x_offset: float = -138.0  # Sol kulenin ek kısım X pozisyon offset'i (negatif = sola)

@export_group("Sol Kule Collision Ayarları")
@export var left_collision_width: float = 200.0  # Sol kule collision genişliği (manuel ayar)
@export var left_collision_x_offset: float = -80.0  # Sol kule collision X pozisyon offset'i (manuel ayar)

@export_group("Sağ Kule Ayarları")
@export var right_tower_scale: Vector2 = Vector2(1.75, 1.75)  # Sağ kulenin ölçeği
@export var right_tower_x_offset: float = 160.0  # Sağ kulenin gövde X pozisyon offset'i (pozitif = sağa)
@export var right_extension_x_offset: float = 180.0  # Sağ kulenin ek kısım X pozisyon offset'i (pozitif = sağa)

@export_group("Sağ Kule Collision Ayarları")
@export var right_collision_width: float = 200.0  # Sağ kule collision genişliği (manuel ayar)
@export var right_collision_x_offset: float = 120.0  # Sağ kule collision X pozisyon offset'i (manuel ayar)

var left_wall_node: StaticBody2D
var right_wall_node: StaticBody2D
var camera: Camera2D

# Sol kule için
var left_gövde_sprite: Sprite2D
var left_ek_kisimlar_node: Node2D
var left_tower_top: float = 0.0  # Sol kulenin en üst noktası (en küçük Y)
var left_extension_height: float = 0.0  # Ek kısım görselinin yüksekliği
var left_body_height: float = 0.0  # Gövde görselinin yüksekliği

# Sağ kule için
var right_gövde_sprite: Sprite2D
var right_ek_kisimlar_node: Node2D
var right_tower_top: float = 0.0  # Sağ kulenin en üst noktası
var right_extension_height: float = 0.0  # Ek kısım görselinin yüksekliği
var right_body_height: float = 0.0  # Gövde görselinin yüksekliği

func _ready():
	# Duvar referanslarını al
	if left_wall:
		left_wall_node = get_node_or_null(left_wall) as StaticBody2D
	if right_wall:
		right_wall_node = get_node_or_null(right_wall) as StaticBody2D
	
	# Kamera referansını al
	if camera_path:
		camera = get_node_or_null(camera_path) as Camera2D
	
	# Sol kule bileşenlerini al
	if left_wall_node:
		left_gövde_sprite = left_wall_node.get_node_or_null("Gövde") as Sprite2D
		left_ek_kisimlar_node = left_wall_node.get_node_or_null("EkKisimlar") as Node2D
		
		if left_gövde_sprite and left_gövde_sprite.texture:
			left_body_height = left_gövde_sprite.texture.get_height()
			# Kuleyi ölçeklendir
			left_gövde_sprite.scale = left_tower_scale
			# Sol kuleyi dışa kaydır
			left_gövde_sprite.position = Vector2(left_tower_x_offset, -left_body_height * left_tower_scale.y)
			# Gövde zeminden başlıyor, üst noktası hesapla (scale dikkate alınarak)
			left_tower_top = left_wall_node.global_position.y - left_body_height * left_tower_scale.y
		
		if left_tower_extension_texture:
			left_extension_height = left_tower_extension_texture.get_height() * left_tower_scale.y  # Scale dikkate alınarak
		
		# İlk collision shape'i ayarla
		_update_collision_shape(left_wall_node, left_tower_top, true)
	
	# Sağ kule bileşenlerini al
	if right_wall_node:
		right_gövde_sprite = right_wall_node.get_node_or_null("Gövde") as Sprite2D
		right_ek_kisimlar_node = right_wall_node.get_node_or_null("EkKisimlar") as Node2D
		
		if right_gövde_sprite and right_gövde_sprite.texture:
			right_body_height = right_gövde_sprite.texture.get_height()
			# Kuleyi ölçeklendir
			right_gövde_sprite.scale = right_tower_scale
			# Sağ kuleyi dışa kaydır
			# Görselin genişliğini al ve sağa kaydır
			var right_body_width = right_gövde_sprite.texture.get_width() * right_tower_scale.x
			right_gövde_sprite.position = Vector2(-right_body_width + right_tower_x_offset, -right_body_height * right_tower_scale.y)
			# Gövde zeminden başlıyor, üst noktası hesapla (scale dikkate alınarak)
			right_tower_top = right_wall_node.global_position.y - right_body_height * right_tower_scale.y
		
		if right_tower_extension_texture:
			right_extension_height = right_tower_extension_texture.get_height() * right_tower_scale.y  # Scale dikkate alınarak
		
		# İlk collision shape'i ayarla
		_update_collision_shape(right_wall_node, right_tower_top, false)

func _process(delta):
	# Kamera referansını kontrol et
	if not camera:
		if camera_path:
			camera = get_node_or_null(camera_path) as Camera2D
		if not camera:
			return
	
	if not left_wall_node or not right_wall_node:
		return
	
	# Kameranın görüş alanının üstünü kontrol et
	var viewport = get_viewport().get_visible_rect()
	var camera_top = camera.global_position.y - viewport.size.y / 2
	
	# Duvarların kameranın 3 ekran yüksekliği kadar üstünde olması gerekiyor
	var target_top = camera_top - viewport.size.y * 3
	
	# Sol kuleyi uzat
	if left_tower_top > target_top:
		_extend_tower(left_wall_node, left_ek_kisimlar_node, left_tower_extension_texture, target_top, true)
		left_tower_top = target_top
	
	# Sağ kuleyi uzat
	if right_tower_top > target_top:
		_extend_tower(right_wall_node, right_ek_kisimlar_node, right_tower_extension_texture, target_top, false)
		right_tower_top = target_top

func _extend_tower(wall: StaticBody2D, ek_kisimlar_node: Node2D, extension_texture: Texture2D, target_top: float, is_left: bool):
	if not ek_kisimlar_node or not extension_texture:
		return
	
	var extension_height = extension_texture.get_height()
	if extension_height <= 0:
		return
	
	# Mevcut kulenin üst noktası
	var current_top = left_tower_top if is_left else right_tower_top
	
	# Hedef nokta mevcut kulenin üstündeyse (daha küçük Y değeri), kuleyi uzat
	if target_top < current_top:
		var wall_global_y = wall.global_position.y
		
		# Mevcut ek parçaların en üst noktasını bul
		var existing_extensions_top = current_top
		if ek_kisimlar_node.get_child_count() > 0:
			var topmost_y = INF
			for child in ek_kisimlar_node.get_children():
				if child is Sprite2D:
					# centered = false olduğu için, görselin sol üst köşesi position'da
					# Görselin üst noktası = wall_global_y + child.position.y
					var child_global_top = wall_global_y + child.position.y
					if child_global_top < topmost_y:
						topmost_y = child_global_top
			if topmost_y != INF:
				existing_extensions_top = topmost_y
		
		# Kaç tane yeni ek parça eklememiz gerekiyor?
		var needed_height = existing_extensions_top - target_top
		if needed_height > 0:
			var extension_count = int(ceil(needed_height / extension_height))
			
			# Her ek parça için bir Sprite2D oluştur
			for i in range(extension_count):
				# Yeni parçanın üst noktası (global koordinat)
				var new_top = existing_extensions_top - (i + 1) * extension_height
				
				# Eğer bu parça hedef noktanın altındaysa veya eşitse, ekle
				if new_top >= target_top:
					# Yeni ek parça oluştur
					var extension_sprite = Sprite2D.new()
					extension_sprite.texture = extension_texture
					extension_sprite.centered = false
					# Ek parçaları da ölçeklendir
					if is_left:
						extension_sprite.scale = left_tower_scale
					else:
						extension_sprite.scale = right_tower_scale
					
					# Pozisyonu ayarla (duvarın global pozisyonuna göre)
					# centered = false olduğu için, görselin sol üst köşesi position'da
					var extension_local_y = new_top - wall_global_y
					
					# Sol veya sağ kuleye göre X pozisyonunu ayarla (manuel offset kullan)
					var extension_x = 0.0
					if is_left:
						# Sol kule ek kısım için manuel offset
						extension_x = left_extension_x_offset
					else:
						# Sağ kule ek kısım için görselin genişliğini al ve manuel offset kullan
						var extension_width = extension_texture.get_width() * right_tower_scale.x
						extension_x = -extension_width + right_extension_x_offset
					
					extension_sprite.position = Vector2(extension_x, extension_local_y)
					
					ek_kisimlar_node.add_child(extension_sprite)
		
		# CollisionShape2D'yi güncelle
		_update_collision_shape(wall, target_top, is_left)
		
		# Kule üst noktasını güncelle
		if is_left:
			left_tower_top = target_top
		else:
			right_tower_top = target_top

func _update_collision_shape(wall: StaticBody2D, target_top: float, is_left: bool):
	var collision_shape = wall.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not collision_shape:
		return
	
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		return
	
	# Duvarın global pozisyonu
	var wall_global_y = wall.global_position.y
	
	# Kule alt noktası (zemin seviyesi)
	var tower_bottom = wall_global_y
	
	# Kule üst noktası
	var tower_top = target_top
	
	# Toplam yükseklik
	var total_height = tower_bottom - tower_top
	
	# Collision genişliğini ve X pozisyonunu manuel ayarlardan al
	var collision_width: float = 0.0
	var collision_x: float = 0.0
	
	if is_left:
		# Sol kule için manuel collision ayarları
		collision_width = left_collision_width
		# Collision X pozisyonu: offset + genişliğin yarısı (shape merkezi)
		collision_x = left_collision_x_offset + collision_width / 2.0
	else:
		# Sağ kule için manuel collision ayarları
		collision_width = right_collision_width
		# Sağ kule için: offset negatif yönde, genişliğin yarısını çıkar (shape merkezi)
		# Sağ kule duvar pozisyonu 1080'de, collision offset'i buradan hesaplanır
		collision_x = right_collision_x_offset - collision_width / 2.0
	
	# CollisionShape2D'yi güncelle (genişlik ve yükseklik)
	shape.size = Vector2(collision_width, total_height)
	
	# CollisionShape2D pozisyonunu ayarla
	# X: Manuel collision X offset'i + genişliğin yarısı (shape merkezi)
	# Y: Kule yüksekliğinin ortası
	var collision_y = (tower_top + tower_bottom) / 2 - wall_global_y
	collision_shape.position = Vector2(collision_x, collision_y)
