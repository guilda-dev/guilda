# シミュレーターアプリ(`GUILDA.launch_gui`)

> 基準: `refactor/design-alignment` の `3526f520`(2026-11-15)。第1-0段階(`HistoryGUILDA`、`DrawerOptionDialog`)は `feature/gui-history-option` で実装しました。仕組みの説明は `_GUILDAdoc/developer/feature-gui.html#history-option` にあり、このノートは計画、決定事項、残りの事項だけを記録します。

## 画面の構成(決定済み)

- 上部のタブ: モデル構築、潮流計算、OPF、連続潮流計算、時間応答シミュレーション、線形化。
- 左側: ネットワーク図(`GraphNetDiagram`、マージ済み)を常に表示し、その下に小さな実行記録の欄を置きます。欄には GUI の操作が実行したコードを表示し、セッションをスクリプトとして書き出せます。
- 右側: タブごとのパネル。
  - モデル構築: クリックした要素の `obj.launch_gui(container)`(`DrawerModelGUI`)を埋め込みます。
  - 解析のタブ: 生成したオプションのフォーム、実行ボタン、「結果を解析」(`result.launch_gui()` を開く)。
- 参考にした設計: `~/workspace/MATLABmooc_eeglab` の `MoocHistory`、`MoocProcessLog`、`mooc_ui_run_steps`、`step_export` の `localScript`。

## 段階

| 段階 | 内容 | 状態 |
|---|---|---|
| 1-0 | `HistoryGUILDA`(実行記録とスクリプトの書き出し)と `DrawerOptionDialog`(`functionSignatures.json` から作るオプションのフォーム) | マージ済み(`aaf33b49`) |
| 1a | `DrawerModelGUI` に追加・削除のボタンを付け、`DrawerOptionDialog.ask` で入力し、`HistoryGUILDA` で実行・記録する | `feature/gui-model-actions` で実装(未マージ)。署名の追加は `220e62ed` |
| 1b | `ResultBase.launch_gui` と `DrawerResultGUI`。Result の `plot_*` を Graph クラスに移す段階の後 | `feature/result-gui` で実装(未マージ) |
| 2a | `DrawerGUILDA`(アプリの枠、`GUILDA.launch_gui`、開始画面、系統モデルの作成タブ) | `feature/guilda-app-frame` で実装(未マージ) |
| 2b | 潮流計算・最適潮流計算・連続潮流計算・近似線形解析のタブ | `feature/guilda-app-analysis-tabs` で実装(未マージ)。`DrawerOptionDialog` の `Value` は `4641fa2a` |
| 2c | 時間シミュレーションのタブ | `feature/guilda-app-sim-tab` で実装(未マージ) |
| 3-1 | `DrawerTagPicker`(タグとモデルキーを検索して表から選ぶピッカー、要素の表、キーの表) | `feature/gui-tag-picker` で実装(未マージ) |
| 3-2a | オプションのフォームの再設計とタグ・Key の欄へのピッカーの組み込み(`DrawerOptionDialog`、`gui_forms.json`) | `feature/gui-forms` で実装、マージ済み(`35408fdd`) |
| 3-2b | 画面構成と表示の改善、GUI の文字の英語化(`DrawerGUILDA`、`DrawerModelGUI`、`DrawerResultGUI`) | `feature/gui-layout` で実装(未マージ) |

## 決定事項(第1-0段階)

### コード文字列だけを実行の元にする

- `HistoryGUILDA.run` はコード文字列そのものを `eval`(`evalc`)します。MOOC の設計にあった別のクロージャは持ちません。そのため、書き出したスクリプトは GUI が実行した内容と必ず一致します(ユーザーの決定)。
- 記録は無効にも削除にもしません。モデルの編集は積み上がります(ユーザーの決定)。
- 失敗した記録は一覧に残し、スクリプトからは除きます(ユーザーの決定)。失敗した実行はワークスペースを変えません。

### 評価するワークスペース

- コードは `@HistoryGUILDA/private/eval_workspace.m` の中で実行します。この関数の変数は `varargin` と `varargout` だけです。保存した変数(構造体)を展開し、`evalc` でコードを実行し、`varargin`・`varargout` 以外のすべての変数を回収して構造体に戻します。
- そのため、ユーザーのコードは `obj`、`s_code`、`l_ok` などの名前も自由に使えます。`varargin` と `varargout` だけは使えません(`set_variable` はエラーにします)。
- エラーは `eval_workspace` から `run` に伝わり、`run` が受け止めます。回収前に止まるので、保存した変数は実行前のままです。

### スクリプトの節

- 指示では「Group ごとに `%% <Group>` の節」でしたが、グループをまとめ直すと実行順が変わり、再現できない場合があります(モデル構築 → 潮流計算 → モデル構築)。そこで、同じグループが続く範囲ごとに節を作り、実行順を保ちます。同じグループの節が複数回出ることがあります。

### `functionSignatures.json` の対象を増やした

- `DrawerOptionDialog` は `functionSignatures.json` だけを読みます。このファイルにはモデルを作る・削除するメソッドと `simulate` しかなかったため、`GUILDA.update_keymap` の `sig_methods` に `PowerNetwork.add_bus`、`calculate_powerflow`、`calculate_optimal_powerflow`、`calculate_continuation_powerflow` を加えて作り直しました。コード補完にもこれらが加わります。
- 既定値は `purpose` の末尾の `Default: <式>.` だけに頼ります(生成側が保証する形)。式を評価して初期値にします。解析メソッドの既定値は `GUILDA.config(...)` の式なので、現在の設定値が表示されます。評価できない式(`obj.solver_CPF.LoadBus`、文章の既定値)の欄は空にし、プレースホルダーに式を表示します。
- 型は、最初のクラス名と `choices=` の式だけを使います。サイズは JSON にないため、数値の欄は配列も受け付けます。`Size` 付きの `double` の設定(`40371b2c`)は `[0.1 0.02]` の形で表示し、そのまま比べます。

### 配色と `uifigure` の判定を共有した

- `DrawerModelGUI/private/gui_palette.m` と `is_ui_container.m` は private のため、新しい 2 クラスからは呼べません。同じ内容を `_GUILDAsystem/+tools/gui_palette.m` と `+tools/is_ui_container.m` に置きました(フォルダ構成の規約: 複数のクラスが使う補助関数は `+tools`)。
- `DrawerModelGUI` は今も private の複製を使います(この段階では `@DrawerModelGUI` を編集しない指示のため)。第1a段階で `tools.*` に切り替え、private の 2 ファイルを削除する予定です。

## 決定事項(第1a段階、2026-11-16)

- `functionSignatures.json` に加えたもの(`220e62ed`): `LocalController.add/remove_local_controller`、Scenario の `add_*`(`add_events`、`add_from_json_struct`、アクセス制限のある `add_record` を除く)と `remove_disturbance`(タグの選択肢。Scenario の Event 化(`1d1fc68b`)で `add_disturbance` は削除、`remove_disturbance` は `remove_event` に改名)、`get_sys`、`ResultPF`・`ResultOPF`・`ResultCPF`・`ResultODE`・`ResultLIN` の `plot_*`、`disp_*`、`get_*`、`export`(`ResultLIN` は基底の未対応の `export` しかないため除外。`judge_out_of_step` は対象外)。
  - `get_sys` は `PowerSystemModel.get_sys` として書きます。`validateFunctionSignaturesJSON` が `PowerNetwork.get_sys` を「`PowerSystemModel` で定義されている」と書き換えるためです。ダイアログは `ask(fig, "PowerSystemModel.get_sys", Object="net")` で使います。
  - Scenario のタグの選択肢は `obj.a_PowerNetwork` から作ります(母線と送電線、機器、制御器、外乱のタグ)。
  - 生成側(`update_keymap`)の変更は不要でした(`_auxiliary` のクラスも `meta.class` で読めます)。
- `DrawerOptionDialog` の `History`: `Object` のルートの変数を実行記録から取り、`Object` のとおりにたどったオブジェクトで選択肢と既定値を評価します。`obj` を使う選択肢は複数選べる一覧です。
- `ask` の待ちのループで、`pause` の前に毎回 `drawnow` を実行します。small の `run_all` で F32 の直後に F51 を実行すると、最初の `ask` でタイマーが一度も動かず、10 秒で `""` を返していました。多くの図を削除した直後は、`pause(0.05)` だけではタイマーが約 2 秒に 1 回しか動かないことを確かめました(`drawnow` を入れると 2 秒に 12 回)。2026-11-15 の F50 の長い停止(旧 `uiwait`)も、同じ原因でタイマーがダイアログを押せなかった可能性があります(未確認)。
- 数値の欄: 表示した初期値の文字列のままなら「変更なし」とします。`pi/2` の既定値は `1.5707963267949` と表示され、読み直すと丸めで値が変わるため、`add_branch` に `Vargmax=...` が付いていました。

## 決定事項(第1b段階、2026-11-16)

### Parent と h_parent

- コードではパネルをワークスペースの変数 `h_parent` で指定します(`G = res.plot_voltage(Parent=h_parent);`)。GUI は描画の直前に `set_variable("h_parent", パネル)` で設定し、パネルを空にします。この設定は記録に残りません。
- 最初の描画の前に `h_parent = [];` を記録の 1 件として実行します(`Status` が `"done"` で同じコードの記録がなければ)。スクリプトはこの行で `h_parent` を空にするので、描画のたびに新しい図が開きます。
- 指示では Header で定義する例でしたが、`Header` はすべての行にコメントの `% ` を付けるため使えません。記録の 1 件にすれば `HistoryGUILDA` に新しいメンバーは要りません。複数の結果の GUI が 1 つの記録を共有しても、各 GUI が実行の直前に自分のパネルを設定するので混ざりません。

### 一覧と出力の名前

- 一覧は `functionSignatures.json` の `"<クラス>.<メソッド>"` の項目から作ります。上位クラスの項目も、近いクラスから順に使います(利用者が `ResultPF` のサブクラスを作っても、`ResultPF.*` のボタンが出る)。`ResultLIN` の `export` は `ResultBase` の既定の実装(Unsupported)だけなので署名がなく、ボタンもありません。
- 出力の名前は署名のとおりです(`G`、`[G_chart, G_net]`、`tab`、`sys`、`rv`、`s_file`)。`disp_*` の署名は `varargout` なので `s_text` にし、`disp(s_text)` を続けます。スクリプトでは表示され、GUI は `s_text` を Text タブに出します(`run` の Detail は最初の 3 行だけのため)。
- 名前は結果ごとに分けていないので、同じ記録で 2 つの結果の `G` を作ると、後のものが前のものを上書きします(描いた図は残ります)。

### 単独の GUI の記録

- `History` を省くと `HistoryGUILDA(Echo=true, Header=...)` を作り、結果を `Variable`(既定 `"res"`)の名前で置きます。スクリプトは結果を作らないので、ヘッダーに「ワークスペースに `res` がある状態で実行する」と書きます。
- 渡された記録の `Variable` に別のオブジェクトがあれば `GUILDA:ResultBase:OtherVariable` で止めます(アプリの変数を上書きしないため)。

## 決定事項(第2a段階、2026-11-16)

仕様は 2026-11-16 にユーザーが承認したもの(入口、開始画面、配置、系統図、系統モデルの作成タブ、長い実行、stale の帯)。仕組みの説明は `_GUILDAdoc/developer/feature-gui.html#app` にあります。

### 公開したメンバー

- `GUILDA.launch_gui(net)`(static。`net` は省略可)。`DrawerGUILDA` を返します。
- `DrawerGUILDA`: コンストラクター `DrawerGUILDA(net, Visible=)`(`Visible` はテスト用)、読み取り専用の `history`、`G`、`h_figure`。
- `DrawerModelGUI`: イベント `TargetChanged`(`render` が前と違うモデルを表示したときに通知。同じモデルの描き直しでは通知しない)。
- ほかはすべて private です。

### 実装で決めたこと

- 開始画面の 4 つの選択はグループ `"Model building"` で実行します。`DrawerModelGUI` の操作と同じグループなので、スクリプトでは 1 つの節 `%% Model building` に続きます。
- フォルダと MATPOWER は、パスの欄、「参照...」(図が見えるときだけ `uigetdir`/`uigetfile`)、「読み込む」の 3 つにしました。テストは欄に直接書き込みます。
- スクリプトのヘッダーは英語です(`Script of the GUILDA app (GUILDA.launch_gui).`、`launch_gui(net)` では `net is the network passed at startup ...` を加える)。アプリの実行記録は `Echo=false` です(記録の欄があるため)。
- 系統図は、実行記録の実行が終わるたびに描き直します。指示は「成功した実行の後」でしたが、失敗した実行もハンドルの系統の一部を変えている場合があるので(上の残りの事項を参照)、失敗の後も描き直します。`ModelChanged` は必ず実行記録の実行の後に来るので、そこでは描き直さず、選択だけを合わせます。
- `net.plot_diagram(State="auto")` が stale の系統で出す INFO は `evalc` で表示しません(情報の行に stale の状態を出すため。描き直しのたびに出ると邪魔)。
- 母線のない系統(空の系統の直後)は `plot_diagram` がエラーになるので、図の代わりに案内(「母線がありません。...」)を出し、`G` は `[]` にします。
- 有効なタブのボタンは `state` の押された色になります(`BackgroundColor` を変えても押された状態の灰色が優先される)。
- 「スクリプトを出力」は、図が見えていれば `uiputfile`、見えなければ `tempdir/guilda_app_script.m` に書き、ボタンの `UserData` にパスを入れます。

### タブの取り決め(2b、2c 向け)

- 各タブは `_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_<キー>_*.m` のファイルの組です。登録は `private/tab_list.m` の 1 か所だけです(キー、見出し、実行記録のグループ、作成関数)。6 つのタブはすでに登録してあるので、2b・2c は `tab_list.m` も本体も編集しません。
- 作成関数 `sct_hook = tab_<キー>_build(h_panel, sct_app)` は、タブを最初に表示したときに 1 回だけ呼ばれます。`h_panel`(右半分の uipanel)に部品を置き、フックの構造体を返します。フックはどれも省略できます。
  - `f_show()`: タブが表示されたとき(作成の直後も)。
  - `f_changed()`: 実行記録の実行が終わったとき(成功・失敗とも)。作成済みのすべてのタブで、描き直しの前に呼ばれます。
  - `G = f_diagram(G, h_parent)`: タブの表示中に系統図を描くとき。`G` は表示中の図(なければ `[]`)、`h_parent` は図のパネルです。`G` 自身(`net.plot_diagram(Graph=G, ...)`)、`delete(h_parent.Children)` の後に描いた新しい図(`res_pf.plot_diagram(Parent=h_parent)` など)、または `[]` を返します。省略すると選択なしの `net.plot_diagram(State="auto")`(`draw_network`)です。描画は記録しません。
  - `f_click(data)`: タブの表示中に系統図の要素がクリックされたとき(`GraphEventData`: `Tag`、`Kind`、`Index`)。
