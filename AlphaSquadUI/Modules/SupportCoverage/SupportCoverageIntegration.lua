-- Final integration of optional audits, evidence-aware sharing and bounded UI.
-- This adapter keeps Support Coverage cross-component rules in one final load step.
local SC=AlphaSquadUI.Modules.SupportCoverage
local Catalog=SC.Catalog
local Try=SC.Try
local Copy=SC.Audit.Copy
local wireKeys=Catalog.wireV2Keys or Catalog.wireV1Keys
local wireV1Count=#(Catalog.wireV1Keys or {})
local wireIndex={};for i,key in ipairs(wireKeys) do wireIndex[key]=i-1 end
-- wire v2 uses 81 capability bits. The remaining 15 high bits in cap4 carry a
-- non-zero fingerprint of the signature frame, without changing the LGB schema.
local DETAIL_FINGERPRINT_SCALE=512
local DETAIL_FINGERPRINT_MODULUS=SC.Details and SC.Details.FINGERPRINT_MODULUS or 32767
local roles={"UNKNOWN","MT","OT","HEAL","DD PARSE","DD SUPPORT","MT/OT","H1","H2"}
local roleId={};for index,role in ipairs(roles) do roleId[role]=index-1 end
local profiles={"full","progression","damage","trash","boss","custom"}
local profileId={};for index,profile in ipairs(profiles) do profileId[profile]=index end
local function SafeMasks(data)
    for index=1,4 do
        local value=data["cap"..index]
        if type(value)~="number" or value<0 or value>16777215 or value%1~=0 then return false end
    end
    return true
end
local function Decode(data)
    local capabilities={}
    local count=data.version==1 and wireV1Count or #wireKeys
    for index=1,count do
        local key=wireKeys[index]
        local zero=index-1
        local value=data["cap"..(math.floor(zero/24)+1)]
        if math.floor(value/2^(zero%24))%2==1 then capabilities[key]={sources={["ASUI v"..tostring(data.version).." capability"]=true},evidence="PEER_CAPABILITY_HINT"} end
    end
    return capabilities
end
local function SignatureFingerprint(snapshot)
    if not SC.Details or not SC.Details.Encode or not SC.Details.Checksum then return nil end
    local body=SC.Details.Encode(snapshot)
    if not body then return nil end
    return SC.Details.Checksum(body)%DETAIL_FINGERPRINT_MODULUS+1
end
local function AdvertisedFingerprint(data)
    if type(data)~="table" or data.version~=2 then return nil end
    local value=math.floor((tonumber(data.cap4) or 0)/DETAIL_FINGERPRINT_SCALE)
    if value<1 or value>DETAIL_FINGERPRINT_MODULUS then return nil end
    return value
end
function SC:IsCurrentGroupMember(tag)
    if not tag or not self:IsGrouped() then return false end
    local size=tonumber(Try(GetGroupSize)) or 0
    if size~=size or size==math.huge or size==-math.huge then return false end
    for index=1,math.min(12,math.max(0,math.floor(size))) do
        local other=Try(GetGroupUnitTagByIndex,index) or ("group"..index)
        if other==tag or Try(AreUnitsEqual,other,tag)==true then return true end
    end
    return self:IsSelf(tag)
end
local function MayReceive(sc,tag)
    return sc.sv and sc.sv.enabled and sc.sv.shareData and sc.sv.experimentalSharing
        and sc:IsCurrentGroupMember(tag) and not sc:IsSelf(tag)
end

local buildPayload=SC.BuildSharePayload
function SC:BuildSharePayload()
    local payload=buildPayload(self)
    if not payload then return end
    for index=1,4 do payload["cap"..index]=0 end
    for key in pairs(self.localSnapshot.capabilities or {}) do
        local index=wireIndex[key]
        if index then
            local field="cap"..(math.floor(index/24)+1)
            payload[field]=payload[field]+2^(index%24)
        end
    end
    local fingerprint=SignatureFingerprint(self.localSnapshot)
    if fingerprint then payload.cap4=payload.cap4+fingerprint*DETAIL_FINGERPRINT_SCALE end
    return payload
