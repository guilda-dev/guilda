# MATLAB の最低バージョン調査(静的調査)

> 基準コミット `a29b51e1`(`refactor/design-alignment`)、調査日 2026-11-07。下限を R2023b に下げる修正(`fix/matlab-r2023b-compat`、`58bd238d`)の後に走査をやり直し、結論と一覧を更新しています(同日)。コードから使用機能を集め、MathWorks のドキュメントで導入リリースを調べた静的調査です。古いリリースで実際に動かしてはいません。複数リリースでの実行確認は GitHub Actions のワークフロー(別セッション)の結果で行います。

## 結論

- **下限は R2023b です。** これを決めているのは次の 3 点です。
  - `ode` オブジェクト一式(`ode`、`odeEvent`、`matlab.ode.options.ODE15s`、`InitialSlope` など)。時間応答シミュレーション(`SolverODE`)の全体で使います。
  - `readstruct` の JSON 読み込み(起動時の設定読み込み `@GUILDA/private/get_config.m:28,33`)。
  - `gitrepo`(`@GUILDA/gitpull.m:10`)。`GUILDA.gitpull` だけです。
- 2026-11-07 の判断で下限を R2023b に下げ、それまで下限を決めていた 2 つの検証関数を置き換えました。
  - `mustBeBetween(x,a,b,"closed")`(R2025a)→ `mustBeInRange(x,a,b)`(R2020b、既定で両端を含む)。`_GUILDAsystem/_auxiliary/@SolverODE/SolverODE.m:39-40`、`@SolverODE/private/validate_options.m:6-7`。範囲外のときのエラー ID は `MATLAB:validators:mustBeInRange` になります。
  - `mustBeRow`(R2024b)→ 非公開の `validateTimeSpanSize` の中で `isrow` を確かめ、行でなければ従来と同じ ID `MATLAB:validators:mustBeRow` のエラーを出す形にしました。`@Scenario/add_disturbance.m:19` の検証関数は `validateTimeSpanSize` だけです。受け付ける値(要素 1 個か 2 個の行)は変わりません。
- **R2023b より新しい項目で残るもの**
  - `ode` の `SeparateComplexParts` プロパティ(R2025a)。`SolverODE.m:41` と `DefaultTimeSimulation.json` の既定値にあります。`makeODE`(`@SolverODE/private/makeODE.m:12-20`)は `ode` の公開プロパティのうち設定にあるものだけを代入するので、R2024b 以前ではこの設定が **黙って無視される** だけで、エラーにはならないと見込まれます([推測] 実行では未確認)。そのときの説明(設定が効かない旨)が要ります。
  - `figure()` に UI コンポーネントを置ける挙動(R2025a)。GUILDA は uifigure を前提に判定しているので下限には効きません。
- **次に新しい項目**
  - R2022b: `arguments (Output)` / `(Input)`(ほぼ全メソッド)。
  - R2022a: `writelines`、`clim`、`fileread` の `Encoding`、`writetable` の `QuoteStrings="minimal"`、グリッドレイアウトの `"fit"` で表を合わせる挙動。
- 走査のやり直しでは、`a29b51e1` 以降に入った変更(`get_sys` の整理、モデル GUI など)で増えた組み込みの項目は `repmat`/`rmfield` への文字列引数と `pi` だけで、どれも古いものです。下限を上げる項目はありませんでした。
- 表記(`check_requirement.m`、README、`_GUILDAdoc`)の「R2025a 以降」は、CI で R2023b の動作を確かめてから改めます。
- CI(下記)の 1 回目で静的調査の見落とし 3 点、2 回目で 2 点(OPF の `linprog` の既定アルゴリズム、テストの段階の照合)が見つかり、直しました。直した後の 3 回目の CI はまだ流していません。

## CI の結果

### 1 回目(GitHub Actions run 42351404631)

> `guilda-dev/guilda` のブランチ `test/matlab-release-matrix`、`fix/matlab-r2023b-compat` の最初の修正(`58bd238d`)を含む状態。MATLAB 本体だけの構成(ツールボックスなし)で、`DebugScript.run_all` の small を実行。ログは `gh run download 42351404631 --repo guilda-dev/guilda -n logs-<release>-matlab`(`2-load.log`、`3-tests-results.csv` など)。

