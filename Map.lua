Map = class()

function Map:init(pos,pix,nx,ny)
    self.npix = pix
    self.pos = pos
    self.nx = nx
    self.ny = ny
    self.selected = nil
    self.matrix = {}
    for i = 1, self.nx do
        local row = {}
        for j = 1, self.ny do table.insert(row,0) end
        table.insert(self.matrix,row)
    end
    self.edgeColor = color(23, 0, 255, 255)
    self.doorColor = color(255, 0, 243, 255)
    self.drawEnergizers = true
    self.flashing = false
end

function Map:flash()
    if self.flashing then
        self.flashing = false
        self.edgeColor = color(23,0,255,255)
    else
        self.flashing = true
        self.edgeColor = color(196, 200, 223, 255)
    end
    self:buildCache()
end

function Map:numDots()
    return(#self.circleCache)
end

function Map:flipDrawEnergizers()
    self.drawEnergizers = not self.drawEnergizers
end

function makeDefaultMap(pos,size)
    local map = Map(pos,size,28,36)
    map:decode(defaultMap)
    return(map)
end

function makeEditorMap(pos,size)
    local editorMap = Map(pos,size,2,16)   
    -- fill up with the options
    local options = "0123456789abcdefghijklmnopqrstu"
    local count = 0
    for i=1,2 do
        for j=1,16 do
            count = count + 1
            editorMap.matrix[i][j] = options:sub(count,count)
        end
    end
    editorMap:buildCache()
    editorMap.selected = vec2(1,1)
    return(editorMap)
end

-- selects a cell
function Map:touched(touch)
    local ps = self.npix*8
    local pos = vec2(math.floor((touch.x-self.pos.x)/ps)+1,math.floor((touch.y-self.pos.y)/ps)+1)
    if self:inBounds(pos) then
        self.selected = pos
    end
    return(self:inBounds(pos))
end

-- is this a free cell
function Map:canOccupy(pos)
    -- hack for the tunnel
    if pos == vec2(0,19) or pos == vec2(29,19) then return(true) end
    
    if not self:inBounds(pos) then return(false) end
    local v = self.matrix[pos.x][pos.y]
    return(v=="0" or v == "7" or v == "8")  -- 7 and 8 are dots
end

-- selected cells are for editing
function Map:setSelectedV(v)
    if not self.selected then return(false) end
    self.matrix[self.selected.x][self.selected.y]=v
    self:buildCache()
    return(true)
end

function Map:getSelectedV()
    if not self.selected then return(nil) end
    return(self.matrix[self.selected.x][self.selected.y])
end

function Map:inBounds(p)
    return(p.x>0 and p.x<=self.nx and p.y>0 and p.y<=self.ny)
end

function Map:draw()
    if not self.cache then self:buildCache() end
    pushMatrix()
    pushMatrix()
    
    strokeWidth(1)
    lineCapMode(SQUARE)
    rectMode(CORNERS)
    ellipse(RADIUS)
    translate(self.pos.x,self.pos.y)
    
    local ps = self.npix*8

    if editorMode == 1 then
        --[[
        stroke(48, 48, 48, 125)
        for i = 0, self.nx*8 do
            local x = i*self.npix
            line(x,0,x,self.ny*ps)
        end
    
        for j = 0, self.ny*8 do
            local y = j*self.npix
            line(0,y,self.nx*ps,y)
        end
        --]]
        stroke(65, 65, 65, 255)
        for i = 0, self.nx do
            local x = i*ps
            line(x,0,x,self.ny*ps)
        end
        
        for j = 0, self.ny do
            local y = j*ps
            line(0,y,self.nx*ps,y)
        end
        fill(78, 31, 76, 255)
        if self.selected then
            rect((self.selected.x-1)*ps,(self.selected.y-1)*ps,
                self.selected.x*ps,self.selected.y*ps)
        end
    end
        
    for c,edges in pairs(self.cache) do
        fill(c)
        stroke(c)
        for _,r in ipairs(edges) do
            rect(r.x1,r.y1,r.x2,r.y2)
        end
    end
    self:drawDots()  
    popMatrix()
    popStyle()
end

function Map:drawDots()
    strokeWidth(1)
    ellipse(RADIUS)
    fill(255, 255, 255, 255)
    stroke(255, 255, 255, 255)
    for _,c in ipairs(self.circleCache) do
        if self.drawEnergizers or c.r < self.npix * 4 then
            ellipse(c.x,c.y,c.r)
        end
    end
end

--------------------------------
-- data store funcs
--------------------------------

function Map:print()
    for j = self.ny,1,-1 do
        local ans = '"'
        for i = 1,self.nx,1 do    
            ans = ans .. self.matrix[i][j]
        end
        ans = ans .. '"..'
        print(ans)
    end
end

function Map:decode(s)
    local count = 0
    for j = self.ny,1,-1 do
        for i = 1,self.nx,1 do
            count = count + 1 
            cellv = s:sub(count,count)
            self.matrix[i][j] = cellv
        end
    end
    self:buildCache()
end

--------------------------------
-- Cache building funcs
--------------------------------

-- builds the drawing cache
function Map:buildCache()
    self:dotCache()
    self.cache = {}
    local ps = self.npix*8
    for i = 1, self.nx do
        for j = 1, self.ny do 
            local cellv = self.matrix[i][j]
            if cellv == "1" then
                -- draw a single line vertical
                self:line(i,j,4,1,4,8,self.edgeColor)
            elseif cellv == "2" then
                -- draw a single line horizontal
                self:line(i,j,1,4,8,4,self.edgeColor)
            elseif cellv == "3" then
                -- draw a round corner on the north east
                self:roundMiddle(i,j,vec2(1,1),self.edgeColor)
            elseif cellv == "4" then
                -- draw a round corner on the north west
                self:roundMiddle(i,j,vec2(-1,1),self.edgeColor)
            elseif cellv == "5" then
                -- draw a round corner on the south east
                self:roundMiddle(i,j,vec2(1,-1),self.edgeColor)
            elseif cellv == "6" then
                -- draw a round corner on the south west
                self:roundMiddle(i,j,vec2(-1,-1),self.edgeColor)
            elseif cellv == "a" then
                -- vertical with an extra line on the left
                self:line(i,j,4,1,4,8,self.edgeColor)
                self:line(i,j,1,1,1,8,self.edgeColor)
            elseif cellv == "b" then
                -- vertical with an extra line on the right
                self:line(i,j,4,1,4,8,self.edgeColor)
                self:line(i,j,8,1,8,8,self.edgeColor)
            elseif cellv == "c" then
                -- horizontal with an extra line on the bottom
                self:line(i,j,1,4,8,4,self.edgeColor)
                self:line(i,j,1,1,8,1,self.edgeColor)
            elseif cellv == "d" then
                -- horizontal with an extra line on the top
                self:line(i,j,1,4,8,4,self.edgeColor)
                self:line(i,j,1,8,8,8,self.edgeColor)
            elseif cellv == "e" then
                -- round ne corner with outside line
                self:roundMiddle(i,j,vec2(1,1),self.edgeColor)
                self:roundOut(i,j,vec2(1,1),self.edgeColor)
            elseif cellv == "f" then
                -- round nw corner with outside line
                self:roundMiddle(i,j,vec2(-1,1),self.edgeColor)
                self:roundOut(i,j,vec2(-1,1),self.edgeColor)
            elseif cellv == "g" then
                -- round se corner with outside line
                self:roundMiddle(i,j,vec2(1,-1),self.edgeColor)
                self:roundOut(i,j,vec2(1,-1),self.edgeColor)
            elseif cellv == "h" then
                -- round sw corner with outside line
                self:roundMiddle(i,j,vec2(-1,-1),self.edgeColor)
                self:roundOut(i,j,vec2(-1,-1),self.edgeColor)
            elseif cellv == "i" then
                -- round ne corner with line on the right
                self:roundMiddle(i,j,vec2(1,1),self.edgeColor)
                self:line(i,j,1,1,1,8,self.edgeColor)
            elseif cellv == "j" then
                -- round nw corner with line on the left
                self:roundMiddle(i,j,vec2(-1,1),self.edgeColor)
                self:line(i,j,8,1,8,8,self.edgeColor)
            elseif cellv == "k" then
                -- round se corner with line on the right
                self:roundMiddle(i,j,vec2(1,-1),self.edgeColor)
                self:line(i,j,1,1,1,8,self.edgeColor)
            elseif cellv == "l" then
                -- round sw corner with line on the left
                self:roundMiddle(i,j,vec2(-1,-1),self.edgeColor)
                self:line(i,j,8,1,8,8,self.edgeColor)
            elseif cellv == "m" then
                -- round sw corner with line on the top
                self:roundMiddle(i,j,vec2(-1,-1),self.edgeColor)
                self:line(i,j,1,8,8,8,self.edgeColor)
            elseif cellv == "n" then
                -- round se corner with line on the top
                self:roundMiddle(i,j,vec2(1,-1),self.edgeColor)
                self:line(i,j,1,8,8,8,self.edgeColor)
            elseif cellv == "o" then
                -- square ne corner 
                self:squareMiddle(i,j,vec2(1,1),self.edgeColor)
                self:squareIn(i,j,vec2(1,1),self.edgeColor)
            elseif cellv == "p" then
                -- square nw corner 
                self:squareMiddle(i,j,vec2(-1,1),self.edgeColor)
                self:squareIn(i,j,vec2(-1,1),self.edgeColor)
            elseif cellv == "q" then
                -- square se corner 
                self:squareMiddle(i,j,vec2(1,-1),self.edgeColor)
                self:squareIn(i,j,vec2(1,-1),self.edgeColor)
            elseif cellv == "r" then
                -- square sw corner 
                self:squareMiddle(i,j,vec2(-1,-1),self.edgeColor)
                self:squareIn(i,j,vec2(-1,-1),self.edgeColor)
            elseif cellv == "s" then
                -- horizontal with an extra line on the bottom, right end
                self:line(i,j,1,4,8,4,self.edgeColor)
                self:line(i,j,1,1,8,1,self.edgeColor)
                self:line(i,j,8,2,8,3,self.edgeColor)
            elseif cellv == "t" then
                -- horizontal with an extra line on the bottom, left end
                self:line(i,j,1,4,8,4,self.edgeColor)
                self:line(i,j,1,1,8,1,self.edgeColor)
                self:line(i,j,1,2,1,3,self.edgeColor)
            elseif cellv == "u" then
                -- the little pen door
                self:line(i,j,1,2,8,3,self.doorColor)
            end  
        end
    end
    
    self:cacheOpt()
end

function Map:dotCache()
    self.circleCache = {}
    local ps = self.npix*8
    for i = 1, self.nx do
        for j = 1, self.ny do 
            local cellv = self.matrix[i][j]
            if cellv == "7" then
                local c = {x=(i-.5)*ps,y=(j-.5)*ps,r=ps/4}
                table.insert(self.circleCache,c)  
            elseif cellv == "8" then
                local c = {x=(i-.5)*ps,y=(j-.5)*ps,r=ps}
                table.insert(self.circleCache,c)
            end  
        end
    end
end

-- x,y from 1 to 8
function Map:line(i,j,x1,y1,x2,y2,c)
    local ps = self.npix*8
    local r = {x1=(i-1+(x1-1)/8)*ps,y1=(j-1+(y1-1)/8)*ps,x2=(i-1+x2/8)*ps,y2=(j-1+y2/8)*ps}
    if not self.cache[c] then self.cache[c] = {} end
    table.insert(self.cache[c],r)
end

function Map:roundMiddle(i,j,dir,c)
    self:line(i,j,4,3.5+2.5*dir.y,4,5+3*dir.y,c)
    self:line(i,j,3.5+2.5*dir.x,4,5+3*dir.x,4,c)
    self:line(i,j,4+dir.x,4+dir.y,4+dir.x,4+dir.y,c)
end

function Map:roundOut(i,j,dir,c)
    self:line(i,j,4.5-3.5*dir.x,3+2*dir.y,4.5-3.5*dir.x,6+2*dir.y,c)
    self:line(i,j,4.5-2.5*dir.x,4-dir.y,4.5-2.5*dir.x,5-dir.y,c)
    self:line(i,j,3+2*dir.x,4.5-3.5*dir.y,6+2*dir.x,4.5-3.5*dir.y,c)
    self:line(i,j,4-dir.x,4.5-2.5*dir.y,5-dir.x,4.5-2.5*dir.y,c)
end

function Map:squareMiddle(i,j,dir,c)
    self:line(i,j,4,3+2*dir.y,4,5.5+2.5*dir.y,c)
    self:line(i,j,3+2*dir.x,4,5.5+2.5*dir.x,4,c)
    self:line(i,j,4,4,4,4,c)
end

function Map:squareIn(i,j,dir,c)
    self:line(i,j,4.5+3.5*dir.x,4.5+3.5*dir.y,4.5+3.5*dir.x,4.5+3.5*dir.y,c)
end

-- merges rects that can be merged
function Map:cacheOpt()
    for c,temp in pairs(self.cache) do
        -- join vertical rects
        local classi = {}
        for _,r in ipairs(self.cache[c]) do
            if not classi[r.x1] then classi[r.x1] = {} end
            if not classi[r.x1][r.x2] then classi[r.x1][r.x2] = {} end
            table.insert(classi[r.x1][r.x2],r)
        end
        
        self.cache[c] = {}
        for x1,rs1 in pairs(classi) do
            for x2,rs in pairs(rs1) do
                local ys = {}
                for _,r in ipairs(rs) do 
                    table.insert(ys,r.y1)
                    table.insert(ys,r.y2)
                end
                table.sort(ys)            
                -- remove end points that are the same to make it a single rect
                for yi = #ys-1,3,-2 do 
                    if math.abs(ys[yi]-ys[yi-1]) < 1 then
                        table.remove(ys,yi)
                        table.remove(ys,yi-1)
                    end
                end
                -- recreate the cache
                for yi = 1,#ys,2 do
                    table.insert(self.cache[c],{x1=x1,x2=x2,y1=ys[yi],y2=ys[yi+1]})
                end
            end
        end
        
        -- join horizontal rects
        classi = {}
        for _,r in ipairs(self.cache[c]) do
            if not classi[r.y1] then classi[r.y1] = {} end
            if not classi[r.y1][r.y2] then classi[r.y1][r.y2] = {} end
            table.insert(classi[r.y1][r.y2],r)
        end
        
        self.cache[c] = {}
        for y1,rs1 in pairs(classi) do
            for y2,rs in pairs(rs1) do
                local xs = {}
                for _,r in ipairs(rs) do 
                    table.insert(xs,r.x1)
                    table.insert(xs,r.x2)
                end
                table.sort(xs)            
                -- remove end points that are the same to make it a single rect
                for xi = #xs-1,3,-2 do 
                    if math.abs(xs[xi]-xs[xi-1]) < 1 then
                        table.remove(xs,xi)
                        table.remove(xs,xi-1)
                    end
                end
                -- recreate the cache
                for xi = 1,#xs,2 do
                    table.insert(self.cache[c],{y1=y1,y2=y2,x1=xs[xi],x2=xs[xi+1]})
                end
            end
        end
    end
end
