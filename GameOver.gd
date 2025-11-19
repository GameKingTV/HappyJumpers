extends Control

# Game.gd'yi preload et
const Game = preload("res://Game.gd")

# Referanslar
@onready var game_end_label: Label = $EndBgContainer/ContentContainer/GameEndLabel
@onready var gold_label: Label = $EndBgContainer/ContentContainer/CurrencyContainer/GoldContainer/GoldLabel
@onready var diamond_label: Label = $EndBgContainer/ContentContainer/CurrencyContainer/DiamondContainer/DiamondLabel
@onready var gold_icon: TextureRect = $EndBgContainer/ContentContainer/CurrencyContainer/GoldContainer/GoldIcon
@onready var diamond_icon: TextureRect = $EndBgContainer/ContentContainer/CurrencyContainer/DiamondContainer/DiamondIcon
@onready var home_button: Control = $EndBgContainer/ContentContainer/ButtonsContainer/HomeButton
@onready var retry_button: Control = $EndBgContainer/ContentContainer/ButtonsContainer/RetryButton

# Oyun sonu verileri (Game.gd'den alınacak)
var earned_coins: int = 0
var earned_diamonds: int = 0
var game_time: float = 0.0

# Sahne yolları
const MENU_SCENE_PATH = "res://Menu.tscn"
const GAME_SCENE_PATH = "res://Game.tscn"

func _ready():
	# Blur efekti için arka planı ayarla
	_setup_blur_background()
	
	# Gölge efektlerini ayarla
	_setup_shadows()
	
	# Oyun sonu verilerini al (Game.gd'den direkt)
	# set_game_over_data() çağrılmadıysa _load_game_over_data() çağrılacak
	_load_game_over_data()
	
	# UI'ı güncelle
	_update_display()
	
	# Butonları bağla
	_setup_buttons()

# Butonları bağla (ayrı fonksiyon olarak, Game.gd'den de çağrılabilir)
func _setup_buttons():
	# Buton sinyallerini bağla
	if home_button:
		_setup_button(home_button, "_on_home")
	if retry_button:
		_setup_button(retry_button, "_on_retry")

# Blur efekti için arka planı ayarla
func _setup_blur_background():
	# Blur efekti için yarı saydam arka plan kullanıyoruz
	# Daha gelişmiş blur için BackBufferCopy ve shader kullanılabilir
	var blur_bg = get_node_or_null("BlurBackground")
	if blur_bg:
		# Yarı saydam siyah arka plan (blur efekti görünümü için)
		blur_bg.color = Color(0, 0, 0, 0.6)

# Gölge efektlerini ayarla (sol üstten ışık, gölgeler sağ alta)
func _setup_shadows():
	# Gölgeler zaten GameOver.tscn'de tanımlı
	# Bu fonksiyon gelecekte ek gölge ayarları için kullanılabilir
	pass

# Oyun sonu verilerini yükle (Game.gd'den)
func _load_game_over_data():
	# Game node'unu bul (group veya parent üzerinden)
	var game_node = get_tree().get_first_node_in_group("game")
	if not game_node:
		# Eğer group yoksa, parent tree'den Game.gd'yi bul
		var current = get_parent()
		while current:
			if current.has_method("get_coin_count"):
				game_node = current
				break
			current = current.get_parent()
	
	# Eğer Game node'u bulunduysa, direkt verileri al
	if game_node and game_node.has_method("get_coin_count"):
		earned_coins = game_node.get_coin_count()
		earned_diamonds = game_node.get_diamond_count()
		game_time = game_node.get_game_time()
		return
	
	# Eğer Game node'u bulunamazsa, dosyadan yükle (yedek)
	var data = Game.load_game_over_data()
	earned_coins = data.get("coins", 0)
	earned_diamonds = data.get("diamonds", 0)
	game_time = data.get("time", 0.0)

# Game.gd'den direkt veri almak için fonksiyon (Game.gd tarafından çağrılır)
func set_game_over_data(coins: int, diamonds: int, time: float):
	earned_coins = coins
	earned_diamonds = diamonds
	game_time = time
	# UI'ı hemen güncelle
	_update_display()

# UI'ı güncelle
func _update_display():
	if gold_label:
		gold_label.text = str(earned_coins)
	if diamond_label:
		diamond_label.text = str(earned_diamonds)

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
		# Mouse üzerine geldiğinde: biraz büyüt
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.15)
	else:
		# Mouse çıktığında: normale dön
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)

# Buton tıklama işleme
func _on_button_gui_input(button: Control, event: InputEvent, method_prefix: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Tıklama efekti
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
		
		# İlgili fonksiyonu çağır
		match method_prefix:
			"_on_home":
				_on_home_pressed()
			"_on_retry":
				_on_retry_pressed()
	elif event is InputEventScreenTouch and event.pressed:
		# Dokunmatik ekran için
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
		
		match method_prefix:
			"_on_home":
				_on_home_pressed()
			"_on_retry":
				_on_retry_pressed()

func _on_home_pressed():
	# Ana menüye dön
	var tree = get_tree()
	if not tree:
		# Eğer get_tree() null dönerse, viewport üzerinden dene
		var viewport = get_viewport()
		if viewport:
			tree = viewport.get_tree()
	if tree:
		tree.change_scene_to_file(MENU_SCENE_PATH)
	else:
		# Son çare: SceneTree'yi doğrudan al
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			scene_tree.change_scene_to_file(MENU_SCENE_PATH)

func _on_retry_pressed():
	# Tekrar oyna - oyunu yeniden başlat
	var tree = get_tree()
	if not tree:
		# Eğer get_tree() null dönerse, viewport üzerinden dene
		var viewport = get_viewport()
		if viewport:
			tree = viewport.get_tree()
	if tree:
		tree.reload_current_scene()
	else:
		# Son çare: SceneTree'yi doğrudan al
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			scene_tree.reload_current_scene()
