-- 这是一个从标记创建视频进度条的脚本
-- 只能在DaVinci Resolve中使用

local function DefaultFont()
    -- 在这里修改你的默认字体
    local defaultFont = {
        title = {font="Heiti SC", style="Medium", size=0.017, space = 1.2},
        subTitle = {font="Heiti SC", style="Light", size=0.013, space = 1.2}
    }
    return defaultFont
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
    local tools = comp:GetToolList()
    for _, node in pairs(tools) do
        node:Delete()
    end
end

local function delimiterXfNodes(comp, beforeNode, afterNode, screenSide, titleMask)
    local markers = SortMarkers(srcMarkers)
    if markers[1].frame == 0 then
        table.remove(markers, 1)
    end
    local count = #markers - 1
    local posY = math.min(math.floor(count / 2), 3)

    for i = 1, count do
        local xf = comp:AddTool("Transform", -3, i-posY)
        local toolName = "delimiterXf_"..i
        local thickness = markers[i].frame / markers[#markers].frame
        if screenSide == 0 then
            xf.Center:SetExpression("Point(" .. thickness .. ", " .. titleMask.Name .. ".Height / 2)")
        elseif screenSide == 1 then
            xf.Center:SetExpression("Point(" .. thickness .. ", 1 - " .. titleMask.Name .. ".Height / 2)")
        elseif screenSide == 2 then
            xf.Center:SetExpression("Point(" .. titleMask.Name .. ".Width / 2 , " .. thickness .. ")")
        elseif screenSide == 3 then
            xf.Center:SetExpression("Point(1 - " .. titleMask.Name .. ".Width / 2 , " .. thickness .. ")")
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
    local timecode = nil
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
        local id = v:GetAttrs().INPS_ID
        if id ~= "StyledText" then
            local expression = linkNode.Name .. "." .. id
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

    if (titleSetting.contextTag == "note") and (config.isTimecode == 0) then
        local allSubTitle = ""
        for i = 1, count do
            allSubTitle = allSubTitle .. markers[i].note
        end
        if allSubTitle == "" then
            local tools = comp:GetToolList()
            for i, tool in pairs(tools) do
                if tool:GetAttrs().TOOLS_Name == "mMergeC" then
                    tool:Delete()
                end
            end
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
            if (markers[i].note ~= "") or (config.isTimecode == 1) then
                context = context .. "\n"
            end
        elseif titleSetting.contextTag == "note" then
            if (config.isTimecode == 1) then
                context = FrameToTimecode(markers[i].frame, showHours) .. markers[i].note
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
        titleMask.Height = 0.05
    elseif screenSide == 1 then  --UP
        titleMask.Center:SetExpression("Point(Width/2, 1-Height/2)")
        titleMask.Width = 1
        titleMask.Height = 0.05
    elseif screenSide == 2 then -- LEFT
        titleMask.Center:SetExpression("Point(Width/2, Height/2)")
        titleMask.Width = 0.08
        titleMask.Height = 1
    elseif screenSide == 3 then --RIGHT
        titleMask.Center:SetExpression("Point(1-Width/2, Height/2)")
        titleMask.Width = 0.08
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

    local default = DefaultFont()

    delimiterXfNodes(comp, shapeColor, mMergeA, config.screenSide, titleMask)
    local titleSetting = {font=default.title.font, style=default.title.style, size=default.title.size, space = default.title.space,
                    fontStyleName = "titleFontStyle", titleName = "title", contextTag = "name",
                    yOffset = 8}
    local subTitleSetting = {font=default.subTitle.font, style=default.subTitle.style, size=default.subTitle.size, space = default.subTitle.space,
                    fontStyleName = "subTitleFontStyle", titleName = "subTitle", contextTag = "note", 
                    yOffset = 0}
    AddTextAndXfNodes(comp, mMergeB, titleMask, config, titleSetting)
    AddTextAndXfNodes(comp, mMergeC, titleMask, config, subTitleSetting)
end

local function ConfigUI()
    local comp = fusion:GetCurrentComp()
    local ask = {
        {"screenSide", Name = "章节标题位于", "Dropdown", Options = {"底部", "顶部", "左侧", "右侧"}, Default = 0},
        {"isTimecode", Name = "副标题插入时间码", "Checkbox", NumAcross=2, Default=0},
        {"showHours", Name="时间码到小时格式", "Checkbox", NumAcross=2, Default=0},
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
