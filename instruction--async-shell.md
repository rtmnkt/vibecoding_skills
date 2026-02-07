# async-shell 改修指示書

## 概要

async-shellスキルを改修する。上位スキル（タスクスキル等）から利用されることを考慮した設計にする。

## 現状の問題

1. **sendコマンドの問題**: `tmux send-keys "text" Enter` を一括で送ると、TUI（Claude CLI等）でEnterが改行として扱われ送信されない。別々のtmux callで解決済み。

2. **tmux直接使用**: Claudeがtmux知識を持っているため、スクリプトを無視して直接tmuxコマンドを使ってしまう。

3. **ペイン多用**: ペインを基本として使用していたが、tmux階層の適切な使い方ではない。

## 改修方針

### tmux階層の正しい使い方

```
セッション（Session）
  └─ ウィンドウ（Window）← バックグラウンドタスク管理の基本単位
       └─ ペイン（Pane）← 同時表示が必要な時のみ
```

- バックグラウンドシェル管理: ウィンドウまたはセッション
- ペイン: ユーザー指示で明示的に使う場合のみ（便利エイリアス的）

### コマンド体系

| コマンド | 説明 |
|----------|------|
| `type <target> <text>` | テキスト入力（Enterなし） |
| `key <target> <key...>` | 特殊キー送信（複数可） |
| `submit <target>` | Enter → 3秒待機 → capture |
| `capture <target>` | 表示領域を行番号付きで取得 |
| `history <target> [lines]` | スクロールバッファ含め行番号付き |

旧 `send` / `sendraw` は削除。

### ファイル構成

```
async-shell/
├── SKILL.md
├── scripts/
│   ├── async_shell.sh              # インターフェース + 環境検出
│   ├── async_shell--impl-tmux.sh   # tmux実装
│   └── async_shell--impl-screen.sh # screen実装
└── references/
    ├── commands.md                 # コマンド仕様
    └── cli--claude.md              # Claude CLI操作パターン
```

- `references/tmux.md`, `references/screen.md` は削除（Claude直接参照防止）
- 将来的に `cli--codex.md` 等を追加可能

### SKILL.md構成

**description**: トリガーフレーズを含める
```
Coordinate with interactive async agents in separate contexts. Run another Claude in separate pane for second opinion, objective review, pair programming, or parallel tasks. Also for background process management.
```

**本文構成**:
1. 目的起点のAsync Agent Patterns
   - objective_review: 客観的視点、コンテキストバイアス回避
   - delegate_task: 単純タスク委譲、トークン節約
   - parallel_execution: 並列独立タスク
   - interactive_dialogue: ペアプロ、対話的協調

2. Basic Operations
   - run_background_process
   - check_state
   - send_input
   - cleanup

3. Implementation（スクリプトとreferencesへの誘導）

### 設計原則

1. **入力と確定の分離**: `type`は絶対にEnterを送らない
2. **行番号付きcapture**: 状態確認を容易に
3. **スクリプト強制**: SKILL.mdで「必ずスクリプト経由で」と明記、tmux直接言及を排除
4. **抽象化維持**: 実装（tmux/screen）は差し替え可能

## 上位スキルからの利用を考慮した設計

タスクスキル等から以下の用途で使用される想定:

1. **サブエージェント起動**: `split` でClaude CLIを別ウィンドウで起動
2. **タスク状態確認**: `capture` で進捗確認（ポーリング最小化のため結果ファイル併用を推奨）
3. **入力送信**: `type` + `submit` または `type` + `key Enter`

async-shellはタスクスキル等の詳細を知らないこと（依存方向を逆にしない）。

## 検証項目

1. `type` + `key Enter` でClaude CLIに正しく送信されるか
2. `split` 後にフォーカスが元のペイン/ウィンドウに残るか
3. `capture` の行番号が正しく付与されるか
4. tmux/screen両方で動作するか

## 参考: 元の会話で解決済みの技術的問題

- `tmux send-keys "text" Enter` を一括送信 → Claude CLIでは改行になる
- 解決: `tmux send-keys "text"` と `tmux send-keys Enter` を分離
