# yt-dlp.nvim

# YouTube Music Player for Neovim

This plugin allows you to manage and play music from YouTube directly within Neovim. You can create a playlist, add songs, and control playback using `yt-dlp` for video extraction and `mpv` for playback.

## Features

- Add YouTube videos to a playlist.
- Play, pause, and stop playback of YouTube music directly from Neovim.
- Automatically loop through the playlist.
- Minimalistic, no video playback—just audio.

## Dependencies

Before using this plugin, you need to install a few dependencies:

### 1. **MPV**
MPV is a versatile media player that will be used to play the YouTube music.

#### Installation:
- **On Ubuntu/Debian:**
  ```bash
  sudo apt update
  sudo apt install mpv
  sudo apt update
  sudo apt install yt-dlp
  ```
- **On MacOs:**
  ```bash
   brew install mpv
   brew install yt-dlp   
  ```
- **On Windows:**
  - You can download MPV from the official website: https://mpv.io/
  - Download the latest release of yt-dlp from the GitHub releases page: https://github.com/yt-dlp/yt-dlp/releases 

## Installation Instructions for the Plugin

### 1. Install Dependencies

Before installing the plugin, ensure the following dependencies are installed:

- **MPV**: A versatile media player for audio playback.
- **yt-dlp**: A tool for downloading YouTube videos and extracting the audio/video URL.

You can install these dependencies by following the official instructions for your system.

### 2. Install the Plugin

To install the plugin in Neovim, follow these steps based on your plugin manager.

#### **2.1 Using vim-plug** (for Vim/Neovim plugin manager)

1. Add the following lines to your `init.vim` or `init.lua`:

   ```vim
   " init.vim
   call plug#begin('~/.vim/plugged')
   Plug 'hainakus/yt-dlp.nvim'
   call plug#end()
   ```
2. 	Run the following command in Neovim to install the plugin:
 ```vim
    :PlugInstall
```
#### **2.2 Using packer.nvim** (for Packer plugin manager)

1. Add this to your `init.lua` (Neovim configuration file):

   ```lua
   -- init.lua
   require('packer').startup(function()
     use 'hainakus/yt-dlp.nvim'
   end)
   ```

#### **2.3. Using lazy.nvim** (for Lazy plugin manager)

1. Add this to your `init.lua` (Neovim configuration file) to load the plugin using **lazy.nvim**:

   ```lua
   -- init.lua
   require('lazy').setup({
     { 'hainakus/yt-dlp.nvim' }
   })
   ```
### yt-dlp.nvim Plugin Usage Instructions

Once you have installed the plugin successfully, you can use the following commands inside Neovim:

---
### Summary:
- **`YTAdd`**: Adds a song to the playlist from a YouTube URL.
- **`YTPlay`**: Plays the song from the playlist and continues through the list.
- **`YTPause`**: Pauses the current playback.
- **`YTStop`**: Stops the current playback and closes `mpv`.
- **`YTPlaylist`**: Shows the current playlist of songs and their YouTube URLs.