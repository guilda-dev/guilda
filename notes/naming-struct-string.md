# 構造体と文字列の接頭辞の改名(`s_` → `sct_`、`str_` → `s_`/`sv_`/`sr_`)

基準: `refactor/design-alignment` の `ce471a1`(2026-11-05)。作業ブランチ `refactor/naming-struct-string`。

2026-11-05 の決定に従い、型の文字 `s` を文字列だけに使うよう名前を揃えました。

- 構造体(大きさを問わない)は `sct_`。
- 文字列は大きさで `s_`(スカラー)、`sv_`(列)、`sr_`(行)、`sm_`(行列)。`str_` はなくなりました。char の配列も文字列として扱い、1 つの文字列を表す char の行は `s_` にしています。
- 改名はスクリプトで行いました。識別子は単語の境界で照合し、ファイルごと(必要な所は行の範囲ごと)の対応表で決めています。`.名前`(プロパティ、フィールド)とそれ以外を分けて扱いました。並べた代入や `arguments` の列は、改名の前に揃っていた所だけ揃え直しています。
- 対象: `_GUILDAsystem`、`_GUILDAobject`、`_GUILDAtutorial`、`_GUILDAverification`、`@GUILDA`、`+DebugScript`、テンプレート(`*.template`、`export_csv_class.txt`)、メッセージの XML、クラス図の SVG、手書きの `_GUILDAdoc/developer/*.html`、`notes/`。`_GUILDAdoc/database` は生成物で、コミットされているのは `list_*.js` の 3 つだけです。どれも対象の名前を含まないので、作り直していません。

## 第 1 段: 構造体(`s_` → `sct_`)

| 旧 | 新 | 場所 |
|---|---|---|
| `s_options` | `sct_options` | ソルバー、解析メソッド、`resolve_options`、互換フック、テスト |
| `s_model`、`s_block`、`s_output`(フィールド名も) | `sct_model`、`sct_block`、`sct_output` | `SolverLIN/solve`、`ResultLIN`(Hidden プロパティ `sct_model`)、`get_ss` |
| `s_var` | `sct_var` | `+opffcn/apply`、`+opffcn/variables` |
| `s_given`、`s_map` | `sct_given`、`sct_map` | 各ソルバーの `get_options`、`resolve_options` |
| `s_phase`、`s_sol`、`s_out` | `sct_phase`、`sct_sol`、`sct_out` | `Scenario.compile`、`SolverODE` |
| `s_view` | `sct_view` | `ResultODE`(非公開プロパティ) |
| `s_opt`、`s_stored`、`s_num`、`s_user`、`s_y` | `sct_*` | `simulate`、`SolverOPF/optimoption`、`v3_user_config`、`get_ss` |
| テストの `s_before`、`s_after`、`s_mapPF`、`s_mapODE`、`s_dyn`、`s_col`、`s_config`、`s_both`、`s_files`、`s_warn`、`s_xml`、`s_tolerance`、`test_F9` の `s_old` | `sct_*` | `+DebugScript`、`_GUILDAverification` |
| `s_edit`(ノートに残っていた旧名) | `sct_edit` | `notes/*.md` |

構造体でない `s_*` の扱い:

| 旧 | 新 | 理由 |
|---|---|---|
| テストの `s_k`、`s_f`、`s_ful`、`s_new`、`s_old`、`s_ref`、`s_x`、`s_def`、`s_all`、`s_sel`、`s_io`、`s_dae`、`s_feedback` | `sys_*` | Control System Toolbox の `ss`/`dss`。テストにある `sys_k`、`sys_f`、`sys_ref` に合わせた |
| `notes/simulate-review-measurements.m` の `s_fault`、`s_after`、`s_ref`、`s_new`、`s_old` | `res_*` | `ResultODE` |
| 同 `s_net` | `c_net` | `for` で回す 1x1 の cell(同じファイルの `c_case` などに合わせた) |
| `collect_call_graph` の説明の `s_x` | `sct_x` | 構造体の受け手の例 |
| `Parameter` の `s_ipara` | 変更なし | 文字列のスカラー |

## 第 2 段: 文字列(`str_` → `s_`/`sv_`/`sr_`/`sm_`)

