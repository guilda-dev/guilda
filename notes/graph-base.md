# 図の共通の基底クラス(GraphBase)

基準: ブランチ `feature/graph-base`(`refactor/design-alignment` の 0cac2e73 から分岐)、2026-11-14。第 1 段階(GraphBase、GraphSpring の移行、DrawerNetDiagram → GraphNetDiagram)と、同日にユーザーが承認した追加(クリック、選択、reset_style、plot_diagram の State と Graph、uiaxes)の記録です。

GUILDA のすべての図をオブジェクトにし、後からの変更(データと時刻、位置、ラベル、色、そのほかの見た目)の受け口を 1 つにそろえます。アニメーションも同じコードで描きます。

## 1. クラスの階層

`_GUILDAsystem/_auxiliary` に置きます(名前空間なし)。

```
GraphBase(抽象、< auxiliary)
├─ GraphSpringBase ─ GraphSpring2D / GraphSpring3D   (plot_spring_model)
├─ GraphNetDiagram   (旧 DrawerNetDiagram。plot_diagram。2D が既定、Dimension="3D" で立体)
├─ GraphNetMap       (第 2b 段階。ResultPF.plot_network。§4.5)
└─ GraphChart        (第 2a 段階: 結果の折れ線・棒グラフ。§4.4。ResultODE.plot_trajectory)
```

`DrawerModelGUI` は GUI なので対象外です(`Drawer*` の名前のまま)。

## 2. 公開の API(GraphBase)

| メンバー | 内容 |
|---|---|
| `set_time(t)` | t に最も近い標本を表示し、リンクした図に伝える(各図は自分の時刻で最も近い標本)。リンクは推移的にたどり、各図を 1 回だけ描く(環でも再帰しない)。軸を消した図はとばす。自分の軸が消えていれば `GUILDA:GraphBase:NoAxes` |
| `set_data(sct_data)` | データを差し替えて描き直す。契約はサブクラスのコンストラクタのデータと同じ。同じタグ・種類の要素の見た目は残し、新しい要素はデータの既定値。表示する標本は前の時刻に最も近いもの。リンクした図は動かさない |
| `set_style(sr_tag, Color=, Label=, Marker=, MarkerSize=, LineWidth=, LineStyle=, Visible=)` | タグで見た目を変える。サブクラスの要素ごとのベクトルのプロパティに書き込むので、2 つの書き方は常に一致し、変わった要素だけを描き直す |
| `set_position(sr_tag, rm_xy)` | 自由配置の図(`GraphNetDiagram`、`GraphNetMap`)だけが上書きする。基底は `GUILDA:GraphBase:PositionNotSupported`。`GraphSpring*` は位置が電圧フェーザなので `GUILDA:GraphSpringBase:PositionPhysical` |
| `get_layout()` | 図が今描いている位置を `net.get_layout` の形で返す(2026-11-16 追加。notes/graph-layout.md §5.4)。`net.set_layout(G.get_layout())` で位置だけをモデルに保存する。`GraphNetDiagram` は `tab_bus`(`Tag`、`X`、`Y`)と `tab_component`(`Tag`、`DX`、`DY`)、`GraphNetMap` は `tab_bus` だけ。基底は `set_position` と同じ `GUILDA:GraphBase:PositionNotSupported` |
| `tab_element` | 読み取り専用(Dependent)。要素ごとに `Tag`、`Kind`、`Index`(その種類のベクトルの中の位置) |
| `animate(Speed=, TimeStep=, UpdateFcn=)` | `GraphSpringBase` から移動。動作は同じ。1 標本なら `GUILDA:GraphBase:OneSample` |
| `export_video(s_file, FrameRate=20, TimeStep=0.05, HoldTime=1, UpdateFcn=, Capture=)` | 同上。録画するのは呼んだ図の figure(`Capture="axes"` なら最初のパネル)。別の figure にあるリンクした図は動くが動画には入らない |
| `link(G_other)` / `unlink(G_other)` | 対称。二度目のリンクと自分自身へのリンクは何もしない。削除した図は読むときに捨てる |
| `ax`、`sct_plt`、`rv_t`、`i_time` | 読み取り専用。`ax` は軸の配列(パネルが複数のとき) |
| `Parent`(コンストラクタと各 `plot_*` の Name-Value) | 容器(figure、uifigure、uipanel、uitab、uigridlayout)か、1 パネルの図なら axes / uiaxes。空なら新しい figure。§3.2 |
| `reset_style(sr_tag)` | そのタグの要素の見た目(style_properties のベクトル)をデータの既定値に戻す。引数なしは全要素。選択は変えない |
| イベント `ElementClicked`、`ElementClickedFcn` | 要素のクリックで `notify` し、`ElementClickedFcn`(既定 `[]`)を `fcn(G, data)` で呼ぶ。`data` は `GraphEventData`(`event.EventData` のサブクラス。読み取り専用の `Tag`、`Kind`、`Index`) |
| イベント `TimeChanged`、`TimeChangedFcn` | `set_time` が図を描いた後に `notify` し、`TimeChangedFcn`(既定 `[]`)を `fcn(G, data)` で呼ぶ。`data` は `GraphTimeEventData`(`event.EventData` のサブクラス。読み取り専用の `Time`(表示した標本の時刻 `rv_t(Index)`)と `Index`(`i_time`))。リンクで動いた図、`animate` と `export_video` のこまごとにも出る。同じ標本でも `set_time` のたびに出る。`build` と `set_data` では出ない。2026-11-16 追加(OPF の調整役の依頼をユーザーが承認。§3.3) |
| `show_controls(Parent=[], ChangedFcn=[])`、`hide_controls()`、`h_controls` | 図の操作パネル(2026-11-17、`feature/graph-controls`、マージ済み 6812d85e)。サブクラスの protected `control_list()` の宣言から作り、プロパティを設定するだけ。部品 → プロパティ、プロパティ → 部品(`PostSet`、`TimeChanged`)の 2 方向。エラーで部品が戻る。Parent が空なら軸の右(約 220 px)、容器ならそれを埋める。自動では出さない。詳しくは notes/graph-diagram-2d.md §5 と §8.3 |
| `select(sr_tag)`、`clear_selection()`、`Selection`、`SelectionColor` | 選択は set_style と別の層。選んだタグの全要素に `SelectionColor`(既定 `#FFB000`、RGB で保持)の重ね描き(クリックを取らない)。見た目のベクトルは変えないので、外すと元の見た目に戻る。`set_time`、`set_data`、描き直しの後も残り、消えたタグは外れる |

set_style の規則:

- タグは 1 つ以上(string 配列)。知らないタグは `GUILDA:GraphBase:UnknownTag`(知らないタグだけを示す)。
- 同じタグの要素が複数の種類にある(矢印は節点のタグ、リンクは機器のタグ)とき、オプションはそれを持つ種類の要素に効き、持たない種類はとばす。そのタグのどの要素にも効かないオプションは `GUILDA:GraphBase:StyleNotApplicable`(種類ごとの使えるオプションを示す)。
- `Color` は色の名前、`"#RRGGBB"`、RGB。`Label`、`MarkerSize`、`LineWidth` は 1 つかタグごと(数が違えば `GUILDA:GraphBase:StyleValue`)。そのほかは全タグに 1 つの値。

## 3. フックの約束(protected)

| フック | 約束 |
|---|---|
| `load_data(sct_data)` | データを検査して保存し、`rv_t`(1 × n_t)と `i_time = 1` を設定し、見た目のベクトルをデータの既定値にする。描かない(実行中は `sct_plt` が空なので、ベクトルの setter は描かないこと) |
| `create_scene()` | `ax` に固定部分を描き、要素のグラフィックスオブジェクトをベクトルの見た目で作って `sct_plt` に入れる。`build` と `set_data` から呼ばれ、固定部分を変えるプロパティの setter からも呼ぶ |
| `update_scene(k)` | 標本 k を描く(`i_time` は k)。時刻の表示(タイトル、カーソル線など)も受け持つ |
| `apply_style(iv_element)` | `tab_element` の行 iv_element の見た目をベクトルから描き直す。ベクトルの setter は図があるとき、変わった行だけで呼ぶ |
| `tab = element_table()` | 今のデータの要素表(`Tag`、`Kind`、`Index`) |
| `sct_map = style_properties()` | 種類ごとに、効く set_style のオプションと書き込むプロパティ(例 `sct_map.node.Color = "NodeColor"`)。オプションのない種類は `struct()` |

