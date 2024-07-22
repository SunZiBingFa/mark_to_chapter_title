# fucript-markers_to_title
达芬奇Resolve的lua脚本，从时间线标记创建进度条的标题文字; 
davinci resolve lua script, Creating title text from timeline markers;

## 如何使用
1. 把该脚本`markers_to_progress_bar_title.lua`放置到`<Your_DaVinci_Script_Path>/Comp`文件夹下
   ```
   -- <Your_DaVinci_Script_path>
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

3. 在`DaVinici Resolve`中当前时间线上，最上方轨道添加一个fusion片段
4. 进入fusion页面，点击菜单栏中的`工作区`>`脚本`>`markers_to_progress_bar_title`即可，脚本将为从当前时间线的标记创建Fusion标题.
