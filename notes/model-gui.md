# モデルの GUI(`PowerSystemModel.gui`)

> 基準: `refactor/design-alignment` の `f5555ce1`(2026-11-07)。仕組みの説明は `_GUILDAdoc/developer/feature-gui.html` にあり、このノートは経緯、決定事項、残りの事項だけを記録します。

## 構成の要約

- 入口: `obj.gui()`(新しい `uifigure`)と `obj.gui(h_container)`(`uifigure`、`uipanel`、`uitab`、`uigridlayout` に展開)。戻り値は `DrawerModelGUI`。
- 画面:
  - ヘッダ: ロゴの青の帯とライムの線。1行目はルートから自身までのパンくず、2行目はタグ、クラス、Docs ボタン(`GUILDA.doc("class", ...)`)、stale の状態。
  - 子カード: 子を種類ごとにまとめ、種類の色のカードで並べます(`build_navigation.m`)。Parameter のコンテナは含めません。子のないモデルではカードの列を作らず、タブを全幅にします。
  - タブ: Parameter(1パラメータ1列の横並び、横スクロール、Docs を促す1行)→ 各抽象クラスの表(平衡点は1変数1行の縦並び)。
- ページ定義: protected の `gui_content` が構造体の列を返します。種類は `table` だけで、フィールドは `s_title`、`s_type`、`content` の3つです。`PowerSystemModel.gui_content` の基底の実装は空を返します。
- 配色: 固定のライトテーマ。色は `@DrawerModelGUI/private/gui_palette.m` にまとめています。
- 主なファイル: `_GUILDAsystem/_auxiliary/@PowerSystemModel/gui.m`、`gui_content.m`、`_GUILDAsystem/@<抽象クラス>/gui_content.m`、`_GUILDAsystem/_auxiliary/@DrawerModelGUI/`。
- テスト: `+DebugScript/test_F32_model_gui.m`、`+DebugScript/test_F33_model_gui_network.m`。

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
  - GUI から関数(Initialize など)を実行するのは、ユーザーの判断で廃止しました。GUI がモデルに対して行うのはパラメータの書き込みだけです。
- `ascii` と `custom` は第2段階で削除済みです。未知の種類は `Unknown page type: ...` のラベルになります。

### 配色は固定のライトテーマ

- MATLAB のテーマに追従させると、ダークテーマで色を設定した部品と設定しない部品が混ざり、読めない箇所が出るため、すべての部品に `gui_palette.m` の色を設定します。
- 新しい `uifigure` には、`Theme` プロパティがあれば `Theme="light"` を設定します。埋め込み先の figure のテーマは変えません。

### `f_model`

- `DrawerModelGUI` はモデルの継承階層の外のクラスなので、protected の `parent`、`children`、`gui_content` を読めません。
- `gui` の中で無名関数 `f_model = @(o) struct("parent", ..., "children", ..., "pages", {o.gui_content()})` を作り、`DrawerModelGUI` のコンストラクタの第3引数として渡します。無名関数は作った場所のアクセス権を保つことを R2026a で確かめています。ユーザーが案 A として承認しました。
- パンくずのために、ルートまでの各親でも `f_model` を呼びます。
- GUI のためだけの public なアクセサーは追加していません。

### その他

- パンくずのリンクと子カードのクリックは同じコンテナに再描画し、子カードのコンテキストメニュー `Open in new window` で別のウィンドウに開きます。
- セルの編集は即座に `tab_parameter` に書き込みます。検査、ログ、stale への反映は `Parameter` が行い、GUI はエラーのとき表を元に戻してアラートを出すだけです。
- `figure()` で作った図は `isUIFigure` 動的プロパティで見分けて拒否します(R2025a 以降の `figure()` は UI コンポーネントを受け付けるため)。エラーは `GUILDA:DrawerModelGUI:NotUIContainer` です。

## 未確認・残りの事項

- **medium のテストで I55 の時間制限テストが2回落ちました。** 負荷によるものと見ており、単独で再実行すると合格しました(`+DebugScript/test_I55_time_limit.m`、`test_levels.m` で medium)。
- **別の GUI に埋め込むときの注意**
  - `render` が消すのは、コンテナの子のうち `Tag` が `"DrawerModelGUI"` のもの(と、その子カードのコンテキストメニュー)だけです。ホストのアプリは同じ `Tag` を使わないでください。
  - `uipanel` や `uitab` に他の部品と一緒に入れると重なります。専用のパネルを渡すのが安全です。
  - `uigridlayout` をコンテナとして渡すと、最初の描画では前のグリッドがないので `Layout` を設定せず、MATLAB の自動配置に任せます。2回目以降は前のグリッドの `Layout` を引き継ぎます。位置を決めたい場合は、そのセルに `uipanel` を置いて渡してください。
  - パンくずや子カードのクリックでも `render` が走るので、ホストの選択状態と表示中のモデルがずれることがあります。表示中のモデルは `h.a_target` で読みます。ホストに通知するイベントはありません。
  - コンテキストメニューは図が所有するので、ホストが図のメニューを独自に管理している場合は干渉しないか確かめてください(未確認)。
  - ダークテーマの figure に埋め込むと、タブの見出しと表の見出し行はテーマの色になります(`uitabgroup` と `uitable` に色のプロパティがないため)。ほかの部分はライトの配色のままです。
  - 非表示の図では `uialert` が使えないため、警告 `GUILDA:DrawerModelGUI:HiddenAlert` に変わります。
