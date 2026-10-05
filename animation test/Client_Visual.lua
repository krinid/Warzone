require ('Utilities')

function getColours ()
	local colours = {}; -- Stores all the built-in colours (player colours only)
	colours.Blue = "#0000FF"; colours.Purple = "#59009D"; colours.Orange = "#FF7D00"; colours["Dark Gray"] = "#606060"; colours["Hot Pink"] = "#FF697A"; colours["Sea Green"] = "#00FF8C"; colours.Teal = "#009B9D"; colours["Dark Magenta"] = "#AC0059"; colours.Yellow = "#FFFF00"; colours.Ivory = "#FEFF9B"; colours["Electric Purple"] = "#B70AFF"; colours["Deep Pink"] = "#FF00B1"; colours.Aqua = "#4EFFFF"; colours["Dark Green"] = "#008000"; colours.Red = "#FF0000"; colours.Green = "#00FF05"; colours["Saddle Brown"] = "#94652E"; colours["Orange Red"] = "#FF4700"; colours["Light Blue"] = "#23A0FF"; colours.Orchid = "#FF87FF"; colours.Brown = "#943E3E"; colours["Copper Rose"] = "#AD7E7E"; colours.Tan = "#FFAF56"; colours.Lime = "#8EBE57"; colours["Tyrian Purple"] = "#990024"; colours["Mardi Gras"] = "#880085"; colours["Royal Blue"] = "#4169E1"; colours["Wild Strawberry"] = "#FF43A4"; colours["Smoky Black"] = "#100C08"; colours.Goldenrod = "#DAA520"; colours.Cyan = "#00FFFF"; colours.Artichoke = "#8F9779"; colours["Rain Forest"] = "#00755E"; colours.Peach = "#FFE5B4"; colours["Apple Green"] = "#8DB600"; colours.Viridian = "#40826D"; colours.Mahogany = "#C04000"; colours["Pink Lace"] = "#FFDDF4"; colours.Bronze = "#CD7F32"; colours["Wood Brown"] = "#C19A6B"; colours.Tuscany = "#C09999"; colours["Acid Green"] = "#B0BF1A"; colours.Amazon = "#3B7A57"; colours["Army Green"] = "#4B5320"; colours["Donkey Brown"] = "#664C28"; colours.Cordovan = "#893F45"; colours.Cinnamon = "#D2691E"; colours.Charcoal = "#36454F"; colours.Fuchsia = "#FF00FF"; colours["Screamin' Green"] = "#76FF7A"; colours.TextColour = "#DDDDDD"; colours.TextColor = "#DDDDDD";
	colours.WZyellow = "#ABA500"; colours.WZgreen = "#198225"; colours["WZLight Blue"] = "#50B2E3"; colours.WZblue = "#242D9A"; colours.WZred = "#9A2929";
	return colours;
end

-- ============================================================
-- CLOUD VISUAL (FLAT BOTTOM, GROWING UPWARD, COLOR SHIFT)
-- ============================================================

function buildCloudVertices(t)
    -- t = 0 → small cloud
    -- t = 1 → large cloud

    local h = 10 + 40 * t      -- cloud height (negative Y = upward)
    local w = 20 + 10 * t      -- cloud width grows slightly

    return {
        -- Flat bottom (y = 0)
        { -w, 0 },             -- [1] bottom left
        { -w*0.5, 0 },         -- [2] bottom mid-left
        {  w*0.5, 0 },         -- [3] bottom mid-right
        {  w, 0 },             -- [4] bottom right

        -- Rounded top (negative Y = upward)
        { -w*0.6, -h*0.6 },    -- [5] upper left
        {  0,     -h },        -- [6] top center
        {  w*0.6, -h*0.6 },    -- [7] upper right
    }
end

function buildCloudTriangles()
    -- Arbitrary triangulation (overlapping allowed)
    return {
        1,2,5,
        2,3,6,
        3,4,7,
        2,5,6,
        3,6,7,
        5,6,7
    }
