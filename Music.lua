ABCMusic = class()
      
function ABCMusic:init(_ABCTune,LOOP,DEBUG,DUMP)
    self.DEBUG = DEBUG
    if self.DEBUG == nil then self.DEBUG = false end
    if DUMP == nil then DUMP = false end
    if _ABCTune == nil then
        print("No tune provided. Use ABCMusic(tunename)")
    end    
    self.LOOP = LOOP
    
    --watch("tempo")
    
    self.soundTablePointer=1
    
    soundTable = {}
    
    self.timeElapsedSinceLastNote = 0
    duration = 1
    tempDuration = 1
    tempo = 240 -- if no tempo is specified in the file, use this
    noteLength = (1/8) -- if no default note length is specified in the file, use this
    
    -- These are the names of the notes and their (trial and error) equivalent seed numbers 
    -- for the sound() function.  The , or ' tells us which octave it is.
    -- Further mapping of the seed address space would improve tonal quality.
    -- d' is highest note, D, is lowest, but 4 octaves are listed in case the tunes need them.
    notes = {
    ["C,"]=85,["D,"]=90,["E,"]=274,["F,"]=487,["G,"]=552,["A,"]=191,["B,"]=118,
    ["C"]=85,["D"]=321,["E"]=48,["F"]=63,["^F"]=436,["G"]=60,["A"]=68,["B"]=11,
    ["c"]=84,["^c"]=268,["d"]=96,["^d"]=280,["e"]=194,["f"]=993,["^f"]=386,["g"]=1372,
    ["^g"]=857,["a"]=1028,["^a"]=1481,["b"]=774,["c'"]=2742,["d'"]=737,["e'"]=1176,
    ["f'"]=198,["g'"]=342,["a'"]=582,["b'"]=422}
    
    -- These are the 'Guitar chords' and the notes making up each one.
    -- Further work needed to expand the range of chords known.
    chordList = {
    ["C"]={"C","E","G"},
    ["C7"]={"C","E","G"},
    ["D"]={"D","A"},
    ["D7"]={"D","A","c"},
    ["Dm"]={"D","F","A"},
    ["Dm7"]={"D","F","A","c"},
    ["F"]={"F","A","c"},
    ["G"]={"G","B","D"},
    ["G7"]={"G","B","D","F"},
    ["Am"]={"A","C","E"},
    ["Am7"]={"A","C","E","G"}}
    
    
      
    -- Print the raw ABC tune for debugging
    if DEBUG then print(_ABCtune) end
    
    -- This is a table of patterns that we use to match against the ABC tune.
    -- We use these to find the next, biggest meaningful bit of the tune.
    -- Lua patterns is like RegEx, in that we can specify parts of the match to be captured with
    -- sets of parentheses.
    -- Not all tokens have been implemented yet, but at least we understand
    -- musically what is going on.
    tokenList = {
        TOKEN_REFERENCE = "^X:(.-)\n",
        TOKEN_TITLE = "^T:(.-)\n",
        TOKEN_KEY = "%[?K:(%a-)[%]\n]", -- matches optional inline [K:...]
        TOKEN_METRE = "%[?M:(.-)[%]\n]",
        TOKEN_DEFAULT_NOTE_LENGTH = "%[?L:(%d-)%/(%d-)[%]\n]",
        TOKEN_TEMPO = "%[?Q:(%d-)[%]\n]",
        TOKEN_CHORD_DURATION = '%[([%^_]?[a-gA-G][,\']?%d?/?%d?.-)%]',
        TOKEN_GUITAR_CHORD = '"(%a+%d?)"',
        TOKEN_START_REPEAT = '|:',
        TOKEN_END_REPEAT = ':|',
        TOKEN_END_REPEAT_START = ":|?:",
        TOKEN_NUMBERED_REPEAT_START = "[|%[]%d",
        TOKEN_NOTE_DURATION = '([%^_]?[a-gA-G][,\']?)(%d?/?%d?)',
        TOKEN_PREV_DOTTED_NEXT_HALVED = ">",
        TOKEN_PREV_HALVED_NEXT_DOTTED = "<",
        TOKEN_SPACE = " ",
        TOKEN_BARLINE = "|",
        TOKEN_DOUBLE_BARLINE = "||",
        TOKEN_THIN_THICK_BARLINE = "|%]",
        TOKEN_NEWLINE = "\n",
        TOKEN_DOUBLE_FLAT = "__",
        TOKEN_DOUBLE_SHARP = "%^^",
        TOKEN_ACCIDENTAL = "[_=\^]",
        TOKEN_REST_DURATION = "(z)(%d?/?%d?)",
        TOKEN_REST_MULTIMEASURE = "(Z)(%d?)",
        TOKEN_TRILL = "~",
        TOKEN_START_SLUR = "%(",
        TOKEN_END_SLUR = "%)",
        TOKEN_STACATO = "%.",
        TOKEN_TUPLET = "%(([1-9])([a-gA-G][,']?[a-gA-G]?[,']?[a-gA-G]?[,']?)",
        TOKEN_TIE = "([a-gA-G][,\']?%d?/?%d?)%-|?([a-gA-G][,\']?%d?/?%d?)",
        TOKEN_MISC_FIELD = "^[(ABCDEFGHIJNOPRSUVWYZmrsw)]:(.-)\n"} -- no overlap with 
                                                -- already specified fields like METRE or KEY

    self:parseTune(_ABCTune)
    self:createSoundTable()
    if DUMP then
        self.dump(soundTable) -- for debugging
    end
