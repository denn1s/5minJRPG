-- ECS/renderer.lua
-- Renderer interface for the ECS

local Transition = require("ECS.transition")
local Renderer = {}
Renderer.__index = Renderer

-- Gameboy color palette (in grayscale)
Renderer.COLORS = {
    {15/255, 56/255, 15/255},   -- Darkest (Black)
    {48/255, 98/255, 48/255},   -- Dark Gray
    {139/255, 172/255, 15/255}, -- Light Gray
    {155/255, 188/255, 15/255}  -- Lightest (White)
}

function Renderer.new(width, height, scale)
    local renderer = {
        width = width,
        height = height,
        scale = scale or 1,
        canvas = love.graphics.newCanvas(width, height)
    }
    setmetatable(renderer, Renderer)
    
    -- Set up crisp pixel rendering globally
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Configure the canvas for pixel-perfect rendering
    renderer.canvas:setFilter("nearest", "nearest")
    
    -- Load pixel font
    renderer.pixelFont = love.graphics.newFont("assets/pixelFontSharp.ttf", 8)
    renderer.pixelFont:setFilter("nearest", "nearest")  -- Ensure the font is pixel-perfect too
    
    return renderer
end

function Renderer:begin()
    -- Begin drawing to our canvas
    love.graphics.setCanvas(self.canvas)
    
    -- Set pixel-perfect line style (no anti-aliasing)
    love.graphics.setLineStyle("rough")
    
    -- Clear with the lightest color (Gameboy "white")
    -- Use the fade-adjusted color for the background
    local adjustedColorIndex = Transition:getAdjustedColorIndex(4)
    love.graphics.setColor(self.COLORS[adjustedColorIndex])
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
end

function Renderer:end_drawing()
    -- Reset canvas
    love.graphics.setCanvas()
end

function Renderer:draw_to_screen()
    -- Draw the canvas to the screen with pixel-perfect scaling
    love.graphics.setColor(1, 1, 1)
    
    -- Calculate integer scaling factor for pixel-perfect rendering
    local scaleX = math.floor(love.graphics.getWidth() / self.width)
    local scaleY = math.floor(love.graphics.getHeight() / self.height)
    local scale = math.min(scaleX, scaleY)
    
    -- Center the scaled canvas on screen
    local offsetX = math.floor((love.graphics.getWidth() - (self.width * scale)) / 2)
    local offsetY = math.floor((love.graphics.getHeight() - (self.height * scale)) / 2)
    
    -- Draw with integer scaling for pixel-perfect rendering
    love.graphics.draw(self.canvas, offsetX, offsetY, 0, scale, scale)
end

function Renderer:draw_pixel(x, y, colorIndex)
    -- Apply the fade effect to the color index
    local adjustedColorIndex = Transition:getAdjustedColorIndex(colorIndex or 1)
    love.graphics.setColor(self.COLORS[adjustedColorIndex])
    love.graphics.points(math.floor(x), math.floor(y))
end

function Renderer:draw_rectangle(x, y, width, height, colorIndex, filled)
    -- Apply the fade effect to the color index
    local adjustedColorIndex = Transition:getAdjustedColorIndex(colorIndex or 1)
    love.graphics.setColor(self.COLORS[adjustedColorIndex])
    
    -- Use math.floor to ensure we're drawing at exact pixel positions
    local drawMode = filled and "fill" or "line"
    love.graphics.rectangle(drawMode, math.floor(x), math.floor(y), 
                          math.floor(width), math.floor(height))
end

function Renderer:draw_sprite(sprite, x, y, colorIndex)
    -- Apply the fade effect to the color index
    local adjustedColorIndex = Transition:getAdjustedColorIndex(colorIndex or 1)
    love.graphics.setColor(self.COLORS[adjustedColorIndex])
    
    -- Draw sprite (if it's an array of 0s and 1s)
    if type(sprite) == "table" then
        -- Use points for pixel-perfect drawing (aligns perfectly with pixel grid)
        for sy = 1, #sprite do
            local row = sprite[sy]
            for sx = 1, #row do
                if row[sx] == 1 then
                    -- Use math.floor to ensure we're drawing at exact pixel positions
                    love.graphics.points(math.floor(x + sx - 1), math.floor(y + sy - 1))
                end
            end
        end
    end
end

function Renderer:draw_text(text, x, y, textColorIndex, shadowColorIndex)
    -- Apply the fade effect to the text color index
    local adjustedTextColorIndex = Transition:getAdjustedColorIndex(textColorIndex or 1)
    
    -- Save current font
    local previousFont = love.graphics.getFont()
    
    -- Set our pixel font
    love.graphics.setFont(self.pixelFont)
    
    -- Draw shadow if shadowColorIndex is provided
    if shadowColorIndex then
        local adjustedShadowColorIndex = Transition:getAdjustedColorIndex(shadowColorIndex)
        love.graphics.setColor(self.COLORS[adjustedShadowColorIndex])
        love.graphics.print(text, math.floor(x) + 1, math.floor(y) + 1)
    end
    
    -- Draw main text
    love.graphics.setColor(self.COLORS[adjustedTextColorIndex])
    love.graphics.print(text, math.floor(x), math.floor(y))
    
    -- Restore previous font
    love.graphics.setFont(previousFont)
end

return Renderer
