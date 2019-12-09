WeldOptimiser = WeldOptimiser or {}
WeldOptimiser.Config = {}

local config = WeldOptimiser.Config

-- How long should a user need to wait between optimisations
config.Cooldown = 10

-- Should this be rank restricted?
config.RankCheck = false

-- Which ranks should be allowed to use this?
config.AllowedUsergroups = {
    ["superadmin"] = true,
    ["admin"] = true,
    ["user"] = true,
}

config.WeldClasses = {
    ["prop_physics"] = true,
}

-----------------------------------------------------------------
-- Addon Code, do not touch unless you know what you are doing!
-----------------------------------------------------------------

WeldOptimiser.PlayerCooldowns = {}

function WeldOptimiser:CanWeld(ply)

    if config.RankCheck and not config.AllowedUsergroups[ply:GetUserGroup()] then
        return false, "Insufficient access rights"
    end

    local lastWeldedTime = (self.PlayerCooldowns[ply:SteamID()] or 0)
    local cooldownRemaining = (lastWeldedTime + config.Cooldown) - RealTime()

    if cooldownRemaining > 0 then
        return false, string.format("Cooldown time remaining: %i seconds", cooldownRemaining)
    end

    return true
end

function WeldOptimiser:BeginCooldown(ply)
    self.PlayerCooldowns[ply:SteamID()] = RealTime()
end

hook.Add("PlayerDisconnected", "WeldOptimiser_Shared_Cleanup", function(ply)
    WeldOptimiser[ply:SteamID()] = nil
end)