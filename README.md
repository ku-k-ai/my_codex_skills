# my_codex_skills

個人用の Codex Skills をまとめたリポジトリです。

## Skills

| Skill | 概要 | 主な用途 | 呼び出し例 | 主な依存関係 |
|---|---|---|---|---|
| [`social-fetch`](./social-fetch/) | SNS投稿のURLを判定し、複数の取得手段を順番に試して、投稿者・本文・日時・反応数・メディアURLなどを共通形式に正規化します。 | X、LinkedIn、Instagram、TikTok、Bluesky、Reddit、Mastodon、Threads、Hacker Newsの投稿取得 | `$social-fetch https://x.com/example/status/123` | ネット接続。Xなどでは `agent-browser` を利用。詳細取得には任意で ScrapeCreators / Apify のAPIキー |
| [`show-me`](./show-me/) | 会話中のテーマを、最小限の図・ツリー・擬似コード・diff・HTMLで視覚的に説明します。 | 処理フロー、ファイル構成、UI構造、変更前後の比較 | `$show-me この処理フローを図解して` | 基本機能に必須の外部依存なし。内容に応じて Mermaid / HTML を使用 |
| [`orchestrate`](./orchestrate/) | 大きな作業を重複しない小さな担当へ分割し、複数エージェントの結果を統合するための運用Skillです。 | 調査、実装、検証を並行化したい大規模タスク | `$orchestrate このリポジトリを調査して修正して` | サブエージェントを利用できる Codex 実行環境 |

## Repository structure

```text
.
├── social-fetch/
│   ├── SKILL.md
│   ├── LICENSE.upstream
│   └── references/
├── show-me/
│   ├── SKILL.md
│   └── LICENSE.upstream
├── orchestrate/
│   ├── SKILL.md
│   └── agents/
└── README.md
```

## Installation

このリポジトリをcloneし、使いたいSkillフォルダーを Codex の個人用Skillsフォルダーへコピーします。

```powershell
git clone https://github.com/ku-k-ai/my_codex_skills.git
Set-Location .\my_codex_skills

$codexSkills = Join-Path $env:USERPROFILE '.codex\skills'
Copy-Item -Recurse -Force .\social-fetch $codexSkills
Copy-Item -Recurse -Force .\show-me $codexSkills
Copy-Item -Recurse -Force .\orchestrate $codexSkills
```

コピー後、新しいCodexタスクから利用してください。Codexは依頼内容に合うSkillを自動選択できます。確実に指定する場合は、メッセージ内で `$social-fetch`、`$show-me`、`$orchestrate` のように `$` 付きで指定します。

## Notes

- `social-fetch` の有料APIは任意です。APIキーや取得したSNSデータはこのリポジトリへcommitしないでください。
- `social-fetch` の各取得手段は、対象サービスの利用規約・レート制限に従って利用してください。
- `show-me` がHTMLを生成する場合、環境によってファイルを開くコマンドが異なることがあります。
- `orchestrate` は複数エージェント機能を利用できる環境を前提とします。

## Provenance and licenses

| Skill | Upstream | License |
|---|---|---|
| `social-fetch` | [coreyhaines31/makerskills](https://github.com/coreyhaines31/makerskills/tree/main/skills/social-fetch) | MIT License。原文を [`social-fetch/LICENSE.upstream`](./social-fetch/LICENSE.upstream) に同梱 |
| `show-me` | [humanlayer/skills](https://github.com/humanlayer/skills/tree/main/plugins/show-me/skills/show-me) | MIT License。原文を [`show-me/LICENSE.upstream`](./show-me/LICENSE.upstream) に同梱 |
| `orchestrate` | ローカルの個人用Skill | 上流ライセンス情報なし |
