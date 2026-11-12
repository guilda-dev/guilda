# 構造上起きえない状況の検査の削除(Issue #119)

> 基準: `refactor/design-alignment` の `c54df004`(2026-11-12)からの作業ブランチ `refactor/119-structural-checks`。仕組みの説明は `_GUILDAdoc/developer/class-design.html#parents` にあり、このノートは決定事項、削除した検査と残した検査、影響、未確認の事項を記録します。

## 決定事項(利用者の決定)

- モデルの物体(機器、ブランチ、局所制御器、大域制御器)は、キーで作る `add_*` と `replace_component` からしか作れないようにする。
- 外した物体は親の参照を外す(`[]` を代入する)のではなく `delete` する。
- その結果起きえなくなった「親が空か、親の型が正しいか」の検査と、親なしの単体利用のための経路を消す。互換や念のための防御的な検査は残さない。

## 実装

### 作成経路の限定

R2026a で、変更前に具体クラスのコンストラクタを直接呼んだ結果(**[実行]**):

| クラス | 変更前 | 変更後 |
|---|---|---|
| `component.generator.*`(5 クラス) | 作成できた(コンストラクタがなく、公開の既定のコンストラクタを継承。基底の `Access={?Component}` は効かない) | `Access={?Bus}` のコンストラクタを追加 |
| `component.load.power`、`impedance` | `MethodRestricted`(既に `Access={?Bus}`) | 変更なし |
| `controller.avr.*`、`pss.PSS1`、`governor.*`、`local_LQR` | 作成できた(公開) | `Access={?Component}` |
| `controller.agc.broadcast_PI_AGC` | 作成できた(公開) | `Access={?PowerNetwork}` |
| `branch.*`(4 クラス) | 作成できた(既定のコンストラクタ。基底の `Access={?Branch, ?PowerNetwork}` は効かない) | `Access={?PowerNetwork}` のコンストラクタを追加 |

- 変更後は 8 種類すべての直接の呼び出しが `MATLAB:class:MethodRestricted` で止まり、`add_*` からは作れることを確認しました。
- `local_LQR` は property の set メソッドを同じ `methods` ブロックに持っていたため、コンストラクタを別のブロックに分けました(set メソッドのブロックには属性を付けられない)。
- `controller.local_LQR_retrofit` は抽象クラス(`key` なし)のままで、作成できないので対象外です。`+load/history` も登録されない旧クラスなので対象外です。
- ブランチは作業の指示の対象(`+component`、`+controller`)の外ですが、`remove_branch` を削除の対象にし、`Branch/gui_content.m` の検査を消すために同じ扱いにしました。

### 外した物体の削除

- 新しい関数 `tools.delete_layers(c_layer)` が、物体とその下の物体を `delete` します(母線は機器ごと、機器と局所制御器は局所制御器ごと)。層の型で振り分けます。
- 対象: `remove_component`、`replace_component`(`Controllers="drop"` で残らない局所制御器を含む)、`remove_bus`(機器とその制御器ごと)、`remove_branch`、`remove_local_controller`、`remove_global_controller`、`add_local_controller` による AVR・ガバナ・PSS の置き換えと、AVR 以外への置き換えで行き場のない PSS。
- `add_global_controller` が接続の検査で止まるときは、作った制御器を `delete` してから止まります。
- `add_local_controller` で置き換えのログに古い制御器のタグを使う箇所は、削除の前にタグを読むよう順序を変えました。

### 外した物体を参照し得るものの確認(コード読み)

| 参照し得るもの | 保持しているもの | `delete` の影響 |
|---|---|---|
| `ResultODE`、`ResultPF`、`ResultCPF`、`ResultOPF` | タグと数値、系統(`ResultBase.a_PowerNetwork`) | なし |
| `ResultLIN`(層の結果を含む) | 数値、名前、系統 | なし |
| `Scenario` | 外乱のタグ、系統 | なし(シナリオは削除しない。`remove_scenario` は従来どおり参照を外すだけ) |
| `GlobalController.controlledUnits` | 機器のハンドル | なし。制御対象の機器と母線は、制御器がある間は削除も置換もできない |
| 編集の記録(`sct_stale`) | 文字列 | なし |
| `DrawerNetDiagram` | 表と数値 | なし |
| `DrawerModelGUI` | 表示中のモデルのハンドル | 既に `isvalid` を確かめ、"The model has been deleted." を表示する |