end

function cloudColor(t)
    -- Off-white → yellow → orange → dark grey
    local colors = {
        {240,240,220},   -- off-white
        {255,230,80},    -- yellow
        {255,140,40},    -- orange
        {60,60,60},      -- dark grey
    }

    -- pick color based on t
    local idx
    if t <= 0.33 then idx = 1
    elseif t <= 0.66 then idx = 2
    elseif t <= 0.90 then idx = 3
    else idx = 4
    end

    local c = colors[idx]
    return string.format("#%02X%02X%02X", c[1], c[2], c[3])
end

function buildCloudColors(vertexCount, t)
    local col = cloudColor(t)
    local list = {}
    for i = 1, vertexCount do
        list[i] = col
    end
    return list
end

function buildCloudFrames()
    local frames = {}
    local triangles = buildCloudTriangles()
    local vertexCount = 7

    local keyTimes = {0.0, 0.33, 0.66, 1.0}

    for _, t in ipairs(keyTimes) do
        local verts = buildCloudVertices(t)
        local colors = buildCloudColors(vertexCount, t)

        table.insert(frames, {
            t = t,
            Vertices = verts,
            Colors = colors
        })
    end

    return frames, triangles
end

function Client_Visual(game, order, visual)
    local terr
    for _, v in pairs(game.Map.Territories) do
        terr = v
        break
    end

    local frames, triangles = buildCloudFrames()

    visual
        .SetAnchorPoint(terr.MiddlePointX, terr.MiddlePointY + 10)
        .SetTriangles(triangles)
        .SetFrames(frames)
        .SetDuration(1500)
end

function bluePentagon ()
-- ============================================================
-- ARROW VISUAL (UPWARD, ELONGATING, BLUE → LIGHT BLUE)
-- ============================================================

function buildArrowVertices(t)
    local h = 5 + 20 * t
    local w = 4
    local tipW = 10

    return {
        { 0, 0 },            -- [1] center
        { 0,  -h },          -- [2] tip (TOP, negative Y = upward)
        {  tipW, -h*0.6 },   -- [3] right mid
        {  w,    0 },        -- [4] bottom right
        { -w,    0 },        -- [5] bottom left
        { -tipW, -h*0.6 },   -- [6] left mid
    }
end

function buildArrowTriangles(vertexCount)
    local tris = {}
    local center = 1

    for i = 2, vertexCount do
        local i2 = (i < vertexCount) and (i + 1) or 2
        table.insert(tris, center)
        table.insert(tris, i)
        table.insert(tris, i2)
    end

    return tris
end

function lerpColor(t)
    local r = math.floor(20   + 100 * t)
    local g = math.floor(40   + 140 * t)
    local b = math.floor(160  +  80 * t)
    return string.format("#%02X%02X%02X", r, g, b)
end

function buildColors(vertexCount, t)
    local c = {}
    local col = lerpColor(t)
    for i = 1, vertexCount do
        c[i] = col
    end
    return c
end

function buildArrowFrames()
    local frames = {}
    local vertexCount = 6
    local triangles = buildArrowTriangles(vertexCount)

    local keyTimes = {0.0, 0.25, 0.5, 0.75, 1.0}

    for _, t in ipairs(keyTimes) do
        local verts = buildArrowVertices(t)
        local colors = buildColors(vertexCount, t)

        table.insert(frames, {
            t = t,
            Vertices = verts,
            Colors = colors
        })
    end

    return frames, triangles
end

function Client_Visual(game, order, visual)
    local terr
    for _, v in pairs(game.Map.Territories) do
        terr = v
        break
    end

    local frames, triangles = buildArrowFrames()

    visual
        .SetAnchorPoint(terr.MiddlePointX, terr.MiddlePointY + 10)
        .SetTriangles(triangles)
        .SetFrames(frames)
        .SetDuration(1200)
end
end