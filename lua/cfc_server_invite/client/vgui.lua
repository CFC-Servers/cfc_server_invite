local WIDTH = 500
local HEIGHT = 500

local COLOR_BUTTON_HOVERED = Color( 83, 227, 251, 255 )
local COLOR_WHITE = Color( 255, 255, 255, 255 )
local COLOR_INVIS = Color( 0, 0, 0, 0 )
local COLOR_CFC_DARK = Color( 27, 30, 48 )
local COLOR_PLAYER_SELECTED = Color( 39, 50, 115, 255 )
local COLOR_PLAYER_UNSELECTED = Color( 36, 41, 67, 255 )

local ICON_PLAYER_UNSELECTED = "materials/icon16/group_add.png"
local ICON_PLAYER_SELECTED = "materials/icon16/tick.png"

local function createFrame( onSuccess, onCanceled )
    local frame = vgui.Create( "DFrame" )

    frame:SetSize( WIDTH, HEIGHT )
    frame:Center()
    frame:MakePopup()
    frame:SetTitle( "Invite Players" )
    frame.OnClose = failed

    frame.InvitedGuests = {}
    frame.InvitedGuestsCount = 0

    function frame:GuestsUpdated()
    end

    function frame:AddGuest( guest )
        self.InvitedGuests[guest] = true
        self.InvitedGuestsCount = self.InvitedGuestsCount + 1
        self:GuestsUpdated()
    end

    function frame:RemoveGuest( guest )
        self.InvitedGuests[guest] = nil
        self.InvitedGuestsCount = self.InvitedGuestsCount - 1
        self:GuestsUpdated()
    end

    function frame:OnSubmit()
        onSuccess( table.GetKeys( self.InvitedGuests ) )
    end

    return frame
end

-- Controls
local function createCounter( parent, frame )
    local counter = vgui.Create( "DLabel", parent )

    local width = WIDTH / 2
    local height = 75
    counter:SetSize( width, height )

    counter:Dock( LEFT )
    counter:SetFont( "DermaLarge" )
    counter:SetText( "Selected: 0" )

    function frame.GuestsUpdated()
        counter:SetText( "Selected: " .. self.InvitedGuestsCount )
    end

    return counter
end

local function createSubmitButton( parent, submitCallback )
    local submitButton = vgui.Create( "DButton", parent )
    local width = WIDTH * 0.3
    submitButton:SetSize( width, 75 )

    submitButton.OutlineColor = COLOR_WHITE
    submitButton:SetTextColor( COLOR_WHITE )
    submitButton.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, COLOR_INVIS )

        surface.SetDrawColor( self.OutlineColor:Unpack() )
        surface.DrawOutlinedRect( 0, 0, w, h )
    end

    submitButton:Dock( RIGHT )
    submitButton:SetFont( "Trebuchet24" )
    submitButton:SetText( "Submit" )
    submitButton.OnCursorEntered = function( self )
        self.OutlineColor = COLOR_BUTTON_HOVERED
        self:SetTextColor( COLOR_BUTTON_HOVERED )
    end

    submitButton.OnCursorExited = function( self )
        self.OutlineColor = COLOR_WHITE
        self:SetTextColor( COLOR_WHITE )
    end

    submitButton.DoClick = submitCallback
end

local function createControlSection( frame )
    local control = vgui.Create( "DPanel", frame )
    control:SetSize( WIDTH, 75 )
    control:Dock( BOTTOM )
    control:DockPadding( 8, 8, 8, 8 )
    control:SetBackgroundColor( COLOR_CFC_DARK )

    createCounter( control, frame )
    createSubmitButton( control, function()
        frame:OnSubmit()
    end )
end

-- Player Row
local function createPlayerButton( row, ply, addGuest, removeGuest )
    local selectButton = vgui.Create( "DImageButton", row )
    selectButton:SetSize( 30, 30 )
    selectButton:SetIcon( ICON_PLAYER_UNSELECTED )
    selectButton:Dock( RIGHT )
    selectButton:DockMargin( 5, 5, 15, 5 )
    selectButton:SetKeepAspect( true )
    selectButton:SetStretchToFit( true )

    function selectButton.DoClick()
        local isSelected = not row.IsSelected
        row.IsSelected = isSelected

        if isSelected then addGuest( ply ) else removeGuest( ply ) end
        self:SetIcon( isSelected and ICON_PLAYER_SELECTED or ICON_PLAYER_UNSELECTED )
        row:ColorTo( isSelected and COLOR_PLAYER_SELECTED or COLOR_PLAYER_UNSELECTED, 0.2, 0.05 )
    end
end

local function createPlayerName( row, ply )
    local name = vgui.Create( "DLabel", row )
    name:SetColor( team.GetColor( ply:Team() ) )
    name:SetText( ply:Nick() )
    name:SetFont( "DermaLarge" )
    name:SizeToContents()
    name:Dock( LEFT )
    name:Center()
end

local function createPlayerRow( parent, ply, addGuest, removeGuest )
    local row = vgui.Create( "DPanel", parent )
    row:SetSize( WIDTH, 40 )
    row:SetBackgroundColor( COLOR_PLAYER_UNSELECTED )
    row:DockMargin( 0, 1, 0, 1 )
    row:DockPadding( 8, 0, 0, 0 )
    row.SetColor = row.SetBackgroundColor
    row.GetColor = row.GetBackgroundColor
    row:Dock( TOP )
    row.IsSelected = false

    createPlayerButton( row, ply, addGuest, removeGuest )
    createPlayerName( row, ply )
end

local function createPlayerScroller( frame )
    local panel = vgui.Create( "DScrollPanel", frame )
    panel:Dock( FILL )

    local function addGuest( ply )
        frame:AddGuest( ply )
    end

    local function removeGuest( ply )
        frame:RemoveGuest( ply )
    end

    for id, teamObj in pairs( team.GetAllTeams() ) do
        local col = teamObj.Color
        local plys = team.GetPlayers( id )

        for _, ply in ipairs( plys ) do
            createPlayerRow( panel, ply, addGuest, removeGuest )
        end
    end
end

-- Entrypoint
function CFCServerInvite:Prompt( onSuccess, onCanceled )
    local frame = createFrame( onSuccess, onCanceled )
    createControlSection( frame )
    createPlayerScroller( frame )
end
