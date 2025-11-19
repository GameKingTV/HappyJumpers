# Vercel Deployment Guide

## ⚠️ ÖNEMLİ: İlk Deploy İçin

Vercel'e deploy etmeden **ÖNCE** Godot'da web export yapmanız gerekiyor!

## Adım 1: Godot'da Web Export Yapın

1. Godot Editor'ü açın
2. **Project → Export** menüsüne gidin
3. **Add...** → **Web** seçin
4. Export Path: `web/index.html` olarak ayarlayın
5. **Export Project** butonuna tıklayın
6. `web/` klasörü oluşturulacak

## Adım 2: Export Dosyalarını Commit Edin

```bash
git add web/
git commit -m "Add web export for Vercel deployment"
git push
```

## Adım 3: Vercel'e Deploy Edin

### Seçenek A: Vercel Dashboard (Önerilen)

1. [vercel.com](https://vercel.com) → **Add New Project**
2. GitHub repository'nizi seçin: `GameKingTV/HappyJumpers`
3. **Root Directory** ayarını **boş bırakın** veya `.` olarak ayarlayın
4. **Framework Preset**: Other
5. **Build Command**: Boş bırakın
6. **Output Directory**: `web`
7. **Install Command**: Boş bırakın
8. **Deploy** butonuna tıklayın

### Seçenek B: Vercel CLI

```bash
npm install -g vercel
vercel
```

Vercel otomatik olarak `vercel.json` dosyasını okuyacak.

## Sorun Giderme

### "No Output Directory named 'web' found" Hatası

Bu hata, `web/` klasörünün henüz oluşturulmadığını gösterir. 

**Çözüm:**
1. Godot'da export yapın (Adım 1)
2. `web/` klasörünü commit edin (Adım 2)
3. Tekrar deploy edin

### Web Export Nasıl Yapılır?

Eğer Godot'da export yapmayı bilmiyorsanız:

1. Godot Editor'ü açın
2. Üst menüden **Project → Export** seçin
3. Sol altta **Add...** butonuna tıklayın
4. Açılan listeden **Web** seçin
5. Sağ tarafta:
   - **Export Path** alanına `web/index.html` yazın
   - (İsteğe bağlı) **Export With Debug** işaretleyin
6. **Export Project** butonuna tıklayın
7. `web/` klasörü proje klasörünüzde oluşacak

## Otomatik Deployment (İleri Seviye)

GitHub Actions ile otomatik export ve deploy için `.github/workflows/deploy-vercel.yml` dosyasını kullanabilirsiniz. Bu için Vercel token'larınızı GitHub Secrets'a eklemeniz gerekir.

