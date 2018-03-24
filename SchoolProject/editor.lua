local js = require "js"
local __G = _G
local load = load
local pack, unpack = table.pack, table.unpack
local tostring = tostring
local traceback = debug.traceback
local insert = table.insert
local document = js.global.document
local xpcall = xpcall

local M = {} --All of the user globals

local newenv = setmetatable({}, {
        __index = function(t, k)
            local v = M[k]
            if v == nil then return __G[k] end
            return v;
        end,
        __newindex = M
    })

function js.global.runLua(window, code, outputElm) 
    --Reset user global table to a clean state
    M = {}
    M["_G"] = M
    --Redirect print and error to output box
    M.print = function(text)
        local msgElm = document:createTextNode(text)
        msgElm.className = "console-msg"
        outputElm:appendChild(msgElm)
        outputElm:appendChild(document:createElement("br"))
    end
    
    M.error = function(text)
        local msgElm = document:createTextNode(text)
        msgElm.className = "console-error"
        outputElm:appendChild(msgElm)
        outputElm:appendChild(document:createElement("br"))
    end
    
    --Clean output window
    while (outputElm:hasChildNodes()) do
        outputElm:removeChild(outputElm.firstChild);
    end 
    
    --Finnally load and run the code
    local fn, err = load(tostring(code), "sandbox", "bt", newenv)
    
    if fn then
        local results = pack(xpcall(fn, traceback))
        if results[1] then
            if results.n > 1 then
                M.print(unpack(results, 2, results.n))
            end
        else
            M.print(results[2])
        end
    else
        M.error(err)
    end
end