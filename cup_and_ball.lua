local metre = 64
local lp = love.physics
local lg = love.graphics

local nSegments = 20
local initialCupX = 400
local initialCupY = 0
local initialBallX = initialCupX
local initialBallY = 500

local function lerp(a, b, t)
  return t < 0.5 and a + (b - a) * t or b + (a - b) * (1 - t)
end

local objs = {}

lp.setMeter(metre)
local world = lp.newWorld(0, 9.81*metre, true)

objs.cup = {}
objs.cup.body = lp.newBody(world, initialCupX, initialCupY, "dynamic")
objs.cup.body:setFixedRotation(true) -- don't rotate the cup
-- The position of the rectangle is the centre, not the top left, so we add
-- half the width/height to the top left of each rectangle to get the centre
objs.cup.shapes = {}
objs.cup.shapes[1] = lp.newRectangleShape(-60+20/2, -60+40/2,   20, 40)
objs.cup.shapes[2] = lp.newRectangleShape( 40+20/2, -60+40/2,   20, 40)
objs.cup.shapes[3] = lp.newRectangleShape(-60+120/2, -20+20/2,  120, 20)
objs.cup.shapes[4] = lp.newRectangleShape(-10+20/2,   0+60/2,   20, 60)

objs.cup.fixtures = {}
for i = 1, #objs.cup.shapes do
  objs.cup.fixtures[i] = lp.newFixture(objs.cup.body, objs.cup.shapes[i])
  -- Don't bounce too much.
  objs.cup.fixtures[i]:setRestitution(0.5)
end

-- Add a mouse joint for the cup.
objs.cup.joint = lp.newMouseJoint(objs.cup.body, objs.cup.body:getPosition())

objs.ball = {}
objs.ball.body = lp.newBody(world, initialBallX, initialBallY, "dynamic")
objs.ball.shape = lp.newCircleShape(25)
objs.ball.fixture = lp.newFixture(objs.ball.body, objs.ball.shape)

objs.string = {}
-- Make the string from the bottom of the cup to the ball
local prevX, prevY = initialCupX, initialCupY+60
for i = 1, nSegments-1 do
  local segment = {}
  local x, y = lerp(initialCupX, initialBallX, i/nSegments),
               lerp(initialCupY+60, initialBallY, i/nSegments)
  segment.body = lp.newBody(world, x, y, "dynamic")
  -- A distance joint has some spring effect already; you can play with
  -- DistanceJoint:setFrequency to make it more elastic.
  segment.joint = lp.newDistanceJoint(
    i == 1 and objs.cup.body or objs.string[i-1].body, segment.body,
    prevX, prevY, x, y
  )
  -- This causes issues, not sure why.
--  segment.shape = lp.newRectangleShape(1, 1)
--  segment.fixture = lp.newFixture(segment.body, segment.shape)

  objs.string[i] = segment
  prevX, prevY = x, y
end

do
  -- Final segment goes from the last body to the ball
  local x, y = objs.ball.body:getPosition()
  objs.ball.joint = lp.newDistanceJoint(
    objs.string[nSegments-1].body, objs.ball.body, prevX, prevY, x, y
  )
end

function love.keypressed(k) return k == "escape" and love.event.quit() end


-- Avoid jerks before the mouse is moved for the first time
-- (at the cost of stealing the mouse once)
love.mouse.setPosition(0, 0)
love.event.pump()
love.mouse.setPosition(400, 300)
objs.cup.body:setPosition(400.5, 300.5)

function love.update(dt)
  objs.cup.joint:setTarget(love.mouse.getPosition())
  world:update(dt)
end

function love.draw()
  for i = 1, #objs.cup.shapes do
    lg.polygon("line", objs.cup.body:getWorldPoints(objs.cup.shapes[i]:getPoints()))
  end
  lg.circle("line", objs.ball.body:getX(), objs.ball.body:getY(), objs.ball.shape:getRadius())
  for i = 0, nSegments - 1 do
    local x1, y1, x2, y2
    if i == 0 then
      x1, y1 = objs.cup.body:getPosition()
      y1 = y1 + 60
    else
      x1, y1 = objs.string[i].body:getPosition()
    end
    if i == nSegments - 1 then
      x2, y2 = objs.ball.body:getPosition()
    else
      x2, y2 = objs.string[i+1].body:getPosition()
    end
    lg.line(x1, y1, x2, y2)
  end
end
