# WSGFlagTracker

A lightweight WoW Classic Era addon that displays two clickable frames showing the **Alliance** and **Horde flag carriers** in Warsong Gulch.

## Features

- 🏳️ Two clearly labeled frames — one per faction
- 🖱️ **Left-click** a frame to target the flag carrier instantly
- 🖱️ **Right-click** to print the carrier's name to chat
- 🗺️ Frames auto-show when entering WSG and auto-hide on exit
- 📍 Draggable — position is saved across sessions
- 🔄 Automatically detects pick-up, drop, capture, and return events

## Installation

1. Download or clone this folder.
2. Place the `WSGFlagTracker` folder into:
   ```
   World of Warcraft/_classic_era_/Interface/AddOns/
   ```
3. Launch WoW and enable the addon in the AddOns menu on the character select screen.

## Interface Version

Targets **Classic Era patch 1.15.x** (`## Interface: 11502`).  
Update the interface number in `WSGFlagTracker.toc` if needed.

## Slash Commands

| Command           | Description                  |
|-------------------|------------------------------|
| `/wsgft`          | Show help                    |
| `/wsgft show`     | Force-show the frames        |
| `/wsgft hide`     | Hide the frames              |
| `/wsgft reset`    | Reset frame position         |
| `/wsgft clear`    | Clear current carrier names  |

## How It Works

The addon listens to the `CHAT_MSG_BG_SYSTEM_*` events that Blizzard fires for WSG flag events:

- **"X picked up the Alliance's flag!"** → marks X as the Horde FC
- **"X picked up the Horde's flag!"** → marks X as the Alliance FC
- Drop / capture / return events clear the respective carrier slot

## Notes

- Because Classic Era does not expose the enemy team's roster directly via API, detection relies entirely on BG system messages — the same source used by all other FC-tracking addons.
- The frames are hidden outside of WSG to avoid cluttering your UI elsewhere.
