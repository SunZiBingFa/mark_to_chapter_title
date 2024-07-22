-- 这是一个从Tag创建视频进度条的脚本
-- 只能在DaVinci Resolve中使用

local function detectOS()
    -- 尝试判断Windows
    local isWindows = os.execute("ver >nul 2>&1") == 0
    
    if not isWindows then
        -- 尝试判断Unix-like系统（包括Linux和macOS）
        local f = io.popen("uname -s")
        if f then
            local sysname = f:read():lower():gsub("%s+", "")
            f:close()
            
            if sysname == "linux" then
                return "Linux"
            elseif sysname == "darwin" then
                return "macOS"
            end
        end
    end
    return isWindows and "Windows" or "Unknown"
end

local function GetOSFont()
    local OS = detectOS()
    local OSfont = {}
    if OS == "macOS" then
        OSfont = {
            title = {font="Heiti SC", style="Medium", size=0.018, space = 1},
            subTitle = {font="Heiti SC", style="Light", size=0.014, space = 1.5},
        }
    elseif OS == "Linux" then
        OSfont = {
            title = {font="Heiti SC", style="Medium", size=0.018, space = 1},
            subTitle = {font="Heiti SC", style="Light", size=0.014, space = 1.5},
        }
    else
        OSfont = {
            title = {font="Heiti SC", style="Medium", size=0.02, space = 1},
            subTitle = {font="Heiti SC", style="Light", size=0.015, space = 1.5},
        }
    end
    return OSfont
end

local function SortMarkers(markers)
    local sort = {}
    for i in pairs(markers) do
        table.insert(sort, i) 
    end
    table.sort(sort, function(a, b)return (tonumber(a) < tonumber(b)) end)

    local timelineDuration = timeline:GetEndFrame() - timeline:GetStartFrame()
    local result = {}
    for k, v in pairs(sort) do
        if v < timelineDuration then
            table.insert(result, {frame = v, name = markers[v].name, note = markers[v].note})
        end
    end
    table.insert(result, {frame = timelineDuration, name = "TimelineEnd__", note = ""})
    return result
end

local function GetTextPos(tagFrame, nextTagFrame, duration)
    return ( tagFrame + (nextTagFrame - tagFrame) / 2 ) / duration
end

local function DeleteAllNode(comp)
    tools = comp:GetToolList()
    for _, node in pairs(tools) do
        node:Delete()
    end
end

