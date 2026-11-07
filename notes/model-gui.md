# モデルの GUI(`PowerSystemModel.gui`)

> 基準: `refactor/design-alignment` の `0fa337f3`(2026-11-07)。仕組みの説明は `_GUILDAdoc/developer/feature-gui.html` にあり、このノートは経緯、決定事項、残りの事項だけを記録します。

## 構成の要約

- 入口: `obj.gui()`(新しい `uifigure`)と `obj.gui(h_container)`(`uifigure`、`uipanel`、`uitab`、`uigridlayout` に展開)。戻り値は `DrawerModelGUI`。
- 画面: ヘッダ(タグ、クラス、stale)、ツリー(親 → モデル → 子)、タブ(Parameter → 各クラスの表 → Equations → Image → Initialize)。
- ページ定義: protected の `gui_content` が構造体の列を返します。種類は `latex`、`image`、`table`、`action` の4つです。
- 主なファイル: `_GUILDAsystem/_auxiliary/@PowerSystemModel/gui.m`、`gui_content.m`、`_GUILDAsystem/@<抽象クラス>/gui_content.m`、`_GUILDAsystem/_auxiliary/@DrawerModelGUI/`。
- テスト: `+DebugScript/test_F32_model_gui.m`、`+DebugScript/test_F33_model_gui_network.m`。

## 経緯

| 段階 | 内容 | マージ |
|---|---|---|
| 第1段階 | `gui`、`gui_content` の基底、`DrawerModelGUI`(ヘッダ、ツリー、Parameter タブ、`render`) | `39587a6e`(`feature/model-gui`) |
| 第2段階 共通部分 | `latex` ページ(KaTeX)、`katex_data`、種類の整理 | `427cf28d` |
| 第2段階 ネットワーク | `Bus`、`Branch`、`PowerNetwork` のページ | `c1bad4f9` |
| 第2段階 動特性 | `PowerSystemModel` の Initialize、`Component`、`LocalController`、`GlobalController` のページ | `0fa337f3`(`feature/model-gui-dynamics`) |
| 第3段階 | 開発者向けページ `feature-gui.html` とこのノート | `docs/model-gui` |

## 決定事項

### ページの内容は抽象クラス6つだけで決める

