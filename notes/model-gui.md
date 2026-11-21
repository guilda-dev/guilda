# モデルの GUI(`LayerPackage.launch_gui`)

> 基準: `refactor/design-alignment` の `f5555ce1`(2026-11-07)。仕組みの説明は `_GUILDAdoc/developer/feature-gui.html` にあり、このノートは経緯、決定事項、残りの事項だけを記録します。

## 構成の要約

- 入口: `obj.launch_gui()`(新しい `uifigure`)と `obj.launch_gui(h_container)`(`uifigure`、`uipanel`、`uitab`、`uigridlayout` に展開)。戻り値は `DrawerModelGUI`。
- 画面:
  - ヘッダ: ロゴの青の帯とライムの線。1行目はルートから自身までのパンくず、2行目はタグ、クラス、Docs ボタン(`GUILDA.doc("class", ...)`)、stale の状態。
  - 子の表(第3-2b段階、2026-11-17): 子を種類ごとに 1 つずつ、検索できる小さな表で示します(`build_navigation.m`)。種類はドロップダウン(`Bus (14)` など)で選び、列は `DrawerTagPicker.element_table` から取ります。行のクリックで表示、行のメニューで `Open in new window` と `Remove`。Parameter のコンテナは含めません。子のないモデルでは表を作らず、追加ボタンだけならその幅の列、どちらもなければタブを全幅にします。
  - タブ: Parameter(Docs を促す1行。1 行でスカラーだけのコンテナは名前と値の縦の表を 2 つずつ横に並べ、それ以外は1パラメータ1列の横並び)→ 各抽象クラスの表(平衡点は1変数1行の縦並び)。
- ページ定義: protected の `gui_content` が構造体の列を返します。種類は `table` だけで、フィールドは `s_title`、`s_type`、`content` の3つです。`PowerSystemModel.gui_content` の基底の実装は空を返します。
- 配色: 固定のライトテーマ。色は `_GUILDAsystem/+tools/gui_palette.m` にまとめています(第1a段階で private の複製を削除)。
- 主なファイル: `_GUILDAsystem/_auxiliary/@LayerPackage/launch_gui.m`、`gui_content.m`、`_GUILDAsystem/@<抽象クラス>/gui_content.m`、`_GUILDAsystem/_auxiliary/@DrawerModelGUI/`。
- 操作: 追加ボタン、子の表の行の `Remove`、Scenario のイベントの表の行の `Remove event`(`remove_event`)、パラメータの編集。どれも `HistoryGUILDA` で実行するコード。
- テスト: `+DebugScript/test_F32_model_gui.m`、`+DebugScript/test_F33_model_gui_network.m`、`+DebugScript/test_F51_model_gui_actions.m`(操作)、`+DebugScript/test_F69_gui_layout.m`(子の表の使い回し、画面構成)。

## 経緯

| 段階 | 内容 | マージ |
|---|---|---|
| 第1段階 | `gui`、`gui_content` の基底、`DrawerModelGUI`(ヘッダ、ツリー、Parameter タブ、`render`) | `39587a6e`(`feature/model-gui`) |
| 第2段階 共通部分 | `latex` ページ(KaTeX)、`katex_data`、種類の整理 | `427cf28d` |
| 第2段階 ネットワーク | `Bus`、`Branch`、`PowerNetwork` のページ | `c1bad4f9` |
| 第2段階 動特性 | `PowerSystemModel` の Initialize、`Component`、`LocalController`、`GlobalController` のページ | `0fa337f3`(`feature/model-gui-dynamics`) |
| 第3段階 | 開発者向けページ `feature-gui.html` とこのノート | `3d1b0dd6`(`docs/model-gui`) |
| 改修 | 固定のライトテーマ(`gui_palette`)、パンくずと Docs ボタンのヘッダ、ツリーを子カードに置き換え、Parameter の表を横並び、平衡点の表を縦並び。Equations、Image、Initialize のページと KaTeX を削除し、ページの種類を `table` だけに | `f5555ce1`(`feature/model-gui`) |
| 改修の文書 | `feature-gui.html`、`model-implementation.html`、Update log、`gui.m` の help、このノートを改修に合わせて更新 | `docs/model-gui` |
| 改名 | `gui` を命名規則(verb_noun)に合わせて `launch_gui` に改名(動作は変更なし)。help、呼び出し、テスト、開発者向けページ、Update log を更新 | `refactor/launch-gui` |
| 操作(第1a段階) | 追加ボタン、カードの Remove、Scenario の外乱の削除、パラメータの編集を `HistoryGUILDA` のコードとして実行。`launch_gui(..., History=)`、イベント `ModelChanged` | `feature/gui-model-actions`(未マージ) |

