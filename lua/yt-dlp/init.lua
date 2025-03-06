local yt_dlp = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local playlist_file = "/tmp/YTLIB.txt"  -- Define playlist file path

-- Ensure playlist file exists
os.execute("touch " .. playlist_file)

-- Function to add song URL and title to playlist
function yt_dlp.add_to_playlist()
    local url = vim.fn.input("🎵 YouTube URL: ")
    if url == "" then return end

    -- Get the title of the song using yt-dlp
    local handle = io.popen("yt-dlp -f bestaudio --get-title " .. url)
    local title = handle:read("*a")
    handle:close()

    -- Remove any leading/trailing whitespaces from the title
    title = title:match("^%s*(.-)%s*$")

    -- Append the title and URL to the playlist file
    os.execute("echo '" .. title .. " || " .. url .. "' >> " .. playlist_file)

    print("✅ Added to playlist: " .. title)
end

-- Function to play song using mpv
function yt_dlp.play_song(song)
    -- Extract the URL from the song string (format: Title - URL)
    local title, url = song:match("^(.-) %|%| (https?://[^\n]+)$")

    if url then
        -- Play the URL with mpv
        os.execute("mpv --no-video --quiet " .. url .. " &")
        print("🎵 Playing: " .. title)
    else
        print("❌ Invalid song format")
    end
end

-- Function to show the playlist with music names and URLs
function yt_dlp.show_playlist()
    local playlist = {}
    for line in io.lines(playlist_file) do
        table.insert(playlist, line)
    end

    pickers.new({}, {
        prompt_title = "🎵 Playlist",
        finder = finders.new_table({ results = playlist }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            local function select_song()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection then
                    yt_dlp.play_song(selection[1]:match("^(.-) %|%| (https?://[^\n]+)$"))
                end
            end
            map("i", "<CR>", select_song)
            map("n", "<CR>", select_song)
            return true
        end,
    }):find()
end

-- Function to control playback (Play, Pause, Stop)
function yt_dlp.control_playback(action)
    -- Read the playlist into a table
    local playlist = {}
    for line in io.lines(playlist_file) do
        table.insert(playlist, line)
    end

    -- If the playlist is empty, do nothing
    if #playlist == 0 then
        print("❌ No songs in the playlist.")
        return
    end

    local current_index = 1
    local function play_next_song()
        if current_index > #playlist then
            current_index = 1  -- Reset to first song (repeat playlist)
        end

        local song = playlist[current_index]
        local title, song_url = song:match("^(.-) %|%| (https?://[^\n]+)$")

        if song_url then
            os.execute("mpv --no-video --quiet " .. song_url .. " > /dev/null 2>&1 &")
            print("🎵 Playing: " .. title)
            current_index = current_index + 1  -- Move to the next song
        else
            print("❌ Could not parse the song URL.")
        end
    end

    if action == "play" then
        play_next_song()
    elseif action == "pause" then
        -- Pause the current playback (assumes mpv is running)
        os.execute("mpv --no-video --pause > /dev/null 2>&1")
        print("⏸️ Paused playback.")
    elseif action == "stop" then
        -- Stop the current playback
        os.execute("pkill mpv")
        print("🛑 Stopped playback.")
    end
end

-- Setup commands and mappings
function yt_dlp.setup()
    vim.api.nvim_create_user_command("YTAdd", yt_dlp.add_to_playlist, {})
    vim.api.nvim_create_user_command("YTPlaylist", yt_dlp.show_playlist, {})
    vim.api.nvim_create_user_command("YTPlay", function() yt_dlp.control_playback("play") end, {})
    vim.api.nvim_create_user_command("YTPause", function() yt_dlp.control_playback("pause") end, {})
    vim.api.nvim_create_user_command("YTStop", function() yt_dlp.control_playback("stop") end, {})
end

return yt_dlp