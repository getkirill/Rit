--[[----------------------------------------------------------------------------

This file is apart of Rit; a free and open sourced rhythm game made with LÖVE.

Copyright (C) 2023 GuglioIsStupid

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

------------------------------------------------------------------------------]]

if not love.filesystem.isFused() then
    __DEBUG__ = true
else
    __DEBUG__ = false
    function print() return end -- disable print
    -- set console to false
    love.conf = function(t)
        t.console = false
    end
end

function loadSongs()
     -- get all .qp files in songs/
    if not love.filesystem.getInfo("songs") then
        love.filesystem.createDirectory("songs")
        love.window.showMessageBox("Songs folder created!", "songs folder has been created at " .. love.filesystem.getSaveDirectory() .. "/songs", "info")
    end
    if not love.filesystem.getInfo("songs/quaver") then
        love.filesystem.createDirectory("songs/quaver")
    end
    if not love.filesystem.getInfo("songs/osu") then
        love.filesystem.createDirectory("songs/osu")
    end
    if not love.filesystem.getInfo("songs/stepmania") then
        love.filesystem.createDirectory("songs/stepmania")
    end
    if not love.filesystem.getInfo("songs/fnf") then
        love.filesystem.createDirectory("songs/fnf")
    end
    songList = {}
    for i, v in ipairs(love.filesystem.getDirectoryItems("songs/quaver")) do
        if love.filesystem.getInfo("songs/quaver/" .. v).type == "file" then
            love.filesystem.mount("songs/quaver/" .. v, "song")
            -- get all .qua files in the .qp file
            for k, j in ipairs(love.filesystem.getDirectoryItems("song")) do
                --print(j)
                --print(love.filesystem.getInfo("song/" .. j).type == "file")
                if love.filesystem.getInfo("song/" .. j).type == "file" then
                    --print("ok so")
                    if j:sub(-4) == ".qua" then
                        --print(j)
                        --print(love.filesystem.getInfo("song/" .. j).type == "file")
                        local title = love.filesystem.read("song/" .. j):match("Title:(.-)\r?\n")
                        local difficultyName = love.filesystem.read("song/" .. j):match("DifficultyName:(.-)\r?\n")
                        local BackgroundFile = love.filesystem.read("song/" .. j):match("BackgroundFile:(.-)\r?\n")
                        songList[#songList + 1] = {
                            filename = v,
                            title = title,
                            difficultyName = difficultyName or "???",
                            BackgroundFile = BackgroundFile:sub(2),
                            path = "song/" .. j,
                            type = "Quaver"
                        }
                    end
                end
            end
            love.filesystem.unmount("songs/quaver/"..v)
        end
    end
    for i, v in ipairs(love.filesystem.getDirectoryItems("songs/osu")) do 
        if love.filesystem.getInfo("songs/osu/" .. v).type == "file" then
            love.filesystem.mount("songs/osu/" .. v, "song")
            -- get all .qua files in the .qp file
            for k, j in ipairs(love.filesystem.getDirectoryItems("song")) do
                --print(j)
                --print(love.filesystem.getInfo("song/" .. j).type == "file")
                if love.filesystem.getInfo("song/" .. j).type == "file" then
                    --print("ok so")
                    if j:sub(-4) == ".osu" then
                        --print(j)
                        --print(love.filesystem.getInfo("song/" .. j).type == "file")
                        local title = love.filesystem.read("song/" .. j):match("Title:(.-)\r?\n")
                        local difficultyName = love.filesystem.read("song/" .. j):match("Version:(.-)\r?\n")
                        songList[#songList + 1] = {
                            filename = v,
                            title = title,
                            difficultyName = difficultyName or "???",
                            path = "song/" .. j,
                            type = "osu!"
                        }
                    end
                end
            end
            love.filesystem.unmount("songs/osu/"..v)
        end
    end
    for i, v in ipairs(love.filesystem.getDirectoryItems("songs/fnf")) do
        if love.filesystem.getInfo("songs/fnf/" .. v).type == "directory" then
            local songDir = "songs/fnf/" .. v
            for k, j in ipairs(love.filesystem.getDirectoryItems(songDir)) do
                if love.filesystem.getInfo(songDir .. "/" .. j).type == "file" then
                    if j:sub(-4) == "json" then
                        gsubbedFile = j:gsub(".json", "")
                        local difficultyName = gsubbedFile:match("-(.*)")
                        songList[#songList + 1] = {
                            filename = j,
                            title = json.decode(love.filesystem.read(songDir .. "/" .. j)).song.song,
                            difficultyName = difficultyName or "normal",
                            BackgroundFile = "None",
                            path = songDir .. "/" .. j,
                            folderPath = songDir,
                            type = "FNF"
                        }
                    end
                end
            end
        end
    end
    for i, v in ipairs(love.filesystem.getDirectoryItems("songs/stepmania")) do 
        -- stepmania songs are in folders
        if love.filesystem.getInfo("songs/stepmania/" .. v).type == "directory" then
            local songDir = "songs/stepmania/" .. v
            for k, j in ipairs(love.filesystem.getDirectoryItems(songDir)) do
                if love.filesystem.getInfo(songDir .. "/" .. j).type == "file" then
                    if j:sub(-3) == ".sm" then
                        local title = love.filesystem.read(songDir .. "/" .. j):match("#TITLE:(.-);")
                        local difficultyName = love.filesystem.read(songDir .. "/" .. j):match("#CREDIT:(.-);")
                        songList[#songList + 1] = {
                            filename = v,
                            title = title,
                            difficultyName = difficultyName or "???",
                            BackgroundFile = "None",
                            path = songDir .. "/" .. j,
                            folderPath = songDir,
                            type = "Stepmania"
                        }
                    end
                end
            end
        end
    end
