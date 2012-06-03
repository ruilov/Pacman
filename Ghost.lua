Ghost = class(Actor)

function Ghost:init(pos,side,color,backgroundC,lev)
    Actor.init(self,pos,side,color,backgroundC,lev)
    self.targetTile = vec2(0,0)  -- the tile this ghost is trying to get to. varies by ghost
    self.mode = "scatter"         -- each ghost is either fright, scatter or chase
    self.inPen = true             -- is this ghost in the pen. is so keep bouncing uo and down
    self.leavingPen = false       -- flag used for moving out of the pen
    self.dead = false             -- eaten by pacman and not yet back to the pan. the eyes
    self.penX = self.pos.x        -- x position to get to when returning to the pen
    self.nextDir = vec2(-1,0)     -- the look ahead direction after we get to targetPos+dir
    self.flashing = false         -- used for animation just before ghost leaves fright mode
end

function Ghost:leavePen()
    if self.inPen then self.leavingPen = true end
end

-- animation for moving into the pen
function Ghost:penMoveIn()
    -- central is the middle square of the pen
    local central = vec2(14,19) * self.side * 8
        
    if self.pos.y ~= central.y then
        self.dir = vec2(0,-self.side) -- first move down
    else
        -- then move to the sides
        if self.penX < self.pos.x then
            self.dir = vec2(-self.side,0)
        else
            self.dir = vec2(self.side,0)
        end
    end
    
    self.pos = self.pos + self.dir
    
    if self.pos.x == self.penX and self.pos.y == central.y then
        -- done entering the pen
        self.inPen = true
        self.leavingPen = true
        self.enteringPen = false
        self.dead = false
        self.mode = self.level.ghostMode
        self:setSpeed(self.level.speeds.ghost*maxSpeed)
    end
end

-- animation for moving out of the pen
function Ghost:penMoveOut()
    
    local central = vec2(14.5,19) * self.side * 8

    if not self.leavingPen or (self.pos.y ~= central.y and self.pos.x ~= central.x) then        
        -- keep bouncing
        if math.abs(self.pos.y - central.y) > 7 then
            self.dir.y = self.dir.y * (-1)
        end        
    else      
        if self.pos.x == central.x then
            --go for the exit
            self.dir = vec2(0,1.21)  -- cant be 1.15, otherwise pinky not ahead of blinky
        else
            -- first centralize x before going for the exit
            -- values tested with vert speed at 1.21 and ghost speed at 73.4
            -- speed at most 1.53 so that inky goes up in pattern2
            -- at least 1.38 so inky start chases at the right tile
            if self.pos.x < central.x then
                self.dir = vec2(math.min((central.x - self.pos.x),1.38),0)
            else
                self.dir = vec2(math.max(central.x - self.pos.x,-1.38),0)
            end
        end
    end
    self.pos = self.pos + self.dir
    
    --left yet?
    if self.pos.y >= 22*self.side*8 then
        self.pos.y = 22*self.side*8
        self.inPen = false
        self.targetPos = vec2(14,22) -- ghosts always start going left
        self.dir = vec2(-1,0)
        self:nextMove()
    end
end

-- decides on next dir
function Ghost:nextMove()
    -- dir tells us where to go once at targetpos. nextdir is after that but
    -- can be overwritten on reversals
    if self.flipDirection then
        self.dir = self:dirToTarget() * (-1)
        self.flipDirection = false
    end

    local realTarget = wrappedTunnel(self.targetPos+self.dir)
    self.targetTile = self:chooseTargetTile(self.level.pacman,self.level.blinky)
              
    -- what are the possible directions from here
    -- order is important: most prefered first
    local neighs = {vec2(0,1),vec2(-1,0),vec2(0,-1),vec2(1,0)}

    -- special regions where ghosts cant go up
    if not self.dead and self.mode ~= "fright" then
        if realTarget == vec2(13,10) or realTarget == vec2(16,10) or
        realTarget == vec2(13,22) or realTarget == vec2(16,22) then
            neighs = {vec2(-1,0),vec2(0,-1),vec2(1,0)}
        end
    end
        
    local chosen = nil
    
    if not self.dead and self.mode == "fright" then
        -- try random and rotate clockwise until it finds a good one
        local rand = math.ceil(random()*4)
        local nei = neighs[rand]
        for d = 1,4 do
            local proposedPos = realTarget + nei
            if nei ~= self.dir*(-1) and self.level.map:canOccupy(proposedPos) then
                chosen = nei
                break 
            end
            nei = -nei:rotate90()
        end
    else
        -- choose the one closest to the target
        local minD = 100000
        for _,nei in ipairs(neighs) do
            if nei ~= self.dir*(-1) then 
                local proposedPos = realTarget + nei
                if self.level.map:canOccupy(proposedPos) then
                    local dist = proposedPos:dist(self.targetTile)
                    if dist < minD-0.001 then 
                        chosen = nei
                        minD = dist
                    end
                end
            end    
        end
    end       
    if not chosen then 
        --print("nochosen")
        chosen = self.dir*(-1) 
    end
    
    self.nextDir = chosen
end

function Ghost:move() 
    -- targetPos is the position we are already going to
    if self.pos == self.targetPos*self.side*8 then
        -- once we reach the target, go to the next one
        self.targetPos = self.targetPos + self.dir
        self.dir = self.nextDir
    end
end

