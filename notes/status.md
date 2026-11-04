# 再設計の状況

この文書の基準は `feature/ieej-report-models` の `a9afe24`、日付は 2026-11-04 です。このブランチは統合ブランチ `refactor/design-alignment`(分岐元 `version4.0`)を `bf7512b` まで取り込み、IEEJ の報告書モデルの作業を加えたものです。`refactor/design-alignment` のその後の 4 コミット(`c51e1ea` の解析クラスの改名、`cf42421` の開発者向け文書の日英切り替えと、それぞれのマージ)は含みません。

移行の方法は [v4-migration.md](v4-migration.md) にあります。この文書には、テスト結果、未決事項、数値の変化の記録を書きます。

## テスト

**確認済み(2026-11-04、MATLAB R2026a):** 想定外の失敗はありません。

- `a9afe24` での `DebugScript.run_all`: 684 件、PASS 682 / KNOWN 1 / FAIL 0 / FIXED? 0 / SKIP 1、851 s(コーディネータの実行。機能別の内訳はこの記録にありません)。
- 下の機能別の表は、`a9afe24` に `docs/ieej-report-models-notes` の変更(F6 のコメント、`_GUILDAverification/` の比較関数と README、notes)を加えた作業ツリーでの再実行です。合計は上と同じです。時間は他の MATLAB 3 つと並行したためで、目安になりません。

```
合計 684 件: PASS 682 / KNOWN 1 / FAIL 0 / FIXED? 0 / SKIP 1   (968 s)
```

| 機能別 | 件数(PASS) | | Issue 別 | 件数(PASS) |
|---|---:|---|---|---:|
| F1 | 29 | | I50 | 7 |
| F2 | 18 | | I51 | 16 |
| F3 | 46 | | I52 | 10 |
| F4 | 30(他に SKIP 1) | | I53 | 6 |
| F5 | 6 | | I54 | 5 |
| F6 | 40 | | I55 | 8 |
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
| F22 | 34(他に KNOWN 1) | | I68 | 4 |
| F24 | 7 | | I69 | 5 |
| F25 | 4 | | I70 | 7 |
| F26 | 2 | | I71 | 11 |
| F27 | 4 | | I89 | 8 |
| F28 | 7 | | I90 | 13 |
| F29 | 13 | | I91 | 7 |
| F30 | 22 | | I92 | 15 |
| F31 | 11 | | I93 | 7 |
| | | | I102 | 6 |
| | | | I105 | 5 |
| | | | I111 | 3 |

- **SKIP:** F4 の `ACAndDCOPFAgreeWithMATPOWEROnIEEE14_bus` です。理由は `MATPOWER (runopf) がパスに無い` です。この比較は実際の MATPOWER ではまだ実行していません。case14 の最適値(8081.53 / 7642.59 $/hr)は MATPOWER なしで検査しています。
- **既知の不具合(KNOWN 1):** F22 の `AVR_DC1WithItsDefaultGainHasAFiniteEquilibrium` です。`AVR_DC1` の既定 `kap = 0` では `Vref = Inf` になり、`simulate` が MATLAB のエラーで止まります(`DebugScript.known_failures`)。
- **追加されたテスト:** F27(park の `Xq_p = Xq`)、F28(`AVR_DC1` の界磁電圧の上下限)、F29(ブランチ開放)、F30(調速機)、F31(`Scenario`)。
- **対話操作:** `+DebugScript/manual_F9_interactive.m` は手動の確認用で、上の結果に含まれません。今回は実行していません。
- **`_GUILDAverification/` は `run_all` に含まれません。** 比較の結果は下の「IEEJ のネットワーク」にあります。

### 再現手順

MATLAB、Control System Toolbox、Optimization Toolbox が必要です。GUILDA のフォルダで次を実行します。`matlab` はお使いの MATLAB の実行ファイルです。約 14 分かかりました(`a9afe24`)。

```
matlab -batch "DebugScript.run_all"
```

## `a9afe24` までに加わった機能

`fe9aa3a`(前回の基準)以後に `feature/ieej-report-models` へ入ったものです。コミットとテストで確認しました。

