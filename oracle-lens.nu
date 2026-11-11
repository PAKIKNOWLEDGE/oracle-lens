#!/usr/bin/env nu

# Oracle Lens — 照亮你系统里的字体
#
# Usage:
#     oracle-lens.nu             列出全部字体
#     oracle-lens.nu <关键词>    搜索字体
#
# 依赖：Nushell，fontconfig（fc-list）

const FCLIST_FORMAT = "%{family}\t%{style}\t%{file}\t%{lang}\n"

const WEIGHT_KEYWORDS = ["extra" "semi" "thin" "light" "medium" "bold" "black" "heavy"]

const KEY_LANGS = {
  "zh": "中文"
  "zh-cn": "简体中文"
  "zh-tw": "繁体中文"
  "zh-hk": "粤语"
  "ja": "日文"
  "ko": "韩文"
  "en": "英文"
  "fr": "法文"
  "de": "德文"
  "ru": "俄文"
  "ar": "阿拉伯文"
  "he": "希伯来文"
  "th": "泰文"
  "vi": "越南文"
}

# 保序去重（比较 key 闭包返回值，保留首次出现的原值）
def uniq-stable [key: closure] {
  reduce --fold [] {|it, acc|
    let k = (do $key $it)
    if (($acc | any {|x| (do $key $x) == $k })) { $acc } else { $acc | append $it }
  }
}