local function delimiterXfNodes(comp, beforeNode, afterNode, screenSide)
    local markers = SortMarkers(srcMarkers)
    if markers[1].frame == 0 then
        table.remove(markers, 1)
    end
    local count = #markers - 1
    local posY = math.min(math.floor(count / 2), 3)

    for i = 1, count do
        local xf = comp:AddTool("Transform", -3, i-posY)
        local toolName = "delimiterXf_"..i
        if screenSide == 0 or screenSide == 1 then
            xf.Center = {markers[i].frame / markers[#markers].frame, 0.5}
        elseif screenSide == 2 or screenSide == 3 then
            xf.Center = {0.5, markers[i].frame / markers[#markers].frame}
        end
        xf:SetAttrs({TOOLS_Name = toolName})
        xf:ConnectInput("Input", beforeNode)
        if i == 1 then
            afterNode:ConnectInput("Background", xf)
        else
            afterNode:ConnectInput("Layer"..(i-1)..".Foreground", xf)
        end
    end
end

local function FrameToTimecode(frame, showHours)
    local frameRate = project:GetSetting("timelineFrameRate")
    local hours = frame / (3600 * frameRate)
    local minutes = frame / (60 * frameRate) % 60
    local seconds = frame / frameRate % 60
    local frames = frame % frameRate
    if showHours == 1 then
        timecode = string.format("%02d:%02d:%02d:%02d", hours, minutes, seconds, frames)
    else
        timecode = string.format("%02d:%02d:%02d", minutes, seconds, frames)
    end
    return timecode
end

local function NoteLinkData(node, linkNode)
    for i, v in pairs(node:GetInputList()) do
        id = v:GetAttrs().INPS_ID
        if id ~= "StyledText" then
            expression = linkNode.Name .. "." .. id
            node[id]:SetExpression(expression)
        end
    end
end

local function AddTextAndXfNodes(comp, mergeNode, titleMask, config, titleSetting)
    local markers = SortMarkers(srcMarkers)
    local count = #markers - 1
    local posX = math.ceil(count / 2)

    local screenSide = config.screenSide
    local showHours = config.showHours
    local createFontStyle = config.createFontStyle

    if titleSetting.contextTag == "note" then
        local allSubTitle = ""
        for i = 1, count do
            allSubTitle = allSubTitle .. markers[i].note
        end
        if allSubTitle == "" then
            return
        end
    end

    if createFontStyle == 1 then
        fontStyle = comp:AddTool("TextPlus", 0, - titleSetting.yOffset - 7)
        fontStyle:SetAttrs({TOOLS_Name = titleSetting.fontStyleName})
        fontStyle.StyledText = "文字样式"
        fontStyle.Font = titleSetting.font
        fontStyle.Style = titleSetting.style
        fontStyle.Size = titleSetting.size
        fontStyle.LineSpacingClone = titleSetting.space
    end

    local context = ""
    for i = 1, count do
        local title = comp:AddTool("TextPlus", i - posX, - titleSetting.yOffset -5)
        title:SetAttrs({TOOLS_Name = titleSetting.titleName .. "_" .. i})

        if createFontStyle == 1 then
            NoteLinkData(title, fontStyle)
        else
            title.Font = titleSetting.font
            title.Style = titleSetting.style
            title.Size = titleSetting.size
            title.LineSpacingClone = titleSetting.space
        end

        if titleSetting.contextTag == "name" then
            context = markers[i].name
            if (markers[i].note ~= "") or string.find(markers[1].note, "%%time%%") then
                context = context .. "\n"
            end
        elseif titleSetting.contextTag == "note" then
            if string.find(markers[1].note, "%%time%%") then
                context = FrameToTimecode(markers[i].frame, showHours) .. markers[i].note
                if i == 1 then
                    context = string.gsub(context, "%%time%%", "")
                end
            else
                context = markers[i].note
            end
            if markers[i].name ~= nil then
                context = "\n" .. context
            end
        end
        title.StyledText = context

        local xf = comp:AddTool("Transform", i - posX, - titleSetting.yOffset - 4)
        xf:SetAttrs({TOOLS_Name = titleSetting.titleName .. "Xf_" .. i})

        local tPos = GetTextPos(markers[i].frame, markers[i+1].frame, markers[#markers].frame)
        if screenSide == 0 then -- DOWN
            xf.Center:SetExpression("Point(" .. tPos .. ", " .. titleMask.Name .. ".Height / 2)")
        elseif screenSide == 1 then -- UP
            xf.Center:SetExpression("Point(" .. tPos .. ", 1 - " .. titleMask.Name .. ".Height / 2)")
        elseif screenSide == 2 then -- LEFT
            xf.Center:SetExpression("Point(" .. titleMask.Name .. ".Width / 2, " .. tPos .. ")")
        elseif screenSide == 3 then --RIGHT
            xf.Center:SetExpression("Point(1 - " .. titleMask.Name .. ".Width / 2, " .. tPos .. ")")
        end

        xf.Center = {xfCenterX, 0.5}
        xf:ConnectInput("Input", title)
        if i == 1 then
            mergeNode:ConnectInput("Background", xf)
        else
            mergeNode:ConnectInput("Layer" .. (i-1) .. ".Foreground", xf)
        end
    end
end

local function SetTitleMask(titleMask, screenSide)
    if screenSide == 0 then -- DOWN
        titleMask.Center:SetExpression("Point(Width/2, Height/2)")
        titleMask.Width = 1
        titleMask.Height = 0.06
    elseif screenSide == 1 then  --UP
        titleMask.Center:SetExpression("Point(Width/2, 1-Height/2)")
        titleMask.Width = 1
        titleMask.Height = 0.06
    elseif screenSide == 2 then -- LEFT
        titleMask.Center:SetExpression("Point(Width/2, Height/2)")
        titleMask.Width = 0.06
        titleMask.Height = 1
    elseif screenSide == 3 then --RIGHT
        titleMask.Center:SetExpression("Point(1-Width/2, Height/2)")
        titleMask.Width = 0.06
        titleMask.Height = 1
    end
end

local function delimiterWidthHeight(node, screenSide)
    if screenSide == 0 or screenSide == 1 then
        node.Width = 0.002
        node.Height = 1
    elseif screenSide == 2 or screenSide == 3 then
        node.Width = 1
        node.Height = 0.002
    end
end

local function FusionProgressTitle(comp, config)
    DeleteAllNode(comp)
    
    local mainBG = comp:AddTool("Background", -1, 3)
    mainBG:SetAttrs({TOOLS_Name = "MainBG"})
    mainBG.TopLeftAlpha = 0
    
    local titleMask = comp:AddTool("RectangleMask", 1, 3)
    titleMask:SetAttrs({TOOLS_Name = "TitleMask"})
    SetTitleMask(titleMask, config.screenSide)
    
    local mMergeA = comp:AddTool("MultiMerge", -2, 1)
    mMergeA:SetAttrs({TOOLS_Name = "mMergeA"})
    
    local mMergeB = comp:AddTool("MultiMerge", 0, -10)
    mMergeB:SetAttrs({TOOLS_Name = "mMergeB"})

    local mMergeC = comp:AddTool("MultiMerge", 0, -2)
    mMergeC:SetAttrs({TOOLS_Name = "mMergeC"})
    
    local mMergeOut = comp:AddTool("MultiMerge", 0, 1)
    mMergeOut:SetAttrs({TOOLS_Name = "mMergeOut"})
    
    local mediaOut = comp:AddTool("MediaOut", 3, 1)
    mediaOut:SetAttrs({TOOLS_Name = "mediaOut"})
    
    local shapeDelimiter = comp:AddTool("RectangleMask", -6, 1)
    shapeDelimiter:SetAttrs({TOOLS_Name = "shapeDelimiter"})
    delimiterWidthHeight(shapeDelimiter, config.screenSide)
    
    local shapeColor = comp:AddTool("Background", -5, 1)
    shapeColor:SetAttrs({TOOLS_Name = "shapeColor"})
    shapeColor.TopLeftRed = 1
    shapeColor.TopLeftGreen = 1
    shapeColor.TopLeftBlue = 1
    
    mMergeOut:ConnectInput("Background", mainBG)
    mMergeOut:ConnectInput("EffectMask", titleMask)
    mMergeOut:ConnectInput("Layer1.Foreground", mMergeA)
    mMergeOut:ConnectInput("Layer2.Foreground", mMergeB)
    mMergeOut:ConnectInput("Layer3.Foreground", mMergeC)
    mediaOut:ConnectInput("Input", mMergeOut)
    shapeColor:ConnectInput("EffectMask", shapeDelimiter)
    mainBG:ConnectInput("EffectMask", titleMask)
    comp:GetFrameList()[1]:ViewOn(mediaOut, 2)

    local OSfont = GetOSFont()

    delimiterXfNodes(comp, shapeColor, mMergeA, config.screenSide)
    titleSetting = {font=OSfont.title.font, style=OSfont.title.style, size=OSfont.title.size, space = OSfont.title.space,
                    fontStyleName = "titleFontStyle", titleName = "title", contextTag = "name",
                    yOffset = 8}
    subTtileSetting = {font=OSfont.subTitle.font, style=OSfont.subTitle.style, size=OSfont.subTitle.size, space = OSfont.subTitle.space,
                    fontStyleName = "subTitleFontStyle", titleName = "subTitle", contextTag = "note", 
                    yOffset = 0}
    AddTextAndXfNodes(comp, mMergeB, titleMask, config, titleSetting)
    AddTextAndXfNodes(comp, mMergeC, titleMask, config, subTtileSetting)
end

local function ConfigUI()
    local comp = fusion:GetCurrentComp()
    local ask = {
        {"screenSide", Name = "进度条标题在", "Dropdown", Options = {"底部", "顶部", "左侧", "右侧"}, Default = 0},
        {"showHours", Name="时间码显示小时", "Checkbox", NumAcross=2, Default=0},
        {"createFontStyle", Name="创建文字样式控制", "Checkbox", NumAcross=2, Default=0}
    }
    local config = comp:AskUser("Config", ask)

    if config == nil then
        print("you cancelled the dialog")
    else
        FusionProgressTitle(comp, config)
    end
end

local function main()
    local page = resolve:GetCurrentPage()
    if page ~= "fusion" then
        timeline:SetCurrentTimecode(timeline:GetStartTimecode())
        resolve:OpenPage("fusion")
        ConfigUI()
        resolve:OpenPage(page)
    else
        ConfigUI()
    end
end


resolve = Resolve()
projectManager = resolve:GetProjectManager()
project = projectManager:GetCurrentProject()
timeline = project:GetCurrentTimeline()
srcMarkers = timeline:GetMarkers()
fusion = resolve:Fusion()

main()