既定は `str_X` → `s_X`(スカラー)です。この規則で改名した名前(どこかのファイルでスカラー、288 個):

`a`, `access`, `alg`, `ancestor`, `answer`, `arg`, `args`, `attributes`, `b`, `bad`, `base`, `block`, `block_comment`, `block_group`, `body`, `branch`, `branch_cases`, `branch_list`, `Bus`, `bus`, `busi`, `bustype`, `call`, `case`, `cases`, `chain`, `changes`, `check`, `class`, `class_char`, `class_key`, `class_name`, `class_path`, `class_url`, `classdef_file`, `clean`, `clean_help`, `cls`, `code`, `col`, `comment`, `comp`, `comp_cases`, `comp_list`, `CompKey`, `CompPath`, `conf`, `coni`, `content`, `context`, `controllers`, `coordinate`, `csv`, `cwd`, `db`, `db_path`, `decl`, `def_file`, `defined`, `defining`, `desc`, `description`, `detail`, `dim`, `dir`, `dir_name`, `dirpath`, `disp`, `doc_path`, `doc_path_for_cmd`, `doc_root`, `dup`, `err`, `ext`, `f`, `fault`, `fcn`, `fdi`, `field`, `file`, `file2`, `file_name`, `file_path`, `filepath`, `first`, `flag`, `fname`, `folder`, `folder_path`, `form`, `from`, `fromto`, `GBij`, `gc`, `gcon`, `gen`, `got`, `group`, `grp`, `GUILDApath`, `hash`, `head`, `head_i`, `header`, `header_i`, `help`, `help_text`, `helper`, `i`, `ID`, `id`, `idx`, `image`, `in`, `indent`, `index`, `Index`, `inline`, `input`, `island`, `issue`, `item`, `joined`, `js`, `js_content`, `js_file`, `json`, `json_template`, `key`, `keyi`, `kind`, `label`, `layer`, `lc`, `left`, `level`, `lim`, `limits`, `line`, `list`, `load`, `local`, `log`, `m`, `Mac`, `main`, `manifest`, `mat`, `matlab`, `member`, `message`, `method`, `method_file`, `methodPF`, `miss`, `mode`, `model`, `modified`, `msg`, `name`, `net`, `NetPath`, `network`, `new`, `newtag`, `next`, `node`, `none`, `normalized_value`, `num`, `obj`, `odefcn`, `off`, `old`, `oldtag`, `on`, `opti`, `order`, `origin`, `Out`, `out`, `overrides`, `owner`, `package`, `para`, `parent`, `part`, `pat`, `path`, `path_add_branch`, `path_add_component`, `path_comp`, `path_rep_component`, `pattern`, `pi`, `plain`, `PlotFcn`, `port`, `pq`, `preamble`, `prefix_group`, `private`, `prop`, `pTag`, `push`, `q`, `quoted`, `raw_help`, `raw_value`, `reason`, `redirect_html`, `redirect_path`, `ref`, `rel`, `remote_ref`, `removed`, `report`, `residual`, `rest`, `result`, `rmFilesi`, `root`, `root_name`, `root_path`, `rule`, `sc`, `scenario`, `scope`, `sec`, `section`, `self_kind`, `sha`, `shared`, `short`, `signature`, `site`, `sol`, `solver`, `source`, `space`, `split`, `src`, `src_file`, `staleID`, `state`, `struct`, `sub`, `suffix`, `summary`, `symbol`, `t0`, `t1`, `tab`, `tag`, `tag_name`, `tag_pattern`, `tagComp`, `target`, `te`, `template`, `term`, `test`, `text`, `title`, `tmp`, `to`, `tok`, `tracked`, `trim`, `ts`, `Type`, `type`, `unit`, `untracked`, `user`, `val`, `validators`, `value`, `var`, `w`, `want`, `warn`, `warn0`, `where`, `why`, `with`, `without`, `y`

下の表はスカラー以外の名前と、文字列でない名前です。同じ旧名でも別のファイルではスカラー(`s_`)のことがあります。