- `sct_app`(タブの API):
  - `app`(`DrawerGUILDA`)、`history`(`history.get_variable("net")` が系統)、`s_title`、`s_group`。
  - `[l_ok, s_detail] = f_run(s_label, s_code, Progress=s_message)`: タブのグループで実行記録により実行します。`Progress` で進捗が不定・キャンセルなしの `uiprogressdlg` を出します。失敗は `uialert`(どちらも図が見えるときだけ)。
  - `h_banner = f_stale_banner(h_grid, i_row)`: `uigridlayout` の `i_row` 行目(全列)に置く stale の帯。「initialize を実行」で `net.initialize();` を実行します。stale でなければ行の高さを 0 にし、自分で実行記録を追います。
  - `f_redraw()`: 系統図を描き直します。
- ファイル:
  - 系統モデルの作成(2a): `tab_model_build.m`、`tab_model_diagram.m`、`tab_model_select.m`、`tab_model_click.m`。
  - 2b: `tab_pf_build.m`(潮流計算)、`tab_opf_build.m`(最適潮流計算)、`tab_cpf_build.m`(連続潮流計算)、`tab_lin_build.m`(近似線形解析)。追加のファイルは `tab_pf_*.m` のようにキーで始めます。4 つの共通の部分は `tab_analysis_panel.m` と `tab_analysis_diagram.m` です(第2b段階の決定事項を参照)。
  - 2c: `tab_sim_build.m`(時間シミュレーション)と `tab_sim_*.m`。
  - 共有: `tab_list.m`、`draw_network.m`(既定の描画)。準備中のタブの `tab_placeholder.m` は、全タブが置き換わったので第2c段階で削除しました。
- 結果の GUI を開くときは、アプリの実行記録と結果の変数名を渡します(`res_pf.launch_gui(<パネル>, History=sct_app.history, Variable="res_pf")`)。

## 決定事項(第2b段階、2026-11-16)

仕様は 2026-11-16 にユーザーが承認したもの(共通の配置、出力の変数、タブごとの内容、系統図)。仕組みの説明は `_GUILDAdoc/developer/feature-gui.html#app` の「解析のタブ」にあります。

### 公開したメンバー

- `DrawerOptionDialog` の `opt.Value (1,1) struct = struct()`(コンストラクターと `ask`)だけです。入力の名前ごとの初期値を MATLAB のコードの文字列で渡します(`struct("s_scenario", """case1""")`)。
  - 指示の「初期値は基準(baseline)として扱い、既定値と違うときだけ書く」は、「欄には渡した値を表示し、呼び出しは署名の既定値と比べる」と解釈しました。渡した値を基準にすると、既定値と違う値を渡しても書かれず、スクリプトで再現できないためです。必須の入力は常に書きます。
  - 数値と式の欄は文字列をそのまま表示し、ほかの欄は評価して表示します。一覧(ドロップダウン、タグの一覧)にない値は一覧に加えます。知らない名前は `GUILDA:DrawerOptionDialog:UnknownValue`、欄に表示できない値は `InvalidValue` です。

### 実装で決めたこと

- 4 つのタブの共通の配置は `private/tab_analysis_panel.m` にまとめました(フォーム、実行、「結果を解析」、状態の行、図の説明)。ファイルの範囲は `tab_pf_*` などでしたが、4 つのタブで同じコードを繰り返さないため、キーで始まらない共有のファイルを 2 つ(`tab_analysis_panel.m`、`tab_analysis_diagram.m`)加えました。2c が使うかどうかは調整役の判断です。
- フォームは `Format` を除きます(結果の変数を Result のクラスに保つため)。フォームは実行記録の `net` で作り、`net` が別の系統になったら作り直します。
- 状態の行は、実行記録の中で `[<結果>, <flag>] = net.<メソッド>(` で始まる最後の終わった実行から作ります(flag の値と経過時間。失敗ならエラー)。潮流計算の flag は 1 が収束です(0 ではない)。
- 「結果を解析」は記録しません。変数を変えず、ウィンドウを開く行はスクリプトで解析を再現しないためです。結果の GUI はアプリと同じ表示状態の新しい `uifigure`(Tag `"result_gui"`)に `res.launch_gui(h_fig, History=, Variable=)` で開きます。結果の GUI のボタンは同じ記録に入ります。
- 潮流計算のタブには、`PowerNetwork.initialize` のフォーム(パネルの Tag `"form_pf_initialize"`)と「平衡点を設定」ボタン(Tag `"pf_initialize"`。stale の帯のボタンの Tag `"initialize"` と区別するため)を置きました。`initialize` が `arguments` ブロックになった後(`251e7899` で取り込み)に、固定の `net.initialize();` のボタンから置き換えました。`tab_analysis_panel` の 2 つ目のフォーム(`sct_extra`)です。
- 既定値が文章の `logical`(`initialize` の `Verbose`、`WarmStart`、`DefaultCost`)は、チェックボックスでは「空(書かない)」を表せないので、空・`true`・`false` のドロップダウン(`DrawerOptionDialog` の欄の種類 `"flag"`)にしました。
- 連続潮流計算: `net.solver_CPF.LoadBus` は既定で空なので、そのままでは実行できません。空の間は `Value` で `LoadBus` の初期値を負荷(`component.load.*`)のある母線にしました(`tab_cpf_value.m`)。呼び出しには `LoadBus=["B005", "B006", "B008"]` が入ります。
- 近似線形解析: `get_sys` の `point` は `[]`(平衡点)、`{sim, t}`、変数の順のベクトルを受けます。既定の `[]` のままにしました(呼び出しは `[res_lin, flag_lin] = net.get_sys();`)。
- 系統図: 解析のタブは、系統図のパネルの中に新しい `uipanel` を作って描きます。`draw_network` は系統図のパネルそのものにある図だけを `Graph=G` で使い回し、その図の色と選択を残すので、パネルを分けないと、潮流計算の母線の色や OPF の選択がモデルのタブに残ります。描き直しのたびに新しい図を作ります(IEEE9bus で約 0.75 s。使い回しでも約 0.7 s で差は小さい)。描画のエラーは `draw_network` に戻します。近似線形解析は独自の図を持たず、既定の描画(平衡点、stale なら構成)です。
- 最適潮流計算の実行前の図は、`tab_parameter.OPF` の `HP`、`fP`、`HQ`、`fQ` のどれかが 0 でない機器を `select` します(負荷はコストが 0)。連続潮流計算の実行後は、結果の `options.LoadBus` の母線を `select` します。
- タグの一覧と 1 つの値(2026-11-17、調整役の依頼): `ResultODE.plot_trajectory` の `Quantity` のように候補の式に `obj` がある入力は複数を選べる一覧になり、2 つ以上選ぶと実行で失敗していました。
  - `type` に `"scalar"`(update_keymap が (1,1) の引数に書き出す。`b0700038` で取り込み)があれば、一覧の代わりにドロップダウンにします。`"scalar"` だけでクラスのない type は、クラスなし(式の欄)として扱います。
  - `"scalar"` が書き出される前の当面の規則(`f81b858a`: 既定値が 1 つの `string`・`char` の Name-Value で 2 つ以上を選ぶと `get_code` が止まる。ファイルに `"scalar"` が現れたら自動で切れる)は、`"scalar"` を取り込んだ後に削除しました。実物のファイルでは二度と働かないためです。`Bus`(既定値 `"all"`)は複数を選べます。
  - F50 は実物の `functionSignatures.json` で確かめます(`Quantity` がドロップダウン、`Bus` に 2 つ選べる、`add_component` の `P` は数値の欄、`Scenario.add_offset` の `unit` がドロップダウン)。以前の、ファイルを一時的に書き換えるテストはやめました(共有のチェックアウトで並行するテストが読むおそれがあるため)。
- 署名のファイルが 2 つになりました(`fix/aux-signatures`)。`_GUILDAsystem/_auxiliary/resources/functionSignatures.json` は `_auxiliary` のクラス(Result、Scenario、`get_sys`)の項目で、今は 36 件とも `_GUILDAsystem/resources/functionSignatures.json` と同じ内容です。`DrawerOptionDialog` はまず `_GUILDAsystem` のファイルを、なければ `_auxiliary` のファイルを読みます。`DrawerResultGUI` のボタンの一覧は `_GUILDAsystem` のファイルだけを読みます(2b の担当外のため変えていない)。
- `DrawerOptionDialog` の確認: 文章の既定値(`get_sys` の `Input`「Default: all inputs.」など)は空の欄で、呼び出しに書きません。式の欄の既定値が文字列の配列なら `["B005", "B006"]`、空(`strings(1,0)`)なら空の欄にしました(以前は `obj.solver_CPF.LoadBus` の式そのものを表示していた)。設定値の既定値は F50 で確かめています。

## 決定事項(第2c段階、2026-11-17)

仕様は 2026-11-16 にユーザーが承認したもの(stale の帯、シナリオの一覧と埋め込みのモデルの GUI、simulate のフォームと実行、系統図の強調と結果の図、時刻のスライダー)。仕組みの説明は `_GUILDAdoc/developer/feature-gui.html#app` の「時間シミュレーションタブ」にあります。

- 公開したメンバーはありません。ファイルは `tab_sim_build.m`、`tab_sim_refresh.m`、`tab_sim_action.m`、`tab_sim_diagram.m` の 4 つです。ボタンなどのコールバックは 1 つの関数 `tab_sim_action` の分岐にまとめました(コールバックごとの 1 回だけ使うローカル関数を作らないため)。2b の `tab_analysis_panel.m` は使っていません(シナリオの一覧、埋め込みの GUI、スライダーがあり、配置が違うため)。
- 選択の規則: 前に選んでいたシナリオ(オブジェクトで追うので、タグを変えても選んだまま)。シナリオが増えたときは、追加したもの(どのタブや記録から追加しても)。どれもなければ最初のもの。
- 埋め込みのモデルの GUI は、選択か系統が変わったときだけ作り直します。イベントの追加は `DrawerModelGUI.run_code` の中で実行記録を動かし、その `Changed` でこのタブの `f_changed` が呼ばれ、その後で GUI が `render` します。そのため、作り直すときは毎回新しい入れ物(`uigridlayout`)を作って古い入れ物を消します。古い GUI の `render` は入れ物が無効なので何もしません。GUI のオブジェクト自体は消しません(操作の途中で消すとエラーになるため)。
- simulate のフォームは `Format` を除きます(`"struct"` では `res_ode` が `ResultODE` でなくなり、図と「結果を解析」が使えないため)。フォームは選択かタグの一覧が変わったときに作り直します(`s_scenario` の選択肢がタグの一覧のため)。そのとき入力したオプションは元に戻ります。
- 結果の図を出す条件: 「実行」で現れた `res_ode`(前に見たものと違う `ResultODE`)を、そのとき選んでいたシナリオの結果とみなし、そのシナリオを選んでいて `res_ode` が同じオブジェクトである間だけ結果の図を出します。`ResultODE` はシナリオのタグを持たないため、タブが覚えます。記録の行から実行した `simulate` の結果は、状態の行と「結果を解析」には出ますが、図は強調の図のままです。
- 結果の図は、タブを表示し直すたびに描き直します。ほかのタブの描画(`draw_network`)が同じ `GraphNetDiagram` に系統を描き直すためです。
- 強調は `select` で行い、`set_style` は使いません。`set_style` の見た目はタグで残り、`draw_network(Graph=G)` で描き直すほかのタブにも残ってしまうためです。選択は既定の描画と系統モデルの作成タブが外します。強調の対象は `tab_event`、`tab_offset`、`tab_input` から求めます(Scenario のイベント化 `1d1fc68b` の後も列は同じ)。
- 「結果を解析」は、アプリの図が見えないとき(テスト)は見えない `uifigure` に開きます(`launch_gui` の既定の新しい図は見えるため)。開く操作は記録しません(第2b段階と同じ)。
- simulate の `Progress` は設定(既定 `"dialog"`)のままで、フォームでも上書きしません。そのため見えるアプリでは、アプリの進捗ダイアログと simulate 自身の進捗の窓が両方出ます(見えるアプリでの見え方は未確認)。
- F55 の「タブの切り替え」のテストは、準備中のタブがなくなったので、解析のタブの実行ボタン(Tag `"run"`)か時間シミュレーションの実行ボタン(Tag `"sim_run"`)を確かめるようにしました。`tab_placeholder.m` は使われなくなったので削除しました。
- F57(`test_F57_guilda_app_sim`)は IEEE9bus、1 秒のシミュレーションで、1 件 6〜22 秒です(2b と Scenario のイベント化を取り込んだ後)。2026-11-17 のテストの分類に従い、分類 gui に登録し、6 件とも large にしました。

## 決定事項(第3-1段階: 表ピッカー)