## 決定事項

### ページの内容は抽象クラス6つだけで決める

- ページを作るのは `PowerNetwork`、`Bus`、`Branch`、`Component`、`LocalController`、`GlobalController` の `gui_content` だけです。基底の `PowerSystemModel.gui_content` は空を返します。
- 利用者が作る継承先のクラスでは、GUI のために何も実装しません。利用者が書くものを増やしたくない、というユーザーの判断です(2026-11-07 承認)。
- 表は抽象クラスのプロパティ(`sv_x`、`sv_u`、平衡点、`a_Parameter`)から作ります。パラメータとモデルの説明は、Docs ボタンで開くクラスのリファレンスに任せます。

### Equations、Image、Initialize のページを削除した(改修、`f5555ce1`)

- 削除したもの: Equations(`latex`、KaTeX、`latex_page.html`、`katex_data`)、Image(`image`、`@Class/image.svg`)、Initialize(`action`、`s_label`)、ツリー(`uitree`)。ページの種類は `table` だけになりました。
- 理由:
  - モデルのクラスで作るもの(help の数式、`image.svg`)を GUI のために増やさないため。
  - 数式や図などの説明は Docs(クラスのリファレンス)に任せ、GUI からは Docs ボタンで開くため。
  - GUI から関数(Initialize など)を実行するのは、ユーザーの判断で廃止しました(この時点)。2026-11-14 にこの判断は見直されました(下の「GUI から関数を実行する」)。
- `ascii` と `custom` は第2段階で削除済みです。未知の種類は `Unknown page type: ...` のラベルになります。

### GUI から関数を実行する(2026-11-14 の判断の見直し)

- ユーザーは「GUI は関数を実行しない」という前の判断を取り消しました。追加・削除と、記録を残すパラメータの編集を GUI から行います。解析(`initialize`、潮流計算など)は今もモデルの GUI からは実行しません(`GUILDA.launch_gui` の解析タブで行う予定)。
- どの操作もコード文字列にして `HistoryGUILDA.run` で実行します。記録と書き出すスクリプトが、実行した内容と一致します(`launch-gui.md` の決定事項)。
- 実装(`feature/gui-model-actions`):
  - コードは実行記録のルートの変数から親のリストと番号でモデルに届きます(`net.a_Bus{3}.a_Component{1}`)。ルートの変数はネットワークなら `net`、それ以外はクラスから(`bus`、`branch`、`comp`、`con`、`gcon`)。実行記録に変数がなければ設定し、別のモデルを持っていれば `GUILDA:DrawerModelGUI:OtherRoot` で拒否します。
  - 追加ボタン: PowerNetwork は Bus、Branch、GlobalController、Scenario。Bus は Component。Component と LocalController は LocalController(`Component.add_local_controller` を機器に対して実行。`LocalController.add_local_controller` はオブジェクトを受け取る内部向けのメソッドなので使いません)。Scenario は `add_fault`、`add_trip`、`add_open_branch`、`add_offset`、`add_input`(`add_disturbance` は Scenario のイベントのクラス化で削除)。第3-2b段階でボタンの文字を短くしました(`+ Controller` は PowerNetwork ではグローバル制御器、Component ではローカル制御器。ツールチップにメソッド)。
  - 削除: 子の表の行のコンテキストメニューの `Remove`(第3-2b段階より前はカード。入れ子の制御器を持つ制御器は `RemoveNested=true`)。Scenario のイベントの表の行の `Remove event`(`remove_event`。`remove_disturbance` から改名)。表示中の図では `uiconfirm` で確認し、非表示の図と batch では確認せずに実行します。
  - パラメータの編集: 変わった変数ごとに `<式>.tab_parameter.<コンテナ>.<変数> = <mat2str>;`。行が複数の表は変わった行だけ(`(2)`)、クラスが変わった列は列全体。
  - 操作の後は描き直し(失敗のときも)、成功したときだけ `ModelChanged` を通知します。パラメータの編集は描き直さず、stale の表示だけ更新します。
  - `DrawerOptionDialog` に `History` を加え、`Object` をその実行記録のワークスペースで評価します。`obj` を使う選択肢(タグ)は複数選べる一覧になります(`add_branch` の両端の母線を選ぶため。ドロップダウンでは 1 つしか選べない)。

