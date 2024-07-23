# fucript-markers_to_title
达芬奇Resolve的lua脚本，从时间线标记创建进度条的标题文字; 
davinci resolve lua script, Creating title text from timeline markers;

## 如何使用
1. 把该脚本`markers_to_progress_bar_title.lua`放置到`<Your_DaVinci_Fusion_Script_Path>/Comp`文件夹下；
   ```
   -- <Your_DaVinci_Fusion_Script_Path>
    Mac OS X:
      - All users: /Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts
      - Specific user:  /Users/<UserName>/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts
    Windows:
      - All users: %PROGRAMDATA%\Blackmagic Design\DaVinci Resolve\Fusion\Scripts
      - Specific user: %APPDATA%\Roaming\Blackmagic Design\DaVinci Resolve\Support\Fusion\Scripts
    Linux:
      - All users: /opt/resolve/Fusion/Scripts  (or /home/resolve/Fusion/Scripts/ depending on installation)
      - Specific user: $HOME/.local/share/DaVinciResolve/Fusion/Scripts
   ```

3. 对时间线打标记，快捷键：`M`，注意：必须是时间线上的标记(当没有选中任何片段时，打的标记便是时间线上的标记;或者锁定所有视频轨)，对剪辑片段的标记不会被识别；
4. 在`DaVinici Resolve`中当前时间线上，最上方轨道添加一个fusion片段；
5. 进入fusion页面，点击菜单栏中的`工作区`>`脚本`>`markers_to_progress_bar_title`即可，脚本将为从当前时间线的标记创建进度条的Fusion标题.（章节标记）

## 须知
1. 标记的名称将被用作主标题，备注信息为副标题
2. 当第一个标记的备注信息中包含`%time%`时，将会为所有副标题添加标记的时间码；
3. 生成的节点模板是带有表达式的，方便修改

## 设置参数
1. `进度条标题在` :: 屏幕中的位置
2. `时间码显示小时` :: 当第一个标记的备注中有 `%time%` 才有效，默认时间码格式显示 `00:00:00`, 启用后格式 `00:00:00:00`
3. `创建文字样式控制` :: 创建文字样式方便于主/副标题文字样式的统一控制修改，但是生成较慢，而且渲染更慢；不勾选的话，更快但不便于修改。

## 默认字体
- 创建进度条标题的时候默认字体是使用macOS上的`黑体-简`，在其他系统上可能会缺少字体而显示 `口口口`。
- 如果你是Linux或Windows用户，请修改`defaultFont`中的默认字体设置，可以在脚本文件中通过搜索`Heiti SC` 或 `默认字体` 找到修改的地方。
- title 是主标题，从标记的 `名称` 获取；
- subTitle 是副标题，从标记的 `备注` 获取。

```
local function DefaultFont()
    -- 在这里修改你的默认字体
    local defaultFont = {
        title = {font="Heiti SC", style="Medium", size=0.018, space = 1},
        subTitle = {font="Heiti SC", style="Light", size=0.014, space = 1.5}
    }
    return defaultFont
end
```