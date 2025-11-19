extends Node2D

# Skor değişkeni - geçilen platform sayısı
var score: int = 0
const POINTS_PER_PLATFORM = 30  # Her platform için 30 puan
const POINTS_PER_COIN = 10  # Her coin için 10 puan
const POINTS_PER_DIAMOND = 50  # Her diamond için 50 puan

# Coin ve Diamond sayaçları (bu oyun için)
var coin_count: int = 0
var diamond_count: int = 0

# Oyun süresi takibi
var game_start_time: float = 0.0
var game_time: float = 0.0
var is_game_running: bool = false

# Referanslar
@onready var player: CharacterBody2D = $Player
@onready var floor: StaticBody2D = $Floor
@onready var score_label: Label = $UI/ScoreLabel
@onready var coin_count_label: Label = $UI/CoinContainer/CoinCountLabel
@onready var diamond_count_label: Label = $UI/DiamondContainer/DiamondCountLabel
@onready var platform_manager = $PlatformManager
@onready var game_over_overlay: CanvasLayer = $GameOverOverlay

# Oyuncunun ulaştığı en yüksek nokta (skor hesaplama için)
var player_highest_y: float = 0.0

# Sayılan platformların Y pozisyonları (tekrar saymayı önlemek için)
var counted_platforms: Array = []

func _ready():
	# Yeni oyun başladığında önceki oyun verilerini temizle
	_reset_game_over_data()
	
	# Oyun değişkenlerini sıfırla
	score = 0
	coin_count = 0
	diamond_count = 0
	player_highest_y = 0.0
	counted_platforms.clear()
	game_time = 0.0
	
	# Player'dan gelen sinyalleri dinle
	if player:
		player.game_over.connect(_on_game_over)
	
	# Başlangıç pozisyonunu kaydet
	if player:
		player_highest_y = player.global_position.y
		# Başlangıç hızını ayarla (skor = 0)
		if player.has_method("update_speed_from_score"):
			player.update_speed_from_score(score)
	
	# Coin ve Diamond sayaçlarını başlat
	_update_coin_counter()
	_update_diamond_counter()
	
	# Oyun süresini başlat
	game_start_time = Time.get_ticks_msec() / 1000.0
	is_game_running = true

func _process(delta):
	if not player or not platform_manager:
		return
	
	# Oyun süresini güncelle
	if is_game_running:
		game_time = (Time.get_ticks_msec() / 1000.0) - game_start_time
	
	# Oyuncunun mevcut Y pozisyonunu al
	var current_player_y = player.global_position.y
	
	# Oyuncu yukarı çıktıysa (daha küçük Y değeri)
	if current_player_y < player_highest_y:
		player_highest_y = current_player_y
		
		# Oyuncunun altında kalan platformları say
		_count_passed_platforms()
	
	# Skoru UI'da göster
	if score_label:
		score_label.text = "Skor: " + str(score)

func _count_passed_platforms():
	# PlatformManager'dan platform listesini al
	var platforms = platform_manager.platforms
	
	# Oyuncunun altında kalan ve daha önce sayılmamış platformları bul
	var new_platforms_count = 0
	
	for platform in platforms:
		if not platform or not is_instance_valid(platform):
			continue
		
		# Platformun Y pozisyonu (platformun merkezi)
		var platform_y = platform.global_position.y
		
		# Eğer platform oyuncunun altındaysa (daha büyük Y değeri) ve daha önce sayılmamışsa
		if platform_y > player_highest_y:
			# Bu platformu daha önce saydık mı kontrol et
			var already_counted = false
			for counted_y in counted_platforms:
				# Aynı Y pozisyonuna yakın platformları sayılmış kabul et (10 piksel tolerans)
				if abs(counted_y - platform_y) < 10.0:
					already_counted = true
					break
			
			if not already_counted:
				# Yeni platform bulundu - say
				new_platforms_count += 1
				counted_platforms.append(platform_y)
	
	# Skoru artır (her platform için 30 puan)
	if new_platforms_count > 0:
		score += new_platforms_count * POINTS_PER_PLATFORM
		# Skor değiştiğinde karakter hızını güncelle
		if player and player.has_method("update_speed_from_score"):
			player.update_speed_from_score(score)

