require ('Utilities')

function getColours ()
	local colours = {}; -- Stores all the built-in colours (player colours only)
	colours.Blue = "#0000FF"; colours.Purple = "#59009D"; colours.Orange = "#FF7D00"; colours["Dark Gray"] = "#606060"; colours["Hot Pink"] = "#FF697A"; colours["Sea Green"] = "#00FF8C"; colours.Teal = "#009B9D"; colours["Dark Magenta"] = "#AC0059"; colours.Yellow = "#FFFF00"; colours.Ivory = "#FEFF9B"; colours["Electric Purple"] = "#B70AFF"; colours["Deep Pink"] = "#FF00B1"; colours.Aqua = "#4EFFFF"; colours["Dark Green"] = "#008000"; colours.Red = "#FF0000"; colours.Green = "#00FF05"; colours["Saddle Brown"] = "#94652E"; colours["Orange Red"] = "#FF4700"; colours["Light Blue"] = "#23A0FF"; colours.Orchid = "#FF87FF"; colours.Brown = "#943E3E"; colours["Copper Rose"] = "#AD7E7E"; colours.Tan = "#FFAF56"; colours.Lime = "#8EBE57"; colours["Tyrian Purple"] = "#990024"; colours["Mardi Gras"] = "#880085"; colours["Royal Blue"] = "#4169E1"; colours["Wild Strawberry"] = "#FF43A4"; colours["Smoky Black"] = "#100C08"; colours.Goldenrod = "#DAA520"; colours.Cyan = "#00FFFF"; colours.Artichoke = "#8F9779"; colours["Rain Forest"] = "#00755E"; colours.Peach = "#FFE5B4"; colours["Apple Green"] = "#8DB600"; colours.Viridian = "#40826D"; colours.Mahogany = "#C04000"; colours["Pink Lace"] = "#FFDDF4"; colours.Bronze = "#CD7F32"; colours["Wood Brown"] = "#C19A6B"; colours.Tuscany = "#C09999"; colours["Acid Green"] = "#B0BF1A"; colours.Amazon = "#3B7A57"; colours["Army Green"] = "#4B5320"; colours["Donkey Brown"] = "#664C28"; colours.Cordovan = "#893F45"; colours.Cinnamon = "#D2691E"; colours.Charcoal = "#36454F"; colours.Fuchsia = "#FF00FF"; colours["Screamin' Green"] = "#76FF7A"; colours.TextColour = "#DDDDDD"; colours.TextColor = "#DDDDDD";
	colours.WZyellow = "#ABA500"; colours.WZgreen = "#198225"; colours["WZLight Blue"] = "#50B2E3"; colours.WZblue = "#242D9A"; colours.WZred = "#9A2929";
	return colours;
end

-- ============================================================
-- NUCLEAR MUSHROOM CLOUD VISUAL (PHASED, ASYMMETRIC, RANDOMIZED)
-- ============================================================

