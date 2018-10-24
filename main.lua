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

local layer = love.graphics.newCanvas()


love.physics.setMeter(64)
local world = love.physics.newWorld(0, 0, true)

local function updatePhysics(dt)
    world:update(dt)
end


local centers = {}

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

--for i = 1, 60 do
--    local j = math.floor(#centers * math.random()) + 1
--    table.insert(centers, {
--        x = centers[j].x + 60 * (1 - 2 * math.random()),
--        y = centers[j].y + 60 * (1 - 2 * math.random()),
--        r = math.random(), g = math.random(), b = math.random(),
--    })
--end

for i = 1, 80 do
    local j = math.floor(#centers * math.random()) + 1
    table.insert(centers, {
        x = centers[j].x + 20 * (1 - 2 * math.random()),
        y = centers[j].y + 20 * (1 - 2 * math.random()),
        r = math.random(), g = math.random(), b = math.random(),
    })
end

local Speck = {}

local specks = {}

function Speck:create()
    self = self or {}
    setmetatable(self, { __index = Speck })

    self.x = self.x or 0.5 * love.graphics.getWidth()
    self.y = self.y or 0.5 * love.graphics.getHeight()
    self.radius = self.radius or 2 + 8 * math.random()
    self.decay = self.decay or 0.3

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
--            self.r, self.g, self.b = center.r, center.g, center.b
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

function Speck:paint()
    local l = 1 - self._life
    local R = love.timer.getTime() - T
    love.graphics.setColor(self.r, self.g, self.b, math.min(0.2 * l * R / 30, 0.8))
    love.graphics.ellipse('fill', self.x, self.y, 120 * l / R, 120 * l / R)
    love.graphics.setLineWidth(l)
    love.graphics.line(self._prevX, self._prevY, self.x, self.y)
end


local moonshine = require 'https://raw.githubusercontent.com/nikki93/moonshine/9e04869e3ceaa76c42a69c52a954ea7f6af0469c/init.lua'
local effect = moonshine(moonshine.effects.glow)
effect.glow.min_luma = 0

function love.update(dt)
    updatePhysics(dt)

    for i = 1, 3 do
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

    layer:renderTo(function()
        love.graphics.stacked('all', function()
            for _, speck in ipairs(specks) do
                speck:paint()
            end
        end)
    end)
end

function love.draw()
    love.graphics.draw(layer, 0, 0)

--    for _, center in ipairs(centers) do
--        love.graphics.ellipse('fill', center.x, center.y, 2, 2)
--    end
end