| リリース | 件数 | PASS | FAIL | 判定 | 主な失敗 |
|---|---|---|---|---|---|
| R2022b | 469 | 7 | 460 | 起動で失敗 | `readstruct` が `.json` を読めない(`get_config`)。以降 `PowerNetwork` などが使えない。下限未満なので想定どおり |
| R2023a | 469 | 7 | 460 | 起動で失敗 | R2022b と同じ |
| R2023b | 469 | 19 | 448 | 失敗 | 445 件が `Unknown table property: VariableTypes.`(下記 1)。ほか `Assertion failed.` 2 件(F19、F8) |
| R2024a | 469 | 19 | 448 | 失敗 | R2023b と同じ |
| R2024b | 469 | 346 | 121 | 失敗 | 87+2 件が `MATLAB:UNIQUE:SetOrderOccurrence`(下記 2)、7 件が「message identifier ... must specify the message text」(下記 3)、`Assertion failed.` 2 件(F21、I56)。残りはツールボックスがないための失敗 |
| R2025a | 462 | 439 | 21 | 成功 | 21 件はすべてツールボックスがないための失敗(想定どおり) |
| R2025b | 462 | 439 | 21 | 成功 | 同上 |
| R2026a | 462 | 439 | 21 | 成功 | 同上 |
| R2026b | 462 | 439 | 21 | 成功 | 同上 |

- 件数は KNOWN 1 件と SKIP 1 件を含みます。R2024b 以前で件数が 7 件多いのは、テスト名の切り詰めで段階(medium/large)の指定が外れ、small に入ったためです(2 回目の 2 を参照)。
- 見つかった点と直し方(`fix/matlab-r2023b-compat` の 2 つ目の修正)
  1. **表の `Properties.VariableTypes`(R2024b)**。`_GUILDAsystem/_auxiliary/@Parameter/Parameter.m:66,84,99` で列のクラスを読んでいました。すべての部品の作成で通るので、R2023b・R2024a ではほぼ全テストが失敗しました。`string(varfun(@class, tab, "OutputFormat", "cell"))` に置き換えました。`table('Size',…,'VariableTypes',…)` の作成側(`Parameter.m:59`)は R2018a からあるので変えていません。
  2. **`unique` の順序指定と出現位置の併用**。`@Scenario/private/getTimeSpan.m:20` の `unique(…, "sorted", "first")` は R2024b では `MATLAB:UNIQUE:SetOrderOccurrence` のエラーです(R2025a から併用できる。R2023b・R2024a は 1 の失敗に隠れて未確認)。値だけを使っているので `"first"` を外しました。時間応答シミュレーションの全体で通ります。
  3. **`assert` のメッセージにエラー ID を渡すテスト**。`assert(cond, DebugScript.helper.msg_id(ME))` のように第 2 引数が ID の形(`GUILDA:X:Y`)の文字列だと、アサーションが失敗したときに R2024b の `assert` はそれを ID とみなし、本文がないとしてエラーにしました(R2025a 以降はアサーションが失敗しないので通らず、挙動は未確認)。実行時コードではなくテスト(`+DebugScript`、23 ファイル 109 か所)の問題で、本当の失敗(2 の `unique`)を隠していました。`assert(cond, "%s", id)` に直しました。
- `Assertion failed.` の 4 件
  - R2023b・R2024a の F19(`AModelColumnAbsentFromParameter_csv…`)と F8(`MATPOWERImportRejectsUnsupportedGencost`): どちらもエラー ID を確かめるテストで、途中で部品を作るので 1 のエラーに置き換わったと見込まれます([推測])。
  - R2024b の I56(`APointThatViolatesKCL…`): 後半の `net.simulate` が 2 のエラーで止まり、期待した `GUILDA:SolverODE:Stale` にならなかったと見込まれます([推測])。
  - R2024b の F21(`AnLQRDrivingAnUnknownInput…`): R2025a 以降でも同じ失敗があり、ツールボックスがないための失敗として扱われています。リリースには依存しません。
