# 再設計の状況

ブランチは `refactor/design-alignment`(分岐元 `version4.0`)です。この文書の基準コミットは `faa2d13`、日付は 2026-11-02 です。

移行の方法は [v4-migration.md](v4-migration.md) にあります。この文書には、テスト結果、未決事項、数値の変化の記録を書きます。

## テスト

**確認済み(`faa2d13`、2026-11-02、MATLAB R2026a):** 想定外の失敗はありません。

```
合計 613 件: PASS 612 / KNOWN 0 / FAIL 0 / FIXED? 0 / SKIP 1   (803 s)
```

| 機能別 | 件数(PASS) | | Issue 別 | 件数(PASS) |
|---|---:|---|---|---:|
| F1 | 29 | | I50 | 7 |
| F2 | 18 | | I51 | 17 |
| F3 | 44 | | I52 | 10 |
| F4 | 30(他に SKIP 1) | | I53 | 6 |
| F5 | 6 | | I54 | 5 |
| F6 | 37 | | I55 | 8 |
| F7 | 54 | | I56 | 13 |
| F8 | 23 | | I57 | 8 |
| F9 | 12 | | I58 | 5 |
| F10 | 10 | | I60 | 6 |
| F15 | 7 | | I61 | 8 |
| F16 | 27 | | I62 | 15 |
| F17 | 9 | | I63 | 5 |
| F18 | 10 | | I64 | 6 |
| F19 | 13 | | I66 | 11 |
| F21 | 13 | | I67 | 11 |
| F22 | 25 | | I68 | 4 |
| F24 | 7 | | I69 | 5 |
| F25 | 4 | | I70 | 7 |
| F26 | 2 | | I71 | 11 |
| | | | I89 | 8 |
| | | | I90 | 13 |
| | | | I91 | 7 |
| | | | I92 | 15 |
| | | | I93 | 7 |
| | | | I102 | 6 |
| | | | I105 | 5 |
| | | | I111 | 3 |

- **SKIP:** F4 の `ACAndDCOPFAgreeWithMATPOWEROnIEEE14_bus` です。理由は `MATPOWER (runopf) がパスに無い` です。この比較は実際の MATPOWER ではまだ実行していません。case14 の最適値(8081.53 / 7642.59 $/hr)は MATPOWER なしで検査しています。
- **既知の不具合:** `DebugScript.known_failures` に該当するテストはありません(KNOWN 0)。
- **対話操作:** `+DebugScript/manual_F9_interactive.m` は手動の確認用で、上の結果に含まれません。今回は実行していません。

### 再現手順

MATLAB、Control System Toolbox、Optimization Toolbox が必要です。GUILDA のフォルダで次を実行します。`matlab` はお使いの MATLAB の実行ファイルです。約 13 分かかりました。

```
matlab -batch "DebugScript.run_all"
```

## 未決事項

状態は `faa2d13` のコードと履歴で確認しました。

### チュートリアル

- **未対応(確認済み):** `_GUILDAtutorial/*.mlx` の最後の変更は 2026-07-24 で、再設計の変更を反映していません。Issue #113「Update the tutorials to the current model building API」は開いています(2026-11-02 に確認)。
- **実行での確認は古い基準のものです:** `df3f709` の調査で、`Step2` と早見表の呼び出しは実行すると失敗しました。`power_network`, `add_controller_global`, `set_component` などの旧 API です(詳細は [model-building-workflow.md](model-building-workflow.md))。`faa2d13` では再実行していません。
- **更新の途中のブランチ:** `docs/tutorial-steps-1-3-v4`, `docs/tutorial-steps-4-6-v4`, `docs/tutorial-classmanual-v4` は仕様が固まるまで保留です。統合ブランチに対して大きく遅れており(`docs/tutorial-steps-1-3-v4` で 375 コミット)、リモートには公開されていません。再開するときは、[v4-migration.md](v4-migration.md) の 1.4, 1.6, 1.12, 1.17 と照合してください。
- **読者への注意:** 現時点で、チュートリアルを v4 の使い方の手本にしないでください。

### 互換コードの一括削除

- `COMPAT(v3)` のフックは 25 行です(`grep -rn "COMPAT(v3)" _GUILDAsystem _GUILDAobject @GUILDA`)。ロジックは `_GUILDAsystem/_VersionSupport/` にあります。
- **未検証:** [v4-migration.md](v4-migration.md) の「Removing compat code in one step」を実行したのは第 1 段階の後だけです。以後は手順を実行しておらず、削除するテストの一覧はテストを読んで増やしたものです。

### 同梱ネットワーク

- `IEEE14bus`, `IEEE14bus_NoTap`, `IEEE14bus_lossless`, `Ishizaki6Bus`, `TEST31bus`, `Txt3Bus` には `network/parameter.csv` がないので、既定の基準値(`GUILDA.config("Model","Hz")`、100 MVA)で読み込みます。`IEEE9bus` と `IEEE68bus` にはあります。

### OPF

要件とロードマップは [opf-requirements.md](opf-requirements.md) にあります。

- **完了:** 段階 1(正しさの修正)と段階 2(`set_opffcn`)です。変更点は [v4-migration.md](v4-migration.md) 1.9 にあります。
- **未着手:** 段階 3 の外部バックエンド(`prob2struct` 経由の CPLEX / Gurobi、`tools.network_to_mpc` 経由の MATPOWER)です。
- **先送り:** 多期間 OPF です。設計上の問いは opf-requirements.md にあります。
- 記録: 開始点は母線の `V0` / `Varg0` です。潮流による開始点は測定して採用しませんでした。反復が減らず(9 母線 43 → 43、IEEE14 59 → 72)、`calculate_powerflow` がスラック母線を設定して系統を編集することがあるためです。