### 配色は固定のライトテーマ

- MATLAB のテーマに追従させると、ダークテーマで色を設定した部品と設定しない部品が混ざり、読めない箇所が出るため、すべての部品に `gui_palette.m` の色を設定します。
- 新しい `uifigure` には、`Theme` プロパティがあれば `Theme="light"` を設定します。埋め込み先の figure のテーマは変えません。

### `f_model`

- `DrawerModelGUI` はモデルの継承階層の外のクラスなので、protected の `parent`、`children`、`gui_content` を読めません。
- `launch_gui` の中で無名関数 `f_model = @(o) struct("parent", ..., "children", ..., "pages", {o.gui_content()})` を作り、`DrawerModelGUI` のコンストラクタの第3引数として渡します。無名関数は作った場所のアクセス権を保つことを R2026a で確かめています。ユーザーが案 A として承認しました。
- パンくずのために、ルートまでの各親でも `f_model` を呼びます。
- GUI のためだけの public なアクセサーは追加していません。

### その他

- パンくずのリンクと子カードのクリックは同じコンテナに再描画し、子カードのコンテキストメニュー `Open in new window` で別のウィンドウに開きます。
- セルの編集は即座にコードとして実行記録で実行します(上の「GUI から関数を実行する」)。検査、ログ、stale への反映は `Parameter` が行い、GUI はエラーのとき表を元に戻してアラートを出すだけです。
- `figure()` で作った図は `isUIFigure` 動的プロパティで見分けて拒否します(R2025a 以降の `figure()` は UI コンポーネントを受け付けるため)。エラーは `GUILDA:DrawerModelGUI:NotUIContainer` です。

## 未確認・残りの事項

- **medium のテストで I55 の時間制限テストが2回落ちました。** 負荷によるものと見ており、単独で再実行すると合格しました(`+DebugScript/test_I55_time_limit.m`、`test_levels.m` で medium)。
- **別の GUI に埋め込むときの注意**
  - `render` が消すのは、コンテナの子のうち `Tag` が `"DrawerModelGUI"` のもの(と、その子カードのコンテキストメニュー)だけです。ホストのアプリは同じ `Tag` を使わないでください。
  - `uipanel` や `uitab` に他の部品と一緒に入れると重なります。専用のパネルを渡すのが安全です。
  - `uigridlayout` をコンテナとして渡すと、最初の描画では前のグリッドがないので `Layout` を設定せず、MATLAB の自動配置に任せます。2回目以降は前のグリッドの `Layout` を引き継ぎます。位置を決めたい場合は、そのセルに `uipanel` を置いて渡してください。
  - パンくずや子カードのクリックでも `render` が走るので、ホストの選択状態と表示中のモデルがずれることがあります。表示中のモデルは `h.a_target` で読みます。表示の切り替えを通知するイベントはありません(モデルの変更は `ModelChanged` で通知します)。
  - コンテキストメニューは図が所有するので、ホストが図のメニューを独自に管理している場合は干渉しないか確かめてください(未確認)。
  - ダークテーマの figure に埋め込むと、タブの見出しと表の見出し行はテーマの色になります(`uitabgroup` と `uitable` に色のプロパティがないため)。ほかの部分はライトの配色のままです。
  - 非表示の図では `uialert` が使えないため、警告 `GUILDA:DrawerModelGUI:HiddenAlert` に変わります。
- **第1a段階の残り(2026-11-16)**
  - `h.render(他の木のモデル)` は、そのモデルのルートが実行記録の変数と違っても描けますが、操作のコードは実行記録の変数からたどるので失敗します(`NotInTree` など)。ホストは同じ木のモデルだけを渡してください。
  - 確認(`uiconfirm`)と表示中の図のアラートはテストで確かめていません(非表示の図だけで試験)。
  - `Remove event` は右クリックした行(`InteractionInformation.Row`)を使い、なければ選択した行を使います。右クリックの経路は手動で未確認です。
  - ルートがネットワーク以外(単独の Component など)の場合: 抽象クラスのコンストラクタが外から呼べないため、テストではネットワークのルートだけを確かめています。
