extends Control

# Referanslar
@onready var tap_to_play_container: Control = $TapToPlayContainer
@onready var tap_to_play_image: TextureRect = $TapToPlayContainer/TapToPlayImage
@onready var high_score_label: Label = $HighScoreLabel
@onready var shop_button: Control = $BottomButtons/ShopButton
@onready var profile_button: Control = $BottomButtons/ProfileButton
@onready var achievements_button: Control = $BottomButtons/AchievementButton
@onready var highscore_button: Control = $BottomButtons/HighScoreButton
@onready var settings_button: Control = $TopRightButtons/SettingsButton
@onready var no_ads_button: Control = $TopRightButtons/NoAdsButton
@onready var background_image: TextureRect = $BackgroundImage

# Oyun sahnesi yolu
const GAME_SCENE_PATH = "res://Game.tscn"

# High score kaydetme/yükleme
const SAVE_FILE_PATH = "user://high_score.save"

var high_score: int = 0
var game_started: bool = false
var tap_to_play_tween: Tween = null

func _ready():
	# High score'u yükle
	_load_high_score()
	
	# High score'u göster
	_update_high_score_display()
	
	# Tap to play görselini konumlandır (ekran ortasından 4cm sağa, 3cm aşağı)
	_position_tap_to_play_image()
	
	# Tap to play görseline pulse animasyonu ekle
	_start_tap_to_play_animation()
	
	# Buton sinyallerini bağla
	_setup_button(shop_button, "_on_shop")
	_setup_button(profile_button, "_on_profile")
	_setup_button(achievements_button, "_on_achievements")
	_setup_button(highscore_button, "_on_highscore")
	_setup_button(settings_button, "_on_settings")
	_setup_button(no_ads_button, "_on_no_ads")

func _input(event):
	# Tap to play - ekrana tıklama
	if not game_started and event is InputEventScreenTouch and event.pressed:
		_start_game()
	elif not game_started and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_start_game()

func _start_game():
	if game_started:
		return
	
	game_started = true
	
	# Tap to play animasyonunu durdur
	_stop_tap_to_play_animation()
	
	# Tüm UI elementlerini gizle
	if tap_to_play_container:
		tap_to_play_container.visible = false
	
	if high_score_label:
		high_score_label.visible = false
	
	if shop_button:
		shop_button.visible = false
	
	if profile_button:
		profile_button.visible = false
	
	if achievements_button:
		achievements_button.visible = false
	
	if highscore_button:
		highscore_button.visible = false
	
	if settings_button:
		settings_button.visible = false
	
	if no_ads_button:
		no_ads_button.visible = false
	
	# Arka plan görselini de gizle
	if background_image:
		background_image.visible = false
	
	# Oyun sahnesine geçiş yap (bağımsız sahne)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _update_high_score_display():
	if high_score_label:
		high_score_label.text = "High Score: " + str(high_score)

# Buton kurulum fonksiyonu
func _setup_button(button: Control, method_prefix: String):
	if not button:
		return
	
	# Mouse etkileşimini etkinleştir
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Sinyalleri bağla
	button.mouse_entered.connect(func(): _on_button_hover(button, true))
	button.mouse_exited.connect(func(): _on_button_hover(button, false))
	button.gui_input.connect(func(event): _on_button_gui_input(button, event, method_prefix))