function Ghost:draw(mapPos)
    pushMatrix()
    pushStyle()
        
    ellipseMode(RADIUS)
    rectMode(CORNER)
    strokeWidth(-1)
    translate(mapPos.x,mapPos.y)
       
    pushMatrix()
    local ps = self.side*8
    translate(self.pos.x-.5*ps,self.pos.y-.5*ps)
    scale(.8)
    
    if not self.dead then
        if self.mode == "fright" then
            if self.flashing then fill(173, 214, 215, 255)
            else fill(42,22,202,255) end
        else
            fill(self.color)
        end
        ellipse(0,0,ps,ps)
        rect(-ps,-ps,ps*2,ps)
        ellipse(-4/5*ps,-ps,ps/5,ps/5)
        ellipse(0,-ps,ps/5,ps/5)
        ellipse(4/5*ps,-ps,ps/5,ps/5)
        fill(self.backgroundC)
        ellipse(-2/5*ps,-ps,ps/5+1,ps/5)
        ellipse(2/5*ps,-ps,ps/5+1,ps/5)
    end
    
    -- draw the eyes
    local eyeDir = self.dir
    --if self.nextDir then eyeDir = self.nextDir end
    if eyeDir.x ~= 0 then eyeDir.x = eyeDir.x / math.abs(eyeDir.x) end
    if eyeDir.y ~= 0 then eyeDir.y = eyeDir.y / math.abs(eyeDir.y) end

    fill(255, 255, 255, 255)
    ellipse(ps/5*(-2+eyeDir.x),ps/5*(1+eyeDir.y),ps/3,ps/3*1.3)
    ellipse(ps/5*(2+eyeDir.x),ps/5*(1+eyeDir.y),ps/3,ps/3*1.3)
    fill(0, 39, 255, 255)
    ellipse(ps/5*(-2+eyeDir.x*2),ps/5*(1+eyeDir.y*2),ps/6,ps/6)
    ellipse(ps/5*(2+eyeDir.x*2),ps/5*(1+eyeDir.y*2),ps/6,ps/6)
    
    popMatrix()
    
    local c = color(self.color.r,self.color.g,self.color.b,120)
    fill(c)
    rectMode(CORNERS)
        
    --[[
    translate(self.targetTile.x*ps,self.targetTile.y*ps)
    rect(-ps,-ps,0,0)
    translate(self.targetPos.x*ps,self.targetPos.y*ps)
    rect(-ps,-ps,0,0)
    --]]
       
    popMatrix()
    popStyle()
end

-- individual ghost behavior

GhostBlinky = class(Ghost)

function GhostBlinky:init(pos,side,backgroundC,lev)
    Ghost.init(self,pos,side,color(255,0,0,255),backgroundC,lev)
    self.dir = vec2(-1,0)
    self.inPen = false
end

function GhostBlinky:chooseTargetTile(pacman,blinky)
    if self.dead then return(vec2(14,22)) end
    
    if self.mode == "chase" then
        return(pacman:mapPos())        
    else return(vec2(26,36)) end
end

GhostClyde = class(Ghost)

function GhostClyde:init(pos,side,backgroundC,lev)
    Ghost.init(self,pos,side,color(255,183,81,255),backgroundC,lev)
    self.dir = vec2(0,1)
    self.targetPos.y = self.targetPos.y + 1
    self.leavingPen = false
end

function GhostClyde:chooseTargetTile(pacman,blinky)
    if self.dead then return(vec2(14,22)) end
    
    if self.mode == "chase" then
        local pacd = pacman:mapPos():dist(self:mapPos())
        if pacd >= 8 then return(pacman:mapPos())
        else return(vec2(1,2)) end
    else return(vec2(1,2)) end
end

GhostInky = class(Ghost)

function GhostInky:init(pos,side,backgroundC,lev)
    Ghost.init(self,pos,side,color(0,255,255,255),backgroundC,lev)
    self.dir = vec2(0,1)
    self.targetPos.y = self.targetPos.y + 1
    self.print = false
end

function GhostInky:chooseTargetTile(pacman,blinky)
    if self.dead then return(vec2(14,22)) end
    
    if self.mode == "chase" then
        local t = pacman:mapPos()
        for i = 1,2 do t = (t+pacman.dir) end
        -- this is a bug in the original game
        if pacman.dir == vec2(0,1) then
            for i = 1,2 do t = (t+vec2(-1,0)) end
        end
        t = blinky:mapPos() + (t - blinky:mapPos())*2
        return(t)
    else return(vec2(28,2)) end  
end

GhostPinky = class(Ghost)

function GhostPinky:init(pos,side,backgroundC,lev)
    Ghost.init(self,pos,side,color(255,0,255,255),backgroundC,lev)
    self.dir = vec2(0,1)
    self.targetPos.y = self.targetPos.y + 1
    self.leavingPen = false
    self.print = false
end

function GhostPinky:chooseTargetTile(pacman,blinky)
    if self.dead then return(vec2(14,22)) end
    
    if self.mode == "chase" then
        local t = pacman:mapPos()
        for i = 1,4 do t = wrappedTunnel(t+pacman.dir) end 
        -- this is a bug in the original game
        if pacman.dir == vec2(0,1) then
            for i = 1,4 do t = wrappedTunnel(t+vec2(-1,0)) end
        end
        return(t)     
    else return(vec2(3,36)) end   
end

