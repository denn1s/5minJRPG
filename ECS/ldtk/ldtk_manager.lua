-- ECS/ldtk/ldtk_manager.lua (singleton)

local json = require("libs.json")

---@class LDtkManager
---@field filePath string
---@field data table
---@field levels table<string, table>
---@field fileDirectory string
local LDtkManager = {}
local instance = nil

function LDtkManager.new(filePath)
    if instance then
        error("LDtkManager already initialized.")
    end

    local dir = filePath:match("(.*[/\\])") or ""
    instance = {
        filePath = filePath,
        data = nil,
        levels = {},
        fileDirectory = dir
    }

    setmetatable(instance, { __index = LDtkManager })
    return instance
end

function LDtkManager.getInstance()
    if not instance then
        error("LDtkManager has not been initialized.")
    end
    return instance
end

function LDtkManager:load()
    local file = assert(io.open(self.filePath, "r"))
    local content = file:read("*all")
    file:close()

    local ok, parsed = pcall(function() return json.decode(content) end)
    if not ok then error("Failed to parse LDtk: " .. tostring(parsed)) end

    self.data = parsed
    for _, level in ipairs(parsed.levels) do
        self.levels[level.identifier] = level
    end

    return true
end

function LDtkManager:getLevel(id)
    return self.levels[id]
end

function LDtkManager:getGridSize()
    return self.data.defaultGridSize or 16
end

function LDtkManager:getLevelPixelSize(id)
    local level = self:getLevel(id)
    if not level then return 0, 0 end
    local size = self:getGridSize()
    return level.__cWid * size, level.__cHei * size
end

function LDtkManager:getTilesetTexturePath(layer)
    if not layer.__tilesetRelPath then return nil end
    return self:resolvePath(layer.__tilesetRelPath)
end

function LDtkManager:resolvePath(relativePath)
    return self.fileDirectory .. relativePath
end

function LDtkManager:getAllTilesetPaths()
    local paths = {}
    local seen = {}

    for _, level in pairs(self.levels) do
        if level.layerInstances then
            for _, layer in ipairs(level.layerInstances) do
                if layer.__type == "Tiles" and layer.__tilesetRelPath then
                    local fullPath = self:resolvePath(layer.__tilesetRelPath)
                    if not seen[fullPath] then
                        seen[fullPath] = true
                        table.insert(paths, fullPath)
                    end
                end
            end
        end
    end

    return paths
end

return LDtkManager

