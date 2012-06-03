maxSpeed = 73.4  -- pix/s

function fruitScore(lev)
    if lev == 1 then return(100)
    elseif lev == 2 then return(300)
    elseif lev == 3 or lev == 4 then return(500)
    elseif lev == 5 or lev == 6 then return(700)
    elseif lev == 7 or lev == 8 then return(1000)
    elseif lev == 9 or lev == 10 then return(2000)
    elseif lev == 11 or lev == 12 then return(3000)
    else return(5000) end
end

-- at what dot count do ghosts leave pen. only active at the start of the level
function penDotCounts(lev)
    if lev == 1 then
        return({inky=30,clyde=90})
    elseif lev == 2 then
        return({inky=0,clyde=50})
    else
        return({inky=0,clyde=0})
    end
end

-- if pacman stops eating dots this forces a ghost out after some time
function penMaxTime(lev)
    if lev < 5 then return(4) else return(2) end
end

-- how long ghosts stay in fright time for
function frightTimes(lev)
    local ts = {6,5,4,3,2,5,2,2,1,5,2,1,1,3,1,1,0,1}
    if lev > #ts then return(0) else return(ts[lev]) end   
end

-- times for the scatter/chase loops. scatter then chase and so on
function ghostModeTimes(lev)
    if lev == 1 then
        return({7,20,7,20,5,20,5})
    elseif lev <= 4 then
        return({7,20,7,20,5,1033,1/60})
    else
        return({5,20,5,20,5,1037,1/60})
    end
end

-- actor speeds at various modes
function levelSpeeds(lev)
    if lev == 1 then
        return({pacman=.8,pacfri=.9,ghost=.75,ghostfri=.5,tunnel=.4,pen=.8})
    elseif lev <= 4 then
        return({pacman=.9,pacfri=.95,ghost=.85,ghostfri=.55,tunnel=.45,pen=.8})
    elseif lev <= 20 then
        return({pacman=1,pacfri=1,ghost=.95,ghostfri=.6,tunnel=.5,pen=.8})
    else
        return({pacman=.9,pacfri=.9,ghost=.95,ghostfri=.5,tunnel=.5,pen=.8})
    end
end

introTune =
     'X:1\n'
    ..'T:Pac Man Theme\n'
    ..'C:Toshio Kai (甲斐敏夫) arr. Fred Bogg Copyright NAMCO\n'
    ..'Q:260\n'
    ..'M:4/4\n'
    ..'L:1/16\n'
    ..'K:B\n'
    ..'[B,B]b^f[B^d] b/2^f3/2^dB [C,C]c\'g[Ce] c\'/2g3/2[Ce]C|\n'
    ..'[B,B]b^f[B^d] b/2^f3/2^dB ^d/2e/2[^gf]f/2^f/2[^ag]g/2^g/2ab2'
    

defaultMap =
"0000000000000000000000000000"..
"0000000000000000000000000000"..
"0000000000000000000000000000"..
"gddddddddddddmnddddddddddddh"..
"a77777777777711777777777777b"..
"a75226752226711752226752267b"..
"a81001710001711710001710018b"..
"a73224732224734732224732247b"..
"a77777777777777777777777777b"..
"a75226756752222226756752267b"..
"a73224711732265224711732247b"..
"a77777711777711777711777777b"..
"ecccc671322601105224175ccccf"..
"00000a7152240340322617b00000"..
"00000a7110000000000117b00000"..
"00000a7110qcsuutcr0117b00000"..
"ddddd47340b000000a03473ddddd"..
"0000007000b000000a0007000000"..
"ccccc67560b000000a05675ccccc"..
"00000a7110oddddddp0117b00000"..
"00000a7110000000000117b00000"..
"00000a7110522222260117b00000"..
"gdddd473403226522403473ddddh"..
"a77777777777711777777777777b"..
"a75226752226711752226752267b"..
"a73261732224734732224715247b"..
"a87711777777700777777711778b"..
"i26711756752222226756711752j"..
"k24734711732265224711734732l"..
"a77777711777711777711777777b"..
"a75222243226711752243222267b"..
"a73222222224734732222222247b"..
"a77777777777777777777777777b"..
"eccccccccccccccccccccccccccf"..
"0000000000000000000000000000"..
"0000000000000000000000000000"
