# HappyJumpers

A mobile platformer game built with Godot Engine 4.5.

## Features

- Platform jumping mechanics
- Coin and diamond collection
- Power-ups system
- Dynamic background management
- Wall and platform management
- Player animations and controls

## Requirements

- Godot Engine 4.5 or later

## How to Run Locally

1. Open the project in Godot Engine
2. Run the main scene (Menu.tscn)

## Web Deployment (Vercel)

### Step 1: Export for Web

1. Open the project in Godot Engine
2. Go to **Project → Export**
3. Click **Add...** and select **Web**
4. Configure export settings:
   - **Export Path**: Set to `web/index.html` (relative to project root)
   - Enable **Export With Debug** if needed
5. Click **Export Project**
6. This will create a `web/` folder with all necessary files

### Step 2: Deploy to Vercel

**Option A: Using Vercel CLI**
```bash
npm i -g vercel
vercel
```

**Option B: Using GitHub Integration**
1. Push the exported `web/` folder to GitHub
2. Connect your GitHub repository to Vercel
3. Set **Root Directory** to `web` in Vercel project settings
4. Deploy

**Option C: Drag & Drop**
1. After exporting, go to [vercel.com](https://vercel.com)
2. Drag and drop the `web/` folder to deploy

### Important Notes

- The `web/` folder is gitignored - you need to export before each deployment
- For automatic deployments, consider using GitHub Actions to export and deploy
- WebAssembly (WASM) files require specific CORS headers (already configured in `vercel.json`)

## Project Structure

- `Menu.tscn` - Main menu scene
- `Game.tscn` - Main game scene
- `GameOver.tscn` - Game over screen
- `Player.gd` - Player controller script
- `Platform.gd` - Platform behavior script
- `Coin.gd` / `Diamond.gd` - Collectible items
- `PowerUp.gd` - Power-up system
- Various manager scripts for backgrounds, platforms, walls, etc.

## License

[Add your license here]
