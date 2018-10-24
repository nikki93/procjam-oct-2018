local server = {}


local sock = require 'https://raw.githubusercontent.com/camchenry/sock.lua/b4a20aadf67480e5d06bfd06727dacd167d6f0cc/sock.lua'
local marshal = require 'marshal'


local world, centers, specks

local conn


specks = {}

local Speck = {}

function Speck:create()
    self = self or {}
    setmetatable(self, { __index = Speck })

    self.x = self.x or 0.5 * love.graphics.getWidth()
    self.y = self.y or 0.5 * love.graphics.getHeight()
    self.radius = self.radius or 2 + 8 * math.random()
    self.decay = self.decay or 0.6

    local minDist2 = 10000000
    local cx, cy
    for _, center in ipairs(centers) do
        local dx, dy = center.x - self.x, center.y - self.y
        local dist2 = dx * dx + dy * dy
        if dist2 < minDist2 then
            cx, cy = center.x, center.y
            self.r, self.g, self.b = center.r + 0.22 * (1 - 2 * math.random()), center.g + 0.22 * (1 - 2 * math.random()), 1
            minDist2 = dist2
        end
    end

    self._life = 1

    self._body = love.physics.newBody(world, self.x, self.y, 'dynamic')
    local vx, vy = math.random(), math.random()
    self._body:setLinearVelocity(
        120 * (1 - 2 * vx * vx),
        120 * (1 - 2 * vy * vy))
    self._shape = love.physics.newCircleShape(self.radius)
    self._fixture = love.physics.newFixture(self._body, self._shape, 2)

    self._prevX, self._prevY = self.x, self.y

    table.insert(specks, self)
end

function Speck:update(dt)
    self._life = self._life - self.decay * dt
    if self._life <= 0 then
        return false
    end

    self._prevX, self._prevY = self.x, self.y
    self.x, self.y = self._body:getX(), self._body:getY()

    do
        local minDist2 = 10000000
        local cx, cy
        for _, center in ipairs(centers) do
            local dx, dy = center.x - self.x, center.y - self.y
            local dist2 = dx * dx + dy * dy
            if dist2 < minDist2 then
                cx, cy = center.x, center.y
                minDist2 = dist2
            end
        end
        minDist2 = math.sqrt(minDist2)

        local dx, dy = cx - self.x, cy - self.y
        local dr = math.sqrt(dx * dx + dy * dy)
        local F = 8
        self._body:applyForce(F * dx / dr, F * dy / dr)
    end

    return true
end

local T = love.timer.getTime()

function Speck:paint(commands)
    local l = 1 - self._life
    local R = love.timer.getTime() - T
    while R > 45 do
        R = R - 45
    end
    commands.setColor(self.r, self.g, self.b, math.min(0.2 * l * R / 30, 0.8))
    commands.ellipse('fill', self.x, self.y, 120 * l / R, 120 * l / R)
    commands.setLineWidth(l)
    commands.line(self._prevX, self._prevY, self.x, self.y)
end


function server.init()
    -- Network
    conn = sock.newServer('*', 22122)
    conn:setSerialization(marshal.encode, marshal.decode)
    conn:enableCompression()
    print("server initialized at '" .. conn:getSocketAddress() .. "'")

    -- Physics
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 0, true)

    -- Centers
    centers = {}
    for i = 1, 8 do
        table.insert(centers, {
            x = love.graphics.getWidth() * math.random(),
            y = love.graphics.getHeight() * math.random(),
            r = math.random(), g = math.random(), b = math.random(),
        })
    end
    for i = 1, 12 do
        local j = math.floor(#centers * math.random()) + 1
        table.insert(centers, {
            x = centers[j].x + 120 * (1 - 2 * math.random()),
            y = centers[j].y + 120 * (1 - 2 * math.random()),
            r = math.random(), g = math.random(), b = math.random(),
        })
    end

    conn:on('mousepressed', function(data)
        table.insert(centers, {
            x = data.x,
            y = data.y,
            r = math.random(), g = math.random(), b = math.random(),
        })
    end)

    -- Start time
    T = love.timer.getTime() - 5
end


local commands = {}
local commandBuf = {}

local funcNames = {
    setColor = true,
    ellipse = true,
    setLineWidth = true,
    line = true,
}

for funcName in pairs(funcNames) do
    commands[funcName] = function(...)
        table.insert(commandBuf, { funcName, { ... } })
    end
end


function server.update(dt)
    world:update(dt)

    if math.random() < 0.5 then
        Speck.create({
            x = love.graphics.getWidth() * math.random(),
            y = love.graphics.getHeight() * math.random(),
        })
    end

    for i = #specks, 1, -1 do
        if not specks[i]:update(dt) then
            table.remove(specks, i)
        end
    end

    commandBuf = {}
    for _, speck in ipairs(specks) do
        speck:paint(commands)
    end
    commands.setColor(1, 0, 0)
    for _, center in ipairs(centers) do
        commands.ellipse('fill', center.x, center.y, 10, 10)
    end
    conn:sendToAll('draw', commandBuf)
    commandBuf = {}

    conn:update()
end


return server