| 旧 | 新 | ファイル |
|---|---|---|
| `str_all` | `sr_all` | `test_I91_slack_power_assignment.m` |
| `str_bad` | `sv_bad` | `test_F10_api_foundation.m` |
| `str_body` | `sv_body` | `+tools/next_tag_number.m` |
| `str_br` | `sv_br` | `@ResultOPF/Plot.m` |
| `str_Bra` | `sv_Bra` | `@PowerNetwork/draw_spring_model.m` |
| `str_bra` | `sv_bra` | `@SolverOPF/solve.m` |
| `str_branch` | `sv_branch` | `+tools/network_to_mpc.m`, `@DrawerNetDiagram/DrawerNetDiagram.m`, `@DrawerNetDiagram/hover_branch.m`, `@DrawerNetDiagram/set_network.m`, `@SolverOPF/solve.m`, `@SolverPF/solve.m` |
| `str_BraOpt` | `sr_BraOpt` | `@PowerNetwork/import_csv.m` |
| `str_BraReq` | `sr_BraReq` | `@PowerNetwork/import_csv.m` |
| `str_BraTag` | `sv_BraTag` | `@PowerNetwork/import_csv.m` |
| `str_Bus` | `sr_Bus` | `@PowerNetwork/add_branch.template` |
| `str_bus` | `sr_bus` | `test_F8_utilities.m` |
| `str_Bus` | `sv_Bus` | `test_I56_initialize_equilibrium.m`, `test_I89_slack_cannot_balance.m`, `test_I90_auto_slack_selection.m`, `test_I91_slack_power_assignment.m`, `test_I92_network_islands.m`, `@PowerNetwork/draw_spring_model.m`, `@PowerNetwork/export_csv.m`, `@PowerNetwork/get_admittance_matrix.m`, `@PowerNetwork/initialize.m` |
| `str_bus` | `sv_bus` | `+helper/branch_losses.m`, `test_F4_opf.m`, `+tools/network_to_mpc.m`, `@Branch/build_opf_problem.m`, `@PowerNetwork/export_csv.m`, `+opffcn/variables.m`, `@DrawerNetDiagram/DrawerNetDiagram.m`, `@DrawerNetDiagram/hover_bus.m`, `@DrawerNetDiagram/reflect_node_label.m`, `@DrawerNetDiagram/set_network.m`, `@ResultOPF/Plot.m`, `@ResultPF/Export.m`, `@ResultPF/Plot.m`, `@SolverPF/solve.m` |
| `str_bus2bus` | `sm_bus2bus` | `@DrawerNetDiagram/set_network.m` |
| `str_BusOpt` | `sr_BusOpt` | `@PowerNetwork/import_csv.m` |
| `str_BusReq` | `sr_BusReq` | `@PowerNetwork/import_csv.m` |
| `str_BusTag` | `sr_BusTag` | `@PowerNetwork/PowerNetwork.m`, `@PowerNetwork/remove_bus.m` |
| `str_BusTag` | `sv_BusTag` | `@PowerNetwork/import_csv.m` |
| `str_busvar` | `sr_busvar` | `@ResultLIN/get_ss.m` |
| `str_busvar` | `sv_busvar` | `+helper/linearize_v3.m`, `@ResultLIN/get_ss.m` |
| `str_class` | `sv_class` | `private/update_class_signature.m` |
| `str_cls` | `sv_cls` | `test_F1_model_building.m`, `@PowerNetwork/info.m` |
| `str_com` | `sv_com` | `@DrawerNetDiagram/reflect_node_label.m` |
| `str_comp` | `sr_comp` | `test_I91_slack_power_assignment.m` |
| `str_CompDir` | `sct_CompDir` | `@PowerNetwork/import_csv.m` |
| `str_component` | `sv_component` | `@DrawerNetDiagram/DrawerNetDiagram.m`, `@DrawerNetDiagram/hover_component.m`, `@DrawerNetDiagram/reflect_node_label.m`, `@DrawerNetDiagram/set_network.m` |
| `str_CompOPF` | `sr_CompOPF` | `@PowerNetwork/import_csv.m` |
| `str_CompOpt` | `sr_CompOpt` | `@PowerNetwork/import_csv.m` |
| `str_CompOpt_` | `sr_CompOpt_` | `@PowerNetwork/import_csv.m` |
| `str_CompReq` | `sr_CompReq` | `@PowerNetwork/import_csv.m` |
| `str_CompTag` | `sv_CompTag` | `@PowerNetwork/import_csv.m` |
| `str_const` | `sv_const` | `@PowerNetwork/build_opf_problem.m` |
| `str_ctrl` | `sv_ctrl` | `@PowerNetwork/remove_bus.m` |
| `str_cub` | `sv_cub` | `@SolverOPF/solve.m` |
| `str_edge` | `sm_edge` | `@PowerNetwork/draw_spring_model.m` |
| `str_edit` | `sv_edit` | `@PowerNetwork/check_edit.m`, `@PowerNetwork/initialize.m` |
| `str_end` | `sv_end` | `test_F4_opf.m`, `+opffcn/variables.m`, `@SolverOPF/solve.m` |
| `str_evt` | `sr_evt` | `@SolverODE/SolverODE.m` |
| `str_evti` | `sr_evti` | `@SolverODE/SolverODE.m` |
| `str_fd` | `sv_fd` | `@PowerNetwork/info.m`, `@DrawerNetDiagram/DrawerNetDiagram.m` |
| `str_feature` | `sr_feature` | `run_all.m` |
| `str_fields` | `sv_fields` | `setting.m` |
| `str_file` | `sr_file` | `run_all.m` |
| `str_file` | `sv_file` | `test_F10_api_foundation.m`, `private/get_config.m`, `private/set_config.m` |
| `str_from` | `sv_from` | `test_F2_powerflow.m` |
| `str_fromto` | `sr_fromto` | `@PowerNetwork/import_csv.m`, `@PowerNetwork/import_matpower.m` |
| `str_g` | `sv_g` | `test_F4_opf.m` |
| `str_GconTag` | `sr_GconTag` | `@PowerNetwork/PowerNetwork.m`, `@PowerNetwork/remove_global_controller.m` |
| `str_gen` | `sv_gen` | `test_F4_opf.m`, `+tools/network_to_mpc.m` |
| `str_global` | `sv_global` | `@PowerNetwork/export_csv.m` |
| `str_hook` | `sv_hook` | `test_F10_api_foundation.m` |
| `str_iBus` | `sv_iBus` | `@PowerNetwork/get_admittance_matrix.m` |
| `str_id` | `sr_id` | `test_F7_linearization.m` |
| `str_id` | `sv_id` | `@PowerNetwork/PowerNetwork.m` |
| `str_ignore` | `sr_ignore` | `@LayerPackage/LayerPackage.m`, `@LayerPackage/disp_tree.m` |
| `str_key` | `f_key` | `@ResultODE/ResultODE.m` |
| `str_key` | `sv_key` | `private/update_class_signature.m`, `@PowerNetwork/export_csv.m` |
| `str_keys` | `sv_keys` | `test_F1_model_building.m` |
| `str_line` | `sv_line` | `test_F16_csv_io.m` |
| `str_list` | `sr_list` | `test_F9_environment.m` |
| `str_load` | `sr_load` | `test_F5_cpf.m`, `test_I71_layer_get_sys.m` |
| `str_load` | `sv_load` | `test_F4_opf.m` |
| `str_local` | `sv_local` | `@PowerNetwork/export_csv.m` |
| `str_log` | `sv_log` | `test_F16_csv_io.m` |
| `str_missing` | `sr_missing` | `@PowerNetwork/remove_branch.m`, `@PowerNetwork/remove_bus.m`, `@PowerNetwork/remove_global_controller.m` |
| `str_missing` | `sv_missing` | `@PowerNetwork/add_global_controller.m` |
| `str_ModifiedFiles` | `sv_ModifiedFiles` | `gitpull.m` |
| `str_name` | `sr_name` | `+opffcn/update.m` |
| `str_name_list` | `sm_name_list` | `@LayerPackage/LayerPackage.m`, `@LayerPackage/attach_tag.m` |
| `str_need` | `sr_need` | `@PowerNetwork/import_matpower.m` |
| `str_NetOpt` | `sr_NetOpt` | `@PowerNetwork/import_csv.m` |
| `str_new` | `sr_new` | `@PowerNetwork/export_csv.m` |
| `str_num` | `sv_num` | `+tools/next_tag_number.m` |
| `str_opt` | `sr_opt` | `@PowerNetwork/import_csv.m` |
| `str_parent` | `sv_parent` | `dictionary.m` |
| `str_path` | `sr_path` | `test_F9_environment.m` |
| `str_path` | `sv_path` | `test_F25_ishizaki_source_data.m`, `@PowerNetwork/export_csv.m` |
| `str_pattern` | `sr_pattern` | `publish_doc.m` |
| `str_phase` | `sr_phase` | `@SolverODE/SolverODE.m` |
| `str_prop` | `sv_prop` | `@LayerPackage/struct.m` |
| `str_Release` | `sr_Release` | `private/check_requirement.m` |
| `str_rep` | `sr_rep` | `@PowerNetwork/export_csv.m` |
| `str_rmBranch` | `sv_rmBranch` | `@PowerNetwork/remove_bus.m` |
| `str_rmComp` | `sv_rmComp` | `@PowerNetwork/remove_bus.m` |
| `str_rmFiles` | `sv_rmFiles` | `gitpull.m` |
| `str_row` | `sv_row` | `@ResultOPF/Plot.m` |
| `str_sameLayer` | `sv_sameLayer` | `@LayerPackage/LayerPackage.m` |
| `str_slack` | `sv_slack` | `@Scenario/out_of_step.m` |
| `str_tag` | `sr_tag` | `@PowerNetwork/PowerNetwork.m`, `@PowerNetwork/remove_scenario.m` |
| `str_tag` | `sv_tag` | `test_F16_csv_io.m`, `test_F1_model_building.m`, `@PowerNetwork/export_csv.m`, `@PowerNetwork/import_csv.m` |
| `str_tag2` | `sv_tag2` | `test_F16_csv_io.m` |
| `str_tagBus` | `sv_tagBus` | `@PowerNetwork/remove_bus.m` |
| `str_tagComp` | `sv_tagComp` | `@Bus/remove_component.m` |
| `str_tagGcon` | `sv_tagGcon` | `@PowerNetwork/remove_global_controller.m` |
| `str_tags` | `sv_tags` | `+tools/next_tag_number.m` |
| `str_templates` | `sr_templates` | `test_F8_utilities.m` |
| `str_to` | `sv_to` | `test_F2_powerflow.m` |
| `str_trip` | `sv_trip` | `@SolverODE/SolverODE.m` |
| `str_type` | `sv_type` | `test_F2_powerflow.m`, `test_F8_utilities.m`, `@PowerNetwork/draw_spring_model.m` |
| `str_u` | `sv_u` | `+helper/linearize_v3.m`, `@ResultLIN/get_ss.m`, `@SolverLIN/solve.m` |
| `str_usable` | `sr_usable` | `@SolverOPF/optimoption.m` |
| `str_written` | `sr_written` | `@PowerNetwork/import_csv.m` |
| `str_x` | `sv_x` | `+helper/linearize_v3.m`, `test_F7_linearization.m`, `@ResultLIN/get_ss.m`, `@SolverLIN/solve.m` |
| `str_z` | `sv_z` | `+helper/linearize_v3.m`, `@SolverLIN/solve.m` |

