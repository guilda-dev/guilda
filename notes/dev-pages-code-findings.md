# For Developer のページ作成で見つかったコードの問題

> 基準コミットは `765663b`(統合ブランチ `refactor/design-alignment`、2026-11-04)です。For Developer の「クラス」(`_GUILDAdoc/developer/class-*.html`)と「機能」(`_GUILDAdoc/developer/feature-*.html`)のページを書く途中で、コードを追って見つかった点を集めました。HTML のページは時点に依存しない説明にするので、ここに分けて記録します。このノートではコードを変更していません。修正するかどうかは保守者が決めます。
>
> **追記(2026-11-04、`feature/ieej-report-models` への統合時):** このブランチでは `EventODE` は `Scenario`(`_auxiliary/@Scenario/`)に置き換わり、`EventODE` クラスはありません。SIM-3 と「確認して外した項目」の `EventODE` の行番号は基準コミットのものです。現在のコードでは、解列の状態の除外は `SolverODE.initial_condition`(`_auxiliary/@SolverODE/SolverODE.m`)、オフセットの組み立ては `Scenario/compile.m` の `phase_offsets` にあります。SIM-3 の内容が現在のコードでも成り立つかは[未確認]です。

**ラベル**

- **[事実]** 基準コミットのコードを読んで確認
- **[再現]** 基準コミットで MATLAB R2026a を実行して確認(2026-11-04)
- **[報告]** ページを書いたセッションの報告で、このノートでは再確認していません

**分類**

- **バグ**: 誤った結果やエラーになる
- **仕様・コメント不一致**: コードと、ヘルプ・コメント・文書の記述が食い違う
- **整理**: 動作に影響しないが、整理した方がよい

**パス** 先頭が `_GUILDAobject/`、`+DebugScript/`、`_GUILDAdoc/` 以外は `_GUILDAsystem/` からの相対パスです。

## 一覧