# Buton hover efekti
func _on_button_hover(button: Control, is_hovered: bool):
	if not button:
		return
	
	# Tween ile yumuşak geçiş
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if is_hovered:
		# Mouse üzerine geldiğinde: biraz büyüt ve parlaklaştır
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.15)
		# TextureRect'i bul ve modulate'i değiştir
		var texture_rect = button.get_node_or_null("TextureRect")
		if texture_rect:
			tween.parallel().tween_property(texture_rect, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.15)
	else:
		# Mouse çıktığında: normale dön
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)
		var texture_rect = button.get_node_or_null("TextureRect")
		if texture_rect:
			tween.parallel().tween_property(texture_rect, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

# Buton tıklama işleme
func _on_button_gui_input(button: Control, event: InputEvent, method_prefix: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Tıklama efekti: kısa süreliğine küçült
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.1)
		
		# İlgili fonksiyonu çağır
		match method_prefix:
			"_on_shop":
				_on_shop_pressed()
			"_on_profile":
				_on_profile_pressed()
			"_on_achievements":
				_on_achievements_pressed()
			"_on_highscore":
				_on_highscore_pressed()
			"_on_settings":
				_on_settings_pressed()
			"_on_no_ads":
				_on_no_ads_pressed()
	elif event is InputEventScreenTouch and event.pressed:
		# Dokunmatik ekran için
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
		
		match method_prefix:
			"_on_shop":
				_on_shop_pressed()
			"_on_profile":
				_on_profile_pressed()
			"_on_achievements":
				_on_achievements_pressed()
			"_on_highscore":
				_on_highscore_pressed()
			"_on_settings":
				_on_settings_pressed()
			"_on_no_ads":
				_on_no_ads_pressed()

func _on_shop_pressed():
	# Shop butonu - şimdilik sadece print
	print("Shop butonuna tıklandı")

func _on_profile_pressed():
	# Profile butonu - şimdilik sadece print
	print("Profile butonuna tıklandı")

func _on_achievements_pressed():
	# Achievements butonu - şimdilik sadece print
	print("Achievements butonuna tıklandı")

func _on_highscore_pressed():
	# High Score butonu - şimdilik sadece print
	print("High Score butonuna tıklandı")

func _on_settings_pressed():
	# Settings butonu - şimdilik sadece print
	print("Settings butonuna tıklandı")

func _on_no_ads_pressed():
	# No Ads butonu - şimdilik sadece print
	print("No Ads butonuna tıklandı")

# Tap to play görselini konumlandır (ekran ortasından 4cm sağa, 3cm aşağı)
func _position_tap_to_play_image():
	if not tap_to_play_image:
		return
	
	# Ekran boyutunu al
	var viewport_size = get_viewport().get_visible_rect().size
	var center_x = viewport_size.x / 2
	var center_y = viewport_size.y / 2
	
	# 4cm = 151.18 pixels, 3cm = 113.39 pixels (96 DPI'da)
	var offset_x_cm = 6.0  # 4cm sağa
	var offset_y_cm = 7.0  # 3cm aşağı
	var pixels_per_cm = 37.795  # 96 DPI'da 1cm = 37.795 pixels
	var offset_x = offset_x_cm * pixels_per_cm
	var offset_y = offset_y_cm * pixels_per_cm
	
	# Görselin texture boyutunu al
	var texture = tap_to_play_image.texture
	if texture and tap_to_play_container:
		var image_size = texture.get_size()
		var half_width = image_size.x / 2.5
		var half_height = image_size.y / 2.5
		
		# Container'ın merkezini (center_x + offset_x, center_y + offset_y) konumuna yerleştir
		# Anchor merkezde (0.5, 0.5) olduğu için offset'ler container'ın merkezine göre
		tap_to_play_container.offset_left = offset_x - half_width
		tap_to_play_container.offset_top = offset_y - half_height
		tap_to_play_container.offset_right = offset_x + half_width
		tap_to_play_container.offset_bottom = offset_y + half_height

# Tap to play görseline pulse animasyonu başlat (büyüyüp küçülme efekti)
func _start_tap_to_play_animation():
	if not tap_to_play_container:
		return
	
	# Önceki animasyonu durdur
	_stop_tap_to_play_animation()
	
	# Container'ın pivot noktasını merkeze ayarla (merkezden büyüyüp küçülmesi için)
	var container_size = tap_to_play_container.size
	if container_size == Vector2.ZERO:
		# Eğer boyut henüz ayarlanmamışsa offset'lerden hesapla
		container_size.x = tap_to_play_container.offset_right - tap_to_play_container.offset_left
		container_size.y = tap_to_play_container.offset_bottom - tap_to_play_container.offset_top
		
		# Hala sıfırsa texture'dan al
		if container_size == Vector2.ZERO:
			if tap_to_play_image and tap_to_play_image.texture:
				container_size = tap_to_play_image.texture.get_size()
	
	# Pivot noktasını container'ın merkezine ayarla
	tap_to_play_container.pivot_offset = container_size / 2.0
	
	# Başlangıç scale değerini ayarla
	tap_to_play_container.scale = Vector2(1.0, 1.0)
	
	# Yeni Tween oluştur
	tap_to_play_tween = create_tween()
	tap_to_play_tween.set_loops()  # Sonsuz döngü
	tap_to_play_tween.set_ease(Tween.EASE_IN_OUT)
	tap_to_play_tween.set_trans(Tween.TRANS_SINE)
	
	# Büyüme animasyonu (1.0 -> 1.15) - merkezden büyüyecek
	tap_to_play_tween.tween_property(tap_to_play_container, "scale", Vector2(1.15, 1.15), 0.8)
	# Küçülme animasyonu (1.15 -> 1.0) - merkezden küçülecek
	tap_to_play_tween.tween_property(tap_to_play_container, "scale", Vector2(1.0, 1.0), 0.8)

# Tap to play animasyonunu durdur
func _stop_tap_to_play_animation():
	if tap_to_play_tween:
		tap_to_play_tween.kill()
		tap_to_play_tween = null
	
	# Scale'i normale döndür
	if tap_to_play_container:
		tap_to_play_container.scale = Vector2(1.0, 1.0)

# High score kaydetme/yükleme
func _load_high_score():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		high_score = file.get_32()
		file.close()
	else:
		high_score = 0

func save_high_score(score: int):
	if score > high_score:
		high_score = score
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
		if file:
			file.store_32(high_score)
			file.close()
		_update_high_score_display()