# 取第一个"大部分是 ASCII 字母"的家族名作为显示名
def get-primary-family [raw: string] {
  let names = ($raw | split row "," | each {|n| $n | str trim } | where {|n| $n | is-not-empty })

  for name in $names {
    let chars = ($name | split chars)
    let total_alpha = ($chars | where {|c| $c =~ r#'^\p{L}$'# } | length)
    if $total_alpha == 0 { continue }
    let ascii_alpha = ($chars | where {|c| $c =~ r#'^[A-Za-z]$'# } | length)
    if ($ascii_alpha / $total_alpha) > 0.8 {
      return $name
    }
  }
  if ($names | is-empty) { $raw } else { $names | first }
}

# 取适合写进配置文件的字体名（短、纯英文、不带 weight 后缀）
def get-config-name [raw: string] {
  let names = ($raw | split row "," | each {|n| $n | str trim } | where {|n| $n | is-not-empty })

  let is_config_friendly = {|name|
    let chars = ($name | split chars)
    let ascii_count = ($chars | where {|c| ($c =~ r#'^[A-Za-z]$'#) or ($c =~ r#'^[ \t\n\r\f\v]$'#) or ($c == "-") or ($c == ".") or ($c == "'") } | length)
    if ($chars | length) == 0 { false } else { ($ascii_count / ($chars | length)) > 0.8 }
  }

  let candidates = ($names | where {|name|
    let low = ($name | str lowercase)
    not ($WEIGHT_KEYWORDS | any {|w| $low | str contains $w })
  })

  for name in $candidates {
    if (do $is_config_friendly $name) { return $name }
  }

  for name in $names {
    if (do $is_config_friendly $name) { return $name }
  }

  if ($names | is-empty) { $raw } else { $names | first }
}

# 清理样式字段中的别名，去重
def clean-style [raw: string] {
  $raw
  | split row ","
  | each {|s| $s | str trim }
  | where {|s| $s | is-not-empty }
  | uniq-stable {|s| $s | str lowercase }
}

# 缩短 home 路径，并取字体所在目录
def family-dir [paths: list] {
  let with_sep = ($paths | where {|p| $p | str contains "/" })
  if ($with_sep | is-empty) { return "" }

  let p = ($with_sep | first)
  let d = ($p | path dirname) + "/"
  let home = ($env.HOME? | default "")
  if ($home | is-not-empty) and ($d | str starts-with $home) {
    "~" + ($d | str substring ($home | str length)..)
  } else {
    $d
  }
}

# 从 lang 字段提取可读的语言摘要
def summarize-lang [langs: list] {
  if ($langs | is-empty) { return "" }

  let all_codes = ($langs
    | each {|raw| $raw | split row "|" | each {|c| $c | str trim } }
    | flatten
    | where {|c| ($c | is-not-empty) and $c != "none" }
    | uniq)

  if ($all_codes | is-empty) { return "" }

  let found = ($all_codes
    | sort
    | where {|c| $KEY_LANGS | columns | any {|k| $k == $c } }
    | each {|c| $KEY_LANGS | get $c })

  let other_count = ($all_codes | where {|c| not ($KEY_LANGS | columns | any {|k| $k == $c }) } | length)

  let result = ($found | uniq | take 4)
  let rest = (($found | uniq | length) - ($result | length)) + $other_count

  let body = ($result | str join " / ")
  if $rest > 0 { $"($body) / 等 ($rest) 种" } else { $body }
}

def style-rank [s: string] {
  if $s == "Regular" { 0 } else if ($s in ["Bold" "Italic" "Bold Italic"]) { 1 } else { 2 }
}

# 样式太多时只保留前几个，避免撑爆表格
def fmt-styles [styles: list] {
  let full = ($styles | str join ", ")
  if ($full | str length) <= 60 { return $full }

  let head = ($styles | take 5 | str join ", ")
  $"($head) … 共 ($styles | length) 种"
}

# 路径太长时保留尾部，前面用 … 省略（尾部最能说明字体装在哪）
def shorten-path [d: string, max: int = 34] {
  let n = ($d | str length)
  if $n <= $max { return $d }
  "…" + ($d | str substring ($n - $max + 1)..)
}

# 适合写进配置文件的短名（kitty / CSS / fontconfig）
def config-name [family: string, names: list] {
  if ($names | is-empty) { return "" }
  let best = ($names | sort-by {|n| $n | str length } | first)
  if $best == $family { "" } else { $best }
}

# 读取并解析 fc-list 输出
def load-fonts [] {
  if (which fc-list | is-empty) {
    print --stderr "错误: 需要 fontconfig（fc-list）"
    exit 1
  }

  ^fc-list --format $FCLIST_FORMAT
  | from tsv --noheaders
  | rename family style file lang
  | where {|r| ($r.family | is-not-empty) }
  | each {|r|
      {
        family: (get-primary-family $r.family)
        config_name: (get-config-name $r.family)
        all_names: ($r.family | split row "," | each {|n| $n | str trim } | where {|n| $n | is-not-empty })
        styles: (clean-style $r.style)
        path: $r.file
        lang: ($r.lang? | default "")
      }
    }
}

def main [...query: string] {
  let fonts = (load-fonts)

  # 按显示名聚合成组
  let groups = ($fonts
    | group-by --to-table family
    | each {|g|
        {
          family: $g.family
          styles: ($g.items | get styles | flatten | uniq-stable {|s| $s | str lowercase })
          langs: ($g.items | get lang | where {|l| $l | is-not-empty } | uniq)
          paths: ($g.items | get path | uniq)
          all_names: ($g.items | get all_names | flatten | uniq)
          config_names: ($g.items | get config_name | uniq)
        }
      })

  let matched = if ($query | is-empty) {
    $groups
  } else {
    let words = ($query | each {|w| $w | str lowercase })
    $groups | where {|g|
      let text = (
        [$g.family ($g.all_names | str join " ") ($g.styles | str join " ") ($g.langs | str join "|")]
        | str join " "
        | str lowercase
      )
      $words | all {|w| $text | str contains $w }
    }
  }

  if ($matched | is-empty) {
    let q = ($query | str join " ")
    print $"🔍 没有找到匹配「($q)」的字体"
    return
  }

  let rows = ($matched
    | sort-by family
    | each {|g|
        let styles = ($g.styles | sort | sort-by {|s| style-rank $s })
        {
          "字体": $g.family
          "配置": (config-name $g.family $g.config_names)
          "样式": (fmt-styles $styles)
          "语言": (summarize-lang $g.langs)
          "路径": (shorten-path (family-dir $g.paths))
        }
      })

  # 配置名全都是空的话，这一列没有意义
  let rows = if ($rows | any {|r| ($r | get "配置") | is-not-empty }) {
    $rows
  } else {
    $rows | reject "配置"
  }

  print $"找到 ($rows | length) 个字体\n"

  # 终端宽度自适应；非 tty（管道/重定向）时给一个足够宽的默认值
  let width = ($env.COLUMNS? | default "200" | into int)
  $rows | table --width $width
}
