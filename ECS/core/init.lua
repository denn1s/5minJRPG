-- ECS/core/init.lua
-- Index file that imports and exports all systems from the ECS/core directory

local Core = {}

-- Import all system modules from this directory
local CameraSystems = require("ECS.core.camera_system")
Core.CameraSetupSystem = CameraSystems.CameraSetupSystem
Core.CameraUpdateSystem = CameraSystems.CameraUpdateSystem
Core.SceneInitSystem = require("ECS.core.scene_init_system")
Core.SpriteRenderSystem = require("ECS.core.sprite_render_system") 
Core.TextureLoadSystem = require("ECS.core.texture_load_system")
Core.TransitionSystem = require("ECS.core.transition_system")
Core.PlayerAnimationSystem = require("ECS.core.player_animation_system")
Core.MovementSystem = require("ECS.core.movement_system")
Core.ColliderRenderSystem = require("ECS.core.collider_render_system")
Core.ColliderSystem = require("ECS.core.collider_system")
Core.GridSyncSystem = require("ECS.core.grid_sync_system")

-- Import LDtk modules
Core.LDtk = require("ECS.ldtk")

-- Return the collected systems
return Core
