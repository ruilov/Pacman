Game = class()

function Game:init(x)
    self.lives = 5
    self.levelNum = 0
    self.score = 0
    self.font = Font()
    self:newLevel()
    self.music = ABCMusic(introTune)
end

function Game:newLevel()
    self.levelNum = self.levelNum + 1
    local lag = 0
    if self.levelNum > 1 then lag = 1 end
    self.level = Level(self.levelNum,self.lives,self.score,lag)
end

function Game:draw()
    playingIntro = self.music:play()
    
    local dt = DeltaTime / 1.1
    if playingIntro then dt = 0 end

    self.level:draw(dt)
       
    -- extra life
    if self.level.score > 10000 and not self.extraLife then
        self.level.lives = self.level.lives + 1
        self.extraLife = true
    end
    
    self.lives = self.level.lives
    self.score = self.level.score
    if self.level.won then self:newLevel() end
       
    local highScore = readLocalData("highscore",0)
    if self.score > highScore then
        saveLocalData("highscore",self.score)
    end
    
    -- draw text at the top
    strokeWidth(2)
    lineCapMode(ROUND)
    scale(0.6)
    self.font:drawstring("HIGH SCORE", 500, 1190)
    self.font:drawstring(highScore.."", 600, 1150)
    if self.level.gameOver or math.floor(ElapsedTime*2)%2==0 then
        self.font:drawstring("1UP", 200, 1190)
    end
    self.font:drawstring(self.score.."", 200, 1150)
end

function Game:touched(touch)
    self.level:touched(touch)
end