end
local receiveBuild=SC.OnPeerShareData
function SC:OnPeerShareData(tag,data)
    if not MayReceive(self,tag) or type(data)~="table" or (data.version~=1 and data.version~=2) or not SafeMasks(data) then return end
    local key=self:GetPlayerKey(tag)
    local previous=self.peerData[key] or {}
    local advertisedFingerprint=AdvertisedFingerprint(data)
    if receiveBuild(self,tag,data)~=true then return end
    local peer=self.peerData[key]
    if not peer then return end
    peer.capabilities=Decode(data)
    for _,field in ipairs({"liveCapabilities","liveKnownKeys","liveUpdatedAt","verifiedLiveUpdatedAt","potionEvidence"}) do
        peer[field]=previous[field]
    end
    if advertisedFingerprint and previous.detailBuildFingerprint==advertisedFingerprint then
        for _,field in ipairs({"auditHashes","detailChecksum","detailAt","detailAliveAt","detailRevision",
            "detailsEvidence","detailBuildFingerprint"}) do peer[field]=previous[field] end
    end
    peer.buildDetailFingerprint=advertisedFingerprint
    peer.connected=self:IsOnline(tag)
    -- Build protocols do not carry equipped counts. Never invent five-piece sets
    -- from presence bits.
    for _,set in ipairs(peer.equipment and peer.equipment.setList or {}) do set.equipped=nil end
end
local receiveLive=SC.OnPeerLiveData
function SC:OnPeerLiveData(tag,data)
    if not MayReceive(self,tag) then return end
    return receiveLive(self,tag,data)
end
function SC:GetLocalLiveCapabilities()
    local effects,complete=self:ObserveEffectsOnUnit("player")
    self.localLive={capabilities=effects,complete=complete,updatedAt=self.NowMs()}
    return effects
end
local initializeSharing=SC.InitializeSharing
function SC:InitializeSharing()
    if not self.sv or not self.sv.enabled or not self.sv.experimentalSharing then
        self.share.available=false
        self.share.error="Experimental sharing is OFF. Unreserved IDs 507-510 are for controlled tests only."
        return
    end
    if self.share.handler then
        self.share.available=self.share.protocol~=nil and self.share.liveProtocol~=nil and self.share.planProtocol~=nil
        if not self.share.detailProtocol and self.InitializeDetailSharing then
            self:InitializeDetailSharing(rawget(_G,"LibGroupBroadcast"),self.share.handler)
        end
        return
    end
    if self.share.registrationAttempted then return end
    self.share.registrationAttempted=true
    local library=rawget(_G,"LibGroupBroadcast")
    initializeSharing(self)
    if self.share.handler and self.InitializeDetailSharing then
        self:InitializeDetailSharing(library,self.share.handler)
    end
    -- A library may become ready after our first initialization callback. Keep
    -- explicit enable/toggle actions retryable only when the library itself was
    -- unavailable. A partial handler/protocol failure may already have reserved
    -- names inside LGB and must not be retried as a duplicate registration.
    if not self.share.handler and (not library or type(library.RegisterHandler)~="function") then
        self.share.registrationAttempted=false
    end
end
local shareBuild=SC.ShareLocalSnapshot
local shareLive=SC.ShareLiveSnapshot
function SC:ShareLocalSnapshot(reason)
    if not self.sv.enabled or not self.sv.shareData or not self.sv.experimentalSharing or self.inCombat then return false end
    local fingerprint=SignatureFingerprint(self.localSnapshot)
    local previousFingerprint=self.share.lastBuildFingerprint
    local sent=shareBuild(self,reason)
    if sent then
        self.share.lastBuildFingerprint=fingerprint
        if self.share.detailProtocol then
            local detailSent=self:QueueBuildDetails(self.detailSharePending==true or previousFingerprint~=fingerprint)
            if detailSent then self.detailSharePending=false end
        end
    end
    return sent
end
function SC:ShareLiveSnapshot()
    return shareLive(self)
end
function SC:GetSharingStatus()
    if not self.sv.experimentalSharing or not self.sv.shareData then return "LOCAL", "Experimental sharing is disabled" end
    if self.share and self.share.available then return "TEST LGB", self.share.detailError end
    return "LOCAL", self.share and self.share.error or "LibGroupBroadcast unavailable"
