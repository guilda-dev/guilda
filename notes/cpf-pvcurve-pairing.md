# 連続潮流計算の図に PV 曲線を添える・電圧安定指標の説明・plot_pqv

ブランチ: `feature/cpf-pvcurve-pairing`(`refactor/design-alignment` 18345f50 から作成し、7f1b96cd と ad121422 をマージ済み)。
テスト: `_GUILDAverification` のブランチ `test/cpf-pvcurve-pairing`(73983175 の上、8cd37ff6)。本体の参照もこのコミット。

## 行ったこと

### A. PV 曲線を添える(PVCurve / PVBus)

- `ResultCPF` の `plot_diagram`, `plot_spring_model`, `plot_stability_index`, `plot_generator`, `plot_branch` に
  Name-Value `PVCurve`(logical、既定 true)と `PVBus`(既定 `""`)を追加し、出力を `[G, G_pv]` にしました。
- `PVBus`: `""` は `plot_pvcurve` の既定と同じ母線(`options.LoadBus`、空なら全母線)、`"all"`、母線タグ。
  不明なタグは何も描く前に `GUILDA:ResultCPF:UnknownBus`。
- λ 軸の 3 つの図: 同じ GraphChart の一番上に PV 曲線のパネルを追加(λ 軸を共有 = 既存の時刻パネルと x 軸を
  `linkaxes`、時刻パネル、`s_cursor` "marker"、ノーズの破線)。`G_pv = G`。
- `plot_diagram` / `plot_spring_model`: コンテナを左 2/3(本体)・右 1/3(`plot_pvcurve(Bus=PVBus)`)の
  枠なし uipanel に分け、`G.link(G_pv)`。新しい figure は 1400 × 600 px。`uigridlayout` の Parent はまず枠なし
  uipanel を置く(`ResultODE` の `draw_with_chart` と同じ作り)。描画に失敗したら作ったパネルを消す。
- `PVCurve=false`、または Parent が axes / uiaxes のときは従来どおり本体だけ(`G_pv = []`)。
- 追加した private 関数は 1 つ: `@ResultCPF/private/pair_pvcurve.m`(両方の配置を担当)。

### B. 電圧安定指標の説明

- `plot_stability_index` の題名 "Voltage stability index: smallest singular value of the power flow Jacobian"、
  縦軸 "\sigma_{min}(J)  (0 at the nose)"、下のパネル "Bus participation in the critical mode at the nose"。
- 定義・読み方・出典を `plot_stability_index` の help、ResultCPF のクラス help、`rv_sigmaMin` の 1 行コメント(短く)に記述。
  名前 `plot_stability_index` / `rv_sigmaMin` はそのまま、Normalize オプションは追加していません。

### C. plot_pqv

- `ResultCPF.plot_pqv(Bus, Parent)`: 既定は `plot_pvcurve` と同じ母線。`cm_Vbus` と `cm_Icomponent`(母線ごとに機器の電流の和)から
  `S = V conj(ΣI)`。標本はステップ(`step_sample`、名前 "Step")。
- `ResultODE.plot_pqv(Bus, Parent)`: 既定は全母線。母線電圧(`rm_variable` の Vre, Vim)と `rm_Icomponent` から。
  標本は出力時刻。解列中の機器(NaN)は 0。データがなければ `GUILDA:ResultODE:NoDiagramData`(既存メッセージを流用)。
- どちらも GraphChart の 3D パネル(`l_3d`、`s_zlabel`、系列ごとに `rv_x` = P、`rm_y` = Q、`rm_z` = |V|)。母線ごとに 1 系列。
- ResultODE のクラス help に 1 行追加。`@GUILDA/update_keymap.m` の結果メソッド一覧に両 `plot_pqv` を追加(GUI と補完)。

### ドキュメント・GUI・補完