基底の `build(opt, n_panel=1, rv_grid=[n_panel 1])`(protected)は、`make_axes(opt.Parent, n_panel, rv_grid)` を `ax` にし、ほかの Name-Value をプロパティに写し、`create_scene`、`update_scene(1)`、`apply_selection` を呼びます。サブクラスのコンストラクタは `load_data` の後に `build` を呼びます。パネルが複数の図(第 2a 段階)はパネルの数を `build` に渡し、格子に並べる図は `rv_grid = [n_row n_col]` も渡します(2026-11-16 追加。省くと 1 列で、以前の呼び出しはそのまま動く)。

### 3.2 Parent と `make_axes(h_parent, n_panel)`(protected)

- 空: 新しい figure を作り、その中に次の容器の扱いをします。
- 容器(figure、uifigure、uipanel、uitab、uigridlayout): その中に `tiledlayout(rv_grid(1), rv_grid(2))`("compact"。既定 `rv_grid = [n_panel 1]`)を作り、n_panel 個の axes を行の順(左から右、上から下)にタイルに作ります。最後のパネルより後のタイルは空のままです。タイルがパネルより少ない格子は `GUILDA:GraphBase:GridSize`。容器のほかの中身は消しません。
- uigridlayout: tiledlayout は**次の空いたセル**に入ります(作る前に Layout を指定する方法がないため)。セルを選ぶときは、後で `G.ax(1).Parent.Layout.Row/Column` を設定します。
- axes / uiaxes: 1 パネルの図(GraphNetDiagram、GraphSpring2D/3D、のちの GraphNetMap)はそのまま描きます。複数パネルの図は `GUILDA:GraphBase:ParentNeedsContainer`。
- それ以外は `GUILDA:GraphBase:ParentType`(旧 `ParentNotAxes`。figure も受け付けるようになったので名前を変えた)。
- `plot_diagram(Graph=G)` などの描き直しは `make_axes` を呼ばず、G の axes をそのまま使うので、tiledlayout や axes は増えません(F47 で数を確認)。
- テスト用の 2 パネルの図 `DebugScript.helper.GraphPanelStub` が、第 2a 段階のフックの約束(複数パネル、`build(opt, 2)`、クリック、選択、見た目)を確かめる最小の例です。

追加のフック(第 1 段階の追加分、2026-11-14):

| フック | 約束 |
|---|---|
| `apply_selection()`(抽象) | 前の重ね描きを消し、`Selection` のタグの要素に `SelectionColor` で重ね描きする。重ね描きは `PickableParts="none"`。基底は `build`、`set_time`、`set_data`、`select`、`clear_selection`、`SelectionColor` の変更の後に呼ぶ。サブクラスが自分で `create_scene` や `update_scene` を呼ぶとき(プロパティの setter など)はその後に呼ぶ |
| `click_element(i_row)`(基底の実装) | サブクラスは `create_scene` で各要素のグラフィックスの `ButtonDownFcn`(またはデータチップなどほかの当たり判定)から、要素の `tab_element` の行で呼ぶ。基底が `GraphEventData` を作り、イベントとコールバックを出す |

`reset_style` の既定値は、`build` で `load_data` の直後(Name-Value の前)の見た目のベクトルです。`set_data` では、前からある要素は前の既定値を、新しい要素は新しいデータの既定値を持ちます。1 つのベクトルを複数の種類が使う(GraphChart の `SeriesColor` は line・bar・marker の全要素)とき、`set_data` は種類ごとにタグで写します(2026-11-16、GraphChart のために変更。以前は最後の種類の行だけを写していた)。

### 3.3 TimeChanged の順と無限ループの防止(2026-11-16)

- `set_time` は、まずリンクをたどって全部の図を描き(各図 1 回)、その後で描いた順に各図の `TimeChanged` の `notify` と `TimeChangedFcn` を呼びます。コールバックの中では、リンクしたどの図もすでに新しい標本を表示しています。
- コールバックが走っている間、その `set_time` で描いた図は固定です(私用のフラグ `l_timeFixed`)。コールバックから呼んだ `set_time` は固定の図を動かさず、イベントも出さず、その先のリンクもたどりません。リンクのガード(各図を 1 回だけ描く)と同じ考えで、リンクした図の `set_time` を呼ぶコールバックも、図どうしで `set_time` を呼び合うコールバックも止まります(固定の図は増える一方なので、呼び出しの連鎖は図の数で終わる)。固定でない図(リンクのない図)は普通に動いて、イベントを出します。
- 自分のコールバックから自分の `set_time` を呼んでも何も起きません(固定のため)。
- コールバックのエラーはそのまま出ます。フラグは戻すので、その後も図は動かせます。リスナー(`addlistener`)のエラーは MATLAB の規則で警告になります。
- 時刻のパネルのない GraphChart(`update_scene` が何もしない)でも `TimeChanged` は出ます。パネルの題を時刻ごとに書くときなどに使います。
- 「表示が変わる set_time ごと」は「`set_time` が描いた図ごと」と解釈しました。同じ標本でも出ます(初めの標本を指定したときに、時刻ごとの見た目を付けるコールバックが呼ばれないと困るため)。軸を消した図と固定の図は描かないので出ません。
- イベントデータは `GraphEventData`(Tag、Kind、Index)が要素のためのものなので使わず、`GraphTimeEventData`(`Time`、`Index`)を加えました。

操作パネルのフック(2026-11-17、`feature/graph-controls`、マージ済み 6812d85e):

| フック | 約束 |
|---|---|
| `sct_ctl = control_list()` | パネルの操作の宣言(行ごとに `Property`、`Widget`、`Items`、`Limits`、`Step`、`Label`、`Group`、`EnableFcn`)。基底は空。宣言するプロパティは `SetObservable`。GraphSpringBase(Label: ShowLabel・ShowValue・ShowLegend、View: RotationScale・ArrowScaleP・ArrowScaleQ、Time)、GraphSpring3D(+ SurfaceAlpha)、GraphChart(時刻のパネルがあれば Time だけ)が宣言済み。GraphNetDiagram(View・Color・Size・Flow・Label・Time の 14 行と時刻)と GraphNetMap(Size: BranchWidthRange だけ)は S4(2026-11-17、`feature/graph-controls-net`、マージ済み 921e6135。graph-diagram-2d §11.3)。自動(NaN)にできる range は `Items` に使っている値を返す関数 `@(G) [a b]` を書くと、行に Auto のチェックボックスが付きます(GraphNetDiagram の `ColorLimits`。2026-11-17、`feature/diagram-look`、graph-diagram-2d §12) |
| `prepare_frame(r_dt)` | `export_video` が各こまの前に `1/FrameRate`、最後に NaN で呼ぶ。基底は何もしない。GraphNetDiagram が上書きし、timer を止めて `step_flow(r_dt)` で流れの点を進め、NaN で timer を戻す(graph-diagram-2d §8.2、S2) |

私用: `refresh_controls()`(パネルをプロパティと表示中の標本に合わせる。`set_data` の最後とリスナーから呼ぶ)、`l_stopAnimate`(パネルの一時停止で `animate` が次のこまで止まる)。

共通の静的ヘルパー(protected static): `set_arrow`、`place_label`、`resolve_overlap`(2026-11-17、`feature/diagram-look`: 箱は最初に 1 回の `get(hv, "Extent")` で測り、縦の移動は箱の計算だけで進め、最後にテキストを動かします。重なっている箱だけを調べます。結果は前と同じ考え方で、GraphSpring2D とネットワーク図の 2D のラベルが使います)、`write_frame`、`range_map`(2026-11-17 追加。量の全標本の最小〜最大 `[vmin vmax]` を範囲 `[a b]` に線形に写す。尺度がなければ全部 (a+b)/2、全部同じ値なら有限の要素を (a+b)/2、NaN は a。notes/graph-diagram-2d.md §4.1)。クラスフォルダの private 関数はサブクラスから呼べないので、基底のメソッドにしました。

### 3.4 図の生存とコールバックの弱い参照(2026-11-17、`fix/graphchart-weakref`)