- ユーザーの要望(2026-11-16): タグやキーを入力する箇所では、候補を裏で集め、ユーザーは検索して選ぶだけにする。機器を選ぶときは、つながる母線、その母線での位置、クラスが見える表にする。ブランチ、母線、制御器も同じ。ページの切り替えに何秒もかからないように、ページごとの全走査はしない。
- 公開するのは `DrawerTagPicker` の静的メソッド 3 つだけ(`element_table`、`key_table`、`pick`)。イベント処理は private 関数 `picker_event` 1 つにまとめた。
- 列: 母線 Tag/Index/Type/Components、ブランチ Tag/Index/From/To/Class、機器 Tag/Bus/BusIndex/Position/Class/Key、ローカル制御器 Tag/Component/Bus/Class/Role/Parent、グローバル制御器 Tag/Class/Units、シナリオ Tag/Time/Description。依頼の列に、機器の Key とローカル制御器の Role を加えた。
- シナリオの表は Scenario の公開プロパティ(Tag、Time、Description)だけで作る。Scenario は Event クラス(EventFault など)へ作り替え中のため、`tab_event`、`tab_input`、`tab_offset` の中身には頼らず、外乱の数の列は置かない(2026-11-17、GUI のコーディネーターの指示)。
- ローカル制御器のタグは兄弟の間でだけ一意なので、`Tag` 列だけでは系統全体で一意にならないことがある。第3-2段階で欄に組み込むときは、メソッドの対象(どの機器の制御器か)で表を絞るか、Component 列と組で扱う。
- 表は開いたときだけ作る。ウィンドウは親の図ごとに 1 つを隠して持ち、データだけ差し替える。
- 状態(表、検索用の文字列、選択、結果)はウィンドウの appdata `sct_state` に持ち、呼び出しが終わったら消す。イベント処理は、表を書き換える前に状態を保存する。表の `Data` の代入中にキューにあったボタンのコールバックが走ると、古い状態で上書きして押下が失われるため(試験で見つけた競合)。
- 計測(R2026a、`network.IEEE68bus()`、F62 の時間の節): 負荷の低いとき(負荷平均 6 前後)、`element_table` の 5 回の最小は Bus 1.5 ms、Branch 1.8 ms、Component 1.8 ms(51 行)、LocalController 2.6 ms(32 行)、GlobalController 0.4 ms、Scenario 0.3 ms(目標 20 ms 未満)。`pick` の機器表は初回 0.98 秒(セッションで最初の uifigure を含む)、2 回目以降は開いてから操作できるまでの中央値 0.031 秒、最大 0.147 秒(目標 0.3 秒未満)。キーの表は初回 0.09 秒、2 回目 3.6 ms。他のセッションの MATLAB が多数動いていたとき(負荷平均 130 前後)は、表が最小 1〜13 ms、`pick` の 2 回目以降が中央値 0.04〜0.29 秒だった。
- 試験 F62 は分類 "gui"(`DebugScript.test_categories`)。段階は計測した時間で決めた(`DebugScript.test_levels`): キーの表の節だけが small、0.3 秒を超える 4 節が medium、3 秒を超える 5 節(ピッカーを何度も開く節と時間の確認)が large。

## 決定事項(第3-2a段階: オプションのフォームの再設計とピッカーの組み込み、2026-11-17)

> `feature/gui-forms`(`35408fdd` でマージ)の下書き `notes/launch-gui-forms-draft.md` を、第3-2b段階でここに移しました。仕組みの説明は `feature-gui.html#history-option` にあります。


### 定義ファイル `_GUILDAsystem/resources/gui_forms.json`

- 署名(`Bus.add_component` など)ごとの項目:
  - `main`: 必須・位置の入力の直後に置く主なオプション(この順)。
  - `groups`: 折りたたみのグループ(`name`、`members`。この順)。フォームを開いたときは閉じています。
  - `labels`: 入力の名前ごとの英語のラベル(`label`)と単位(`unit`)。
  - `visible`: `names` の入力を、`when` の条件のどれかが成り立つ間だけ表示します。条件は「名前: 値の一覧」で、すべての名前が一致すると成り立ちます。`{"not": [...]}` は「どれでもない」。数値は文字列で書きます(`"NaN"`)。
  - `pick`: 選択肢(`choices`)のない入力にピッカーを付けるときの要素の種類(CPF の `LoadBus` は Bus、`add_global_controller` の `a_Unit` は Component)。
  - `propertyDefaults`: `opt.?GraphNetDiagram` のように、クラスのプロパティから作った Name-Value の既定値を取るクラス。
  - `same`: ほかの署名と同じ配置(`ResultODE.plot_diagram`、`ResultOPF.plot_lmp` は `ResultPF.plot_diagram` と同じ)。
- 項目のある署名で、どの一覧にもないオプションは `Advanced` に入れます(作り忘れても表示から消えないように)。
- 項目のない署名は `_fallback` の規則で名前から分類します: `Limits`(`Pmin`、`Vmax` など。正規表現 `^([PQVSI]|Varg)(min|max)$`)、`OPF`(`OPF*`)、`Stability`(`Stability*`、`MinDampingRatio`、`MaxRealPart`)、`Graph`(`DX`、`DY`、`X`、`Y`、`Shape`、`Path`、`Offset`、`FromOffset`、`ToOffset`、`Length`、`MarkerSize`、`Color`、`Style`)、`Advanced`(`Parent`、`PlotFcn`、`Progress`、`Format`、`WarmStart`、`Export`)。どれにも当たらないものは主なオプションです。
- 項目を書いた署名: `Bus.add_component`、`Bus.replace_component`、`Component.add_local_controller`、`PowerNetwork.add_bus`/`add_branch`/`add_global_controller`/`add_scenario`、`calculate_powerflow`/`calculate_optimal_powerflow`/`calculate_continuation_powerflow`/`initialize`/`simulate`、`PowerSystemModel.get_sys`、`Scenario.add_*`、`Event*.edit`、Result の `plot_*`。
- 条件付きの表示:
  - `initialize`: `Method="OPF"` のときだけ OPF のオプション(`DefaultCost`、`Cost`、`Constraint`、`ReferenceBus`、`Problem`、`InitialPoint`、`MinDampingRatio`、`MaxRealPart`)。`Stability*` はさらに `MinDampingRatio` か `MaxRealPart` が NaN でも空でもないとき。`PlotFcn` は `powerflow` と `OPF` のとき。
  - `calculate_optimal_powerflow`: `MinDampingRatio`、`MaxRealPart` は `Method="AC OPF"` のとき。`Stability*` はさらにどちらかが NaN でないとき(安定度制約付き OPF が動く条件と同じ)。
  - `plot_diagram`(2D の作り直しの後の GraphNetDiagram): 主なオプションは `Dimension`、`ColorMode`、`BranchWidthMode`、`MarkerSizeMode`、`BusHeightMode`、`LabelMode`、`FlowMode`。グループは Colors、Labels、Sizes、Flow、Data、Advanced。
- `simulate`: `StopAngle` は `StopOnOutOfStep=true` のとき。`add_bus`: `Length` は `Shape` が `hbar`/`vbar` のとき。`get_sys`: `Port` は `Type="DAE"` のとき。
  - 隠れたオプションは、値を変えていても呼び出しに書きません。
- `Progress`(解析の進行表示。`feature/analysis-progress-default` で calculate_* と initialize に加わる)は、アプリが自分の進行表示を出すため、4 つの解析と `simulate` で `Advanced` に入れました。署名にない名前は無視されるので、マージの前後どちらでも効きます(`18214c87` を取り込んで確かめた)。`initialize` の `Progress` は `Method` が `powerflow`、`OPF`、`FixedInput` のときだけ表示します(署名の目的のとおり)。

### フォームの並びと速さ

- 並び: 必須・位置の入力 → 主なオプション → グループ(見出しのボタン `▸ Limits  (4)`。開くと `▾`。変えた欄があれば `(4, 1 changed)`)。
- グループの欄は、最初に開いたときに作ります。IEEE68bus の OPF のフォームは 2 回目以降 0.1〜0.24 秒でした(他のセッションの MATLAB で負荷平均 10〜30 のとき)。`Value` で値を渡した欄のあるグループは最初から開きます(その値を見せて書くため)。
- 行は表示する欄だけを順に並べ、隠れた欄と閉じたグループの欄は高さ 0 の 1 行にまとめます(高さ 0 の行が多いと行間が積み重なるため)。
- 開いていないグループの欄は既定値のまま(呼び出しに書かない)と扱います。テストや別のコードが閉じたグループの欄を `findall` で探すときは、先に見出し(Tag `group_<名前>`、空白は `_`)を押します。

### 既定値の表示

- すべての欄に既定値を入れて表示します(灰色のプレースホルダーは使わない)。
- NaN: 目的(`purpose` の `Default:` より前)に「NaN は none」(`NaN for none`、`NaN: none`、`NaN = none`)とあれば `none`、NaN に触れていれば `auto`、触れていなければ `NaN` のまま(`add_fault` の `Point`、`add_bus` の `baseMVA`)。
- Inf と -Inf: 目的に `Inf: none`(`-Inf: none`、`Inf for none`)とあれば `none`、なければ `Inf`/`-Inf`。
- 欄は `auto`、`none` をそのまま受け付け、呼び出しには NaN、Inf、-Inf と書きます。`none` は目的が示す値です(`Vmin` に `none` と入れると `Vmin=-Inf`)。
- `""` は空の欄です。式の欄の `NaN`(`add_component` の `parameter`)も目的が NaN に触れていれば `auto` と表示します。
- 既定値が文章(評価できない)の欄は空にし、横に斜体の薄い文字で `default: ...` を出します(Tag `hint_<名前>`)。`GUILDA.setting` / `GUILDA.config` を含む文章は `from GUILDA.setting`、`true (calculate_optimal_powerflow)` のように値と括弧書きなら値だけ、24 文字を超えるものは省略し、全文はツールチップです。
- `Default: obj.<プロパティ>`(Event の `edit`)は呼び出しの対象で評価します。
- `propertyDefaults` のクラスのプロパティは、classdef の宣言(`名前 (サイズ) 型 {検証} = 既定値 % 説明`)を読み、既定値の式と説明を使います。大きな既定値(`Colormap` の `turbo`)は式のまま表示します。
- 単位は目的の先頭の `[pu]` などから取り、ラベルの後ろに `P [pu]` のように書きます。
- 既定値と違う欄は背景を薄い青にし、ラベルを青にし、右端に既定値へ戻すボタン(`↺`、Tag `reset_<名前>`)を出します。戻すボタンは最初に変えたときに作ります。
- 必須の入力が空でも、フォームを作った直後はメッセージを出しません(利用者が触る前に警告しないため)。

### ピッカーの組み込み

- 対象:
  - `choices` の式が `obj` からたどる要素の配列(`a_Bus`、`a_Branch`、`a_Component`、`a_LocalController`、`a_GlobalController`、`a_Scenario`)を使う入力。
  - `choices` が `GUILDA.keymap("<分類>")` の `Key`。
  - `gui_forms.json` の `pick` の入力。
- 欄: 複数を取る入力はタグの文字の欄(`B001, B002`。カンマ・空白・`;`・`|` で区切る)と `Select...`。1 つだけ取る入力(`"scalar"`)と `Key` は、これまでのドロップダウンと `Select...`。`pick` の式の欄には `["B005", "B006"]` と書きます。
- 表は `Select...` を押したときに作ります。ネットワークは `Object` のルートの変数がネットワークならそれ、なければ対象から `a_PowerNetwork`、`a_Scenario`、`a_Bus`、`a_Component` をたどって探します。History がない、またはネットワークが見つからないときは `Select...` を付けません。
- 表の行は、選択肢の式が返したタグの要素だけです。種類が 1 つなら `element_table` の表、複数(`add_fault` の母線とブランチ、`add_trip` の機器・ローカル制御器・グローバル制御器)なら列 Tag、Kind、Bus、Detail、Class の表にまとめます。
- ローカル制御器のタグは兄弟の間でだけ一意です。`Component.remove_local_controller` では、表を呼び出しの対象の機器の制御器だけに絞るので、タグはその中で一意です。`add_trip` と `EventTrip.edit` は単位をタグだけで指定するので、選んだタグを系統の複数の要素が持つときは、フォームのメッセージで知らせます(`GUILDA:DrawerOptionDialog:SharedTag`)。今の既定のタグ(`B001SG1CA1` のように機器のタグを含む)では起きません。
- キャンセルでは欄を変えません(複数選択で何も選ばずに Select を押した場合も変えない。消すときは欄の文字を消す)。
- 手で入れたタグが選択肢にないときは `GUILDA:DrawerOptionDialog:UnknownTag` のメッセージで、`get_code` は `""` です。

### `ask`

- ボタンは `Run` と `Cancel`(Tag `dialog_run`、`dialog_cancel`)。
- ウィンドウの高さはフォームに合わせ(160〜640 px)、グループを開くと上端を保ったまま伸びます。フォームとボタンの間に空白は残りません。待ち方(表示中は `uiwait`、非表示と `-batch` は最大 10 秒)は変えていません。

### 互換性

- コンストラクター、`ask`、`get_code` の引数と結果は変えていません。公開メンバーは増やしていません(増やしたのは private のプロパティ `sct_group`、`c_visible`、`h_grid`、`a_object`、`a_network`、`f_resize` と private メソッド `draw_field`、`form_event`、private 関数 `number_text`、`tags_text`、`parse_tags`、`code_strings`)。メッセージ ID を 2 つ加えました(`UnknownTag`、`SharedTag`)。
- 欄の Tag は入力の名前のままです。変わった点: ネットワークの要素のタグを複数取る欄は一覧(`uilistbox`)から文字の欄(`uieditfield`)になりました。`from_to` の既定値 `[1,2]` は母線の番号なので、空の欄にし、`Select...` が横にあるのでヒントは欄のプレースホルダー `default: [1,2]` にしました(選んだ母線は常に書く)。
- ほかの段階のテストの直したところ: F51、F52、F55、F57 のダイアログのボタンの文字(`"実行"` → `"Run"`、`"キャンセル"` → `"Cancel"`)。F52 は `get_ss` の `Format`(名前による分類で閉じたグループ Advanced に入る)の前に見出しを押す手順(ダイアログの操作の補助関数がボタンを Tag でも探す)。F50 は閉じたグループを開く手順と、一覧から文字の欄への変更。F62 は件数の文字(`"2 chosen"`)。
- `DrawerTagPicker.pick` の文字も英語にしました(`Select`、`Cancel`、検索欄、件数 `"%d chosen / %d shown / %d in all"`、既定の題 `"Select"`)。

### 試験(第3-2a段階)