- 走査スクリプト(`scan_matlab_features`)に、1〜3 を正規表現で拾う項目(`syntax` の `table Properties.VariableTypes`、`unique order + occurrence`、`assert message is an identifier`)を足しました。直す前のコードでは 3 件・1 件・108 件を拾い、直した後は 0 件です。

### 2 回目(GitHub Actions run 42353112661)

> 1 回目の修正(`fe4b9030`)の後。MATLAB 本体だけの構成(matlab)と、Optimization・Control System・Symbolic Math の各ツールボックスを入れた構成(toolboxes)の 2 通り。

| リリース | matlab: 件数 / PASS / FAIL | toolboxes: 件数 / PASS / FAIL | 判定 |
|---|---|---|---|
| R2022b | 469 / 7 / 460 | 469 / 7 / 460 | 起動で失敗(`readstruct` の JSON。下限未満で想定どおり) |
| R2023a | 469 / 7 / 460 | 469 / 7 / 460 | 同上 |
| R2023b | 469 / 443 / 24 | 469 / 466 / 1 | 失敗(matlab: I92 1 件、toolboxes: I90 1 件。下記 1、2) |
| R2024a | 469 / 443 / 24 | 469 / 467 / 0 | matlab は I92 1 件で失敗、toolboxes は成功 |
| R2024b | 469 / 443 / 24 | 469 / 467 / 0 | 同上 |
| R2025a | 462 / 439 / 21 | 462 / 460 / 0 | 成功 |
| R2025b | 462 / 439 / 21 | 462 / 460 / 0 | 成功 |
| R2026a | 462 / 439 / 21 | 462 / 460 / 0 | 成功 |
| R2026b | 462 / 439 / 21 | 462 / 460 / 0 | 成功 |

- matlab の FAIL のうち、ツールボックスがないための失敗(R2025a 以降で 21 件、R2024b 以前で 23 件)は想定どおりとして扱われます。
- 見つかった点と直し方(`fix/matlab-r2023b-compat` の 3 つ目の修正)
  1. **テスト名の切り詰め(R2024b 以前)**。R2024b 以前はテスト名を 63 文字(当時の `namelengthmax`。R2026a では 2048)で切ります。`+DebugScript/test_levels.m` の名前は切らない名前なので、63 文字を超える 7 件のテストの段階が照合できず、既定の small で動いていました。その 1 つが I92 の `AFailedOPFOnASplitNetworkNamesTheIslands_AlsoWhenTheOPFStopsWithAnInternalError`(large、OPF を使う)で、ツールボックスがないと `GUILDA:require_toolbox:Unavailable` で止まります。テストの診断文(`assert(…, "%s", msg_id(ME))`)が ID だけなので、CI はツールボックスがないための失敗と見分けられませんでした。実行時コードの問題ではなく、`+DebugScript/run_all.m` で両方の名前を 63 文字に切って照合するようにしました。
  2. **`linprog` の既定アルゴリズム `"dual-simplex-highs"`(R2024a)**。DC OPF(`linprog`)で R2023b の Optimization Toolbox が `Invalid value for OPTIONS parameter Algorithm` で止まりました。HiGHS のアルゴリズム名は R2024a からです。既定値を `"dual-simplex"` に改めました(`SolverOPF.m:44`、`@GUILDA/config/DefaultOptimalPowerFlow.json`、`_GUILDAdoc/developer/feature-opf.html`)。R2024a 以降の `"dual-simplex"` は `"dual-simplex-highs"` と同じ(R2026a で `optimoptions` が `dual-simplex-highs` を返すことを確認)で、R2023b では従来の双対シンプレックス法です。そのため R2023b では解法が変わります。`quadprog` の `"interior-point-convex"` と `fmincon` の `"interior-point"` は R2023b にもあります。選択肢の `"interior-point"` は R2024a 以降は HiGHS の内点法、R2023b では従来の内点法です。

## 方法