- **きまり: グラフィックスのコールバックは図のオブジェクトを `matlab.lang.WeakReference` でだけ持つ。** 強い参照を捕まえると、`savefig`(Live Editor の出力も)が関数のワークスペースごと図のオブジェクトを保存します。大きな図では `MATLAB:loadsave:saveRecursionLimit` の警告になり(GraphNetDiagram の S1。graph-diagram-2d §11.1)、警告が出ない小さな図でも .fig に図のオブジェクトの複製が入り、`openfig` で生き返ります(GraphChart の線の `ButtonDownFcn` で確かめた)。
- **図の生存は `build` が受け持つ。** `build` は `make_axes` の直後に、`ax(1)` へ `addlistener(ax(1), "ObjectBeingDestroyed", ...)` を付けます。このリスナーは図を `containers.Map` に入れて持ち、軸が消えるときに map を空にします。これで、出力を受け取らない図(`res.plot_trajectory();`、`res.plot_iteration(...)`)も軸がある間は動き、figure を消すと解放されます。全部の図が `build` を通るので、仕組みは 1 つです。
  - リスナーが図を直接捕まえると解放されません(図 → `ax` → リスナー → 図の環。R2026a で確かめた)。map を空にして環を切ります。
  - `addlistener` のリスナーは軸の寿命に結び付き、図のプロパティにも `UserData` にも入らないので、`savefig` は保存しません。figure の appdata や軸の `UserData` に図を入れる方法は、保存されるので採りませんでした。
  - 軸を消しても `delete(G)` はしません。利用者が出力 G を持っていれば、図を閉じた後も G は有効です(`set_time` などは `GUILDA:GraphBase:NoAxes`)。
- 弱い参照にしたコールバック: GraphChart の線・マーカー・棒の `ButtonDownFcn`(私用の `click_weak`)、`show_controls` のすべての操作の関数、`PostSet`・`TimeChanged` のリスナー、パネルの `DeleteFcn`(私用の `call_weak(wr, fcn)`。`on_delete` は図が消えていても軸の位置を戻す)。GraphNetDiagram・GraphNetMap は S1 から、`ResultOPF.plot_iteration` は 4e744715 から弱い参照です。GraphSpring2D/3D の節点とばねの `ButtonDownFcn` も同じ私用の `click_weak` にしました(調整役の承認のうえ、`fix/graph-spring-plot` と行が分かれるようにその行だけ)。
- 保存して開いた図のコールバックの弱い参照は空なので、クリックや操作は何もしません(図のオブジェクトは保存されないため)。パネルのリスナーも空で保存されます。
- 新しい図やコールバックを足すときは、`obj` を捕まえず `wr = matlab.lang.WeakReference(obj)` を捕まえ、呼ぶ前に `isempty(G) || ~isvalid(G)` を確かめます。図を生かしておく仕組みを別に作る必要はありません。
- F48 が確かめること: 出力を clear してもクリックが `ElementClickedFcn` を呼ぶ、`savefig` が警告を出さない、保存した図を開いてもコールバックのワークスペースに GraphBase がない(操作パネルを含む)、figure を消すと弱い参照の先が無効になる。GraphChart、plot_trajectory(操作パネルつき)、GraphSpring2D、GraphSpring3D で確かめます(medium)。

### 3.1 第 2 段階への見通し

- **GraphChart**(第 2a): `ax` はパネルの配列、要素は系列(種類 `"line"`、`"bar"`、`"marker"` など、タグは系列名)。`create_scene` が全パネルの線を作り、`update_scene(k)` は時刻のカーソル(xline)を動かすだけ(線は全時刻を描いたまま)。`style_properties` は `line` に `Color`、`LineWidth`、`LineStyle`、`Visible`、`Label`(凡例)を割り当てる。`LineStyle` は今は GraphSpring・GraphNetDiagram のどちらにもないオプションで、GraphChart のために API にある。
- 第 2 段階の図も `apply_selection` を実装し、`create_scene` で `click_element` をつなぐ(GraphChart なら系列の線)。
- **GraphNetMap**(第 2b): 地図上の母線とブランチ。位置が地理座標なら `set_position` は上書きしない(物理的な位置)、模式図なら上書きする。

## 4. サブクラスの要素とベクトル

### 4.1 GraphSpringBase(GraphSpring2D / 3D)

| 種類 | タグ | set_style | ベクトル |
|---|---|---|---|
| `node` | `sv_node` | Color, Label, Marker, MarkerSize, Visible | `NodeColor`(n×3)、`NodeLabel`、`NodeMarker`、`NodeSize`、`NodeVisible` |
| `edge` | `sv_edge`(省くと `"E1"`, `"E2"`, …) | Color, LineWidth, Visible | `EdgeColor`(n×3)、`EdgeLineWidth`、`EdgeVisible` |
| `arrow` | 節点のタグ | なし | なし |

- データの `sv_marker`、`rv_size`、`sv_color` はベクトルの初期値で、`sct_data` には残しません(見た目の置き場所を 1 つにするため)。`rm_color` も無くなりました。
- `EdgeLineWidth` の既定値は 2D 0.8、3D 1.0(以前の描画と同じ)。
- クリック: 節点(`Node`)とばね(`Spring`)の `ButtonDownFcn`。選択: 節点に輪(`NodeSize + 10` の o)、ばねに幅の広い線(`EdgeLineWidth + 4`、下に置く)。矢印は節点のタグを持つが重ね描きはしない。
- 3D で節点のマーカーが球と円錐の間で変わると、面の大きさが変わるので図を作り直します。大きさが変わると今の標本を描き直します。
- 節点を隠すと、そのラベルと |E| の円も隠れます。矢印は隠れません(矢印には見た目のオプションがない)。

### 4.2 GraphNetDiagram

| 種類 | タグ | set_style | ベクトル |
|---|---|---|---|
| `bus` | 母線のタグ | Color, Label, MarkerSize | `BusColor`(n×3)、`BusLabel`、`BusMarkerSize` |
| `component` | 機器の完全なタグ | Color, Label, MarkerSize | `ComponentColor`、`ComponentLabel`、`ComponentMarkerSize` |
| `branch` | ブランチのタグ | Color, LineWidth | `BranchColor`、`BranchLineWidth` |
| `link` | 機器のタグ | Color | `LinkColor` |