- F66(`test_F66_gui_forms`、分類 gui): 定義ファイルによる並びと閉じたグループ、名前による分類、条件付きの表示(`initialize` の Method、OPF の安定度)、既定値の表示(auto/none/空/文章のヒント、obj のプロパティ、クラスのプロパティの既定値)、強調と戻すボタン、単位とラベル、ピッカー(複数、1 つ、Key、`pick`、ローカル制御器、種類の混ざった表)、変えていないオプションを書かないこと、IEEE68bus での時間(OPF のフォームと `Select...` の 2 回目以降の最小が 0.3 秒未満)。
- 時間の節は、2 回目以降の 5 回の最小で判定し(他のセッションの MATLAB の負荷で一部の回が遅くなるため)、中央値も表示します(第3-3段階で、基準の作業との比の判定に変えました。下の「4. F66 の時間の節の安定化」)。負荷平均 13 のとき、OPF のフォームは最小 0.16 秒・中央値 0.43 秒、Key のピッカーは 0.05/0.18 秒、`add_trip` のピッカーは 0.08/0.18 秒でした。
- 試験の番号: 当初の F64 は開発ブランチの `test_F64_controller_slots.m` と重なったため、調整役の指示で F66 に改めました(第3-2b段階のテストは F65 の後、F69 に変更)。
- 段階: 0.3 秒未満の 3 節は small、0.3〜3 秒の 4 節は medium、3 秒を超える 4 節(ピッカーを何度も開く節と時間の節)は large。

### 署名に足りない情報(担当の調整役へ)

- `Scenario.add_trip` と `EventTrip.edit` の `choices` は、機器の直下のローカル制御器だけを並べ、AVR の下の PSS(入れ子)を含みません。`validate_events` は入れ子も受け付けるので、ピッカーで PSS を選べません(担当: simulate)。
- `ResultPF.plot_diagram`、`ResultODE.plot_diagram`、`ResultOPF.plot_lmp` の `opt.?GraphNetDiagram` の項目には `purpose` も `Default:` もありません。フォームは `propertyDefaults` で GraphNetDiagram の宣言から補っています(担当: update_keymap)。
- `initialize` の `Solver`、`Tolerance`、`MaxIteration`、`Verbose`、`WarmStart`、`PlotFcn` の既定値は「Method が実行する解析の設定」という文章なので、フォームは今の設定値を表示できません(空の欄とヒント)。
- `ReferenceBus`(OPF、`initialize`)は `"auto"`、母線のタグ、`"none"` を取る文字列ですが `choices` がなく、ピッカーを付けていません。
- `add_global_controller` の `a_Unit`、CPF の `LoadBus` には `choices` がないので、`gui_forms.json` の `pick` で補っています。
- `ResultCPF.plot_pvcurve` の `Bus` の既定値 `default_bus(obj)` は private 関数で、フォームでは評価できません(文章のヒントになる)。
- `PowerNetwork.add_bus` の `baseMVA`(互換のため無視)は既定値 NaN ですが、目的に NaN の意味がないので `NaN` と表示します。

### 残りの事項(第3-2a段階)

- 時間の確認は他のセッションの MATLAB による負荷に左右されます。負荷平均 10 前後で OPF のフォームの 2 回目は 0.1〜0.2 秒、`Select...`(Key)は 0.11〜0.18 秒、`add_trip` の 4 種類の表は 0.2 秒でした。負荷平均 30〜90 では `add_trip` の表が 0.5〜1.1 秒になり、F66 の時間の節は中央値では失敗することがあったため、最小で判定しています。
- 見えるアプリでの操作(ダイアログの高さの変化、ピッカーの重なり)は、`exportapp` の画像で確かめただけです。

## 決定事項(第3-2b段階: 画面構成と英語化、2026-11-17)

2026-11-17 の画面写真のレビュー(IEEE14bus)の指摘への対応です。仕組みの説明は `feature-gui.html` の `#layout`、`#result-gui`、`#app` にあります。

- **GUI の文字はすべて英語**(ユーザーの決定)。タブは Model、Power flow、OPF、CPF、Time simulation、Linearization。情報の帯、実行記録の見出しとボタン(`Hide log`、`Export script`)、状態の行、案内、`uialert`/`uiconfirm` の文も英語。メソッド名と引数名はそのまま。`DrawerOptionDialog.ask` のボタン(Run、Cancel)と `DrawerTagPicker.pick` の文字は 3-2a で英語になりました。実行記録のグループの見出しの括弧 `【】`(`HistoryGUILDA`)も担当外で、F69 の英語の検査から除いています。
- **情報の帯は 2 行**。2 行目は系統図の色と選択の意味です。タブの約束に省略できるフック `s_legend = f_legend()` を加えました(既存のタブはそのまま動く)。解析のタブは `tab_analysis_legend.m`(結果の変数の有無で実行前・後の文を選ぶ)、時間シミュレーションは `tab_sim_legend.m`。フックがなければ本体が既定の文(枝の電流、stale なら位相構成だけ)を書きます。
- **カラーバーのラベル**: 既定の描画は `ColorMode="I"`、`ColorbarLabel="Branch current |I| [pu]"`、`TitleFormat=""`。潮流計算の結果は `ColorMode="P"`、`ColorbarLabel="Branch active power |P| [pu]"`、`ColorLimits=[0 最大値]`。最適潮流計算の結果は `plot_lmp` のラベル(LMP)のまま。時間シミュレーションの結果は電流のラベルで、`TitleFormat` は既定(時刻)。
- **潮流計算の前後の違い**: 前は `ColorMode="none"` とカラーバーなしで母線の種類の色だけ、後は枝の有効電力の色と矢印。ラベルを `LabelMode="value"` にする案は、IEEE14bus で文字が重なって読めなかったので採らず、値は hover で見る、と凡例に書きました。
- **系統図をパネルに合わせる**: `GraphNetDiagram` は x・y を少なくとも [0 1] の範囲で描くため、座標の狭い系統では余白が大きくなります。アプリの側で描くたびに `axis tight` と長い辺の 4 % の余白に直します(Graph クラスは変えていない)。2D の既定(`1ec24cde`)をマージした後に確かめました。
- **実行記録**: 高さを固定の 130 px にし、系統図が残りを使います。`Hide log` で 0 にできます(uigridlayout には境界のドラッグがないため、大きさを変えるのではなく隠す方式にしました)。
- **Display options**(アプリの帯の横と結果の GUI のヘッダー): `G.show_controls(Parent=<グリッド>)` を図の右の 230 px の列に出します。グラフ調整役の約束どおり、グリッドを親に渡して次のセルに入ったパネルの `Layout` を後から設定し、子を消した後(新しい図)は出し直します。操作を宣言していない図(現在の `GraphNetDiagram`、「No controls for this graph.」)は列を作らず、アプリでは帯にその旨を書きます。
- **`ChangedFcn` は記録しない**(決定): 操作パネルの変更は図のプロパティを設定するだけで変数を変えず、アプリではタブが次に描くときに設定し直すこともあり、結果の GUI のスクリプトは図を既定で描くためです。記録すると、`G` という変数が実行記録にない場合(アプリの系統図)にスクリプトが再現できません。
- **解析の進行表示**: 解析を実行するコード(解析のタブのフォーム、`simulate`、`initialize` と stale の帯)は `run_code` に `Progress` を渡しません(GUI 実装設計の調整役の依頼、ユーザーの B 案)。解析そのもの(`ProgressGUILDA`)が Tag `"GUILDA:app"` の図に進捗を出し、同じ図に 2 つの `uiprogressdlg` が開くと両方が残るためです。系統の読み込み(開始画面)のダイアログはそのまま。非表示の図では `uiprogressdlg` が出ないので、二重にならないことは F55〜F57 では確かめられません。
- **Model タブの子の表**: カードの列を、種類ごとの検索できる表(`DrawerTagPicker.element_table` の列)に置き換えました。表は種類を初めて表示するときに作り(遅延)、同じモデルの次の描き直しでは実行記録に新しい項目がなければ使い回します(`DrawerModelGUI` の private のプロパティ `m_cache`、`containers.Map`)。ローカル制御器のタグは兄弟の間でだけ一意なので、表示中の機器(と親の制御器)の行に絞ってからタグで対応させます。行の右クリックの経路(`InteractionInformation.Row`)は手動で未確認です。
- **追加ボタン**: `+ GlobalController`、`+ LocalController` が切れていたので `+ Controller` にしました(ツールチップにメソッド)。子のないモデルでは左の列をボタンの幅にします。
- **パラメータの表**: 1 行でスカラー(数値、logical、string)だけのコンテナは、名前と値の縦の表(cell 1 列、`RowName` に名前)にし、2 つずつ横に並べます。string は uitable の cell が char しか持てないので char で表示し、編集の後で string に戻します。複数行のコンテナは今までどおり 1 パラメータ 1 列です。
- **解析のタブ**: Run、Analyze result、状態の行を題の下の 1 行にまとめ、フォームを残りの高さに置きました(フォームとボタンの間の空白をなくす)。潮流計算の `net.initialize` のフォームは、見出しの行にボタンを置きます。時間シミュレーションのタブは、見出しの行に Run と Analyze result を置き、時刻のスライダーの行は結果を表示するまで高さ 0 で隠し、目盛りは約 6 個にしました。
- **結果の GUI**: ボタンはメソッド名から作る読みやすいラベル(`plot_voltage` → Voltage、`get_lmp` → LMP、`export` → Export to file)で、ツールチップにメソッド。一覧は 2 つの署名ファイル(`_GUILDAsystem/resources` と `_GUILDAsystem/_auxiliary/resources`)をまとめて読みます(`private/read_signatures.m`)。開いたときは記録せずに、Text に要約(`disp_summary`、なければ結果の表示)、Plot に一覧の最初の `plot_*` を既定で描きます。
- 新しい公開のメンバーはありません。private のプロパティ(`DrawerGUILDA.h_side`、`DrawerModelGUI.m_cache`、`DrawerResultGUI.G_plot`)と private のメソッド(`DrawerResultGUI.show_plot_controls`)を加えました。
- テスト: F69(`test_F69_gui_layout`。F65 は static-controllers が使うため F65 から改番、分類 gui、1 件が medium、5 件が large)。F32、F51、F52、F55、F56、F57 を英語と子の表に合わせて直しました。

## 決定事項(第3-3段階: 最終レビューの 4 件、2026-11-17)

ブランチ `fix/gui-polish`。最終レビューで残った 4 件を直しました。

### 1. 解析のタブのフォームの下の空白

- 原因: `tab_analysis_panel` のフォームの行(と潮流計算の `net.initialize` のフォームの行)が `"1x"` で、残りの高さを 2 つのフォームで分け合っていました。フォームの中身は上に詰めて描かれるので、その下に大きな空白が残りました。
- 直し方: フォームの容器を `uipanel` から 1x1 の `uigridlayout`(行の高さ `"fit"`、Tag は今までどおり `form`、`form_<s_tag>`)に変え、タブの格子の行をすべて `"fit"` にしました。`DrawerOptionDialog` の格子は、行の高さが数値と `"fit"` だけなので、`"fit"` の行に入れると内容の高さになります。グループを開閉すると行の高さが変わり、下の行(`initialize` の見出しとフォーム、注記)がそのまま追従します。余った高さはタブの一番下に残り、フォームがタブより高いときはタブの格子(`Scrollable` on)をスクロールします。`DrawerOptionDialog` は変えていません(高さの報告に誤りはなかった)。
- 時間シミュレーションのタブも同じ形で、`simulate` のフォームの行が `"1x"` だったため、時刻のスライダーの行との間に空白がありました。フォームの行を `"fit"` にしたので、スライダーはフォームのすぐ下に出ます。シナリオのモデル GUI の行は `"1x"` のままです(高さを使う表のため)。
- OPF、CPF、Linearization は同じ `tab_analysis_panel` なので、同じ直し方で空白がなくなりました(IEEE14bus と IEEE9bus の `exportapp` の画像で確認。OPF の 3 つのグループをすべて開いた場合も確認)。
- テスト: F56 の潮流計算の節で、フォームの容器が `"fit"` の 1x1 の格子であることと、タブの格子のフォームの行が `"fit"` であることを確かめます。`-batch` の非表示の図では部品の `Position` が描画まで決まらないため、位置ではなく構造で確かめています。

### 2. `Scenario.add_fault` の `Point` の "NaN"

- 意味: `Point` は枝の故障の位置(from 端 0 〜 to 端 1、0 < Point < 1)で、母線の故障には使いません。既定値 NaN は「母線の故障で位置がない」ことを表します(`add_fault` のヘルプ「Bus rows have Point NaN」、`EventFault` の `tab_event` の母線の行も NaN、`notes/scenario-event-classes.md` §2.8)。
- 表示: 欄は NaN を `bus` と表示し、横に薄いヒント「bus: a bus fault · 0 to 1 along a branch」を出します。`bus` と入れると NaN(既定値)として書かず、数を入れると `Point=0.3` のように書きます。単位はありません(枝の長さに対する比)。
- データ: `gui_forms.json` の `labels` に 2 つのキーを加えました。`nan`(NaN の表示語。欄はこの語を受け付けて NaN と書く)と `hint`(欄の横の短いヒント。Tag `hint_<名前>`、ツールチップは目的)。`Scenario.add_fault` と `EventFault.edit` の `Point` に使っています。
- コード(`DrawerOptionDialog`): 欄の構造体に `s_auto`(NaN の語。既定 `"auto"`)と `s_note`(ヒント)を加え、`"auto"` と書いていた比較を `s_auto` にしました(`build_form`、`get_code`、`form_event`、private 関数 `number_text` の第 4 引数)。公開のメンバーは増えていません。
- 署名の文(担当: simulate の調整役へ): `Scenario.add_fault` の `Point` の目的は「Fault position along a branch, 0 < Point < 1 (required for branches). Default: NaN.」で、NaN の意味が書いてありません。そのためフォームは `NaN` と表示していました。`EventFault.edit` は「(NaN for buses)」と書いてあるので、`auto` と表示していました(意味は自動ではない)。どちらも `gui_forms.json` で `bus` にしたので、文を直さなくても表示は正しくなりますが、`add_fault` の目的にも「NaN for buses」を加えると、コマンドラインのヘルプと補完でも意味がわかります。Scenario と Event のクラスは変えていません。

- Scenario のモデルの GUI の Events の表では、`Point` の列に今も `NaN` が出ます。表の文字は `@Scenario/gui_content.m`(Scenario のクラス、担当: simulate)が `mat2str` で作っているので、変えていません。母線の行を `bus` と表示するなら、そこで直す必要があります。

### 2b. すべて NaN のベクトルの既定値(`ColorLimits` の `[NaN NaN]`)