1. 対象: `@GUILDA`、`_GUILDAsystem`、`_GUILDAobject` の `.m`(パスに `未` を含むものと `archive/` を除く、553 ファイル)。
2. 機械的な抽出: `+DebugScript/+helper/scan_matlab_features.m` を MATLAB R2026a で実行しました。
   ```matlab
   GUILDA.addpath;
   tab = DebugScript.helper.scan_matlab_features(csv="scan.csv");
   ```
   - `mtree` で構文解析し、識別子、`matlab.*` などのパッケージ名、Name=Value の名前、組み込み関数への文字列引数("Name",value 形式のオプション名の候補)、`obj.name` のフィールド名を集めます。
   - `which` で MATLAB 本体・ツールボックスのものだけを残します(GUILDA のパスを通した状態で引くので、GUILDA 側の同名関数は除かれます)。
   - 言語機能(`arguments (Output)`/`(Repeating)`、`opt.?Class`、`"..."` など)は正規表現で拾います。
   - 結果は約 1400 行(`a29b51e1` で組み込みの識別子 411、文字列引数 787、Name=Value 52 など。修正後は 1375 行で、識別子 409、文字列引数 794、Name=Value 52)。
3. 補足の手作業: `ode` オブジェクトに代入しているプロパティ(`o.Xxx = ...`)、UI コンポーネントにドットで代入しているプロパティ、`"fit"` の使い方、`height`/`width` を表以外に使う箇所は grep で確認しました。
4. 導入リリース: 各関数・プロパティの MathWorks ドキュメント(現行 R2026b 版)の "Version History" を参照しました。オプションは、そのオプションを追加したリリースを調べています。ページに記載がないものは、旧リリースのアーカイブ文書(オンラインで読めるのは R2021b 以降)との比較や MATLAB Answers で補い、表に「未確認」と書いています。
5. `+DebugScript` と `_GUILDAverification` も同じスクリプトで走査しましたが、下限を上げる項目はありませんでした(`testsuite`、`regexpPattern`(R2020b)、`matlab.ode.options.ODE23t/ODE45`(R2023b)など。走査スクリプト自身は `dictionary`(R2022b)と非公開の `mtree` を使います)。

### 走査の限界

- オブジェクトのメソッド呼び出し(`obj.method(...)`)とドット代入のプロパティは、組み込み関数と同名のものしか自動では拾えません。`ode`、UI、グラフィックスの主要なものは上記 3 の手作業で補いましたが、網羅ではありません。
- 実行時にしか決まらない名前(`o.(props{ip})`、`set(h, name, value)` に変数で渡すものなど)は拾えません。
- ある機能の「挙動の変化」(例: R2024a で `~` を `OnOffSwitchState` に使うと戻り値の型が変わる)は、使い方を個別に読まないと判断できません。GUILDA ではそのような使い方は見つけていません([未確認] 網羅的には読んでいない)。

## 一覧(MATLAB 本体、新しい順)

場所は代表的なもの(先頭の数か所)。URL の `…/` は `https://www.mathworks.com/help/matlab/ref/` です。

