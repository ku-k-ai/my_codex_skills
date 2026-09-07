# my_codex_skills

個人用の Codex Skills をまとめたリポジトリです。2026-09-03 時点で、公開・再配布できる37スキルを収録しています。

## Skills

| Skill | 概要 |
|---|---|
| [`archify`](./archify/) | アーキテクチャ、ワークフロー、シーケンス、データフロー、状態遷移を検証可能なHTML図にします。 |
| [`ask-matt`](./ask-matt/) | Matt Pocock系スキルから、状況に合うスキルや進め方を案内します。 |
| [`code-review`](./code-review/) | 変更をコーディング規約と仕様適合の2軸で並行レビューします。 |
| [`codebase-design`](./codebase-design/) | deep moduleを中心に、境界・インターフェース・テスト容易性を設計します。 |
| [`consulting-pptx-skill`](./consulting-pptx-skill/) | 約80項目のスライド規約、38型SlideSpec、生成パイプライン、機械QAで、経営会議・提案書向けの編集可能PPTXを作ります。 |
| [`diagnosing-bugs`](./diagnosing-bugs/) | 難しい不具合や性能劣化を、再現と仮説検証のループで診断します。 |
| [`domain-modeling`](./domain-modeling/) | ドメイン用語、`CONTEXT.md`、ADRを整備してモデルを明確にします。 |
| [`eli5`](./eli5/) | 初学者向けに、大きな絵と少ない言葉のHTMLでテーマを説明します。 |
| [`grill-me`](./grill-me/) | 計画や設計を厳しく質問し、曖昧さを削ります。 |
| [`grill-with-docs`](./grill-with-docs/) | 計画を厳しく検討しながら、ADRや用語集も残します。 |
| [`grilling`](./grilling/) | アイデア、判断、計画を対話で徹底的にストレステストします。 |
| [`handoff`](./handoff/) | 現在の会話を、別エージェントが継続できる引き継ぎ文書に圧縮します。 |
| [`hatch-pet`](./hatch-pet/) | Codex互換v2アニメーションPetを作成・修復・検証・パッケージ化します。 |
| [`implement`](./implement/) | 仕様書またはチケットに基づいて実装を進めます。 |
| [`improve-codebase-architecture`](./improve-codebase-architecture/) | コードベースのdeepening候補を可視化し、改善対象を絞ります。 |
| [`my-orchestrate`](./my-orchestrate/) | 独立した調査・実装を並列に進める場合や、設計・変更に独立レビューが必要な場合に、役割に応じたCodexサブエージェントを選び、結果を統合する。 |
| [`orchestrate`](./orchestrate/) | 大規模作業を複数エージェントへ分割し、結果を統合します。 |
| [`prototype`](./prototype/) | 状態モデル、ロジック、UIなどの設計判断を使い捨て試作で検証します。 |
| [`requirements_flow_alignment_skill`](./requirements_flow_alignment_skill/) | 目的、利用Flow、画面、データFlow、現行実装を分けて要件認識を合わせます。 |
| [`research`](./research/) | 信頼性の高い一次情報を調査し、Markdownへ記録します。 |
| [`resolving-merge-conflicts`](./resolving-merge-conflicts/) | 進行中のGit merge/rebase conflictを安全に解消します。 |
| [`retro`](./retro/) | コーディングセッションを振り返り、今後のエージェント環境の改善候補を提示します。 |
| [`setup-matt-pocock-skills`](./setup-matt-pocock-skills/) | Matt Pocock系エンジニアリングスキル用のissue tracker、ラベル、文書構成を初期化します。 |
| [`show-me`](./show-me/) | 図、ツリー、コード形状、HTMLでテーマを視覚的に説明します。 |
| [`skill-doctor`](./skill-doctor/) | ローカルの会話履歴を採点し、Skillの具体的な改善案とレポートを作成します。 |
| [`skill-publish`](./skill-publish/) | 個人用Skillの導入・更新と、公開可能な差分のGit同期を一つの流れで行います。 |
| [`social-fetch`](./social-fetch/) | SNS投稿を複数手段で取得し、共通形式に正規化します。 |
| [`tdd`](./tdd/) | red-green-refactorで機能追加や不具合修正を進めます。 |
| [`teach`](./teach/) | このワークスペース内で新しいスキルや概念を教えます。 |
| [`to-questionnaire`](./to-questionnaire/) | 未解決の判断事項を、他者が回答できる質問票に変換します。 |
| [`to-spec`](./to-spec/) | それまでの会話を仕様書にまとめ、issue trackerへ公開します。 |
| [`to-tickets`](./to-tickets/) | 計画や仕様を依存関係付きのtracer-bullet ticketsへ分解します。 |
| [`triage`](./triage/) | issueと外部PRを状態機械として分類・検証・整理します。 |
| [`wait-what`](./wait-what/) | 直前の説明が伝わらなかったとき、別の切り口で説明し直します。 |
| [`wayfinder`](./wayfinder/) | 1セッションを超える大規模作業を、意思決定チケットの地図として計画します。 |
| [`wizard`](./wizard/) | 人間だけが実施できる手順を案内する対話型Bash wizardを生成します。 |
| [`writing-for-agents`](./writing-for-agents/) | Skill、`AGENTS.md`、`CLAUDE.md`など、エージェント向け文書を設計します。 |



