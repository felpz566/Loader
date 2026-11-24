# Neon Arena

A top-down 2D arena shooter made with Godot 4, designed for Android touchscreens and desktop testing.

## Features

- Top-down arena combat with procedural visuals
- Touch controls: move on the left, aim and fire on the right
- Desktop keyboard and mouse controls
- Enemy waves that get harder as your score increases
- Health bar, score counter, and restart after defeat

## Run locally

1. Install Godot 4.3 or newer.
2. Clone this repository.
3. Open `project.godot` in Godot.
4. Press F6 or F5 to run.

## Android APK export

1. Install the matching Godot export templates from **Editor → Manage Export Templates**.
2. Install Android Studio / Android SDK and configure the SDK paths in **Editor → Editor Settings → Export → Android**.
3. Add an Android export preset in **Project → Export**.
4. Set a package name, such as `com.felpz.neonarena`, select APK, and export.

For release builds, configure a signing keystore in the Android export preset. Never commit private keystores or passwords.

## Controls

### Android
- Drag on the left half of the screen to move.
- Touch/drag on the right half to aim and fire.

### Desktop
- WASD / arrow keys: move.
- Hold the left mouse button toward a direction to aim and fire.

## Structure

```
project.godot
scenes/main.tscn
scripts/game.gd
README.md
LICENSE
```

## License

MIT. See [LICENSE](LICENSE).
