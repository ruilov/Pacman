Editor = class()

alreadyPrinted = false

function Editor:init(map)
    self.map = map
    self.editorMap = makeEditorMap(vec2(675,120),4)
end

function Editor:touched(touch)
    self.editorMap:touched(touch)
    local changed = self.map:touched(touch)        
    local v = self.editorMap:getSelectedV()
    if changed and v then self.map:setSelectedV(v) end
end

function Editor:draw()
    self.map:draw()
    self.editorMap:draw()
    if printMap == 0 then alreadyPrinted = false end
    if not alreadyPrinted and printMap == 1 then
        self.map:print()
        alreadyPrinted = true
    end
end