- `set_position` は母線と機器を図の中だけで動かします(規則 6: 図はモデルに書かない)。位置は図が持ち(`tab_bus.graph`、`tab_component.graph` の写し。2026-11-16 から新しい列: 母線は中心 `X`、`Y`、機器は母線の中心からの `DX`、`DY`)、スナップショットの座標か自動配置が既定値です。機器の位置は母線からの相対なので、母線を動かすと機器と接続線の折れ点もついてきます。機器に与えた位置(絶対)は母線からの相対に直して持ちます。
- `set_data` は状態 `sct_state`(`rv_t`、`cm_Vbus`、`cm_Icomp`)を差し替えます。追加のフィールド `sct_network`(新しいスナップショット)があれば系統も設定し直します(編集した系統の描き直し)。スナップショットに座標のない母線・機器は、前に描いていた位置をタグで引き継ぎ、新しいものだけを自動配置します(`tools.layout_place_buses`。座標のある母線は動かない。notes/graph-layout.md §4.7)。見た目と選択もタグで残ります。コンストラクタの引数 `(sct_network, sct_state)` は 2026-11-13 の表のままです。
- 2D と 3D(2026-11-17、notes/graph-diagram-2d.md の S1): `Dimension`(既定 `"2D"`)。2D は要素ごとに 1 つの `line`(棒の母線は線分、点の母線と機器はマーカー、ブランチとリンクは折れ線、変圧器は From 端の近くの 2 つの円の `line` を `sct_plt.EdgeSymbol` に)で、照明・立体なし、正射影、`SortMethod="childorder"`。3D は今までの立体(`draw_graph_network`)。どちらも母線の高さ(`BusHeightMode`)を使い、ブランチの z は経路の弧長で両端の高さを線形に補間します。2D の `set_time` と `BusHeightMode` の変更は作り直さず `ZData` を変えるだけ(`update_heights`)。視点は最初の作成だけ真上で、描き直し(`Dimension`、3D の高さ、`set_position`、`set_data`)では残ります。
- 流れのアニメーション(2026-11-17、notes/graph-diagram-2d.md の S2): 2D では各ブランチとリンクの上を、`FlowMode`(`"P"` 既定、`"Q"`、`"I"`、`"none"`)の流れの向きに三角形の点が動きます。速さは `FlowSpeed`·d0·|q|/q_max(q_max は全標本の最大)、間隔は 0.25·d0 で一定、点は経路の z に沿います。`FlowAnimation`(既定 true)のとき、見える 2D の figure(`-batch` でない)でだけ timer(Tag `GUILDA:GraphNetDiagram:Flow`、0.04 s ごと)が動き、figure を閉じる・`cla`・`delete(G)`・3D・`"none"` で止めて消します。timer と軸のリスナーは図を `matlab.lang.WeakReference` で持ちます。テストは隠し `step_flow(r_dt)` で決まった時間だけ進めます(F60)。`BranchDirection`/`LinkDirection` は流れの符号で、3D の円錐も同じ向きです。
- クリック: 母線・機器・ブランチ・リンクの立体(筒の子や矢印の円錐を含む)、2D では各要素の `line` の `ButtonDownFcn`。データカーソルモードではクリックがデータチップになるので、データチップの関数(`customhover`)からも `click_element` を呼びます。リンクの `UserData` の `Type` は `"Link"`(以前は `"Component"`)。コールバック(`ButtonDownFcn`、データチップ)は図を `matlab.lang.WeakReference` で持ち、`UserData` には `Type` と `Index` だけを入れます(2026-11-17。以前は図を捕まえた関数ハンドルと、矢印のグループの `UserData` の円錐のハンドルがあり、IEEE68 の図を `savefig`・Live Editor の出力で保存すると `MATLAB:loadsave:saveRecursionLimit` の警告が出ていた。円錐は `Tag` の `"From"`/`"To"` で区別する)。
- 選択: 母線と機器に輪、ブランチとリンクに太い線。立体の少し上に描きます。機器のタグはそのリンクも選びます。ブランチとリンクの線は、描いた管と同じ経路(端と中間点 `MidXaxis`/`MidYaxis`)を通ります(2026-11-16 修正。以前は端の母線の間の直線で、IEEE14 の EL001 のように折れた枝から外れていた。折れ点は今はブランチの `Path`)。`draw_graph_network` が管の経路を `sct_plt.EdgePath`/`CompPath` に持ち、`apply_selection` はそれを `1.5*NodeRadius` だけ上げて描きます。 2D(2026-11-17)では記号と同じ高さに置き、子の順の最初(下)に描きます: 輪は大きさ + 8 pt、線は幅 + 5 pt、棒の母線は両端に 0.1·d0 長く幅 + 6 pt の線分。
- 題と色の棒(2026-11-16 追加、OPF の調整役の依頼をユーザーが承認): `TitleFormat`(既定 `"t = %.2f s"`)は、標本が 2 つ以上のとき `set_time` ごとに `sprintf(TitleFormat, t)` を題にします。OPF の反復番号のように時刻以外を出すときは書式を変え、`""` にすると題を書かないので、`title(G.ax, …)` で付けた題が残ります。`ColorbarLabel`(既定 `""`)は色の棒のラベルで、設定すると色の棒のラベルだけを書き換え(描き直さない)、描き直しのたびにも付け直します。`draw_graph_network` は `cla reset` の前に題の文字を取っておき、戻します(`BusHeightMode` が "none" 以外の `set_time`、形を変えるプロパティ、`set_position` で利用者の題が消えないように)。
- 書き出した画像で題が切れる不具合(2026-11-16 修正): 原因は `axis vis3d` を `daspect([1 1 1])`、`view(0,90)`、`Projection="perspective"` の前に呼んでいたことです。vis3d はその時点の視野角(`CameraViewAngle`)を固定するので、縦横比と投影を変えた後の図には視野角が狭すぎ、描画が軸の枠からはみ出し(IEEE14 で 6.6° に対し本来 8.2°)、枠の上に置かれる題は図の外に出ていました(画面でも `exportgraphics` でも見えない)。軸の範囲や tiledlayout、GraphBase の問題ではありません。縦横比、視点、投影を決めた後に vis3d を呼ぶように順を変えました。図は以前より少し小さくなり、余白に題が入ります。2D・3D(`BusHeightMode`)、figure・uifigure の uipanel のどれでも、題の有無で書き出した画像が変わることを F47 で確かめます(修正前の順では同じ画像になり失敗することを確認済み)。
  - 画像に出る細い線(2026-11-16 修正): `getframe`、`exportapp`、150 dpi の `exportgraphics` の画像に、母線の直方体の角から図の端まで伸びる水平・垂直の細い線が多数出ていました(IEEE14 で 12〜21 本。100 dpi の `exportgraphics` では出ない。-batch では `Visible` が on でも off でも同じ)。格子線ではありません(`XGrid` は off で、`GridSpacing=10` でも同じ)。原因は直方体(`draw_cuboid`、`draw_cuboid_horizontal`、`draw_cuboid_vertical`)の辺(`EdgeColor`)です。二分探索で、辺を消すと線が消え、格子・照明・透視投影・vis3d・Renderer・視点(仰角 89°)は無関係でした。ただの axes に辺のある直方体の patch を 3 つ置き `view(0,90)` にするだけでも、照明・透視なしで同じ線が出るので、MATLAB(R2026a)の描画の不具合で、それを起こしていたのがこちらの辺です。直方体の `EdgeColor` を `"none"` にしました。色を付けると `set_graphics_color` が辺を面と同じ色にしていたので、見た目はほぼ変わりません(縁の暗い線がなくなるだけ)。管・球・円錐はもとから辺なしです。F47 で、3 母線の図の `getframe` の軸の中に半分以上が暗い行・列がないこと、直方体の辺がないことを確かめます(修正前のコードで失敗することを確認済み)。`exportgraphics` に切り替える回避策は不要になりました。
- 大きさと太さ(2026-11-15 追加、OPF の `plot_iteration` で発電機の P をマーカーの大きさ、ブランチの |P| を太さで示すため): `BusMarkerSize`、`ComponentMarkerSize`、`BranchLineWidth`(n×1)。NaN の行(または空)は既定(2026-11-17 から: `MarkerSizeMode` の量を `MarkerSizeRange` に写した大きさ、`BranchWidthMode` の量を `BranchWidthRange` に写した幅)、有限の行はそれを上書きします(RGB の `*Color` と同じ規則)。単位は pt で、範囲には写しません(2026-11-17 から。`BranchWidthScale`、`BranchWidthOffset`、`MarkerSize` は削除)。`reset_style` で NaN に戻ります。`BranchWidthMode` に "user" は加えていません。
  - 描いた立体の点を動かすだけで、図は作り直しません(`create_scene`・`redraw` を呼ばない)。`draw_graph_network` が要素ごとに立体の点を「基準点+径方向+軸方向」に分けて `sct_plt.BusGeom`/`CompGeom`/`EdgeGeom` に持ち、`apply_style` が倍率(設定値÷既定値)で点を置き直します。母線・機器は中心について拡大し、棒(`"_"`、`"|"`)は長さを変えず高さだけ(範囲で決まる大きさと同じ扱い)。ブランチの管は中心線について太くし、変圧器の球は中心について、矢印の円錐は先端について拡大します(円錐の長さは plot_edge と同じく端の区間の半分まで)。倍率が変わらない要素は点を書き直しません。選択の輪は母線・機器の大きさに合わせます。
  - 速さ: IEEE68(母線 68、機器 51、ブランチ 83)で色・大きさ・太さの 6 つのベクトルを全要素について 1 回ずつ代入して中央値 0.082〜0.087 s、同じ内容を set_style(2 回の呼び出し)で 0.099〜0.100 s(負荷平均 10〜12 の計算機。初回は JIT のため約 0.2 s)。F46 は 0.5 s 未満を確かめます。速くするため、`set_graphics_color` がパッチの `CData` を読む処理(1 個 6 ms、色を変えると上書きされるので不要)と葉のオブジェクトへの `allchild` をやめ、`set_style` と `apply_style` は表の行の取り出しを配列にしました。
