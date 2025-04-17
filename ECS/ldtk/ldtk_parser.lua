-- ECS/ldtk/ldtk_parser.lua
-- Parser for LDtk map files

local json = require("libs.json") -- Assuming you have a JSON parser library

---@class LDtkParser
---@field filePath string Path to the LDtk file
---@field data table Parsed data from the LDtk file
---@field levels table<string, table> Levels indexed by identifier
---@field fileDirectory string Directory containing the LDtk file
local LDtkParser = {}
LDtkParser.__index = LDtkParser

---Create a new LDtk parser
---@param filePath string Path to the LDtk file
---@return LDtkParser
function LDtkParser.new(filePath)
    local parser = {
        filePath = filePath,
        data = nil,
        levels = {},
        fileDirectory = filePath:match("(.*[/\\])") or ""
    }
    setmetatable(parser, LDtkParser)
    
    print("LDtkParser: Created for file: " .. filePath)
    print("LDtkParser: File directory: " .. parser.fileDirectory)
    
    return parser
end

---Load and parse the LDtk file
---@return boolean success True if loaded successfully
function LDtkParser:load()
    local file, errorMsg = io.open(self.filePath, "r")
    if not file then
        print("Failed to open LDtk file: " .. errorMsg)
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Try to parse JSON
    local success, result = pcall(function()
        return json.decode(content)
    end)
    
    if not success then
        print("Failed to parse LDtk JSON: " .. tostring(result))
        return false
    end
    
    self.data = result
    
    -- Index levels by identifier for easier access
    for _, level in ipairs(self.data.levels) do
        self.levels[level.identifier] = level
    end
    
    print("LDtk file loaded successfully: " .. self.filePath)
    return true
end

---Get all level identifiers
---@return string[] Level identifiers
function LDtkParser:getLevelIdentifiers()
    local identifiers = {}
    for _, level in ipairs(self.data.levels) do
        table.insert(identifiers, level.identifier)
    end
    return identifiers
end

---Get a level by its identifier
---@param identifier string Level identifier
---@return table|nil Level data or nil if not found
function LDtkParser:getLevel(identifier)
    return self.levels[identifier]
end

---Print information about all layers in a level
---@param levelIdentifier string Level identifier
function LDtkParser:printLevelLayers(levelIdentifier)
    local level = self:getLevel(levelIdentifier)
    if not level then
        print("Level not found: " .. levelIdentifier)
        return
    end
    
    print("Layers in level " .. levelIdentifier .. ":")
    
    -- Check if layerInstances exists
    if not level.layerInstances then
        print("  No layer instances found in this level")
        return
    end
    
    for _, layer in ipairs(level.layerInstances) do
        local layerType = layer.__type or "Unknown"
        local layerId = layer.__identifier or "Unnamed"
        
        print(string.format("  - %s (%s)", layerId, layerType))
        
        -- Print entity instances if it's an Entities layer
        if layerType == "Entities" and layer.entityInstances then
            print(string.format("    Contains %d entities:", #layer.entityInstances))
            for _, entity in ipairs(layer.entityInstances) do
                print(string.format("      * %s at position (%d, %d)", 
                    entity.__identifier or "Unknown", 
                    entity.px and entity.px[1] or 0, 
                    entity.px and entity.px[2] or 0))
            end
        end
        
        -- Print tiles count if it's a Tiles layer
        if layerType == "Tiles" and layer.gridTiles then
            print(string.format("    Contains %d tiles", #layer.gridTiles))
        end
        
        -- Print IntGrid information if available
        if layerType == "IntGrid" and layer.intGridCsv then
            local nonZeroCount = 0
            for _, val in ipairs(layer.intGridCsv) do
                if val ~= 0 then nonZeroCount = nonZeroCount + 1 end
            end
            print(string.format("    IntGrid: %d cells with non-zero values", nonZeroCount))
        end
    end
end

---Print basic information about the LDtk file
function LDtkParser:printInfo()
    if not self.data then
        print("No data loaded")
        return
    end
    
    print("LDtk file info:")
    print("  Version: " .. (self.data.jsonVersion or "Unknown"))
    print("  Default grid size: " .. (self.data.defaultGridSize or "Unknown"))
    print("  Default background color: " .. (self.data.bgColor or "Unknown"))
    print("  Levels: " .. #self.data.levels)
    
    print("Level identifiers:")
    for _, identifier in ipairs(self:getLevelIdentifiers()) do
        print("  - " .. identifier)
    end
end

---Get tilesets defined in the file
---@return table[] Array of tileset definitions
function LDtkParser:getTilesets()
    if not self.data or not self.data.defs or not self.data.defs.tilesets then
        return {}
    end
    return self.data.defs.tilesets
end

---Get layer definitions from the file
---@return table[] Array of layer definitions
function LDtkParser:getLayerDefs()
    if not self.data or not self.data.defs or not self.data.defs.layers then
        return {}
    end
    return self.data.defs.layers
end

---Get entity definitions from the file
---@return table[] Array of entity definitions
function LDtkParser:getEntityDefs()
    if not self.data or not self.data.defs or not self.data.defs.entities then
        return {}
    end
    return self.data.defs.entities
end

---Resolve a relative path from the LDtk file
---@param relativePath string Path relative to the LDtk file
---@return string Full path
function LDtkParser:resolvePath(relativePath)
    return self.fileDirectory .. relativePath
end

return LDtkParser
