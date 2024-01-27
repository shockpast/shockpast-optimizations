if SERVER then
  AddCSLuaFile("optimization/cl_optimization.lua")
  AddCSLuaFile("optimization/sh_optimization.lua")

  include("optimization/sh_optimization.lua")
end

if CLIENT then
  include("optimization/cl_optimization.lua")
  include("optimization/sh_optimization.lua")
end