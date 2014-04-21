-------------------------------------------------
--[[		   PlayerPort					]]--
--[[ Teleport to your friends, group or		]]--
--[[ locations (via players in your guild) 	]]--
--[[ 			   							]]--
--[[ Version 0.1.3 							]]--
------------------------------------------------

-- emit to chat window 
local function chatmsg(args) 
	local msg = ""
	
	if args == nil then 
		msg = "nil"
	end
	
	local argtype = type(args)
	if argtype == "string" then 
		msg = args 
	elseif argtype == "table" then 
		local first = true 
		for i,v in ipairs(args) do 
			if first == false then 
				msg = msg.." , "
			end
			msg = msg..tostring(v)
			first = false
		end
	elseif args ~= nil then 
		msg = tostring(args)
	end
	CHAT_SYSTEM:AddMessage(msg) 
end 

-- http://www.lua.org/pil/19.3.html
local function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
	i = i + 1
	if a[i] == nil then return nil
	else return a[i], t[a[i]]
	end
  end
  return iter
end

-- get a table of zoneName->{playerName,alliance} from guilds
local function GetGuildMemberLocationTable()
	local returnValue = {}
	local gCount = GetNumGuilds()
	local pCount = 0
	local cCount = 0
	
	local pAlliance = GetUnitAlliance("player")
	local pName = string.lower(GetDisplayName())
	
	for g = 1, gCount do 
		
		pCount = GetNumGuildMembers(g)
		
		for p = 1, pCount do
			local playerName,note,rankindex,playerStaus,secsSinceLogoff = GetGuildMemberInfo(g,p)
			-- only get players that are online >_<
			if  playerStaus ~= PLAYER_STATUS_OFFLINE and secsSinceLogoff == 0 and pName ~= string.lower(playerName) then 
				local hasChar, charName, zoneName,classtype,alliance = GetGuildMemberCharacterInfo(g,p)
				
				if hasChar == true and alliance == pAlliance then 
					returnValue[zoneName] = returnValue[zoneName] or {}
					table.insert(returnValue[zoneName],{playerName,alliance,charName})
				end
			end
		end
	
	end
	return returnValue
end
-- get a table of {displayName,zoneName,alliance} from friends list
local function GetFriendLocationTable()
	local returnValue = {}
	local fCount = GetNumFriends()
	local pAlliance = GetUnitAlliance("player")
	
	for i = 1, fCount do
		local displayName, note, playerstaus,secsSinceLogoff = GetFriendInfo(i)
		
		-- only get players that are online >_<
		if playerstaus ~= PLAYER_STATUS_OFFLINE and secsSinceLogoff == 0 then 
			local hasChar, charName, zoneName,classtype,alliance = GetFriendCharacterInfo(i)
			
			if hasChar == true and pAlliance == alliance then 
				table.insert(returnValue,{displayName,zoneName,alliance})
			end
		end
		
	end
	return returnValue
end

-- get a table of {playerName?,zoneName,alliance,groupLeader} from group list
local function GetGroupLocationTable()
	local returnValue = {}
	
	local gCount = GetGroupSize()
	
	local pChar = string.lower(GetUnitName("player"))
	
	for i = 1, gCount do 
		local unitTag = GetGroupUnitTagByIndex(i)
		local unitName = GetUnitName(unitTag)
		-- only get players that are online >_<
		if unitTag ~= nil and IsUnitOnline(unitTag) and string.lower(unitName) ~= pChar then 
			table.insert(returnValue,{unitName,GetUnitZone(unitTag),GetUnitAlliance(unitTag),IsUnitGroupLeader(unitTag),GetUniqueNameForCharacter(GetUnitName(unitTag))})
		end 
		
	end
	
	return returnValue
end

-- (GetEvenShorterAllianceName)
local function GetAlliance(alliance)
	if alliance == ALLIANCE_EBONHEART_PACT  then
		return "EP"
	elseif alliance == ALLIANCE_ALDMERI_DOMINION  then
		return "AD"
	elseif alliance == ALLIANCE_DAGGERFALL_COVENANT then
		return "DC"
	end
	--return GetShortAllianceName(alliance)
end

