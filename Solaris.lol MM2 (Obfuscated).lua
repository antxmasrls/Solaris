
local UISettingsTab = Window:AddTab({
    Name = "Settings",
    Description = "",
    Icon = "settings",
    Tooltip = "UI configuration and configs",
})

local MenuGroup = UISettingsTab:AddGroupbox({
	Side = "Left",
	Name = "Menu",
	IconName = "wrench"
})

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library:Notify({ Title = "Settings", Description = value and "Keybind Menu Opened" or "Keybind Menu Closed", Time = 4 })
		Library.KeybindFrame.Visible = value
	end,
})

MenuGroup:AddToggle("KeybindMenuVisibilityControl", {
	Default = false,
	Text = "Keybind Menu Visibility",
	Callback = function(value)
		Library:Notify({ Title = "Settings", Description = value and "Keybind Visibility Control Enabled" or "Keybind Visibility Control Disabled", Time = 4 })
		Library.KeybindMenu:SetVisibilityControl(value)
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(Value)
		Library:Notify({ Title = "Settings", Description = Value and "Custom Cursor Enabled" or "Custom Cursor Disabled", Time = 4 })
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddToggle("AlwaysOnTop", {
	Text = "Always On Top",
	Default = Window.AlwaysOnTop,
	Callback = function(Value)
		Library:Notify({ Title = "Settings", Description = Value and "Always On Top Enabled" or "Always On Top Disabled", Time = 4 })
		Window:SetAlwaysOnTop(Value)
	end,
})

MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(Value)
		Library:Notify({ Title = "Settings", Description = "Notification side set to " .. tostring(Value), Time = 4 })
		Library:SetNotifySide(Value)
	end,
})

MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "DPI Scale",
	Callback = function(Value)
		Library:Notify({ Title = "Settings", Description = "DPI Scale set to " .. tostring(Value), Time = 4 })
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)
		Library:SetDPIScale(DPI)
	end,
})

MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		Window:SetCornerRadius(value)
	end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	Library:Notify({ Title = "Settings", Description = "Unloading UI...", Time = 4 })
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("Solaris MM2")
SaveManager:SetFolder("Solaris MM2")
SaveManager:SetSubFolder("Solaris MM2")

SaveManager:BuildConfigSection(UISettingsTab)
ThemeManager:ApplyToTab(UISettingsTab)

SaveManager:LoadAutoloadConfig()