end

local receiveDetails=SC.OnDetailData
function SC:OnDetailData(tag,data)
    if not MayReceive(self,tag) then return end
    receiveDetails(self,tag,data)
    local peer=self.peerData[self:GetPlayerKey(tag)]
    if not peer then return end
    if peer.detailAt and self.NowMs()-math.max(peer.detailAt,peer.detailAliveAt or 0)<=120000 then
        peer.asui=true;peer.dataQuality="ASUI DETAILS";peer.connected=self:IsOnline(tag)
        -- No flag claims a complete build. Individual fields independently carry evidence.
    end
    local entry=self.byKey and self.byKey[self:GetPlayerKey(tag)]
    if entry then
        for _,field in ipairs({"liveCapabilities","liveKnownKeys","liveUpdatedAt","verifiedLiveUpdatedAt",
            "auditHashes","detailAt","detailAliveAt","detailChecksum","buildDetailFingerprint",
            "detailBuildFingerprint"}) do entry[field]=peer[field] end
    end
end

function SC:BroadcastPlan()
    if not self.sv.enabled or not self.sv.shareData or not self.sv.experimentalSharing or self.inCombat
        or not self:IsGrouped() or not self:IsRaidLead() then return false end
    local protocol=self.share and self.share.planProtocol
    if not protocol or (protocol.IsEnabled and not protocol:IsEnabled()) then return false end
    self.share.lastPlanAttemptAt=self.NowMs()
    self.share.planRevision=((self.share.planRevision or 0)%250)+1
    local revision=self.share.planRevision
    local success=true
    local function Send(kind,key,owner)
        local ok,queued=pcall(protocol.Send,protocol,{revision=revision,kind=kind,key=key,ownerHash=owner})
        if not ok or queued~=true then success=false end
    end
    Send(0,profileId[self.sv.activeProfile] or 1,0)
    local function Hash(value)
        local hash=216613;value=tostring(value):lower()
        for i=1,#value do hash=(hash*131+value:byte(i))%16777215 end
        return hash
    end
    for _,row in ipairs(self.coverage.entries or {}) do
        if row.assigned and wireIndex[row.key] then Send(1,wireIndex[row.key],Hash(row.assigned.key)) end
    end
    for key,role in pairs(self.sv.roleOverrides) do
        if self.byKey[key] and roleId[role] then Send(2,roleId[role],Hash(key)) end
    end
    if success then
        self.lastPlanSignature=self:GetPlanSignature()
        self.share.lastPlanSentAt=self.NowMs()
    end
    return success
end
function SC:MaybeBroadcastPlan()
    local now=self.NowMs()
    local changed=self:GetPlanSignature()~=self.lastPlanSignature
    local heartbeatDue=now-(self.share.lastPlanSentAt or -300000)>=300000
    if self.sv.enabled and self.sv.shareData and self.sv.experimentalSharing and not self.inCombat
        and self:IsGrouped() and self:IsRaidLead() and (changed or heartbeatDue)
        and now-(self.share.lastPlanAttemptAt or 0)>=5000 then self:SchedulePlanBroadcast() end
end
function SC:OnPlanData(tag,data)
    if not MayReceive(self,tag) or Try(IsUnitGroupLeader,tag)~=true or type(data)~="table" then return end
    local revision,kind,key,hash=tonumber(data.revision),tonumber(data.kind),tonumber(data.key),tonumber(data.ownerHash)
    if not revision or revision<1 or revision>250 or revision%1~=0 or not kind or kind<0 or kind>2 or kind%1~=0
        or not key or key<0 or key>127 or key%1~=0 or not hash or hash<0 or hash>16777215 or hash%1~=0 then return end
    local sender=self:GetPlayerKey(tag)
    if kind==0 then
        if not profiles[key] then return end
        if self.remotePlan and self.remotePlan.sender==sender and self.remotePlan.revision==revision then
            -- A repeated marker is a transport duplicate, not the start of a new
            -- plan. Resetting here could erase assignments already received.
            self.remotePlan.receivedAt=self.NowMs()
        else
            self.remotePlan={revision=revision,sender=sender,profile=profiles[key],assignments={},receivedAt=self.NowMs()}
        end
    elseif self.remotePlan and self.remotePlan.sender==sender and self.remotePlan.revision==revision then
        if kind==1 and wireKeys[key+1] then self.remotePlan.assignments[wireKeys[key+1]]=hash
        elseif kind==2 and hash==self:GetMyHash() and roles[key+1] then self.remotePlan.myRole=roles[key+1] end
    else return end
    if not self.assignmentBannerPending then
        self.assignmentBannerPending=true
        zo_callLater(function() SC.assignmentBannerPending=false;SC:ShowPersonalAssignmentBanner() end,350)
    end