- `feature/diagram-look` で `GraphNetDiagram` の `ColorLimits` の既定値が `[NaN NaN]`(自動)になり、`plot_diagram` などのフォームが `[NaN NaN]` と表示していました(GUI 実装設計の調整役の依頼)。
- 決定: 一般の規則にしました(`gui_forms.json` には書かない)。目的に NaN の意味が書いてある数の欄(スカラーの NaN を `auto` と表示する欄と同じ条件)では、すべての要素が NaN のベクトルも `auto`(または `labels` の `nan` の語)と表示します。変えなければ書かず、`auto` と入れ直すと既定値に戻ります。変えたのは private 関数 `number_text` だけです。
- 理由: `ColorLimits` の目的は「NaN: from the data」と NaN の意味を書いているので、条件は今のスカラーの規則と同じで済みます。引数ごとに `gui_forms.json` に書く方式は、同じ形の新しい引数が増えるたびに書き足す必要があります。
- テスト: F66 の `ResultPF.plot_diagram` の節で、`auto` の表示、`[0 2]` を入れると `ColorLimits=[0 2]` と書くこと、`auto` で書かなくなることを確かめます。

### 3. 時間シミュレーションのタブの画像(`exportapp` の失敗)

- 再現: IEEE14bus の B004 の故障で `simulate` が flag -1 で止まった後、`exportapp` が `MATLAB:ui:figure:ExportUnsuccessful`(Export unsuccessful)で失敗しました。IEEE9bus の B007 の故障(最後まで計算できる)では成功しました。
- 原因: `HistoryGUILDA.run` は出力を `evalc` で取り込み、最初の 3 行を記録の Detail にします。`evalc` は警告を `[` char(8) ... `]` char(8)(バックスペース)で囲むので、警告を出した実行(flag -1 の `simulate` など)の Detail にバックスペースが入り、実行記録の一覧(`uilistbox` の Items)に表示されていました。この制御文字があると `exportapp` が失敗します。調べた範囲では、`uiprogressdlg` は閉じていて、タイマーはなく、ウィンドウの状態も通常でした。系統図、タブ、時刻の行を消しても失敗したままで、一覧の Items にだけ char(8) がありました。
- 直し方: `HistoryGUILDA.run` の Detail から、警告の括弧(`[` char(8) と `]` char(8))を除き、改行以外の制御文字を空白にします。`Echo` の出力はそのままです。F50 に、警告を出した実行の Detail に制御文字がないことの確認を加えました。
- 画像(セッションの作業フォルダ、`exportapp`、IEEE9bus、`case1`(0〜2 秒)、B007 の故障 0.1〜0.15 秒): シナリオを選んだ状態、実行後、スライダーを 0.12 秒に動かした後の 3 枚。IEEE14bus の B004(flag -1)の実行後の画像も撮れるようになりました。
- 撮影の前に開発ブランチを 2 回取り込みました(1 回目: `fix/graphchart-weakref` 06f450e6、`fix/graph-spring-plot` 47784287。2 回目: `feature/diagram-look` 3a4392f0、`fix/graph-spring-plot` e3f92038)。画像は 2 回目の後に撮り直し、系統図(母線のタグだけのラベル、大きくなった記号、カラーバーのラベル)が正しく表示されることを確かめました。`list_UpdateLog.js` の衝突は両方の項目を残して解きました。

### 4. F66 の時間の節の安定化

- 経緯: `AnOPFFormAndAPickerOpenInUnder0_3S...` が、他のセッションの MATLAB が動いているときに失敗していました(ピッカー 0.95 秒、別の実行でフォーム 0.30008 秒と 0.42 秒)。2 回目以降の 5 回の最小で判定していましたが、負荷が続くと最小も 0.3 秒を超えます。
- 選んだ方法: 各回の直前に、決まった基準の作業(隠れた図に 20 行の `uilabel` と `uieditfield` の格子を作って `drawnow`)の時間を測り、1 回目を除く 8 回の最小どうしの比で判定します。比の上限は 6、絶対の上限は 1.5 秒です。目標の 0.3 秒は表示するだけにしました。
- 理由: 負荷はフォームと基準の作業を同じように遅くするので、比は負荷にほとんど左右されません。一方で、フォームやピッカーが退行して 2.5〜3 倍遅くなれば比で失敗します。負荷平均が高いときに判定を飛ばす方法(`assumeTrue`)は、負荷の高い時間が長いと退行を見逃し続けるので採りませんでした。テストは large のままです。
- 計測(R2026a、IEEE68bus): 負荷平均 5〜7 のとき、OPF のフォームは最小 0.118 秒(基準 0.067 秒、比 1.77)、Key のピッカーは 0.046 秒(比 0.85)、`add_trip` のピッカーは 0.064 秒(比 1.42)でした。自分で CPU を使うプロセスを 12 個(コア数)動かして負荷平均を 30〜50 にしたときは、フォーム 0.176 秒(比 2.45)、Key 0.044 秒(比 0.97)、`add_trip` 0.137 秒(比 1.94)で、すべて上限の比 6 を大きく下回りました。中央値はフォーム 0.28 秒、`add_trip` 0.32 秒で、0.3 秒の絶対の判定なら落ちうる値でした。

## 高速化(2026-11-18)

> 基準: `refactor/design-alignment` の `d5691ee8` から 3 つのセッションで並行して作業し、`f2759344` までにマージしました。P1 はアプリ(`@DrawerGUILDA`、`refactor/perf-app`)、P2 はモデルの GUI(`@DrawerModelGUI`、`refactor/perf-model-gui`)、P3 はオプションのフォーム・ピッカー・結果の GUI(`@DrawerOptionDialog`・`@DrawerTagPicker`・`@DrawerResultGUI`、`refactor/perf-forms`)を担当しました。

### 目標と方針(ユーザーの判断)

- GUI がサクサク動くこと。目標は次のとおりです。
  - タブの切り替え・モデル間の移動・フォームやピッカーの 2 回目以降の表示: 0.3 秒未満。
  - 新しいモデルの GUI・結果の GUI の窓: 0.5 秒未満。
  - ボタンや入力: すぐに反応すること。
- まず MATLAB のまま最適化しました(案 A)。届かない部分は、同じ uifigure の中の `uihtml`(`Data` と `HTMLEventReceivedFcn`)に移してよい、という方針です(案 B)。MATLAB が裏側に残り、操作はこれまでどおりコードとして `HistoryGUILDA` で実行します。
- 3 つに共通して効いたのは「作り直さない」ことです。部品は一度作って中身だけを書き換え、プロパティは値が変わったときだけ設定します(同じ値でも設定のたびに画面側へ送られるため)。

### 計測の方法

- R2026a。見える uifigure で、2 回目以降を測りました(クラスと uifigure は先に一度使っておきます)。変更前は `d5691ee8` を別のフォルダに取り出し、同じスクリプトで測りました。スクリプトは作業用で、リポジトリには入れていません。
- この Mac は、ほかのセッションの MATLAB で負荷平均が 5〜50 でした。同じ操作でも 1.5〜2 倍揺れるので、同じ時間帯の値どうしで比べてください。負荷の低いときの値は測っていません。
- テストの時間の判定(F66、F75、F76、F77)は、各回の直前に測る基準の作業(隠れた図に 20 行の `uilabel` と `uieditfield`)との比と、大きな退行を捉える絶対の上限で行います。段階はすべて large です。

### 前後の時間(秒)

| 画面 | 操作 | IEEE14 前 → 後 | IEEE68 前 → 後 |
|---|---|---|---|
| アプリ | 起動 `GUILDA.launch_gui(net)` | 3.5〜4.0 → 2.7〜3.2 | 2.8〜3.6 → 2.6〜2.7 |
| アプリ | タブの切り替え(中央値) | 0.9〜1.2 → 0.04 | 1.4〜1.5 → 0.04〜0.05 |
| アプリ | 潮流計算の Run(括弧は計算) | 2.7〜3.9 (1.0〜1.4) → 1.2〜2.1 (0.5〜0.8) | 4.8〜6.8 (1.6〜2.2) → 4.3〜5.8 (2.2〜3.1) |
| アプリ | 編集の後の描き直し(Power flow のタブ) | 1.2〜3.6 → 0.26〜0.38 | 1.9〜3.6 → 0.25〜0.54 |
| モデルの GUI | 新しい `launch_gui`(パネルへ) | 1.2〜2.9 → 0.19〜0.50 | 0.48〜1.0 → 0.19〜0.37 |
| モデルの GUI | 別の母線への `render` | 0.62〜0.93 → 0.08〜0.26 | 0.41〜0.96 → 0.05〜0.20 |
| モデルの GUI | 機器への `render` | 0.74〜1.0 → 0.14〜0.20 | 0.50〜1.0 → 0.12〜0.20 |
| モデルの GUI | `render(net)` | 0.46〜0.94 → 0.20 | 0.31〜0.72 → 0.16〜0.20 |
| モデルの GUI | パラメータの編集 | 0.47〜0.77 → 0.06〜0.13 | 0.23〜0.51 → 0.02〜0.08 |
| フォーム | `ask`(OPF のフォーム)が開くまで | — | 0.55〜0.58 → 0.05〜0.18 |
| 結果の GUI | ボタンを押してダイアログが開くまで | — | 0.78〜0.89 → 0.11〜0.30 |
| 結果の GUI | 窓が描かれるまで(ResultPF) | — | 0.27〜0.46 → 0.15〜0.48 |
| ピッカー | IEEE68 の機器の一覧 | — | 0.04〜0.22 → 0.04〜0.13 |

- 埋め込みのフォーム(0.06〜0.19 秒)、グループの開閉(0.05〜0.11 秒)、欄の入力(約 0.02 秒)は、変更前から目標内でした。
- 結果の GUI の全体(最初のプロットまで 1.6〜3.3 秒)は良くなっていません。Log の表示を後回しにした分が、最初のプロットと枠の描画に移っただけとみられます。窓が描かれるまでは目標内です。
- アプリの起動の残り(IEEE68 で約 2.6 秒)の内訳は次のとおりです。アプリの側を HTML にしても縮みません。
  - 隠れた図での作成: 1.7〜2.6 秒(系統図 0.7〜1.3 秒、モデルの GUI 約 0.5 秒、`HistoryGUILDA.attach_view` 約 0.5 秒)。
  - 表示から描画まで: 1.6〜2 秒(uifigure の表示)。
- 調整役が変更前に測った値(負荷のある状態)は、アプリの起動 10〜11 秒、タブの切り替え 1.4〜5 秒、モデルの GUI の `bus.launch_gui(panel)` 2.6 秒、別の母線への `render` 1.6 秒(IEEE14)・4.1 秒(IEEE68)でした。

### 見つかった重い箇所と、変えたこと

- **アプリ(P1)**
  - 切り替えのたびに系統図を作り直していました(1 回 0.5〜1.5 秒)。いまは系統図をタブごとのパネルに持ち、切り替えでは `Visible` を変えるだけです。描き直すのは実行の後だけで、表示中のタブはすぐに、隠れたタブは次に表示したときに描きます。
  - 描き直しは `net.plot_diagram(Graph=G)` で行います。結果の図は、同じ結果のあいだは描き直しません。
  - 流れのアニメーションは表示中のタブだけで動かします。起動時は、表示してから始めます。最初の `timer.start` に約 1.2 秒かかるためです。
  - Model と Time simulation のタブのモデルの GUI は、隠れている間に実行があったときだけ描き直します。
  - 見える図では、実行の後の系統図の描き直しを単発のタイマー(0.05 秒)で後に回します。続けた実行は 1 回にまとめて描きます。
  - タブの取り決め(`f_diagram`、`f_changed`、`f_show`)の呼ばれ方は `private/tab_list.m` と `feature-gui.html` にあります。
- **モデルの GUI(P2)**
  - `render` は毎回グリッドを消して作り直していました。9 回の `render` で `uitable` を 51 個作り、プロパティを 510 回設定していました。削除も重く、表 4 つのタブで約 1 秒かかっていました。
  - いまは `build_frame` が部品を一度だけ作り、`render` は変わったプロパティだけを書きます(`set_changed`)。
  - 子の表は列の構成ごとに `uitable` を持ち、同じセルに重ねます。表示中の表だけに Tag `"children"` を付けます。列の構成の書き換えに 0.15〜0.4 秒かかるためです。
  - `DrawerTagPicker.element_table` は、実行記録に新しい記録ができるまで持っておきます。
  - 子のないモデルでは、左の列を図から外さずに、幅や高さを 0 にします。表を含む部品を外して付け直すと 0.3〜0.75 秒かかるためです。
- **フォームと結果の GUI(P3)**
  - `ask` は親の図ごとに隠れた窓を 1 つ持ち、最近のフォームを 8 個まで使い回します。欄の部品が同じなら値だけを戻します。
  - `get_code`・`form_event` は、変わった色・行・表示だけを設定します。
  - 結果の GUI では次の 3 点を変えました。
    - `read_signatures` は JSON を一度だけ読みます。
    - Log のタブは開いたときに `attach_view` します。
    - メソッドのボタンは、押した瞬間に印と待ちのポインターを出します。
  - ピッカーは部品のハンドルを appdata に持ち、`findall` をやめました。

### uihtml にした範囲(案 B)

- **モデルの GUI の右側の本体(Parameter タブと `gui_content` のページ)だけ**です。1 つの `uihtml`(Tag `"body"`、`@DrawerModelGUI/private/model_body.html`)にまとめ、1 回の表示で `Data` を 1 回だけ送ります(`body_data`)。前と同じ `Data` なら送りません。
  - 理由: 案 A だけでは、移動に 0.25〜0.9 秒かかりました。`uitable` 1 つの書き換えに 40〜60 ms かかり、1 回の表示で 5〜7 個を書き換えるためです。
  - 操作は `HTMLEventReceivedFcn` で受けます。
    - `select`: 選んだタブを、次のモデルでも同じ題なら残します。
    - `edit`: パラメータの編集です。前と同じく `net.a_Bus{1}.tab_parameter.powerflow.V = 1.02;` のようなコードを実行記録で実行し、失敗したら元の値に戻してアラートを出します。数値の列に数値でない文字を入れると、コードを実行する前に拒否します(`GUILDA:DrawerModelGUI:NotANumber`)。
    - `remove_event`: Scenario のイベントの表の行を消します。
  - 本体の `UserData` には、ページの元の MATLAB の表を入れます(アプリやテストが値を読むため)。
  - 配色は `tools.gui_palette` のライトの色です。CDN は使いません。
  - ヘッダ、追加ボタン、子の表は MATLAB のままです。
