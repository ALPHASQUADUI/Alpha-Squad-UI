-- Ąlpha Şquad UI - Shared event registry
-- Kept intentionally lightweight. Modules own their gameplay event subscriptions.
AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Events = AlphaSquadUI.Events or {}

function AlphaSquadUI.Events.MakeNamespace(moduleName, eventName)
    return string.format("AlphaSquadUI_%s_%s", tostring(moduleName or "Core"), tostring(eventName or "Event"))
end

-- Subscriptions belong to a module; disabling it removes its gameplay callbacks.
-- Loading/activation and shell geometry stay reachable so it can resume safely.
function AlphaSquadUI.Events.NewScope(always)
    local manager=EVENT_MANAGER
    local unpack=unpack or table.unpack
    local scope={active=true,events={}}
    local function Key(name,event) return tostring(name)..":"..tostring(event) end
    local function Attach(entry)
        manager:RegisterForEvent(entry.name,entry.event,entry.callback)
        for _,filter in ipairs(entry.filters) do manager:AddFilterForEvent(entry.name,entry.event,unpack(filter)) end
    end
    function scope:RegisterForEvent(name,event,callback)
        local key=Key(name,event)
        local entry={name=name,event=event,callback=callback,filters={},always=always and always(name,event)==true}
        self.events[key]=entry
        if self.active or entry.always then Attach(entry) end
    end
    function scope:AddFilterForEvent(name,event,...)
        local entry=self.events[Key(name,event)]
        if entry then entry.filters[#entry.filters+1]={...};if self.active or entry.always then manager:AddFilterForEvent(name,event,...) end end
    end
    function scope:UnregisterForEvent(name,event)
        self.events[Key(name,event)]=nil;manager:UnregisterForEvent(name,event)
    end
    function scope:SetActive(active)
        active=active==true;if self.active==active then return end;self.active=active
        for _,entry in pairs(self.events) do
            if not entry.always then
                if active then Attach(entry) else manager:UnregisterForEvent(entry.name,entry.event) end
            end
        end
    end
    function scope:RegisterForUpdate(...) return manager:RegisterForUpdate(...) end
    function scope:UnregisterForUpdate(...) return manager:UnregisterForUpdate(...) end
    return scope
end