| ID | 対象 | 概要 | 分類 |
|---|---|---|---|
| CPF-1 | `SolverCPF` の `build_layout` | `iv_CPFX` が消えず、`UseInternalState=true` の後の `false` が失敗 | バグ |
| CPF-2 | `SolverCPF` の `pf_equation` | `Fdx(1)` が母線の累計 `PQG` を使う | バグ |
| CPF-3 | `SolverCPF` の `pf_equation`、ヘルプ | `LoadBus` の母線のすべての機器を増やす。ヘルプは「負荷」 | 仕様・コメント不一致 |
| CPF-4 | `SolverCPF.solve` | 平衡点のエラー ID が他の解析と違う | 整理 |
| CPF-5 | `NewtonRaphsonMethod.solve` | 最後の反復で収束しても警告 | バグ |
| CPF-6 | `SolverCPF.ArcLength` | 名前は弧長だが、値は距離の 2 乗 | 整理 |
| OPF-1 | `PowerNetwork.build_opf_problem` | `Description` の誤字 "Optimal Poer Flow" | 整理 |
| OPF-2 | `SolverOPF/optimoption.m` | 進捗のコメント "(stage 3)" | 整理 |
| INI-1 | `PowerNetwork.initialize` | `QdistributionRule` を渡さず `"Qmax"` に届かない | 仕様・コメント不一致 |
| INI-2 | `GlobalController.get_equilibrium` | 呼ばれる順がヘルプと文書の逆 | 仕様・コメント不一致 |
| GC-1 | `GlobalController` | `Jacobi_dx` / `Jacobi_Y` を使うが抽象メソッドにない | バグ |
| GC-2 | `GlobalController.get_sys` | コメントの入力が「出力」になっている | 仕様・コメント不一致 |
| GC-3 | `GlobalController.set_parent` | アクセスが広い | 整理 |
| LC-1 | `LocalController`、`GlobalController` の `children` | `para_dynamics` を含まない | バグ |
| LC-2 | `LocalController/validate.m` | classdef で宣言していない | 整理 |
| LC-3 | `LocalController.key` | 宣言の形が `Component` / `GlobalController` と違う | 整理 |
| DOC-1 | `class-design.html` | `getCompPQ` のシグネチャに `obj` がない | 仕様・コメント不一致 |
| BR-1 | `Branch.build_opf_problem` | 引数名が宣言とファイルで違う | 整理 |
| BR-2 | `Branch` のコンストラクタ | `assert(..., "ERROR: ...")` | 整理 |
| MSG-1 | `error(msg(...))` / `warning(msg(...))` | ID が付かない | 仕様・コメント不一致 |
| MSG-2 | `msg.m` | `MSGnums > args` が数値とセルの比較 | バグ |
| IO-1 | `tools.network_to_mpc` | PG に潮流の P でなく OPF の `P0` を書く | 仕様・コメント不一致 |
| PF-1 | `PowerNetwork.calculate_powerflow` | スラックの自動選択が編集として残る | 仕様・コメント不一致 |
| PF-2 | `SolverPF` の `PFconst_slack` | 角度に `atan(Vim/Vre)` を使う | バグ |
| GEN-1 | `component.generator.abstract` | `avr` / `pss` / `governor` と `set_*` が動かない | バグ |
| NET-1 | 同梱ネットワーク、`import_csv` | タグが `"PowerNetwork"` のまま | 整理 |
| SIM-1 | `SolverODE.getODEJacobian` | 大域制御器の入力に `u_connect` を掛けない | バグ |
| SIM-2 | `SolverODE.getODEJacobian` | 大域制御器のブロックの列の並び | 整理 |
| SIM-3 | 解列(トリップ) | 機器を解列しても局所制御器の状態は残る | 仕様・コメント不一致 |
| SIM-4 | `SolverODE.getNextPhase` | 平衡点からの再開が発電機だけ | 仕様・コメント不一致 |
| LIN-1 | 質量行列 | シミュレーションと線形化で呼び方が違う | 整理 |
| LIN-2 | `Component.get_sys_alone` | 線形化は `I` 依存を拒否、シミュレーションは対応 | 仕様・コメント不一致 |
| DEAD-1 | `SolverODE` ほか | 使われていないコード | 整理 |
| DBG-1 | `DebugScript.helper.build_ieee14` | コメントが実際と違う | 仕様・コメント不一致 |
| WEB-1 | `_GUILDAdoc/images/about/*.svg` | 英語の文字だけ | 整理 |
| WEB-2 | `class.html` / `method.html` | エラー表示が言語の切り替えに追従しない | バグ |
| WEB-3 | `method.html` | 電話の幅で 420px に広がる | バグ |