local function IsPlayerReallyInGroup(playerName)
	local gCount = GetGroupSize()
	local pName = string.lower(playerName)
	
	for i = 1, gCount do 
		local unitTag = GetGroupUnitTagByIndex(i)
		-- only get players that are online >_<
		if unitTag ~= nil and string.lower(GetUnitName(unitTag)) == pName then
			return true
		end
	end
	return IsPlayerInGroup(playerName)
end

-- search all guilds for playerName
local function IsPlayerInGuild(playerName)
	local gCount = GetNumGuilds()
	
	local pCount = 0
	
	for g = 1, gCount do 
		
		pCount = GetNumGuildMembers(g)
		
		for p = 1, pCount do
			local name = GetGuildMemberInfo(g,p)
			if string.lower(playerName) == string.lower(name) then
				return true
			end
		end
	
	end
	return false
end

local function IsJumpablePlayer(playerName)
	return IsPlayerReallyInGroup(playerName) or IsFriend(playerName) or IsPlayerInGuild(playerName)
end

local function JumpToPlayer(playerName)
	if IsPlayerReallyInGroup(playerName) then
		chatmsg("Jumping to group member: "..playerName)
		JumpToGroupMember(playerName)
		return true
	elseif IsFriend(playerName) then 
		chatmsg("Jumping to friend: "..playerName)
		JumpToFriend(playerName)
		return true
	elseif IsPlayerInGuild(playerName) then 
		chatmsg("Jumping to guild member: "..playerName)
		JumpToGuildMember(playerName)
		return true 
	else
		chatmsg("Unable to jump to player: "..playerName)
		return false
	end
end

local function JumpToLocation(zoneName,tryFriendsAndGroup)

	local locTable
	rawZone = zoneName
	zoneName = string.lower(zoneName)
	
	if tryFriendsAndGroup == true then
		locTable = GetGroupLocationTable()
		for i,v in ipairs(locTable) do 
			if string.lower(v[2]) == zoneName then
				JumpToPlayer(v[1])
				return true
			end
		end

		locTable = GetFriendLocationTable()
		for i,v in ipairs(locTable) do 
			if string.lower(v[2]) == zoneName then
				JumpToPlayer(v[1])
				return true
			end
		end
	end
	
	locTable = GetGuildMemberLocationTable()
	
	for k,v in pairs(locTable) do
		if string.lower(k) == zoneName then
			local count = #v
			if count > 0 then 
				-- end up somewhere in the zone...
				local c = v[math.random(1,count)][1]
				chatmsg("Jumping to: "..rawZone.." via "..c)
				JumpToPlayer(c)
				return true
			end
		end
	end
	
	chatmsg("Unable to jump too: "..zoneName)
	return false
end

--- Location list control menu 
local _locationListControl

local function AddSetJumpButton(btnPrefix,btnId,text,jumpFunc)
	id = btnPrefix..tostring(btnId)
	btn = _locationListControl:GetButton(id)
	
	if btn == nil then 
		btn = _locationListControl:AddButton(id,text,20,jumpFunc)
	else
		btn:SetText(text)
		btn:SetHandler("OnClicked",jumpFunc)
		btn:SetHidden(false)
	end
end


