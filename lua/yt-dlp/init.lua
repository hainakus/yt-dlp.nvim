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

-- Function to get the duration of the song (in seconds)
function yt_dlp.get_song_duration(url)
    local handle = io.popen("yt-dlp -f bestaudio --get-duration " .. url)
    local duration = handle:read("*a")
    handle:close()

    -- Remove any leading/trailing whitespaces
    if duration then
        duration = duration:match("^%s*(.-)%s*$")

        -- Match mm:ss or m:ss format
        local min, sec = duration:match("^(%d+):(%d+)$")

        if min and sec then
            -- Convert minutes to seconds and add to seconds
            local total_seconds = tonumber(min) * 60 + tonumber(sec)
            return total_seconds * 1  -- Convert to milliseconds
        else
            print("❌ Could not parse duration: " .. duration)
            return nil
        end
    else
        print("❌ Could not retrieve song duration for: " .. url)
        return nil
    end
end

-- Function to play the song using mpv
function yt_dlp.play_song(song)
    -- Extract the URL from the song string (format: Title - URL)
    local title, url = song:match("^(.-) %|%| (https?://[^\n]+)$")

    if url then
        -- Play the URL with mpv
        local command = "mpv --no-video --quiet --msg-level=all=error " .. url .. " > /dev/null 2>&1 &"
        os.execute(command)
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

-- Function to play the next song in the playlist
function yt_dlp.play_next_song(current_index)
    local playlist = {}
    -- Read the playlist into a table
    for line in io.lines(playlist_file) do
        table.insert(playlist, line)
    end

    -- If the playlist is empty, do nothing
    if #playlist == 0 then
        print("❌ No songs in the playlist.")
        return
    end

    -- If the current index is greater than the number of songs, reset to the first song
    if current_index > #playlist then
        current_index = 1
    end

    -- Get the current song from the playlist
    local song = playlist[current_index]
    local title, song_url = song:match("^(.-) %|%| (https?://[^\n]+)$")

    if song_url then
         yt_dlp.play_song(song)
         -- Get the duration of the current song in seconds
         local duration = yt_dlp.get_song_duration(song_url)

         -- If duration is valid, schedule the next song
         if duration then
             -- Advance to the next song in the playlist
             current_index = current_index + 1

             -- Set a timer to play the next song after the duration of the current song
             vim.defer_fn(function()
                 yt_dlp.play_next_song(current_index)
             end, duration * 1000)  -- Convert seconds to milliseconds
         else
             -- If we couldn't get the duration, skip to the next song
             current_index = current_index + 1
             yt_dlp.play_next_song(current_index)
         end
    else
        print("❌ Could not parse the song URL.")
    end
end

-- Function to control playback (Play, Pause, Stop)
function yt_dlp.control_playback(action)
    if action == "play" then
        local current_index = 1  -- Start from the first song
        yt_dlp.play_next_song(current_index)  -- Start playing the first song
    elseif action == "pause" then
        -- Pause the current playback (assumes mpv is running)
        os.execute("mpv --no-video --pause --quiet --msg-level=all=error > /dev/null 2>&1")
        print("⏸️ Paused playback.")
    elseif action == "stop" then
        -- Stop the current playback
        os.execute("pkill mpv")
        print("🛑 Stopped playback.")
    end
end
-- Function to shuffle a table (Fisher-Yates shuffle algorithm)
local function shuffle_table(t)
    math.randomseed(os.time()) -- Seed random number generator
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i] -- Swap elements
    end
end

-- Function to play the shuffled playlist
function yt_dlp.play_shuffled()
    local playlist = {}

    -- Read playlist entries into a table
    for line in io.lines(playlist_file) do
        table.insert(playlist, line)
    end

    -- If the playlist is empty, do nothing
    if #playlist == 0 then
        print("❌ No songs in the playlist to shuffle.")
        return
    end

    -- Shuffle the playlist
    shuffle_table(playlist)

    -- Function to play each song in sequence
    local function play_next_shuffled_song(index)
        if index > #playlist then
            print("✅ Finished playing shuffled playlist.")
            return
        end

        local song = playlist[index]
        local title, url = song:match("^(.-) %|%| (https?://[^\n]+)$")

        if url then
            print("🎵 Playing: " .. title)

            -- Get the song duration
            local duration = yt_dlp.get_song_duration(url)

            -- Play the current song
            os.execute("mpv --no-video --quiet --msg-level=all=error " .. url .. " > /dev/null 2>&1 &")

            -- Schedule next song
            if duration then
                vim.defer_fn(function()
                    play_next_shuffled_song(index + 1)
                end, duration * 1000)  -- Convert seconds to milliseconds
            else
                -- If duration fails, move to next song immediately
                play_next_shuffled_song(index + 1)
            end
        else
            print("❌ Invalid song format, skipping...")
            play_next_shuffled_song(index + 1)
        end
    end

    -- Start playing the first shuffled song
    play_next_shuffled_song(1)
end
-- Setup commands and mappings
function yt_dlp.setup()
    vim.api.nvim_create_user_command("YTAdd", yt_dlp.add_to_playlist, {})
    vim.api.nvim_create_user_command("YTPlaylist", yt_dlp.show_playlist, {})
    vim.api.nvim_create_user_command("YTPlay", function() yt_dlp.control_playback("play") end, {})
    vim.api.nvim_create_user_command("YTPause", function() yt_dlp.control_playback("pause") end, {})
    vim.api.nvim_create_user_command("YTStop", function() yt_dlp.control_playback("stop") end, {})
    vim.api.nvim_create_user_command("YTPlayShuffle", yt_dlp.play_shuffled, {})
end

return yt_dlp