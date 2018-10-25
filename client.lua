local client = {}


local sock = require 'https://raw.githubusercontent.com/camchenry/sock.lua/b4a20aadf67480e5d06bfd06727dacd167d6f0cc/sock.lua'
local marshal = require 'marshal'


local layer

local conn


local nDraws = 0

function client.init(address)
    conn = sock.newClient(address, 22122)
    conn:setSerialization(marshal.encode, marshal.decode)
    conn:connect()
    print("client connected to '" .. address .. "'")

    layer = love.graphics.newCanvas()

    conn:on('draw', function(commands)
        nDraws = nDraws + 1
        layer:renderTo(function()
            love.graphics.stacked('all', function()
                for _, command in ipairs(commands) do
                    love.graphics[command[1]](unpack(command[2]))
                end
            end)
        end)
    end)
end

function client.update(dt)
    conn:update()
end

function client.draw()
    love.graphics.draw(layer, 0, 0)

    love.graphics.print('ping: ' .. conn:getRoundTripTime(), 20, 20)
    love.graphics.print('fps: ' .. love.timer.getFPS(), 20, 80)
    love.graphics.print('draws: ' .. nDraws, 20, 120)
    nDraws = 0
end

function client.mousepressed(x, y)
    conn:send('mousepressed', { x = x, y = y })
end


return client