- **Scenario の表の列が切れる件**(ユーザーの報告): 原因は、ページの `uitable` の `ColumnWidth="fit"` が、空の表や中身の短い列で見出しを切っていたことです。HTML の表は列幅を見出しと中身に合わせ、収まらなければ横にスクロールします。Equilibrium、Summary、パラメータの表も同じです。データは変えていません。
- **アプリ(P1)とフォーム・ピッカー・結果の GUI(P3)は案 A で目標に届いた**ので、uihtml にはしていません。P3 の側では、uihtml のページの読み込みに 0.3 秒前後かかることと、`get_code` の規則を JS 側と二重に持つことになることも理由です。

### GUI の外で見つかった重い処理(担当: 設定・モデルと描画)

- **`msg`**: 呼ぶたびに JSON を `readstruct` で読みます(1 回 0.1〜0.15 秒)。
  - 系統図が topology になるときの `show_msg("info", "GUILDA:PowerNetwork:DiagramTopology")` が、この経路を通ります。アプリは `evalc` で表示を消していますが、文は毎回組み立てられます。
  - `HistoryGUILDA.get_variable` がない変数のエラーを作るときも同じ経路で、アプリのタブの更新で 1 回の実行に 7 回呼ばれていました。存在を確かめるメソッドがあれば避けられます(`@HistoryGUILDA` は相談が必要)。
  - 担当: 設定。
- **`PowerSystemModel.get.tab_parameter`**: 呼ぶたびに table を作ります。系統図のスナップショットで約 200 回呼んでいて、約 0.27 秒かかります(IEEE68)。
  - 図に関わる値(`operation`・`graph`・`dynamics`)が変わったことを示す印がモデルにあれば、図に影響しない編集の後の描き直しを省けます(提案)。
  - 担当: モデル。
- **`simulateFcn_check`**: 系統図を描くたびに、すべての機器と制御器の `sct_stale` を集めます(約 0.07 秒)。担当: 描画。
- **結果の図に `Graph=G` がない**(2026-11-18 以降、アプリの系統図は結果を描かないので、アプリでは問題になりません): 潮流計算の後の描き直し(IEEE68 で約 1.2 秒)は、ほとんどが `ResultPF.plot_diagram` の新しい図の作成です。`ResultPF`・`ResultOPF`・`ResultODE` の `plot_*` に `Graph=G` があれば、0.3 秒程度になる見込みです(未確認)。担当: 描画。
- `net.plot_diagram(Graph=G)` 自体は、IEEE14 で約 0.2〜0.7 秒、IEEE68 で約 0.4〜1.2 秒かかります(そのうち `set_data` が約半分)。担当: 描画。

#### `msg` と `tab_parameter` の対処(2026-11-18、`refactor/perf-msg-cache-tab-parameter`)

- **`msg`**: クラスごとの定義(`GUILDA/en/<Class>.xml`)を最初の呼び出しで読み、persistent の `containers.Map` に持っておきます。xml を編集したら `clear msg`(または `clear functions`)で読み直します(ヘルプに記載)。
  - あわせて、フォルダを `replace(mfilename("fullpath"),'msg','')` で求めていたのを `fileparts` に変えました。パスに `msg` を含むフォルダ(この作業の worktree など)では、xml が見つからずに止まっていました。
  - 呼び出し元の確かめは軽いので、そのままです。`dbstack` と分割は約 0.03 ms、`is_subclass`(サブクラスから呼ぶときだけ)は約 0.4 ms でした。ID の検査は変えていません。
- **`PowerSystemModel.get.tab_parameter`**: 組み立て方を軽くする案は採りませんでした。1 回約 0.15 ms のうち、ほとんどが `table` の作成そのもので、組み立て方では縮まないためです。代わりに、組み立てた table を Hidden・Transient のプロパティ `tab_parameterCache` に持ち、次のときに消します。
  - `Parameter` が table を保存したとき(`set.tab_parameter`。直接の書き込み、`set_parameter`、`set_layout`、GUI の編集はすべてここを通ります)。
  - `log_edit` が `Parameter` の編集を伝えるとき(値の変更と、コンテナの改名)。
  - `a_Parameter` を設定したとき(`set.a_Parameter`。import や読み込みで作り直すときも含みます)。
  - 書き込みが拒否されたときは何も保存されないので、持っている table はそのままです。MAT ファイルには保存されず、読み込んだ後に組み立て直します。
- 計測(R2026a、IEEE68bus、`initialize` の後。負荷平均 3〜5。変更前は `92ec2d18` を別のフォルダに取り出し、`msg` の 60 行目だけを `fileparts` にして測りました):

| 項目 | 変更前 | 変更後 |
|---|---|---|
| `msg` 1 回(プロファイラの値) | 7〜8 ms(うち `readstruct` 5〜6 ms) | 1〜2 ms |
| `bus.tab_parameter` 1 回(中央値) | 0.15 ms | 0.001〜0.009 ms |
| `struct(net,false)`(中央値、7 回) | 0.17〜0.19 秒 | 0.14 秒 |

  - `struct(net,false)` では getter が 251 回呼ばれます。残りの時間は、主に `snapshot` 自身と `Component.get.rv_Uoffset`(`get_variable_map`、約 0.07 秒、プロファイラの値)です。
  - 調整役の値(`msg` 0.1〜0.15 秒、getter で約 0.27 秒)より小さいのは、負荷の違いと、プロファイラで測ったかどうかの違いとみられます(未確認)。
- 試験: F80 `test_F80_parameter_table_cache`(分類 model・env、段階 medium)。編集のそれぞれの経路の後に読むと新しい値が返り、持っている table が組み立て直した table と等しいこと、`clear msg` の前後で文が同じことを確かめます。

### 試験

- 新しいテストを 3 つ加えました。分類はすべて gui です。
  - F75 `test_F75_model_gui_speed`: モデルの GUI。部品が増えないこと、本体に `Data` を 1 回だけ送ること、隠れた部品が戻ること、ページの表が列と文字をすべて持つこと、時間。
  - F76 `test_F76_guilda_app_speed`: アプリ。実行のない切り替えでは描き直さないこと、表示中のタブだけを描き直すこと、アニメーションと操作パネル、時間。
  - F77 `test_F77_gui_speed`: フォーム・結果の GUI。使い回したフォームが既定値から始まること、窓が親ごとに 1 つであること、ボタンの印、時間。
- テストの変更:
  - F32・F33・F51 は、本体を uihtml の `Data`・`UserData`・`HTMLEventReceivedFcn` で読み書きするようにしました。
  - F32・F51・F55 は、子の表の種類を切り替えた後に表を探し直します。
  - F69 の「パネルに合わせる」は、図の範囲が描画を含むことの確認に変えました。
- 結果: 3 つのブランチとも、gui の small・medium と各ファイルの単独の `runtests` が通りました。
  - P2 の medium 全体では、負荷平均 44 のときに I55 の時間制限のテストが 1 件だけ落ち、再実行ではすべて通りました。
  - F77 の `ask` の時間のテストは、負荷が急に上がると比の上限 6 を超えることがあります(large でだけ実行されます)。

### 未確認・残りの事項

- **手での確認**: 見える図で、モデルの GUI の HTML の操作をまだ試していません。セルの編集(Enter・Esc)、チェックボックス、右クリックの `Remove event`、タブの切り替えです。テストは `HTMLEventReceivedFcn` を直接呼び、表示はスクリーンショットで確かめただけです。マージの後にユーザーに試してもらう予定です。
- **ダークテーマ**: ダークテーマの図に埋め込むと、子の表の見出し行だけがテーマの色になります。
- **系統図のラベル**: アプリを隠れた図で作ってから表示したとき、系統図のラベルの合わせ直しが働くかを、目では確かめていません。
- **単発のタイマー**: アプリの描き直しのタイマーは `matlab -batch` では働きません。そのため、テストではなく `-nodesktop` で確かめました。
- **埋め込みのフォーム**(アプリの解析タブなど)は、呼び出し側が毎回作り直すので、使い回しが効きません(1 回 0.1〜0.2 秒)。使い回すには、公開メンバーを加える必要があります(P1 と P3 の相談事項)。
- **モデルの GUI の新しい窓**(0.2〜0.5 秒): ほとんどが部品の作成と `uihtml` の読み込みです。子の表も HTML にすれば、さらに縮む見込みです(未着手)。
- **前の GUI の部品**: 同じコンテナに別のモデルの GUI が描くと、前の GUI が外していた追加ボタンのグリッドは消されずに残ります。図には付いていないので、表示はされません。

## シナリオのフォーム: 依存する選択肢と add_scenario の Time(2026-11-18、`fix/gui-scenario-forms`)

`refactor/scenario-scalar-time`(`d81dc99a`)で変わった署名に、フォームを合わせました。仕組みの説明は `_GUILDAdoc/developer/feature-gui.html#history-option` と `DrawerOptionDialog.m` の冒頭にあります。

### ユーザーの判断(2026-11-18)

- `Scenario.add_input` の GUI のフォームは、`unit` が変わったら `name` の選択肢を作り直します。
- GUI の add_scenario のボタンは、タグ `"CASE"` と Time `[0, 10]` で始めます。

### 依存する選択肢(一般の仕組み)

- `choices=` の式が、同じメソッドのほかの入力を参照するときに働きます。参照の見つけ方は 2 つです。特定の署名の特別扱いはしません。
  - 入力の名前そのもの: `Scenario.add_input` の `name` の `get_element(unit)`。
  - 入力の既定値が `obj.<プロパティ>` のとき、その式: `EventInput.edit` の `Name` の式の `obj.s_unit`(`Unit` の既定値)。
  - ダブルクォートの中の文字は参照とみなしません。今の署名で依存と判定されるのは `add_input` の `name`、`EventInput.edit` の `Name`、`add_scenario` の `Time` と `Description` の 4 つだけです(両方の functionSignatures.json で確認)。
- 式の参照は `arg.<名前>` に書き換えます。その入力の今の値(ウィジェットの値、まだ作っていない欄は最初に表示する値)を `arg` に入れて `eval_text` で評価します。
- 評価し直すのは、参照される欄の change・reset・select のときだけです(`private/refresh_depend.m`)。参照されない欄を変えても評価しません。参照の参照も順にたどります。
- 一覧(`uilistbox`)とドロップダウンは新しい項目になり、その中に残る選択は残します(ドロップダウンは残らなければ最初の項目)。
- 参照される入力が空か読めない間は、項目なしにし、横のヒント(Tag `hint_<名前>`)に `Select unit first` と表示します。エラーにはしません。`History` がなく `obj` を使う式が評価できないときは、これまでどおり文字の欄です。
- `EventInput.edit` の `Name` の選択肢の式には `obj.a_Scenario.a_PowerNetwork` があり、これまでは `a_Scenario` を「シナリオの一覧」とみなしてシナリオのピッカー付きの文字の欄にしていました。パスの途中(後ろに `.` が続く `a_*`)は要素の一覧とみなさないようにしたので、入力の名前の一覧になりました。

### add_scenario の Time

- `gui_forms.json` に新しい鍵は加えませんでした。署名の既定値の文章 `From.Time, else [0, 10]` を `, else ` で候補に分け、ほかの入力を参照する候補が 1 つでもあれば、評価できる最初の候補を既定値にします(参照がなければ、これまでどおり文章のヒントです。`true if X, else false` のような文章を誤って読まないため)。
- `From` は `Time` より後の入力なので、すべての欄を作った後で評価し直します(build_form の最後の refresh_depend)。
- `From` が既定値 `Scenario.empty` のままなら `From.Time` は評価できず、`[0 10]` を表示します。`From` が `History` の変数とプロパティ・数の添字だけ(`sc0`、`net.a_Scenario{1}`)なら、その `Time` を表示します。関数やメソッドの呼び出しは評価しません(重い処理を走らせないため)。それ以外は空の欄で、ヒントに `default: From.Time, else [0, 10]` を出します。
- 欄を変えていない間だけ `From` に合わせて変わります。表示のままなら書かないので、既定のままの呼び出しは `sc = net.add_scenario();` です。`Description` も同じ仕組みで `From.Description` を表示します。

### add_trip と add_open_branch

- どちらも時刻 1 つの数値の欄で、初めは空(必須)です。`sc.add_trip("B003SG1", 1);`、`sc.add_open_branch("<ブランチ>", 0.5);` と書き、そのまま実行できることを F87 で確かめました。

### 変えたファイルとメンバー

- `@DrawerOptionDialog`: `build_form.m`、`draw_field.m`、`form_event.m`、`DrawerOptionDialog.m`(説明と private のプロパティ `a_history`)。private 関数を 4 つ加えました: `eval_depend.m`(依存する式の評価)、`refresh_depend.m`(評価し直し)、`field_baseline.m`(既定値からウィジェットの値への変換。build_form から移したもの)、`hint_text.m`(ヒントの文字。draw_field から移したもの)。`eval_text.m` は 3 つ目の入力 `arg` を受けます。
- 公開メンバーは増やしていません。署名(functionSignatures の生成、Scenario と PowerNetwork の API)は変えていません。

### 時間(IEEE68bus、2〜3 回目)

| 操作 | 時間(秒) |
|---|---|
| `Scenario.add_input` のフォームを開く | 0.24〜0.30 |
| `unit` を変えて `name` を作り直す | 0.06〜0.10 |
| 関係のない欄(`Tag`)を変える | 0.03〜0.05 |
| `EventInput.edit` のフォームを開く / `Unit` を変える | 0.17〜0.19 / 0.04〜0.05 |
| `PowerNetwork.add_scenario` のフォームを開く / `From` を変える | 0.10〜0.18 / 0.02〜0.03 |
| `Scenario.add_trip` のフォームを開く | 0.09〜0.11 |

初回(MATLAB の起動直後)は `add_input` のフォームが 1.2 秒でした。

### 試験

- F87(`test_F87_gui_dependent_forms`、分類 gui、5 節すべて medium): `add_input` の `name` が `unit` に合わせて変わり残せる選択を残すこと、関係のない欄では作り直さないこと、`unit` が空のときの `Select unit first`、`History` なしの文字の欄、`EventInput.edit` の `Name`、`add_scenario` の Time(`[0 10]`、`From` の Time、評価しない式のヒント、変えた Time を残すこと)、遮断と開放のフォームのコード。
- 単独の実行で最初の節は 6〜7 秒(MATLAB の uifigure の初回の準備)、2 回目は 2 秒でした。