| 項目 | 使用箇所(file:line) | 導入 | 出典 | 確認 |
|---|---|---|---|---|
| `ode` の `SeparateComplexParts` | `@SolverODE/SolverODE.m:41`、`@SolverODE/private/validate_options.m:8` | R2025a | …/ode.html("Since R2025a") | 確認。R2024b 以前では `makeODE` が代入しないので下限には効かない見込み([推測]) |
| `figure()` に UI コンポーネントを置ける | `@DrawerModelGUI/private/is_ui_container.m:18-21`(`isUIFigure` で uifigure と見分ける) | R2025a | …/uibutton.html | 確認。GUILDA は uifigure を前提に判定しているので下限には効かない |
| `ode` オブジェクト、`solve(o,t0,tf)`、`ODEResults`(`Time`、`Solution`) | `@SolverODE/private/makeODE.m:10`、`@SolverODE/solve.m:147` | **R2023b** | …/ode.html、…/matlab.ode.oderesults.html | 確認 |
| `ode` の `Solver`、`SolverOptions`、`EventDefinition`、`InitialValue`、`InitialSlope`、`MassMatrix`、`Jacobian`、`ODEFcn`、`RelativeTolerance`、`AbsoluteTolerance` | `@SolverODE/solve.m:51,64,65,93,144`、`@SolverODE/set_equations.m:29-35` | R2023b | …/ode.html | 確認(「Since」の表記なし = ode と同時) |
| 行列を `MassMatrix` に、関数ハンドルを `Jacobian` に代入(自動変換) | `@SolverODE/set_equations.m:29-35` | R2023b | …/odemassmatrix.html、…/odejacobian.html | 推測(変更の記載なし) |
| `odeEvent`(`EventFcn`、`Response="stop"`) | `@SolverODE/solve.m:65` | R2023b | …/odeevent.html | 確認("stop" は推測) |
| `matlab.ode.options.ODE15s`(`OutputFcn`) | `@SolverODE/SolverODE.m:38`、`@SolverODE/solve.m:64` | R2023b | …/matlab.ode.options.ode15s-properties.html | 確認 |
| `matlab.ode.Options`、`matlab.ode.SolverID` | `@SolverODE/SolverODE.m:37-38`、`@SolverODE/private/validate_options.m:4-5` | R2023b(推定) | 単独のページなし(404)。`ode.html` の例の出力に `SolverID` が出る | **未確認** |
| `readstruct` の JSON 読み込み | `@GUILDA/private/get_config.m:28,33`(`@GUILDA/config/Default*.json`) | **R2023b** | …/readstruct.html | 確認 |
| `gitrepo` | `@GUILDA/gitpull.m:10` | **R2023b** | …/gitrepo.html | 確認(`GUILDA.gitpull` だけ) |
| `arguments (Output)` | 400 か所(例: `@GUILDA/GUILDA.m:45`) | R2022b | …/arguments.html | 確認 |
| `arguments (Input)` 属性 | 508 か所(例: `@GUILDA/config.m:2`) | R2022b(推定) | …/arguments.html(Output と一緒に記載) | 推測 |
| `writelines` | `@GUILDA/private/set_config.m:16`、`@PowerNetwork/export_csv.m:95` | R2022a | …/writelines.html | 確認 |
| `clim` | `@DrawerNetDiagram/DrawerNetDiagram.m:150`、`@DrawerNetDiagram/draw_graph_network.m:189` | R2022a | …/clim.html | 確認 |
| `fileread` の `Encoding` | `@GUILDA/doc.m:61` | R2022a | R2021b/R2022a のアーカイブ文書の比較 | 確認(比較) |
| `writetable` の `QuoteStrings="minimal"` | `@Scenario/export_csv.m:74` | R2022a | R2021b/R2022a のアーカイブ文書の比較 | 確認(比較) |
| `uigridlayout` の `"fit"` を `uitable`/`uiimage` に効かせる | `@DrawerModelGUI/private/build_page.m:24-25` | R2022a(`"fit"` 自体は R2019b) | …/matlab.ui.container.gridlayout-properties.html、MATLAB Answers 1469656 | `"fit"` 自体は未確認(二次資料) |
| Name=Value 構文 | 例: `@SolverPF/solve.m:113`、`@GUILDA/private/set_config.m:13` | R2021a | matlab_prog/validate-name-value-arguments.html | 確認 |
| `formattedDisplayText` | `@SolverOPF/build_problem.m:128` | R2021a | …/formatteddisplaytext.html | 確認 |
| `jsonencode` の `PrettyPrint` | `@GUILDA/private/set_config.m:13,18` | R2021a | R2021b 文書にあり、R2021a 文書はオフライン | 未確認 |
| `mustBeInRange` | `@SolverODE/SolverODE.m:39-40`、`@SolverODE/private/validate_options.m:6-7` | R2020b | …/mustbeinrange.html | 確認 |
| `readstruct`(XML) | `_GUILDAsystem/_auxiliary/SystemTools/msg.m:54` | R2020b | …/readstruct.html | 確認 |
| `readlines` | `@GUILDA/GUILDA.m:57` | R2020b | …/readlines.html | 確認 |
| `mustBeA`、`mustBeText`、`mustBeNonzeroLengthText`、`mustBeFolder`、`mustBeScalarOrEmpty`、`mustBeValidVariableName` | 例: `@PowerNetwork/simulate.m:214,219`、`@Scenario/Scenario.m:113` | R2020b | …/mustbea.html ほか | 確認 |
| `digitsPattern`(pattern) | `@Scenario/private/check_tag.m:4` | R2020b | …/digitspattern.html | 確認 |
| `matlabRelease` | `@GUILDA/private/export_class_database.m:263` | R2020b | …/matlabrelease.html | 確認 |
| `turbo` | `@DrawerNetDiagram/DrawerNetDiagram.m:31` | R2020b | …/turbo.html | 確認 |
| `height`/`width` を表以外に | `@ResultODE/Plot.m:29` | R2020b | …/height.html、…/width.html | 確認 |
| `detectImportOptions` の `VariableNamingRule` | `@Scenario/import_csv.m:50` | R2020b | …/readtable.html | 確認(readtable の記載) |
| `uilabel` の `WordWrap` | `@DrawerModelGUI/private/build_header.m:13` | R2020b | …/matlab.ui.control.label.html | 確認 |
| `uitreenode` の `ContextMenu`、uifigure の `uicontextmenu` | `@DrawerModelGUI/private/build_tree.m:15,43` | R2020a | …/matlab.ui.container.contextmenu.html、MATLAB Answers | 未確認(有力) |
| `renamevars` | `@PowerNetwork/import_csv.m:327` | R2020a | …/table.renamevars.html | 確認 |
| `uihtml`(`HTMLSource`、`Data`) | `@DrawerModelGUI/private/build_page.m:17-18` | R2019b | …/uihtml.html | 確認(プロパティは推測) |
| `tiledlayout`/`nexttile`(`TileSpacing="compact"`) | `@ResultOPF/Plot.m:27`、`@ResultPF/Plot.m:21` | R2019b | …/tiledlayout.html | 確認("compact" は推測) |
| `arguments` ブロック | 908 か所 | R2019b | …/arguments.html | 確認 |
| `arguments (Repeating)` と名前-値引数の併用 | `@PowerNetwork/simulate.m`、`@PowerNetwork/get_sys.m` ほか 11 ファイル | R2020b 以前 | matlab_prog/validate-repeating-arguments.html | **未確認**(最初のリリース不明) |
| `opt.?ClassName` | `@DrawerNetDiagram/DrawerNetDiagram.m:100`、`@MethodDynamic/MethodDynamic.m:35` ほか 6 か所 | R2020b 以前 | matlab_prog/validate-name-value-arguments.html(日付なし)、MATLAB Answers 760546 | **未確認** |
| `matches`、`namedargs2cell` | `@PowerNetwork/handle_edit.m:34`、`@PowerNetwork/import_csv.m:122` | R2019b | …/string.matches.html、…/namedargs2cell.html | 確認 |
| `uiimage`(`ScaleMethod`) | `@GUILDA/setting.m:67`、`@DrawerModelGUI/private/build_page.m:20` | R2019a | …/uiimage.html | 確認(プロパティは推測) |
| `uigridlayout`(`Padding`、`RowSpacing`、`Scrollable`、`Layout.Row/Column`) | `@DrawerModelGUI/render.m:38`、`@DrawerModelGUI/private/build_parameter_tab.m:16-17` | R2018b | …/uigridlayout.html | 関数は確認、`Scrollable` は未確認 |
| `xline` | `@ResultCPF/Plot.m:32`、`@ResultLIN/Plot.m:31` | R2018b | …/xline.html | 確認 |
| `removevars`、`normalize`、`table`(`Size`+`VariableTypes`) | `_GUILDAobject/+network/@IEEE68bus/private/add_avr_pss.m:13`、`@DrawerNetDiagram/private/plot_edge.m:32`、`@Parameter/Parameter.m:59` | R2018a | …/removevars.html、…/double.normalize.html | `Size`+`VariableTypes` は未確認 |
| `uitree`(`SelectionChangedFcn`)、`uiconfirm`、`uimenu` の `MenuSelectedFcn` | `@DrawerModelGUI/private/build_tree.m:14,16`、`@GUILDA/setting.m:122` | R2017b | …/uitree.html、…/uiconfirm.html | 確認 |
| `isfile`/`isfolder`、`lsqminnorm`、`decomposition`、`vecnorm` | `@GUILDA/doc.m:59`、`@MethodNewtonRaphson/solve.m:47`、`@SolverODE/set_equations.m:23`、`@SolverLIN/solve.m:239` | R2017b | 各関数のページ | 確認 |
| `matlab.lang.OnOffSwitchState` | `@SolverODE/SolverODE.m:41` | R2017a | …/matlab.lang.onoffswitchstate-class.html | 確認 |
| `mustBeMember`、`mustBePositive`、`mustBeNonnegative`、`mustBeInteger`、`mustBeReal` | 多数 | R2017a | …/mustbemember.html ほか | 確認 |
| `"..."` 文字列リテラル | 2322 行 | R2017a | MathWorks の string arrays 製品ページ | 確認(リファレンス以外) |
| `string`、`strlength`、`compose`、`pad`、`splitlines`、`join`、`jsonencode`/`jsondecode`、`detectImportOptions`、`fillmissing`、`matlab.net.base64encode` | 多数 | R2016b | 各関数のページ | 確認(`fillmissing` の "constant" は推測) |
| `uifigure`、`uibutton`、`uialert`、`uilabel` など | `@GUILDA/setting.m:9`、`@DrawerModelGUI/DrawerModelGUI.m:50` | R2016a | …/uifigure.html ほか | 確認(`uitextarea` などは個別に未確認) |
| `graph`、`conncomp`、`plot(graph, Layout="force")` | `@PowerNetwork/initialize.m:269`、`@DrawerNetDiagram/set_network.m:32-34` | R2015b | …/graph.plot.html、…/graph.conncomp.html | 確認(`UseGravity`/`Iterations` は未確認) |
| `matlab.lang.makeUniqueStrings` | `@LocalController/validate.m:140` | R2014a | …/matlab.lang.makeuniquestrings.html | 確認 |
| `odeset`/`ode15s`(`Mass`、`JPattern`、`Events`) | `@MethodDynamic/solve.m:73-77` | R2006a 以前 | …/odeset.html | 確認 |
| `mtree`(非公開) | `@GUILDA/private/collect_call_graph.m:238` | 不明(非公開関数) | なし | 未確認。文書生成(`GUILDA.doc` の更新)だけで使う |