- **park の `Xq_p = Xq`:** `get_equilibrium` が `Xq - Xq_p` と `Xd - Xd_p` で割らなくなり、q 軸の過渡回路のない機械(IEEJ の LGT=4)を `Xq_p = Xq` で表せます(`4243124`、F27)。
- **`AVR_DC1` の界磁電圧の上下限:** `Vfld_max`(既定 `Inf`)と `Vfld_min`(既定 `-Inf`)。上下限では `Vfld` を止めるワインドアップなしの制限です。既定では軌道も `get_sys` も以前とビット単位で同じです(`8b225d2`、F28)。
- **調速機の枠と IEEJ の調速機:** 機器に `"avr"` / `"local"` の連鎖と並ぶ `"governor"` を付けられます。出力は重なってはならず(`GUILDA:Component:ControllerOutputOverlap`)、順序は連鎖、次に調速機です(`70a59ac`)。`controller.governor.IEEJ_LPT1`, `IEEJ_LPT3`, `IEEJ_LPT4`(`9733ecc`、F30)。[model-building-improvements.md](model-building-improvements.md) の Q12 の決定です。
- **ブランチ開放:** `OpenBranch`(`1d98226`、F29)。区間ごとに Y を作り直します。現在は `sc.add_open_branch` です。
- **`Scenario`(`ODEevent` の置き換え):** 系統が所有するシナリオに外乱、`Time`, `Options`, `Description`, `Judge`(既定 `Scenario.out_of_step`)を持ちます。`Scenario.compile` が区間のデータを 1 回だけ作ります(EV5)。CSV の読み書きもあります。`ODEevent(tag, net, ...)` は `_GUILDAsystem/_VersionSupport/ODEevent.m` で動き、`GUILDA:Deprecated:ODEevent` を警告します(`e543585`, `a116725`, `b870e43`, `ce78de1`、F31)。移行は [v4-migration.md](v4-migration.md) 1.18 です。
- **区間の開始の初期条件:** 微分状態を固定して代数変数だけを解きます。警告 `InitialConditionRelaxed` と緩めた再計算はなくなりました(`8bd906c`、統合は `bf7512b`)。
- **`_GUILDAverification/`:** 同梱ネットワークと文献の比較の置き場所(パスに入れない)。ネットワークごとに `README.md`、シナリオの CSV、報告書の判定の CSV、比較関数があります(`_GUILDAdoc/developer/folder-structure.html`)。

## IEEJ のネットワーク

`network.IEEJ_EAST10`, `IEEJ_EAST30`, `IEEJ_WEST10`, `IEEJ_WEST30` は、電気学会の報告書のモデルを既定にしました。調速機あり(`Governor=true`)、励磁の界磁電圧 `EF` は 0〜4 pu(`Vfld_min = 0`, `Vfld_max = 4`)、q 軸は `Xq_p = Xq` です。`Governor=false` で調速機なしにできます。

- **負荷は未決(利用者の作業待ち):** 負荷は今も定インピーダンス(`"load-impedance"`)です。報告書の NLT=2(P は 0.7 pu 以上で定電流、Q は定インピーダンス)は GUILDA にありません。利用者の ZIP 負荷モデルを待っています。
- **報告書の表との一致(各 README の記録。基準 `ae320a0`、2026-11-04、MATLAB R2026a):**

| ネットワーク | 表 | 調速機あり | 調速機なし |
|---|---|---|---|
| EAST10 | 4.3 | 33 / 44 | 35 / 44 |
| EAST30 | 4.9 | 55 / 55 | 55 / 55 |
| WEST10 | 4.5 | 9 / 26 | 9 / 26 |
| WEST30 | 4.13 | 5 / 12 | 5 / 12 |

  調速機ありの 4 つの値は、`docs/ieej-report-models-notes` の作業ツリー(`a9afe24` に比較関数の起動部分の変更を加えたもの)で全件を再実行し、同じ値を確認しました。調速機なしの値は各 README の `ae320a0` の記録です。