end


function ABCMusic:parseTune(destructableABCtune)
    
    -- Go through each token and find the first match in the tune.  Use the biggest lowest
    -- starting index and then discard the characters that matched.
    
    local lastLongest = 0
    parsedTune = {}
    
    -- We create a copy of the tune to whittle away at.
    --destructableABCtune = ABCtune
    
    -- Iterate through the tune until none left
    while true do
        
        -- Loop through all tokens to see which one matches the start of the whittled tune.
        for key, value in pairs(tokenList) do
            
            token = value
            -- Find the start and end index of the token match, plus record what was in the 
            -- pattern capture parentheses.  I pulled out a max two captures for each match, which
            -- seemed adequate.
            startIndex, endIndex, capture1, capture2 = string.find(destructableABCtune, token)
            if startIndex == nil then startIndex = 0 end
            if endIndex == nil then endIndex = 0 end
            -- Get the actual match from the tune
            tokenMatch = string.sub(destructableABCtune,startIndex, endIndex)
        
            -- Take the one that matches the start of the whittled tune.
            if startIndex == 1 then
                
                -- In case there are two possible matches, then take the biggest one.    
                -- This shouldn't happen if the token patterns are right.
                if endIndex > lastLongest then
                   
                    lastLongest = endIndex
                    lastToken = key
                    lastTokenMatch = tokenMatch
                    captureFinal1 = capture1
                    captureFinal2 = capture2
                end
            end
        end
        
        if lastTokenMatch == "" then
            print("No match found for character ".. string.sub(destructableABCtune,1,1) )
            -- set the whittler to trim the strange character away
            lastLongest = 1
        else
            -- Build a table containing the parsed tune.
            -- Due to iterative delays in the print function needed for debugging, we will use
            -- a 4-strided list for quicker printing it later with table.concat().
            table.insert(parsedTune,lastToken)
            table.insert(parsedTune,lastTokenMatch)
            
            -- Where no captures occurred, we will just fill the table item with 1,
            -- which will be the default duration of a note that has no length modifier.
            if captureFinal1 == "" or captureFinal1 == nil then captureFinal1 = 1 end
            if captureFinal2 == "" or captureFinal2 == nil then captureFinal2 = 1 end
            
            table.insert(parsedTune,captureFinal1)
            table.insert(parsedTune,captureFinal2)
        end
        
        -- Whittle off the match
        destructableABCtune = string.sub(destructableABCtune, lastLongest + 1)
        
        -- Stop the loop once we have no tune left to parse
        if string.len(destructableABCtune) == 0 then
            break
        end
         
        -- Clear the variables       
        lastLongest = 0
        lastToken = ""
        lastTokenMatch = ""
    end
    
    -- For debugging purposes, print the whole parsed tune.
    if self.DEBUG then print(table.concat(parsedTune,"\n")) end
