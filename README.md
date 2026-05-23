# Oracle Lens 🔍

照亮你系统里的字体。`fc-list | grep` 的替代品。

## 用法

```bash
oracle-lens              # 列出全部字体
oracle-lens nerd         # 搜索含有 "nerd" 的字体
oracle-lens sarasa       # 搜索 sarasa 字体
oracle-lens jetbrains    # 搜索 jetbrains 字体
```

## 输出示例

```
找到 5 个字体:

  Sarasa Fixed SC Nerd Font
    ├ 样式: Regular, Bold, Bold Italic, Italic, ExtraLight, Light, SemiBold
    ├ 路径: /usr/share/fonts/jonz94-sarasa-fixed-sc-nerd-fonts/
    └ 语言: 德文 / 英文 / 法文 / 俄文 / 越南文 / 简体中文 / 粤语 / 等 195 种

  Sarasa UI SC Nerd Font
    ├ 样式: Regular, Bold, Bold Italic, Italic, ExtraLight, Light, SemiBold
    ├ 路径: /usr/share/fonts/jonz94-sarasa-ui-sc-nerd-fonts/
    └ 语言: 德文 / 英文 / 法文 / 俄文 / 越南文 / 简体中文 / 粤语 / 等 187 种
```

## 依赖

- Python 3
- fontconfig（`fc-list`，任何有 X11/Wayland 的发行版都自带）

## License

MIT
