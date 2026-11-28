# デバッグテストの分類と段階の見直し

基準: `refactor/design-alignment` の 3bd90d8e (2026-11-16)。ブランチ `test/split-test-categories`。

`+DebugScript/test_F*.m`, `test_I*.m` を機能別の「分類」で束ね (`DebugScript.test_categories`)、
`DebugScript.run_all("Category", ...)` で分類単位に実行できるようにした。あわせて重複テストを整理し、
small を 1 分以内に収めるため遅いテストを medium / large へ移した。ファイルの再編成はしていない。

## 計測 (手順 1)

- `DebugScript.run_all("FailOnUnexpected",false)` (large、全件) を 1 回、R2026a で実行。
- **計測時は他のセッションのテストが同時に走っており、負荷平均は 8〜13 だった。** 時間はすべて
  この条件の値で、普段 (このノートの前の記録で large 約 15 分) の 3〜4 倍になっている。
  - 全件 934 件・3314 s (PASS 931 / KNOWN 1 / FAIL 1 / SKIP 1)
  - 段階別のテスト時間の合計: small 607 件 843 s、medium 232 件 847 s、large 95 件 1582 s
- 既存の FAIL (直していない):
  - `test_I92_network_islands/AFailedOPFOnASplitNetworkNamesTheIslands_AlsoWhenTheOPFStopsWithAnInternalError`
    — 「メッセージ識別子の引数を指定する場合は、メッセージ テキストの引数を指定しなければなりません。」
    (OPF が内部エラーで止まる経路で、error(id) の呼び方が誤っているとみられる。未調査)
- KNOWN: `test_F22_model_contract/AVR_DC1WithItsDefaultGainHasAFiniteEquilibrium` (known_failures.m に登録済み)
- SKIP: `test_F4_opf/ACAndDCOPFAgreeWithMATPOWEROnIEEE14_bus` (MATPOWER が無い)

### ファイル単位の準備の時間

- スクリプト形式のテストでは、最初の `%%` より前の共通設定が **各テストの前に毎回** 実行され、
  その時間は各テストの Time に含まれる。次のファイルは共通設定で `build_ieee14` + `initialize`
  (または組み込み系統の構築) をしており、その分 (高負荷下で 0.2〜0.3 s) が全テストに乗る:
  F5, F6, F7, F32, F33, F29, I51, I52, I53, I54, I55, I60, I61, I62, I63。
- 各ファイルの最初のテストは、クラスの読み込みなどの初回の時間 (高負荷下で 1〜3 s) が乗る。
  small に残した軽いテストでも、ファイルの先頭にあると 2〜4 s になることがある。

## 重複の整理 (手順 2)

削除・統合したテスト。検証内容 (assert の対象) は統合先に残してある。

| 削除・統合したテスト | 内容 | 同じ内容を保証するテスト |
|---|---|---|
| `test_F15_build_checks/AllBuilt_inNetworksStillBuild` (削除) | 組み込み 13 系統が構築でき、ブランチがある | `test_F16_csv_io/BuildingTheBuilt_inNetworksDoesNotWarn` (13 系統を構築し `~isempty(net.a_Branch)` も確認する形に統合)。構築の失敗は `test_I93_model_equilibrium/TheBuilt_inNetworksAreFarBelowTheThreshold_WithTheirControllers` でも検出される |
| `test_F19_model_constructor/Built_inNetworksAndTheBundledCSVDataDoNotWarnAboutQ` (削除) | 組み込み 13 系統の構築で `GUILDA:Component:GeneratorQIgnored` が出ない (警告をエラーにする) | `test_F16_csv_io/BuildingTheBuilt_inNetworksDoesNotWarn`。F16 は警告を一切出さないことを確認していたが Tutorial3bus が抜けていたので追加し、Q の警告をエラーにする設定も移した (途中で出た警告も見逃さない) |
| `test_I92_network_islands/TheBuilt_inNetworksDoNotWarn` (削除) | 組み込み 13 系統の `initialize` で島の警告 `GUILDA:PowerNetwork:NetworkIsland` が出ない | `test_I93_model_equilibrium/TheBuilt_inNetworksAreFarBelowTheThreshold_WithTheirControllers`。同じ 13 系統を構築して `initialize` しているので、そのループで最後の警告が島の警告でないことも確認する |
| `test_F7_linearization/LinearModelsOfEveryBundledNetworkMatchTheReferenceValues` (一部重複を解消) | 基準値の全系統で線形モデルが一致 | 5 系統 (IEEE9bus, Ishizaki6Bus, Txt3Bus, Ishizaki6Bus+GC, IEEE14bus+GC) は `test_F7_linearization/LinearModelsMatchTheReferenceValues` (medium) が比べるので、large のテストはその残りだけを比べる。2 つ合わせて基準値の全系統を比べる |

