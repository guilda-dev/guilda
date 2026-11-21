# 図の断面リンク(マーカーのカーソル、標本の名前、固有値の断面)

基準: ブランチ `feature/graph-section-link`(`refactor/design-alignment` の efc44399 から分岐)、2026-11-19。連続潮流計算の拡張(2026-11-19 承認)のうち S2(図の基盤と ResultLIN)の記録です。S1(SolverCPF / ResultCPF の `get_sys({cpf, steps})`)と S3(ResultCPF の plot と文書)は別のセッションです。

目的は、PV 曲線の段(step)を標本の軸にしたアニメーションと、断面ごとの線形化の結果を、既存の `GraphBase.link` / `set_time` でつなぐことです。λ は鼻の先で単調でなくなり、GraphBase の標本の値は非減少でなければならないので、標本は段の番号にします。

## 1. 変更の一覧

| 段 | 内容 | コミット |
|---|---|---|
| 1 | GraphChart のマーカーのカーソル(`s_cursor`) | 74583f2e |
| 2 | 標本の名前と文字(`s_sampleName`、`sv_sampleText`)を GraphChart、GraphNetDiagram、GraphSpring2D/3D のデータで受ける | 7da710bd |
| 3 | ResultLIN.plot_eigenvalue の複数断面(GraphChart の `iv_sample` と標本ごとの題名) | 0f6c73de |
| 4 | ResultLIN.plot_eigenvalue_path(新しい公開メソッド) | 74fd1df1 |

新しい公開メンバーは `ResultLIN.plot_eigenvalue_path` だけです。ほかはデータの構造体の項目と、protected / private のメンバーです(§6)。

## 2. GraphChart のマーカーのカーソル

- パネルの項目 `s_cursor`: `"line"`(既定。従来の縦線 x = t)または `"marker"`。
- `"marker"` は時刻のパネル(`l_time` が true)だけで使えます。そのパネルの線とマーカーの組は、`rm_y` の行が標本(`rv_t`)ごとに 1 行でなければなりません(`iv_sample` とは併用できません)。
- `set_time` で標本 k を表示すると、線とマーカーの組ごとに (rv_x(k), rm_y(k, 列)) へ丸いマーカーを置きます。色は要素の色(`SeriesColor`、NaN なら軸の色の順)、表示は `SeriesVisible` に従います。凡例に入らず、クリックを受けません。最初の `set_time` までは隠れます(縦線と同じ)。
- PV 曲線なら x = λ、標本 = 段です。`link`、`animate`、`export_video` はそのまま動きます。
- 誤り: `s_cursor` の値、または時刻のパネルでないパネルの `"marker"` は `GUILDA:GraphChart:FieldValue`。行の数の誤りは `GUILDA:GraphChart:FieldSize`。

## 3. 標本の名前と文字(GraphBase)

- 各図のデータ(GraphChart と GraphSpring2D/3D は `sct_data`、GraphNetDiagram は状態の構造体)の任意の項目:
  - `s_sampleName`: 標本の名前(例 `"Step"`)。`""`(既定)は秒の時刻。
  - `sv_sampleText`: 標本ごとの文字(1 x n_t、例 `"Step 12 (λ = 0.734)"`)。
- 標本の文字は protected の `sample_text(k, s_format)` が決めます。`sv_sampleText` があればその k 番目、名前だけなら「名前 値」(例 `"Step 12"`)、どちらもなければ従来どおり `sprintf(s_format, rv_t(k))`。
- 出る場所:
  - `show_controls` の時刻の文字(従来 `"t = … s"`)。名前があれば時刻の見出し(Group が `"Time"` のとき)も名前になります。名前の変わる `set_data` ではパネルを作り直します。
  - GraphSpring2D/3D の題名(従来 `"t = %.2f s"`)。
  - GraphNetDiagram の題名(`TitleFormat` の代わり。`TitleFormat = ""` なら従来どおり題名を書きません)。
- 既定の動作(項目なし)は変わりません。
- 誤り: `GUILDA:GraphBase:SampleLabel`(名前が 1 つの文字でない、文字の数が標本の数と違う)。
- 説明の「[s]」は「時刻 [s]、または名前のある標本の値(例 段)」に一般化しました(`rv_t`、`set_time` の t、`animate` / `export_video` の TimeStep)。
- サブクラスの `load_data` は `rv_t` を設定した後に `load_sample_label(sct_data)` を呼びます(フックの契約に追記)。

## 4. ResultLIN.plot_eigenvalue の複数断面