判断した点:

- 大きさが変わる変数は、通常の大きさにしました。`dictionary.m` の `str_parent` は最初はスカラーで、その後は列になるので `sv_parent`。`Scenario/compile.m` の `str_dup` は重複の列を作った直後に先頭の 1 つにするので `s_dup`。
- 同じファイルで大きさの違う使い方をしている所は、行の範囲で分けました: `test_F16_csv_io` と `test_F1_model_building` の `str_tag`(ループのスカラーと、`string(net.a_Branch)` の列)、`test_F4_opf` の `str_bus`、`test_F7_linearization` の `str_id`、`publish_doc` の `str_pattern`(ループのスカラーと cell の行)、`get_ss` の `str_busvar`(`coordinate_filter` では列 `sv_busvar`、呼び出し側では行 `sr_busvar`)、`import_csv` の `str_tag`(`read_full_tag` の出力と `sct_comp` のフィールドは列 `sv_tag`、`set_full_tag` の引数はスカラー)。
- `Branch.a_Bus` は 2x1 の cell なので、`string(br.a_Bus)` は列(`sv_bus`、`sv_end`)。`draw_spring_model` の `str_edge`(N x 2)と `set_network` の `str_bus2bus`(2 x N)は `sm_`。
- `LayerPackage.attach_tag` の引数 `str_name_list` は `(:,:) string` と宣言されているので `sm_name_list`。
- 文字列でないもの: `ResultODE` の `str_key` は関数ハンドルなので `f_key`、`import_csv` の `str_CompDir` は `dir` の構造体なので `sct_CompDir`。
- 既存の名前との衝突: `SolverLIN/solve` の主関数では、母線ごとのループの `sv_u` と、その後の入力名の列 `str_u` → `sv_u` が同じ名前になります。ループの値はループの中でしか使わないので、動作は変わりません。`linearize_v3`、`get_ss`、`test_F7_linearization` の `sv_x`/`sv_u` は別の関数かテストのセクションで、衝突しません。