- 単位と範囲(2026-11-17、notes/graph-diagram-2d.md の S1): 大きさと幅はすべて pt(MATLAB の `MarkerSize`、`LineWidth` と同じ)で、座標の広がりに依存しません。`BranchWidthMode` の量を `BranchWidthRange`(既定 [1 4] pt)へ、`MarkerSizeMode`(`"none"` 既定、`"P"`、`"Q"`、`"S"`)の量を `MarkerSizeRange`(既定 [5 10] pt。2026-11-17 に [4 8] から変更、graph-diagram-2d §12。母線と機器は別々の尺度)へ線形に写します。尺度は状態の**全標本**の最小〜最大で 1 つ(時間応答の全体で 1 pt が表す量が同じ)、`set_data` で新しい状態から計算し直します。モードが `"none"`、値が 1 つだけ、値がない(構成だけ)ときは範囲の中央、NaN の値は最小です。リンクは全部 `LinkWidth`(既定 1 pt)。3D では 1 pt = span/400(span は母線の中心の箱の長い辺)。範囲の検査に外れると `GUILDA:GraphNetDiagram:RangeValue`。
- 状態が NaN(構成だけ)のとき: 高さは 0、色の値は NaN(灰色)、色の棒なし(2026-11-17。色の値が 1 つもなければ色の棒を出さない。以前は意味のない 0〜2 の色の棒が出ていた)、幅と大きさは範囲の中央、矢印は隠れ、ホバーはタグとパラメータ(ブランチの R, X など)だけ。
- 色の棒は軸の右(`eastoutside`。2026-11-17 から。以前の `westoutside` と幅 0.005 では `plot_lmp` の色の棒のラベルが図の左で切れていた)。
- ブランチのない系統(作りかけ)も描けます。uifigure では `Renderer` などの設定を省きます。

- 色・ラベル・軸(2026-11-17、`feature/diagram-look`、notes/graph-diagram-2d.md §12): `ColorLimits` の既定は `[NaN NaN]`(自動。全標本の色の値から、大きさは [0, 最大]、P・Q は ±最大|x|、`"user"` は [最小, 最大])、`ColorbarLabel` の既定 `""` は `ColorMode` の量("|I| [pu]" など)。`LabelMode` の既定は新しい値 `"bus"`(母線のタグだけ)。機器のラベルのテキストは表示するときに作ります。2D では重なるラベルを `resolve_overlap` でずらし、軸の範囲は図の箱 + 3% とラベルです(`fit_axes`)。

### 4.3 `net.plot_diagram` の `State` と `Graph`

- `State="auto"`(既定): 最新の系統は平衡点。初期化前や編集で古くなった系統は構成だけを描き、INFO(`GUILDA:PowerNetwork:DiagramTopology`)を出します(API の規則 5: 害のない既定)。`simulateFcn_check` の唯一のエラーが DiagramStale なので、それを受けて構成に切り替えます(`error(msg())` は identifier を持たないので、エラー全体を受けます)。
- `State="equilibrium"`: 今までどおり `GUILDA:PowerNetwork:DiagramStale`。
- `State="topology"`: 常に構成だけ。スラック母線なし、機器のない母線、ブランチのない母線でも描けます。ColorMode などは強制せず、状態が NaN なので色・高さ・矢印が出ません(後で平衡点に描き直したときに元の設定が生きる)。
- `Graph=G`: 既存の GraphNetDiagram に描き直します。`G.set_data` に新しいスナップショットと状態を渡すので、同じ軸、同じハンドルで、見た目・選択・位置がタグで残ります。古い図形は `cla reset` で消えます(テストは軸の子の数で確認)。ほかの Name-Value は G のプロパティに設定します。G でないもの、軸の消えた G は `GUILDA:PowerNetwork:DiagramGraph`。グラフ側に新しいメソッドはありません。

### 4.4 GraphChart(第 2a 段階、2026-11-16)

基準: ブランチ `feature/graph-chart`(`refactor/design-alignment` の 9d8e964d から分岐)。結果の折れ線・棒グラフの共通のクラスで、まず `ResultODE.plot_trajectory` を移しました(試行)。PF・CPF・LIN の図と ResultOPF の図はこれから移します。

パネル(上から下に並ぶ軸)と系列の図です。系列は 1 つのパネルに描く線の組、棒の組、マーカーの組です。

#### データの約束(コンストラクタと `set_data`)

| フィールド | 内容 |
|---|---|
| `sct_panel`(1×n_panel の構造体配列、省略可) | パネルごと: `s_title`、`s_xlabel`、`s_ylabel`(既定 `""`)、`rv_xlim`、`rv_ylim`(`[]` は自動)、`s_xscale`、`s_yscale`(`"linear"` か `"log"`)、`l_time`(時刻のパネル。既定 false)、`l_grid`(既定 true)、`s_legendLocation`(既定 `"best"`。`"none"` は凡例なし)。省くと 1 パネル |
| `sct_series`(構造体配列) | 系列ごと: `i_panel`(既定 1)、`s_type`(`"line"`(既定)、`"bar"`、`"marker"`)、`rv_x`(n_x)か `sv_x`(n_x の分類名。x = 1..n_x に描き、目盛りのラベルにする。同じパネルの分類はそろえる)、`rm_y`(n_x × n_col。線・マーカーは列ごとに 1 要素、棒は 1 列で行ごとに 1 本)、`sv_tag`(線・マーカーは列ごと、棒は棒ごと。棒の既定は `sv_x`)、`sv_legend`(線・マーカーは列ごと、既定はタグ、`""` は凡例に入れない。棒は系列に 1 つ、既定 `""`)、`rm_color`(1×3 か要素ごとの行、色の名前も可。NaN の行(既定)は軸の色の順)、`r_lineWidth`(既定 1)、`s_lineStyle`(既定 `"-"`)、`s_marker`(線は `"none"`、マーカーは `"o"`)、`r_markerSize`(既定 6) |
| `sct_refline`(構造体配列、省略可) | 基準線(制限値など): `i_panel`、`s_axis`(`"x"` は縦線、`"y"`(既定)は横線)、`r_value`、`s_label`、`rv_color`(既定 [0.85 0.33 0.10])、`s_lineStyle`(既定 `"--"`)。固定の描画で、要素ではない |
| `rv_t`(1×n_t、省略可、既定 0) | `set_time` が選ぶ時刻 |
| `rv_grid`(1×2、省略可、既定 `[n_panel 1]`) | タイルの行と列の数 `[n_row n_col]`。タイルは n_panel 以上。パネルは行の順に入る(2×2 ならパネル 2 は右上、3 は左下)。残りのタイルは空。正の整数でない、タイルが足りないときは `GUILDA:GraphChart:FieldValue`。2026-11-16 追加(OPF の `plot_iteration` の 4 パネルを 1 列にすると対数軸の目盛りがつぶれるため) |
| `s_title`(省略可) | 図全体の題。tiledlayout に書く(Parent が軸のときは、パネルの題がなければその軸に) |

- 構造体配列は MATLAB の規則で全要素が同じフィールドを持つので、使わないフィールドは `[]` にします(空は既定値)。
- 同じパネルの棒の系列は 1 つのグループ化した棒グラフ(`bar(…, "grouped")`)に描くので、x をそろえます(違えば `GUILDA:GraphChart:FieldValue`)。
- `set_data` はパネルの数も格子も変えられません(`GUILDA:GraphChart:PanelCount`、`GUILDA:GraphChart:GridChange`。軸は `build` で決まるため)。`set_data` の `rv_grid` もコンストラクタと同じ規則で、省くと `[n_panel 1]` なので、格子に並べた図では同じ `rv_grid` を渡します。
- 時刻ごとの図の題は `TimeChangedFcn` で書きます(例 `G.TimeChangedFcn = @(G, d) title(G.ax(1).Parent, sprintf("iteration %d", d.Index))`)。GraphChart に `TitleFormat` は加えません(2026-11-16 決定)。
- エラー ID: `GUILDA:GraphChart:MissingField`、`FieldValue`、`FieldSize`、`Panel3D`(3D のパネル、2026-11-22)、`PanelCount`、`GridChange`、`StyleSize`、`StyleValue`。

#### 要素とベクトル