- `numel(rv_t) > 1` の結果は、全断面の固有値を 1 つの GraphChart に持ちます。標本は `rv_t`(有限で非減少でなければ 1 … n_t)。
- 仕組みは GraphChart の新しい系列の項目 `iv_sample`(各行の標本)です。`set_time(t)` は最も近い断面の行だけを "stable" / "unstable" に出します。パネルの `s_title` は標本ごとの文字列(1 x n_t)でもよくなり、題名は「Eigenvalues (ODE) (section k of n, t = …)」になります。
- 始めの断面は `Index`(既定 `res.Index`)。軸の範囲は全断面の固有値と虚軸(実部 0)を含む固定の範囲なので、アニメーションで軸が動きません。
- 操作パネルは標本の名前 `"Section"`、文字「Section k of n, t = …」。
- 1 断面の結果は従来どおりです(時刻のパネルも時刻の操作もなし)。
- `Index` が断面の数より大きいと `GUILDA:ResultLIN:IndexRange`。

## 5. ResultLIN.plot_eigenvalue_path(新規)

- `G = res.plot_eigenvalue_path(Type=, Tolerance=, Parent=)`。Type の既定は `res.Type`、Tolerance の既定は 1e-6(plot_eigenvalue と同じ)。
- 2 つの時刻のパネル: 上が断面ごとの有限固有値の最大の実部("max_real")、下が振動モード(|Im λ| > 1e-6、get_mode と同じ)の最小の減衰比 −Re λ/|λ|("min_damping"、振動モードのない断面は NaN)。どちらも y = 0 の点線。
- 最大の実部が Tolerance を超える最初の断面に、両パネルの縦の破線。上のパネルのラベルは、その固有値が複素なら `"Hopf (section k of n, t = …)"`、実なら `"instability (…)"`。すべて安定なら線はありません。
- x 軸は `rv_t`(ラベル `"t [s]"`)、有限で非減少でなければ断面の番号(ラベル `"Section"`)。時刻のパネルなので、`plot_eigenvalue` やばね質点の図とリンクできます。
- 1 断面の結果は `GUILDA:ResultLIN:OneSection`。
- 断面ごとの固有値は plot_eigenvalue と共有の private 関数 `section_eigenvalues`(`@ResultLIN/private`)で求めます。

## 6. 新しい内部の項目・メンバー

| 場所 | 名前 | 種類 |
|---|---|---|
| GraphBase | `s_sampleName`、`sv_sampleText` | protected プロパティ |
| GraphBase | `load_sample_label(sct_data)`、`sample_text(k, s_format)` | protected メソッド |
| GraphBase(show_controls のパネル) | `UserData.s_sampleName` | パネルの内部データ |
| GraphChart(データ) | パネルの `s_cursor`、標本ごとの `s_title`、系列の `iv_sample`、`s_sampleName`、`sv_sampleText` | データの項目 |
| GraphChart | `sct_plt.CursorMarker` | 描画オブジェクト(protected の sct_plt の項目) |
| GraphSpringBase、GraphNetDiagram(データ) | `s_sampleName`、`sv_sampleText` | データの項目 |
| ResultLIN | `private/section_eigenvalues.m` | private 関数 |
| メッセージ | `GUILDA:GraphBase:SampleLabel`、`GUILDA:ResultLIN:OneSection` | 誤りの ID |

## 7. テスト

| ファイル | 追加したテスト |
|---|---|
| `test_F48_graph_chart` | マーカーのカーソル(色・表示・リンク・set_data・誤り)、`iv_sample` と標本ごとの題名 |
| `test_F46_graph_base` | 標本の名前と文字(GraphSpring2D、GraphChart、GraphNetDiagram の操作パネルと題名、既定の時刻) |
| `test_F42_graph_spring` | 標本の文字の題名(2D / 3D、set_data、誤り) |
| `test_F84_linearization_analysis` | plot_eigenvalue の複数断面(`get_sys({sim, rv_t})`、set_time、軸の範囲、操作パネル、ばね質点の図とのリンク)、plot_eigenvalue_path(値、縦線、Tolerance、plot_eigenvalue とのリンク、行列の点、1 断面の誤り) |

- 1 秒を超えた 4 件は `test_levels.m` に medium で登録しました。`test_categories.m` は変えていません(既存のファイルに追加しただけ)。
- F84 の共通設定に IEEE9 の故障の模擬(0–1.5 s)と 4 断面の線形化を加えました。故障中(t = 0.52)の断面は ODE で不安定(実の固有値)なので、縦線は `"instability"` の側を確かめています。`"Hopf"` の側は自動テストでは通っていません。

## 8. 残り・注意

- `animate` / `export_video` の `TimeStep` の既定は 0.05 です。段を標本にした図では 1 段に 20 枚の同じ絵になるので、S3 は `TimeStep=1` を渡すか、ResultCPF 側で案内してください。
- GraphNetDiagram の流れの点(2D)は標本の間を実時間として動かすので、段の図では点の速さに物理的な意味はありません。
- `plot_eigenvalue_path` は ResultGUI(`@GUILDA/update_keymap.m` のメソッドの一覧と functionSignatures.json)に入れていません。GUI に出すかは未決定です。
- `GraphMatrix` は標本の名前に対応していません(依頼の範囲外)。
