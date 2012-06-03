-- this is most of the game logic

Level = class()

function Level:init(levelNum,lives,score,lag)
    self.levelNum = levelNum
    self.score = score
    self.lives = lives
    self.won = false
    self.map = makeDefaultMap(vec2(80,20),2.5)  
    self.time = 0 -- main time variable
    self.ateDotCount = 0 -- how many dots pacman ate
    self.font = Font()
    self.dotSound = false -- for alternating the two dot sounds
    self.lastDotSound = 0
    -- level specific configs
    self.speeds = levelSpeeds(self.levelNum) -- actor speeds
    self.frightTime = frightTimes(self.levelNum) -- how long ghosts stay in fright for
    self.penDotCounts = penDotCounts(self.levelNum) -- how many dots until ghosts leave the pen
    self.penMaxTime = penMaxTime(self.levelNum) -- if pacman stops eating force ghosts out
    self.fruitScore = fruitScore(self.levelNum)
    self.fruitTs = {70,170}
   
    self.timeTimers = {}
    local initT = self.time + lag
    self:setup(initT)
    
    -- pinky always leaves the pen right away. can't put in setup because
    -- pinky logic changes when a life is lost and we respawn
    table.insert(self.timeTimers,{t = initT, f = Ghost.leavePen,obj=self.pinky})
    
    -- inky and clyde leave after a certain number of dots
    self.dotTimers = {}
    if self.penDotCounts.inky ~= 0 then
        table.insert(self.dotTimers,{t =self.penDotCounts.inky,f=Ghost.leavePen,obj=self.inky})
    end
    if self.penDotCounts.clyde ~= 0 then
        table.insert(self.dotTimers,{t =self.penDotCounts.clyde,f=Ghost.leavePen,obj=self.clyde})
    end
    
    for _,fruitT in ipairs(self.fruitTs) do
        if self.ateDotCount < fruitT then
            table.insert(self.dotTimers,{t=fruitT,f=Level.newFruit,obj=self})
        end
    end
end

