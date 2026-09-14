-- Branding preserves native UTF-8 glyphs without depending on pattern semantics.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
AlphaSquadUI={}
local original=string.gmatch
string.gmatch=function() error("Branding must not depend on byte-range pattern matching in the ESO client") end
assert(loadfile("AlphaSquadUI/Core/Theme.lua"))()
string.gmatch=original
local theme=AlphaSquadUI.Theme
local function Plain(value) return value:gsub("|c%x%x%x%x%x%x",""):gsub("|r","") end
check(Plain(theme.brandText)=="Ąlpha Şquad UI","Extended Latin brand initials survive exact UTF-8 color markup")
check(theme.brandText:find("|cFF6F0CĄ|r",1,true)==1,"The first gradient color encloses the complete initial glyph")
check(theme.brandText:find("|cFFFFFFUI|r",1,true)~=nil,"UI retains explicit white markup")
check(Plain(theme.Gradient("Aé雪😀",{0,0,0},{255,255,255}))=="Aé雪😀","One through four byte glyphs remain unchanged")
check(Plain(theme.authorText)=="@SeRuM1" and theme.PlayerName("@SeRuM1")==theme.authorText,"Author styling retains only the public account name")
check(theme.PlayerName("|cFFFFFF@Player|r |Hbad")=="@Player ||Hbad","Other player text cannot inject color or hyperlink markup")
check(Plain(theme.Brand("Builds"))=="Ąlpha Şquad UI  •  Builds","Window titles retain both branded initials and their section")
print(string.format("PASS: %d assertions; Lua %s. No ESO-runtime certification.",total,_VERSION))
