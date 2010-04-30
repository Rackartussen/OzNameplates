OzNameplates = LibStub("AceAddon-3.0"):NewAddon("OzNameplates", "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

OzNameplates.options = {
    name = "OzNameplates",
    handler = OzNameplates,
    type = "group",
	get = "OptionsGet",
	set = "OptionsSet",
    args = {
		healthBar={
			name = "Health bar",
			type = "group",
			get = "HealthBarOptionsGet",
			set = "HealthBarOptionsSet",
			order = 5,
			args={
				-- more options go here
				width = {
					type = "range",
					min = 50,
					max = 500,
					step = 10,
					name = "Width",
					desc = "Width of the nameplates",
					order = 2,
				},
				height = {
					type = "range",
					min = 0,
					max = 32,
					step  = 2,
					name = "Height",
					desc = "Height of the nameplates",
					order = 3,
				},
			},
		},
		castBar ={
			name = "Cast bar",
			type = "group",
			get = "CastBarOptionsGet",
			set = "CastBarOptionsSet",
			order = 6,
			args = {
				width = {
					type = "range",
					min = 50,
					max = 500,
					step  = 10,
					name = "Width",
					desc = "Width of the cast bar",
					order = 2,
				},
				height = {
					type = "range",
					min = 0,
					max = 32,
					step  = 2,
					name = "Height",
					desc = "Height of the cast bar",
					order = 3,
				},
			}
		},
		tanking = {
			type = "toggle",
			name = "Tanking",
			desc = "Tanking",
			order = 1,
		},
		fontSize = {
			type = "range",
			min = 4,
			max = 15,
			step  = 1,
			name = "Font Size",
			desc = "Size of the font",
			order = 4,
		},
		fontFile = {
			type = "select",
			name = "Font",
			desc = "Font",
			dialogControl = "LSM30_Font",
			values = LSM:HashTable("font"),
			order = 1,
		},
		statusBarFile = {
			type = "select",
			name = "Texture",
			dialogControl = "LSM30_Statusbar",
			values = LSM:HashTable("statusbar"),
			order = 2,
		},
    },
}

local defaults = {
	profile = {
		healthBar = {
			width = 150,
			height = 14,
		},
		castBar = {
			width = 150,
			height = 12,
		},
		barColor = {.7,.7,.7},
		font = "Fonts\\FRIZQT__.TTF",
		fontFile = "",
		fontSize = 9,
		statusBar = "Interface\\TargetingFrame\\UI-StatusBar\\Blizzard",
		statusBarFile = "",
		border = "Interface\\None",
		borderFile = "",
		fontFlags = "",
		background = {},
		done = false,
		overlayTexture = [=[Interface\Tooltips\Nameplate-Border]=],
		backdrop = {
			edgeFile = [=[Interface\Addons\OzNameplates\media\glowtex]=], 
			edgeSize = 5,
			insets = {
				left = 3, 
				right = 3, 
				top = 3, 
				bottom = 3}
			}
		
	},
}

function OzNameplates:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("OzNameplatesDB", defaults, "Default")

	self.lastUpdate = 0
	self.numKids = 0

	self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("OzNameplates", self.options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("OzNameplates", "OzNameplates")

	self:RegisterChatCommand("oznp", "ChatCommand")

end

function OzNameplates:ChatCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(OzNameplates, "wh", "OzNameplates", input)
    end
end

function OzNameplates:OnEnable()

	-- Create dummy frame for OnUpdate catching
	self.dummyFrame = CreateFrame("Frame", nil, UIParent)
	self.dummyFrame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	self:HookScript(self.dummyFrame,"OnUpdate","OnUpdate")
	self.unitClass = UnitClass("player")
	if (self.unitClass == "Death Knight" or self.unitClass == "Druid") then
		self:CheckShapeshiftInfo()
		self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	elseif (self.unitClass == "Warrior" or self.unitClass == "Paladin") then
		self:RegisterEvent("PLAYER_TALENT_UPDATE")
		self:CheckTalentInfo()
	else
		self.db.profile.tanking = false
	end
end

function OzNameplates:PLAYER_TALENT_UPDATE()
	self:CheckTalentInfo()
end

function OzNameplates:CheckTalentInfo()
	local talentInfo = {0,0,0}
	for i = 1, GetNumTalentTabs() do
       local name, icon, pointsSpent, _, _ = GetTalentTabInfo(i)
	   talentInfo[i] = pointsSpent
	end
	if (self.unitClass == "Warrior") then
		if (talentInfo[3] > talentInfo[2] and talentInfo[3] > talentInfo[1]) then
			self.db.profile.tanking = true
		else
			self.db.profile.tanking = false
		end
	elseif (self.unitClass == "Paladin") then
		if (talentInfo[2] > talentInfo[1] and talentInfo[2] > talentInfo[3]) then
			self.db.profile.tanking = true
		else
			self.db.profile.tanking = false
		end
	end
end

function OzNameplates:CheckShapeshiftInfo()
	for i=1,GetNumShapeshiftForms() do
		local icon, name, active, castable = GetShapeshiftFormInfo(i)
		if (active) then	
			if (self.unitClass == "Death Knight") then
				if (name == "Frost Presence") then
					self.db.profile.tanking = true
				else 
					self.db.profile.tanking = false
				end
			elseif (self.unitClass == "Druid") then
				if (name == "Dire Bear Form" or name == "Bear Form") then
					self.db.profile.tanking = true
				else 
					self.db.profile.tanking = false
				end
			end
		end
	end
end

function OzNameplates:UPDATE_SHAPESHIFT_FORM()
	self:CheckShapeshiftInfo()
end

function OzNameplates:OnUpdate(dummyFrame, elapsed)
	self.lastUpdate = self.lastUpdate + elapsed

	if self.lastUpdate > 0.1 then
		self.lastUpdate = 0

		local newNumKids = WorldFrame:GetNumChildren()
		if newNumKids ~= self.numKids then
			for i = self.numKids+1, newNumKids do
				local frame = select(i, WorldFrame:GetChildren())

				if self:IsValidFrame(frame) then
					self:CreateFrame(frame)
				end
			end
			self.numKids = newNumKids
		end
	end
end

function OzNameplates:IsValidFrame(frame)
	if frame:GetName() then
		return
	end

	overlayRegion = select(2, frame:GetRegions())

	return overlayRegion and overlayRegion:GetObjectType() == "Texture" and overlayRegion:GetTexture() == self.db.profile.overlayTexture
end

local UpdateTime = function(self, curValue)
	local minValue, maxValue = self:GetMinMaxValues()
	if self.channeling then
		self.time:SetFormattedText("%.1f ", curValue)
	else
		self.time:SetFormattedText("%.1f ", maxValue - curValue)
	end
end

function OzNameplates:ThreatUpdate (nameplateFrame, elapsed)
	nameplateFrame.elapsed = nameplateFrame.elapsed + elapsed
	if nameplateFrame.elapsed >= 0.2 then
		if not self.db.profile.tanking then
			if not nameplateFrame.oldglow:IsShown() then
				nameplateFrame.healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0)
				nameplateFrame.healthBar:SetWidth(self.db.profile.healthBar.width);
				nameplateFrame.healthBar:SetStatusBarColor(nameplateFrame.r, nameplateFrame.g, nameplateFrame.b)
			else
				nameplateFrame.healthBar.hpGlow:SetBackdropBorderColor(1,0,0)
				nameplateFrame.healthBar:SetWidth(self.db.profile.healthBar.width*1.2);
				if (nameplateFrame.healthBar.UnitType == "Hostile") then
					nameplateFrame.healthBar:SetStatusBarColor(1, 0, 0)
				else
					nameplateFrame.healthBar:SetStatusBarColor(nameplateFrame.r, nameplateFrame.g, nameplateFrame.b)
				end
			end
		else
			if not nameplateFrame.oldglow:IsShown() then
				nameplateFrame.healthBar.hpGlow:SetBackdropBorderColor(1,0,0)
				nameplateFrame.healthBar:SetWidth(self.db.profile.healthBar.width*1.2);
				if (nameplateFrame.healthBar.UnitType == "Hostile") then
					nameplateFrame.healthBar:SetStatusBarColor(1, 0, 0)
				else
					nameplateFrame.healthBar:SetStatusBarColor(nameplateFrame.r, nameplateFrame.g, nameplateFrame.b)
				end
			else
				nameplateFrame.healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0)
				nameplateFrame.healthBar:SetWidth(self.db.profile.healthBar.width);
				nameplateFrame.healthBar:SetStatusBarColor(nameplateFrame.r, nameplateFrame.g, nameplateFrame.b)
			end
		end

		self.elapsed = 0
	end