## Installation

リポジトリをcloneし、必要なSkillフォルダーをCodexの個人用Skillsフォルダーへコピーします。

```powershell
git clone https://github.com/ku-k-ai/my_codex_skills.git
Set-Location .\my_codex_skills

$codexSkills = Join-Path $env:USERPROFILE '.codex\skills'
Copy-Item -Recurse -Force .\social-fetch $codexSkills
Copy-Item -Recurse -Force .\show-me $codexSkills
Copy-Item -Recurse -Force .\orchestrate $codexSkills
```

すべてインストールする場合:

```powershell
$codexSkills = Join-Path $env:USERPROFILE '.codex\skills'
Get-ChildItem -Directory | ForEach-Object {
    Copy-Item -Recurse -Force $_.FullName $codexSkills
}
```

コピー後、新しいCodexタスクから利用してください。Codexは依頼内容に合うSkillを自動選択できます。確実に指定する場合は、メッセージ内で `$social-fetch` のように `$` 付きで指定します。

## Sync scope

- 同期元は個人管理領域 `~/.codex/skills` の直下です。
- OpenAI管理領域の `.system` は含めません。
- プラグインキャッシュやアプリ同梱Skillは含めません。
- `pptx` は同梱の独自ライセンスが複製・配布を禁止しているため、この公開リポジトリには含めません。
- `consulting-pptx-skill` はMITライセンスの別Skillで、コンサル資料の新規作成・ストーリー設計・品質QAに特化しているため収録します。
- APIキー、Cookie、取得データ、`.env`、秘密鍵などはcommitしないでください。

## Event-driven sync

Codexの `PostToolUse` Hookが、Skillの追加・更新を行ったツール実行の直後だけ `~/.codex/skills` とこのリポジトリを比較します。定期監視や1時間ごとのポーリングは行いません。

既に公開承認済みのSkillは差分をcommitして `main` へpushします。新規Skillは `.codex-skill-sync.json` に出典と再配布確認を記録し、必要なライセンス、秘密情報検査、frontmatter、付随ファイルを検証できた場合だけ公開します。ライセンス不明、再配布禁止、秘密情報、削除、dirty worktree、non-fast-forwardは自動処理せず、`~/.codex/hooks/state/skill-sync/sync.log` に保留理由を残します。

## Provenance and licenses

このリポジトリは複数ライセンスです。各Skillフォルダーのライセンス表示が、そのSkillに適用されます。

| Skills | Upstream | License |
|---|---|---|
| `ask-matt`, `code-review`, `codebase-design`, `diagnosing-bugs`, `domain-modeling`, `grill-me`, `grill-with-docs`, `grilling`, `handoff`, `implement`, `improve-codebase-architecture`, `prototype`, `research`, `resolving-merge-conflicts`, `retro`, `setup-matt-pocock-skills`, `tdd`, `teach`, `to-questionnaire`, `to-spec`, `to-tickets`, `triage`, `wait-what`, `wayfinder`, `wizard`, `writing-for-agents` | [mattpocock/skills](https://github.com/mattpocock/skills) | MIT。各フォルダーの `LICENSE.upstream` に原文を同梱 |
| `skill-doctor` | [warpdotdev/common-skills](https://github.com/warpdotdev/common-skills/tree/main/.agents/skills/skill-doctor) | MIT。`skill-doctor/LICENSE.upstream` に原文を同梱 |
| `eli5` | [anthropics/claude-plugins-community](https://github.com/anthropics/claude-plugins-community/tree/main/eli5/skills/eli5) | リポジトリルートのApache License 2.0を安全側で適用し、`eli5/LICENSE.upstream` に同梱。プラグインメタデータ上はMIT表記 |
| `skill-publish` | ローカルの個人用Skill | リポジトリ所有者が作成した個人用Skill |
| `social-fetch` | [coreyhaines31/makerskills](https://github.com/coreyhaines31/makerskills/tree/main/skills/social-fetch) | MIT。`social-fetch/LICENSE.upstream` に原文を同梱 |
| `show-me` | [humanlayer/skills](https://github.com/humanlayer/skills/tree/main/plugins/show-me/skills/show-me) | MIT。`show-me/LICENSE.upstream` に原文を同梱 |
| `archify` | [tt-a1i/archify](https://github.com/tt-a1i/archify) | MIT。`archify/LICENSE` を参照 |
| `consulting-pptx-skill` | [gozen3ji/consulting-pptx-skill](https://github.com/gozen3ji/consulting-pptx-skill) | MIT。Codex起動条件、Windows互換修正、同梱サンプル整合化を追補し、`consulting-pptx-skill/LICENSE.upstream` に原文を同梱 |
| `hatch-pet` | ローカルにインストールされた配布物 | Apache License 2.0。`hatch-pet/LICENSE.txt` を参照 |
| `orchestrate`, `requirements_flow_alignment_skill` | ローカルの個人用Skill | 上流ライセンス情報なし |
| `my-orchestrate` | ローカルの個人用Skill | All rights reserved by the repository owner |

ブランド名・ロゴの利用条件は、各権利者の商標・ブランドガイドラインにも従ってください。