`delete` で壊れるものは見つかりませんでした。

## 削除した検査

行番号は基準コミットのものです。

| ファイル:行 | 検査 | 起きえない理由 |
|---|---|---|
| `@Component/Component.m:250` | `get.c_Vequilibrium` の `isempty(obj.a_Bus)` | 機器は `Bus` が作り、作成直後に `a_Bus` を設定する。外した機器は削除される |
| `@Component/get_sys.m:76-82` | 系統のない機器でハンドルを作る分岐(`build_stale`) | 同上。母線は必ず系統にある(`add_bus` だけが作り、`remove_bus` は削除する) |
| `@Component/get_sys.m:133,182,204-207` | `~isempty(obj.a_Bus)` | 同上 |
| `@Component/get_variable_map.m:41` | `~isempty(obj.a_Bus)` | 同上 |
| `@Component/private/gc_routes.m:14` | `isempty(comp.a_Bus) \|\| isempty(...a_PowerNetwork)` | 同上 |
| `@Component/validate.m:258` | 系統のない機器は機器の接続マップを使う分岐 | 同上 |
| `@Component/set_input.m:38` | `GUILDA:Component:InputNotConnected` | 同上 |
| `@Bus/get_sys.m:50` | `~isempty(obj.a_PowerNetwork)` | 母線は必ず系統にある |
| `@Bus/private/controlling_gcon.m:14` | `isempty(net)` | 同上 |
| `@Branch/gui_content.m:15` | `isempty(obj.a_Bus)` | ブランチは `add_branch` が両端を設定して作り、`remove_branch` は削除する |
| `@LocalController/get_sys.m:41-62,86-93` | 親・系統のない制御器でハンドルを作る分岐、`net_of` | 制御器は `add_local_controller` が作って付け、外すと削除する |
| `@LocalController/observed_component.m:16` | `~isa(comp, "Component")` → `[]` | 親を上にたどると必ず機器に着く(PSS の親は AVR、AVR の親は機器) |
| `@LocalController/resolve_observe.m:18` | 機器がないときの分岐 | `resolve_observe` は付けた直後だけ呼ばれる |
| `@LocalController/parent_equilibrium.m:14` | `isempty(obj.a_Component)` | 制御器は必ず親を持つ |
| `@LocalController/validate.m:20` | `GUILDA:LocalController:ValidateNotAttached` | 同上 |
| `@GlobalController/get_sys.m:55-77,91-107` | 系統のない制御器の名前付けとハンドルの作成 | 大域制御器は `add_global_controller` が作って付け、外すと削除する |
| `@PowerNetwork/add_global_controller.m:63-69` | `GUILDA:PowerNetwork:GconOtherNetwork` | `GlobalController` のコンストラクタが、制御対象がこの系統の機器であることを確かめる(`InvalidComponent`)。機器は必ず母線と系統にある |
| `_auxiliary/@SolverODE/build_index.m:166-176` | `GUILDA:SolverODE:ForeignControlledUnit` | 同上。制御対象の機器と母線は、制御器がある間は削除も置換もできない |
| `_auxiliary/@PowerSystemModel/get_Hz.m:12-19` | 系統がないときの `GUILDA.config("Model","Hz")` | 親を上にたどると必ず系統に着く |
| `+controller/@local_LQR/get_equilibrium.m:12` | `GUILDA:local_LQR:NotOnComponent` | 役割 `"local"` の制御器は機器に直接付く |
| `+controller/+governor/@abstract/initial_output.m:12` | `isa(comp, "Component") && any(comp.sv_u == "Pmech")` | ガバナは機器に直接付き、`add_local_controller` が出力 `Pmech` が機器の入力にあることを確かめる |

なくなったエラー ID(メッセージのカタログからも削除): `GUILDA:Component:InputNotConnected`、`GUILDA:LocalController:ValidateNotAttached`、`GUILDA:local_LQR:NotOnComponent`、`GUILDA:PowerNetwork:GconOtherNetwork`、`GUILDA:SolverODE:ForeignControlledUnit`。

## 残した検査

