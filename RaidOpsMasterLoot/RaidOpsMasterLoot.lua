-----------------------------------------------------------------------------------------------
-- Client Lua Script for RaidOpsMasterLoot
-- Copyright (c) Piotr Szymczak 2014 dogier140@poczta.fm . All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
local Major, Minor, Patch, Suffix = 1, 16, 0, 0
-----------------------------------------------------------------------------------------------
-- RaidOpsMasterLoot Module Definition
-----------------------------------------------------------------------------------------------
local RaidOpsMasterLoot = {} 

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local Hook = Apollo.GetAddon("MasterLootDependency")
 
 local ktClassToIcon =
{
	[GameLib.CodeEnumClass.Medic]       	= "Icon_Windows_UI_CRB_Medic",
	[GameLib.CodeEnumClass.Esper]       	= "Icon_Windows_UI_CRB_Esper",
	[GameLib.CodeEnumClass.Warrior]     	= "Icon_Windows_UI_CRB_Warrior",
	[GameLib.CodeEnumClass.Stalker]     	= "Icon_Windows_UI_CRB_Stalker",
	[GameLib.CodeEnumClass.Engineer]    	= "Icon_Windows_UI_CRB_Engineer",
	[GameLib.CodeEnumClass.Spellslinger]  	= "Icon_Windows_UI_CRB_Spellslinger",
}

local ktClassToString =
{
	[GameLib.CodeEnumClass.Medic]       	= "Medic",
	[GameLib.CodeEnumClass.Esper]       	= "Esper",
	[GameLib.CodeEnumClass.Warrior]     	= "Warrior",
	[GameLib.CodeEnumClass.Stalker]     	= "Stalker",
	[GameLib.CodeEnumClass.Engineer]    	= "Engineer",
	[GameLib.CodeEnumClass.Spellslinger]  	= "Spellslinger",
}
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function RaidOpsMasterLoot:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function RaidOpsMasterLoot:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- RaidOpsMasterLoot OnLoad
-----------------------------------------------------------------------------------------------
function RaidOpsMasterLoot:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("RaidOpsMasterLoot.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function RaidOpsMasterLoot:OnRestore(eLevel, tData)	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end
	self.tItems = tData
end

function RaidOpsMasterLoot:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end
	local tSave = self.tItems
	return tSave
end
-----------------------------------------------------------------------------------------------
-- RaidOpsMasterLoot OnDocLoaded
-----------------------------------------------------------------------------------------------
function RaidOpsMasterLoot:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    
		if Apollo.GetAddon("RaidOps") or Apollo.GetAddon("MasterLootDependency") == nil then
			Print("[RaidOps MasterLoot] Main addon found or MasterLoot addon not found , disable this addon or figure out which addons you need to disable.")
			Apollo.AddAddonErrorText(self, "Main addon found or MasterLoot addon not found , disable this addon or figure out which addons you need to disable.")
			Event_FireGenericEvent("OneVersion_ReportAddonInfo", "RaidOpsMasterLoot", Major, Minor, Patch)
			return	
		else self:BeginInit() end
		
	end
end

		
		
function RaidOpsMasterLoot:BeginInit()
		if self.tItems == nil then 
			self.tItems ={}
			self.tItems["settings"] = {}			
		end
		Apollo.RegisterTimerHandler(1, "OnWait", self)
		self.wait_timer = ApolloTimer.Create(1, true, "OnWait", self)
end
local wait_counter = 0
function RaidOpsMasterLoot:OnWait()
	if wait_counter == 1 then 
		self:CompleteInit() 
		Apollo.RemoveEventHandler("OnWait",self)
		self.wait_timer:Stop()
	else 
		wait_counter = wait_counter + 1 
	end
end

function RaidOpsMasterLoot:MLSettingsShow()
	self.wndMLSettings:Show(true,false)
	self.wndMLSettings:ToFront()
end

function RaidOpsMasterLoot:CompleteInit()
	Hook = Apollo.GetAddon("MasterLootDependency")
	self.wndResponses = Apollo.LoadForm(self.xmlDoc,"Responses",nil,self)
	self.wndResponses:Show(false,true)
	Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)
	self.tSelectedItems = {}
	self:HookToMasterLootDisp()
	self:MLSettingsRestore()
	Apollo.RegisterSlashCommand("ropsml", "MLSettingsShow", self)
	if not self.tItems["settings"]["ML"].bStandardLayout then
		Hook.wndMasterLoot:Destroy()
		Hook.wndMasterLoot = Apollo.LoadForm(self.xmlDoc,"MasterLootWindowVertLayout",nil,Hook)
		Hook.wndMasterLoot:SetSizingMinimum(579,559)
		Hook.wndMasterLoot:MoveToLocation(Hook.locSavedMasterWindowLoc)
		Hook.wndMasterLoot_ItemList = Hook.wndMasterLoot:FindChild("ItemList")
		Hook.wndMasterLoot_LooterList = Hook.wndMasterLoot:FindChild("LooterList")
		Hook.wndMasterLoot:SetSizingMinimum(800, 500)
	else
		Hook.wndMasterLoot:SetSizingMinimum(800, 310)
	end

    self.wndInsertedControls = Apollo.LoadForm(self.xmlDoc,"InsertMLControls",Hook.wndMasterLoot,self)

	if self.tItems["settings"].BidSortAsc == 1 then 
		self.wndInsertedControls:FindChild("Asc"):SetCheck(true) 
	else 
		self.wndInsertedControls:FindChild("Desc"):SetCheck(true) 
	end
	
	self.wndInsertedControls:FindChild("Asc"):SetRotation(270)
	self.wndInsertedControls:FindChild("Desc"):SetRotation(90)
	
	Hook.wndMasterLoot:FindChild("MasterLoot_Window_Title"):SetAnchorOffsets(48,27,-350,63)
	self.tEquippedItems = {}

	Hook.wndMasterLoot:Show(true)
	--Hook:OnMasterLootUpdate(true)
	--self.channel = ICCommLib.JoinChannel(self.tItems["settings"]["ML"].strChannel ,ICCommLib.CodeEnumICCommChannelType.Global)
	--self.channel:SetReceivedMessageFunction("OnReceivedItem",self)
	self.strMyName = GameLib.GetPlayerUnit():GetName()
	-- OneVersion
	Event_FireGenericEvent("OneVersion_ReportAddonInfo", "RaidOpsMasterLoot", Major, Minor, Patch)
