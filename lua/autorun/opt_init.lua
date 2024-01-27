SOptimization = SOptimization or {} -- shockpast. Optimization. (awful naming)

local color_cornflower = Color(84, 109, 229)
local color_gray = Color(210, 218, 226)

function SOptimization.Log(...)
  MsgC(color_cornflower, "[#] ", color_gray, ..., "\n")
end

if SERVER then
  AddCSLuaFile("optimization/cl_optimization.lua")
end

if CLIENT then
  include("optimization/cl_optimization.lua")
end