- `feature-cpf.html`: 図の表の署名を更新、`plot_pqv` の行、「ステップの図に添える PV 曲線」と「電圧安定指標 σmin」の小節。
- `feature-simulation.html`: ResultODE のメソッド一覧に `plot_pqv`。
- `list_UpdateLog.js` に 1 件(2026-11-23、feature)。
- `gui_forms.json`: 5 メソッドの main に PVCurve / PVBus(PVBus にヒント)、両 `plot_pqv` の項目。
  `ResultCPF.plot_diagram` は `"same": "ResultPF.plot_diagram"` をやめて独自の項目にしました(PVCurve / PVBus を main に置くため。
  ResultPF.plot_diagram の main にある ODE 用の Trajectory は外しています)。
- `GUILDA.update_keymap(Signature=true)` で `functionSignatures.json` 2 か所を再生成。

## 決定・判断

- PV パネルの線のタグは `"V_" + 母線タグ`(凡例は母線タグ)。`plot_stability_index` の棒が母線タグを使うので、
  そのままだとタグが重なり `set_style("B009")` が両方に効くため。PV の系列は既存の系列の後に追加し、既存要素の
  `tab_element` の行(Index)を変えません。パネルの順だけ PV が一番上。
- `PVBus` の既定は `""`(意味は plot_pvcurve の既定)。5 ファイルそれぞれに既定値用のローカル関数を置かないため。
- Parent が axes のときの扱いは、ResultODE の side chart(Trajectory)と揃えて「本体だけ・G_pv = []」にしました。
- `plot_stability_index` の help には、Q 制約で経路が終わる場合(limit-induced)の注意は書いていません(下記で確認できなかったため)。

## σmin の注意点の確認(IEEE14bus、LoadBus = B009, B014 など)

- √(λmax − λ) で小さくなる: ノーズ前 12 ステップで σ/√(λmax−λ) ≈ 0.52〜0.63(ほぼ一定)。確認。
- Limits "Q" の切替で跳ぶ: 切替ステップで 0.524 → 0.436、0.408 → 0.332 など。確認。
- "V" / "S" の停止で 0 にならない: 全母線 Vmax = 1.3 にして Limits "V" で B014 の Vmin で停止 → σ_end = 0.49。
  全ブランチ Smax = 2.0 にして Limits "S" で EL001 で停止 → σ_end = 0.52。確認。
- Q 制約で経路が終わる場合: IEEE14bus / IEEE9bus の複数の LoadBus と、発電機の Qmax を平衡点の Q + 0.02〜0.3 に狭めた場合を
  試しましたが、いずれも切替の後になめらかなノーズに達し σ はノーズで約 0.001〜0.02 でした。経路が切替点で折り返す例が
  作れなかったため、この注意は書いていません。

## テスト

- 新規 `+DebugScript/test_F114_cpf_pvcurve_pairing.m`(分類 cpf, graph, simulate)。7 件(large 3、medium 4 を `test_levels.m` に登録)。
  単独実行で 7/7 合格。
- 実行結果(ad121422 をマージした後、submodule 8cd37ff6、R2026a、分類 cpf, graph, gui, env, simulate):
  - small: PASS 198 / FAIL 1。
  - medium: PASS 539 / FAIL 1(F114 の medium 4 件は合格)。
  - F114 + F97 を large で: F114 7/7 合格、F97 は 5 合格・3 失敗。
- 失敗はすべて `test_F97_cpf_analysis_plots`(指示により編集していません)。原因は PVCurve の既定が true になったこと:
  - `plot_stability_indexDrawsSigmaMin...`(small): `numel(G.ax) == 2` とタグの完全一致、`TopBus=0` で `isscalar(G.ax)` を確認している。
  - `plot_generatorDraws...` / `plot_branchDraws...`(large): `tab_element.Tag` の完全一致(PV の `V_B003` が加わる)。
  - 直し方: これらの呼び出しに `PVCurve=false` を加える(既存の行・タグ・値は変わらないので、ほかの assert はそのまま通る)。
- 競合: `list_UpdateLog.js`(bd4b52fb の doc の項目と本件の項目)は両方を残しました。functionSignatures.json は再生成して差分なし。
