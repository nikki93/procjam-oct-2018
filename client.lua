local client = {}


local sock = require 'https://raw.githubusercontent.com/camchenry/sock.lua/b4a20aadf67480e5d06bfd06727dacd167d6f0cc/sock.lua'
local bitser = require 'https://raw.githubusercontent.com/gvx/bitser/4f2680317cdc8b6c5af7133835de5075f2cc0d1f/bitser.lua'


local layer

local conn


function client.init(address)
    conn = sock.newClient(address, 22122)
    conn:setSerialization(bitser.dumps, bitser.loads)
    conn:connect()
    print("client connected to '" .. address .. "'")

    layer = love.graphics.newCanvas()

    conn:on('draw', function(commands)
        layer:renderTo(function()
            love.graphics.stacked('all', function()
                for _, command in ipairs(commands) do
                    love.graphics[command.funcName](unpack(command.args))
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
end


return client
