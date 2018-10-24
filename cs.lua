-- `love.graphics.stacked([arg], foo)` calls `foo` between `love.graphics.push([arg])` and
-- `love.graphics.pop()` while being resilient to errors
function love.graphics.stacked(...)
    local arg, func
    if select('#', ...) == 1 then
        func = select(1, ...)
    else
        arg = select(1, ...)
        func = select(2, ...)
    end
    love.graphics.push(arg)

    local succeeded, err = pcall(func)

    love.graphics.pop()

    if not succeeded then
        error(err, 0)
    end
end


local server = require 'server'
local client = require 'client'

local isServer, isClient


function love.draw()
    if isClient then client.draw() end
end

function love.update(dt)
    if isClient then client.update(dt) end
    if isServer then server.update(dt) end
end

function love.keypressed(k)
    if k == 's' then
        isServer = true
        server.init()
    end

    if k == 'c' then
        isClient = true
        client.init('192.168.1.80')
    end
end

function love.mousepressed(x, y, button)
    if isClient then client.mousepressed(x, y, button) end
end