function Level:setup(initT)
    self.cumMove = {} -- used for user inputs
    self.fruit = false
    self.showFruitPoints = false
    self.ghostMode = "scatter"
        
    -- various actors
    self.pacman = Pacman(vec2(14,10),self.map.npix,color(255,255,0,255),backgroundC,self)
    self.blinky = GhostBlinky(vec2(14,22),self.map.npix,backgroundC,self)
    self.pinky = GhostPinky(vec2(14,19),self.map.npix,backgroundC,self)
    self.inky = GhostInky(vec2(12,19),self.map.npix,backgroundC,self)
    self.clyde = GhostClyde(vec2(16,19),self.map.npix,backgroundC,self)
    self.ghosts = { self.blinky, self.pinky, self.inky, self.clyde }
    
    -- move timers    
    self.pacman:setInitT(initT)
    self.pacman:setSpeed(maxSpeed*self.speeds.pacman)
    table.insert(self.timeTimers,self.pacman.moveTimer)   
    for _,ghost in ipairs(self.ghosts) do
        ghost:setInitT(initT)
        if ghost == self.blinky then thisSpeed = self.speeds.ghost
        else thisSpeed = self.speeds.pen end
        ghost:setSpeed(maxSpeed*thisSpeed)
        table.insert(self.timeTimers,ghost.moveTimer)
    end

    -- ghost mode timers, scatter/chase
    local ghostModeTs = ghostModeTimes(self.levelNum)
    local sum = initT
    for i = 1,#ghostModeTs-1,2 do
        sum = sum + ghostModeTs[i]
        table.insert(self.timeTimers,{t = sum, f = Level.setChase,obj=self,pauseFright = true})
        sum = sum + ghostModeTs[i+1]
        table.insert(self.timeTimers,{t = sum, f = Level.setScatter,obj=self,pauseFright = true})
    end
    sum = sum + ghostModeTs[#ghostModeTs]
    table.insert(self.timeTimers,{t = sum, f = Level.setChase,obj=self,pauseFright = true})
    
    -- leaving pen timers, only if this is the start of the level and ghosts leave right away
    -- otherwise it will be a dot based timer that the callee will setup
    if self.time == 0 then
        if self.penDotCounts.inky == 0 then
            table.insert(self.timeTimers,{t = initT, f = Ghost.leavePen,obj=self.inky})
        end
        if self.penDotCounts.clyde == 0 then
            table.insert(self.timeTimers,{t = initT, f = Ghost.leavePen,obj=self.clyde})
        end
    end
    
    -- pen max time timer in case pacman stops eating dots
    self.forceGhostTimer = {t=initT+self.penMaxTime,period=self.penMaxTime,
        f=Level.forceGhostOut,obj=self}
    table.insert(self.timeTimers,self.forceGhostTimer)
    
    -- energizer timer animation
    table.insert(self.timeTimers,{t=initT,period=.2,f=Map.flipDrawEnergizers,obj=self.map})
end

function Level:draw(dt)
    finalTime = self.time + dt   -- game speed adjusts for draw frequency
    while true do
        -- find the least timer
        local minT = finalTime
        local minIdx = nil
        for idx,timer in ipairs(self.timeTimers) do
            if timer.t < minT then
                minT = timer.t
                minIdx = idx
            end
        end
        
        if not minIdx then
            self.time = finalTime
            break 
        end
        
        self.time = minT
        
        -- execute
        local t = self.timeTimers[minIdx]
        t.f(t.obj)
              
        if t.period then t.t = t.t + t.period
        else table.remove(self.timeTimers,minIdx) end
    end
    
    -- draw stuff
    self.pacman:draw(self.map.pos)  
    self.map:draw()
    -- fruit
    if self.fruit then
        spriteMode(CORNER)
        sprite("Planet Cute:Heart",17.5*self.map.npix*8,(16-.5)*self.map.npix*8,
            self.map.npix*10,self.map.npix*15)
    end
    if self.showFruitPoints then
        pushMatrix()
        pushStyle()
        strokeWidth(2)
        lineCapMode(ROUND)
        scale(0.6)
        self.font:drawstring(self.fruitScore.."",
            (self.map.pos.x+self.map.npix*8*13)/.6,
            (self.map.pos.y+self.map.npix*8*15.3)/.6)
        popMatrix()
        popStyle()
    end
    for _,g in ipairs(self.ghosts) do
        g:draw(self.map.pos)
    end
    
    -- life counter
    for liv = 1, self.lives-1 do
        local pac = Pacman(vec2(liv*2+1,1),self.map.npix,color(255,255,0,255),backgroundC,self)
        pac:draw(self.map.pos)
    end  
end

-- called whenever an actor enters a new tile. maybe this code should be in the actor classes
function Level:actorMoved(actor)
    self:pacmanMeetsGhosts() -- does someone die?
    
    if actor == self.pacman then
        -- eat dots
        local mapPos = self.pacman:mapPos()
        if self.map.matrix[mapPos.x][mapPos.y] == "7" then  -- 7 is little dot
            self:ateDot(mapPos,false)
        elseif self.map.matrix[mapPos.x][mapPos.y] == "8" then  -- 8 is big dot
            self:ateDot(mapPos,true)
        end
        
        -- eat fruit
        if mapPos.y == 16 and math.abs(self.pacman.pos.x/self.map.npix/8 - 14.5) < .75 then
            if self.fruit then 
                self.score = self.score + self.fruitScore 
                self.showFruitPoints = true
                table.insert(self.timeTimers,{t=self.time+2,f=Level.killFruitPoints,obj=self})
            end
            self.fruit = false
        end
    else
        -- if this is a ghost, set speed depending on location
        if not actor.dead then
            if self:inTunnel(actor:mapPos()) then 
                actor:setSpeed(self.speeds.tunnel*maxSpeed)
            else 
                if actor.mode ~= "fright" then
                    actor:setSpeed(self.speeds.ghost*maxSpeed)
                else
                    actor:setSpeed(self.speeds.ghostfri*maxSpeed)
                end
            end
        end
        
        actor:nextMove()
    end
end

function Level:newFruit()
    self.fruit = true  
    local fruitT = random() + 9   
    table.insert(self.timeTimers,{t=self.time+fruitT,f=Level.killFruit,obj=self}) 
end

function Level:killFruit()
    self.fruit = false
end

function Level:killFruitPoints()
    self.showFruitPoints = false
end

function Level:killPacPoints()
    self.pacman.drawAsPoints = nil
end

-- handles a pacman meeting a ghost. one of them dies
function Level:pacmanMeetsGhosts()
    local pacpos = self.pacman:mapPos()
    for _,ghost in ipairs(self.ghosts) do
        local ghostpos = ghost:mapPos()
        if pacpos == ghostpos and not ghost.dead then
            if ghost.mode == "fright" then
                -- kill the beast
                -- freeze everything for one second
                for i,timer in ipairs(self.timeTimers) do
                    if not timer.obj.dead then timer.t = timer.t + 1 end
                end
                
                -- score
                self.score = self.score + self.ghostPoints
                self.pacman.drawAsPoints = self.ghostPoints
                table.insert(self.timeTimers,{t=self.time+1,f=Level.killPacPoints,obj=self})
                self.ghostPoints = self.ghostPoints * 2
                
                -- send it back towards the pen on high speed
                ghost.dead = true
                ghost.moveTimer.period = ghost.moveTimer.period / 3
                -- a bit of a hack below to bypass look ahead logic and mov towards
                -- target tile right away  
                ghost.dir = ghost:dirToTarget()
                ghost.targetPos = ghost.targetPos - ghost.dir
                ghost:nextMove()
                ghost.targetPos = ghost.targetPos + ghost.dir
                ghost.dir = ghost.nextDir
            else
                self:lifeLost() -- too bad
            end
        end
    end
end

function Level:lifeLost()
    -- a bit of a fragile assumption here that this function was called from
    -- a periodic timer. Otherwise the respawn timer we setup below
    -- could end up being removed from the timeTimers array in the main
    -- timer loop in the draw function
    self.timeTimers = {}   
    if self.lives > 1 then
        table.insert(self.timeTimers,{t=self.time+2,obj=self,f=Level.respawn})
    else
        self.gameOver = true
    end
end

function Level:respawn()
    self.lives = self.lives - 1
    self:setup(self.time+1)
    -- these are not setup in setup because logic is different than level start
    self.dotTimers = {}
    table.insert(self.dotTimers,{t=self.ateDotCount+7,f=Ghost.leavePen,obj=self.pinky})
    table.insert(self.dotTimers,{t=self.ateDotCount+17,f=Ghost.leavePen,obj=self.inky})
    table.insert(self.dotTimers,{t=self.ateDotCount+32,f=Ghost.leavePen,obj=self.clyde})
    
    for _,fruitT in ipairs(self.fruitTs) do
        if self.ateDotCount < fruitT then
            table.insert(self.dotTimers,{t=fruitT,f=Level.newFruit,obj=self})
        end
    end
end

function Level:inTunnel(pos)
    return( pos.y == 19 and (pos.x <= 5 or pos.x >= 24 ) )
end

-- animation for just before leaving fright move
function Level:flashGhosts()
    for _,g in ipairs(self.ghosts) do g.flashing = not g.flashing end
    self.flashCount = self.flashCount + 1
    
    -- number of flashes
    local max = 10
    if self.frightTime == 1 then max = 4 end
    
    if self.flashCount == max then
        -- turn it off
        for i,timer in ipairs(self.timeTimers) do
            if timer.f == Level.flashGhosts then timer.period = nil end
        end
    end
end

-- end of level animation
function Level:flashMap()
    self.map:flash()
    self.mapFlashCount = self.mapFlashCount + 1
    
    if self.mapFlashCount == 8 then
        -- turn it off
        self.timeTimers = {}
        self.won = true
    end
end

-- handle pacman eating a dot. might go into fright mode. also triggers dot timers
function Level:ateDot(dotPos,energizer)
    self.map.matrix[dotPos.x][dotPos.y] = "0"
    self.map:dotCache()
    
    self.ateDotCount = self.ateDotCount + 1
    self.score = self.score + 10
    if energizer then self.score = self.score + 40 end
    
    self.dotSound = not self.dotSound
    
    --[[
    if self.time - self.lastDotSound > 0.05 then
        self.lastDotSound = self.time
        if self.dotSound then sound(SOUND_HIT,1038)
        else sound(SOUND_HIT,843) end
    end
    --]]
        
    if self.map:numDots() == 0 then
        -- level done, set off animation
        self.mapFlashCount = 0
        self.timeTimers = {}
        table.insert(self.timeTimers, {t=self.time,period =.4,obj=self,f=Level.flashMap})
        return(nil)
    end
    
    -- freeze pacman for a little bit
    local frozenT = 1/60
    if energizer then frozenT = frozenT + 2/60 end
    self.pacman.moveTimer.t = self.pacman.moveTimer.t + frozenT
    
    -- reset the force ghost timer
    self.forceGhostTimer.t = self.time + self.penMaxTime
    
    if energizer and self.frightTime > 0 then
        -- enter fright mode
        
        -- change speeds
        self.pacman:setSpeed(self.speeds.pacfri*maxSpeed)
        for _,ghost in ipairs(self.ghosts) do
            if not self:inTunnel(ghost:mapPos()) then
                ghost:setSpeed(self.speeds.ghostfri*maxSpeed)
            end
            ghost.flashing = false
        end

        self:setGhostMode("fright")
              
        -- set up timers to stop fright and start flashing
        self.flashCount = 0
        local flashT = 10/4
        if self.frightTime == 1 then flashT = 1 end
        local hasStop = false
        local hasFlash = false
        for _,timer in ipairs(self.timeTimers) do
            -- the scatter / chase timers pause while in fright
            if timer.pauseFright then timer.t = timer.t + self.frightTime end
            
            if timer.f == Level.stopFright then
                hasStop = true
                timer.t = self.time+self.frightTime  -- reuse the old timer
            end
            
            if timer.f == Level.flashGhosts then
                hasFlash = true
                
                timer.t = self.time+self.frightTime-flashT  -- reuse the old timer
            end
        end
               
        if not hasStop then
            table.insert(self.timeTimers,
                {t=self.time+self.frightTime,obj=self,f=Level.stopFright})
        end
        
        if not hasFlash then
            table.insert(self.timeTimers, {t=self.time+self.frightTime-flashT,
                period =1/4,obj=self,f=Level.flashGhosts})
        end
        
        -- ghost points
        self.ghostPoints = 200
    end
    
    -- trigger dot timers
    local newTs = {}
    for idx,timer in ipairs(self.dotTimers) do
        if timer.t == self.ateDotCount then
            -- execute
            timer.f(timer.obj)              
            if timer.period then 
                timer.t = timer.t + timer.period
                table.insert(newTs,timer)
            end
        else
            table.insert(newTs,timer)
        end
    end
    self.dotTimers = newTs
end

-- forces one ghost out of the pen. if pacman stops eating eventually this gets called
function Level:forceGhostOut()
    if self.pinky.inPen and not self.pinky.leavingPen then
        self.pinky:leavePen()
    elseif self.inky.inPen and not self.inky.leavingPen then
        self.inky:leavePen()
    elseif self.clyde.inPen and not self.clyde.leavingPen then
        self.clyde:leavePen()
    end   
end

function Level:setChase()
    self:setGhostMode("chase")
end

function Level:setScatter()
    self:setGhostMode("scatter")
end

function Level:stopFright()
    self:setGhostMode(self.ghostMode)
    
    -- change speeds
    self.pacman:setSpeed(self.speeds.pacman*maxSpeed)
    for _,ghost in ipairs(self.ghosts) do
        if not self:inTunnel(ghost:mapPos()) then 
            ghost:setSpeed(self.speeds.ghost*maxSpeed)
        end
    end
end

function Level:setGhostMode(m)
    if m ~= "fright" then self.ghostMode = m end  
    for _,g in ipairs(self.ghosts) do
        if not g.dead then
            g.flipDirection = g.mode ~= "fright"
            g.mode = m
        end     
    end
end

function Level:touched(touch)
    if touch.state == BEGAN then 
        self.cumMove = {}
    elseif touch.state == MOVING or touch.state == ENDED then
        local thisMove = vec2(touch.deltaX,touch.deltaY)
        table.insert(self.cumMove,thisMove)
        while #self.cumMove > 5 do table.remove(self.cumMove,1) end       
    end
end

