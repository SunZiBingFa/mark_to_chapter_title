# Mark_to_chapter_title
达芬奇Resolve的lua脚本，从时间线标记创建进度条的标题文字。<br/>
davinci resolve lua script, Creating chapter title text from timeline markers。

## 须知
## 更新
新增了两个脚本，一个是给windows用户的脚本：`mark_to_chapter_title_for_win`， 以及一个给macOS用户的脚本`mark_to_chapter_title_for_mac.lua`。<br>

原本的脚本：`mark_to_chapter_title.lua` 需要下载 `思源黑体-VF` (SourceHanSansSC-VF)，Linux用户可以考虑下载该字体或修改默认字体。


### 版本要求
DaVinci Resolve 18.5 以上，因为使用到了 18.5 的 `multiMerge` 节点。
### 字体链接
『思源黑体-VF』
https://github.com/adobe-fonts/source-han-sans/releases

下载: Variable OTF/TTF/OTC/WOFF2 <br>
如果不想下载字体，可以修改默认字体，方法详见本文末尾。


## 如何使用
1. 把该脚本`mark_to_chapter_title.lua`放置到`<Your_DaVinci_Fusion_Script_Path>/Comp`文件夹下；
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

2. 对时间线打标记，快捷键：`m`，【注：必须是时间线上的标记才被识别(当没有选中任何片段时，打的就是时间线上的标记；或者锁定所有视频轨后打标记)，对剪辑片段的标记和超出渲染出点的标记将不被识别】；
3. 双击标记或使用快捷键 `Ctrl/Command + m` 修改标记内容，标记名称即为章节主标题（必须），备注为副标题（可选）；
4. 在`DaVinici Resolve`中当前时间线上，最上方轨道添加一个fusion片段，播放头确保在fusion片段的时间范围内；
5. 进入fusion页面，点击菜单栏中的`工作区`>`脚本`>`Comp`>`markers_to_progress_bar_title`启动脚本。

## 其他
1. 生成的节点模板是带有表达式的，方便修改。
2. 控制节点：`TitleMask`节点的宽度或高度，控制进度条粗细；`fontStyle`和`subFontStyle`控制文本样式（需勾选`创建文字样式控制`）。
3. `创建文字样式控制`该选项会创建一个用于修改主/副标题文字样式的节点，但是生成较慢，而且渲染更慢；不勾选的话，更快但不便于修改。如果勾选了该选项，不建议使用该片段渲染，可以修改完样式后配合`DaVinci Resolve`的`抓取静帧`命令，使用静帧替换Fusion片段。

## 默认字体
- 创建进度条标题的时候默认字体是开源字体`思源黑体VF`，可自行搜寻字体下载，该字体免费开源，如缺少该字体会显示 `口口口`。
- 或者修改代码中`defaultFont`中的默认字体设置，可以在脚本文件中通过搜索`默认字体` 找到修改的地方。
- `title` 是主标题，从标记的 `名称` 获取字符串；
- `subTitle` 是副标题，从标记的 `备注` 获取字符串。

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