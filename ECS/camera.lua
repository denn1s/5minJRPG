-- ECS/camera.lua
-- Camera system for the ECS
local StaticWorldManager = require("ECS.world_manager")

---@class Camera
---@field x number X position in world coordinates (top-left corner of viewport)
---@field y number Y position in world coordinates (top-left corner of viewport)
---@field width number Width of the viewport
---@field height number Height of the viewport
local Camera = {}
Camera.__index = Camera

---@param width number Width of the viewport (usually SCREEN_WIDTH)
---@param height number Height of the viewport (usually SCREEN_HEIGHT)
---@param x? number Initial X position (defaults to 0)
---@param y? number Initial Y position (defaults to 0)
---@return Camera
function Camera.new(width, height, x, y)
    local camera = {
        x = x or 0,
        y = y or 0,
        width = width,
        height = height
    }
    setmetatable(camera, Camera)
    return camera
end

-- Set the camera position
---@param x number
---@param y number
---@return Camera
function Camera:setPosition(x, y)
    print("[Camera] Setting position:", x, y)
    local originalX = self.x
    local originalY = self.y

    self.x = self:clampX(x)
    self.y = self:clampY(y)

    print("[Camera] Position after clamping:", self.x, self.y)
    if originalX ~= self.x or originalY ~= self.y then
        print("[Camera] WARNING: Position was clamped")
    end

    return self
end

-- Constrain the camera within world bounds (x-axis)
---@param x number
---@return number
function Camera:clampX(x)
    local WorldManager = StaticWorldManager.getInstance()
    local world = WorldManager:getActiveWorld()

    if not world then 
        print("[Camera] WARNING: No active world for clampX, returning raw value:", x)
        return x 
    end

    print("[Camera] clampX - world width:", world.pixelWidth, "camera width:", self.width)

    -- Check for invalid world dimensions
    if world.pixelWidth <= 0 then
        print("[Camera] WARNING: World has invalid width:", world.pixelWidth, 
            "- not clamping camera position")
        return x
    end

    if x < 0 then
        print("[Camera] clampX - clamping to 0 (min)")
        return 0
    elseif x > world.pixelWidth - self.width then
        local maxX = math.max(0, world.pixelWidth - self.width)
        print("[Camera] clampX - clamping to maxX:", maxX)
        return maxX
    end
    return x
end

-- Constrain the camera within world bounds (y-axis)
---@param y number
---@return number
function Camera:clampY(y)
    local WorldManager = StaticWorldManager.getInstance()
    local world = WorldManager:getActiveWorld()

    if not world then 
        print("[Camera] WARNING: No active world for clampY, returning raw value:", y)
        return y
    end

    print("[Camera] clampY - world height:", world.pixelHeight, "camera width:", self.height)

    -- Check for invalid world dimensions
    if world.pixelHeight <= 0 then
        print("[Camera] WARNING: World has invalid height:", world.pixelHeight, 
            "- not clamping camera position")
        return y
    end

    if y < 0 then
        print("[Camera] clampY - clamping to 0 (min)")
        return 0
    elseif y > world.pixelHeight - self.height then
        local maxY = math.max(0, world.pixelHeight - self.height)
        print("[Camera] clampY - clamping to maxY:", maxY)
        return maxY
    end
    return x
end

-- Move the camera by a delta amount
---@param dx number
---@param dy number
---@return Camera
function Camera:move(dx, dy)
    return self:setPosition(self.x + dx, self.y + dy)
end

-- Center the camera on a position
---@param x number
---@param y number
---@return Camera
function Camera:centerOn(x, y)
    return self:setPosition(
        x - self.width / 2,
        y - self.height / 2
    )
end

-- Check if a point is within the camera's view
---@param x number
---@param y number
---@return boolean
function Camera:isPointVisible(x, y)
    return x >= self.x and x <= self.x + self.width and
        y >= self.y and y <= self.y + self.height
end

-- Check if a rectangle is at least partially within the camera's view
---@param x number
---@param y number
---@param width number
---@param height number
---@return boolean
function Camera:isRectVisible(x, y, width, height)
    return x + width >= self.x and x <= self.x + self.width and
        y + height >= self.y and y <= self.y + self.height
end

-- Convert world coordinates to screen coordinates
---@param x number
---@param y number
---@return number, number
function Camera:worldToScreen(x, y)
    return x - self.x, y - self.y
end

-- Convert screen coordinates to world coordinates
---@param x number
---@param y number
---@return number, number
function Camera:screenToWorld(x, y)
    return x + self.x, y + self.y
end

return Camera