end
local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
fnfMomentShiz = {
    true, false
}
songSelectScrollOffset = 0
-- love.filesystem.isFused() and
if  (love.system.getOS() == "Windows" or love.system.getOS() == "OS X") then
    discordRPC = require "lib.discordRPC"
    nextPresenceUpdate = 0
end
function love.load()
    require "modules.overrides"
    debug = require "modules.debug"
    input = (require "lib.baton").new({
        controls = {
            one4 = {"key:d", "button:dpleft", "axis:leftx-"},
            two4 = {"key:f", "button:dpdown", "axis:lefty-"},
            three4 = {"key:j", "button:dpup", "axis:lefty+"},
            four4 = {"key:k", "button:dpright", "axis:leftx+"},
    
            up = {"key:up", "button:dpup", "axis:lefty-"},
            down = {"key:down", "button:dpdown", "axis:lefty+"},
            left = {"key:left", "button:dpleft", "axis:leftx-"},
            right = {"key:right", "button:dpright", "axis:leftx+"},
           
    
            confirm = {"key:return", "button:a"},
            pause = {"key:return", "button:start"},
            restart = {"key:r", "button:b"},
            quit = {"key:escape", "button:back"}
        },
        joystick = love.joystick.getJoysticks()[1]
    })
    graphics = require "modules.graphics"

    ini = require "lib.ini"
    if discordRPC then 
        discordRPC.initialize("785717724906913843", true) 
        --[[
        function discordRPC.ready(userId, username, discriminator, avatar)
            debug.print(string.format("Discord: ready (%s, %s, %s, %s)", userId, username, discriminator, avatar))
        end
    
        function discordRPC.disconnected(errorCode, message)
            debug.print(string.format("Discord: disconnected (%d: %s)", errorCode, message))
        end
    
        function discordRPC.errored(errorCode, message)
            debug.print(string.format("Discord: error (%d: %s)", errorCode, message))
        end
        --]]
    end
    settingsIni = require "settings"
    settingsIni.loadSettings()

    function round(num)
        return math.floor(num + 0.5)
    end

    speed = settings.scrollspeed or 1
    autoplay = settings.autoplay or false

    quaverLoader = require "parsers.quaverLoader"
    osuLoader = require "parsers.osuLoader"
    stepmaniaLoader = require "parsers.stepmaniaLoader"
    fnfLoader = require "parsers.fnfLoader"

    receptors = {}

    state = require "modules.state"
    beatHandler = require "modules.beatHandler"

    game = require "states.game"
    songSelect = require "states.songSelect"
    skinSelect = require "states.skinSelect"
    resultsScreen = require "states.resultsScreen"
    audioOffsetter = require "states.audioOffset"

    push = require "lib.push"
    Timer = require "lib.timer"
    charthits = {}
    for i = 1, 4 do
        charthits[i] = {}
    end
    curSongSelected = 1
    font = love.graphics.newFont("fonts/Dosis-SemiBold.ttf", 16)
    scoreFont = love.graphics.newFont("fonts/Dosis-SemiBold.ttf", 64)
    accuracyFont = love.graphics.newFont("fonts/Dosis-SemiBold.ttf", 48)
    love.graphics.setFont(font)
    love.graphics.setDefaultFilter("nearest", "nearest")

    fourkColours = {
        {255, 0, 0},
        {0, 255, 0},
        {0, 0, 255},
        {255, 255, 0}
    }
    sevenkColours = {
        {255, 0, 0},
        {0, 255, 0},
        {0, 0, 255},
        {255, 255, 0},
        {255, 0, 255},
        {0, 255, 255},
        {255, 255, 255}
    }

    DEFAULT_SPACING = 200
    DEFAULT_KEYS = 4 -- default keys and spacing for making them center with special spacings and what-not

    musicTimeDo = false
    health = 1

    love.window.setMode(settings.width, settings.height, {resizable = true, vsync = settings.vsync, fullscreen = settings.fullscreen})
    --resolution.setup(settings.width, settings.height, 1920, 1080, {_type = "normal"})
    push.setupScreen(1920, 1080, {upscale = "normal"})
    -- now we do some math (ew) to reposition the keys to be centered if they have a special spacing
    --[[
    KEYS_posX = {}
    for i = 1, DEFAULT_KEYS do
        KEYS_posX[i] = DEFAULT_SPACING * (i - 1) - (DEFAULT_SPACING * (DEFAULT_KEYS - 1) / 2)
        print(KEYS_posX[i])
    end
    --]] -- oh my god i fucking god i hate math
    fnfMomentSelected = 1
    
    loadSongs()
    state.switch(skinSelect)
