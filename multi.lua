local SERVER_IP = '192.168.1.80'

-- Pick a computer to be the server. Set `SERVER_IP` above to its address visible from other
-- computers you will use. On the server, run the game and press 's' to start the server.
--
-- On any computer that can see the server, press 'c' to connect as a client (you can also do this
-- on the server itself).


-- Require libraries

local sock = require 'https://raw.githubusercontent.com/camchenry/sock.lua/b4a20aadf67480e5d06bfd06727dacd167d6f0cc/sock.lua'
local bitser = require 'https://raw.githubusercontent.com/gvx/bitser/4f2680317cdc8b6c5af7133835de5075f2cc0d1f/bitser.lua'


-- Methods for a server session. In this game it just broadcasts mouse move events from one client
-- to all others.

local Server = {}

function Server:create()
    self = setmetatable(self or {}, { __index = Server })

    -- Actually make `sock` server with given `ip`, defaulting to use any IP we get
    self._sock = sock.newServer(self.ip or '*', 22122)
    self._sock:setSerialization(bitser.dumps, bitser.loads)
    self.ip = self._sock:getSocketAddress()
    print("Server created at '" .. self.ip .. "'")

    -- Broadcast `'mousemoved'` messages to all clients except the sender (sender updates their
    -- own data locally)
    self._sock:on('mousemoved', function (data, client)
        data.connectId = client:getConnectId(),
        self._sock:sendToAllBut(client, 'mousemoved', {
            connectId = client:getConnectId(),
            data = data,
        })
    end)

    return self
end

function Server:update(dt)
    -- This tells `sock` to check for new messages and fire our listeners
    self._sock:update()
end


-- Methods for client sessions. In this game they send mouse move events to the server, listen
-- for updates to all client mouse positions, and render all client mouse positions.

local Client = {}

function Client:create()
    self = setmetatable(self or {}, { __index = Client })

    -- Actually make `sock` client with given `ip`
    self.ip = assert(self.ip, "`Client` needs `ip`")
    self._sock = sock.newClient(self.ip, 22122)
    self._sock:setSerialization(bitser.dumps, bitser.loads)
    self._sock:connect()
    print("Client connected to '" .. self.ip .. "'")

    -- Table of mouse position states keyed by client `connectId`s
    self._state = setmetatable({}, { __mode = 'k' })

    -- Update a client's mouse position when we receive the `'mousemoved'` event
    self._sock:on('mousemoved', function (msg)
        local data = msg.data
        self._state[msg.connectId] = {
            x = data.x,
            y = data.y,
        }
    end)

    return self
end

function Client:draw()
    -- Draw all mouse positions
    for _, state in pairs(self._state) do
        love.graphics.ellipse('fill', state.x, state.y, 20, 20)
    end
end

function Client:update(dt)
    -- This tells `sock` to check for new messages and fire our listeners
    self._sock:update()
end

function Client:mousemoved(x, y, dx, dy)
    -- Send a `'mousemoved'` event, then simulate receiving it locally so that we update our own
    -- data immediately for rendering and save the round trip to the server.
    local data = { x = x, y = y }
    self._sock:send('mousemoved', data)
    self._sock:_activateTriggers('mousemoved', {
        connectId = self._sock:getConnectId(),
        data = data
    })
end


-- Top-level Love events. Create and/or maintain client and/or server sessions and send them events.

local server, client

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
        client = Client.create({ ip = SERVER_IP })
    end
end

function love.mousemoved(x, y, dx, dy)
    if client then client:mousemoved(x, y, dx, dy) end
end