これで組み込み 13 系統をすべて構築する処理は 5 回から 2 回 (F16 の構築だけ、I93 の構築 + initialize)、
F7 の基準値の比較は 5 系統分が 1 回に減る。削除は 3 件 (934 → 931 件)。

### 重複の候補 (判断に迷うので残した)

| テスト | 重なり | 残した理由 |
|---|---|---|
| `test_F3_initialize/InitializeWithOPF` と `test_I56_initialize_equilibrium/OPFInitializeGivesARealEquilibrium` | どちらも IEEE14 で `initialize(Method="OPF")` を解く | F3 は設定の Method によらず AC OPF になること、I56 は KCL 残差・ドリフト・機器の電力と 9 母線での確認。assert が違う |
| `test_F8_utilities/TemplateIshizaki6Bus`, `TemplateTEST31bus`, `TemplateTxt3Bus`, `TemplateTutorial3bus`, `TemplateIEEE14bus` | 構築と `initialize` は I93 の全系統のループと重なる | 母線数と潮流計算の `flag > 0` は I93 では見ていない。統合するなら I93 のループに母線数と潮流計算を足す |
| `test_F24_tags/AutomaticTagsOfTheBuilt_inNetworksAreValidVariableNames` | 4 系統の構築は F16 の全系統の構築と重なる | タグの検査はタグの分類 (model) のテストとして独立させておく方が分かりやすい |
| 共通設定で IEEE14 を作り `initialize` するファイル (上の一覧) | 系統を使わないテストも毎回その時間を払う | 共通設定を各セクションへ移すとテストの書き方が大きく変わるので今回はしていない。系統を使わないテストを別ファイルへ分けるか、`net` を使うセクションだけで作れば軽くなる |

## 段階の見直し (手順 3)

- 計測が高負荷下だったので、閾値は計測値で **small は 0.5 s 以下、medium は 5 s 以下、それより長いものは large**
  とした (普段の負荷でおよそ 0.3 s / 3 s に当たる見込み)。
- small のテストで 0.5 s を超えたものを medium (5 s 超は large) に、medium のテストで 5 s を超えたものを
  large に登録し直した。`test_levels.m` は行の追加・段階の書き換え・削除したテストの行の削除だけで、並べ替えはしていない
  (一覧に節の無かったファイルは末尾に節を足した)。
- 分類ごとに small の煙テストが残るよう、次は閾値を超えても small に残した:
  - cpf: `test_F5_cpf/LimitsOptionValuesAreChecked`
  - graph: `test_F41_spring_node/TheVectorizedCallEqualsTheCallsPerColumn`,
    `test_F41_spring_node/CSVFilesWithoutTheNewColumnsStillImportWithTheDefaults`,
    `test_F44_net_diagram/ResultPFPlot_diagramUsesTheSolution`
  - opf: `test_F4_opf/DefaultOPFCostOfALoadIs0`, `test_F4_opf/UnknownOrInvalidOptionsStopWithAnError`
- 追加したテストは 1 件: `test_F5_cpf/CPFOnA3_busNetworkPassesTheNose`。CPF の経路をたどるテストは IEEE14 の
  ものしかなく、どれも重いので small に CPF の計算そのものが無くなる。`build_3bus` の 3 母線でノーズ点を
  越えることだけを確かめる小さな代表として足した。

## 分類 (手順 4)

`DebugScript.test_categories` の分類と、ソースを変えたときに回す分類の目安は、そのファイルの
ヘッダーコメントにある。1 つのファイルが複数の分類に属するときは分類ごとに 1 行ずつ書く。
すべての test_F*/test_I* が分類に属するかは `run_all` が毎回調べ、無ければ
`DebugScript:UnknownCategoryTest` の警告を出す。

## 結果 (手順 7)

基準: このブランチの a752e1b4。