end

function love.resize(w, h)
    --resolution.resize(w, h, 1920, 1080, {_type = "normal"})
    push.resize(w, h)
end

function love.update(dt)
    Timer.update(dt)
    state.update(dt)
    if __DEBUG__ then debug.update(dt) end
    if discordRPC then 
        if love.timer.getTime() or 0 > nextPresenceUpdate then
            if presence then
                discordRPC.updatePresence(presence)
                --debug.print("Next presence update: "..nextPresenceUpdate)
                --debug.print("Current time is "..love.timer.getTime())
            end
            nextPresenceUpdate = love.timer.getTime() + 2.0
        end
        discordRPC.runCallbacks()
    end

    input:update(dt)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    if state.keypressed then
        state.keypressed(key)
    end
    if key == "k" and (choosingSong or choosingSkin) then
        love.system.openURL("https://ko-fi.com/A0A8GRXMX")
    end

    if key == "o" then 
        state.switch(audioOffsetter)
    end
end

function love.draw()
    push.start()
        state:draw()
        if choosingSong or choosingSkin then
            -- set x and y to bottom left corner of screen
            love.graphics.print("Press K to open my Ko-fi page!", 1545, 1040, 0, 2, 2)
        end
    push.finish()

    if __DEBUG__ then debug.draw() end
end

function love.focus(f)
    state.focus(f)
end

function love.quit()
    if discordRPC then 
        discordRPC.shutdown()
    end
end