| ファイル | 検査 | 残す理由 |
|---|---|---|
| `_auxiliary/@LayerPackage/LayerPackage.m:88` (`set.s_tag`) | `~isempty(obj.parent)` | 構築途中: コンストラクタがタグを設定する時点では親が未設定。`add_local_controller` も親を付ける前にタグを付け替える |
| `+controller/@local_LQR/log_change.m:8` | `~isempty(obj.a_Component)` | 構築途中: コンストラクタが `Q`、`R`、`V0` を代入すると set メソッドから呼ばれる |
| `@GlobalController/GlobalController.m:151-163` | `isa(arg, 'Component')`、別の系統の機器 | 利用者の入力(`add_global_controller` の制御対象)の検査 |
| `@GlobalController/get_sys.m` の `GlobalControllerPort` | 制御対象の出力・入力の不足 | 起きえる: 追加の後で局所制御器を編集すると、出力の行き先がなくなることがある |
| `@PowerNetwork/add_global_controller.m` の `GconTagInUse` | タグの重複 | 親の検査ではない(対象外) |
| `@Component/get_variable_map.m:76`、`@LocalController/get_sys.m`・`observed_component.m` の `while isa(..., "LocalController")`、`PowerNetwork/handle_edit.m`、`SolverLIN/point_vector.m`、`SolverLIN/solve.m:43`、`Parameter.m:63` | 層の型での振り分け | 振り分けであり、親の検査ではない |
| `tools/slack_bus_index.m`、`SolverLIN/solve.m:168`、`SolverODE/private/check_islands.m`、`import_matpower.m:126`、`Bus.m:138` | `isempty(b.a_Component)` | 機器のない母線は起きえる |
| `PowerNetwork/calculate_powerflow.m:72`、`initialize.m:251` | `isempty(obj.a_Bus)` | 母線のない系統は起きえる |
| `Scenario`、`add_scenario`、`ResultBase`、`ResultODE`、`ResultPF/Export` | `a_PowerNetwork` が空 | シナリオと結果はモデルの物体ではなく、系統なしで存在できる |

## テストの変更

- 直接の生成をやめ、`add_*` で作る形に直しました: `test_F28`(AVR_DC1)、`test_F30`(ガバナ。既存の `build_gov` を使用)、`test_F7`(AGC、local_LQR の Toolbox の確認)。
- 外した物体の確認を、親が空であることから `isvalid` が false であることに変えました: `test_F1`、`test_F21`、`test_F30`、`test_I66`、`test_F33`(削除したブランチの表示は "The model has been deleted.")。`test_F1` の母線の削除で、母線の機器も削除されることを加えました。
- 新しいテスト `test_F1_model_building` の節 "Model objects are created only by the add methods" で、8 種類の直接の生成が `MATLAB:class:MethodRestricted` になることを確かめます。
- テスト用のスタブの機器(`BadComponentStub`、`BadJacobianStub`、`BadPortStub`、`HessianStub`)のコンストラクタを `add_component` の引数 `(タグの番号, parameter, 設定)` に合わせ、新しい補助関数 `DebugScript.helper.stub_component` で登録して母線に付けます(`test_F22`、`test_F7`)。`test_I93`、`test_I105` の引数の入れ替え(`Replace`、`Regexp`)は不要になったので削除しました。
- 意図がなくなったため削除したテスト: 親のない制御器の `validate` が `ValidateNotAttached` で止まること(`test_F22`)、親のない層の `get_sys` が stale を確かめないこと(`test_I71`)、外した負荷の `set_input` が `InputNotConnected` で止まること(`test_F3_initialize`)、系統のない機器の `get_sys`・`validate` がハンドルを作ること(`test_F3_edit_handling`)、付ける前の AGC の `get_sys` が `GlobalControllerPort` を出すこと(`test_F7`。追加時の `GconPorts` が同じ原因を示すことの確認に置き換え)。

## 未確認・残りの事項

- 利用者が自分で書くモデルクラスのコンストラクタを公開のままにすると、そのクラスは直接作れます。文書(`model-implementation.html`、`feature-model-building.html`、`class-design.html`)で `Access` の宣言を求めていますが、強制はしていません。
- `_GUILDAobject/+controller/validate.m`(開発者用の記号計算のスクリプト)は `controller.avr.AVR_DC1("avr")` を直接作るため動きません。変更前から `set_odefcn(60)` の引数が合わず動かないスクリプトで、対象外としました。
- 保存した MAT ファイルから読み込んだ系統の外した物体は、読み込みのときにはもう系統にないので問題になりません。古い MAT ファイルに、親の外れた物体が単独で保存されている場合の読み込みは確かめていません。
