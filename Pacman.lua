Pacman = class(Actor)

function Pacman:init(pos,side,color,backgroundC,lev)
    Actor.init(self,pos,side,color,backgroundC,lev)
    self.dir = vec2(-1,0)
    self.drawAsPoints = nil
end

function Pacman:mouthPos()
    local diff = (self.targetPos*8 - self.pos/self.side)    
    local ans = diff.x
    if diff.x == 0 then ans = diff.y end
    if ans < 0 then ans = ans + 8 end    
    ans = (math.floor(ans/2)+1)%4
    return(ans)
end

function Pacman:move()   
    local userMove = false
    if #self.level.cumMove > 0 then
        local sumMoves = tableSum(self.level.cumMove,vec2(0,0))
        local queuedMove = discretise(sumMoves.x,sumMoves.y)
        local proposedPos = self.targetPos + queuedMove
        if self.level.map:canOccupy(proposedPos) then
            
            -- pacman also needs to be within the targetPos square
            -- note that this makes pacman faster on corners since it 
            -- moves in both directions at the same time. this replicates
            -- game mechanics from the original
            realPos = self:scaledPos()
            if realPos.x <= self.targetPos.x and 
            realPos.x > self.targetPos.x - 1 and
            realPos.y <= self.targetPos.y and 
            realPos.y > self.targetPos.y - 1 then
                --print(sumMoves)
                self.targetPos = proposedPos
                self.dir = queuedMove
                self.level.cumMove = {}
                userMove = true
            end
        end
    end
    
    -- do the auto move   
    if not userMove and self.pos == self.targetPos*self.side*8 then
        proposedPos = self.targetPos + self.dir
        if self.level.map:canOccupy(proposedPos) then
            self.targetPos = proposedPos
        end               
    end
end

function Pacman:draw(mapPos)
    pushMatrix()
    pushStyle()
    translate(mapPos.x,mapPos.y)
    local ps = self.side*8
    
    if self.drawAsPoints then
        translate(self.pos.x-1.3*ps,self.pos.y-1*ps)
        scale(0.5)    
        self.level.font:drawstring(self.drawAsPoints.."",0,0)
        popMatrix()
        popStyle()
        return(nil)
    end
    
    pushMatrix()
    translate(self.pos.x-.5*ps,self.pos.y-.5*ps)
    
    stroke(self.color)
    fill(self.color)
    ellipseMode(RADIUS)
    scale(0.83)
    --scale(5)
    ellipse(0,0,ps)
        
    local mDir = self.dir
    -- should be able to use angleBetween but to avoid its bug, just do cases
    
    if mDir.x < 0 then rotate(180) 
    elseif mDir.x > 0 then rotate(0)
    elseif mDir.y < 0 then rotate(270)
    elseif mDir.y > 0 then rotate(90) end
    local m = self:mouthPos()
    if m == 2 then
        self:drawMouth(20,-self.side*3,-1)
        self:drawMouth(-20,-self.side*3,1)
    elseif m == 1 or m == 3 then
        self:drawMouth(0,-self.side*3,0)
    end
    
    popMatrix()
    
    --[[
    translate(self.targetPos.x*ps,self.targetPos.y*ps)
    fill(255, 0, 239, 120)
    rect(-ps,-ps,0,0)
    --]]
    popMatrix()
    popStyle()
end

function Pacman:drawMouth(ang,offx,offy)
    pushMatrix()
    local aperture = 30
    local tan = math.tan(math.rad(aperture))
    local side = self.side*8-offx
    
    local p = vec2(side,0)
    p = p:rotate(math.rad(aperture+ang))   
    local tri = Triangle(p-vec2(-offx,2-offy),side,side*tan,180+aperture+ang,self.backgroundC)
    tri:draw()

    p = vec2(side,0)
    p = p:rotate(-math.rad(aperture-ang))
    tri = Triangle(p+vec2(offx,1+offy),side*tan,side,90-aperture+ang,self.backgroundC)
    tri:draw()
    popMatrix()
end

-- triangle class used for mouth drawing. taken from my tangrams game
Triangle = class()

log2 = math.log(2)

-- angle in degrees and counter-clockwise from the positive x-axis
function Triangle:init(pos,sideX,sideY,angle,color)
    self.pos = pos
    self.angle = angle
    self.side = sideX
    self.ratio = sideY/sideX
    self.color = color
end

function Triangle:draw()
    pushStyle()
    pushMatrix()
    
    translate(self.pos.x,self.pos.y)
    rotate(self.angle)
    fill(self.color)
    rectMode(RADIUS)
    noStroke()
    noSmooth()

    local niter = math.ceil(math.log(self.side)/log2)-1
    for iter = 1,niter do
        local nsq = 2^(iter-1)
        for sq = 0,nsq-1 do
            self:drawLittleSquare(sq,nsq)
        end
    end
    
    popMatrix()
    popStyle()
end

-- private helper function
function Triangle:drawLittleSquare(sqNum,numSquares)
    local temp = self.side/4/numSquares
    local d = sqNum*temp*4
    local x = temp+d
    local y = self.side-3*temp-d
    local rx = temp   
    local ry = temp
    if x > 0 then
        x = x - 1
        rx = rx + 1
    end
    if y > 0 then
        y = y - 1
        ry = ry + 1
    end
    rect(x,y*self.ratio,rx,ry*self.ratio)
end
