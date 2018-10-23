local sock = require 'https://raw.githubusercontent.com/camchenry/sock.lua/b4a20aadf67480e5d06bfd06727dacd167d6f0cc/sock.lua'
local bitser = require 'https://raw.githubusercontent.com/gvx/bitser/4f2680317cdc8b6c5af7133835de5075f2cc0d1f/bitser.lua'


local server

local Server = {}

function Server:create()
    self = setmetatable(self or {}, { __index = Server })

    self._sock = sock.newServer(self.ip or '*', 22122)
    self._sock:setSerialization(bitser.dumps, bitser.loads)
    self.ip = self._sock:getSocketAddress()
    print("Server created at '" .. self.ip .. "'")

    self._sock:on('keypressed', function (data, client)
        self._sock:sendToAll('keypressed', data)
    end)

    return self
end

function Server:update(dt)
    self._sock:update()
end

local client

local Client = {}

function Client:create()
    self = setmetatable(self or {}, { __index = Client })

    self.ip = assert(self.ip, "`Client` needs `ip`")
    self._sock = sock.newClient(self.ip, 22122)
    self._sock:setSerialization(bitser.dumps, bitser.loads)
    self._sock:connect()
    print("Client connected to '" .. self.ip .. "'")

    self._sock:on('keypressed', function (data)
        print("'" .. data .. "' was pressed!")
    end)

    return self
end

function Client:draw() end

function Client:update(dt)
    self._sock:update()
end

function Client:keypressed(k)
    self._sock:send('keypressed', k)
end


function love.draw()
    if client then client:draw() end
end

function love.update(dt)
    if server then server:update(dt) end
    if client then client:update(dt) end
end

function love.keypressed(k)
    if k == 's' then
        server = Server.create({ ip = '*' })
    end

    if k == 'c' then
        client = Client.create({ ip = '192.168.1.80' })
    end

    if client then client:keypressed(k) end
end
