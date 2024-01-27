local commands = {
  ["Render"] = {
    ["r_threaded_client_shadow_manager"] = 1,
    ["r_threaded_particles"] = 1,
    ["r_queued_ropes"] = 1,
    ["r_threaded_renderables"] = 1,
    ["r_fastzreject"] = 1,
    ["r_norefresh"] = 1,
    ["r_glint_procedural"] = 1,
    ["mod_load_vcollide_async"] = 1, -- asynchronous load of "vcollide"
    ["mod_load_anims_async"] = 1,
    ["mod_load_mesh_async"] = 1,
    ["mat_forcemanagedtextureintohardware"] = 1, -- allocates textures into GPU's VRAM
    ["mat_managedtextures"] = 1,
    ["mat_bufferprimitives"] = 1,
    -- -1=default, 0=synchronous single thread, 2=queued multithreaded
    ["mat_queue_mode"] = 2, -- use 1, when game eats too much GPU
  },
  ["Threading"] = {
    ["gmod_mcore_test"] = 1,
    ["cl_threaded_client_leaf_system"] = 1,
    ["studio_queue_mode"] = 1,
  },
  ["Filesystem"] = {
    ["filesystem_max_stdio_read"] = 64 * 1.5,
    ["mem_min_heapsize"] = 48 * 2,
    ["mem_max_heapsize"] = 256 * 1.5
  },
  ["Sound"] = {
    ["snd_async_fullyasync"] = 1,
    ["snd_noextraupdate"] = 1
  }
}

local hooks = {
  ["RenderScreenspaceEffects"] = {
    "RenderColorModify", "RenderBloom", "RenderToyTown",
    "RenderTexturize", "RenderSunbeams", "RenderSobel",
    "RenderSharpen", "RenderMaterialOverlay", "RenderMotionBlur",
    "RenderBokeh"
  },
  ["RenderScene"] = {
    "RenderStereoscopy", "RenderSuperDoF"
  },
  ["Think"] = {
    "DOFThink", "RenderHalos",
  },
  ["PreRender"] = { "PreRenderFrameBlend" },
  ["PostRender"] = { "RenderFrameBlend" },
  ["PostDrawEffects"] = { "RenderWidgets" },
  ["OnEntityCreated"] = { "WidgetInit" },
  ["PlayerTick"] = { "TickWidgets" },
  ["LoadGModSave"] = { "LoadGModSave" }
}

hook.Add("InitPostEntity", "optimization:client[commands]", function()
  for categoryName, categoryCommands in pairs(commands) do
    SOptimization.Log("Executing '" .. categoryName .. "' with " .. table.Count(categoryCommands) .. " commands.")

    for commandName, commandValue in pairs(categoryCommands) do
      RunConsoleCommand(commandName, commandValue)
    end
  end

  hook.Remove("PreGamemodeLoaded", "optimization:client[commands]")
end)

hook.Add("InitPostEntity", "optimization:client[unnecessary_hooks]", function()
  for eventName, identifier in pairs(hooks) do
    hook.Remove(eventName, identifier)
  end

  hook.Remove("InitPostEntity", "optimization:client[unnecessary_hooks]")
end)

local delay = UnPredictedCurTime() + 60

hook.Add("Think", "optimization:client[junk_cleanup]", function()
  if UnPredictedCurTime() <= delay then return end

  RunConsoleCommand("r_cleardecals")

  ---@param ent Entity
  for _, ent in ipairs(ents.FindByClass("class C_ClientRagdoll")) do
    if IsValid(ent) == nil then goto skip end

    SafeRemoveEntity(ent)

    ::skip::
  end

  ---@param ent Entity
  for _, ent in ipairs(ents.FindByClass("class C_PhysPropClientside")) do
    if IsValid(ent) == nil then goto skip end

    SafeRemoveEntity(ent)

    ::skip::
  end

  delay = UnPredictedCurTime() + 60
end)

local eyeFov = 71
local eyePos = Vector()
local eyeAngles = Angle()
local eyeVector = Vector()

hook.Add("RenderScene", "optimization:client[cache_view]", function(origin, angles, fov)
  eyeFov = fov
  eyePos = origin
  eyeAngles = angles
  eyeVector = angles:Forward()
end)

local entityMeta = FindMetaTable("Entity")

function entityMeta:IsVisible()
  local pos = self:GetPos()
  return self == LocalPlayer() and (eyeVector:Dot(pos - eyePos) > 1.5 or pos:DistToSqr(eyePos) < 3000000)
end

function entityMeta:IsInRange()
  local pos = self:GetPos()
  return pos:DistToSqr(eyePos) < 3000000
end

hook.Add("InitPostEntity", "optimization:client[gm_fixes]", function()
  local GM = GAMEMODE

  local CalcMainActivity = GM.CalcMainActivity
  function GM:CalcMainActivity(ply, ...)
    if not ply:IsVisible() then
      return ply.CalcIdeal, ply.CalcSeqOverride
    end

    return CalcMainActivity(self, ply, ...)
  end

  local UpdateAnimation = GM.UpdateAnimation
  function GM:UpdateAnimation(ply, ...)
    if not ply:IsVisible() then return end

    return UpdateAnimation(self, ply, ...)
  end

  local PrePlayerDraw = GM.PrePlayerDraw
  function GM:PrePlayerDraw(ply, ...)
    if not ply:IsVisible() then
      return true
    end

    return PrePlayerDraw(self, ply, ...)
  end

  local DoAnimationEvent = GM.DoAnimationEvent
  function GM:DoAnimationEvent(ply, ...)
    if not ply:IsVisible() then
      return ply.CalcIdeal
    end

    return DoAnimationEvent(self, ply, ...)
  end

  local PlayerFootstep = GM.PlayerFootstep
  function GM:PlayerFootstep(ply, ...)
    if not ply:IsInRange() then
      return true
    end

    PlayerFootstep(self, ply, ...)
  end

  local PlayerStepSoundTime = GM.PlayerStepSoundTime
  function GM:PlayerStepSoundTime(ply, ...)
    if not ply:IsInRange() then
      return 350
    end

    return PlayerStepSoundTime(self, ply, ...)
  end

  local TranslateActivity = GM.TranslateActivity
  function GM:TranslateActivity(ply, ...)
    if not ply:IsVisible() then
      return ACT_HL2MP_IDLE
    end

    return TranslateActivity(self, ply, ...)
  end

  hook.Remove("PostGamemodeLoaded", "optimization:client[gm_fixes]")
end)

hook.Add("InitPostEntity", "optimization:client[detour_render]", function()
  render.SupportsHDR = function() return false end
  render.SupportsPixelShaders_1_4 = function() return false end
  render.SupportsPixelShaders_2_0 = function() return false end
  render.SupportsVertexShaders_2_0 = function() return false end
end)

EyeFov = function() return eyeFov end
EyePos = function() return eyePos end
EyeAngles = function() return eyeAngles end
EyeVector = function() return eyeVector end