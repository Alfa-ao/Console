local slashCommand = ToWs( "/console.log" )
local wtTextContainer = mainForm.wtTextContainer

local function LoadConfig()
    return userMods.GetGlobalConfigSection( common.GetAddonName() ) or {}
end

local function SaveConfig( data )
    local config = LoadConfig()
    
    config[ "active" ] = data.active
    
    userMods.SetGlobalConfigSection( common.GetAddonName(), config  )
end

DnDManager:Init()
DnDManager:Register( wtTextContainer, { saveToConfig = true },
{
    {
        wtHandle = wtTextContainer.wtDragBottomRight,
        allowX = true,
        allowY = true,
        limitsX = { min = 400, max = 1000 },
        limitsY = { min = 200, max = 1000 },
    }
} )

--------------------------------------------------------------------------------
-- Кнопка "X" закрыть консоль.
--------------------------------------------------------------------------------
local function OnButtonClose()
    mainForm:Show( false )
    advEvent:SendEventUserMods( "CONSOLE_USERADDON_DISABLE" )
    wtTextContainer:RemoveItems()
    SaveConfig { active = false }
end

advReaction.RegisterReactionHandler( false, OnButtonClose, "close_click", wtTextContainer.wtClose )

--------------------------------------------------------------------------------
local isActive = LoadConfig().active

--------------------------------------------------------------------------------
-- События
--------------------------------------------------------------------------------
local events = {
    {
        function( params )
            if params.name == ADDON_NAME then
                if params.state == ADDON_STATE_LOADED and isActive then
                    mainForm:Show( true )
                    advEvent:SendEventUserMods( "CONSOLE_USERADDON_SEND_PING" )
                elseif params.state == ADDON_STATE_UNLOADING then
                    advEvent:SendEventUserMods( "CONSOLE_USERADDON_DISABLE" )
                end
            end
        end,
        "EVENT_ADDON_LOAD_STATE_CHANGED"
    },
    {
        function( params )
            if params.text == slashCommand then
                mainForm:Show( true )
                advEvent:SendEventUserMods( "CONSOLE_USERADDON_SEND_PING" )
                SaveConfig { active = true }
            end
        end,
        "EVENT_UNKNOWN_SLASH_COMMAND"
    },
    {
        function( params )
            if not mainForm:IsVisible() then return end
            
            local result = ( params.var_dump or type( params.data ) ~= "string" ) 
                and var_dump( params.data ) 
                or params.data
            
            if not result then return end
            
            if params.highlight then
                result = SyntaxHighlighter:highlight( result )
            end
            
            result = result:gsub("\r?\n", "<br/>")
            
            wtTextContainer:PushFrontText( ToWs( "<html>" .. result .. "</html>" ) )
        end,
        "CONSOLE_USERADDON_SEND_DATA"
    },
}

advEvent.RegisterEventHandlers( false, events )