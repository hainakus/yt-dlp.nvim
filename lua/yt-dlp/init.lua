local yt_dlp = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local playlist_file = "/tmp/nvim_yt_playlist.txt"

-- Ensure playlist file exists
os.execute("touch " .. playlist_file)

function yt_dlp.add_to_playlist()
    local url = vim.fn.input("🎵 YouTube URL: ")
    if url == "" then return end
    os.execute("yt-dlp -f bestaudio --get-title " .. url .. " >> " .. playlist_file)
    os.execute("echo " .. url .. " >> " .. playlist_file)
    print("✅ Added to playlist!")
end

function yt_dlp.play_song(song)
    os.execute("mpv --no-video --quiet " .. song .. " &")
end

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
                    yt_dlp.play_song(selection[1])
                end
            end
            map("i", "<CR>", select_song)
            map("n", "<CR>", select_song)
            return true
        end,
    }):find()
end

function yt_dlp.setup()
    vim.api.nvim_create_user_command("YTAdd", yt_dlp.add_to_playlist, {})
    vim.api.nvim_create_user_command("YTPlaylist", yt_dlp.show_playlist, {})
    print("✅ yt-dlp.nvim commands loaded!") -- Debug print
end

return yt_dlp