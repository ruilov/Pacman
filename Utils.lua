function mapcar(tab,f)
    local ans = {}
    for _,elem in ipairs(tab) do table.insert(ans,f(elem)) end
    return(ans)
end

function foldl(tab,f,init)
    local ans = init
    for _,elem in ipairs(tab) do ans = f(elem,ans) end
    return(ans)
end

function addF(x,y)
    return(x+y)
end

function printElem(x)
    print(x)
    return(x)
end

function tableSum(tab,init)
    return(foldl(tab,addF,init))
end

function tablePrint(tab)
    mapcar(tab,printElem)
end

function random()
    return(math.random())
end

-- discretise returns one of the four cardinal directions, whichever is strongest
function discretise(dx,dy)
    if math.abs(dx) > math.abs(dy) then
        return( vec2(dx/math.abs(dx),0) )
    else
        return( vec2(0,dy/math.abs(dy)) )
    end
end

function wrappedTunnel(pos)
    if pos == vec2(0,19) then pos = vec2(28,19) 
    elseif pos == vec2(29,19) then pos = vec2(1,19) end
    return(pos)
end