local function RefreshLocationList()
	local glocTable = GetGuildMemberLocationTable()
	local flocTable = GetFriendLocationTable()
	local grlocTable = GetGroupLocationTable()

	
	local btnPrefix = "PlayerPort_LocationOptionsList_Button"
	local btnId = 1
	
	local id = ""
	
	local btn
	-- hide all
	_locationListControl:HideAll(4)

	-- group
	for i,v in ipairs(grlocTable) do 
		local jumpFunc = function() 
			if JumpToPlayer(v[1]) then
				_locationListControl:SetHidden(true)
			else
				RefreshLocationList()
			end
		end
		
		local ldr = ""
		if v[4] == true then 
			ldr = " *"
		end
		
		local text ="[Group] "..v[1]..ldr.." ["..v[2].." ("..GetAlliance(v[3])..")]"
		
		AddSetJumpButton(btnPrefix,btnId,text,jumpFunc)
		
		btnId = btnId + 1 
	end
	--friends
	for i,v in ipairs(flocTable) do
	
		local jumpFunc = function() 
			if JumpToPlayer(v[1]) then
				_locationListControl:SetHidden(true)
			else
				RefreshLocationList()
			end
		end
		
		local text = "[Friend] "..v[1].." ["..v[2].." ("..GetAlliance(v[3])..")]"
		
		AddSetJumpButton(btnPrefix,btnId,text,jumpFunc)
		
		btnId = btnId + 1 
	end
	-- locations
	for loc,charTable in pairsByKeys(glocTable,
		function(x,y) 
			if glocTable[x][1][2] == glocTable[y][1][2] then 
				return x < y
			else 
				return glocTable[x][1][2] < glocTable[y][1][2]
			end
		end) do 
		
		local jumpFunc = function() 
			if JumpToLocation(loc,false) then
				_locationListControl:SetHidden(true)
			else
				RefreshLocationList()
			end
		end
		
		local text = loc.." ["..GetAlliance(charTable[1][2]).."] ".." ("..tostring(#charTable)..")"
		
		AddSetJumpButton(btnPrefix,btnId,text,jumpFunc)
		
		btnId = btnId + 1 
	end
	_locationListControl:SetScrollHeightForVisible()
end

local function OpenLocationList()

	if _locationListControl == nil then 
		_locationListControl = ScrollList("PlayerPort_LocationOptionsList","Goto Location",400,400,ZO_AlchemyTopLevelSkillInfo)
		_locationListControl:AddButton("PlayerPort_LocationOptionsList_ButtonRefresh","Refresh",20,
			function() RefreshLocationList() end
		)
		_locationListControl:AddButton("PlayerPort_LocationOptionsList_ButtonClose","Close",20,function() _locationListControl:SetHidden(true) end)
		_locationListControl:AddButton("PlayerPort_LocationOptionsList_ButtonClosest","Closest Wayshrine",20,function() 
			JumpToPlayer(GetDisplayName()) 	
			_locationListControl:SetHidden(true) 
		end)
	else
		_locationListControl:SetHidden(false)
	end
	RefreshLocationList()
end

--[[ chat link click function hook ]]--

local _listControl
local function InitList()
	_listControl = ScrollList("PlayerPort_MenuList","Player Options",200,100,ZO_AlchemyTopLevelSkillInfo)
	_listControl:AddButton("PlayerPort_MenuList_JumptoPlayerButton","Jump To Player",20,function() end)
	_listControl:AddButton("PlayerPort_MenuList_CloseButton","Close",20,function() _listControl:SetHidden(true) end)
	_listControl:SetHidden(true)
end

local function InitChatSystemLinkClickedHook()
	local orig_ZO_ChatSystem_OnLinkClicked = ZO_ChatSystem_OnLinkClicked
	function ZO_ChatSystem_OnLinkClicked(cmd,link,button)
		if button == 2 and string.find(cmd,"display:") ~= nil then 
			if _listControl == nil then
				InitList()
			end
			if _locationListControl ~= nil then 
				_locationListControl:SetHidden(true)
			end
			_listControl:SetHidden(false)
			local btn = _listControl:GetButton("PlayerPort_MenuList_JumptoPlayerButton")
			if btn ~= nil then 
				local s,c = string.find(link,"@.+]")
				local playerName = string.sub(link,s,c-1)
				btn:SetHandler("OnClicked",function() 
					JumpToPlayer(playerName)  
					_listControl:SetHidden(true)
				end)
			end
		end
		orig_ZO_ChatSystem_OnLinkClicked(cmd,link,button)
	end
end

local function InitSlashCommands()

	SLASH_COMMANDS["/goto"] = function(args)
		if args ~= nil and args ~= "" then
			if IsJumpablePlayer(args) == true then
				JumpToPlayer(args)
			else
				JumpToLocation(args,true)
			end
		else
			if _listControl ~= nil and _listControl:IsHidden() == false then
				_listControl:SetHidden(true)
			end
			
			if _locationListControl == nil or _locationListControl:IsHidden() == true then 
				OpenLocationList()
			else
				_locationListControl:SetHidden(true)
			end
		end
	end
	
end

local function PlayerPort_Loaded(eventCode, addOnName)

	if(addOnName ~= "PlayerPort") then
        return
    end
	
	InitChatSystemLinkClickedHook()
	
	InitSlashCommands()
	
end

EVENT_MANAGER:RegisterForEvent("PlayerPort_Loaded", EVENT_ADD_ON_LOADED, PlayerPort_Loaded)


