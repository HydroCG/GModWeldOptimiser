TOOL.Category		= "Constraints"
TOOL.Name			= "Optimised Weld"

function TOOL:LeftClick(trace)
	local traceEntity = trace.Entity
    
    if !IsValid(traceEntity) or traceEntity:IsPlayer() then return end

    if SERVER then
        WeldOptimiser:StartOptimising(self:GetOwner(), traceEntity)
    end

	return true
end

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", { Description = "Welds every prop owned by you together. Left click the prop you want to weld everything to in order to begin." })
end