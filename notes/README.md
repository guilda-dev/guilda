# notes/

統合ブランチ `refactor/design-alignment` で進めている GUILDA の再設計の作業ノートです。

**利用者向けの文書ではありません。** 何が変わったか、何が未決か、スクリプトとモデルをどう移行するかを、開発の間だけ記録します。経緯を知らない共同開発者が単独で読めるように書きます。結果や状態には基準コミットと日付を添え、確認済み、未確認、未決を区別します。

## 現在の状態と移行

- [status.md](status.md): テスト結果と未決事項。
- [v4-migration.md](v4-migration.md): スクリプト作者とモデル作者向けの移行ガイド、非推奨の形、互換性の方針。
- [naming-struct-string.md](naming-struct-string.md): 構造体(`sct_`)と文字列(`s_`/`sv_`/`sr_`)の接頭辞への改名の対応表。

## コードの問題の記録

- [dev-pages-code-findings.md](dev-pages-code-findings.md): For Developer のクラスと機能のページを書く途中で見つかったコードと文書の問題(バグ、仕様・コメント不一致、整理)。

## 要件

- [opf-requirements.md](opf-requirements.md): OPF の要件、ロードマップ、未決の設計事項。
- [powerflow-options.md](powerflow-options.md): 潮流計算のオプション、Method クラス、ウォームスタートとキャッシュ、`V0`/`Varg0` の廃止、`operation` 制約の扱いの仕様。
- [fixed-input.md](fixed-input.md): `initialize` の Method="FixedInput"(入力 u を固定した平衡点)、`rv_Uequilibrium` の編集、アルゴリズムの選択の `Solver` への改名、線形化の `Algorithm` から `Method` への改名の仕様。
- [controller-signal-routing.md](controller-signal-routing.md): 機器・局所制御器・大域制御器の信号構造(母線電流 I の廃止、出力の直達の禁止、GC の観測と出力の振り分け、DAE の右辺の評価順)の仕様。

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
- 同梱ネットワークと文献の結果の比較: `_GUILDAverification/<network>/`(条件、モデルの違い、一致数の日付つきの記録は各 `README.md`)。
- 新しいクラス、機能、修正の利用者向けのお知らせ: ホームタブの Update log(`_GUILDAdoc/database/list_UpdateLog.js`)。

このフォルダは、再設計のリリース時に削除するか、リリースノートと文書へまとめます。
