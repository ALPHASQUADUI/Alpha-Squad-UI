-- Ąlpha Şquad UI - Shared theme tokens
AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Theme = AlphaSquadUI.Theme or {}

local Theme = AlphaSquadUI.Theme
Theme.colors = Theme.colors or {
    bg = {0.010, 0.016, 0.030, 0.96},
    panel = {0.020, 0.030, 0.052, 0.98},
    panelActive = {0.050, 0.035, 0.020, 0.99},
    orange = {1.00, 0.58, 0.16, 1.00},
    white = {0.95, 0.97, 1.00, 1.00},
    muted = {0.53, 0.62, 0.72, 1.00},
    green = {0.34, 0.82, 0.52, 1.00},
    red = {1.00, 0.30, 0.35, 1.00},
    gold = {0.97, 0.78, 0.30, 1.00},
    cyan = {0.20, 0.82, 1.00, 1.00},
    cyanDim = {0.10, 0.36, 0.49, 1.00},
}

-- UTF-8 aware, static color markup: no animation and no frame callbacks.
function Theme.Gradient(text,first,last)
    local chars={};for char in tostring(text):gmatch("[%z\1-\127\194-\244][\128-\191]*") do chars[#chars+1]=char end
    local out={}
    for i,char in ipairs(chars) do
        local t=(i-1)/math.max(1,#chars-1)
        local r=math.floor(first[1]+(last[1]-first[1])*t+0.5)
        local g=math.floor(first[2]+(last[2]-first[2])*t+0.5)
        local b=math.floor(first[3]+(last[3]-first[3])*t+0.5)
        out[#out+1]=string.format("|c%02X%02X%02X%s",r,g,b,char)
    end
    return table.concat(out).."|r"
end
Theme.brandText=Theme.Gradient("Ąlpha Şquad",{255,111,12},{255,184,62}).." |cFFFFFFUI|r"
Theme.authorText=Theme.Gradient("@SeRuM1",{78,158,255},{102,222,255})
function Theme.Brand(section) return Theme.brandText..(section and ("  •  "..section) or "") end
function Theme.PlayerName(name)
    local clean=(tostring(name or ""):gsub("|[cC]%x%x%x%x%x%x",""):gsub("|[rR]",""):gsub("|","||"))
    return clean=="@SeRuM1" and Theme.authorText or clean
end
