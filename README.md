# Oracle Lens 🔍

照亮你系统里的字体。`fc-list | grep` 的替代品。

## 用法

```bash
oracle-lens              # 列出全部字体
oracle-lens nerd         # 搜索含有 "nerd" 的字体
oracle-lens sarasa       # 搜索 sarasa 字体
oracle-lens mono jetbrains   # 多个关键词取交集
```

有两个实现，输出等价，任选其一：

| 文件 | 运行时 | 说明 |
| --- | --- | --- |
| `oracle-lens` | Python 3 | 主实现，自包含单文件 |
| `oracle-lens.nu` | Nushell | 结构化实现，输出原生表格 |

## 输出示例

Nushell 版（原生表格，宽度随终端自适应）：

```
找到 6 个字体

╭───┬─────────────────────────────────┬──────────────────────────────────────┬───────────────────────────┬────────────────────╮
│ # │              字体               │                 样式                 │           语言            │        路径        │
├───┼─────────────────────────────────┼──────────────────────────────────────┼───────────────────────────┼────────────────────┤
│ 0 │ JetBrainsMono Nerd Font         │ Regular, Bold, Bold Italic … 共 16 种 │ 德文 / 英文 / 法文 / 等 150 种 │ …truetype/NerdFonts/ │
╰───┴─────────────────────────────────┴──────────────────────────────────────┴───────────────────────────┴────────────────────╯
```

Python 版（树形文本）：

```
找到 5 个字体:

  Sarasa Fixed SC Nerd Font
    ├ 样式: Regular, Bold, Bold Italic, Italic, ExtraLight, Light, SemiBold
    ├ 路径: /usr/share/fonts/jonz94-sarasa-fixed-sc-nerd-fonts/
    └ 语言: 德文 / 英文 / 法文 / 俄文 / 越南文 / 简体中文 / 粤语 / 等 195 种
```

## 依赖

- Python 3（`oracle-lens`）或 Nushell 0.112+（`oracle-lens.nu`）
- fontconfig（`fc-list`，任何有 X11/Wayland 的发行版都自带）

## 开发环境

```bash
nix develop                    # flake，提供 python3 + nushell
nix-shell                      # 等价的 legacy shell.nix
```

## License

MIT