end

function OzNameplates:GetClass(r, g, b)
	local r, g, b = floor(r*100+.5)/100, floor(g*100+.5)/100, floor(b*100+.5)/100
	for class, color in pairs(RAID_CLASS_COLORS) do
		if RAID_CLASS_COLORS[class].r == r and RAID_CLASS_COLORS[class].g == g and RAID_CLASS_COLORS[class].b == b then
			return class
		end
	end
	return 0
end

function OzNameplates:ClassIconTexCoord(r, g, b)
	local class = self:GetClass(r,g,b)
	if not (class==0) then
		local texcoord = CLASS_BUTTONS[class]
		if (texcoord) then
			return unpack(texcoord)
		end
	end
	return 0.5, 0.75, 0.5, 0.75
end


function OzNameplates:UpdateFrame (nameplateFrame)
	nameplateFrame.healthBar.UnitType = nil
	local r, g, b = nameplateFrame.healthBar:GetStatusBarColor()
	nameplateFrame.icon:SetTexCoord(self:ClassIconTexCoord(r, g, b))
	local newr, newg, newb
	if g + b == 0 then
		-- Hostile unit
		newr, newg, newb = 0.69, 0.31, 0.31
		nameplateFrame.healthBar:SetStatusBarColor(0.69, 0.31, 0.31)
		--if nameplateFrame.boss:IsShown() or nameplateFrame.elite:IsShown() then
			nameplateFrame.healthBar.UnitType = "Hostile"
		--end
	elseif r + b == 0 then
		-- Friendly unit
		newr, newg, newb = 0.33, 0.59, 0.33
		nameplateFrame.healthBar:SetStatusBarColor(0.33, 0.59, 0.33)
	elseif r + g == 0 then
		-- Friendly player
		newr, newg, newb = 0.31, 0.45, 0.63
		nameplateFrame.icon:SetTexCoord(self:ClassIconTexCoord(r, g, b))
		nameplateFrame.healthBar:SetStatusBarColor(0.31, 0.45, 0.63)
	elseif 2 - (r + g) < 0.05 and b == 0 then
		-- Neutral unit
		newr, newg, newb = 0.65, 0.63, 0.35
		nameplateFrame.healthBar:SetStatusBarColor(0.65, 0.63, 0.35)
	else
		-- Hostile player - class colored.
		newr, newg, newb = r, g, b
	end

	nameplateFrame.r, nameplateFrame.g, nameplateFrame.b = newr, newg, newb

	nameplateFrame.healthBar:ClearAllPoints()
	nameplateFrame.healthBar:SetPoint("CENTER", nameplateFrame.healthBar:GetParent())
	nameplateFrame.healthBar:SetHeight(self.db.profile.healthBar.height)
	nameplateFrame.healthBar:SetWidth(self.db.profile.healthBar.width)

	nameplateFrame.castBar:ClearAllPoints()
	nameplateFrame.castBar:SetPoint("TOP", nameplateFrame.healthBar, "BOTTOM", 0, -4)
	nameplateFrame.castBar:SetHeight(self.db.profile.castBar.height)
	nameplateFrame.castBar:SetWidth(self.db.profile.castBar.width)

	nameplateFrame.highlight:ClearAllPoints()
	nameplateFrame.highlight:SetAllPoints(nameplateFrame.healthBar)
	local nameplateName = nameplateFrame.oldname:GetText()
	if (nameplateName == "Grounding Totem") then
		self:Print("Hi there");
	end
	nameplateFrame.name:SetText(nameplateName)

	local level, elite, mylevel = tonumber(nameplateFrame.level:GetText()), nameplateFrame.elite:IsShown(), UnitLevel("player")
	nameplateFrame.level:ClearAllPoints()
	nameplateFrame.level:SetPoint("RIGHT", nameplateFrame.healthBar, "RIGHT", -2, 0)
	if nameplateFrame.boss:IsShown() then
		nameplateFrame.level:SetText("B")
		nameplateFrame.level:SetTextColor(0.8, 0.05, 0)
		nameplateFrame.level:Show()
	elseif not elite and level == mylevel then
		nameplateFrame.level:Hide()
	else
		nameplateFrame.level:SetText(level..(elite and "+" or ""))
	end
