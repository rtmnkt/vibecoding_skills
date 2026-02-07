# async-shell 開発資料

## 設計思想

### 基本単位

```
セッション（Session） $N
  └─ ウィンドウ（Window） @N ← バックグラウンドタスクの基本単位
       └─ ペイン（Pane） %N ← 同時表示が必要な時のみ
```

- `new` でウィンドウを作成し、`@N` で識別
- ペインは `util split` で明示的に使う場合のみ

### 抽象化

- SKILL.md に実装詳細（tmux/screen）を一切記載しない
- Claudeが直接tmuxコマンドを使うことを防止
- 将来的な実装差し替えを可能に

### 入力と確定の分離

- `type`: テキスト入力のみ、Enterを絶対に送らない
- `submit`: Enterのみ送信
- `key`: 特殊キー送信（承認応答、キャンセル等）

TUIアプリ（Claude CLI等）では `send-keys "text" Enter` を一括送信すると改行として扱われる問題があり、分離が必須。

### 責務範囲

**本スキルの責務:**
- バックグラウンドシェル作成・終了
- テキスト入力・キー送信
- 画面出力取得

**利用者の責務:**
- タスク完了検知・待機
- 結果解釈
- ポーリング戦略

---

## コマンド体系

### メインコマンド（ウィンドウ操作）

| コマンド | 説明 |
|----------|------|
| `new [cmd]` | 新ウィンドウ作成、`@N` 返却 |
| `list` | ウィンドウ一覧 |
| `type <@N> <text>` | テキスト入力（Enterなし） |
| `submit <@N>` | Enter送信 |
| `capture <@N> [-h lines]` | 出力取得 |
| `kill <@N>` | ウィンドウ終了 |
| `current` | 現在のウィンドウID |
| `help` | コマンド一覧 |

### capture オプション

| オプション | 説明 |
|-----------|------|
| `-h lines` | スクロールバッファを含める行数 |

### utilコマンド（ペイン操作）

| コマンド | 説明 |
|----------|------|
| `util split [h\|v] [cmd]` | ペイン分割、`%N` 返却 |
| `util focus <pane>` | ペイン間移動 |
| `util panes` | ペイン一覧 |

### 特殊キー

```
Enter, Escape, Tab, Up, Down, Left, Right
C-c (Ctrl+C), C-d (Ctrl+D), C-l (Ctrl+L)
```

### 連結操作

```bash
bash $SCRIPT type @N "command" && bash $SCRIPT submit @N
```

---

## ファイル構成

```
async-shell/
├── SKILL.md                        # スキル定義
├── scripts/
│   ├── async_shell.sh              # インターフェース + help
│   ├── async_shell--impl-tmux.sh   # tmux実装
│   └── async_shell--impl-screen.sh # 未実装エラーのみ
└── references/
    └── cli--claude.md              # Claude CLI操作パターン
```

---

## 変更履歴

### v1 → v2

| 項目 | v1 | v2 |
|------|-----|-----|
| 基本単位 | ペイン (`%N`) | ウィンドウ (`@N`) |
| `split` | メインコマンド | `util split` に移動 |
| `history` | 独立コマンド | `capture -h` に統合 |
| `info` | 存在 | 削除 |
| `wait` | 存在（undocumented） | 削除 |
| `commands.md` | 存在 | 削除（helpに統合） |
| screen実装 | 中途半端 | 未実装エラーのみ |

### v2 → v3

| 項目 | v2 | v3 |
|------|-----|-----|
| `submit` | Enter + 0.5s + capture | Enterのみ |
| `capture -w` | 事前待機オプション | 削除 |
| SKILL.md | interactive中心 | fire-and-forget推奨、parallel強化 |
| 完了検知 | 曖昧 | 責務外と明記 |
| new推奨 | `new "claude"` | `new "bash"` |

### v3 → v4

| 項目 | v3 | v4 |
|------|-----|-----|
| セッション管理 | なし（セッション内必須） | 自動作成（`async_shell`） |
| `ASYNC_SESSION` | なし | 環境変数でオーバーライド可能 |
| `ensure_session()` | なし | 復活（初回使用時に作成） |
| tmux外実行 | エラー | 対応（自動セッション作成） |
| `-t "$ASYNC_SESSION"` | なし | new, listで使用 |
| SKILL.md | Session Managementなし | セクション復活 |

---

## 上位スキルからの利用

タスクスキル等から以下の用途で使用される想定:

1. **サブエージェント起動**: `new "bash"` → `type @N "claude"` → `submit @N`
2. **タスク状態確認**: `capture` または結果ファイル確認
3. **入力送信**: `type @N "text" && submit @N`

async-shellは上位スキルの詳細を知らない（依存方向を逆にしない）。

---

## 将来の拡張余地

### スコープ管理

現状の問題:
- 並列agentが本スキルを使用すると、他agentのウィンドウも `list` に表示される
- 消し忘れでウィンドウが残る可能性

案: `start` / `exit` コマンドでセッション分離

### CLI拡張

`references/` に追加可能:
- `cli--codex.md`
- `cli--cursor.md`

---

## 技術的背景

### TUIでのEnter問題

```bash
# NG: 一括送信するとEnterが改行になる
tmux send-keys "text" Enter

# OK: 分離して送信
tmux send-keys "text"
tmux send-keys Enter
```

### tmux ID形式

| 種類 | 形式 | 例 |
|------|------|-----|
| セッション | `$N` | `$0`, `$1` |
| ウィンドウ | `@N` | `@1`, `@2` |
| ペイン | `%N` | `%1`, `%2` |

---

## テスト項目

1. `type @N "text"` + `submit @N` でClaude CLIに正しく送信されるか
2. `new` 後にフォーカスが元のウィンドウに残るか（`-d` オプション）
3. `capture` の行番号が正しく付与されるか
4. `capture -h 100` でスクロールバッファが取得できるか
5. `util split` 後にペインIDが正しく返却されるか
6. `submit` がEnterのみ送信しcaptureしないか
7. tmux外から実行時にセッションが自動作成されるか
8. `ASYNC_SHELL_SESSION` でセッション名をオーバーライドできるか
9. `list` と `new` が指定セッション内で動作するか
