---
name: skills-tuning
description: Skillをチューニングするスキル。input（入力素材）とreference（人間が作ったお手本）のペアを与えると、テキスト勾配で対象のスキルフォルダ全体を自動で改善し続ける。スキル最適化、スキルチューニング、プロンプト改善と言われたら使う。
disable-model-invocation: false
argument-hint: [作業フォルダ] [データセット名(default:auto)]
---

# Skills Tuning

スキルフォルダ全体を自動でfine-tuningするスキルです。

最適化の対象は SKILL.md 単体ではなく、**スキルフォルダ全体**です。Claude Code のスキルフォルダには制約がなく、あらゆるファイルを置ける:

- **Markdown ファイル**: ルール定義、パターン集、ガイドライン、テンプレート等
- **スクリプト**: Python/Shell スクリプト（バリデーション、前処理、座標計算等）
- **サブフォルダ**: templates/、examples/、scripts/ 等の自由な構造
- **設定ファイル**: JSON/YAML のテンプレートや設定

スキルの最適化は3つのステップで行われる:

1. **ベースライン計測（without-skill）**: スキルなしの素のモデル出力でスコアを計測する
2. **ベーススキル構築（base-skill）**: train データの reference を全件分析し、共通パターンを抽出して高品質な初期スキルを構築する
3. **チューニング（tuned）**: 既存ファイルの記述を微調整し、スキルの能力を保持したまま改善する

## 計算グラフ

```
forward       : スキルフォルダ + input.md → サブエージェント → output（JSON等）
loss          : output vs reference → score.md
backward      : score.md × N cases → 逆追跡 → improvement.md（コンテンツ勾配 + 構造勾配）
update        : スキルフォルダ += improvement → スナップショット
```

各ステップの詳細はサブエージェントに定義されている:
- Forward（推論） → forward-runner サブエージェント
- Loss（損失計算） → loss-evaluator サブエージェント
- Backward + Update（勾配計算 + パラメータ更新） → backward-updater サブエージェント

---

## フォルダ構成

```
{作業フォルダ}/
├── eval_config.md                   # 評価基準（必須）
├── data/
│   └── train/                       # 学習データ（これだけあれば始められる）
│       ├── case_01/
│       │   ├── input.md            # 入力素材
│       │   └── reference.*         # お手本（.md, .json等）
│       └── case_02/
│           └── ...
│
└── runs/                            # 実験結果（自動生成）
    └── exp_NN/
        ├── skill/                   # 作業スキル（常に最新の状態）
        │   └── SKILL.md
        ├── without-skill/           # ベースライン（スキルなし）
        │   ├── train/{case_name}/
        │   │   ├── output.*        # forward の出力
        │   │   ├── judgment-log.md  # 判断の過程
        │   │   └── score.md        # loss の結果
        │   └── scoreboard.md
        ├── base-skill/              # ベーススキル構築後
        │   ├── train/{case_name}/...
        │   ├── skill/               # スナップショット
        │   └── scoreboard.md
        └── tuned/                   # チューニング後
            ├── train/{case_name}/...
            ├── skill/               # スナップショット
            ├── improvement.md       # 改善記録
            └── scoreboard.md
```

### 原則

- スキルは `runs/exp_NN/skill/` 内で base-skill-builder がゼロから生成する
- 全ての編集は `runs/exp_NN/skill/` に対して行う
- ユーザーが事前にスキルを用意する必要はない。data/train/ だけあれば始められる
- 実験完了後、ユーザーが明示的に指示した場合のみ `.claude/skills/` にデプロイする

推奨データ数: train 7+

---

## Step 1: 準備

作業フォルダは `$0`（未指定ならカレントディレクトリ）。データセットは `$1`（未指定なら auto）。

### データセットの解決

`$1` でデータセット名が指定された場合、`data/{データセット名}/train/` を使用する。未指定（auto）の場合は以下の優先順で探索する:

1. `data/train/` が存在すればそれを使う
2. `data/` 直下に `train/` がなく、サブディレクトリ（例: `data/something/`）が1つだけあればそれを使う
3. サブディレクトリが複数ある場合はエラー — ユーザーにデータセット名の指定を求める

### 準備

