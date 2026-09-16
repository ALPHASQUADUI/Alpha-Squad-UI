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
check(Loc.GetPreference()=='fr' and Loc.GetLanguage()=='fr','New installation follows French ESO')
check(ASUI.Preferences.sv.language=='fr','Initial client language persists as the selected locale')
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
check(not Loc.SetLanguage('auto'),'The retired automatic selector is not accepted')
language='fr'
check(Loc.GetLanguage()=='en','Changing the native language does not override the saved choice')
Loc.SetLanguage('fr')
check(Loc.GetLanguage()=='fr' and label.text=='PRÊT','Explicit French selection refreshes labels')
local untouched = '@Player %s |H1:item:999:0|h[READY]|h'
check(ASUI.L(untouched)==untouched,'No substring replacement inside player names, links or native text')
check(ASUI.L('%s missing',untouched)==untouched..' missing','Formatting inserts remote text only as data')
Loc.Register('fr',{['Bad %s']='Incorrect %d'})
check(ASUI.L('Bad %s','text')=='Bad text','Mismatched translation placeholders fall back safely')
Loc.Register('fr',{['Adds 10% Weapon Damage']='Ajoute 10% de dégâts des armes'})
check(ASUI.L('Adds 10% Weapon Damage')=='Ajoute 10% de dégâts des armes','Literal percentages in French prose are not treated as printf flags')
Loc.RegisterCallback('broken',function()error('Simulated repaint failure')end)
Loc.SetLanguage('en')
check(label.text=='READY' and callbacks==3,'One failed optional callback cannot block other windows')
Loc.UnregisterCallback('broken');Loc.UnregisterCallback('test');Loc.Unbind(label)
Loc.SetLanguage('fr')
check(label.text=='READY','Retired bindings cannot overwrite controls reused for player data')
Loc.sv=nil;Loc.language=nil;ASUI.Preferences.sv.language='broken';Loc.Initialize()
check(Loc.GetPreference()=='fr' and Loc.GetLanguage()=='fr','Invalid old value migrates to the game language')
ASUI.Preferences.sv.language='en';Loc.sv=nil;Loc.Initialize()
check(Loc.GetLanguage()=='en','Saved explicit choice wins over French client on reload')
for _,case in ipairs({{'auto','fr','fr'},{'auto','de','en'},{false,'es','en'},{false,'FR','fr'}}) do
    ASUI.Preferences.sv.language=case[1] or nil;language=case[2];Loc.sv=nil;Loc.language=nil
    Loc.Initialize()
    check(Loc.GetPreference()==case[3] and ASUI.Preferences.sv.language==case[3],
        'Legacy, missing or unsupported preferences migrate to an explicit supported language')
    language=case[3]=='fr' and 'en' or 'fr';Loc.sv=nil;Loc.Initialize()
    check(Loc.GetPreference()==case[3],'A migrated locale remains stable after the game language changes')
end
Loc.SetLanguage('en')
assert(loadfile('AlphaSquadUI/Localization/NativeNames.lua'))()
assert(loadfile('AlphaSquadUI/Localization/fr.lua'))()
assert(loadfile('AlphaSquadUI/Localization/fr_catalog.lua'))()
check(ASUI.L('Unknown')=='Unknown','Dictionary load does not change selected language')
Loc.SetLanguage('fr')
check(ASUI.L('Unknown')=='Inconnu','The shipped French dictionary is available')
check(ASUI.L('BACK')=='RETOUR' and ASUI.L('BACK WEAPON BAR')=='ARRIÈRE',
    'Weapon bars and back navigation use distinct French context')
check(ASUI.L('CHARGING')=='EN CHARGE','Personal charging state is translated')
check(ASUI.L('Group Damage Shield')=='Bouclier de groupe','A duplicate key cannot overwrite the correct group shield label')
check(ASUI.L('Major Fortitude')=='Résilience majeure','Use the native French buff name rather than a literal cognate')
check(ASUI.L('Elemental Catalyst')=='Catalyseur élémentaire' and ASUI.L('Glittering Goad')=='L’Aiguillon luisant',
    'Verified catalog set headings follow the selected locale')
check(Loc.GetNativeName('ability',38563,'Native fallback')=='Cor de guerre'
    and Loc.GetNativeName('ability',40223,'Native fallback')=='Cor agressif',
    'Base skills and morphs retain their distinct verified names')
check(Loc.GetNativeName('ability',29230,'Native effect')=='Native effect',
    'A Standard effect ID cannot borrow the cast skill name')
check(Loc.GetNativeName('ability',28988,'Native fallback')=='Étendard des Chevaliers-dragons'
    and Loc.GetNativeName('ability',39075,'Native fallback')=='Chef de la meute',
    'The verified Standard and Pack Leader cast identities use native French names')
check(Loc.GetNativeName('set',768,'Native fallback')=='Les Échos lumineux',
    'A verified set identity resolves independently from client language')
check(Loc.GetNativeName('set',999999,untouched)==untouched and Loc.GetNativeName('ability',0,untouched)==untouched,
    'Unverified names remain untouched, including native links')
check(Loc.GetNativeName('set','768','Unverified')=='Unverified', 'Text is not coerced into a native identity')
Loc.SetLanguage('en')
check(ASUI.L('BACK WEAPON BAR')=='BACK' and Loc.GetNativeName('set',768,'Nom natif')=='Lucent Echoes',
    'Contextual English and set names restore without cached French')
Loc.SetLanguage('fr')
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
