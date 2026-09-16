-- Language preference, live repaint and data-isolation boundaries.
local count = 0
local function check(value, message) count=count+1; assert(value,message) end
local language, opens = 'fr', 0
GetCVar = function(key) check(key=='language.2','Read only the ESO language setting');return language end
AlphaSquadUI = { Preferences = { Initialize=function() opens=opens+1 end, sv={} } }
assert(loadfile('AlphaSquadUI/Core/Localization.lua'))()
local ASUI, Loc = AlphaSquadUI, AlphaSquadUI.Localization
Loc.Register('fr',{READY='PRÊT',['%d missing']='%d absents',Unknown='Inconnu',Close='Fermer'})
check(ASUI.L('READY')=='PRÊT' and opens==0,'Manifest-time labels follow ESO without opening SavedVariables')
Loc.Initialize()
check(Loc.GetPreference()=='auto' and Loc.GetLanguage()=='fr','New installation follows French ESO')
check(ASUI.Preferences.sv.language=='auto','Automatic selection persists as auto, not a frozen locale')
local label = {SetText=function(self,text)self.text=text end}
Loc.Bind(label,'READY')
local dynamic = {SetText=label.SetText}
local number=3
Loc.Bind(dynamic,function()return '%d missing' end,number)
check(label.text=='PRÊT' and dynamic.text=='3 absents','Static and formatted labels use selected language')
local callbacks=0
Loc.RegisterCallback('test',function(resolved)
    callbacks=callbacks+1
    check(label.text==(resolved=='en' and 'READY' or 'PRÊT'),'Static labels repaint before dynamic windows')
end)
check(Loc.SetLanguage('en'),'Supported explicit language is accepted')
check(label.text=='READY' and dynamic.text=='3 missing' and callbacks==1,'All bound controls and windows change without reload')
check(Loc.SetLanguage('en') and callbacks==1,'Repeated preference does not redraw or allocate a timer')
check(not Loc.SetLanguage('de') and ASUI.Preferences.sv.language=='en','Unsupported override cannot corrupt the preference')
language='de';Loc.SetLanguage('auto')
check(Loc.GetLanguage()=='en','Other game languages safely fall back to English')
language='fr';Loc.SetLanguage('auto')
check(Loc.GetLanguage()=='fr' and label.text=='PRÊT','Auto can re-resolve the native language')
local untouched = '@Player %s |H1:item:999:0|h[READY]|h'
check(ASUI.L(untouched)==untouched,'No substring replacement inside player names, links or native text')
check(ASUI.L('%s missing',untouched)==untouched..' missing','Formatting inserts remote text only as data')
Loc.Register('fr',{['Bad %s']='Incorrect %d'})
check(ASUI.L('Bad %s','text')=='Bad text','Mismatched translation placeholders fall back safely')
Loc.Register('fr',{['Adds 10% Weapon Damage']='Ajoute 10% de dégâts des armes'})
check(ASUI.L('Adds 10% Weapon Damage')=='Ajoute 10% de dégâts des armes','Literal percentages in French prose are not treated as printf flags')
Loc.RegisterCallback('broken',function()error('Simulated repaint failure')end)
Loc.SetLanguage('en')
check(label.text=='READY' and callbacks==4,'One failed optional callback cannot block other windows')
Loc.UnregisterCallback('broken');Loc.UnregisterCallback('test');Loc.Unbind(label)
Loc.SetLanguage('fr')
check(label.text=='READY','Retired bindings cannot overwrite controls reused for player data')
Loc.sv=nil;Loc.language=nil;ASUI.Preferences.sv.language='broken';Loc.Initialize()
check(Loc.GetPreference()=='auto' and Loc.GetLanguage()=='fr','Invalid old value migrates to the game language')
ASUI.Preferences.sv.language='en';Loc.sv=nil;Loc.Initialize()
check(Loc.GetLanguage()=='en','Saved explicit choice wins over French client on reload')
assert(loadfile('AlphaSquadUI/Localization/fr.lua'))()
assert(loadfile('AlphaSquadUI/Localization/fr_catalog.lua'))()
check(ASUI.L('Unknown')=='Unknown','Dictionary load does not change selected language')
Loc.SetLanguage('fr')
check(ASUI.L('Unknown')=='Inconnu','The shipped French dictionary is available')
-- Prevent newly added literal UI strings from silently falling back to English.
local compile=loadstring or load
local manifest=assert(io.open('AlphaSquadUI/AlphaSquadUI.txt','r'))
for path in manifest:lines() do
    if path:match('%.lua$') and not path:match('^Localization/') and path~='Core/Localization.lua' then
        local file=assert(io.open('AlphaSquadUI/'..path,'r'));local content=file:read('*a');file:close()
        for literal in content:gmatch('L%(%s*("[^"\n]*")') do
            local read=compile('return '..literal)
            if read then
                local source=read()
                if source:find('[A-Za-z]') then
                    check(Loc.dictionaries.fr[source]~=nil,'Missing French UI key: '..source)
                end
            end
        end
    end
end
manifest:close()
-- The catalogue stores canonical English metadata; descriptions localize only at presentation.
ASUI.Modules={SupportCoverage={}}
assert(loadfile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageCatalog.lua'))()
local catalog=ASUI.Modules.SupportCoverage.Catalog
for _,effect in pairs(catalog.effects) do
    for _,field in ipairs({'description','conditions','duplicateRule'}) do
        check(Loc.dictionaries.fr[effect[field]]~=nil,'Missing French catalogue '..field..': '..tostring(effect[field]))
    end
    for _,provider in ipairs(effect.providers or {}) do
        check(Loc.dictionaries.fr[provider.conditions]~=nil,'Missing French provider condition: '..provider.conditions)
    end
end
print('Localization: '..count..' assertions passed')