end

function OzNameplates:GetTargetSpellInfo()
	local _, _, displayName, icon, _, _, _, castId, noInterrupt = UnitCastingInfo("target")
	if displayName then
		return displayName, icon, noInterrupt
	end
	_, _, displayName, icon, _, _, _, noInterrupt = UnitChannelInfo("target")
	if displayName then
		return displayName, icon, noInterrupt
	end
	return "", "", nil
end

function OzNameplates:FixCastbar(frame)
	frame.castbarOverlay:Hide()

	frame:SetHeight(10)
	frame:ClearAllPoints()
	frame:SetPoint("TOP", frame.healthBar, "BOTTOM", 0, -4)

	local displayName, icon, noInterrupt = self:GetTargetSpellInfo()
	if displayName then
		frame.spellName:SetText(displayName)
	end
	if (noInterrupt) then
		frame:SetStatusBarColor(1, 1, 1)
	else
		frame:SetStatusBarColor(0.9,0.9,0.1)
	end

	frame.castIcon:SetTexture(icon)
	
end

function OzNameplates:ColorCastBar(frame, shielded)
	if shielded then
		frame:SetStatusBarColor(0.8, 0.05, 0)
		frame.cbGlow:SetBackdropBorderColor(0.75, 0.75, 0.75)
	else
		frame.cbGlow:SetBackdropBorderColor(0, 0, 0)
	end