| 種類 | 要素 | set_style | 描き方 |
|---|---|---|---|
| `line` | 線 1 本(列) | Color, Label, LineWidth, LineStyle, Marker, MarkerSize, Visible | line オブジェクト 1 つ |
| `marker` | マーカーの組 1 つ(列) | Color, Label, Marker, MarkerSize, Visible | 線のない line オブジェクト |
| `bar` | 棒 1 本 | Color, Visible | 系列の Bar の `CData` の行(`FaceColor="flat"`)。隠すと高さを NaN にし、場所は残す |

- 要素の順は系列の順、系列の中は列(棒)の順です。`tab_element.Index` は要素の通し番号で、ベクトルのプロパティ `SeriesColor`(n×3、NaN の行は軸の色の順)、`SeriesLabel`(凡例。`""` は入れない)、`SeriesLineWidth`、`SeriesMarker`、`SeriesMarkerSize`、`SeriesLineStyle`、`SeriesVisible` の行です。どのベクトルも全要素の行を持ち、その種類にないオプションの行は使いません(例: 棒の `SeriesLineWidth`)。
- 同じタグを複数の要素が持ってよく(例: `plot_voltage` の |V| と角度の棒がどちらも母線のタグ)、`set_style` と `select` はそのタグの全要素に効きます。
- NaN の色の既定は `create_scene` で軸の `ColorOrder` から決めます: 線・マーカーはパネルの中の順、棒は系列の順(MATLAB のグループ化した棒と同じ)。
- ベクトルの setter は変わった行だけで `apply_style` を呼び、今のグラフィックスオブジェクトのプロパティだけを変えます(作り直さない)。凡例は変わった行のパネルだけを作り直します(表示している線・マーカーのうちラベルが空でないもの、凡例のある棒の系列。`AutoUpdate="off"` なので選択の重ね描きは入らない)。
- 時刻のカーソル: `l_time` のパネルに `xline` を 1 本(`HandleVisibility="off"`、クリックを取らない)。`build` の描画では隠し、最初の `set_time` から表示します(静止画は以前の plot_trajectory と同じ見た目)。`set_data` は表示の有無を保ちます。時刻のパネルがなければ `update_scene` は何もしないので、`set_time` は無視されます(`rv_t` が 1 つなら `i_time` も 1 のまま)。
- クリック: 線・マーカーの `ButtonDownFcn`。棒は系列の Bar の `ButtonDownFcn` で、当たった点(`IntersectionPoint`)に最も近い `XEndPoints` の棒を選びます。
- 選択: 線の下に太い線(`LineWidth + 4`)、マーカーに輪(`MarkerSize + 8` の o)、棒に枠(棒の幅は群の間隔か棒どうしの間隔 × `BarWidth`)。隠した要素は重ね描きしません。
- `cla` は `"reset"` を使いません(tiledlayout の軸の配置を保つため)。代わりに目盛り・範囲・尺度のモードを戻します。

#### plot_* を移す手順

1. 今の描画から、パネル(`nexttile` ごと)と系列(`plot` / `bar` の呼び出しごと)を書き出す。`yline` / `xline` の制限値は `sct_refline`、`semilogy` は `s_yscale="log"`、分類の `categorical` の x は `sv_x` にする。
2. 要素のタグを決める: 母線・ブランチ・機器の線や棒はそのタグ、それ以外(残差、Vmin など)は意味のある名前。凡例の文字が違えば `sv_legend`。
3. 色を指定していた系列(安定・不安定の固有値など)は `rm_color` に初期値を入れる(`reset_style` の既定値になる)。
4. `G = GraphChart(sct, Parent=opt.Parent)` を返し、`arguments (Output)` を `G` にする。`Parent` の既定 `[]`(新しい figure)はそのまま。パネルが複数の図は Parent に軸を受けない(`GUILDA:GraphBase:ParentNeedsContainer`)。
5. 戻り値の `ax` / `fig`(tiledlayout)を使う呼び出しとテストを `G.ax`、`G.tab_element` に直す。図の題(`title(fig, …)`)は `s_title`。
6. 時間軸のある図(`plot_trajectory`、`plot_convergence` の仮想時間など)だけ `l_time=true` にする。

#### 決めたこと

- 種類の名前は `"line"`、`"bar"`、`"marker"`。マーカーの組は線のない line オブジェクトで、要素は列ごと(固有値の安定・不安定を 2 つの要素にできる)。
- 棒の要素は 1 本ずつ(色と表示を棒ごとに変えられる)。棒の Label(目盛りのラベル)と LineWidth は持ちません。グループの棒では 1 つの目盛りを複数の棒が共有するためです。
- 基準線は要素にしません(見た目の変更の要望が出たら、タグ付きの線の系列で描けます)。
- 図全体の題は `s_title`、パネルの題は `sct_panel.s_title`。`plot_trajectory` は 1 パネルなので、以前と同じく軸の題に書きます。
- 新しい公開のメンバーは `GraphChart`、そのコンストラクタ `GraphChart(sct_data, Parent=)` と 7 つのベクトルのプロパティだけです(格子はデータのフィールド `rv_grid` で、プロパティではない)。データは保護の `sct_data` で、外からは読めません。
- `ResultODE.plot_trajectory(Quantity=, Bus=, Parent=)` は G を返します。オプションと内容(線幅 1.2、凡例 `Interpreter="none"`、題 "Time response"(停止の理由付き)、軸のラベル)は同じです。空の結果(時刻のない ResultODE)もデータのない線として描けます。

#### 確認したこと(R2026a)

- `uigridlayout` を Parent にすると、MATLAB が「GridLayout は TiledChartLayout をサポートしていません」の警告を出します(GraphBase の make_axes の動作で、GraphChart 特有ではない)。F48 は uitab と uipanel で確かめ、uigridlayout は試していません。

#### ResultPF の図(第 2a-2 段階、2026-11-16)

基準: ブランチ `feature/graph-chart-pf`(`refactor/design-alignment` の baeb9985 から分岐)。`plot_voltage`、`plot_branch`、`plot_convergence` は `GraphChart` の `G` を返します(以前は tiledlayout か軸)。オプションと描く内容は同じです。

| メソッド | パネル | 要素のタグ | 基準線 |
|---|---|---|---|
| `plot_voltage` | \|V\|、角度(`Quantity` で 1 つか 2 つ)。全体の題は `s_title` | 棒は母線のタグ(\|V\| と角度の棒で同じタグ)。制約の線(種類 `"line"`)は `"Vmin"`・`"Vmax"` | なし |
| `plot_branch` | 1 つ(題 "Branch flows (…)") | 棒はブランチのタグ | `"loading"` の 1(ラベル `S_{max}`) |
| `plot_convergence` | 残差(対数軸)、`Bus` があれば \|V\| | 残差の線は `"Residual"`、\|V\| の線は母線のタグ | `Tolerance` |

- `plot_voltage` の Vmin・Vmax は母線ごとの値なので(母線で違ってよい)、`sct_refline`(1 つの値の横線)ではなく、分類の x の線の系列(破線、マーカー `"_"`、凡例なし)にしました。以前の描画と同じで、`set_style("Vmax", …)` で変えられます。
- `plot_convergence` は `Solver="dynamic"` のときだけパネルを時刻のパネル(`rv_t` は `rv_step`)にします(手順 6)。凡例は以前と同じく |V| のパネルだけです。
- 以前のタグ(`"Branch"`、`"Limit"`、`"Tolerance"`、`"V"`)はなくなりました。基準線は GraphChart の `Tag="RefLine"` です。
- 使わなくなった局所関数 `draw_limits`(plot_voltage)と、1 か所でしか呼ばない `branch_smax`(plot_branch)はメソッドに入れました。
- **uigridlayout の修正(`make_axes`):** GridLayout は tiledlayout を子に持てず、MATLAB が `MATLAB:HandleGraphics:UnsupportedComponentUsePanel` を出していました。uigridlayout のときは、次の空いたセルに枠のない `uipanel` を置き、その中に tiledlayout を作ります。セルを選ぶのは `G.ax(1).Parent.Parent.Layout`(以前は `G.ax(1).Parent.Layout`)。§3.2 の uigridlayout の項目と §4.4「確認したこと」の警告はこの修正で古くなりました。F47(plot_diagram)と F48(1 パネルと 2 パネルの GraphChart)で警告が出ないことを `lastwarn` で確かめます。
- GraphChart と GraphBase の変更は `make_axes` だけです。