local function clamp (x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

local function rand (scale)
    return (math.random() * 2 - 1) * scale
end

local function buildRing (radius, centerY, count, jitter)
    local verts = {}
    for i = 0, count - 1 do
        local a = (math.pi * 2 / count) * i
        local x = math.cos(a) * radius + rand(jitter)
        local y = math.sin(a) * radius + centerY + rand(jitter)
        table.insert(verts, { x, y })
    end
    return verts
end

-- ============================================================
-- GROUND CLOUD (WIDER, TRIANGULAR-ISH, FLAT BOTTOM)
-- ============================================================

local function buildGroundCloud (p, count)
    if p <= 0 then
        return buildRing(0.5, 0, count, 0)
    end

    local r = 18 + 10 * p   -- wider ground cloud
    local jitter = 1.8

    local verts = buildRing(r, 0, count, jitter)

    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local sinv = math.sin(angle)

        if sinv < 0 then
            verts[i][2] = 0
        else
            verts[i][2] = verts[i][2] - sinv * (7 + 3 * p)
        end
    end

    return verts
end

-- ============================================================
-- COLUMN (ORGANIC, WAVY, SAME WIDTH)
-- ============================================================

local function buildColumn (p, count)
    if p <= 0 then
        return buildRing(0.5, -10, count, 0)
    end

    local baseY = -10
    local topY = -45
    local centerY = baseY + (topY - baseY) * p

    local r = 3 + 2 * p
    local jitter = 1.0

    local verts = buildRing(r, centerY, count, jitter)

    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local wobble = math.sin(angle * 3 + p * 6) * 2
        verts[i][1] = verts[i][1] + wobble
    end

    return verts
end

-- ============================================================
-- MUSHROOM CAP (CLOUDY, ASYMMETRIC, EXPANDING)
-- ============================================================

local function buildCap (p, count)
    if p <= 0 then
        return buildRing(0.5, -45, count, 0)
    end

    local baseY = -45
    local topY = -70
    local centerY = baseY + (topY - baseY) * p

    local r = 15 + 25 * p   -- larger cap
    local jitter = 3.0

    local verts = buildRing(r, centerY, count, jitter)

    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local sinv = math.sin(angle)
        local cosv = math.cos(angle)

        if sinv > 0 then
            verts[i][1] = verts[i][1] * (1.4 + 0.4 * p)
            verts[i][2] = verts[i][2] - sinv * (14 + 10 * p)
        end

        -- slight asymmetry
        verts[i][1] = verts[i][1] + cosv * p * 2
    end

    return verts
end

-- ============================================================
-- TRIANGLES (CONNECT RING A → B → C)
-- ============================================================

local function buildTriangles (count)
    local tris = {}

    for i = 1, count do
        local a1 = i
        local a2 = (i % count) + 1
        local b1 = i + count
        local b2 = ((i % count) + 1) + count

        table.insert(tris, a1)
        table.insert(tris, b1)
        table.insert(tris, a2)

        table.insert(tris, a2)
        table.insert(tris, b1)
        table.insert(tris, b2)
    end

    for i = 1, count do
        local b1 = i + count
        local b2 = ((i % count) + 1) + count
        local c1 = i + count * 2
        local c2 = ((i % count) + 1) + count * 2

        table.insert(tris, b1)
        table.insert(tris, c1)
        table.insert(tris, b2)

        table.insert(tris, b2)
        table.insert(tris, c1)
        table.insert(tris, c2)
    end

    return tris
end

-- ============================================================
-- COLOR SYSTEM (PHASED, MIXED, RANDOMIZED)
-- ============================================================

local function getColorWeights (t)
    local phase = clamp(t, 0, 1)

    local wWhite, wYellow, wOrange, wRed, wGrey, wDarkGrey

    if phase < 0.20 then
        wWhite = 0.40
        wYellow = 0.35
        wOrange = 0.25
        wRed = 0
        wGrey = 0
        wDarkGrey = 0

    elseif phase < 0.50 then
        wWhite = 0.10
        wYellow = 0.20
        wOrange = 0.20
        wRed = 0.50
        wGrey = 0
        wDarkGrey = 0

    else
        wWhite = 0
        wYellow = 0.10
        wOrange = 0.15
        wRed = 0.25
        wGrey = 0.35
        wDarkGrey = 0.15
    end

    return {
        { 255,255,255, wWhite },
        { 255,230,80, wYellow },
        { 255,140,40, wOrange },
        { 255,40,40,  wRed },
        { 120,120,120, wGrey },
        { 60,60,60,   wDarkGrey }
    }
end

local function pickColor (weights)
    local r = math.random()
    local acc = 0

    for i = 1, #weights do
        acc = acc + weights[i][4]
        if r <= acc then
            local c = weights[i]
            return string.format("#%02X%02X%02X", c[1], c[2], c[3])
        end
    end

    local c = weights[#weights]
    return string.format("#%02X%02X%02X", c[1], c[2], c[3])
end

local function buildColors (count, t)
    local weights = getColorWeights(t)
    local list = {}
    for i = 1, count do
        list[i] = pickColor(weights)
    end
    return list
end

-- ============================================================
-- FRAME BUILDER (PHASED GROWTH)
-- ============================================================

local function buildFrames ()
    local frames = {}
    local count = 16
    local triangles = buildTriangles(count)

    local keyTimes = {
        0.00, 0.08, 0.16,
        0.24, 0.32, 0.40,
        0.48, 0.56, 0.64,
        0.72, 0.80, 0.90,
        1.00
    }

    for _, t in ipairs(keyTimes) do
        local groundP = clamp(t / 0.40, 0, 1)
        local columnP = clamp((t - 0.20) / 0.60, 0, 1)
        local capP = clamp((t - 0.40) / 0.60, 0, 1)

        local ringA = buildGroundCloud(groundP, count)
        local ringB = buildColumn(columnP, count)
        local ringC = buildCap(capP, count)

        local verts = {}

        for i = 1, count do table.insert(verts, ringA[i]) end
        for i = 1, count do table.insert(verts, ringB[i]) end
        for i = 1, count do table.insert(verts, ringC[i]) end

        local colors = buildColors(count * 3, t)

        table.insert(frames, {
            t = t,
            Vertices = verts,
            Colors = colors
        })
    end

    return frames, triangles
end

-- ============================================================
-- CLIENT VISUAL
-- ============================================================

function Client_Visual (game, order, visual)
    local terr
    for _, v in pairs(game.Map.Territories) do
        terr = v
        break
    end

    local frames, triangles = buildFrames()

    visual
        .SetAnchorPoint(terr.MiddlePointX, terr.MiddlePointY)
        .SetTriangles(triangles)
        .SetFrames(frames)
        .SetDuration(1600)
end


function pentagram_growing_up ()
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