end

-- A blank or unavailable field cannot pass a comparison against an empty template.
local auditValue=SC.Audit.Value
function SC.Audit.Value(snapshot,key)
    if not snapshot then return end
    if snapshot.asui and not snapshot.skills and key~="food" then return nil end
    return auditValue(snapshot,key)
end
local captureBuild=SC.CaptureExpectedBuild
function SC:CaptureExpectedBuild(role,snapshot,playerKey)
    snapshot=snapshot or self.localSnapshot
    if not snapshot or (role~="MT" and role~="OT" and role~="H1" and role~="H2"
        and role~="DD PARSE" and role~="DD SUPPORT") then
        return false,"Assign a specific role before capturing its expected build."
    end
    local champion=self.Audit.Value(snapshot,"champion")
    if champion then
        local counts={}
        for discipline in champion:gmatch(":([A-Z]+):") do counts[discipline]=(counts[discipline] or 0)+1 end
        local scope=self.sv.championScope or "COMBAT"
        local complete=scope~="ALL" and counts[scope]==4 or scope=="ALL" and counts.COMBAT==4 and counts.CONDITIONING==4 and counts.WORLD==4
        if not complete then
            -- Capture other verified fields; omit an incomplete CP target rather than validating it.
            local reference=playerKey and self:GetTemplateKey(role)..":"..playerKey or self:GetTemplateKey(role)
            local previousTemplate=self.sv.buildTemplates[reference]
            local scopedPlayerKey=playerKey and tostring(self.sv.activeProfile)..":"..playerKey
            local previousPlayerTemplate=scopedPlayerKey and self.sv.playerTemplates[scopedPlayerKey]
            local ok,message=captureBuild(self,role,snapshot,playerKey)
            if ok then
                local template=self.sv.buildTemplates[reference]
                template.values.champion=nil
                if template.hashes then
                    for _,discipline in ipairs({"all","combat","conditioning","world"}) do
                        template.hashes["champion_"..discipline]=nil
                    end
                end
                local retained=0
                for _ in pairs(template.values or {}) do retained=retained+1 end
                for _ in pairs(template.hashes or {}) do retained=retained+1 end
                if retained==0 then
                    self.sv.buildTemplates[reference]=previousTemplate
                    if scopedPlayerKey then self.sv.playerTemplates[scopedPlayerKey]=previousPlayerTemplate end
                    return false,"Champion target omitted, but no other verified build fields were available to save."
                end
            end
            return ok,message.." Champion target omitted: four verified slottables are required per selected discipline."
        end
    end
    return captureBuild(self,role,snapshot,playerKey)
end

-- Freeze raid-session evidence separately from settings. Combat collection continues with a hidden HUD.
local startPull=SC.StartPull
function SC:StartPull()
    if self.ClosePullReport then self:ClosePullReport() end
    startPull(self)
    self.lastQuietAt=nil
end
local sample=SC.SampleLiveCoverage
function SC:SampleLiveCoverage()
    for _,entry in ipairs(self.roster or {}) do
        local peer=self.peerData[entry.key]
        if peer then
            entry.liveCapabilities=peer.liveCapabilities;entry.liveKnownKeys=peer.liveKnownKeys;entry.liveUpdatedAt=peer.liveUpdatedAt
        end
    end
    sample(self)
end

local evaluate=SC.EvaluateCoverage
function SC:EvaluateCoverage(reason)
    return evaluate(self,reason)