`@...` で始まる場所は、`@GUILDA/` 以外は `_GUILDAsystem/_auxiliary/` または `_GUILDAsystem/` の下です(例: `@SolverODE` は `_GUILDAsystem/_auxiliary/@SolverODE`、`@PowerNetwork` は `_GUILDAsystem/@PowerNetwork`)。

## 任意のツールボックス

### Optimization Toolbox(潮流計算の `fsolve`、OPF)

| 項目 | 使用箇所 | 導入 | 出典 | 確認 |
|---|---|---|---|---|
| `solvers(prob)` | `@SolverOPF/optimoption.m:17,59` | **R2022b** | https://www.mathworks.com/help/optim/ug/optimizationproblem.solvers.html | 確認 |
| `Objective` を構造体(名前つき目的)で与える | `@SolverOPF/build_problem.m:41-43`(`struct("GenCost",0)`)、`@SolverOPF/solve.m:48-50` | R2022a | …/optim/ug/optim.problemdef.optimizationvalues.paretoplot.html | 間接的に確認 |
| `sin`/`cos`/`^` を最適化変数に直接使う(`fcn2optimexpr` なし) | `@SolverOPF/private/build_branch.m:76,81,92,126-129` | R2020b 前後 | Loren のブログ(2020-10)、…/optim/ug/fcn2optimexpr.html | **未確認** |
| `solve(prob,x0,"Solver",s,"Options",o)`(x0 は構造体、5 出力) | `@SolverOPF/solve.m:47` | R2018b(Name-Value 形) | …/optim/ug/optim.problemdef.optimizationproblem.solve.html | 確認(`lambda` 出力は推測で R2017b) |
| `optimproblem`、`optimvar`(`Type`、`LowerBound`、`UpperBound`)、名前つき `Constraints` | `@SolverOPF/private/build_bus.m:27`、`@SolverOPF/private/build_branch.m:47` | R2017b | …/optim/ug/optimproblem.html、…/optim/ug/optimvar.html | 確認 |
| `fsolve` と `optimoptions` の名前(`SpecifyObjectiveGradient`、`MaxFunctionEvaluations`、`MaxIterations`、`FunctionTolerance`、`PlotFcn`) | `@MethodFsolve/solve.m:17-34` | R2016a | …/optim/ug/current-and-legacy-option-name-tables.html | 確認 |
| `UseParallel`、`OutputFcn` | `@MethodFsolve/solve.m:17-18` | R2016a 以前 | …/optim/ug/fsolve.html | 未確認(古い)。R2026b で `true/false` は非推奨(`"off"/"auto"/"on"` へ) |

