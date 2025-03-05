local yt_dlp = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Default playlist location
local default_playlist_dir = "/tmp/nvim_yt_playlists/"

-- Ensure playlist directory exists
os.execute("mkdir -p " .. default_playlist_dir)

-- Function to add to playlist
function yt_dlp.add_to_playlist()
    local playlist_name = vim.fn.input("🎵 Playlist Name: ") or "default"
    local url = vim.fn.input("🎵 YouTube URL: ")

    if url == "" then return end

    -- Ensure playlist file exists
    local playlist_file = default_playlist_dir .. playlist_name .. ".txt"
    os.execute("touch " .. playlist_file)

    -- Save URL to playlist file
    os.execute("yt-dlp -f bestaudio --get-title " .. url .. " >> " .. playlist_file)
    os.execute("echo " .. url .. " >> " .. playlist_file)
    print("✅ Added to playlist: " .. playlist_name)
end

-- Function to show playlist
function yt_dlp.show_playlist()
    local playlist_name = vim.fn.input("🎵 Playlist Name: ") or "default"
    local playlist_file = default_playlist_dir .. playlist_name .. ".txt"

    if vim.fn.filereadable(playlist_file) == 0 then
        print("❌ Playlist not found!")
        return
    end

    local playlist = {}
    for line in io.lines(playlist_file) do
        table.insert(playlist, line)
    end

    pickers.new({}, {
        prompt_title = "🎵 Playlist: " .. playlist_name,
        finder = finders.new_table({ results = playlist }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            local function select_song()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection then
                    yt_dlp.play_song(selection[1])
                end
            end
            map("i", "<CR>", select_song)
            map("n", "<CR>", select_song)
            return true
        end,
    }):find()
end

-- Function to play song
function yt_dlp.play_song(url)
    os.execute("mpv --no-video --quiet " .. url .. " &")
    print("🎶 Playing: " .. url)
end

-- Function to control mpv (play, pause, stop)
function yt_dlp.control_playback(action)
    if action == "play" then
        os.execute("mpv --no-video --quiet --start=0 &")
    elseif action == "pause" then
        os.execute("mpv --no-video --quiet --pause")
    elseif action == "stop" then
        os.execute("pkill mpv")
    end
end

-- Setup the commands
function yt_dlp.setup()
    vim.api.nvim_create_user_command("YTAdd", yt_dlp.add_to_playlist, {})
    vim.api.nvim_create_user_command("YTPlaylist", yt_dlp.show_playlist, {})
    vim.api.nvim_create_user_command("YTPlay", function() yt_dlp.control_playback("play") end, {})
    vim.api.nvim_create_user_command("YTPause", function() yt_dlp.control_playback("pause") end, {})
    vim.api.nvim_create_user_command("YTStop", function() yt_dlp.control_playback("stop") end, {})
end

return yt_dlp