## F32 を単独で実行したときの失敗(2026-11-18)

- 症状: `runtests("DebugScript.test_F32_model_gui")` だけで実行すると 2 件が失敗し、`run_all` では通るように見えていました。
- `AValueOfAnotherClassIsRefused...` の原因: `run_all` は最初に `DefaultFigureVisible` を `"off"` にしますが、F32 は自分では設定していませんでした。単独では `launch_gui` の uifigure が見える状態で開くため、`show_alert` が警告(`GUILDA:DrawerModelGUI:HiddenAlert`)の代わりに `uialert` を出し、`lastwarn` が空になっていました。GUI のコードは意図どおりの動き(見える図には `uialert`)なので、テストを直しました。F32 の共通設定で `DefaultFigureVisible` を `"off"` にし、`onCleanup` で元に戻します。ほかの GUI のテスト(F33・F50〜F52・F55〜F57・F62・F66・F69)はすでに同じ設定をしていました。
- `TheChildTablesListOneKindAtATime...` の原因: 単独かどうかとは関係がなく、`run_all` の large でも失敗していました(large のテストなので small・medium では実行されず、見逃されていました)。静的な制御器が既定になった(`ee170fc6`)後は、AVR を加えた発電機の子の表に `gov-static` も並びますが、期待が 1 行のままでした。期待を 2 行(avr と governor)に直しました。
- 手引き: テストを書く手引き(For Developer の Model implementation の「テストスイートにテストを追加する」)に、スクリプトは単独でも通るように、頼る状態は共通設定で設定して戻すこと、を 1 行加えました。

## 利用者の意見への対応(2026-11-18、`fix/launch-gui-feedback`)

ユーザーが `GUILDA.launch_gui` を試して出した 3 つの要望に対応しました。仕組みの説明は `_GUILDAdoc/developer/feature-gui.html` の「解析のタブ」「Time simulation タブ」と結果の GUI の節にあります。

### 1. 解析の後に Analyze result を目立たせる

- 要望: 解析が終わったら Analyze result を押せばよいことが分からなかった。
- 新しい結果がまだ開かれていない間は、Analyze result を塗りのボタン(ロゴの青 `rv_blue`、太字、白字)にし、Run を普通の見た目(`rv_card`、本文の色)にします。2 つのボタンの見た目を入れ替える形です。状態の行の終わりには "— open Analyze result" と書きます。
- 「新しい結果」の条件: 結果の変数に `ResultBase` があり、そのタブの呼び出し(`[res_pf, flag_pf] = net.calculate_powerflow(` など)で最後に終わった記録が done で、タブから最後に開いた結果(`res_opened`)と違うこと。記録の行から実行した結果も新しい結果です。
- 元に戻るとき: 結果を開いたとき、実行が失敗したとき(変数は前の結果のまま)、結果の変数がなくなったとき。
- 実装は共通の private 関数 `analyze_highlight.m` で、解析のタブ(`tab_analysis_panel.m`)と時間シミュレーションのタブ(`tab_sim_refresh.m`)の 2 か所から呼びます。履歴の変化(`f_changed`)のときだけ動き、タブの切り替えでは動きません。変わるプロパティだけを設定します。
- 点滅は入れませんでした(タイマーが要るため)。タイマーは使っていません。

### 2. アプリの系統図は平衡点のまま

- 要望: 解析が終わると、アプリの系統図も結果で描き替わる。平衡点の潮流状態のままでよい。ただし、シナリオで設定した条件や OPF の画面の条件の表示は今のまま残す。
- 潮流計算のタブ: `res_pf.plot_diagram` の分岐を除き、母線の種類の色分け(slack 赤、PV 青、PQ 灰)を実行の前後とも表示します。
- 最適潮流計算のタブ: `res_opf.plot_lmp` の分岐を除き、コストのある機器の選択を実行の前後とも表示します。
- 時間シミュレーションのタブ: `res_ode.plot_diagram` の分岐を除き、シナリオの対象の選択を実行の前後とも表示します。結果の図とともに、時刻のスライダーの行、状態の `G_res`、`tab_sim_action` の "time" と "sync" の分岐をなくしました(ほかに使う所がないため)。`res` と `s_res_scenario` は状態の行の "[case1]" に使うので残しました。
- 連続潮流計算のタブの LoadBus の選択は条件なので残しました。近似線形解析のタブは既定の描画のままです。
- 凡例(`f_legend`)は、潮流計算と最適潮流計算では実行の前後で同じ文にし、"Open Analyze result after a run to see ..." と書きます。`tab_analysis_legend.m` は CPF のタブだけが使います。
- 結果は Analyze result のウィンドウだけで見ます。

### 3. 結果の GUI で動く図を自動で再生する

- 要望: 解析結果を描くとき、動くものは既定で再生してほしい。
- 対象: 描いた図(`G_plot`)が標本 2 つ以上の `GraphBase` で、`GraphChart` でないもの(`ResultODE.plot_diagram`、`plot_spring_model` など)。`plot_trajectory` などの時系列のグラフは時刻の線が動くだけなので再生しません(判断。必要なら変えられます)。`plot_iteration` は最初の出力のグラフ(`GraphChart`)が対象になるので再生しません。
- 始め方(2026-11-20 に `G.play()` に替えました。「自動再生を再生バーの play に替える」の節): private メソッド `DrawerResultGUI.autoplay` が、1 回だけ動くタイマー(Tag `"GUILDA:DrawerResultGUI:Autoplay"`、`StartDelay` 0.1 秒)で `G.animate()` を呼びます。図を描いたボタンの処理はすぐに終わるので、ウィンドウは操作できます。タイマーは `StopFcn` で自分を消します。前の図のタイマーが待っていれば先に消します。
- 止まるとき: ウィンドウを閉じたとき、ほかの図に置き換えたとき(軸が消えるので `animate` が次の画で抜けます)、操作パネル(Display options)の Pause を押したとき。
- `matlab -batch` と非表示のウィンドウでは再生せず、タイマーも作りません(テストの結果を変えないため)。
- 見えるウィンドウの系統図は `FlowAnimation` を true にします(既定で true なので、普段は何も変わりません)。
- `GraphBase` の変更(private だけ): プロパティ `l_animating` を加えました。`animate` の間は true で、操作パネルの再生のボタンは Pause を示します(再生中に出したパネルでも)。再生中に Play を押しても 2 つ目の再生は始めません。`animate` は途中で抜けたときも、エラーのときも、最後に `l_animating` を戻してボタンを Play にします。
- 気づいたこと: 再生はタイマーのコールバックの中で `animate` が回るので、MATLAB のコマンドの処理(テストの `pause` など)は再生が終わるまで戻りません。ウィンドウのボタンは `animate` の `pause`・`drawnow` の間に動きます。

### 公開したメンバー

- ありません。加えたのは private メソッド `DrawerResultGUI.autoplay`、private プロパティ `DrawerResultGUI.t_autoplay` と `GraphBase.l_animating`、`@DrawerGUILDA/private/analyze_highlight.m` です。

### 試験

- F90 `test_F90_analyze_highlight`(gui、medium、3 件): 潮流計算のタブと時間シミュレーションのタブの強調と戻り方、記録の行から実行した結果、タイマーを作らないこと。
- F91 `test_F91_result_gui_autoplay`(gui・graph、medium、4 件): バッチと非表示のウィンドウで再生しないこと、再生中の Pause の表示と二重に再生しないこと、Pause で次の画で止まること、軸を消すと止まること。見えるウィンドウで実際に再生が始まるテストは `matlab -batch` では SKIP します(`-nodesktop` で通ることを確かめました)。
- F56・F57・F69・F76 の系統図の確かめ方を、平衡点のままの図に直しました。F56 の状態の行の確かめ方も直しました。名前が変わったテストは `test_levels.m` を直しました。
- 番号は F81・F86 がほかのブランチで使われているため、F90・F91 にしました。
- 気づいたこと: スクリプトのテストの最初の節(共通設定)は、ファイルで 1 回だけ実行されます(各テストの前ではありません。R2026a で確かめました)。そのため、GUI のテストの共通設定の `c_fig = onCleanup(@() close_new_figures(...))` は、テストごとには図を閉じません。F90 の図が残った同じセッションで F56・F57 を続けて実行すると、「結果のウィンドウが 1 つ」の確かめで落ちました。F90・F91 は、各節の始めに `a_before` を取り、終わりに `close_new_figures(a_before)` を呼ぶようにしました。ほかの GUI のテスト(F55〜F57 など)の共通設定は直していません(残りの事項)。

### 計測(R2026a、IEEE68bus、非表示のアプリ、3 回目の値)

| 項目 | 変更前(`4ce61ae0`) | 変更後 |
|---|---|---|
| 潮流計算のタブの Run(計算と描き直し) | 1.66 秒 | 0.91 秒 |
| タブの切り替え(潮流計算 ⇔ モデル) | 0.04〜0.06 秒 | 0.04〜0.09 秒 |

- Run が短くなったのは、結果の図を新しく作らず、系統図を `Graph=G` で描き直すためです。潮流計算そのものは約 0.35〜0.43 秒です。1 回目と 2 回目は JIT の影響で長く(変更前 6.2・3.8 秒、変更後 5.0・2.8 秒)、負荷の違いもあるので目安です。

## 自動再生を再生バーの play に替える(2026-11-20、`fix/result-gui-play`)

`feature/graph-playback-bar` で、2 標本以上の `GraphBase` に再生バー(Play/Pause、時刻のスライダー、時刻の文字、速度)と公開メンバー `PlaySpeed`・`play()`・`pause()` が加わりました。時刻のスライダーと Play は `show_controls` の操作パネルから再生バーに移りました。このブランチはそれに結果の GUI を合わせます(`feature/graph-playback-bar` から切りました)。

### 変更

- `DrawerResultGUI.autoplay` は `G.play()` を直接呼びます。1 回だけ動くタイマー(Tag `"GUILDA:DrawerResultGUI:Autoplay"`)と private プロパティ `t_autoplay` とその後始末をなくしました。再生は再生バーの timer(Tag `"GUILDA:GraphBase:Playback"`)で、すぐに戻るので、ボタンの処理もウィンドウも止まりません。
- `matlab -batch` と非表示のウィンドウの判定は `autoplay` から除きました。`play()` がその場合に timer を作らず何もしないためです。
- 再生する図の条件は同じです(標本 2 つ以上の `GraphBase` で、`GraphChart` でないもの)。`play()` は 1 標本と軸のない図でエラーになるので、`autoplay` は標本の数と軸を先に確かめます。
- 止まるとき: ウィンドウを閉じたとき、ほかの図に置き換えたとき(軸が消えると timer も消えます)、再生バーの Pause を押したとき。ヘルプ(`autoplay.m`、`DrawerResultGUI.m`)の「Pause of the control panel」を「Pause of the playback bar」に直しました。
- 系統図の `FlowAnimation` を true にするのは、見えるウィンドウだけでなく非表示のウィンドウと `-batch` でも行うようになりました(判定を除いたため)。`FlowAnimation` は既定で true で、非表示と `-batch` では流れの timer を作らないので、動きは変わりません。
- Display options(`show_plot_controls.m`)は変えていません。時刻の行がなくなっても、操作のある図(系統図)は幅 230 px、操作のない図(`GraphChart` は "No controls for this graph." だけ)は幅 0 のままで動くことを F91 で確かめました。

### 公開したメンバー

- ありません。private プロパティ `DrawerResultGUI.t_autoplay` を除きました。

### 試験

- F91 `test_F91_result_gui_autoplay`(gui・graph、medium、5 件)を書き直しました。
  - バッチと非表示のウィンドウで再生せず timer もないこと(名前は同じ)。
  - `PlayOfThePlaybackBarShowsPauseWhileAnimatePlays_PlayDoesNotStartASecondOne_PauseStopsIt`(旧 `ThePlayButtonShowsPauseWhileAnimatePlays_…`): プロットのパネルの再生バーの Play(`findall(<プロットのパネル>, "Tag", "GUILDA:GraphBase:Play")`)が `animate` の間 Pause を示し、Play を押しても timer を作らず、Pause で次の画で止まること。
  - 軸を消すと `animate` が止まること(名前は同じ)。
  - `DisplayOptionsWithoutATimeRow_TheDiagramShowsItsControlsAndATimeChartNone`(新規): 上の Display options の確かめ。
  - `AVisibleWindowStartsPlayingByATimerAndTheButtonReturns_Closing_ReplottingOrDeletingTheAxesLeavesNoTimer`(旧 `AVisibleWindowStartsPlayingAnAnimatedPlotAfterTheButtonReturns_…`): `batchStartupOptionUsed` を隠して(F61・F100 と同じ)見える uifigure で、timer があり Play が Pause を示すこと、最後まで再生すること、描き直す・時刻のグラフに替える・軸を消す・窓を閉じると timer が残らないこと。`-batch` でも SKIP しません。
- `test_levels.m` の F91 の名前を直し、新しいテストを medium に登録しました。

## OPF の反復を自動再生する(2026-11-20、`fix/result-gui-play`)

`refactor/opf-structure`(`26b03111`)で、`ResultOPF.plot_iteration(Parent)` は `[G_chart, G_net]` を返すようになりました。自分の Play とスライダーはなくなり、`G_chart`(`GraphChart`)の再生バーが `G_chart.link(G_net)` で系統図も動かします。結果の GUI の `G_plot` は最初の出力の `G_chart` で、`GraphChart` は再生しない決まりだったので、反復は自動再生しませんでした。2026-11-20 に利用者が直すことを承認しました。

### 変更

