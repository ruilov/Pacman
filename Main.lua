backgroundC = color(0, 0, 0, 255)
dt = 0
editor = nil
game = nil

function setup()
    setInstructionLimit(0)
    --displayMode(FULLSCREEN)
    --watch("dt")
    --watch("xx")
    editorMode = 0
    --iparameter("editorMode",0,1,0)
    --iparameter("printMap",0,1,0)    
    game = Game()
    --editor = Editor(game.level.map)
end

function touched(touch)
    if editorMode == 0 then
        game:touched(touch)
    else
        editor:touched(touch)
    end
end

function draw()  
    dt = DeltaTime*100   
    background(backgroundC)
    noSmooth()
    if editorMode == 0 then
        game:draw()
        xx = game.level.time
    else
        editor:draw()
    end
end