end

function SC:GetEffectiveScale()
    local width=self.Clamp(self.sv.width,300,680)
    local height=72+10*(self.Clamp(self.sv.rowHeight,24,48)+1)
    return math.max(0.1,math.min(self.sv.scale/100,(GuiRoot:GetWidth()-24)/width,(GuiRoot:GetHeight()-24)/height))
end
function SC:ClampToScreen(save)
    if not self.window or not self.sv then return end
    local scale=self.window:GetScale() or 1
    local left,top=self.window:GetLeft(),self.window:GetTop()
    if left==nil or top==nil then return end
    local x=self.Clamp(left,0,math.max(0,GuiRoot:GetWidth()-self.window:GetWidth()*scale))
    local y=self.Clamp(top,0,math.max(0,GuiRoot:GetHeight()-self.window:GetHeight()*scale))
    if math.abs(x-left)>0.5 or math.abs(y-top)>0.5 then
        self.window:ClearAnchors();self.window:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,x,y)
        if save then self:SavePosition() end
    end
end
local appearance=SC.ApplyAppearance
function SC:ApplyAppearance()
    appearance(self)
    if not self.window then return end
    local rowHeight=self.Clamp(self.sv.rowHeight,24,48)
    for index,row in ipairs(self.window.rows) do
        row:ClearAnchors();row:SetAnchor(TOPLEFT,self.window,TOPLEFT,8,60+(index-1)*(rowHeight+1))
        row.accent:SetDimensions(3,rowHeight)
    end
    local width=self.window:GetWidth()
    self.window.title:SetDimensions(math.max(100,width-178),22)
    self.window.status:SetDimensions(152,22)
    self.window.metrics:SetDimensions(math.max(100,width-68),20)
end
local visibility=SC.ApplyVisibility
function SC:ApplyVisibility()
    visibility(self)
    if not self.window then return end
    local overlayVisible = self.inspectorWindow and not self.inspectorWindow:IsHidden()
        or self.reportWindow and not self.reportWindow:IsHidden()
        or self.matrixWindow and not self.matrixWindow:IsHidden()
    if overlayVisible then self.window:SetHidden(true) end
    if self.SetSafetyUpdateActive then
        self:SetSafetyUpdateActive(self.sv.enabled and (not self.window:IsHidden() or self.settingsPageVisible or overlayVisible))
    end
    if self.window:IsHidden() or self.inCombat then
        if self.banner then self.banner:SetHidden(true) end
        if self.assignmentBanner then self.assignmentBanner:SetHidden(true) end
    end