func _on_game_over():
	# Oyun süresini durdur
	is_game_running = false
	
	# Altın ve elmasları kaydet
	_save_currency(coin_count, diamond_count)
	
	# High score'u kaydet
	_save_high_score(score)
	
	# Oyun sonu verilerini geçici dosyaya kaydet (yedek olarak)
	_save_game_over_data()
	
	# Oyun sonu overlay'ini göster
	if game_over_overlay:
		game_over_overlay.visible = true
		# GameOver script'ini başlat
		var game_over_control = game_over_overlay.get_node_or_null("GameOver")
		if game_over_control:
			# Verileri direkt GameOver kontrolüne geçir (dosyadan okumak yerine)
			game_over_control.set_game_over_data(coin_count, diamond_count, game_time)
			# Butonları bağla (eğer henüz bağlanmadıysa)
			game_over_control._setup_buttons()

# High score kaydetme (Menu.gd ile aynı dosya yolu)
func _save_high_score(score: int):
	const SAVE_FILE_PATH = "user://high_score.save"
	
	# Mevcut high score'u yükle
	var current_high_score = 0
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		current_high_score = file.get_32()
		file.close()
	
	# Yeni skor daha yüksekse kaydet
	if score > current_high_score:
		var write_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
		if write_file:
			write_file.store_32(score)
			write_file.close()

# Skoru döndür (Player.gd'den erişim için)
func get_score() -> int:
	return score

# Coin sayısını döndür
func get_coin_count() -> int:
	return coin_count

# Diamond sayısını döndür
func get_diamond_count() -> int:
	return diamond_count

# Oyun süresini döndür
func get_game_time() -> float:
	return game_time

# Coin toplandığında çağrılır (skora etkisi yok)
func on_coin_collected():
	# Coin sayacını artır
	coin_count += 1
	_update_coin_counter()

# Diamond toplandığında çağrılır (skora etkisi yok)
func on_diamond_collected():
	# Diamond sayacını artır
	diamond_count += 1
	_update_diamond_counter()

# Coin sayacını güncelle
func _update_coin_counter():
	if coin_count_label:
		coin_count_label.text = str(coin_count)

# Diamond sayacını güncelle
func _update_diamond_counter():
	if diamond_count_label:
		diamond_count_label.text = str(diamond_count)

# Altın ve elmas verilerini kaydet
func _save_currency(coins: int, diamonds: int):
	const CURRENCY_FILE_PATH = "user://currency.save"
	
	# Mevcut para birimlerini yükle
	var current_coins = 0
	var current_diamonds = 0
	var file = FileAccess.open(CURRENCY_FILE_PATH, FileAccess.READ)
	if file:
		current_coins = file.get_32()
		current_diamonds = file.get_32()
		file.close()
	
	# Yeni değerleri ekle
	current_coins += coins
	current_diamonds += diamonds
	
	# Kaydet
	var write_file = FileAccess.open(CURRENCY_FILE_PATH, FileAccess.WRITE)
	if write_file:
		write_file.store_32(current_coins)
		write_file.store_32(current_diamonds)
		write_file.close()

# Altın ve elmas verilerini yükle
static func load_currency() -> Dictionary:
	const CURRENCY_FILE_PATH = "user://currency.save"
	
	var coins = 0
	var diamonds = 0
	var file = FileAccess.open(CURRENCY_FILE_PATH, FileAccess.READ)
	if file:
		coins = file.get_32()
		diamonds = file.get_32()
		file.close()
	
	return {"coins": coins, "diamonds": diamonds}

# Oyun sonu verilerini geçici dosyaya kaydet
func _save_game_over_data():
	const GAME_OVER_DATA_PATH = "user://game_over_data.save"
	
	var file = FileAccess.open(GAME_OVER_DATA_PATH, FileAccess.WRITE)
	if file:
		file.store_32(coin_count)
		file.store_32(diamond_count)
		file.store_float(game_time)
		file.close()

# Oyun sonu verilerini yükle
static func load_game_over_data() -> Dictionary:
	const GAME_OVER_DATA_PATH = "user://game_over_data.save"
	
	var coins = 0
	var diamonds = 0
	var time = 0.0
	var file = FileAccess.open(GAME_OVER_DATA_PATH, FileAccess.READ)
	if file:
		coins = file.get_32()
		diamonds = file.get_32()
		time = file.get_float()
		file.close()
	
	return {"coins": coins, "diamonds": diamonds, "time": time}

# Oyun başladığında önceki oyun verilerini temizle
func _reset_game_over_data():
	const GAME_OVER_DATA_PATH = "user://game_over_data.save"
	
	# Dosyayı sıfırla (0, 0, 0.0 yaz)
	var file = FileAccess.open(GAME_OVER_DATA_PATH, FileAccess.WRITE)
	if file:
		file.store_32(0)  # coins = 0
		file.store_32(0)  # diamonds = 0
		file.store_float(0.0)  # time = 0.0
		file.close()