#### CPF と LIN の図(第 2a-2 段階、`feature/graph-chart-cpf-lin`、2026-11-16)

§4.4 の手順で 2 つの図を移しました。オプションと描く内容は同じで、戻り値だけが `G`(GraphChart)になります。GraphChart と GraphBase は変えていません。

| メソッド | パネル | 要素(タグ) | 固定の描画(`sct_refline`) |
|---|---|---|---|
| `ResultCPF.plot_pvcurve(Bus=, Parent=)` | 1 つ(題 "PV curve"(ノーズに達しなければ " - nose not reached")、x `\lambda`、y `\|V\| [pu]`、凡例 `southwest`) | 線: 母線ごとに 1 本、タグは母線のタグ(線幅 1.2) | ノーズの縦線 `λ_max = …`(`"--"`、色 [0.15 0.15 0.15]。λ_max が NaN のときはなし) |
| `ResultLIN.plot_eigenvalue(Type=, Tolerance=, Parent=)` | 1 つ(題は従来どおり、x "Real"、y "Imag"、凡例なし) | マーカーの組 2 つ: `"stable"`(青 [0 0.447 0.741])と `"unstable"`(赤 [0.85 0.1 0.1])。マーカーは `x` | 虚軸の縦線(`":"`、色 [0.15 0.15 0.15]) |

- 固有値のタグは安定・不安定の 2 つにしました(§4.4 の決めたことにある使い方)。モードや機器ごとの組は、固有値と機器の対応(参加率)が今の結果にないので見送りました。不安定な固有値がなくても `"unstable"` の要素はあり(点のない線)、タグの組は常に同じです。
- 色は `rm_color` に入れたので、`reset_style` で従来の青・赤に戻ります。
- 凡例は GraphChart の規則で `Interpreter="none"` になります(以前の plot_pvcurve は tex)。母線のタグに `_` があっても添字になりません。
- 複素平面の縦横比(`axis equal`)は以前も使っていなかったので加えていません。点ごとのデータチップも以前と同じく MATLAB の標準のままです。
- 呼び出しとテストを `G.ax`、`G.tab_element`、`G.sct_plt` に直しました(F5 の Plot and Export、F7 の Linearization result Plot と Plot draws the algorithm of the options)。

#### 3D のパネル(`feature/chart-3d`、2026-11-22)

`ResultODE.plot_pqv` と `ResultCPF.plot_pqv`(母線ごとに x = P、y = Q、z = |V| の線 1 本、標本でほかの図とリンクしてマーカーのカーソル)のために、データの構造体にフィールドを加えました。公開のメンバーは増やしていません。

| フィールド | 内容 |
|---|---|
| パネルの `l_3d`(既定 false) | 3D のパネル。`view(3)` に描き、箱と格子は 2D のパネルと同じ |
| パネルの `s_zlabel`(既定 `""`)、`rv_zlim`(既定 `[]` は自動) | z の軸ラベルと範囲。自動の範囲は z も含む |
| 系列の `rm_z`(既定 `[]`) | `rm_y` と同じ大きさの z。線・マーカーの組の `ZData` になる |

- 3D のパネルに置けるのは `rm_z` のある線とマーカーの組だけです。棒、`rm_z` のない系列、基準線(`xline`・`yline` は 2D の表示向けのため)は `GUILDA:GraphChart:Panel3D`。2D のパネルの `rm_z` も同じ ID です。`rm_z` の大きさの誤りは `FieldSize`、`rv_zlim` の誤りは `FieldValue`。
- **回転:** 3D の軸の既定の操作(ドラッグで回転、ホイールで拡大)と、軸のツールバーの回転ボタンを使います。`rotate3d` のモードは常時オンにしません(モード中は線の `ButtonDownFcn` が呼ばれず `ElementClicked` が出ないため)。`create_scene` は軸の向きが `[0 90]`(2D の既定)のときだけ `view(3)` にするので、ユーザーが回した向きは `set_data` の後も残ります。2D のパネルは毎回 `view(2)`。
- **時刻のカーソル:** 縦線のカーソルは 3D では意味がないので、`l_3d` かつ `l_time` のパネルでは `s_cursor` の既定を `"marker"` にし、`"line"` を明示すると `Panel3D` の誤りにしました(省いたときに誤りにすると呼ぶ側の手間が増えるため、明示の `"line"` だけを止める)。マーカーは標本 k で `(rv_x(k), rm_y(k, 列), rm_z(k, 列))`。
- `iv_sample`、凡例、色の順、`set_style`、選択の重ね描き(`ZData` も写す)、`link`、`set_time` は 2D と同じです。`has_playback` は変えていません(時刻のパネルなら再生バーが付く)。データチップは MATLAB の標準(X、Y、Z が出る)のままです。
- テストは F48 に 6 節(ZData とラベル、範囲、マーカーのカーソルと 2D の図とのリンク、`iv_sample`、誤り、クリック)。

### 4.5 GraphNetMap(第 2b 段階、`ResultPF.plot_network`)

基準: ブランチ `feature/graph-netmap`(`refactor/design-alignment` の 9d8e964d から分岐)、2026-11-16。§1 の「未実装」と §3.1 の見通しの記述は、GraphChart の節と合流させやすいようにこの節では書き換えず、ここに実装を記録します。

潮流の軽い 2D の地図です。MATLAB の graph plot(`GraphPlot`)1 つで描き、`G.sct_plt.Graph` がそのハンドルです。単線結線図を描く `GraphNetDiagram`(2D が既定、`Dimension="3D"` で立体)とは別のクラスのままにしました(図の作り方、要素の種類、見た目の持ち方がまったく違うため)。`res.plot_network(Parent=, Color=, Arrow=)` は今までの `h` ではなく `G` を返し、描く図は同じです。

データ(`GraphNetMap(sct_data, Parent=, …)` と `set_data` で同じ契約):

| フィールド | 内容 |
|---|---|
| `sv_bus`(n_bus×1) | 母線のタグ |
| `rm_xy`(n_bus×2) | 母線の中心。NaN の行は、前のデータで描いた同じタグの位置を引き継ぎ、それでもない母線は `tools.layout_place_buses` で隣の近くに置く(座標のある母線は動かない。全母線に座標がないときだけ `"force"`。2026-11-16 から。以前は 1 つでも NaN があると全母線を `"force"`) |
| `rv_length`(n_bus×1、省略可) | 配置のための棒の長さ(水平の棒は正、縦は負、点は NaN)。`plot_network` が渡す |
| `c_path`(n_branch×1 の cell、省略可) | 配置のための各ブランチの折れ点(m×2)。`plot_network` が渡す |
| `cv_V`(n_bus×1) [pu] | 母線電圧のフェーザ |
| `sv_branch`(n_branch×1) | ブランチのタグ |
| `im_end`(n_branch×2) | 各ブランチの from・to 母線の `sv_bus` の行 |
| `rm_P`、`rm_Q`(n_branch×2) [pu] | from・to 端からブランチに入る P、Q |
| `s_color` | `"V"`(\|V\|)か `"angle"`(位相 [deg])。節点の色 |
| `s_arrow` | `"P"`、`"Q"`(その流れの矢印)か `"none"`(矢印なし、幅は `BranchWidthRange` の中央) |

`Color` と `Arrow` はプロパティではなくデータに入れました(図の形、つまり有向グラフか無向グラフか、が変わるので、変えるときは `set_data` で描き直す)。

| 種類 | タグ | set_style | ベクトル(データの順) |
|---|---|---|---|
| `bus` | 母線のタグ | Color, Label, MarkerSize, Marker | `BusColor`(n×3、NaN の行は電圧の色)、`BusLabel`(既定はタグ)、`BusMarkerSize`(既定 6。2026-11-17 に 7 から変更)、`BusMarker`(既定 `"o"`) |
| `branch` | ブランチのタグ | Color, LineWidth, LineStyle | `BranchColor`(n×3、NaN の行は graph plot の既定の辺の色)、`BranchLineWidth`(pt。NaN の行は流れの幅: 両端の大きい方の |P|(|Q|)の最小〜最大を `BranchWidthRange`(既定 [1 4] pt、2026-11-17 追加)に写す)、`BranchLineStyle`(既定 `"-"`) |

