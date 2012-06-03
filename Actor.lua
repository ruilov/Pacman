Actor = class()

function Actor:init(pos,side,color,backgroundC,lev)
    self.pos = pos*side*8+vec2(side*4,0) -- actors start in between squares
    self.targetPos = pos      -- the square where we're going
    self.side = side          -- misnamed. this is the num of ipad pixels per pacman pixel
    self.dir = vec2(0,0)      -- once we get to targetPos, which direction to go
    self.color = color
    self.backgroundC = backgroundC
    self.level = lev          -- point back to the parent level

    self.movePeriod = 0       -- controls the speed
    self.moveTimer = {t = 0, period = 0, f = Actor.movePix, obj = self}
end

function Actor:setInitT(t)
    self.moveTimer.t = t
end

function Actor:setSpeed(s)
    self.moveTimer.period = 1/s
end

-- moves to the next pixel
function Actor:movePix()
    self:move()  -- if we get to targetpos, go to the next pos
    
    -- first some special cases
    if self.dir == vec2(0,0) then 
        print("dir is zero")
        return(nil) 
    end
    
    -- pen out animation
    if self.inPen then return(self:penMoveOut()) end
    
    -- we're almost at the pen. set off the pen in animation
    if self.dead and self.pos == vec2(14.5,22)*self.side*8 then self.enteringPen = true end
    
    -- pen in animation
    if self.enteringPen then return(self:penMoveIn()) end
    
    -- move one pacman pixel
    local dx = self.targetPos.x*self.side*8 - self.pos.x
    local dy = self.targetPos.y*self.side*8 - self.pos.y   
    if dx < 0 then dx = math.max(dx,-self.side) else dx = math.min(dx,self.side) end
    if dy < 0 then dy = math.max(dy,-self.side) else dy = math.min(dy,self.side) end
    
    local mapPosBefore = self:mapPos()
    self.pos = self.pos + vec2(dx,dy)
    
    -- hack for the tunnel
    local mapPos = self:mapPos()
    if mapPos == vec2(29,19) then
        self.pos.x = 1*self.side*8-self.side*3
        self.targetPos = vec2(1,19)
    elseif mapPos == vec2(0,19) then
        self.pos.x = 28*self.side*8+self.side*3
        self.targetPos = vec2(28,19)
    end
    
    -- new position?
    local mapPosAfter = self:mapPos()
    if mapPosBefore ~= mapPosAfter then self.level:actorMoved(self) end
end

-- what's the direction from here to target
function Actor:dirToTarget()
    local diff = self.targetPos*self.side*8 - self.pos
    if diff.x ~= 0 then diff.x = diff.x / math.abs(diff.x) end
    if diff.y ~= 0 then diff.y = diff.y / math.abs(diff.y) end
    return diff
end

function Actor:scaledPos()
    return(self.pos/self.side/8 - vec2(0.51,0.51))
end

-- map coordinates
function Actor:mapPos()
    local p = self:scaledPos()
    return(vec2(math.floor(p.x)+1,math.floor(p.y)+1))
end