- ページを作るのは `PowerNetwork`、`Bus`、`Branch`、`Component`、`LocalController`、`GlobalController` の `gui_content` と、その基底の `PowerSystemModel.gui_content` だけです。
- 利用者が作る継承先のクラスでは、GUI のために何も実装しません。利用者が書くものを増やしたくない、というユーザーの判断です(2026-11-07 承認)。
- 継承先のクラスの情報は、すでに書いてあるものから自動で取ります。
  - 数式: クラス help の `**Equations**` の下の ```` ```math ```` ブロック。`help(class(obj))` で読むので、上位クラスの help は対象外です。
  - 画像: `@Class/image.svg`。モデルのクラスから上位クラスへ幅優先で探し、最初に見つかったものを使います。
  - 表: 抽象クラスのプロパティ(`sv_x`、`sv_u`、平衡点、`a_Parameter`)。

### `ascii` と `custom` のページを削除した

- 第1段階の種類は `latex`、`ascii`、`image`、`table`、`action`、`custom` の6つでした。
- 第2段階で、ページの内容を抽象クラス6つだけで決める方針とあわせて、`ascii` と `custom` を削除しました(ユーザー承認、2026-11-07)。数式は KaTeX の `latex` で表示します。
- 残る種類は `latex`、`image`、`table`、`action` の4つです。未知の種類は `Unknown page type: ...` のラベルになります。

### Initialize はルートのネットワークで実行する

- Initialize のページは `PowerSystemModel.gui_content` が作ります。親をたどって最初に見つかった `PowerNetwork`(モデルが属するネットワーク)の `initialize()` を実行し、その後 `render()` で再描画します。
- どの階層のモデル(母線、機器、制御器)を表示していても、ボタンが初期化するのはネットワーク全体です。
- ネットワークに属さないモデルでは、タブを出しません。
- 失敗したときはアラートを出し、再描画しません。

### `katex_data`

- `uihtml` は、HTML ファイルのフォルダとその下のフォルダにあるファイルしか読めません。`latex_page.html` は `@DrawerModelGUI/private/` にあり、KaTeX は `_GUILDAdoc/vendor/katex/` にあるので、パスでは読み込めません。
- `build_page.m` のローカル関数 `katex_data` が `katex.min.js` と `katex.min.css` を読み、woff2 のフォントを data URI として CSS に埋め込み、`Data` で渡します。結果は persistent 変数に保持し、MATLAB のセッションごとに1回だけ読みます。ユーザー承認済みです。

### `f_model`

- `DrawerModelGUI` はモデルの継承階層の外のクラスなので、protected の `parent`、`children`、`gui_content` を読めません。
- `gui` の中で無名関数 `f_model = @(o) struct("parent", ..., "children", ..., "pages", {o.gui_content()})` を作り、`DrawerModelGUI` のコンストラクタの第3引数として渡します。無名関数は作った場所のアクセス権を保つことを R2026a で確かめています。ユーザーが案 A として承認しました。
- GUI のためだけの public なアクセサーは追加していません。

### その他

- ツリーのクリックは同じコンテナに再描画し、コンテキストメニュー `Open in new window` で別のウィンドウに開きます。
- セルの編集は即座に `tab_parameter` に書き込みます。検査、ログ、stale への反映は `Parameter` が行い、GUI はエラーのとき表を元に戻してアラートを出すだけです。
- `figure()` で作った図は `isUIFigure` 動的プロパティで見分けて拒否します(R2025a 以降の `figure()` は UI コンポーネントを受け付けるため)。エラーは `GUILDA:DrawerModelGUI:NotUIContainer` です。

## 未確認・残りの事項

- **KaTeX の見た目は未確認です。** テスト(F32)は `uihtml` に渡す `Data`(`sv_math`、`s_js`、`s_css`)までを確かめていますが、MATLAB の画面で数式が実際にどう描かれるか(フォント、大きさ、長い式の横スクロール)は目で確かめていません。
- **medium のテストで I55 の時間制限テストが2回落ちました。** 負荷によるものと見ており、単独で再実行すると合格しました(`+DebugScript/test_I55_time_limit.m`、`test_levels.m` で medium)。
- **配布物に `_GUILDAdoc/vendor/katex` が必要です。** `katex_data` は `<リポジトリのルート>/_GUILDAdoc/vendor/katex/` を固定のパスで読みます。配布パッケージで `_GUILDAdoc` を削るか移すと、Equations のページを描くときに `fileread` が失敗し、数式を持つモデルの GUI が開けなくなるはずです(推測、未実行)。現在の `.claude/release/release.sh` は `_GUILDAdoc` を削りません。
- **別の GUI に埋め込むときの注意**
  - `render` が消すのは、コンテナの子のうち `Tag` が `"DrawerModelGUI"` のもの(と、そのツリーのコンテキストメニュー)だけです。ホストのアプリは同じ `Tag` を使わないでください。
  - `uipanel` や `uitab` に他の部品と一緒に入れると重なります。専用のパネルを渡すのが安全です。
  - `uigridlayout` をコンテナとして渡すと、最初の描画では前のグリッドがないので `Layout` を設定せず、MATLAB の自動配置に任せます。2回目以降は前のグリッドの `Layout` を引き継ぎます。位置を決めたい場合は、そのセルに `uipanel` を置いて渡してください。
  - ツリーのクリックでも `render` が走るので、ホストの選択状態と表示中のモデルがずれることがあります。表示中のモデルは `h.a_target` で読みます。ホストに通知するイベントはありません。
  - コンテキストメニューは図が所有するので、ホストが図のメニューを独自に管理している場合は干渉しないか確かめてください(未確認)。
  - 非表示の図では `uialert` が使えないため、警告 `GUILDA:DrawerModelGUI:HiddenAlert` に変わります。