end

function RaidOpsMasterLoot:ReArr()
	 if self.tItems["settings"]["ML"].bArrTiles then
		Hook.wndMasterLoot_LooterList:ArrangeChildrenTiles()
	end
	
	if self.tItems["settings"]["ML"].bArrItemTiles then
		Hook.wndMasterLoot_ItemList:ArrangeChildrenTiles()
	end
end

function RaidOpsMasterLoot:BidRandomLooter()
	local children = Hook.wndMasterLoot:FindChild("LooterList"):GetChildren()
	
	local luckyChild
	for k,child in ipairs(children) do
		if not child:IsEnabled() or child:FindChild("CharacterName"):GetText() == "Guild Bank" then table.remove(children,k) end
	end
	
	for k,child in pairs(children) do
		child:SetCheck(false)
	end
	
	luckyChild = children[math.random(#children)]
	
	Hook.tMasterLootSelectedLooter = luckyChild:GetData()
	Hook.wndMasterLoot:FindChild("Assignment"):Enable(true)
	luckyChild:SetCheck(true)
end

function RaidOpsMasterLoot:string_starts(String,Start)
	return string.sub(string.lower(String),1,string.len(Start))==string.lower(Start)
end

function RaidOpsMasterLoot:BidMLSearch(wndHandler,wndControl)
	if self.wndInsertedSearch:GetText() ~= "Search" then
		local children = Hook.wndMasterLoot:FindChild("LooterList"):GetChildren()
		
		for k,child in ipairs(children) do
			child:Show(true,true)
		end
		
		for k,child in ipairs(children) do
			if not self:string_starts(child:FindChild("CharacterName"):GetText(),self.wndInsertedSearch:GetText()) then child:Show(false,true) end
		end
		
		if wndControl ~= nil and wndControl:GetText() == "" then wndControl:SetText("Search") end
	
		if self.tItems["settings"]["ML"].bArrTiles then
			Hook.wndMasterLoot_LooterList:ArrangeChildrenTiles()
		else
			Hook.wndMasterLoot_LooterList:ArrangeChildrenVert()
		end
	end
end
	 
	 
function RaidOpsMasterLoot:MLSettingsRestore()
	self.wndMLSettings = Apollo.LoadForm(self.xmlDoc,"MLSettings",nil,self)
	self.wndMLSettings:Show(false,true)
	if self.tItems["settings"]["ML"] == nil then
		self.tItems["settings"]["ML"] = {}
		self.tItems["settings"]["ML"].bShowClass = true
		self.tItems["settings"]["ML"].bArrTiles = true
		self.tItems["settings"]["ML"].bShowValues = true
	end

	if self.tItems["settings"]["ML"].strChannel == nil then self.tItems["settings"]["ML"].strChannel = "your guild's channel" end
	if self.tItems["settings"]["ML"].bArrItemTiles == nil then self.tItems["settings"]["ML"].bArrItemTiles = true end
	if self.tItems["settings"]["ML"].bStandardLayout == nil then self.tItems["settings"]["ML"].bStandardLayout = true end
	if self.tItems["settings"]["ML"].bListIndicators == nil then self.tItems["settings"]["ML"].bListIndicators = true end
	if self.tItems["settings"]["ML"].BidSortAsc == nil then self.tItems["settings"]["ML"].BidSortAsc = true end
	if self.tItems["settings"]["ML"].bGroup == nil then self.tItems["settings"]["ML"].bGroup = false end
	if self.tItems["settings"]["ML"].bShowLastItemBar == nil then self.tItems["settings"]["ML"].bShowLastItemBar = true end
	if self.tItems["settings"]["ML"].bShowLastItemTile == nil then self.tItems["settings"]["ML"].bShowLastItemTile = true end	
	if self.tItems["settings"]["ML"].bShowCurrItemBar == nil then self.tItems["settings"]["ML"].bShowCurrItemBar = false end
	if self.tItems["settings"]["ML"].bShowCurrItemTile == nil then self.tItems["settings"]["ML"].bShowCurrItemTile = false end
	if self.tItems["settings"]["ML"].bAllowMulti == nil then self.tItems["settings"]["ML"].bAllowMulti = false end
	if self.tItems["settings"]["ML"].bShowGuildBank == nil then self.tItems["settings"]["ML"].bShowGuildBank = false end
	if self.tItems["settings"]["ML"].strGBManager == nil then self.tItems["settings"]["ML"].strGBManager = "" end
	if self.tItems["settings"]["ML"].bDisplayApplicable == nil then self.tItems["settings"]["ML"].bDisplayApplicable = false end
	if self.tItems["settings"]["ML"].tWinners == nil then self.tItems["settings"]["ML"].tWinners = {} end
	self.tItems["settings"]["ML"].bShowCurrItemTile = false
	self.tItems["settings"]["ML"].bShowLastItemTile = true
	self.tItems["settings"]["ML"].bShowCurrItemBar = false


	if self.tItems["settings"]["ML"].bArrTiles then self.wndMLSettings:FindChild("Tiles"):SetCheck(true) else self.wndMLSettings:FindChild("List"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bShowClass then self.wndMLSettings:FindChild("ShowClass"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bStandardLayout then self.wndMLSettings:FindChild("Horiz"):SetCheck(true) else self.wndMLSettings:FindChild("Vert"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bArrItemTiles then self.wndMLSettings:FindChild("TilesLoot"):SetCheck(true) else self.wndMLSettings:FindChild("ListLoot"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bGroup then self.wndMLSettings:FindChild("GroupClass"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bShowLastItemBar then self.wndMLSettings:FindChild("ShowLastItemBar"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bShowLastItemTile then self.wndMLSettings:FindChild("ShowLastItemTile"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bShowCurrItemBar then self.wndMLSettings:FindChild("ShowCurrItemBar"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bShowCurrItemTile then self.wndMLSettings:FindChild("ShowCurrItemTile"):SetCheck(true) end
	
	if self.tItems["settings"]["ML"].bAllowMulti then self.wndMLSettings:FindChild("AllowMultiItem"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bShowGuildBank then self.wndMLSettings:FindChild("ShowGuildBankEntry"):SetCheck(true) end
	
	self.wndMLSettings:FindChild("GBManager"):SetText(self.tItems["settings"]["ML"].strGBManager)
	self.wndMLSettings:FindChild("DisplayApplicable"):SetCheck(self.tItems["settings"]["ML"].bDisplayApplicable)

end

function RaidOpsMasterLoot:MLSettingsArrangeTypeChanged(wndHandler,wndControl)
	if wndControl:GetName() == "Tiles" then self.tItems["settings"]["ML"].bArrTiles = true else self.tItems["settings"]["ML"].bArrTiles = false end
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:MLSettingsShowClassEnable()
	self.tItems["settings"]["ML"].bShowClass = true
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:MLSettingsShowClassDisable()
	self.tItems["settings"]["ML"].bShowClass = false
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:MLSettingsGroupEnable()
	self.tItems["settings"]["ML"].bGroup = true
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:MLSettingsGroupDisable()
	self.tItems["settings"]["ML"].bGroup = false
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:MLSettingsDataTypeChanged(wndHandler,wndControl)
	if wndControl:GetName() == "Values" then self.tItems["settings"]["ML"].bShowValues = true else self.tItems["settings"]["ML"].bShowValues = false end
	Hook:OnMasterLootUpdate(true)
end
function RaidOpsMasterLoot:MLSettingsClose()
	self.wndMLSettings:Show(false,false)
end

function RaidOpsMasterLoot:MLSettingsLayoutTypeChanged(wndHandler,wndControl)
	if wndControl:GetName() == "Horiz" then self.tItems["settings"]["ML"].bStandardLayout = true else self.tItems["settings"]["ML"].bStandardLayout = false end
end

function RaidOpsMasterLoot:MLSettingsArrangeLootTypeChanged(wndHandler,wndControl)
	if wndControl:GetName() == "TilesLoot" then self.tItems["settings"]["ML"].bArrItemTiles = true else self.tItems["settings"]["ML"].bArrItemTiles = false end
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:SendRequestsForCurrItem(itemz)
	if self.channel then self:Bid2PackAndSend({type = "GimmeUrEquippedItem",item = itemz}) end
end

-- Hook
function RaidOpsMasterLoot:BidMasterItemSelected()
	local HookML = Apollo.GetAddon("MasterLootDependency")
	local DKPInstance = Apollo.GetAddon("RaidOpsMasterLoot")
	if HookML.tMasterLootSelectedItem and HookML.tMasterLootSelectedItem.itemDrop then
		DKPInstance.SelectedMasterItem = HookML.tMasterLootSelectedItem.itemDrop:GetName()
		DKPInstance.wndInsertedMasterButton:Enable(true)
		DKPInstance.wndInsertedControls:FindChild("Window"):FindChild("Random"):Enable(true)
	end
end

function RaidOpsMasterLoot:HookToMasterLootDisp()
	if not self:IsHooked(Apollo.GetAddon("MasterLootDependency"),"RefreshMasterLootLooterList") then
		self:RawHook(Apollo.GetAddon("MasterLootDependency"),"RefreshMasterLootLooterList")
		self:RawHook(Apollo.GetAddon("MasterLootDependency"),"OnAssignDown")
		self:RawHook(Apollo.GetAddon("MasterLootDependency"),"RefreshMasterLootItemList")
		self:PostHook(Apollo.GetAddon("MasterLootDependency"),"OnItemCheck","BidMasterItemSelected")
		self:Hook(Apollo.GetAddon("MasterLootDependency"),"OnCharacterCheck","BidCharacterChecked")
		self:RawHook(Apollo.GetAddon("MasterLootDependency"),"OnLootAssigned")
	end
end

function RaidOpsMasterLoot:OnAssignDown(luaCaller,wndHandler, wndControl, eMouseButton)

	if luaCaller.tMasterLootSelectedItem ~= nil and luaCaller.tMasterLootSelectedLooter ~= nil then
		local DKPInstance = Apollo.GetAddon("RaidOpsMasterLoot")
		-- gotta save before it gets wiped out by event
		local SelectedLooter = luaCaller.tMasterLootSelectedLooter
		local SelectedItemLootId = luaCaller.tMasterLootSelectedItem.nLootId

		luaCaller.tMasterLootSelectedLooter = nil
		luaCaller.tMasterLootSelectedItem = nil
		if #DKPInstance.tSelectedItems > 1 then
			for k,item in ipairs(DKPInstance.tSelectedItems) do
				GameLib.AssignMasterLoot(item,SelectedLooter)
				DKPInstance:MLRegisterItemWinner()
			end
			DKPInstance.tSelectedItems = {}
		else
			GameLib.AssignMasterLoot(SelectedItemLootId,SelectedLooter)
		end

	end

end

function RaidOpsMasterLoot:OnLootAssigned(luaCaller,objItem, strLooter)
	local DKPInstance = Apollo.GetAddon("RaidOpsMasterLoot")
	if DKPInstance.bIsSelectedGuildBank and string.lower(strLooter) == string.lower(DKPInstance.tItems["settings"]["ML"].strGBManager) then strLooter = "Guild Bank" end
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", String_GetWeaselString(Apollo.GetString("CRB_MasterLoot_AssignMsg"), objItem:GetName(), strLooter))
end

function RaidOpsMasterLoot:EPGPGetSlotSpriteByQualityRectangle(ID)
	if ID == 5 then return "BK3:UI_BK3_ItemQualityPurple"
	elseif ID == 6 then return "BK3:UI_BK3_ItemQualityOrange"
	elseif ID == 4 then return "BK3:UI_BK3_ItemQualityBlue"
	elseif ID == 3 then return "BK3:UI_BK3_ItemQualityGreen"
	elseif ID == 2 then return "BK3:UI_BK3_ItemQualityWhite"
	else return "BK3:UI_BK3_ItemQualityGrey"
	end
end

function RaidOpsMasterLoot:MLRegisterItemWinner()
	if Hook.tMasterLootSelectedLooter and Hook.tMasterLootSelectedItem then
		self.tItems["settings"]["ML"].tWinners[Hook.tMasterLootSelectedLooter:GetName()] = Hook.tMasterLootSelectedItem.itemDrop:GetItemId()
	end
end

function RaidOpsMasterLoot:Bid2PackAndSend(tData)
	if not tData.type then return end
	tData.strSender = strMyName
	local strData = serpent.dump(tData)
	self.channel:SendMessage("ROPS" .. strData)
end

function RaidOpsMasterLoot:Bid2PackAndSendPrivate(tData,strTarget)
	if not tData.type then return end
	tData.strSender = strMyName
	local strData = serpent.dump(tData)
	self.channel:SendPrivateMessage(strTarget,"ROPS" .. strData)
end


--[[function RaidOpsMasterLoot:OnReceivedItem(channel, strMessage, idMessage)
	if string.sub(strMessage,1,4) ~= "ROPS" then return end
	local tMsg = serpent.load(string.sub(strMessage,1,4))
	if tMsg.type and tMsg.strSender then
		if tMsg.type == "MyEquippedItem" then
			local item = Item.GetDataFromId(tMsg.item)
			self.tEquippedItems[tMsg.strSender] = {}
			self.tEquippedItems[tMsg.strSender][item:GetSlot()] = tMsg.item
			self:UpdatePlayerTileBar(tMsg.strSender,item)
		elseif tMsg.type == "Confirmation" then
			self:AddResponse(tMsg.strSender)
		end
	end
end]]

function RaidOpsMasterLoot:UpdatePlayerTileBar(strPlayer,item)
	if item == nil then return end
	local children = Hook.wndMasterLoot_LooterList:GetChildren()
	for k,child in ipairs(children) do
		if child:FindChild("CharacterName"):GetText() == strPlayer then
			if self.tItems["settings"]["ML"].bArrTiles and self.tItems["settings"]["ML"].bShowCurrItemTile then
				child:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
				child:FindChild("ItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
				child:FindChild("ItemFrame"):Show(true)
				Tooltip.GetItemTooltipForm(self,child:FindChild("ItemFrame"),item, {bPrimary = true, bSelling = false})
			elseif not self.tItems["settings"]["ML"].bArrTiles then
				child:FindChild("CurrItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
				child:FindChild("CurrItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
				child:FindChild("CurrItemFrame"):Show(true)
				Tooltip.GetItemTooltipForm(self,child:FindChild("CurrItemFrame"),item, {bPrimary = true, bSelling = false})
			end
			break
		end
	end
end

function sortMasterLootEasyDKPNonWnd(a,b)
	local DKPInstance = Apollo.GetAddon("RaidOpsMasterLoot")
	if DKPInstance.tItems["settings"].BidSortAsc == 0 then
		return a:GetName() < b:GetName()
	else
		return a:GetName() > b:GetName()
	end
end


function RaidOpsMasterLoot:RefreshMasterLootLooterList(luaCaller,tMasterLootItemList)
	luaCaller.wndMasterLoot_LooterList:DestroyChildren()
	if luaCaller ~= Apollo.GetAddon("MasterLootDependency") then luaCaller = Apollo.GetAddon("MasterLootDependency") end
	local DKPInstance = Apollo.GetAddon("RaidOpsMasterLoot")
	if luaCaller.tMasterLootSelectedItem ~= nil then
		for idx, tItem in pairs (tMasterLootItemList) do
			if tItem.nLootId == luaCaller.tMasterLootSelectedItem.nLootId then
				local bStillHaveLooter = false
				local tables = {}
				-- Creating Tables
				if DKPInstance.tItems["settings"]["ML"].bGroup then
					tables.esp = {}
					tables.war = {}
					tables.spe = {}
					tables.med = {}
					tables.sta = {}
					tables.eng = {}
				else
					tables.all = {}
				end
				
				-- Determining applicable classes
				local bWantEsp = true
				local bWantWar = true
				local bWantSpe = true
				local bWantMed = true
				local bWantSta = true
				local bWantEng = true
				
				if DKPInstance.tItems["settings"]["ML"].bDisplayApplicable then
					if string.find(tItem.itemDrop:GetName(),"Imprint") then
					    bWantEsp = false
					    bWantWar = false
					    bWantSpe = false
					    bWantMed = false
					    bWantSta = false
					    bWantEng = false
						
						local tDetails = tItem.itemDrop:GetDetailedInfo()
						if tDetails.tPrimary.arClassRequirement then
							for k , class in ipairs(tDetails.tPrimary.arClassRequirement.arClasses) do
								if class == 1 then bWantWar = true
								elseif class == 2 then bWantEng = true
								elseif class == 3 then bWantEsp = true
								elseif class == 4 then bWantMed = true
								elseif class == 5 then bWantSta = true
								elseif class == 7 then bWantSpe = true
								end
							end
						end
					else
						local strCategory = tItem.itemDrop:GetItemCategoryName()
						if strCategory ~= "" then
							if string.find(strCategory,"Light") then
								bWantEng = false
								bWantWar = false
								bWantSta = false
								bWantMed = false
							elseif string.find(strCategory,"Medium") then
								bWantEng = false
								bWantWar = false
								bWantSpe = false
								bWantEsp = false
							elseif string.find(strCategory,"Heavy") then
								bWantEsp = false
								bWantSpe = false
								bWantSta = false
								bWantMed = false
							end
							
							if string.find(strCategory,"Psyblade") or string.find(strCategory,"Heavy Gun") or string.find(strCategory,"Pistols") or string.find(strCategory,"Claws") or string.find(strCategory,"Greatsword") or string.find(strCategory,"Resonators") then 
								bWantEsp = false
								bWantWar = false
								bWantSpe = false
								bWantMed = false
								bWantSta = false
								bWantEng = false
							end 
							
							if string.find(strCategory,"Psyblade") then bWantEsp = true
							elseif string.find(strCategory,"Heavy Gun") then bWantEng = true
							elseif string.find(strCategory,"Pistols") then bWantSpe = true
							elseif string.find(strCategory,"Claws") then bWantSta = true
							elseif string.find(strCategory,"Greatsword") then bWantWar = true
							elseif string.find(strCategory,"Resonators") then bWantMed = true
							end 
						end
					end
				end
				-- Create name table to send request
				if DKPInstance.tItems["settings"]["ML"].bShowCurrItemBar or DKPInstance.tItems["settings"]["ML"].bShowCurrItemTile then
					if tItem.itemDrop:IsEquippable() then
						DKPInstance:SendRequestsForCurrItem(tItem.itemDrop:GetItemId())
						self.tEquippedItems[GameLib.GetPlayerUnit():GetName()] = {}
						--self.tEquippedItems[GameLib.GetPlayerUnit():GetName()][tItem.itemDrop:GetEquippedItemForItemType():GetSlot()] = tItem.itemDrop:GetEquippedItemForItemType():GetItemId()
					end
				end
				-- GuildBank
				local wndGuildBank
				if DKPInstance.tItems["settings"]["ML"].bShowGuildBank then
					if DKPInstance.tItems["settings"]["ML"].bArrTiles then
						wndGuildBank = Apollo.LoadForm(DKPInstance.xmlDoc, "CharacterButtonTileClass", luaCaller.wndMasterLoot_LooterList, luaCaller)
					else
						wndGuildBank = Apollo.LoadForm(DKPInstance.xmlDoc, "CharacterButtonListClass", luaCaller.wndMasterLoot_LooterList, luaCaller)
					end
					if wndGuildBank then
						wndGuildBank:FindChild("CharacterName"):SetText("Guild Bank")
						wndGuildBank:FindChild("ClassIcon"):SetSprite("achievements:sprAchievements_Icon_Group")
						wndGuildBank:FindChild("CharacterLevel"):SetText("")
					end
				end
				
				for k,tab in pairs(tables) do
					table.sort(tab,sortMasterLootEasyDKPNonWnd)
				end

				local unitGBManager
				--Creating windows
				for k,tab in pairs(tables) do
					for j,unitLooter in ipairs(tab) do
						local wndCurrentLooter
						local strName = unitLooter:GetName()
						if DKPInstance.tItems["settings"]["ML"].bArrTiles then
							if DKPInstance.tItems["settings"]["ML"].bShowClass or DKPInstance.tItems["settings"]["ML"].bShowLastItem then
								wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc, "CharacterButtonTileClass", luaCaller.wndMasterLoot_LooterList, luaCaller)
								wndCurrentLooter:FindChild("ClassIcon"):SetSprite(ktClassToIcon[unitLooter:GetClassId()])
							else
								wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc,"CharacterButtonTile", luaCaller.wndMasterLoot_LooterList,luaCaller)
							end
							wndCurrentLooter:FindChild("CharacterLevel"):SetText(unitLooter:GetBasicStats().nLevel)
							
							if DKPInstance.tItems["settings"]["ML"].bShowLastItemTile then
								if self.tItems["settings"]["ML"].tWinners[unitLooter:GetName()] then
									local item = Item.GetDataFromId(self.tItems["settings"]["ML"].tWinners[unitLooter:GetName()])
									wndCurrentLooter:FindChild("ItemFrame"):Show(true,false)
									wndCurrentLooter:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
									wndCurrentLooter:FindChild("ItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
									Tooltip.GetItemTooltipForm(self,wndCurrentLooter:FindChild("ItemFrame"),item, {bPrimary = true, bSelling = false})
								end
							elseif DKPInstance.tItems["settings"]["ML"].bShowCurrItemTile then -- Set Current Item
								if DKPInstance.tEquippedItems[unitLooter:GetName()] and DKPInstance.tEquippedItems[unitLooter:GetName()][tItem.itemDrop:GetSlot()] then
									local item = Item.GetDataFromId(DKPInstance.tEquippedItems[unitLooter:GetName()][tItem.itemDrop:GetSlot()])
									wndCurrentLooter:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
									wndCurrentLooter:FindChild("ItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
									wndCurrentLooter:FindChild("ItemFrame"):Show(true,false)
									Tooltip.GetItemTooltipForm(self,wndCurrentLooter:FindChild("ItemFrame"),item, {bPrimary = true, bSelling = false})
								end
							end	
							
						else -- List
							if DKPInstance.tItems["settings"]["ML"].bShowClass then
								wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc, "CharacterButtonListClass", luaCaller.wndMasterLoot_LooterList, luaCaller)
								wndCurrentLooter:FindChild("ClassIcon"):SetSprite(ktClassToIcon[unitLooter:GetClassId()])
							else -- no class
								wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc, "CharacterButtonList", luaCaller.wndMasterLoot_LooterList, luaCaller)
							end
							wndCurrentLooter:FindChild("CharacterLevel"):SetText(unitLooter:GetBasicStats().nLevel)
							
							if DKPInstance.tItems["settings"]["ML"].bShowLastItemBar then
								if self.tItems["settings"]["ML"].tWinners[unitLooter:GetName()] then
									local item = Item.GetDataFromId(self.tItems["settings"]["ML"].tWinners[unitLooter:GetName()])
									wndCurrentLooter:FindChild("LastItemFrame"):Show(true)
									wndCurrentLooter:FindChild("LastItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
									wndCurrentLooter:FindChild("LastItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
									Tooltip.GetItemTooltipForm(self,wndCurrentLooter:FindChild("LastItemFrame"),item, {bPrimary = true, bSelling = false})
								end
							end
							if DKPInstance.tItems["settings"]["ML"].bShowCurrItemBar then
								if DKPInstance.tEquippedItems[unitLooter:GetName()] and DKPInstance.tEquippedItems[unitLooter:GetName()][tItem.itemDrop:GetSlot()] then
									local item = Item.GetDataFromId(DKPInstance.tEquippedItems[unitLooter:GetName()][tItem.itemDrop:GetSlot()])
									wndCurrentLooter:FindChild("CurrItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
									wndCurrentLooter:FindChild("CurrItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
									wndCurrentLooter:FindChild("CurrItemFrame"):Show(true)
									Tooltip.GetItemTooltipForm(self,wndCurrentLooter:FindChild("CurrItemFrame"),item, {bPrimary = true, bSelling = false})
								end
							end
						end
						wndCurrentLooter:FindChild("CharacterName"):SetText(unitLooter:GetName())
						
						if DKPInstance.tItems["settings"]["ML"].bShowGuildBank and string.lower(unitLooter:GetName()) == string.lower(DKPInstance.tItems["settings"]["ML"].strGBManager) then unitGBManager = unitLooter end
						
						wndCurrentLooter:SetData(unitLooter)
						
						
						if luaCaller.tMasterLootSelectedLooter == unitLooter then
							wndCurrentLooter:SetCheck(true)
							bStillHaveLooter = true
						end
					end
				end
				-- Guild Bank
				if wndGuildBank and unitGBManager then
					wndGuildBank:SetTooltip(unitGBManager:GetName() .. " is behind this.")
					wndGuildBank:SetData(unitGBManager)
				elseif wndGuildBank then
					wndGuildBank:Destroy()
				end

				if not bStillHaveLooter then
					luaCaller.tMasterLootSelectedLooter = nil
				end

				-- get out of range people
				-- tLootersOutOfRange
				if tItem.tLootersOutOfRange and next(tItem.tLootersOutOfRange) then
					for idx, strLooterOOR in pairs(tItem.tLootersOutOfRange) do
						local wndCurrentLooter = Apollo.LoadForm(luaCaller.xmlDoc, "CharacterButton", luaCaller.wndMasterLoot_LooterList, luaCaller)
						wndCurrentLooter:FindChild("CharacterName"):SetText(String_GetWeaselString(Apollo.GetString("Group_OutOfRange"), strLooterOOR))
						wndCurrentLooter:FindChild("ClassIcon"):SetSprite("CRB_GroupFrame:sprGroup_Disconnected")
						wndCurrentLooter:Enable(false)
					end
				end
				DKPInstance:BidMLSearch()
				if DKPInstance.tItems["settings"]["ML"].bArrTiles then
					luaCaller.wndMasterLoot_LooterList:ArrangeChildrenTiles()
				else
					luaCaller.wndMasterLoot_LooterList:ArrangeChildrenVert()
				end
			end
		end
	end
end

function RaidOpsMasterLoot:BidAddItem(wndHandler,wndControl)
	table.insert(self.tSelectedItems,wndControl:GetParent():GetData().nLootId)
end

function RaidOpsMasterLoot:BidRemoveItem(wndHandler,wndControl)
	for k,item in ipairs(self.tSelectedItems) do
		if item == wndControl:GetParent():GetData().nLootId then table.remove(self.tSelectedItems,k) end
	end
	
end

function RaidOpsMasterLoot:OnItemCheck(wndHandler,wndControl,eMouseButton)
	Hook:OnItemCheck(wndHandler,wndControl,eMouseButton)
end

function RaidOpsMasterLoot:OnItemMouseButtonUp(wndHandler,wndControl,eMouseButton)
	Hook:OnItemMouseButtonUp(wndHandler,wndControl,eMouseButton)
end

function RaidOpsMasterLoot:BidCharacterChecked(wndHandler,wndControl)
	if wndControl:FindChild("CharacterName"):GetText() == "Guild Bank" then self.bIsSelectedGuildBank = true else self.bIsSelectedGuildBank = false end
end

function RaidOpsMasterLoot:RefreshMasterLootItemList(luaCaller,tMasterLootItemList)

	luaCaller.wndMasterLoot_ItemList:DestroyChildren()
	local DKPInstance = Apollo.GetAddon("RaidOpsMasterLoot")

	
	for idx, tItem in ipairs (tMasterLootItemList) do
		local wndCurrentItem
		
		if DKPInstance.tItems["settings"]["ML"].bArrItemTiles then
			wndCurrentItem = Apollo.LoadForm(DKPInstance.xmlDoc,"ItemButtonTile",luaCaller.wndMasterLoot_ItemList, DKPInstance)
		else
			wndCurrentItem = Apollo.LoadForm(DKPInstance.xmlDoc, "ItemButton", luaCaller.wndMasterLoot_ItemList, DKPInstance)
			wndCurrentItem:FindChild("ItemName"):SetText(tItem.itemDrop:GetName())
		end
		
		if DKPInstance.tItems["settings"]["ML"].bAllowMulti and DKPInstance.tSelectedItems then
			wndCurrentItem:FindChild("Multi"):Show(true) 
			wndCurrentItem:FindChild("Multi"):AddEventHandler("ButtonCheck","BidAddItem",DKPInstance)
			wndCurrentItem:FindChild("Multi"):AddEventHandler("ButtonUncheck","BidRemoveItem",DKPInstance)
			for k,item in ipairs(DKPInstance.tSelectedItems) do
				if tItem.nLootId == item then 
					wndCurrentItem:FindChild("Multi"):SetCheck(true) 
					break
				end
			end
		end
		
		wndCurrentItem:FindChild("ItemIcon"):SetSprite(tItem.itemDrop:GetIcon())
		
		wndCurrentItem:SetData(tItem)
		if luaCaller.tMasterLootSelectedItem ~= nil and (luaCaller.tMasterLootSelectedItem.nLootId == tItem.nLootId) then
			wndCurrentItem:SetCheck(true)
			luaCaller:RefreshMasterLootLooterList(tMasterLootItemList)
		end
		Tooltip.GetItemTooltipForm(luaCaller, wndCurrentItem , tItem.itemDrop, {bPrimary = true, bSelling = false, itemCompare = tItem.itemDrop:GetEquippedItemForItemType()})
	end
	if DKPInstance.tItems["settings"]["ML"].bArrItemTiles then
		luaCaller.wndMasterLoot_ItemList:ArrangeChildrenTiles(0)
	else
		luaCaller.wndMasterLoot_ItemList:ArrangeChildrenVert(0)
	end
end
---------------------------------------------------------------------------------------------------
-- MLSettings Functions
---------------------------------------------------------------------------------------------------

function RaidOpsMasterLoot:MLSettingsShowCurrItemEnableBar( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowCurrItemBar = true
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:MLSettingsShowCurrItemDisableBar( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowCurrItemBar = false
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:MLSettingsShowCurrItemEnableTile( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowCurrItemTile = true
	self.tItems["settings"]["ML"].bShowLastItemTile = false
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:MLSettingsShowCurrItemDisableTile( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowCurrItemTile = false
	Hook:OnMasterLootUpdate(true)
end
--
function RaidOpsMasterLoot:MLSettingsShowLastItemEnableBar( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowLastItemBar = true
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:MLSettingsShowLastItemDisableBar( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowLastItemBar = false
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:MLSettingsShowLastItemEnableTile( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowLastItemTile = true
	self.tItems["settings"]["ML"].bShowCurrItemTile = false
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:MLSettingsShowLastItemDisableTile( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowLastItemTile = false
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:SetChannelAndReconnect( wndHandler, wndControl, strText )
	if string.len(strText) <= 4 then 
		wndControl:SetText(self.tItems["settings"]["ML"].strChannel) 
		return 
	end
	self.tItems["settings"]["ML"].strChannel = strText
	self.channel = ICCommLib.JoinChannel(self.tItems["settings"]["ML"].strChannel ,ICCommLib.CodeEnumICCommChannelType.Global)
	self.channel:SetReceivedMessageFunction("OnReceivedItem",self)
end

function RaidOpsMasterLoot:MLShowGuildBank()
	self.tItems["settings"]["ML"].bShowGuildBank = true
end

function RaidOpsMasterLoot:MLShowGuildBankNot()
	self.tItems["settings"]["ML"].bShowGuildBank = false
end

function RaidOpsMasterLoot:MLSetGBManager(wndHandler,wndControl,strText)
	self.tItems["settings"]["ML"].strGBManager = strText
end

function RaidOpsMasterLoot:BidAllowMultiSelection()
	self.tItems["settings"]["ML"].bAllowMulti = true
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:BidDisAllowMultiSelection()
	self.tItems["settings"]["ML"].bAllowMulti = false
	self.tSelectedItems = {}
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:BidDisplayApplicableEnable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bDisplayApplicable = true
	Hook:OnMasterLootUpdate(true)
end

function RaidOpsMasterLoot:BidDisplayApplicableDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bDisplayApplicable = false
	Hook:OnMasterLootUpdate(true)
end

---------------------------------------------------------------------------------------------------
-- Rsponses Functions
---------------------------------------------------------------------------------------------------

function RaidOpsMasterLoot:ResponsesClose( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Show(false)
end

function RaidOpsMasterLoot:SendRequests( wndHandler, wndControl, eMouseButton )
	self.allResponses = ""
	self.wndResponses:FindChild("EditBox"):SetText(self.allResponses)
	self.wndResponses:Show(true,false)
	self.wndResponses:ToFront()
	if self.channel then
		self:Bid2PackAndSend({type = "WantConfirmation"})
	end
end

function RaidOpsMasterLoot:Bid2GetTargetsTable()
	local targets = {}
	local myName = GameLib.GetPlayerUnit():GetName()
	for k=1,GroupLib.GetMemberCount() do
		local member = GroupLib.GetGroupMember(k)
		if member.strCharacterName ~= myName then
			table.insert(targets,member.strCharacterName)
		end
	end
	return targets
end

function RaidOpsMasterLoot:AddResponse(who)
	self.allResponses = self.allResponses .. who .. "\n"
	self.wndResponses:FindChild("EditBox"):SetText(self.allResponses)
end

-----------------------------------------------------------------------------------------------
-- RaidOpsMasterLoot Instance
-----------------------------------------------------------------------------------------------
local RaidOpsMasterLootInst = RaidOpsMasterLoot:new()
RaidOpsMasterLootInst:Init()