end

function OzNameplates:OnSizeChanged(frame)
	self.needFix = true
end

function OzNameplates:OnValueChanged(frame, curValue)
	UpdateTime(frame, curValue)
	if frame.needFix then
		FixCastbar(frame)
		frame.needFix = nil
	end
end

function OzNameplates:OnShow(frame)
	frame.channeling  = UnitChannelInfo("target") 
	self:FixCastbar(frame)
	self:ColorCastBar(frame, frame.shieldedRegion:IsShown())
end

function OzNameplates:OnHide(frame)
	frame.highlight:Hide()
	frame.healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0)
end

function OzNameplates:OnEvent(frame, event, unit)
	if unit == "target" then
		if frame:IsShown() then
			self:ColorCastBar(frame, event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
		end
	end
end

function OzNameplates:CreateFrame(frame)
	if frame.done then
		return
	end

	frame.nameplate = true

	frame.healthBar, frame.castBar = frame:GetChildren()
	local healthBar, castBar = frame.healthBar, frame.castBar
	local glowRegion, overlayRegion, castbarOverlay, shieldedRegion, spellIconRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()

	frame.oldname = nameTextRegion
	nameTextRegion:Hide()

	local newNameRegion = frame:CreateFontString()
	newNameRegion:SetPoint("LEFT", healthBar, "LEFT", 0, 1)
	newNameRegion:SetFont(self.db.profile.font, self.db.profile.fontSize, self.db.profile.fontFlags)
	newNameRegion:SetTextColor(0.84, 0.75, 0.65)
	newNameRegion:SetShadowOffset(0.5, -0.5)
	frame.name = newNameRegion

	local classicontexture = frame:CreateTexture(nil, "OVERLAY")
	classicontexture:SetPoint("TOPRIGHT", healthBar, "TOPLEFT", 0, 0)
	classicontexture:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
	classicontexture:SetWidth(self.db.profile.healthBar.height)
	classicontexture:SetHeight(self.db.profile.healthBar.height)
	frame.icon = classicontexture

	frame.level = levelTextRegion
	levelTextRegion:SetFont(self.db.profile.font, self.db.profile.fontSize, self.db.profile.fontFlags)
	levelTextRegion:SetShadowOffset(0.5, -0.5)

	healthBar:SetStatusBarTexture(self.db.profile.statusBar)
	healthBar.hpBackground = healthBar:CreateTexture(nil, "BORDER")
	healthBar.hpBackground:SetAllPoints(healthBar)
	healthBar.hpBackground:SetTexture(self.db.profile.statusBar)
	healthBar.hpBackground:SetVertexColor(0.15, 0.15, 0.15)

	healthBar.hpGlow = CreateFrame("Frame", nil, healthBar)
	healthBar.hpGlow:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -4.5, 4)
	healthBar.hpGlow:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 4.5, -4.5)
	healthBar.hpGlow:SetBackdrop(self.db.profile.backdrop)
	healthBar.hpGlow:SetBackdropColor(0, 0, 0)
	healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0)

	castBar.castbarOverlay = castbarOverlay
	castBar.healthBar = healthBar
	castBar.shieldedRegion = shieldedRegion
	castBar:SetStatusBarTexture(self.db.profile.statusBar)

	self:HookScript(castBar,"OnShow","OnShow")
	self:HookScript(castBar,"OnSizeChanged","OnSizeChanged")
	self:HookScript(castBar,"OnValueChanged","OnValueChanged")
	self:HookScript(castBar,"OnEvent","OnEvent")
	castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	castBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

	castBar.time = castBar:CreateFontString(nil, "ARTWORK")
	castBar.time:SetPoint("RIGHT", castBar, "RIGHT", -2, 0)
	castBar.time:SetFont(self.db.profile.font, self.db.profile.fontSize, self.db.profile.fontFlags)
	castBar.time:SetTextColor(0.84, 0.75, 0.65)
	castBar.time:SetShadowOffset(0.5, -0.5)

	castBar.spellName = castBar:CreateFontString(nil, "ARTWORK")
	castBar.spellName:SetPoint("LEFT", castBar, "LEFT", 2, 1)
	castBar.spellName:SetFont(self.db.profile.font, self.db.profile.fontSize, self.db.profile.fontFlags)
	castBar.spellName:SetTextColor(0.84, 0.75, 0.65)
	castBar.spellName:SetShadowOffset(0.5, -0.5)

	castBar.castIcon = castBar:CreateTexture(nil, "OVERLAY")
	castBar.castIcon:SetPoint("RIGHT", castBar, "LEFT", -2, 0)
	castBar.castIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
	castBar.castIcon:SetWidth(self.db.profile.castBar.height)
	castBar.castIcon:SetHeight(self.db.profile.castBar.height)
	castBar.castIcon:SetTexCoord(0.1,0.9,0.1,0.9)

	castBar.cbBackground = castBar:CreateTexture(nil, "BORDER")
	castBar.cbBackground:SetAllPoints(castBar)
	castBar.cbBackground:SetTexture(self.db.profile.statusBar)
	castBar.cbBackground:SetVertexColor(0.15, 0.15, 0.15)

	castBar.cbGlow = CreateFrame("Frame", nil, castBar)
	castBar.cbGlow:SetPoint("TOPLEFT", castBar, "TOPLEFT", -4.5, 4)
	castBar.cbGlow:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 4.5, -4.5)
	castBar.cbGlow:SetBackdrop(self.db.profile.backdrop)
	castBar.cbGlow:SetBackdropColor(0, 0, 0)
	castBar.cbGlow:SetBackdropBorderColor(0, 0, 0)

	spellIconRegion:SetHeight(0.01)
	spellIconRegion:SetWidth(0.01)
	
	highlightRegion:SetTexture(self.db.profile.statusBar)
	highlightRegion:SetVertexColor(0.25, 0.25, 0.25)
	frame.highlight = highlightRegion

	raidIconRegion:ClearAllPoints()
	raidIconRegion:SetPoint("LEFT", healthBar, "RIGHT", 2, 0)
	raidIconRegion:SetHeight(self.db.profile.healthBar.height)
	raidIconRegion:SetWidth(self.db.profile.healthBar.height)

	frame.oldglow = glowRegion
	frame.elite = stateIconRegion
	frame.boss = bossIconRegion

	frame.done = true

	glowRegion:SetTexture(nil)
	overlayRegion:SetTexture(nil)
	shieldedRegion:SetTexture(nil)
	castbarOverlay:SetTexture(nil)
	stateIconRegion:SetTexture(nil)
	bossIconRegion:SetTexture(nil)

	self:UpdateFrame(frame)
	self:HookScript(frame, "OnShow", "UpdateFrame")
	self:HookScript(frame, "OnHide", "OnHide")

	frame.elapsed = 0
	self:HookScript(frame, "OnUpdate", "ThreatUpdate")
end

function OzNameplates:HealthBarOptionsGet(info)
	return self.db.profile.healthBar[info[#info]]
end

function OzNameplates:HealthBarOptionsSet(info, value)
	self.db.profile.healthBar[info[#info]] = value
end

function OzNameplates:CastBarOptionsGet(info)
	return self.db.profile.castBar[info[#info]]
end

function OzNameplates:CastBarOptionsSet(info, value)
	self.db.profile.castBar[info[#info]] = value
end

function OzNameplates:OptionsGet(info)
    return self.db.profile[info[#info]]
end

function OzNameplates:OptionsSet(info, value)
	self.db.profile[info[#info]] = value   -- we use the db names in our settings for Zzz
	if info[#info] == "fontFile" then
		self.db.profile.font = LSM:Fetch("font",value)
	elseif info[#info] == "statusBarFile" then
		self.db.profile.statusBar = LSM:Fetch("statusbar",value)
	elseif info[#info] == "borderFile" then
		self.db.profile.border = LSM:Fetch("border",value)
	end
end

