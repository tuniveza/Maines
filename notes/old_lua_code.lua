
--[[ local AC = LibStub("AceConfig-3.0")  -- Load AceConfig
local ACD = LibStub("AceConfigDialog-3.0")  -- Load AceConfigDialog

local defaults = {
    profile = {
        message = "shit",
        showOnScreen = true,
    },
}

local options = {
    name = "Maines",  -- Addon name
    handler = WelcomeHome,  -- Your addon's handler
    type = "group",  -- Type of configuration (group, list, etc.)
    args = {
        message = {
            type = "input",
            name = "Trash?",
            desc = "Set the welcome message",
            get = function(info) return defaults.profile.message end,
            set = function(info, value) defaults.profile.message = value end,
        },
        showOnScreen = {
            type = "toggle",
            name = "Garbage",
            desc = "Toggle display on screen",
            get = function(info) return defaults.profile.showOnScreen end,
            set = function(info, value) defaults.profile.showOnScreen = value end,
        },
        -- Add more options as needed
    },
}

-- Register the configuration panel
AC:RegisterOptionsTable("Maines", options)
ACD:AddToBlizOptions("Maines", "Maines")  -- Add to Blizzard's options menu

 ]]

 --[[ 

local frame = CreateFrame("Frame");
local category, layout = Settings.RegisterCanvasLayoutCategory(frame, "My Category Name");

-- Any anchors assigned to the frame will be disposed. Intended anchors need to be provided through
-- the layout object. If no anchor points are provided, the frame will be anchored to TOPLEFT (0,0)
-- and BOTTOMRIGHT (0,0).
layout:AddAnchorPoint("TOPLEFT", 10, -10);
layout:AddAnchorPoint("BOTTOMRIGHT", -10, 10);


-- or a settings list:
local category, layout = Settings.RegisterVerticalLayoutCategory("My Category Name");

Settings.RegisterAddOnCategory(category);

-- To assign a subcategory:
local category = category or Settings.GetCategory("My Category Name");

-- a frame:
local category = category or Settings.GetCategory("My Category Name");
local subcategory, layout = Settings.RegisterCanvasLayoutSubcategory(category, frame, "My Subcategory Name");

-- or a settings list:
local subcategory, layout = Settings.RegisterVerticalLayoutSubcategory(category, "My Subcategory Name");

Settings.RegisterAddOnCategory(subcategory);

-- Sample setting creation and registration:
local myVariableTable = {}; -- Saved in your .toc

-- check box
local variable, name, tooltip = "MyCheckBox", "My CheckBox", "My CheckBox Tooltip";
local setting = Settings.RegisterProxySetting(category, variable, myVariableTable, Settings.VarType.Boolean, name, Settings.Default.True);
Settings.CreateCheckBox(category, setting, tooltip);

-- slider
local variable, name, tooltip = "MySlider", "My Slider", "My Slider Tooltip";
local minValue, maxValue, step = 1, 100, 1;
local options = Settings.CreateSliderOptions(minValue, maxValue, step);
options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);

local defaultValue = 50;
local setting = Settings.RegisterProxySetting(category, variable, myVariableTable, Settings.VarType.Number, name, defaultValue);
Settings.CreateSlider(category, setting, options, tooltip);

-- dropdown
local variable, name, tooltip = "MyDropDown", "My DropDown", "My DropDown Tooltip";
local function GetOptions()
    local container = Settings.CreateControlTextContainer();
    container:Add(0, "Option A");
    container:Add(1, "Option B");
    container:Add(2, "Option C");
    return container:GetData();
end

local defaultValue = 0;
local setting = Settings.RegisterProxySetting(category, variable, myVariableTable, Settings.VarType.Number, name, defaultValue);
Settings.CreateDropDown(category, setting, GetOptions, tooltip);
 ]]




 Maines_Option_Panel_Title = Maines_Option_Panel:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
Maines_Option_Panel_Title:SetPoint("TOPLEFT", 16, -16)
Maines_Option_Panel_Title:SetText("Maines")

Maines_Descriptor = Maines_Option_Panel:CreateFontString("ARTWORK", nil, "GameFontWhiteSmall")
Maines_Descriptor:SetPoint("TOPLEFT", 16, -32)
Maines_Descriptor:SetText("This addon has been written for the purposes of customizable nameology of main names within social channel's")


Maines_Option_Description = Maines_Option_Panel:CreateFontString("ARTWORK", nil, "GameFontWhiteSmall")
Maines_Option_Description:SetPoint("TOPLEFT", 16, -48) ]]