- OPF の追加の下限は R2022b(`solvers`)で、MATLAB 本体の下限より低いです。

### Control System Toolbox(`Format="ss"`、LQR)

| 項目 | 使用箇所 | 導入 | 出典 | 確認 |
|---|---|---|---|---|
| `ss`(`StateName`/`InputName`/`OutputName`)、`dss`、`tf`、`lqr`、`feedback`、`bode` | `_GUILDAobject/+controller/@local_LQR/design_gain.m:26-35`、`@ResultLIN/get_ss.m:121,434`、`_GUILDAobject/+controller/+modeling/get_environment.m:47,58,79` | R2006a 以前 | https://www.mathworks.com/help/control/ref/ss.html ほか | 確認 |
| `ssdata` | `_GUILDAobject/+controller/@local_LQR_retrofit/local_LQR_retrofit.m:76,80` | 古い | ページ 404 | 未確認(古いのは確実) |

- 追加の下限はありません。

### Symbolic Math Toolbox

- 実行時コードでは `license`/`ver` での有無の確認だけです(`@MethodNewtonRaphson/has_symbolic.m:6`)。`symvar`(`@MethodNewtonRaphson/MethodNewtonRaphson.m:65`)は MATLAB 本体の関数です。開発用スクリプトは調べていません。

## 未決の点