- **WEST30:** 平衡点はピークと夜間の両方で不安定です。定電流の P 負荷と調速機を入れたリポジトリ外の試験用のコピーでは 11 / 12 が一致しましたが、再測定していません(未確認)。
- **WEST10:** ピークの不一致の原因は特定していません(13 件中 2 件の一致)。夜間の調速機ありでは、周期 1.97 s のモードがわずかに不安定です(実部 +0.0013。クラスの説明では約 2.0 s と記載)。
- 条件、モデルの違い、事例ごとの結果は `_GUILDAverification/<network>/README.md` にあります。比較関数は、GUILDA を起動したあと `run(fullfile(GUILDA.pwd, "_GUILDAverification", "<network>", "<compare_...>.m"))` で既定の全件を、またはそのフォルダへ `cd` してオプションつきで呼び出します。4 つとも同じ方法で動きます(2026-11-04 に両方の方法で確認)。

## 未決事項

状態は `a9afe24` のコードと履歴で確認しました(下で日付や基準を別に示した項目を除く)。

### チュートリアル

- **未対応(確認済み):** `_GUILDAtutorial/*.mlx` の最後の変更は 2026-07-24 で、再設計の変更を反映していません。Issue #113「Update the tutorials to the current model building API」は開いています(2026-11-02 に確認)。
- **実行での確認は古い基準のものです:** `df3f709` の調査で、`Step2` と早見表の呼び出しは実行すると失敗しました。`power_network`, `add_controller_global`, `set_component` などの旧 API です(詳細は [model-building-workflow.md](model-building-workflow.md))。`faa2d13` では再実行していません。
- **更新の途中のブランチ:** `docs/tutorial-steps-1-3-v4`, `docs/tutorial-steps-4-6-v4`, `docs/tutorial-classmanual-v4` は仕様が固まるまで保留です。統合ブランチに対して大きく遅れており(`docs/tutorial-steps-1-3-v4` で 375 コミット)、リモートには公開されていません。再開するときは、[v4-migration.md](v4-migration.md) の 1.4, 1.6, 1.12, 1.17 と照合してください。
- **イベントの API:** チュートリアルは今も `odeEventSet` を使っています(`Step4_SimulateCondition.mlx` で確認)。`ODEevent` も `Scenario` も使っていません。#113 の保留中のブランチも含めて、更新するときは [v4-migration.md](v4-migration.md) 1.18 と照合してください。
- **読者への注意:** 現時点で、チュートリアルを v4 の使い方の手本にしないでください。

### モデル実装の文書

- **追加済み(確認済み):** `_GUILDAdoc/developer/model-implementation.html` は `4d1336e` で追加しました。新しいモデルの実装手順、契約、最小の発電機と制御器、`validate` による確認を説明しています。
- Issue #114「Document how to implement new models」は開いています(2026-11-02 に確認)。

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

### `Scenario` の未確認の既定

`Scenario` の実装者が既定として選び、保守者がまだ確認していない点です(v4-migration.md 1.18)。

- `ODEevent` の互換で、同じ系統に同じタグの `ODEevent` を作り直すと、前のものを置き換えます(系統から外れて実行できなくなります)。
- 互換の返り値は `Scenario` で、`ev.TimeSpan` などの旧プロパティはありません(`ev.tab_disturbance` の列として読むだけ)。
- `sc.simulate` はありません。実行は `net.simulate(sc)` です。
- 判定(`sc.judge`)は `net.simulate` の `output` に入りません。

### 解析結果と編集

- **未実装:** 結果は、解析の後に系統が編集されたかを記録しません。`tab_editLog` は `initialize` で消えるので、刻印には使えません。提案は [get-sys-improvements.md](get-sys-improvements.md) の ED5 です。

### 保守者の判断を待つ問い

各ノートの判断の節に、質問と現状があります。

| ノート | 未決の問い |
|---|---|
| [model-building-improvements.md](model-building-improvements.md) §8 | Q3(モデルの残差をいつエラーにするか)、Q10(数値の添字)、Q11(外部クラスの登録)、Q13(未完成のクラスの整理)。Q12 は 2026-11-04 に変えると決まり、実装済みです |
| [get-sys-improvements.md](get-sys-improvements.md) §7 | Q8(使われていないコードの削除)、Q9(線形化の疎行列)、Q10(編集の刻印)、Q11(UX シートの記入) |
| [simulate-improvements.md](simulate-improvements.md) §8 | Q1(`Solver` の不一致は保留と記録)、Q8、Q12。Q13 のブランチ開放は EV5 より前に実装され、EV5 はその後 `Scenario.compile` として実装されました(同ノートの「その後の実装」) |

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