### 既存の `sv_` のうち行だったもの(`sv_` → `sr_`)

| 旧 | 新 | ファイル |
|---|---|---|
| `sv_bad`(定数プロパティ) | `sr_bad` | `BadComponentStub`、`BadControllerStub`、`test_I93_model_equilibrium` |
| `sv_reserved`(定数プロパティ) | `sr_reserved` | `LocalController` |
| `sv_method` | `sr_method` | `PowerNetwork/initialize` |
| `sv_old`、`sv_new` | `sr_old`、`sr_new` | `v3_simulate_args`(`v3_initialize_args` は 2026-11-13 に削除) |
| `sv_field` | `sr_field` | `Scenario` |
| `sv_col` | `sr_col` | `Scenario/export_csv`、`Scenario/import_csv` |
| `sv_names`、`sv_in`、`sv_part` | `sr_names`、`sr_in`、`sr_part` | `tools.resolve_options` |
| `sv_name`(1 か所) | `sr_name` | `ResultCPF` の表の列名 |
| 区間データのフィールド `sv_event` | `sr_event` | `Scenario/compile`、`feature-simulation.html` |

モデルクラスの `sv_para = ["M","D",...]` や `load.power` の `sv_u = ["Pload","Qload"]` は、基底クラスの宣言 `(:,1) string` で列に変換されるので変えていません。

