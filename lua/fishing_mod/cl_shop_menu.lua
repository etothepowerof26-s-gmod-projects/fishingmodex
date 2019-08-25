local PANEL = {} -- Main panel

function PANEL:Init()
	self:MakePopup()
	self:SetDeleteOnClose(false)
	self:SetSizable(true)
	self:SetTitle("Fishing Mod")
	self.baitshop = vgui.Create("Fishingmod:BaitShop", self)
	
	fishingmod.BaitIcons = {}
	for k,v in pairs(self.baitshop.categories) do
		for _, icon in ipairs(v.horiz_scroller:GetItems()) do
			table.insert(fishingmod.BaitIcons, icon)	
		end
	end
	
	self.upgrade = vgui.Create("Fishingmod:Upgrade", self)
	
	self.sheet = vgui.Create("DPropertySheet", self)
	self.sheet:Dock(FILL)
	self:DockPadding(3,21+3,3,3)
	self:SetSize(300, 400)
	self:Center()
	
	-- Add more sheets, maybe more fishing rods and prestige?
	self.sheet:AddSheet("Upgrade", self.upgrade, "icon16/star.png", false, false)
	self.sheet:AddSheet("Bait Shop", self.baitshop, "icon16/add.png", false, false)
	
	fishingmod.UpdateSales()
end

vgui.Register( "Fishingmod:ShopMenu", PANEL, "DFrame" )

-- Upgrade Tab 
local PANEL = {}

function PANEL:CreateUpgradeLabel(varname, printname, type, command, price)
	self[varname] = vgui.Create("Fishingmod:UpgradeButton", self)
	self[varname]:SetType(printname, type, command, price)
	self:AddItem(self[varname])
end

function PANEL:Init()
	local x,y = self:GetParent():GetSize()
	self:SetSize(x,y)			
	self:SetPadding(5)
	self:SetPadding(5)
	
	
	self.money = vgui.Create("DLabel", self)
	self.money.Think = function(self)
		local money = LocalPlayer().fishingmod.money
		self:SetText("Money: " .. money)
	end
	self:AddItem(self.money)
	
	self:CreateUpgradeLabel("length"      , "Rod Length:"   , "length"       , "rod_length"   , fishingmod.RodLengthPrice   )
	self:CreateUpgradeLabel("stringlength", "String Length:", "string_length", "string_length", fishingmod.StringLengthPrice)
	self:CreateUpgradeLabel("reelspeed"   , "Reel Speed:"   , "reel_speed"   , "reel_speed"   , fishingmod.ReelSpeedPrice   )
	self:CreateUpgradeLabel("force"       , "Hook Force:"   , "force"        , "hook_force"   , fishingmod.HookForcePrice   )
end

vgui.Register("Fishingmod:Upgrade", PANEL,"DPanelList")
	

-- Bait Shop tab
local PANEL = {}

