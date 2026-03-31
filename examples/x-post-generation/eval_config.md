# Xポスト生成の評価設定

## 評価方針

reference（実際に書いた投稿）と output（生成された投稿）を直接比較し、どれだけ近いかを測る。

## 評価軸（重み付けなし、単純平均）

| 軸 | 評価観点 | スコア計算 |
|---|---|---|
| **content_coverage** | reference に含まれる事実・データ・固有名詞が output にも含まれているか | (output に存在する reference の情報断片数 / reference の情報断片総数) × 100 |
| **structure_match** | 構成（段落の順序、セクションの切り方、話の流れ）が reference と近いか | 段落ごとの内容対応を分析し、順序の一致度を 0-100 で算出 |
| **style_match** | 文体・トーン（語尾、表現パターン、敬体/常体、絵文字使用等）が reference と近いか | reference の文体特徴を抽出し、output がどれだけ再現しているかを 0-100 で判定 |
| **length_match** | 文字数が reference と近いか | score = max(0, 100 - |ref文字数 - out文字数| / ref文字数 × 100) |

## 各軸の詳細

### content_coverage

reference のテキストから情報断片（事実、数値、固有名詞、主張）を抽出し、output に含まれているか照合する。

- 同じ事実が言い換えられていても OK
- output に reference にない情報があってもペナルティなし
- reference の情報が output から欠落している場合に減点

### structure_match

reference と output の段落構成を比較する。

- 導入→本題→結論の流れが同じか
- セクション見出しの有無や位置が近いか
- 話の展開順序（時系列、因果関係等）が一致しているか

### style_match

reference の文体的特徴を抽出し、output が再現しているかを評価する。

- 敬体（です/ます）vs 常体（だ/である）の一致
- 一人称の使い方
- 専門用語の使い方（そのまま vs 平易に言い換え）
- 段落の長さの傾向

### length_match

文字数の近さを測る。reference の文字数に対する乖離率でスコアを算出する。

## score.md のフォーマット

```markdown
# 評価: {case_name}（iter_N）

## 定量サマリ

| 軸 | スコア | 詳細 |
|---|---|---|
| content_coverage | XX.X | 情報断片 X/Y 個が output に存在 |
| structure_match | XX.X | 段落構成の一致度 |
| style_match | XX.X | 文体特徴の再現度 |
| length_match | XX.X | ref: X文字, out: Y文字 |
| **総合（単純平均）** | **XX.X** | |

## 定性分析

### reference と output の主な違い

なぜその違いが生じたかを分析する。

### 品質ギャップ一覧

| # | 軸 | reference の該当箇所 | output の該当箇所 | 説明 |
|---|---|---|---|---|
```