end
function SC:GetHUDIssues()
    local result={}
    if self.inCombat then
        for _,row in ipairs(self.coverage.entries or {}) do
            if not row.liveKnown then
                if self.sv.showUnknown then result[#result+1]={severity="unknown",text=row.effect.label,value="UNKNOWN"} end
            elseif row.live==false then
                result[#result+1]={severity=row.liveCount==0 and "error" or "warning",text=row.effect.label,
                    value=string.format("%d/%d",row.liveCount or 0,row.liveTotal or 0)}
            elseif not self.sv.problemsOnly then result[#result+1]={severity="ok",text=row.effect.label,value="UP"} end
        end
    else
        for _,issue in ipairs(self.coverage.issues or {}) do
            if issue.severity~="unknown" or self.sv.showUnknown then
                result[#result+1]={severity=issue.severity,text=issue.text,value=issue.severity=="unknown" and "UNKNOWN" or ""}
            end
        end
        if not self.sv.problemsOnly then
            for _,row in ipairs(self.coverage.entries or {}) do
                if row.status=="covered" then result[#result+1]={severity="ok",text=row.effect.label,value="PLANNED"} end
            end
        end
    end
    local priority={error=1,warning=2,unknown=3,ok=4}
    table.sort(result,function(a,b) local aa,bb=priority[a.severity] or 5,priority[b.severity] or 5;return aa==bb and a.text<b.text or aa<bb end)
    return result
end
local refreshHUD=SC.RefreshHUD
function SC:RefreshHUD()
    refreshHUD(self)
    if not self.window or self.window:IsHidden() then return end
    self.window.metrics:SetText("Capability planning / measured coverage")
    if self.inCombat then
        local unknown,problems=0,0
        for _,row in ipairs(self.coverage.entries or {}) do
            if not row.liveKnown then unknown=unknown+1 elseif row.live==false then problems=problems+1 end
        end
        if problems==0 and unknown>0 then
            self.window.status:SetText("UNVERIFIED")
            self.window.status:SetColor(0.97,0.78,0.30,1)
        end
    end
end
local readyBanner=SC.ShowReadyBanner
function SC:ShowReadyBanner(...)
    if not self.sv or not self.sv.enabled or not self.sv.visible or self.uiObscured or self.inCombat
        or self.settingsPageVisible or self.window and self.window:IsHidden() then return end
    return readyBanner(self,...)
end
local assignmentBanner=SC.ShowPersonalAssignmentBanner
function SC:ShowPersonalAssignmentBanner()
    if not self.sv or not self.sv.enabled or not self.sv.visible or self.uiObscured or self.inCombat
        or self.settingsPageVisible or self.window and self.window:IsHidden() then return end
    return assignmentBanner(self)
end

local function Action(parent,name,text,x,y,width,callback)
    local control=WINDOW_MANAGER:CreateControl(name,parent,CT_CONTROL)
    control:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);control:SetDimensions(width,28);control:SetMouseEnabled(true)
    local label=WINDOW_MANAGER:CreateControl(name.."Label",control,CT_LABEL)
    label:SetAnchorFill(control);label:SetFont("ZoFontGameBold");label:SetText(text);label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetColor(1,0.65,0.22,1)
    control:SetHandler("OnMouseUp",function(_,button,inside) if button==MOUSE_BUTTON_INDEX_LEFT and inside~=false then callback() end end)
    return control
end
local buildSettings=SC.BuildIntegratedSettingsPage
function SC:BuildIntegratedSettingsPage(page,ui)
    if not page or not ui then return end
    if not self.sv then self:EnsureSavedVariables() end
    buildSettings(self,page,ui)
    if not self.sv then return end
    Action(page,"AlphaSquadSupportOpenInspector","DETAILS / HISTORY",482,4,190,function() SC:OpenInspector("CHECKS") end)
end
local matrixCreate=SC.CreateMatrixWindow
function SC:CreateMatrixWindow()
    matrixCreate(self)
    local win=self.matrixWindow
    Action(win,"AlphaSquadSupportMatrixPrev","PREVIOUS",650,706,100,function() SC.matrixPage=math.max(1,(SC.matrixPage or 1)-1);SC:RefreshMatrix() end)
    Action(win,"AlphaSquadSupportMatrixNext","NEXT",758,706,90,function() SC.matrixPage=(SC.matrixPage or 1)+1;SC:RefreshMatrix() end)
    Action(win,"AlphaSquadSupportMatrixDetails","INSPECT",854,706,130,function() SC:OpenInspector("BUILD") end)
    if AlphaSquadSupportMatrixFooter then AlphaSquadSupportMatrixFooter:SetWidth(620) end
    self:ResizeInspector()
end
local matrixRefresh=SC.RefreshMatrix
function SC:RefreshMatrix()
    if not self.matrixWindow or self.matrixWindow:IsHidden() then return end
    local original=self.coverage
    local total=#(original.entries or {})
    self.matrixPage=math.max(1,math.min(math.max(1,math.ceil(total/20)),self.matrixPage or 1))
    local view={};for key,value in pairs(original) do view[key]=value end
    view.entries={}
    for index=(self.matrixPage-1)*20+1,math.min(total,self.matrixPage*20) do view.entries[#view.entries+1]=original.entries[index] end
    self.coverage=view
    local ok,problem=pcall(matrixRefresh,self)
    self.coverage=original
    if not ok then error(problem) end
    self.matrixWindow.summary:SetText(string.format("%s | %d/%d planned | Page %d/%d | Source presence is not uptime",
        tostring(original.profileLabel or ""),original.coveredCount or 0,original.requiredCount or 0,self.matrixPage,math.max(1,math.ceil(total/20))))
    for index,row in ipairs(self.matrixWindow.playerRows) do
        local player=self.roster[index]
        if player then
            row.quality:SetText(player.dataQuality or (player.asui and "ASUI" or "LIMITED"))
            local food=self.Audit.Value(player,"food")
            row.food:SetText(food==nil and "FOOD ?" or food=="NONE" and "NO FOOD" or "FOOD OK")
            local glyphs=player.equipment and player.equipment.glyphs
            if not glyphs or glyphs.verified~=true then row.glyph:SetText("GLYPH ?") end
        end
    end
end
local resize=SC.ResizeInspector
function SC:ResizeInspector()
    resize(self)
    if self.matrixWindow then self.matrixWindow:SetScale(math.max(0.1,math.min(1,(GuiRoot:GetWidth()-24)/1040,(GuiRoot:GetHeight()-24)/740))) end
end
local refreshSettings=SC.RefreshSettings
function SC:RefreshSettings()
    local main=AlphaSquadUI.Settings and AlphaSquadUI.Settings.mainWindow
    if main and not main:IsHidden() then refreshSettings(self)
    elseif self.matrixWindow and not self.matrixWindow:IsHidden() then self:RefreshMatrix() end
    if self.RefreshInspector then self:RefreshInspector() end
end

local inspectorRows=SC.GetInspectorRows
function SC:GetInspectorRows()
    local rows=inspectorRows(self)
    if self.inspectorTab=="CHECKS" then
        rows[#rows+1]={title="Lock HUD position",detail="Move the header while unlocked. Saved positions are preserved.",button=self.sv.locked and "LOCKED" or "UNLOCKED",
            action=function() self:SetLocked(not self.sv.locked);self:RefreshInspector() end}
        rows[#rows+1]={title="Reset HUD position",detail="Does not reset build templates or pull history.",button="RESET POSITION",action=function() self:ResetPosition() end}
        rows[#rows+1]={title="Save this raid / boss context",detail=self:GetContextKey(),button="SAVE CONTEXT",action=function() self:SaveContextProfile();self:RefreshInspector() end}
        rows[#rows+1]={title="Load this raid / boss context",detail="Loads your saved role/build checks and effect targets; unknown HM is not guessed.",button="LOAD CONTEXT",action=function() self:LoadContextProfile();self:RefreshInspector() end}
    elseif self.inspectorTab=="BUILD" then
        local player=self:GetInspectedPlayer()
        if player and self:IsSelf(player.unitTag or "player") then
            local food=player.food or {}
            if food.active and food.timeEnds then rows[#rows+1]={title="Food time remaining",detail=string.format("%.0f minutes",math.max(0,food.timeEnds-self.NowMs()/1000)/60)} end
            local potion=player.potion or {}
            rows[#rows+1]={title="Potion stack / cooldown",detail=string.format("Count %s | Remaining %s ms | Selected item is not proof of consumption",tostring(potion.count or "UNKNOWN"),tostring(potion.cooldownRemaining or "UNKNOWN"))}
        end
    end
    return rows
end

local registerEvents=SC.RegisterEvents
function SC:RegisterEvents()
    registerEvents(self)
    if EVENT_ACTIVE_WEAPON_PAIR_CHANGED then
        local name="AlphaSquadUI_SupportCoverage_WeaponPair"
        EVENT_MANAGER:UnregisterForEvent(name,EVENT_ACTIVE_WEAPON_PAIR_CHANGED)
        EVENT_MANAGER:RegisterForEvent(name,EVENT_ACTIVE_WEAPON_PAIR_CHANGED,function()
            if SC.sv.enabled then SC:ScheduleRefresh("active bar changed",80) end
        end)
    end
end
local buildRoster=SC.BuildRoster
function SC:BuildRoster()
    for key,peer in pairs(self.peerData or {}) do
        if peer.unitTag then
            local name=Try(GetUnitName,peer.unitTag)
            if name and peer.characterName and peer.characterName~="" and name~=peer.characterName then
                self.peerData[key]=nil
                if self.detailReceivers then self.detailReceivers[key]=nil end
            end
        end
    end
    return buildRoster(self)
end
