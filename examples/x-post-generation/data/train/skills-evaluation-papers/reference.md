私が最近読んだ"Skillsの評価に関連する論文・ブログ"7個。

【Evaluating Skills — LangChain】
Claude Codeのようなコーディングエージェント向けに、Skillsをどう評価するかを整理したブログ。成功率・実行時間・スキル呼び出し率をLangSmithで記録し、比較できる評価方法を示している。

【Meta Context Engineering via Agentic Skill Evolution】
Skills設計そのものをAIに進化させる仕組みを提案した研究。先生と学生のように、"Skillsを改善するAIと、実タスク用に組み立てるAIを分ける"ことで、精度・汎用性・効率の向上を示している。

【A Survey on Agent-as-a-Judge】
AI評価を、LLM as a Judgeのような単純な自動採点ではなく「複数エージェント＋ツール＋メモリ」で行う枠組みを整理したサーベイ。状況に応じて評価プロセスを変える柔軟な評価設計の重要性をまとめている。

【SoK: Agentic Skills — Beyond Tool Use in LLM Agents】
面白いのは、「スキルを増やせば強くなる」ではなく、「短く焦点の合った良いスキルを持つと強くなる」と示している点。実際、2〜3モジュール程度の focused skill は改善幅が大きい一方、網羅的すぎる comprehensive skill はむしろ性能を落とすことがある。

【SkillsBench: Benchmarking How Well Agent Skills Work Across Diverse Tasks】
「スキルを追加すると性能がどれだけ上がるか」を測るためのベンチマーク。84タスク・11ドメインで、人間設計スキルと自動生成スキルの差や、スキルの有効性を定量比較できる。

【AutoSkill: Experience-Driven Lifelong Learning via Skill Self-Evolution】
ユーザーとの対話や行動履歴から再利用可能なSkillsを自動生成し、継続的に進化させる枠組みを提案した研究。モデルを再学習せずに、経験をスキルとして蓄積・再利用できる点が特徴。

【Demystifying evals for AI agents-Anthropic】
エージェントは非決定的で、複数ターンで、ツールも使い、環境の状態も変えるので、従来のLLM as a Judgeのような"1問1答の正誤判定"では評価できない。だから評価対象を分解し、再現可能な形で回し、複数の評価基準で採点し、 エージェントの実行履歴ログを見て妥当性を確認する必要がある。