1. 上記で解決したデータパスの `train/` を探索し、各ケースディレクトリを列挙する
2. 各ケースに `input.md` と reference ファイルがあることを確認する
3. **eval_config.md が作業フォルダ直下にあることを確認する（必須）**。なければエラー終了。eval_config は評価基準を定義するファイルで、これがないと loss-evaluator が的外れな評価をし、backward の改善方向がズレる
4. **サブエージェントの確認**: `.claude/agents/` に以下が存在することを確認する
   - `forward-runner.md`, `loss-evaluator.md`, `backward-updater.md`, `base-skill-builder.md`
5. 実験ディレクトリを作成する: `runs/exp_NN/skill/`
6. 以下を表示して開始:
   - train ケース数
   - eval_config のパス

---

## Step 2: ベースライン計測（without-skill）

**スキルなしの素のモデル出力**で train を回し、ベースラインスコアを記録する。

### 2-0. 最小スキルの作成

`runs/exp_NN/skill/SKILL.md` に最小限の骨格だけを書く（スキル名と1行の指示のみ）。これがベースラインの「スキルなし」状態。

```
mkdir -p runs/exp_NN/skill/
```

SKILL.md の例:
```markdown
---
name: {作業フォルダ名から推定}
description: {reference の内容から推定した1行の説明}
---

# {スキル名}

入力をもとに出力を生成してください。
```

### 2-1. ベースライン forward → loss

最小スキルで train 全ケースについて forward → loss を実行する（Step 4 の「forward → loss（パイプライン実行）」と同じ手順）。

1. train 全ケースについて forward → loss を実行する
2. 結果を `runs/exp_NN/without-skill/train/` に保存する
3. scoreboard を `runs/exp_NN/without-skill/scoreboard.md` に保存する
4. ベースラインスコアを表示する

```
=== ベースライン（without-skill） ===
[Train]  case_01: XX.X | case_02: XX.X | ... | 平均: XX.X
```

---

## Step 3: ベーススキル構築（base-skill）

### 3-1〜3-3. データ分析とベーススキル構築（サブエージェントに委譲）

**base-skill-builder サブエージェント**を起動してベーススキルを構築する。

親エージェントのコンテキストを汚染しないため、サブエージェントとして分離する（25件の reference 全件読み込み + 分析はコンテキスト消費が大きい）。

```
Agent(subagent_type="base-skill-builder") へのプロンプト:

作業コピー: {runs/exp_NN/skill/ の絶対パス}
trainデータ: {data/train/ の絶対パス}
```

サブエージェントが行うこと:
1. train 全ケースの reference と input を分析（構造、パターン、スタイル）
2. 共通パターンを抽出し、必要に応じてファイルを追加（タスクに応じて判断）
3. 分析結果を SKILL.md に反映

**ベーススキル構築の設計思想:**
- チューニングは微調整（fine-tuning）であるべき。大きな変更はベーススキル構築の段階で行う
- ベーススキルが不十分だとチューニングで大きな勾配が出て、1回の更新で壊れやすくなる
- 「チューニングで直す」のではなく「ベーススキルで8割カバーし、チューニングで残り2割を磨く」が理想

出力:
- `runs/exp_NN/skill/` — ベーススキルが構築された状態

### 3-4. ベーススキルの評価

構築したベーススキルで train 全ケースについて forward → loss を実行し、ベーススキルの効果を確認する。

1. train 全ケースについて forward → loss を実行する（Step 4 の「forward → loss（パイプライン実行）」と同じ手順）
2. 結果を `runs/exp_NN/base-skill/train/` に保存する
3. scoreboard を `runs/exp_NN/base-skill/scoreboard.md` に保存する
4. ベースラインとの比較を表示する

### 3-5. ベーススキルのスナップショットを保存する

構築したベーススキルを `runs/exp_NN/base-skill/skill/` にスナップショットとして保存する。

```
=== ベーススキル構築完了 ===
分析した train ケース数: XX
更新したファイル: SKILL.md 等
```

---

## Step 4: チューニング（tuned）

### Phase A: backward + update（勾配計算 + パラメータ更新）

**base-skill/train/ の結果**（前ステップの loss）を分析し、スキルを微調整する。

```
Agent(subagent_type="backward-updater") へのプロンプト:

スキルフォルダ: {作業コピー（runs/exp_NN/skill/）の絶対パス}
train結果: {runs/exp_NN/base-skill/train/ の絶対パス}
improvement出力先: {runs/exp_NN/tuned/improvement.md の絶対パス}
スナップショット保存先: {runs/exp_NN/tuned/skill/ の絶対パス}
```