end


function ABCMusic:createSoundTable()
    -- Here we interpret the parsed tune into a table of notes to play and for how long.
    -- The upside of an intermediate process is that there will be no parsing delays to lag
    -- things if we are playing music in the middle of a game.  It is also easier to debug!
    -- On the other hand, ABC format allows for inline tempo or metre changes. To comply
    -- we would need to either switch duration to seconds rather than beats, or implement another
    -- parsing thing during playback...
    
    local tempChord={}
    local parsedTunePointer = 1
    while true do
        
        if parsedTune[parsedTunePointer] == nil then break end
        
        -- Break out our 4-strided list into the token, what it actually matched, and the
        -- two captured values.
        token = parsedTune[parsedTunePointer]
        rawMatch = parsedTune[parsedTunePointer + 1]
        value1 = parsedTune[parsedTunePointer + 2]
        value2 = parsedTune[parsedTunePointer + 3]
        
        -- Doing anything here seems to take forever.
        -- print(token.."\n"..rawMatch.."\n"..value1.."\n"..value2) end
    
        if token == "TOKEN_TEMPO" then
            ptempo = tonumber(value1)
            --iparameter("ptempo", 40, 480, tempo)
        end
        
        if token == "TOKEN_DEFAULT_NOTE_LENGTH" then
            noteLength = value2
            -- Set the tempo, eg if you wanted one quarter note or crotchet per second
            -- you would set Q:60 and L:1/4
            tempo = tempo * (noteLength/4)
            if self.DEBUG then print("Tempo is " .. tempo) end
        end
        
        if token == "TOKEN_NOTE_DURATION" then
            duration = value2
            if duration == "/2" then duration = (1/2) end
            if duration == "3/2" then duration = (3/2) end
            -- If there are chords to play at the same time, they will be in the tempChord table.
            table.insert(tempChord,{value1, duration})
            table.insert(soundTable,tempChord)
            tempChord = {}
        end 
        
        if token == "TOKEN_TIE" then
            duration = string.sub(value1,-1) + string.sub(value2,-1)
            value1 = string.sub(value1,1,string.len(value1)-1)
            table.insert(soundTable,{{value1, duration}})
        end
        
        if token == "TOKEN_TUPLET" then
            -- More types of tuplets exist, up to 9, but need more work.
            if value1 == "2" then
                duration = 1.5 -- the 2 signals two notes in the space of three
                -- We reprocess the notes making up the tuplet
                for i = 1, string.len(value2) do
                    note,noteLength = string.match(value2,tokenList["TOKEN_NOTE_DURATION"],i)
                    table.insert(soundTable,{{note, duration}})
                end
            end  
            
            if value1 == "3" then
                duration = 0.333 -- the 3 signals three notes in the space of two
                -- We reprocess the notes making up the tuplet
                for i = 1, string.len(value2) do
                    note,noteLength = string.match(value2,tokenList["TOKEN_NOTE_DURATION"],i)
                    table.insert(soundTable,{{note, duration}})
                end
            end            
        end
        
        if token == "TOKEN_GUITAR_CHORD" then
            -- The ABC standard leaves it up to the software how to interpret guitar chords,
            -- but they should precede notes in the ABC tune.  I'm just going with a vamp.
            duration = 0
            tempChord = {}
            if chordList[value1] == nil then
               print("Chord ".. value1.. " not found in chord table.")
            else
                for key, value in pairs(chordList[value1]) do
                    -- This places the notes of the chord into a temporary table which will
                    -- be appended to by the next non-chord note.
                    table.insert(tempChord,{value, duration})
                end        
            end         
        end
        
        if token == "TOKEN_CHORD_DURATION" then
            -- These are arbitrary notes sounded simultaneously.  If their durations are
            -- different that could cause trouble.
            while true do
                -- Do this loop unless we hace already whittled away the chord into notes.
                if string.len(rawMatch) <= 1 then
                    break
                end
                
                -- Reprocess the chord into notes and durations.
                startIndex, endIndex, note, noteDuration =
                    string.find(rawMatch,tokenList["TOKEN_NOTE_DURATION"])
            
                if noteDuration == "" or noteDuration == nil then noteDuration = 1 end
                
                -- This places the notes of the chord into a temporary table which will
                -- be appended to the sound table at the end of the chord.
                table.insert(tempChord,{note, noteDuration})
                -- Whittle away the chord
                rawMatch = string.sub(rawMatch, endIndex + 1) 
            end
            -- Append chord to sound table.
            table.insert(soundTable,tempChord)
            tempChord = {}
        end       
        -- Move to the next token in our strided list of 4.
        parsedTunePointer = parsedTunePointer + 4
    end
