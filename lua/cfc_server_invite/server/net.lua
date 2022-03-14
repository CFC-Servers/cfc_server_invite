local IsValid = IsValid
local rawget = rawget

-- TODO: Split this out into multiple files with specific responsibilities

-- Server -> Client: "Tell me who you want to invite"
-- Client -> Server: "This are the players I want to invite"
util.AddNetworkString( "CFC_ULXCommands_InviteSetup" )


-- TODO: Figure out these two network messages
--
-- Server -> Inviter: "This player responded to your invite"
-- Server -> Guest: "This player invited you to join a server"
-- Guest -> Server: "This is my response to that player's invite"

util.AddNetworkString( "CFC_ULXCommands_InviteResponse" )
util.AddNetworkString( "CFC_ULXCommands_ServerInvite" )


local inviteTimeout = CFCServerInvite.inviteTimeout

-- Waiting for these players to tell us who to invite
CFCServerInvite.pendingInviteData = {}
local pendingInviteData = CFCServerInvite.pendingInviteData

-- Waiting for these players to respond to an invite
CFCServerInvite.pendingInviteResponses = {}
local pendingInviteResponses = CFCServerInvite.pendingInviteResponses

-- TODO: Make this a more formal structure
-- These are the players' responses to a given player's invite
-- i.e. { [inviter] = { [guest1] = true, [guest2] = false, [guest3] = false } }
CFCServerInvite.inviteResponses = {}
local inviteResponses = CFCServerInvite.inviteResponses

-- Player told us who we need to invite
net.Receive( "CFC_ULXCommands_InviteSetup", function( _, inviter )
    -- TODO: Make sure the player has access to the command

    -- If the inviter somehow already has an invite out, don't start another
    if inviteResponses[inviter] then return end
    if not pendingInviteData[inviter] then return end
    pendingInviteData[inviter] = nil

    local invited = net.ReadTable()
    local invitedCount = #invitedGuests

    if invitedCount > game.MaxPlayers() then
        error( "Received too many players in an invite response!: " .. invitedCount )
    end

    for i = 1, invitedCount do
        local ply = rawget( invited, i )

        if IsValid( ply ) then
            if not ply.IsPlayer and ply:IsPlayer() then
                error( "Tried to invite a not-player! (From: " .. tostring( inviter ) .. ") (Not-player: " .. tostring( ply ) .. " )" )
            end

            pendingInviteResponses[ply] = inviter
        end
    end

    net.Start( "CFC_ULXCommands_ServerInvite" )
    net.WriteEntity( inviter )
    net.Send( invited )

    timer.Create( "CFC_ULXCommands_InviteTimeout_" .. inviter:SteamID64(), inviteTimeout, 1, function()
        -- TODO: Check for any missing responses, assume they're "no thanks"
        -- Then run final "invite complete" code
    end )
end )

-- Player told us whether or not they accepted the invite
net.Receive( "CFC_ULXCommands_ServerInvite", function( _, ply )
    if not pendingInviteResponses[ply] then return end
    pendingInviteResponse[ply] = nil

    local inviter = net.ReadEntity()
    local response = net.ReadBool()

    local inviteGroup = inviteResponses[inviter]
    if not inviteGroup then
        local info = "( Player: " .. tostring( ply ) .. " | " .. "Inviter: " .. tostring( inviter ) .. " )"
        error( "Player responded to a not-existing invite!: " .. info )
    end

    inviteGroup[ply] = response
    -- TODO: Check if this was all of the expected responses
    -- If so, run final "invite complete" code
end )

local function inviteComplete()
    -- TODO:
    -- Alert all invited players (and inviter) that they'll be prompted to join the new server in X seconds
    -- Clients run timer, all prompt at the same time
    -- Server runs timer, clears out all invite data
end