### 解析結果と編集

- **未実装:** 結果は、解析の後に系統が編集されたかを記録しません。`tab_editLog` は `initialize` で消えるので、刻印には使えません。提案は [get-sys-improvements.md](get-sys-improvements.md) の ED5 です。

### 保守者の判断を待つ問い

各ノートの判断の節に、質問と現状があります。

| ノート | 未決の問い |
|---|---|
| [model-building-improvements.md](model-building-improvements.md) §8 | Q3(モデルの残差をいつエラーにするか)、Q10(数値の添字)、Q11(外部クラスの登録)、Q12(1 機器 1 系統の枠)、Q13(未完成のクラスの整理) |
| [get-sys-improvements.md](get-sys-improvements.md) §7 | Q8(使われていないコードの削除)、Q9(線形化の疎行列)、Q10(編集の刻印)、Q11(UX シートの記入) |
| [simulate-improvements.md](simulate-improvements.md) §8 | Q1(`Solver` の不一致は保留と記録)、Q8、Q12、Q13。Q8 以降はこのノートに未回答と記録されています。`faa2d13` のコードとの照合はしていません |

## 解決済みの項目

以前この文書で未決だった項目です。

- **`TimeLimit`:** 実行全体の上限として実装済みです(`e0b6d97`)。既定は `Inf` です。`test_I55_time_limit.m` で確認しています。
- **Hz と baseMVA の編集:** Hz は `f_*` だけを古くし、baseMVA は平衡点も古くします(`LayerPackage`)。`_GUILDAdoc/developer/class-design.html` の編集の表にも行があります。

## IEEE14 のデータと CSV のタップ

[v4-migration.md](v4-migration.md) 1.15 が参照する数値の記録です。古いスクリプトの結果と比べるときに使います。各行の値は記載のコミットの時点の計算で、`faa2d13` では再計算していません。F8 のテストは現在の母線電圧、OPF コスト、最も遅い固有値を固定しています。

- **CSV のタップ:** `PowerNetwork.import_csv` は `tap` / `phase` 列を読み、`Tap` / `Phase` も受け付けます。両方あると `GUILDA:import_csv:DuplicateColumns` です。以前は読み込んだタップがすべて 1 でした(IEEE14 の 4-7, 4-9, 5-6 など)。
- **`IEEE14bus` は MATPOWER `case14` に一致します**(100 MVA)。`C` は case14 の b の半分、負荷の Q は −Qd、母線の `Vmin` / `Vmax` は 0.94 / 1.06、発電機の上下限、コストは `HP = c2·100²`、`fP = c1·100`、負荷のコストは 0 です。Ybus は case14 と 1e-14 で一致し、潮流の発電機 Q は `runpf(case14)` の値(−16.55, 43.56, 25.08, 12.73, 17.62 MVAr)、AC / DC OPF は 8081.53 / 7642.59 $/hr です。
- **意図して残した点:** すべての発電機(母線 3, 6, 8 の調相機を含む)は 1 組の動特性の `gen-park` です。母線 7 の負荷は 0 です。ブランチ 7-9 は `pi` 線路です(case14 でタップ 1)。
- **`IEEE14bus` の修正前との差**(`63bc5a0` のコードで計算): 母線電圧は最大 0.052 pu(母線 14)、角度は 0.82°、スラックの P は 232.86 → 232.39 MW です。発電機母線の無効電力は (−34.3, −8.7, −13.9, −12.0, 3.1) → (−16.6, 30.9, 6.1, 5.2, 17.6) MVAr です。ELD / DC OPF の配分は各 51.8 MW(コスト 2.66)→ 221.0 / 38.0 / 0 / 0 / 0 MW(7642.59 $/hr)、AC OPF のコストは 2.68 → 8081.52 $/hr です。最も遅いモードは −0.535 → −0.540、最小の減衰比は 0.037 → 0.035 です。母線 8 は潮流で 1.09 pu となり `Vmax` 1.06 を超えますが、case14 と同じです(潮流は上下限を課しません)。
- **`IEEE14bus_NoTap`** は `IEEE14bus` の変圧器 4-7, 4-9, 5-6 をタップ 1、位相 0 にしたものです。`IEEE14bus` との差: 母線電圧は最大 0.015 pu(母線 5)、角度は 0.45°、AC OPF のコストは 8079.95 と 8081.52 $/hr、最も遅いモードは −0.530 と −0.540 です。
- **`IEEE14bus_lossless` のタップ修正の影響**(データは旧来のまま): 母線電圧は最大 0.016 pu(母線 5)、角度は 0.15°、母線の無効電力は最大 27.9 MVAr、最も遅いモードは −0.332 → −0.385 です。B008 の故障後の ω の差は 1.5e-4(ピーク 1.6e-3)、OPF のコストは不変です。
- **`IEEE14bus_lossless` は現在 `IEEE14bus` の R = 0 版です。** タップを修正した旧データとの差(`2723422` のコードと `fe1e5c3` の CSV で計算): 母線電圧は最大 0.054 pu(母線 14)、角度は 0.33°、スラックの P は不変(219.0 MW、損失なし)、最も遅いモードは −0.385 → −0.595、最小の減衰比は 0.037 → 0.035 です。ELD / DC / AC OPF のコストは 2.66 → 7642.59 $/hr で、損失がないので 3 つとも同じです。