## 利用者のコードが気づく変更

互換の別名は作っていません。

- 公開プロパティ: すべての層(`PowerNetwork`、`Bus`、`Branch`、`Component`、制御器、`Parameter`、`Scenario`)の `str_tag` → `s_tag`。`Bus.str_bustype` → `s_bustype`。結果の `str_solver`、`str_network` → `s_solver`、`s_network`。
- `linearize`/`get_sys` の `output.str_issue` → `output.s_issue`。モデル作者向けの `sct_edit.str_odefcn` → `sct_edit.s_odefcn`。
- `net.info` と `struct(obj)` が作る表や構造体の列名、フィールド名も `s_tag`、`s_bustype` になります。
- `LocalController.sv_reserved` → `sr_reserved`、`ResultLIN` の Hidden プロパティ `s_model` → `sct_model`、`DrawerNetDiagram` の `str_bus`/`str_branch`/`str_component` → `sv_*`。
- 引数の名前(`remove_bus(sr_BusTag)`、`remove_scenario(sr_tag)` など)は位置引数なので、呼び出しは変わりません。
- `.mlx` チュートリアル: `Step4_SimulateCondition.mlx` の `.str_tag`、`str_tagComp` を `.s_tag`、`sv_tagComp` に、v3 の `.str_u`、`.str_x` を現在のプロパティ名 `.sv_u`、`.sv_x` にしました。このチュートリアルは v3 の API(`odeEventSet` など)のままです。ほかの `.mlx` は対象の名前を含みません。

## 意図して残したもの

- `collect_call_graph` の受け手の判定の正規表現 `^(s|str|sct|...)_` は `str` を残し、`sr` を足しました。利用者のコードの `str_*` も値として扱い続けるためです。この正規表現は `\bstr_[A-Za-z]` には一致しません。
- `@GUILDA` の文書ツールの `bln_`、`cell_` は対象外です。
- `.codex/config.toml` と `.github/copilot-instructions.md` の例 `s_label` は文字列で、規則どおりです。

`git grep -nP "\bstr_[A-Za-z]"` が見つけるのは、旧名を並べたこのファイルと `v4-migration.md` の 1.19 の表だけです(コード、手書きの文書、`.mlx` の中身には残っていません)。