end

function ABCMusic:fromTheTop()
   self.soundTablePointer = 1
end 

function ABCMusic:play()
    -- Step through the parsed tune and decide whether to play the next bit yet.
    
    if ptempo ~= nil then
        tempo = ptempo
    end
    
    -- This normalises the tempo to smooth out lag between cumlative frames.  Meant to be the
    -- same idea for smoothing out animation under variable processing loads.
    self.timeElapsedSinceLastNote = self.timeElapsedSinceLastNote + DeltaTime
    local framesToBeSkipped = ( 60 / ((tempo) / 60 ) ) * (duration/2) -- tempo = bpm, so / by 60 for bps
    
    -- If there is still a tune and it's time for the next set of notes
    if framesToBeSkipped <= (self.timeElapsedSinceLastNote * 60 ) -- multiply time by 60 to get frames
         and self.soundTablePointer <= #soundTable then            -- because draw() is 60 fps
            
        -- Step through the set of notes nested in the sound table, finding each note and
        -- its duration.  If we had volume, we would also want to record it in the most nested
        -- table.
        -- The operator # gives us the number of elements in a table until a blank one - see Lua 
        -- documentation.
        -- Luckily our table will never have holes in it, or the notes would fall through.
        -- The sound table looks like:
        -- 1:    1:    1:    C
        --             2:    4
        --       2:    1:    E
        --             2:    4
        -- 2: etc...
        for i = 1, #soundTable[self.soundTablePointer] do 
            oldTempDuration = tempDuration
            -- This line plays the note currently being pointed to.  If it is part of a set
            -- to be played at once, this will loop around without delay.
            sound(SOUND_BLIT, notes[soundTable[self.soundTablePointer][i][1]])
            tempDuration = tonumber(soundTable[self.soundTablePointer][i][2])
    
            -- Keep the longest note duration of the set of notes to be played together,
            -- to be used as one of the inputs for the delay until the next note.  
            if oldTempDuration > tempDuration then
                tempDuration = oldTempDuration
            end
        end
       
        duration = tempDuration
        oldTempDuration=0
        tempDuration = 0
        
        -- Looping music... we need a better way to do this...
        if self.LOOP ~= nil and self.soundTablePointer == #soundTable then 
            self.soundTablePointer = 1
        else
            -- Increment the pointer in our sound table.
            self.soundTablePointer = self.soundTablePointer + 1
        end
        
        -- Reset counters rather than going to infinity and beyond.
        self.timeElapsedSinceLastNote = 0
    end
    
    return( self.soundTablePointer <= #soundTable)
end

-- Handy function from Pixel to only use for debugging and if the ABCtube is a line long,
-- 'cos it is slow.
-- print contents of a table, with keys sorted. 
-- second parameter is optional, used for indenting subtables
function ABCMusic:xdump(t,indent)
    local names = {}
    if not indent then indent = "" end
    for n,g in pairs(t) do
        table.insert(names,n)
    end
    table.sort(names)
    for i,n in pairs(names) do
        local v = t[n]
        if type(v) == "table" then
            if(v==t) then -- prevent endless loop if table contains reference to itself
                print(indent..tostring(n)..": <-")
            else
                print(indent..tostring(n)..":")
                dump(v,indent.."   ")
            end
        else
            if type(v) == "function" then
                print(indent..tostring(n).."()")
            else
                print(indent..tostring(n)..": "..tostring(v))
            end
        end
    end
end