function PANEL:Init()
	self:Dock(FILL)
	
	-- Populate bait shop table
	local tbl = {}
	for key, data in pairs(fishingmod.BaitTable) do
		local mdl = data.models[1]
		tbl[mdl] = {
			price = data.price,
			name  = key,
			level = fishingmod.CatchTable[key].levelrequired
		}
	end	
	
	self.categories = {}
	local categories = {5, 10, 15, 30, 50}
	
	for k,v in pairs(categories) do
		local category_table = {
			min = k == 1 and 0 or (k == #categories and v or categories[k - 1]),
			max = (k == #categories and 999 or v)
		}
		
		local category_panel = self:Add("Bait for levels " .. tostring(category_table.min) .. (category_table.max ~= 999 and "-" .. tostring(category_table.max) or "+"))
		
		category_table.sheet = category_panel
		category_table.horiz_scroller = vgui.Create("DPanelList")
		local scroller = category_table.horiz_scroller
		
		scroller:Dock(FILL)
		scroller:EnableHorizontal(true)
		scroller:EnableVerticalScrollbar(true)
		category_table.sheet:SetContents(scroller)
		table.insert(self.categories, category_table)
	end
	
	for model, data in pairs(tbl) do
		local level = LocalPlayer().fishingmod.level
		local required_level = data.level
		
		local category_table = {}
		for k,v in pairs(self.categories) do
			if required_level >= v.min and required_level	< v.max then
				category_table = v
				break
			end
		end
		
		-- PrintTable(_cat)
		
		if next(category_table) == nil then continue end
		
		local icon = vgui.Create("Fishingmod:SpawnIcon")
		icon:SetModel(model)
		icon:SetTooltip(
			"This bait has a chance to catch a(n) " .. data.name
			.. "\nand requires level "
			.. required_level
			.. "\n\nCost: $"
			.. string.Comma(tostring(data.price))
		)
		icon:SetSize(58,58)
		
		fishingmod.BaitTable[data.name].icon = icon
		fishingmod.BaitTable[data.name].name = data.name
		
		if level < required_level then
			icon:SetGrey(true)
		else
			icon.DoClick = function()
				RunConsoleCommand("fishing_mod_buy_bait", data.name)
			end
		end
		
		category_table.horiz_scroller:AddItem(icon)
	end
		
end
	
vgui.Register("Fishingmod:BaitShop", PANEL,"DCategoryList")


------------- Helper components --------------
	
-- Upgrade button
local PANEL = {}

function PANEL:Init()
	self.left = vgui.Create("DButton", self)
	self.left:SetSize(20,20)
	self.left:SetText("<<")
	self.left:SetTooltip("+0")
	
	self.left.DoClick = function()
		-- Change these to network messages
		RunConsoleCommand("fishingmod_downgrade_"..self.command, "1")
	end
			
	self.right = vgui.Create("DButton", self)
	self.right:SetSize(20,20)
	self.right:SetText(">>")		
	
	self.right.DoClick = function()
		RunConsoleCommand("fishingmod_upgrade_"..self.command, "1")
	end

	self.rightlabel = vgui.Create("DLabel", self)
	self.rightlabel:SetSize(100,30)
	
	self.leftlabel = vgui.Create("DLabel", self)
	self.leftlabel:SetSize(100,30)
	
	self.left:Dock(LEFT)
	self.leftlabel:SetPos(30,-4)
	self.rightlabel:SetPos(130,-4)
	self.right:Dock(RIGHT)
end

function PANEL:SetType(friendly, type, command, loss)
	self.friendly = friendly
	self.command = command
	self.type = type
	self.right:SetTooltip("-" .. loss)
	self.set = true
	self.leftlabel:SetText(self.friendly)
end

function PANEL:Think()
	if not self.set then return end
	self.rightlabel:SetText(LocalPlayer().fishingmod[self.type])
end

vgui.Register("Fishingmod:UpgradeButton", PANEL)


-- Markup Tooltip
local PANEL = {}

function PANEL:Init()
	self.percent = 0
end

function PANEL:SetSale(multiplier)
	self.percent = math.Round((multiplier * -1 + 1) * 100)
end

function PANEL:SetGrey(bool)
	self.grey = bool
end

function PANEL:PaintOver(w, h)
	self.BaseClass.PaintOver(self, w, h)

	draw.SimpleText(self.percent.."% OFF", "DermaDefault", 5, 3, color_black, TEXT_ALIGN_LEFT,TEXT_ALIGN_LEFT)
	draw.SimpleText(self.percent.."% OFF", "DermaDefault", 4, 2, HSVToColor(math.Clamp(self.percent + 40, 0, 160), 1, 1), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
	if self.grey then
		draw.RoundedBox(6, 0, 0, 58, 58, Color(100, 100, 100, 200))
	end
end

vgui.Register("Fishingmod:SpawnIcon", PANEL, "SpawnIcon")

function fishingmod.UpdateSales()
	for key, bait in pairs(fishingmod.BaitTable) do
		local required_level = fishingmod.CatchTable[key].levelrequired
		local saleprice = math.Round(bait.price * bait.multiplier)
		
		if IsValid(bait.icon) then
			local newprice
			if saleprice ~= 0 then
				newprice = "$" .. string.Comma(tostring(saleprice))
			else
				newprice = "FREE!"
			end
			
			bait.icon:SetTooltip(
				"This bait has a chance to catch a(n) " .. bait.name
				.. "\nand requires level "
				.. required_level
				-- .. "\n\nThere is a sale for this bait!"
				.. "\n\nOriginal Cost: $"
				.. string.Comma(tostring(bait.price))
				.. "\nCost now: "
				.. newprice
			)
			
			bait.icon:SetSale(bait.multiplier)
		end
	end
end