出力:
- `runs/exp_NN/skill/` — 作業コピーが直接編集済み
- `runs/exp_NN/tuned/skill/` — スナップショット
- `runs/exp_NN/tuned/improvement.md` — 変更記録

### Phase B: forward → loss（チューニング後の評価）

更新されたスキルで train 全ケースの forward → loss を実行し、チューニングの効果を計測する。

```
train 全ケースについて並列:
  1. forward-runner (background) → 完了通知
  2. 即座に loss-evaluator (background) → score.md 出力
```

#### forward（推論）

```
Agent(subagent_type="forward-runner", run_in_background=true) へのプロンプト:

スキルフォルダ: {作業コピー（runs/exp_NN/skill/）の絶対パス}
input: {input.md の絶対パス}
output: {output ファイルの絶対パス}
reasoning: {judgment-log.md の絶対パス}
```

出力先:
- `runs/exp_NN/tuned/train/{case_name}/output.*`
- `runs/exp_NN/tuned/train/{case_name}/judgment-log.md`

#### loss（損失計算）

```
Agent(subagent_type="loss-evaluator", run_in_background=true) へのプロンプト:

output: {output ファイルの絶対パス}
reference: {reference ファイルの絶対パス}
eval_config: {eval_config.md の絶対パス}（存在する場合）
score出力先: {score.md の絶対パス}
ケース名: {case_name}
```

出力先: `runs/exp_NN/tuned/train/{case_name}/score.md`

#### エージェント確認

forward-runner / loss-evaluator が解決できない場合はエラー終了する。汎用エージェントへのフォールバックは禁止。
デプロイ後、Agent(subagent_type="forward-runner", prompt="ping") で疎通確認を行う。

### Phase C: scoreboard（スコア表示）

scoreboard を `runs/exp_NN/tuned/scoreboard.md` に保存し、画面にも表示する:

```
=== チューニング結果 ===

[Train]  case_01: 82.5 | case_02: 78.0 | case_03: 81.2 | 平均: 80.6

[推移]
  ステップ       | train平均 | 判定
  ---------------+-----------+------
  without-skill  | 65.0      | ベースライン
  base-skill     | 72.2      | +7.2
  tuned          | 74.5      | +2.3
```

---

## Step 5: 結果まとめ

### ベストモデルの選択

without-skill / base-skill / tuned の中で train スコアが最も高いステップのスナップショットを「ベストモデル」とする。tuned がベストでない場合（リグレッション）は、ベストモデルのスナップショットで作業コピー（`runs/exp_NN/skill/`）を上書きする。

**元のスキルフォルダ (`.claude/skills/{skill-name}/`) は自動では更新しない。** ユーザーが明示的にデプロイを指示した場合のみ、ベストモデルを元スキルフォルダにコピーする。

### results.md

`runs/exp_NN/results.md` に統合レポートを生成する:

```markdown
# Experiment Report — exp_NN

## スコア推移

| ステップ | {case_01} | {case_02} | ... | 平均 | 判定 |
|----------|-----------|-----------|-----|------|------|
| without-skill | XX.X | XX.X | ... | XX.X | ベースライン |
| base-skill    | XX.X | XX.X | ... | XX.X | +X.X |
| tuned         | XX.X | XX.X | ... | XX.X | +X.X |

## 軸別スコア（ベストモデル）

| ケース | {軸1} | {軸2} | ... | 総合 |
|--------|-------|-------|-----|------|
| {case_01} | XX.X | XX.X | ... | XX.X |
| ...    |       |       |     |      |
| **平均** | **XX.X** | **XX.X** | ... | **XX.X** |

## ベストモデル

{ステップ名}（train平均: XX.X）

## 改善内容

{improvement.md の要約 — チューニングで何を変えたか}

## 残った課題

{低スコアケースの分析 — なぜ低いか、何が改善できそうか}
```

各ステップの scoreboard.md はそのまま残す（途中経過の記録）。results.md は全ステップの情報を統合した最終レポート。

### 完了メッセージ

```
=== チューニング完了 ===
ベストモデル: {ステップ名}（train平均: XX.X）
作業コピー: runs/exp_NN/skill/
元スキルにデプロイするには明示的に指示してください
```