1. CI で確かめたい点
   - 2 回目の 1、2 を直した後に、R2023b〜R2024b の matlab と R2023b の toolboxes で全テストが通るか。件数が R2025a 以降と同じ 462 件になるか。
   - ユーザー設定に `Algorithm_linprog = "dual-simplex-highs"` を保存している場合、R2023b では OPF が同じエラーで止まります([推測])。
   - R2024b 以前で `SeparateComplexParts` が `makeODE` で黙って無視されるか(上記の [推測] の確認)。黙って無視される場合、その旨の説明をどこに書くか。
   - 「未確認」の項目のうち、下限 R2023b に関わるもの: `matlab.ode.SolverID`/`matlab.ode.Options`(`ode` と同時の R2023b と推定)。`Repeating` と名前-値引数の併用、`opt.?Class`、最適化変数への `sin`/`cos` は R2020b 前後と見込まれ、R2023b より古いので結論には影響しない見込みです。
   - R2022b で何が失敗するか(`ode` オブジェクトがないので時間応答シミュレーションは動かない見込み)。
2. CI の結果を見てから、`check_requirement.m`、README、`_GUILDAdoc` の表記を R2023b に改めます。
3. 走査で拾えないもの(「走査の限界」)が残っています。CI の結果で補います。
4. `str2mat`(`@DrawerNetDiagram/draw_graph_network.m:93,94,134,135`)は古い関数で、上限側(将来の削除)の懸念です。下限には関係しません。