- 見た目の変更は `GraphPlot` の `NodeColor`、`NodeLabel`、`MarkerSize`、`Marker`、`EdgeColor`、`LineWidth`、`LineStyle` を代入するだけで、描き直しません(同じハンドルのまま。F49 で確認)。graph plot のこれらのプロパティは節点・辺ごとの配列を 1 回で代入するので、変わった要素の種類ごとに 1 回代入します。
- `BusColor` に NaN でない行があると `NodeColor` を n×3 の RGB にし、NaN の行には電圧の値のカラーマップの色(軸と同じ尺度の計算)を入れます。全行が NaN なら `"flat"` に戻します。この計算が軸の尺度と一致するように、色の範囲(`clim`)は描くときに電圧の値の範囲で固定します。
- graph plot の辺は端点の順に並び替わるので、各辺のブランチを `sct_plt.EdgeBranch` に持ち、ベクトル(ブランチの順)を辺の順に並べて代入します。`h.UserData` は従来どおり辺ごとのブランチのタグです。
- `ColorbarLabel`(既定 `""`)は `GraphNetDiagram` と同じ名前です。`""` は `"|V| [pu]"` か `"\angleV [deg]"`(`s_color` による)で、設定すると色の棒のラベルだけを書き換えます。題は従来の `"Power flow (color: …, arrows: …)"` のままで、`TitleFormat` は加えていません(1 標本なので)。
- `set_time`: 潮流は 1 標本(`rv_t = 0`)なので、`update_scene` は何もしません。`animate` と `export_video` は `GUILDA:GraphBase:OneSample` で止まります(1 標本の GraphNetDiagram と同じ)。
- `set_position(sr_tag, rm_xy)` は母線だけを図の中で動かします(規則 6)。`GraphPlot` の `XData`/`YData` を書き換えるだけで、ブランチは端に付いて動きます。位置はデータの写し(非公開)にあり、スナップショットや系統には書きません。ブランチのタグは `GUILDA:GraphNetMap:PositionKind`、行の数の誤りは `PositionSize`。
- `Parent`: 1 パネルの図なので、容器(中に tiledlayout)、axes、uiaxes のどれでも描けます。
- クリック(当たり判定): graph plot には節点・辺ごとの `ButtonDownFcn` がなく、graph plot 全体に 1 つだけです。そこで graph plot の `ButtonDownFcn` が受け取るクリックの点(`IntersectionPoint`)を、軸の画素の大きさ(`getpixelposition` と `xlim`/`ylim`)で画素の座標に直し、(1) 中心からの距離が `BusMarkerSize/2 + 4` 画素以内の母線のうち最も近いもの、(2) なければ、両端の母線を結ぶ線分までの距離が `幅/2 + 4` 画素以内のブランチのうち最も近いもの、を `click_element` に渡します。どちらでもなければ何もしません。軸自体の `ButtonDownFcn` は使いません(利用者の axes を渡されたときに上書きしないため)。graph plot の外(空白)のクリックはそもそも graph plot に届かないので、判定は不要です。
  - 平行なブランチ(多重グラフ)は graph plot では曲線で描かれますが、判定と選択の線は両端の直線で行います。同じ両端の平行なブランチの間では、先の行のブランチが選ばれます。
- 選択: 母線に輪(`2.2 × BusMarkerSize` の o)、ブランチに両端を結ぶ太い線(幅 + 5)。`PickableParts="none"`。`set_position` と大きさ・幅の変更の後に描き直します。
- エラー ID: `GUILDA:GraphNetMap:MissingField`、`DataSize`、`DataValue`、`PositionSize`、`PositionKind`、`RangeValue`(`SystemTools/GUILDA/en/GraphNetMap.xml`)。graph plot の `ButtonDownFcn` は地図を弱い参照で持ちます(2026-11-17。保存した図が地図を保存しない)。
- 非公開のメンバー: `sct_data`(データと描いた位置、流れの幅)、`click_at`(当たり判定)、`colorbar_text`(ラベル)。公開で加えたのは指示の範囲(ベクトル 7 つと `ColorbarLabel`)だけです。

## 5. 決定事項

1. **すべての `plot_*` は図のオブジェクトを返す。** 第 1 段階では `plot_spring_model` と `plot_diagram`。結果の折れ線(第 2a)と地図(第 2b)も GraphBase の上に作ります。
2. **タグのメソッドとベクトルのプロパティの両方。** `set_style` はベクトルに書き込むだけなので、2 つの書き方は同期します。ベクトルの setter が変わった行を見つけて `apply_style` を呼ぶので、どちらの書き方でも変わった要素だけを描き直します。
3. **GraphNetDiagram の RGB の色(`BusColor` など)を加えた。** 理由: 既存の `*ColorData` はカラーマップの値で RGB を表せず、さらに `ColorMode` が "user" 以外では `BranchColorData` と `LinkColorData` を標本ごとに書き直すので、set_style の色がアニメーションで消えてしまう。NaN の行を「指定なし」とする RGB のベクトルを 4 つ加え、指定があれば色の値と ColorMode より優先します(NaN に戻すと色の値の色、色の値もなければ描いたときの色)。`*ColorData` は名前も意味もそのままです。
4. **`LabelMode` に `"user"` を加えた。** `"tag"` と `"value"` はラベルを標本ごとに(プロパティを変えたときも)書き直すので、set_style(Label=) は次の描き直しまでしか残りません。ColorMode の "user" と同じく、"user" ではラベルを書き直しません。set_style はモードを自動では変えません(タグとベクトルの書き方を同じにするため)。
5. **GraphNetDiagram の set_style のオプションは Color、Label と、大きさ(MarkerSize、LineWidth)。** 当初は Color と Label だけでしたが、2026-11-15 に OPF の調整役の依頼(ユーザー承認)で要素ごとの `BusMarkerSize`、`ComponentMarkerSize`、`BranchLineWidth` を加えました(4.2)。マーカーの形(`graph` の `Marker`)と表示・非表示は今もベクトルを持ちません。違反の強調は `select(tags)` と `SelectionColor` で行い、位置の取得や Highlight のオプションは加えていません。
6. **名前。** `Graph*` に統一(GraphSpring の命名の例外を、図のクラス全体の規則にした)。`DrawerNetDiagram` → `GraphNetDiagram`。互換の別名はありません。
7. **`set_position` は自由配置の図だけ。** GraphSpring の位置は電圧フェーザそのもの(物理的な意味がある)なので設定できず、エラーでそう伝えます。
8. **link。** 対称で、推移的にたどります。描画は内部のループで行い、`set_time` を再帰的に呼ばないので環でも止まります。削除された図(`isvalid` が偽)は読むときに捨て、軸を消した図はとばします。プロパティを変えたときの描き直しはリンクした図を動かしません(`update_scene` を直接呼ぶ)。
9. **Parent の誤りは 1 つの ID。** `GUILDA:GraphSpringBase:ParentNotAxes` と `GUILDA:DrawerNetDiagram:ParentNotAxes` は `GUILDA:GraphBase:ParentType` 1 つになりました(容器も受け付けるので名前も変えた)。
10. **閉じた図の `set_time`。** 以前の DrawerNetDiagram は新しい figure を開いていましたが、どの図も `GUILDA:GraphBase:NoAxes` で止まるようにそろえました。
11. **選択は見た目と別の層。** 選択を set_style で表すと、外したときに利用者の見た目を戻せないので、重ね描きにしました。重ね描きは毎回作り直します(位置は今のグラフィックスから読む)。
12. **クリックの通知はイベントとコールバックの両方。** GUI は `ElementClickedFcn` 1 つで足り、複数の聞き手は `addlistener` を使えます。
13. **net.plot_diagram の既定 State="auto"。** GUI で作りかけの系統を描くため。従来のエラーは `State="equilibrium"` で得られます。

## 6. 未決事項

- GraphNetDiagram の要素ごとの表示・非表示やマーカー(Visible、Marker の set_style)。
- `export_video(Capture="axes")` で複数のパネルを録画する方法(今は最初のパネル)。
- 第 2a 段階で、結果の `plot_*`(`plot_voltage` など)の戻り値を GraphChart にするときの api-design.html の更新。
