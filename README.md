# Prism Blocks (Godot 4)

A block puzzle game for Android: drag pieces onto an 8x8 board and clear full rows and columns.

## Open and run

1. Install **Godot 4.3 or newer** (standard version, not .NET) from https://godotengine.org/download
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5** to play. On a computer the mouse stands in for your finger.

## What's in it

| Area | Details |
|---|---|
| Classic | Endless mode. Difficulty rises with your score. One revive per game. |
| Adventure | 50 levels with goals: score, lines, gems, ice. Stars for finishing in few moves. |
| Daily challenge | Same pieces for everyone each day. No power-ups or revives. |
| Special blocks | Ice (from level 6), stone (11), bombs (16), thick ice (30). Bombs also appear in classic after 400 points. |
| Scoring | Multi-line clears, combo streaks, same-color line bonus (x2), board-clear bonus (+500). |
| Power-ups | Hammer, rotate, swap, undo. Bought with coins or one free use per rewarded ad. |
| Coins and shop | Earned from games and levels. 5 themes, power-up packs, a few free coins from ads each day. |
| Fair dealer | Every tray has at least one order where all three pieces fit. Difficulty is the same for every player. |

## Project layout

```
scripts/
  main.gd               screen router, Android back button
  autoload/save_data.gd progress, coins, settings (user://save.json)
  autoload/sfx.gd       sounds synthesized in code, vibration
  autoload/ads.gd       ad placeholder (see below)
  core/                 shapes, board rules, dealer, levels, themes (no UI)
  game/game_view.gd     board, tray, drag-and-drop, effects
  game/game_screen.gd   HUD, power-up bar, dialogs
  screens/              main menu, level select, shop
  ui/                   block artwork, buttons, small widgets
```

## Before publishing

- **Ads:** `ads.gd` only shows a placeholder screen. Install the AdMob plugin for Godot 4 (for example Poing Studios' "godot-admob-plugin"), then replace the body of `_fake()` with real rewarded and interstitial calls. Keep the function names so the rest of the game needs no changes. Add the GDPR/UMP consent form at startup.
- **Font:** download Lilita One (free, Open Font License) from Google Fonts and save it as `fonts/LilitaOne-Regular.ttf`. It's picked up automatically.
- **Android export:** in Godot, install the Android build template (Project > Install Android Build Template), set up the Android SDK and a release keystore, and enable the **VIBRATE** permission in the export preset.
- **Sounds:** the synthesized sounds work, but recorded or bought sound effects will feel richer. Replace entries in `sfx.gd` with loaded `.ogg` files.