- `DrawerResultGUI.autoplay(obj, c_output)` に、図を描いた呼び出しのすべての出力(`c_output`)を渡します(`run_method.m`)。`GraphChart` の `G_plot` は、標本が 2 つ以上あり、かつ `c_output` に `GraphChart` でない、標本が 2 つ以上の `GraphBase` があるときだけ再生します(`plot_iteration` の `G_net`)。
- link を読む公開の手段は `GraphBase` にありません(`c_link` は private)。そのため、link ではなく「同じ呼び出しのほかの出力」で決めます。`@GraphBase` などの Graph* のファイルは変えていません。
- `play()` を呼ぶのは `G_plot`(`G_chart`)だけです。timer は 1 つで、`G_net` は link で同じ反復に動きます。
- `plot_trajectory` のような時系列のグラフだけの図は、これまでどおり自動再生しません。止まるとき(窓を閉じる、ほかの図に置き換える、Pause)も同じです。
- 開いたときの既定の図(`render.m`)は変えていません。`ResultOPF` の最初の `plot_*` は `plot_dispatch`(`GraphChart` だけ)なので再生しません。
- `FlowAnimation` を true にするのは、これまでどおり `G_plot` が系統図のときだけです。`G_net` の `FlowAnimation` は既定の true のままです。

### 公開したメンバー

- ありません。private メソッド `autoplay` に引数 `c_output` を加えました。

### 試験

- F91 に `TheIterationsOfAnOPFPlay_TheChartPlaysByOneTimerAndTheLinkedNetworkDiagramFollows_ClosingTheWindowLeavesNoTimer`(medium)を加えました。IEEE9bus の AC OPF で、非表示の窓では再生しないこと、見える窓(`batchStartupOptionUsed` を隠す)では開いたときの `plot_dispatch` は再生せず、`plot_iteration` で `"GUILDA:GraphBase:Playback"` の timer が 1 つでき、`G_net.i_time` が動いて `G_chart.i_time` と同じであること、窓を閉じると再生と流れの timer が残らないことを確かめます。
- `batchStartupOptionUsed` を隠す処理をローカル関数 `hide_batch_startup` にまとめ、`press` はダイアログのないメソッド(`s_dialog` が `""`)ではタイマーを作らないようにしました。

### 残りの事項

- 窓を閉じたとき、`G_net` の流れの timer が一度だけ `GUILDA:GraphNetDiagram:FlowTimer` の警告(「double 型の変数では、ドット インデックスはサポートされていません」)を出して止まります。`flow_tick` が消えた図を読むためです。timer は残りません。`GraphNetDiagram` の範囲なので、このブランチでは直していません。

## 結果のフォームの表のピッカー(2026-11-22、`fix/gui-result-target-picker`)

利用者の依頼(2026-11-22): 結果の GUI の `ResultLIN.get_contribution`、`get_reduced_matrix`、`plot_reduced_matrix` のフォームで、`target` の横に Select... を付け、要素とクラスの一覧から選べるようにする。`target` には結果の `choices` 式があるのでタグの一覧の欄になっていましたが、`ResultLIN` には `a_network` がないので Select... が付きませんでした。GUI の調整役の決定で、`ResultLIN` の特例ではなく一般の仕組みとし、公開のメンバーは加えません。

### 変更

- `gui_forms.json` の `pick` は、要素の種類の一覧の代わりにオブジェクト `{"table": "<obj の式>"}` も取ります。`choices` のある入力(欄が一覧またはドロップダウン)に使います。
  - `build_form`: この項目があれば `s_pick = "table"`、式を `s_table` に置きます。一覧の欄は要素のピッカーと同じくタグの文字の欄(`tagtext`)にします。`a_network` を見ません。フォームを作るときには式を評価しません(開く速さを保つため)。`History` がなく選択肢を評価できない欄(文字列の欄)には付きません。
  - `form_event` の `"select"`: 式を `a_object` で評価し(`eval_text`。エラーの文を返す 3 つ目の出力を加えました)、`Tag` 列のある表なら `DrawerTagPicker.pick` を開きます。`Multiple` は欄に従い(`"scalar"` なら 1 行)、`Selected` は今の値です。選んだタグは要素のピッカーと同じく欄に書きます。式がエラー、`Tag` 列がない、行がないときは、`GUILDA:DrawerOptionDialog:NoPickTable`(「<入力>: nothing to select (<理由>).」)を、表示中の窓では `uialert`、非表示の窓では警告で出し、欄は変えません。エラーは出しません。
  - 要素の種類の一覧の `pick`(`choices` のない入力)は、これまでどおり `a_network` があるときだけです。
- `gui_forms.json` の 3 つの項目の `target` の表: `obj.sct_model.sct_sys.tab_owner` の要素ごとの行(Tag = Owner、Class、Kind = `"element"`)と、Class ごとの行(Tag = クラス名、Class、Kind = `"class"`)。`plot_reduced_matrix` は既存の項目に加え、`get_contribution`(main: Index)と `get_reduced_matrix`(main: State、Index、Time)は新しい項目で、これまでの名前による分類(`_fallback`)と同じ配置です。Mode と Group は加えていません。
- パッケージ名(`controller.avr` など)は `choices` にありますが、表には入れていません(依頼の範囲は要素とクラス)。手で入れれば使えます。

### 公開したメンバー

- ありません。private の欄の構造体に `s_table` を、private 関数 `eval_text` に 3 つ目の出力 `s_error` を加えました。メッセージ `GUILDA:DrawerOptionDialog:NoPickTable` を加えました。

### 試験

- F113 `test_F113_gui_table_picker`(分類 gui、4 件): 3 つのフォームの `target` が文字の欄と Select... になること(History がなければ付かない)、表に要素の行とクラスの行があり複数選択であること、2 行選ぶと欄と `get_code()` に書かれ、開き直すと選んだ状態であること、モデルのない `ResultLIN()` では式がエラーになり警告だけで欄が変わらないこと、`Scenario.add_trip` の `unit` の要素のピッカーがそのまま動くこと。
- 段階(`test_levels.m`、small での時間): 式のエラーの節(0.09 秒)は small、フォームの節(1.7 秒)と `add_trip` の節(1.2 秒)は medium、ピッカーを 4 回開く節(4.8 秒)は large。
- フォームの開く時間(IEEE9bus、新しい非表示の uifigure、`drawnow` まで、2〜6 回目の中央値): `get_contribution` 0.484 秒、`get_reduced_matrix` 0.480 秒、`plot_reduced_matrix` 0.481 秒。Select... のない `get_eigenvalue` は 0.464〜0.499 秒で、差はありません。

## 自動再生はバーを持つ最初の出力(2026-11-22、`feature/ode-side-chart-bar-rule`)

Graph の Q4(再生バーは描く内容が時刻で変わる図だけ)と Q3(ResultODE の `plot_diagram`・`plot_spring_model` の横のグラフ、`[G, G_chart]`)に合わせて結果の GUI を変えました。GUI の取りまとめの了承済みです。

### 変更

- `DrawerResultGUI.autoplay(obj, c_output)`: 「`GraphChart` の `G_plot` は、同じ呼び出しのほかの出力が `GraphChart` でない動く図のときだけ再生する」規則をやめました。出力(`c_output`。空なら `{G_plot}`)を順に見て、再生バーを持つ最初の図を `play()` します。timer は 1 つです。
- バーは新しい公開メンバーを使わずに探します。図の `ax(1).Parent` が tiledlayout のとき、その親(図の容器)の直下を `findall(..., "-depth", 1, "Tag", "GUILDA:GraphBase:PlaybackBar")` で探します。横のグラフは別の uipanel に入るので、`G` のバーを横のグラフのものと取り違えません。
- `plot_diagram`・`plot_spring_model` は `G` が再生し、link した `G_chart` が動きます。`plot_iteration` はバーが `G_net` に移ったので `G_net` が再生し、`G_chart` が動きます。`plot_trajectory` はバーがなく再生しません。
- `FlowAnimation` を true にするのは今までどおり `G_plot` が系統図のときです。
- `render.m`: 開いたときの最初の図も、署名の出力の数だけ受け取り(`[c_value{:}] = ...`)、`autoplay(obj, c_value)` に渡します(`run_method` と同じ)。`G_plot` は最初の GraphBase の出力です。
- `G_plot`(Display options の対象)は最初の GraphBase の出力のままで、`[G, G_chart]` なら `G` です。操作パネルは `G` の区画ではなく GUI の 2 列目に出ます(`show_plot_controls` は変えていません)。
- ヘルプ(`DrawerResultGUI.m`、`autoplay.m`、`render.m`)と `feature-gui.html`(EN/JA)を直しました。

### 公開したメンバー

- ありません。

### 試験

- F91: Display options の節で、時刻のグラフ(`plot_trajectory`)に再生バーがないことを確かめるように直しました。見える窓の節に、`plot_diagram` で `G` が再生し(timer 1 つ、バーが Pause)、横のグラフ `G_chart` が同じ時刻に動くことを加えました。OPF の節は「`G_net` が再生し、グラフが動く」に直し、名前を `TheIterationsOfAnOPFPlay_TheNetworkDiagramPlaysByOneTimerAndTheLinkedChartFollows_ClosingTheWindowLeavesNoTimer` に変えました(`test_levels.m` も)。
- F52: ResultODE の節で `plot_diagram` を `Trajectory="Vangle"` で実行し、コードが `[G, G_chart] = res.plot_diagram(Trajectory="Vangle", Parent=h_parent);` になることと、書き出したスクリプトで図が 2 つできることを確かめます。


- 失敗した実行が、ハンドルのオブジェクト(`net`)の一部をすでに変えている場合があります。その記録は失敗としてスクリプトから除かれるので、書き出したスクリプトを実行しても、その途中までの変更は再現されません。`HistoryGUILDA` は失敗時にワークスペースの変数を戻しますが、ハンドルの中身は戻せません。モデルの GUI は失敗した後も描き直して、実際の状態を表示します。
- `launch_gui` が作る既定の実行記録は `net` を変数として持つだけで、それを作る行はスクリプトに入りません。スクリプトを何もない状態から実行できるようにするには、先にネットワークを実行記録で作ります(第2a段階で対応: `GUILDA.launch_gui()` の開始画面の選択がスクリプトの最初の行になります。`GUILDA.launch_gui(net)` は、ヘッダーに `net` が起動時の系統であると書きます)。
- `ResultLIN.get_ss` と `plot_eigenvalue` の引数のコメントの `Default:` が 2 回入る件は、第1b段階で直しました(`c20d935e`)。
- `DrawerOptionDialog` の 3 つの不具合(第1b段階で発見)は、同じ段階で直しました。`choices` の欄の既定値が配列のとき(`disp_violation`、`disp_binding`)は複数を選べる一覧にし、文字列の欄の既定値が空(`strings(1,0)`)のとき(`plot_convergence`、`disp_bus`、`disp_branch`)は空の欄にし、欄のない署名でもフォームを作れるようにしました。一覧で何も選ばないと `strings(1,0)` と書きます。F50 に各場合のテストを、F52 に 5 つのボタンの実行を加えました。`functionSignatures.json` のすべての署名(55 件)でフォームを作れることも確かめました(テストには入れていない)。
- F52 は small(`test_levels.m` に登録なし)で約 70 秒です。AC OPF の計算(約 5 秒)とダイアログの待ちが大半です。small のまま(2026-11-16 決定)。
- F51 の `ask` を使うテストは 1 件 15〜23 秒です(追加を 10 回)。small の目安を超えるので、`test_levels.m` への登録(medium)が必要か確認が必要です。
- `Echo=true` の出力は実行の後にまとめて表示します(`evalc` で取り込むため)。長いシミュレーションの途中経過(`Progress="disp"`)は実行中には表示されません。
- `attach_view` のダブルクリックで開くファイルは、行の最初の `<受け手>.<メソッド>(` を見て、受け手の式(`net.a_Bus{3}` など、関数呼び出しを含まないもの)をワークスペースで評価してクラスを求めます。見つからなければ最初の `<関数>(` を `which` で探します。テストでは確認していません(エディターが開くため)。
- テストの段階: F50 は small(`test_levels.m` に登録なし)です。`ask` の 2 つのテストはそれぞれ約 5 秒と約 10 秒かかります。medium の基準(1 件 1 秒程度)を超えるので、small のままでよいか確認が必要です。
- `ask` の待ち方(2026-11-16): 表示中のダイアログは `uiwait` で利用者を待ちます。非表示(親の図が非表示)または `matlab -batch` のときは操作する人がいないため、`pause(0.05)` の繰り返しで最大 10 秒待ち、その後キャンセル(`""`)として返します。ループは自分で終わるので、コールバックやタイマーが動かなくても止まりません。
  - 経緯: 2026-11-15 の small `run_all` が F50 で 11 時間以上止まりました(`uiwait` は戻る条件がボタンの押下だけで、テストのタイマーがダイアログを見つけられないと戻りません)。どのセクションで止まったかはログに残っていません(`run_all` のログは終了時に書くため)。F50 だけ、および直前の F44・F46・F47・F4 との組み合わせでは再現しませんでした。原因は未確定ですが、待ちに上限を付けたので再発しても 10 秒で返ります。F50 に「誰も押さないと 10 秒以内に `""` を返す」テストを加えました。
- 非表示の図では `uialert` を使いません。フォームの無効な値はフォームの中のメッセージで知らせます。
- `PowerNetwork.initialize` を `sig_methods` に加えました(第2a段階)。`initialize` は `arguments` ブロックになり(`50244b3e`)、潮流計算のタブでフォームを使っています(第2b段階)。
- F56(第2b段階、`test_F56_guilda_app_analysis`)は 1 件 6〜33 秒です。アプリの作成(初回約 7 秒)と、実行記録の 1 回の実行ごとの描き直し(約 1.3 秒)が大半です。2026-11-17 のテストの分類(`6925a5e4`、`notes/test-categories.md`)に従い、分類 gui に登録し、6 件とも large にしました。F50 に加えた 2 件(文章の既定値、1 つの値のタグ)も large です(3.3〜5.6 秒)。
- 結果の変数は最後の実行のものです。実行の後で系統を編集しても、Analyze result が開くのは前の結果です(系統図は結果を描かないので、図には出ません。2026-11-18 の「利用者の意見への対応」)。
- F55(第2a段階、`test_F55_guilda_app`。F54 はグラフ配置のテストと重なったため変更)は small で約 100 秒です(各テストでアプリを作り、系統図の描画が 1 回 0.6〜0.8 秒かかる。ダイアログの待ちを含む)。small のままでよいか、medium に登録するか確認が必要です。
- 系統図をタブの切り替えのたびに描き直す件は、高速化(2026-11-18)で解消しました。いまは実行の後にだけ描き直します(上の「高速化」の節)。