| 段階 | 件数 | 実行時間 | 負荷平均 | 結果 |
|---|---|---|---|---|
| small | 232 (以前 607) | 75 s (全体 78 s) | 開始時 1.4 | PASS 230 / KNOWN 1 / SKIP 1 |
| small | 232 | 116〜121 s | 11〜13 | 同上 |
| medium | 773 | 1606 s | 8〜13 | PASS 770 / KNOWN 1 / FAIL 1 (F43、下記で修正) / SKIP 1 |
| large | 932 (以前 934) | 2515 s | 3〜9 | PASS 929 / KNOWN 1 / FAIL 1 (既存の I92) / SKIP 1 |

- large の件数は 934 − 削除 3 + 追加 1 = 932。新たな FAIL は無い。
- small は負荷の低いときで 75 s で、目標の 1 分をやや超える。各ファイルの最初のテストの初回の時間
  (1〜3 s) と、共通設定で IEEE14 を作るファイルの準備の時間が残りの大半。さらに縮めるなら、上の
  「重複の候補」の共通設定の見直しか、閾値を 0.3 s 相当より下げる。
- medium で見つかった F43 の失敗: `test_F43_spring_model/OwnNodeOfAClassicalGeneratorEqualsVfieldE_jdelta`
  は前のセクションで作ったシナリオ "fault" を使っており、前のテストが large に移ると単独で失敗した。
  このセクションの中でシナリオを作るように直した (3c81b1b4)。

分類ごとの small (負荷の低いとき、各分類を別々に実行したテスト時間の合計。ファイルの初回の時間を含む):

| 分類 | ファイル数 | small の件数 | テスト時間 |
|---|---|---|---|
| model | 22 | 90 | 23.9 s |
| powerflow | 10 | 41 | 17.5 s |
| simulate | 22 | 29 | 18.3 s |
| linearize | 2 | 9 | 4.7 s |
| opf | 2 | 5 | 3.4 s |
| cpf | 2 | 3 | 4.0 s |
| io | 4 | 24 | 10.5 s |
| graph | 8 | 4 | 7.9 s |
| gui | 4 | 7 | 3.8 s |
| env | 4 | 25 | 2.2 s |

未知の分類名は `DebugScript:UnknownCategory` のエラーになることを確認した。

## 開発ブランチの取り込み (2026-11-17)

`refactor/design-alignment` の baf9ee56 を `git merge` で取り込んだ (マージコミット 84db83c1、競合なし)。

- F7 は開発ブランチ側で `Coordinate` → `Port` の改名 (`PortIsAnOptionOfGet_sys` など) が入った。
  基準値の比較 (`+helper/linearization_reference_check.m`) も `Port="PQ"` に変わっただけで、
  medium と large で比べる系統を分けた整理とは重ならない。`test_levels.m` の改名済みの行もそのまま。
  (2026-11-28 に基準値と比べる側を作り直した: `linearization-connector.md` §26)
- 新しいファイルの分類: `test_F52_result_gui` → gui、`test_F54_graph_layout` → graph、
  `test_F55_guilda_app` → gui。`test_categories.m` のヘッダーと model-implementation.html の対応表に
  `@DrawerResultGUI`, `@DrawerGUILDA`, `launch_gui` (gui)、`get_layout`, `set_layout`, `layout_*` (graph) を足した。
- 段階: 変わったファイル (F2, F3, F7, F17, F19, F34, F43, F44, F47, F49, F50, F52, F54, F55、267 件) を
  large で計測した。**負荷平均が 31〜77 で、前の計測 (large1) と共通のテストの時間比の中央値は約 3 倍**
  (四分位 1.9〜4.3)。そのため既に段階のあるテストは動かさず、新しいセクション 37 件だけを
  計測値 ÷ 3 に 0.5 s / 5 s の基準を当てて振り分けた:
  - small に残したもの: F34 の 1 件、F54 の `PathParseAndValidator`, `ChecksAtInputTime_add___`
  - medium: F47 1、F50 1、F54 10、F55 2
  - large: F50 1、F52 の全 7 件 (計測値 31〜129 s)、F55 7 件 (26〜102 s)
  - 開発ブランチでは F52, F54, F55 はすべて small だった (一覧に行が無かった)。
- small 全体: 235 件 (232 + F34 1 + F54 2)、PASS 233 / KNOWN 1 / FAIL 0 / SKIP 1、テスト時間 388 s。
  負荷平均 31〜57 での値なので、前の 75 s (負荷平均 1.4) とは比べられない。
- Category 指定の small: gui 7 件 20 s、graph 6 件 26 s、linearize 9 件 13 s、いずれも FAIL 0。
