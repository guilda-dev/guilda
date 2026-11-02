# notes/

統合ブランチ `refactor/design-alignment` で進めている GUILDA の再設計の作業ノートです。

**利用者向けの文書ではありません。** 何が変わったか、何が未決か、スクリプトとモデルをどう移行するかを、開発の間だけ記録します。経緯を知らない共同開発者が単独で読めるように書きます。結果や状態には基準コミットと日付を添え、確認済み、未確認、未決を区別します。

## 現在の状態と移行

- [status.md](status.md): テスト結果と未決事項。
- [v4-migration.md](v4-migration.md): スクリプト作者とモデル作者向けの移行ガイド、非推奨の形、互換性の方針。

## 要件

- [opf-requirements.md](opf-requirements.md): OPF の要件、ロードマップ、未決の設計事項。

## 調査と改善案

各ファイルは当時の基準コミットでの記録で、本文は更新しません。冒頭に基準を示しています。改善案のファイルには、質問への対応状況を判断の節に追記しています。

| 対象 | 調査 | 改善案 |
|---|---|---|
| `get_sys` | [get-sys-workflow.md](get-sys-workflow.md)(流れ、データ、編集、引数)、[get-sys-linearization.md](get-sys-linearization.md)(数値計算と内部構造) | [get-sys-improvements.md](get-sys-improvements.md) |
| `simulate` | [simulate-review-workflow.md](simulate-review-workflow.md)(流れ、データ、編集、副作用)、[simulate-review-runtime.md](simulate-review-runtime.md)(引数、イベント、区間、内部構造)、[simulate-review-measurements.md](simulate-review-measurements.md)(挙動と性能の実測)、[simulate-review-measurements.m](simulate-review-measurements.m)(実測スクリプト) | [simulate-improvements.md](simulate-improvements.md) |
| モデル構築 | [model-building-workflow.md](model-building-workflow.md)(既存クラスからの組み立て)、[model-building-extension.md](model-building-extension.md)(新しいクラスの実装) | [model-building-improvements.md](model-building-improvements.md) |

調査文書が参照する `GUILDA_主機能UX定義シート.xlsx` はリポジトリに含まれていません。

## 他の内容の置き場所

- `_GUILDAdoc/` の HTML: 利用者と将来の開発者向けの恒久的な文書です。GUILDA の仕組みを説明し、この作業の進捗は書きません。
- 新しいクラス、機能、修正の利用者向けのお知らせ: ホームタブの Update log(`_GUILDAdoc/database/list_UpdateLog.js`)。

このフォルダは、再設計のリリース時に削除するか、リリースノートと文書へまとめます。
