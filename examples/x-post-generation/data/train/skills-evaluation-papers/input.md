# テーマ
Skillsの評価に関連する論文・ブログ7個の紹介

# やったこと / 素材
- 以下の7つの論文・ブログを読んだ：
  1. Evaluating Skills — LangChain
     - コーディングエージェント向けのSkills評価方法
     - 成功率・実行時間・スキル呼び出し率をLangSmithで記録し比較
     - URL: https://blog.langchain.com/evaluating-skills
  2. Meta Context Engineering via Agentic Skill Evolution (MCE)
     - Skills設計そのものをAIに進化させる仕組み
     - Skillsを改善するAIと実タスク用に組み立てるAIを分ける（先生と学生のような構造）
     - 精度・汎用性・効率の向上を示した
     - URL: https://github.com/metaevo-ai/meta-context-engineering
  3. A Survey on Agent-as-a-Judge
     - LLM as a Judgeのような単純な自動採点ではなく「複数エージェント＋ツール＋メモリ」で評価する枠組み
     - 状況に応じて評価プロセスを変える柔軟な評価設計の重要性
     - URL: https://arxiv.org/pdf/2602.20867
  4. SoK: Agentic Skills — Beyond Tool Use in LLM Agents
     - 「スキルを増やせば強くなる」ではなく「短く焦点の合った良いスキルを持つと強くなる」
     - 2〜3モジュール程度のfocused skillは改善幅が大きい
     - 網羅的すぎるcomprehensive skillはむしろ性能を落とすことがある
  5. SkillsBench: Benchmarking How Well Agent Skills Work Across Diverse Tasks
     - スキル追加で性能がどれだけ上がるかを測るベンチマーク
     - 84タスク・11ドメインで人間設計スキルと自動生成スキルの差を定量比較
  6. AutoSkill: Experience-Driven Lifelong Learning via Skill Self-Evolution
     - ユーザーとの対話や行動履歴から再利用可能なSkillsを自動生成し継続的に進化
     - モデルを再学習せずに経験をスキルとして蓄積・再利用
  7. Demystifying evals for AI agents — Anthropic
     - エージェントは非決定的・複数ターン・ツール使用・環境変更があるので従来の1問1答正誤判定では評価できない
     - 評価対象を分解し、再現可能な形で回し、複数の評価基準で採点し、実行履歴ログで妥当性確認する必要

# 結果 / データ
- 7つの論文・ブログを読んだまとめ

# 考察 / 気づき
- MCEの論文は従来のCE（コンテキストエンジニアリング）を一段上げて、Skills設計自体をAIに進化させるアプローチ
- focused skillの方がcomprehensive skillより有効という知見が興味深い
- エージェント評価は単純なLLM as a Judgeでは不十分で、より柔軟な設計が必要
