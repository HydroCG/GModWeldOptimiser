WeldOptimiser = WeldOptimiser or {}

local STATUS_RETRIEVE_ENTITIES = 1
local STATUS_DESTROY_WELDS     = 2
local STATUS_REWELD_ENTITIES   = 3

local activeOptimisations = {}

local function DebugPrint(msg)
    print(msg)
end

local function GetEntitiesOwnedByPlayer(ply)
    local playerOwnedEntities = {}

    local allowedWeldClasses = WeldOptimiser.Config.WeldClasses

    for index, ent in pairs(ents.GetAll()) do
        local class = ent:GetClass()

        if not allowedWeldClasses[class] or
           not ent.CPPIGetOwner or
           ent:CPPIGetOwner() ~= ply then

            continue
        end
        
        table.insert(playerOwnedEntities, ent)
    end

    return playerOwnedEntities
end

local function OptimiseWeld(process)
    
    local status = process.status
    local processPly = process.ply

    if not IsValid(processPly) then
        return true
    end

    if status == STATUS_RETRIEVE_ENTITIES then
        process.entities = GetEntitiesOwnedByPlayer(process.ply)
        process.status = STATUS_DESTROY_WELDS

        processPly:PrintMessage(HUD_PRINTTALK, "[OptimisedWeld] Removing existing weld constraints")
        
        return false
    end

    local entities = process.entities
    local entityCount = #entities
    local entityId = process.entityId or 1
    
    if status == STATUS_DESTROY_WELDS then
        
        if entityId <= entityCount then
            local currentEnt = entities[entityId]
            
            if IsValid(currentEnt) then
                constraint.RemoveConstraints(entities[entityId], "Weld")
                DebugPrint(string.format("Destroying: %i / %i", entityId, entityCount))
            end

            process.entityId = entityId + 1
        else
            process.status = STATUS_REWELD_ENTITIES

            process.entityId = 1
            processPly:PrintMessage(HUD_PRINTTALK, "[OptimisedWeld] Re-welding entities")
        end

        return false
    end

    if status == STATUS_REWELD_ENTITIES then
        if entityId <= entityCount then

            local baseEnt = process.originEnt
            local targetEnt = entities[entityId]

            if IsValid(baseEnt) and IsValid(targetEnt) and baseEnt != targetEnt then
                constraint.Weld(baseEnt, targetEnt, 0, 0, 0, false, false)
                DebugPrint(string.format("Welding: %i / %i", entityId, entityCount))
            end
            
            process.entityId = entityId + 1
        else
            processPly:PrintMessage(HUD_PRINTTALK, "[OptimisedWeld] Finished")
            return true
        end
    end
end

local function OptimiseTick()

    local deadProcesses = {}

    for k,process in pairs(activeOptimisations) do
        if OptimiseWeld(process) then
            table.insert(deadProcesses, process)
        end
    end

    -- Remove dead processes from the active list as they're finished
    for k,v in pairs(deadProcesses) do
        table.RemoveByValue(activeOptimisations, v)
    end
end

function WeldOptimiser:StartOptimising(ply, originEnt)

    if not originEnt.CPPIGetOwner or
           originEnt:CPPIGetOwner() ~= ply then
        ply:PrintMessage(HUD_PRINTTALK, "The selected origin entity is not owned by you.")

        return false
    end

    local canWeld, errorMessage = WeldOptimiser:CanWeld(ply)

    if not canWeld then
        -- Quick and dirty error reporting to tell the player why they can't perform the operation
        ply:PrintMessage(HUD_PRINTTALK, string.format("Error: %s", errorMessage))
        return
    end

    table.insert(activeOptimisations, {
        ["originEnt"] = originEnt,
        ["ply"] = ply,
        ["status"] = STATUS_RETRIEVE_ENTITIES,
    })

    WeldOptimiser:BeginCooldown(ply)
end

timer.Remove("Weld_Optimisation")
timer.Create("Weld_Optimisation", 0.01, 0, OptimiseTick)