確認して外した項目は[最後の節](#確認して外した項目)にあります。

## 連続潮流計算(CPF)

### CPF-1 `iv_CPFX` が消えず、次の実行が失敗する

- **対象:** `_auxiliary/@SolverCPF/private/build_layout.m`、`private/pf_equation.m`
- **内容:** `build_layout` は `UseInternalState=true` のときだけ `Component.iv_CPFX` を書き(49 行、76 行)、`false` のときに消しません。前の実行の添字が残ったまま、`pf_equation` が `x(i_Comp.iv_CPFX)` を状態として使います。
- **再現・根拠:** [再現] `network.IEEE9bus` で `UseInternalState=true` を実行します。負荷 `component.load.impedance` に `getCompPQ` がないため `GUILDA:build_layout:MissingGetCompPQ` で止まりますが、止まる前に発電機の `iv_CPFX` は書かれています。続けて同じネットワークで `UseInternalState=false` を実行すると、`pf_equation` で「行列乗算に対する次元が正しくありません」になります。新しく作ったネットワークでは `false` の実行は成功します。
- **影響:** 一度 `true` を試すと、そのネットワークでは `false` の CPF が使えなくなります。エラーの文章から原因はわかりません。
- **分類:** バグ

### CPF-2 `Fdx(1)` が母線の累計 `PQG` を使う

- **対象:** `_auxiliary/@SolverCPF/private/pf_equation.m` 43 行
- **内容:** `UseInternalState=true` で、状態を持つ機器の 1 本目の式を `Fdx(1) = PQG(1) - real(compSeq)` に置き換えます。`PQG` はその母線の機器のループで足し上げている途中の値で、その機器の電力ではありません。また、`LoadBus` の母線では `PQG` に `~isLoad`(0)が掛かるので、`Fdx(1) = -real(compSeq)` になります。
- **再現・根拠:** [事実] コードを読んで確認しました。1 母線に状態を持つ機器が 2 台以上ある例、`LoadBus` に発電機の母線を含めた例は実行していません。
- **影響:** 1 母線に状態を持つ機器が 1 台で、その母線が `LoadBus` にない場合だけ正しい式になります。それ以外では、誤った曲線になるか収束しない可能性があります。
- **分類:** バグ

### CPF-3 `LoadBus` の母線のすべての機器を増やす

- **対象:** `_auxiliary/@SolverCPF/private/pf_equation.m` 39 行、`_auxiliary/@SolverCPF/SolverCPF.m` のヘルプ
- **内容:** 増やす対象は母線単位で決まり(`isLoad = ismember(i_Bus.str_tag, sv_load)`)、その母線の発電機も含むすべての機器の電力に `(1 + λ)` を掛けます。`UseInternalState=true` では `or(isLoad, useInt)` なので、すべての母線のすべての機器を増やします。一方、クラスのヘルプは "scales the loads of LoadBus"、`UseInternalState` のヘルプは "all loads are scaled" と書いています。`LoadBus` プロパティのヘルプ("The power the components of these buses draw")と `feature-cpf.html` はコードどおりです。
- **再現・根拠:** [事実] コードを読んで確認しました。
- **影響:** 発電機のある母線を `LoadBus` に入れると、負荷だけを増やすつもりで発電も増えます。`UseInternalState=true` では `LoadBus` の指定が結果に効きません。
- **分類:** 仕様・コメント不一致(意図した仕様かどうかは未決)

### CPF-4 平衡点のエラー ID が他の解析と違う

- **対象:** `_auxiliary/@SolverCPF/solve.m` の `check_network`
- **内容:** CPF は独自の確認で `GUILDA:SolverCPF:NoEquilibrium` / `GUILDA:SolverCPF:StaleEquilibrium` を出します。`simulate` と `linearize` は `PowerNetwork.require_equilibrium` を使い、`GUILDA:PowerNetwork:EquilibriumStale` を出します。
- **再現・根拠:** [事実] `SolverODE.m` 170 行、`SolverLIN/solve.m` 29 行。テスト `+DebugScript/test_F5_cpf.m` は CPF の ID を固定しています。
- **影響:** 同じ状態で解析によって ID が違うので、利用者が ID で分岐しにくくなります。CPF は `require_equilibrium` と違い、古い `f_*` を作り直しません。
- **分類:** 整理

### CPF-5 最後の反復で収束しても警告が出る

- **対象:** `_auxiliary/@NewtonRaphsonMethod/NewtonRaphsonMethod.m` の `solve`(142 行)
- **内容:** 反復の後の判定が `if iteration >= MaxIt` で、収束したかを見ません。`iteration == MaxIt` で収束した場合も `GUILDA:NewtonRaphsonMethod:MaxIteration` の警告が出ます。
- **再現・根拠:** [再現] `NRMFcn = @(x) x`、`InitVal = 0`、`MaxIter = 1` では 1 回目で収束し(`iteration = 1`)、それでも警告 "…failed to converge." が出ました。
- **影響:** CPF の補正で、収束した点にも収束失敗の警告が出ることがあります。
- **分類:** バグ

### CPF-6 `ArcLength` は距離の 2 乗

- **対象:** `_auxiliary/@SolverCPF/SolverCPF.m`、`private/correct.m`
- **内容:** 補正の条件は `(x - x_current)' * (x - x_current) = ArcLength` で、`ArcLength` は弧長の 2 乗です。ヘルプには "|x - x_current|^2 = ArcLength" とあり、説明とは一致しています。
- **再現・根拠:** [事実]
- **影響:** 名前から弧長と思って値を決めると、ステップの大きさを誤ります。
- **分類:** 整理

## 最適潮流計算(OPF)

### OPF-1 問題の `Description` の誤字

- **対象:** `@PowerNetwork/build_opf_problem.m` 45 行
- **内容:** `"Optimal Poer Flow ("` は "Optimal Power Flow" の誤字です。
- **再現・根拠:** [事実]
- **影響:** `prob.Description` と表示に誤字が出ます。
- **分類:** 整理

### OPF-2 進捗のコメント

- **対象:** `_auxiliary/@SolverOPF/optimoption.m` 57 行
- **内容:** "External backends (stage 3) add their own capability check at this point." の "stage 3" は開発計画の段階です(`opf-requirements.md`)。コードのコメントに進捗を書いています。
- **再現・根拠:** [事実]
- **影響:** 計画が変わると意味がなくなります。
- **分類:** 整理

## 初期化

### INI-1 `QdistributionRule` の `"Qmax"` に届かない

- **対象:** `@PowerNetwork/initialize.m` 123 行、`@Bus/set_equilibrium.m`
- **内容:** `Bus.set_equilibrium` は `QdistributionRule`(`"baseMVA"` / `"Qmax"`)を受け取りますが、唯一の呼び出し元 `initialize` は `"rm_PQ"` だけを渡します。`initialize` にもこのオプションはありません。
- **再現・根拠:** [事実] `set_equilibrium(` の呼び出しは `initialize.m` 123 行だけです。
- **影響:** `"Qmax"` の配分は使えません。
- **分類:** 仕様・コメント不一致

### INI-2 `GlobalController.get_equilibrium` の呼ばれる順

- **対象:** `@PowerNetwork/initialize.m` 111–114 行、`@GlobalController/GlobalController.m` 34 行、`_GUILDAdoc/developer/model-implementation.html`
- **内容:** `initialize` は大域制御器の `get_equilibrium` を、母線の `set_equilibrium`(機器の平衡点を書く処理)より前に呼びます。ヘルプは "Called by PowerNetwork.initialize after the equilibria of the components are set."、`model-implementation.html` は "Called after the components are set." と書いています。
- **再現・根拠:** [事実]
- **影響:** 機器の平衡点を読む大域制御器は、前回の平衡点(初回は空)を読みます。
- **分類:** 仕様・コメント不一致(コードと文書のどちらに合わせるかは未決)

## GlobalController / LocalController

### GC-1 `Jacobi_dx` / `Jacobi_Y` が抽象メソッドにない

- **対象:** `@GlobalController/GlobalController.m` の `set_odefcn`(213–214 行)
- **内容:** `set_odefcn` は `obj.Jacobi_dx` と `obj.Jacobi_Y` を使いますが、抽象メソッド(31–52 行)にも基底クラスにも定義がありません。`Component` と `LocalController` のような数値微分の既定もありません。
- **再現・根拠:** [事実]
- **影響:** ヤコビ行列を書かないサブクラスはエラーなしに作れ、`f_JacobiDx` を呼んだとき(シミュレーションのヤコビ行列、`get_sys`)に初めて失敗します。
- **分類:** バグ

### GC-2 `get_sys` のコメントの入力

- **対象:** `@GlobalController/GlobalController.m` 132–134 行
- **内容:** コメントは "The inputs are the outputs of the controlled units" ですが、入力 `sv_u` は制御対象の状態 `sv_x` です(158 行の確認、クラスのヘルプ 5 行)。
- **再現・根拠:** [事実]
- **影響:** 読み手が入力の意味を誤解します。
- **分類:** 仕様・コメント不一致

### GC-3 `set_parent` のアクセス

- **対象:** `@GlobalController/GlobalController.m` 218 行
- **内容:** `methods (Access={?Component,?LocalController,?PowerNetwork})` ですが、`GlobalController.set_parent` を呼ぶのは `PowerNetwork`(`add_global_controller`、`remove_global_controller`)だけです。`Component` から呼ぶ `set_parent` は局所制御器のものです。
- **再現・根拠:** [事実]
- **影響:** 動作への影響はありません。
- **分類:** 整理

### LC-1 `children` に `para_dynamics` がない

- **対象:** `@LocalController/LocalController.m` 298 行、`@GlobalController/GlobalController.m` 229 行、`_auxiliary/@LayerPackage/reset_edit.m`
- **内容:** `LocalController.children` は入れ子の制御器だけ、`GlobalController.children` は `{}` を返します。`Component.children` は `Parameter` オブジェクト(`para_dynamics` など)も含みます。`reset_edit` は `children` をたどるので、制御器の `Parameter` の編集状態と編集履歴はリセットされません。
- **再現・根拠:** [事実] リセットされないことはコードで確認しました。それが解析の結果に影響する例は確認していません。
- **影響:** `initialize` の後も、制御器のパラメータの編集状態が残ります。
- **分類:** バグ(影響の大きさは未確認)

### LC-2 `validate.m` を classdef で宣言していない

- **対象:** `@LocalController/validate.m`
- **内容:** 公開メソッドのファイルがありますが、`LocalController.m` に宣言がありません。`Component` は `methods(Hidden)` で宣言しています(`Component.m` 241–244 行)。
- **再現・根拠:** [事実]
- **影響:** `Component` と違い、`validate` が隠しメソッドになりません。宣言のコメントもありません。
- **分類:** 整理

### LC-3 `key` の宣言の形

- **対象:** `@LocalController/LocalController.m` 33–34 行
- **内容:** `LocalController.key` は `properties(Abstract, SetAccess=protected, Hidden)` で、サブクラスがコンストラクタで代入します(例 `AVR_ST1.m` 57 行)。`Component.key` は `properties(Abstract,Constant)`、`GlobalController.key` は `properties(Abstract, Constant, Hidden=true)` です。
- **再現・根拠:** [事実]
- **影響:** 同じ役割のプロパティの書き方が 3 クラスで揃っていません。`LocalController` では、インスタンスを作らないと `key` を読めません。
- **分類:** 整理

## Component、Branch と文書

### DOC-1 `getCompPQ` のシグネチャ

- **対象:** `_GUILDAdoc/developer/class-design.html`(モデルの契約の行)
- **内容:** `getCompPQ(x, V, u, param)` と書いていますが、`build_layout` はインスタンスメソッドとして呼び(`i_Comp.getCompPQ(x,V,u,params)`)、実装は `getCompPQ(obj,x,V,u,para)` です(`_GUILDAobject/+component/+generator/@park/park.m` 75 行など)。エラーの文章も `getCompPQ(obj,x,V,u,param)` です。
- **再現・根拠:** [事実]
- **影響:** 静的メソッドとして実装すると呼べません。
- **分類:** 仕様・コメント不一致

### BR-1 `Branch.build_opf_problem` の引数名

- **対象:** `@Branch/Branch.m` 119 行、`@Branch/build_opf_problem.m` 1 行
- **内容:** 宣言は `rm_V`、ファイルは `Vvar` です。
- **再現・根拠:** [事実]
- **影響:** 動作への影響はありません。ヘルプと生成文書で名前が揃いません。
- **分類:** 整理

### BR-2 `Branch` のコンストラクタの `assert`

- **対象:** `@Branch/Branch.m` 88–90 行
- **内容:** `assert(isreal(opt.R), "ERROR: R must be a real number.")` のように、ID のない英文で止めます。他の検査は `error(msg(...))` です。
- **再現・根拠:** [事実]
- **影響:** メッセージが XML のカタログになく、ID もありません。
- **分類:** 整理

## メッセージ

### MSG-1 `error(msg(...))` に ID が付かない

- **対象:** `_auxiliary/SystemTools/msg.m` と、その呼び出し全般
- **内容:** `msg` は文章だけを返すので、`error(msg("GUILDA:..."))` / `warning(msg(...))` の `ME.identifier` と `lastwarn` の ID は空です。一方、コメントには "Error with ID GUILDA:PowerNetwork:EquilibriumStale" のように ID があるかのような記述があります(`@PowerNetwork/check_edit.m` 11 行など)。ID が付くのは、`import_csv` の `assert`(`GUILDA:import_csv:MissingColumns` など)、`SolverODE` と `CalculateInitialCondition` で作る `MException`、`+opffcn/apply.m` の `MException`、`LayerPackage.m` 160 行の `assert` だけです。
- **再現・根拠:** [再現] `LoadBus="B999"` の CPF で `ME.identifier` は空でした。テストは `DebugScript.helper.msg_id` で文章から ID を逆引きしています(そのヘルプにも「identifier が付かない」とあります)。
- **影響:** 利用者は ID でエラーを判別できません。
- **分類:** 仕様・コメント不一致

### MSG-2 `msg.m` の引数の数の比較

- **対象:** `_auxiliary/SystemTools/msg.m` 71 行
- **内容:** `elseif MSGnums > args` は数値とセル配列 `args` の比較です。`narg` と比べるつもりと思われます(77 行の `args - MSGnums` も同じ)。
- **再現・根拠:** [事実] 実行はしていません。MATLAB ではセルに `>` を使うとエラーになるので、引数の数が合わないときに、意図したメッセージの代わりに MATLAB のエラーになります。
- **影響:** プレースホルダの数を誤った呼び出しの原因がわかりにくくなります。
- **分類:** バグ

## データの入出力

### IO-1 `tools.network_to_mpc` の PG

- **対象:** `+tools/network_to_mpc.m` 72 行
- **内容:** 発電機の PG / QG に OPF の初期値 `para_OPF.P0` / `Q0` を書きます。VG は潮流の `V` です。ヘルプは PG の出どころを書いていません。
- **再現・根拠:** [再現] `network.IEEE9bus` では `mpc.gen` の PG / QG はすべて 0 で、潮流の P は 0.716 / 1.63 / 0.85 pu(母線 1 / 2 / 3)です。報告にあった「往復で最大 0.586 pu」は、このノートでは再現の手順を確認していません。
- **影響:** mpc から潮流を始めるとき(`runpf`)、または `import_matpower` で戻すとき、発電機の出力が元のネットワークと違います。OPF 用の変換(ヘルプの "for OPF")としては意図どおりかもしれません。
- **分類:** 仕様・コメント不一致(意図は未決)

## 潮流計算

### PF-1 スラックの自動選択が編集として残る

- **対象:** `@PowerNetwork/calculate_powerflow.m` 41–45 行、`@Bus/Bus.m` の `set.l_isSlack`、`_GUILDAdoc/developer/api-design.html` の機能の表
- **内容:** スラックが未設定だと `bus.l_isSlack = true` を設定し、`set.l_isSlack` が `"Slack"` の編集を記録します。初期化済みのネットワークでは平衡点が古くなり、スラックは呼び出しの後も設定されたままです。API Design の表は潮流計算の「net の変更」を「なし」としています(注記にスラックの選択は書かれています)。関数のヘルプと `feature-power-flow.html` はコードどおりです。
- **再現・根拠:** [再現] `network.IEEE9bus` でスラックを外して `calculate_powerflow` を実行すると、`tab_editLog` に `"slack bus -> B001"`(log `"Slack"`)が追加され、スラックは設定されたままでした。
- **影響:** 潮流計算だけで、その後の `simulate` などが `EquilibriumStale` で止まることがあります。
- **分類:** 仕様・コメント不一致

### PF-2 スラックの角度に `atan(Vim/Vre)`

- **対象:** `_auxiliary/@SolverPF/private/PFconst_slack.m` 5 行
- **内容:** スラックの角度の式が `atan(Vim/Vre)` です。値の範囲は ±90° で、`Vre = 0` で 0 除算になります。ヤコビ行列(`-Vim/Vdist, Vre/Vdist`)は `atan2` と同じです。
- **再現・根拠:** [事実] 実行はしていません。
- **影響:** スラックの角度の指定が ±90° を超えると、指定と違う解になるか収束しません。
- **分類:** バグ

## モデルのクラス

### GEN-1 発電機の旧制御器スロット

- **対象:** `_GUILDAobject/+component/+generator/@abstract/abstract.m` 85–116 行
- **内容:** getter `get.avr` / `get.pss` / `get.governor` は存在しないプロパティ `SpecificControllers` を読みます。`set_avr` / `set_pss` / `set_governor` は宣言だけで、メソッドのファイルがありません。いずれも `<@Deprecated>` です。
- **再現・根拠:** [事実] `SpecificControllers` はリポジトリのどこにも定義されていません。
- **影響:** `gen.avr` などを読むとエラーになり、旧 API の案内(`add_local_controller` を使う)が出ません。
- **分類:** バグ

### NET-1 ネットワークのタグ

- **対象:** `_GUILDAobject/+network/@*`、`@PowerNetwork/import_csv.m`
- **内容:** 同梱ネットワーク(`IEEE9bus` など)のタグは既定の `"PowerNetwork"` のままです。`import_csv(..., Network=obj)` はタグを設定しません。`Network` を省略した `import_csv` はフォルダ名をタグにします。
- **再現・根拠:** [再現] `network.IEEE9bus` と `network.IEEE14bus` の `str_tag` は `"PowerNetwork"` でした。
- **影響:** 編集履歴やメッセージで、どのネットワークかが区別できません。
- **分類:** 整理

## シミュレーション

### SIM-1 ヤコビ行列で大域制御器の入力に `u_connect` を掛けない

- **対象:** `_auxiliary/@SolverODE/SolverODE.m` の `getODEJacobian`(687–702 行)
- **内容:** `getODEFunction` は、解列した制御対象の入力を 0 にするため `u_connect * u_GC` を渡します(632–635 行)。`getODEJacobian` は `u_GC` をそのまま渡し、列にも `u_connect` を掛けません。
- **再現・根拠:** [事実] 実行はしていません。
- **影響:** 制御対象を解列した区間で、ヤコビ行列が式と一致しません。ode15s の収束が遅くなるか失敗する可能性があります(解が誤るかは未確認)。
- **分類:** バグ

### SIM-2 大域制御器のブロックの列の並び

- **対象:** `_auxiliary/@SolverODE/SolverODE.m` 691、701–702 行
- **内容:** 列は `lh_GC = [iv_odeX; iv_odeU]` ですが、足すブロックは `[Axx, Bxv, Bxu, Bxi]` の 4 列分です。大域制御器には V と I のポートがなく `Bxv` / `Bxi` が空なので、たまたま合っています。
- **再現・根拠:** [事実]
- **影響:** 現状は正しい値です。ポートの扱いを変えると壊れます。
- **分類:** 整理

### SIM-3 解列した機器の局所制御器の状態

- **対象:** `_auxiliary/@EventODE/EventODE.m` の `getInitialCondition`(328–337 行)と `getStateTags`
- **内容:** 解列では、状態のタグが `TripUnit` に一致する変数を `EM` で除きます。局所制御器の状態には制御器自身のタグが付くので、機器を解列しても制御器の状態は除かれず、NaN にもならず、積分が続きます。
- **再現・根拠:** [事実] コードを読んで確認しました。実行はしていません。
- **影響:** 解列中の制御器の状態が意味のない値に動き、結果に残ります。
- **分類:** 仕様・コメント不一致(期待する扱いが文書にありません)

### SIM-4 平衡点からの再開が発電機だけ

- **対象:** `_auxiliary/@SolverODE/SolverODE.m` の `getNextPhase`(841 行)
- **内容:** 解列が終わった機器を平衡点(`get_equilibrium(V, 0, 0, 0)`)から再開する処理は、`isa(..., 'component.generator.abstract')` の機器だけです。他の機器は平衡点を計算し直しません。
- **再現・根拠:** [事実] 分岐はコードで確認しました。他の機器がどの値から再開するかは確認していません。
- **影響:** 発電機以外の動的な機器の解列からの復帰が、発電機と違う扱いになります。
- **分類:** 仕様・コメント不一致

## 線形化

### LIN-1 質量行列の呼び方

- **対象:** `+tools/read_mass.m`、`@Component/get_sys_alone.m` 24 行、`@LocalController/get_sys_alone.m` 26 行、`@GlobalController/GlobalController.m` 184 行
- **内容:** シミュレーションは `tools.read_mass` で `f_Mass([],[],[],[],[])` を読み、定数でなければ止めます。線形化は `f_Mass(0,x,V,I,u)` を呼びます。
- **再現・根拠:** [事実]
- **影響:** 定数の質量行列なら同じ値です。引数に依存する質量行列は、シミュレーションでは止まり、線形化では通ります。
- **分類:** 整理

### LIN-2 `I` に依存するモデル

- **対象:** `@Component/get_sys_alone.m` 37 行
- **内容:** 線形化は電流 `I` に依存するモデルを `GUILDA:Component:CurrentDependence` で拒否します。シミュレーションは `I` を引数に渡して対応します。
- **再現・根拠:** [事実]
- **影響:** シミュレーションできるモデルを線形化できません。
- **分類:** 仕様・コメント不一致(制約として文書にするか、対応するかは未決)

## 使われていないコード

### DEAD-1

- **対象:** `_auxiliary/@SolverODE/SolverODE.m` の `getSubJacobian`(925 行)、`_auxiliary/@SolverODE/private/checkSimulationTime.m`、`+tools/+for_ss/`
- **内容:** `getSubJacobian` はコメントアウトした行からしか参照されていません。`checkSimulationTime` と `tools.for_ss.*`(`collect`、`dae2ode`、`feedback`、`kron`、`reorder`)は、そのフォルダの外から呼ばれていません(`+DebugScript/` を含む)。
- **再現・根拠:** [事実] `grep` で確認しました。
- **影響:** 読み手が線形化やシミュレーションの経路と誤解します。
- **分類:** 整理

## テスト

### DBG-1 `build_ieee14` のコメント

- **対象:** `+DebugScript/+helper/build_ieee14.m` 6 行
- **内容:** コメントは「コンストラクタ内で CSV を読み込むだけで、平衡点は未設定」ですが、`network.IEEE14bus` のコンストラクタは初期化まで行います。
- **再現・根拠:** [再現] 作った直後の `sct_edit.str_flag` は `"initialized"`、`l_staleEquilibrium` は false でした。
- **影響:** テストの前提を誤解します。
- **分類:** 仕様・コメント不一致

## 文書のサイト

### WEB-1 About の図が英語だけ

- **対象:** `_GUILDAdoc/images/about/*.svg`(5 ファイル)
- **内容:** 図の中の文字("One-way flow from big plants"、"Socialization" など)が英語だけで、日本語の表示でも切り替わりません。
- **再現・根拠:** [事実] SVG の `<text>` を確認しました。
- **影響:** 日本語の読者に英語が残ります。
- **分類:** 整理

### WEB-2 エラー表示が言語の切り替えに追従しない

- **対象:** `_GUILDAdoc/class.html` 374、389 行付近、`_GUILDAdoc/method.html` 67、95 行
- **内容:** 正常な表示は `guilda-langchange` で描き直しますが、読み込みエラーと引数不足の表示は `tr(...)` で一度だけ作り、イベントを受けません。
- **再現・根拠:** [事実] コードを読んで確認しました。ブラウザでは確認していません。
- **影響:** エラーの表示は、再読み込みするまで前の言語のままです。
- **分類:** バグ

### WEB-3 `method.html` が電話の幅で広がる

- **対象:** `_GUILDAdoc/method.html`
- **内容:** 電話の幅で、ページが 420px まで広がり横にスクロールします。
- **再現・根拠:** [報告] このノートでは確認していません。原因の要素も特定していません。
- **影響:** 電話で読みにくくなります。
- **分類:** バグ

## 確認して外した項目

- **`SolverODE.restore_working_data` が `rv_Xoffset` / `rv_Uoffset` を機器だけ戻す:** オフセットを設定するのは `EventODE.setEventCondition`(216、255 行)で、対象は機器だけです。局所制御器と大域制御器のオフセットは変わらないので、現状では不具合ではありません。ただし既定値が違います(機器は空、制御器は `0` と `@(t) 0`)。
- **`+tools/+for_ss` が「線形化の経路にない」:** 経路にないだけでなく、どこからも呼ばれていません。DEAD-1 にまとめました。
