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

function LDtkManager:load(levelWidth, levelHeight)
    local file = assert(io.open(self.filePath, "r"))
    local content = file:read("*all")
    file:close()

    local ok, parsed = pcall(function() return json.decode(content) end)
    if not ok then error("Failed to parse LDtk: " .. tostring(parsed)) end

    self.data = parsed
    self.levelWidth = levelWidth
    self.levelHeight = levelHeight
    for _, level in ipairs(parsed.levels) do
        self.levels[level.identifier] = level
    end

    return true
end

function LDtkManager:getLevel(id)
    return self.levels[id]
end

function LDtkManager:getGridSize()
    return self.data.defaultGridSize or 8
end

function LDtkManager:getLevelPixelSize(id)
    local level = self:getLevel(id)
    if not level then
        print("[LDtkManager] WARNING: Level not found:", id)
        return 0, 0
    end

    if not level.pxWid or not level.pxHei or size <= 0 then
        print("[LDtkManager] WARNING: Invalid level dimensions or grid size:", 
            level.pxWid, level.pxHei)
        return 0, 0
    end

    local width = level.pxWid
    local height = level.pxHei
    print("[LDtkManager] Level pixel size for", id, ":", width, height, 
        "(grid:", level.pxWid, level.pxHei, " of size:", ")")
    return width, height
end

function LDtkManager:getLevelGridSize(id)
    local level = self:getLevel(id)
    if not level then
        print("[LDtkManager] WARNING: Level not found:", id)
        return 0, 0
    end

    -- Make sure we have valid grid size and dimensions
    local size = self:getGridSize()
    if not level.pxWid or not level.pxHei or size <= 0 then
        print("[LDtkManager] WARNING: Invalid level dimensions or grid size:", 
            level.pxWid, level.pxHei, size)
        return 0, 0
    end

    if not level.gWid or not level.gHei then
        local width = level.pxWid
        local height = level.pxHei
        level.gWid = math.floor(width/size)
        level.gHei = math.floor(height/size)
        print("[LDtkManager] Level pixel size for", id, ":", width, height, 
            "(grid:", level.gWid, level.gHei, " of size:", size, ")")
    end
    return level.gWid, level.gHei
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

