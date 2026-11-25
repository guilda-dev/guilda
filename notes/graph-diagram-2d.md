# ネットワーク図の 2D 化、流れのアニメーション、範囲の正規化、図の操作パネル

基準: ブランチ `docs/graph-diagram-2d-spec`(`refactor/design-alignment` の f8c20aaf から分岐)、2026-11-16。仕様です。**S1〜S5 はすべて実装し、`refactor/design-alignment` にマージ済みです(2026-11-17)。** 状況とマージのコミットは §8.3、実装の記録は §11 にあります。2026-11-16 にユーザーが §9 の Q1〜Q17 を決めました(Q9 と Q10 は提案と違う決定で、本文に反映済み)。

前提の文書: [graph-base.md](graph-base.md)(GraphBase の約束と API)、[graph-layout.md](graph-layout.md)(配置データの新しい列と描き方の規則 §4.6)。この文書の座標・形・接続位置の規則は graph-layout §4 のものを使い、ここでは繰り返しません。

## 0. ユーザーの要望と決定(2026-11-16)

要望:

- `plot_diagram` の既定の節点が大きすぎる。
- 細すぎて見えないブランチがある。
- 幅と大きさに範囲を決めて、その範囲に正規化してほしい。
- `plot_network` と `plot_diagram` は同じ情報を 2.5D と 3D で描いているように見える。重い 3D より、潮流を動き(アニメーション)で見せるほうがよい。
- 描いた後に、表示する内容を対話的に変えられるとよい。

決定:

1. **`plot_diagram` の既定を 2D にする。** 線と記号で描き、照明・直方体・管は使わない。各ブランチとリンクの上を、潮流の向きに点(または短い線)が動く**流れのアニメーション**を付ける。速さ(と、場合により密度)は |P| などの量に比例させる。今の 3D(`BusHeightMode` を含む)はオプションとして残す。(その後 Q9 で、高さ `BusHeightMode` は 2D でも効くことになりました。3D は立体の描画のオプションです。)役割は、`plot_network`(GraphNetMap)が軽い 2D の地図(graph plot、自動配置)、`plot_diagram`(GraphNetDiagram)が標準の単線結線図(棒、折れ点、接続位置)の再現。
2. **範囲の正規化。** 新しく `BranchWidthRange = [min max]` と `MarkerSizeRange = [min max]` を設け、選んだ量のデータの最小〜最大を範囲に線形に写す。`BranchWidthScale` と `BranchWidthOffset` は削除する。既定の節点を小さくする。
3. **図ごとの操作パネルを GraphBase に組み込む。** 各サブクラスが調整できるプロパティ(色の量、幅の量、ラベル、アニメーションの再生・停止、標本の時刻のスライダーなど)を宣言し、パネルはその宣言から作る。GUI アプリに埋め込める。操作はプロパティを設定するだけなので、タグ・ベクトルの API とパネルは常に一致する。

## 1. 今の描画で分かったこと(コードを読んだ結果)

`_auxiliary/@GraphNetDiagram/draw_graph_network.m` と `private/plot_node.m`、`plot_edge.m`、`draw_cuboid*.m` から。数値は同梱の CSV から計算しました(MATLAB での描画の確認はしていません)。

- **節点の大きさは座標の広がりに比例します。** `node_radius = 0.016 * span * (MarkerSize/10)`(span は母線の座標の x・y の広い方の幅)。既定の `MarkerSize = 10` で、四角の母線は一辺 `1.6 * node_radius` ≒ span の 2.6%、機器は `0.75` 倍の球です。画面の大きさに関係なく図に対する割合で決まるので、母線の多い系統ほど節点どうしが混み合います。
- **ブランチの管の太さは座標の絶対値です。** 半径は `0.001 * (BranchWidthOffset + BranchWidthScale * 値)` で、span を掛けていません。IEEE14(span ≒ 1)では見えますが、IEEE68 の座標は x −6〜8、y −1〜9(span ≒ 14)なので、最も細い管(半径 ≒ 0.0015)は図の幅の約 0.01% で、ほとんど見えません。**「細すぎて見えないブランチ」の主な原因はこれ**と考えます(推測。描画して確かめていない)。
- **既定の `BranchWidthMode = "Ysvd"` の値は偏っています。** 直列アドミタンスの大きさ |1/(R+jX)|(Ysvd と同じ桁)は IEEE68 で最小 3.1、中央値 66、90% 点 221、最大 905(変圧器の X が小さい)です。今の倍率 `1 + 0.15 * 値` は 1.5〜137 倍に広がり、太い線が図を覆います。最小〜最大を [1 4] pt に線形に写すと、87% のブランチが 1.5 pt 未満に集まります(IEEE14 は 1.8〜22.6 で 55%)。§4.2 と §9 の Q4 で扱います。
- 母線の棒(`"_"`)は長さ `Length`、奥行き 0.005(絶対値)、高さ `node_radius` の直方体です。
- 矢印は管の両端の円錐で、向きは `BranchDirection`(端の電圧の位相差の符号)、機器のリンクは `LinkDirection`(機器の P の符号)です。
- `update_scene` は `BusHeightMode` が `"none"` 以外だと標本ごとに図全体を作り直します(`draw_graph_network` を呼ぶ)。
- `GraphSpring3D` には `View`(1×2、カメラの方位角と仰角 [deg])というプロパティがすでにあります。§2.4 の名前に関係します。
- `ResultOPF.plot_iteration` は `G_net.MarkerSize` を使って機器の大きさを計算し(`rm_size = G_net.MarkerSize * (0.5 + P/max P)`)、`BranchLineWidth` に 1〜5 を入れ、図の下に自前の再生ボタンとスライダー(`uicontrol`)を置いています。

## 2. 描画

### 2.1 2D の基本

- **2D は「3D 空間に置いた平らな記号」です**(Q9 の決定)。記号は線とマーカーだけで、立体・照明は使いませんが、各点は z を持ちます。z は母線の高さ(`BusHeightMode`。今の 3D と同じ値で、`"none"` なら 0)です。`Dimension="3D"` は立体の描画を指します。
- 軸: 既定の視点は真上(`view(ax, 0, 90)`)、`DataAspectRatio = [1 1 1]`、正射影、照明なし、x・y・z の軸の線と目盛りは今と同じく隠す(`XColor = "none"` など)。利用者は軸のツールバーの回転(`rotate3d`)で視点を回せます。
- 重ね順は奥行きではなく作る順にします(`ax.SortMethod = "childorder"`)。同じ平面に重なる線・点・選択の重ね描きが奥行きの判定でちらつかないようにするためです。回転したときに遠くの記号が手前に描かれることがありますが、平らな記号の図では許容します(実装時に IEEE14 を回して見え方を確かめる)。
- 視点は描き直し(`create_scene`、`Dimension` の切り替え、`BusHeightMode` の変更)の前に `[az, el] = view(ax)` で取っておき、戻します。真上に戻すのは最初の `build` だけです。
- **大きさと幅の単位はポイント(pt)です。** MATLAB の `LineWidth` と `MarkerSize` と同じ単位で、画面の上の大きさが座標の広がりに依存しません。IEEE14 でも IEEE68 でも、同じ値なら同じ太さに見えます。§1 の 2 つの問題(節点が図に比例して大きい、管が座標の絶対値で細い)はこれで両方なくなります。
- 長さ(棒の `Length`、折れ点、機器の位置)はこれまでどおり座標の単位です。
- **基準の長さ d0:** 2D の記号のうち座標の単位で描くもの(変圧器の記号、流れの点、ラベルのずれ)は、図の基準の長さ d0 に比例させます。d0 は全ブランチの経路の長さ(端点と折れ点を結ぶ折れ線の長さ)の中央値です。ブランチがなければ母線の外接箱の長い辺の 0.1 倍、それも 0 なら 0.1 にします(graph-layout §4.7 の d0 と同じ考え。あちらは母線の中心どうしの距離)。
- グラフィックスオブジェクトは**要素ごとに 1 つ**の `line`(母線、機器、ブランチ、リンク)にします。要素ごとに色・幅・大きさ・`ButtonDownFcn` を持てるからです。IEEE68 で約 260 個(母線 68、機器 51、ブランチ 83、リンク 51、変圧器の記号)で、作るのに 0.2 s 程度の見込みです(§2.6 で計測)。流れの点だけは、種類ごとに 1 つの `patch` にまとめます(§3.3。こまごとに位置を変えるため)。

### 2.2 要素ごとの描き方

| 要素 | 2D の描き方 | 色 | 大きさ・幅 |
|---|---|---|---|
| 母線(`"hbar"`、`"vbar"`) | 中心 `(X, Y)`、長さ `Length` の線分 1 本(`line`、2 点) | `Color` = 母線の色 | `LineWidth` = 母線の大きさ s × 0.5 [pt](既定 s = 6 なら 3 pt) |
| 母線(点の形) | 中心に 1 点のマーカー。`"circle"`、`"square"`、`"^"`、`"v"`、`"<"`、`">"` は MATLAB のマーカーにそのまま渡す。`"none"` は描かない(当たり判定のため `Visible="off"` の点を置く) | `MarkerFaceColor` と `MarkerEdgeColor` = 母線の色 | `MarkerSize` = s [pt] |
| ブランチ | 端点 → `Path` の折れ点 → 端点の折れ線(`line`)。端点は graph-layout §4.6 の規則(棒の上の `FromOffset`/`ToOffset`、点の形は中心) | `Color` | `LineWidth` = w [pt] |
| 変圧器の記号(`Style="transformer"`) | From 端の近くに、少し重なる 2 つの円(白抜き)。円は座標の単位の多角形(48 点の `line`)で、半径 ρ = min(0.06·d0, 0.2·経路の長さ)、中心は経路に沿って From 端から 1.6ρ と 2.8ρ。ブランチの線は円の内側も通したままにする(単線結線図の慣習) | ブランチと同じ色 | 線の幅はブランチの w と同じ |
| 機器 | 母線の中心 + `(DX, DY)` に 1 点のマーカー(形は `Shape`)。棒の形は機器にない | 今と同じ既定の色(円は黄 [0.611 0.466 0.125]、三角は赤 [0.717 0.192 0.172])の塗り。`ComponentColor`、色の値があればそれ | `MarkerSize` = 機器の大きさ s [pt] |
| リンク | 機器 → `Path`(母線の中心からの相対)→ 母線の上の点(`Offset`)の折れ線 | `Color` | `LineWidth` = `LinkWidth`(§4.3) |
| ラベル | 今と同じ `text`(枠と背景つき)。位置は母線の中心から (0, 0.3·d0)、機器は (0.25·d0, 0.25·d0) ずらす | 今と同じ | `LabelFontSize`(既定 5 のまま。§9 の Q8) |
| 流れの点 | §3 | §3.3 | §3.3 |

- **z(高さ)の付け方**(Q9):
  - 母線: 点のマーカーも棒の線分も、その母線の高さ z_bus に置きます。
  - ブランチ: 端点は両端の母線の高さです。`Path` の折れ点の z は、端点から端点まで、x・y の弧長に比例して線形に補間します(今の 3D は折れ点を両端の平均の高さに置いているが、補間のほうが線が滑らかに傾く。3D もこの規則にそろえる)。
  - 機器とリンク: 機器はその母線の高さに置き、リンクの全点も同じ高さです(今の 3D と同じ)。
  - 変圧器の記号: 円は水平面の中の多角形で、z は円の中心の経路上の高さです。
  - ラベル: 記号と同じ z に置きます。
- 色の決め方は今と同じです: 要素ごとの RGB(`BusColor` など)が NaN でなければそれ、そうでなければ色の値(`*ColorData`)のカラーマップの色、どちらもなければ描いたときの既定の色(母線とブランチは濃い灰 [0.2 0.2 0.2])。値が NaN の色は灰色です。
- **静止の矢印は 2D では描きません。** 向きは流れの点(三角形)が示します(§3.3)。アニメーションを止めても点は残るので、静止画でも向きが分かります。`BranchDirection`、`LinkDirection` のプロパティは残し、流れの向きの符号として使います(§3.1)。
- 重ね順(下から): 選択の重ね描き、ブランチ、リンク、変圧器の記号、流れの点、母線、機器、ラベル。
- 当たり判定: 各要素の `line` の `ButtonDownFcn` から `click_element` を呼びます(今と同じ)。流れの点と選択の重ね描きは `PickableParts="none"`。データチップ(`customhover`)は 2D でも今と同じ内容です。

### 2.3 選択の重ね描き(2D)

| 要素 | 重ね描き |
|---|---|
| 棒の母線 | 同じ線分を少し長く(両端に 0.1·d0)、`LineWidth` = 母線の幅 + 6 pt で下に描く |
| 点の母線、機器 | 同じ中心に `"o"` のマーカー(塗りなし、`MarkerSize` = s + 8、`LineWidth` = 2) |
| ブランチ、リンク | 同じ経路の線を `LineWidth` = w + 5 pt で下に描く |

色は `SelectionColor`、`PickableParts="none"` です。機器のタグはそのリンクも選びます(今と同じ)。重ね描きは記号と同じ 3D の点(同じ z)を通り、「下に描く」は作る順で決めます(`SortMethod="childorder"` のため、z をずらさない)。大きさ・幅を変えたとき、`set_position` の後、高さが変わったとき(標本の変更、`BusHeightMode` の変更)に描き直します。

### 2.4 3D への切り替え: `Dimension`

- 新しいプロパティ `Dimension`(`"2D"`(既定)か `"3D"`)。`"3D"` は今の描画(直方体、管、球、円錐、照明、透視投影)です。高さ(`BusHeightMode`)はどちらでも効きます(Q9)。2 つの違いは記号が平らか立体かだけです。
- **名前の理由(Q1):** 指示の例は `View` でしたが、`GraphSpring3D.View` がすでにカメラの角度(1×2 の数値)の意味で使われており、MATLAB の `view` もカメラの意味です。同じ名前で別の意味のプロパティが図のクラスに並ぶのを避けるため `Dimension` にしました。
- **いつでも変えられます。** setter は `create_scene` を呼んで図を作り直し、`update_scene(i_time)` と `apply_selection` を続けます(今の `MarkerSize` などの setter と同じ扱い)。軸、ハンドルの `G`、リンク、コールバックはそのままです。軸のカメラの設定(`view`、`Projection`、`vis3d`)と照明は `create_scene` が毎回決め直します(`cla reset` で消えるので、2D に戻すと残りません)。
- **2 つの見方で共有するもの:** データ(スナップショットと状態)、位置(`set_position` の結果、自動配置)、高さ(`BusHeightMode`)、要素ごとのベクトル(色・ラベル・大きさ・幅)、モード(`ColorMode`、`BranchWidthMode`、`MarkerSizeMode`、`LabelMode`、`FlowMode`)、範囲と全標本の正規化の尺度(§4.1)、選択、表示中の標本、視点(§2.1)、題と色の棒のラベル。
- **共有しないもの:** 流れのアニメーションは 2D だけです(3D では点を描かず、今の円錐の矢印を描く。Q3)。照明と透視投影は 3D だけです。
- **3D の大きさの換算:** 3D でも同じ範囲と同じ値(pt)を使い、座標の長さに直して描きます。1 pt を `u = span / 400` とします(軸の幅が約 400 pt の図で 2D と同じ見かけ)。母線の `node_radius = 0.5 · s · u`、管の半径 = `0.5 · w · u`、リンクの管の半径 = `0.5 · LinkWidth · u`。棒の奥行き(今は絶対値 0.005)も `s · 0.5 · u` にします。これで 3D の管も span に比例し、IEEE68 の細い管の問題もなくなります。今の倍率で大きさを変える仕組み(`BusGeom` などの「基準点+径方向+軸方向」の点、graph-base §4.2)は 3D の中でそのまま使います。

### 2.5 `update_scene` と見た目の変更(2D)

- `update_scene(k)` は、色の値(`ColorMode`)、ラベル(`LabelMode`)、幅と大きさ(`BranchWidthMode`、`MarkerSizeMode` が状態の量のとき)、高さ(`BusHeightMode` が `"none"` 以外のとき)、流れ(§3)を計算し直し、要素の `line` のプロパティ(`Color`、`LineWidth`、`MarkerSize`、高さが変わる要素の `ZData`、ラベルの `Position`)を代入するだけです。2D では作り直しません(今の 3D は高さが変わるたびに図全体を作り直している。§1)。高さが変わると、流れの経路の累積の長さ(§3.3)と選択の重ね描きも作り直します。
- ベクトルの setter(`BusColor`、`BranchLineWidth` など)は今と同じく変わった行だけで `apply_style` を呼び、2D では `Color`、`LineWidth`、`MarkerSize` を代入します。
- `BranchWidthMode`、`MarkerSizeMode`、範囲の setter は 2D では作り直さず、全要素の幅・大きさを代入し直します(3D は今と同じく作り直す)。

### 2.6 速さの目標

IEEE68(母線 68、機器 51、ブランチ 83)、R2026a、初回の JIT を除いた中央値で:

| 操作 | 2D の目標 | 3D |
|---|---|---|
| `net.plot_diagram()` の作成(`build`) | 0.5 s 以下 | 今の値を計測して記録(目標なし) |
| `Dimension` の切り替え | 0.5 s 以下(切り替え先の作成と同じ) | 同左 |
| 色・大きさ・幅の 6 つのベクトルを全要素に代入、または同じ内容の `set_style` | **0.1 s 以下**(OPF の要件と同じ) | 今の 0.08〜0.10 s を保つ |
| `set_time`(1 標本、色・ラベル・幅・流れの計算を含む。`BusHeightMode="V"` でも) | 0.1 s 以下 | 今の値(`BusHeightMode="none"`) |
| 流れのアニメーションの 1 こまの計算(§3.3) | 5 ms 以下(`drawnow` を除く) | なし |

F59 で 2D の値を確かめます(負荷のある計算機でも通るよう、テストの上限は目標の 5 倍にし、実測値を notes に記録します。F46 の 0.5 s と同じ扱い)。

## 3. 流れのアニメーション

### 3.1 量、向き、速さ

- 新しいプロパティ `FlowMode`(`"P"`(既定)、`"Q"`、`"I"`、`"none"`)。`ColorMode` とは別にします(`ColorMode` には向きのない `"Loss"`、`"user"` があるため。§9 の Q2)。
- 各ブランチの流れの値 q(符号つき、From → To が正):
  - `"P"`: q = (P_from − P_to)/2。P_from、P_to は各端からブランチに入る有効電力(`rm_Pbranch`)。損失があっても両端の平均で向きと大きさを決めます。
  - `"Q"`: q = (Q_from − Q_to)/2(`rm_Qbranch`)。
  - `"I"`: 大きさは max(|I_from|, |I_to|)、向きは P の向き(電流のフェーザ自体に「向き」はないので、有効電力の向きで決める)。P が 0 なら Q の向き。
- 各リンクの値(機器 → 母線が正): `"P"` は機器の注入 P(`rv_Pcomp`)、`"Q"` は Q、`"I"` は |I| で向きは P。
- 速さ: v_i = `FlowSpeed` · d0 · |q_i| / q_max [座標/s]。q_max は**状態の全標本**のブランチとリンクの |q| の最大です(幅・大きさと同じく全標本で 1 つの尺度。§4.1、Q10)。`load_data`(と `set_data`)で全標本の流れを 1 回まとめて計算します(疎行列の積 1 回)。
- `FlowSpeed`(既定 1): 最も大きい流れの点が 1 秒に進む長さを d0 の倍数で表します。
- |q_i| < 1e-3 · q_max、または q_i が NaN(構成だけの図、解列した機器)の要素は点を描きません。q_max が 0 か NaN なら全部描きません。
- **密度(点の間隔)は一定**にします: 間隔 Δ = 0.25 · d0。量は速さだけで示します(密度も量に比例させると、小さい流れの線に点がほとんどなくなり、向きが読めなくなるため。§9 の Q5)。
- `BranchDirection`、`LinkDirection`(今は位相差と P の符号)は、`FlowMode` の q の符号を入れるように変えます(`"none"` のときは今の規則)。3D の円錐の向きも同じ値を使うので、2 つの見方で向きがそろいます。

### 3.2 こまのループ(timer)

- 新しいプロパティ `FlowAnimation`(logical、既定 true)。true でも、次のすべてを満たすときだけ timer を動かします:
  1. `Dimension == "2D"` で `FlowMode ~= "none"`、
  2. 軸があり、その figure の `Visible` が `"on"`、
  3. `batchStartupOptionUsed` が false(`matlab -batch` ではない)。
- 動かさないときも点は描きます(位相 0 の位置に止まった点)。静止画と書き出した画像で向きが分かるようにするためです。
- timer: `timer(ExecutionMode="fixedSpacing", Period=0.04, BusyMode="drop", Tag="GUILDA:GraphNetDiagram:Flow")`。目標 25 こま/秒です。`TimerFcn` は前のこまからの実時間 dt(`tic`/`toc`、0.1 s で打ち切り)だけ点を進め(§3.3)、`drawnow limitrate` を呼びます。こまの間隔を実時間で測るので、こまが落ちても点の速さは変わりません。
- こまの数(Period)はプロパティにしません(新しいメンバーを増やさないため。§9 の Q6)。
- 始め・止め: `FlowAnimation` の setter が timer を作る・止めて消す。`Dimension`、`FlowMode` の setter と `create_scene` も上の条件で始め・止めを判定します。figure が後から表示された場合(GUI が作ってから見せる)のために、timer は figure の `Visible` を毎こま確かめ、隠れている間は描きません(timer は残す)。隠れた figure で作った図は timer を作らないので、表示した後は `G.FlowAnimation = true` を設定し直すか、パネルの再生を押します(§9 の Q7)。
- `TimerFcn` は図そのものではなく `matlab.lang.WeakReference` で図を持ちます。timer は MATLAB の全体の一覧に残るので、強い参照だと図を消しても timer が図を生かし続けるためです(R2025a 以降で使える。実装時に確かめる)。

### 3.3 点の描き方と 1 こまの計算

- 点は流れの向きを指す二等辺三角形で、長さ 0.06·d0、幅 0.035·d0(座標の単位)。ブランチの点で 1 つ、リンクの点で 1 つの `patch` にまとめ、`Faces`/`Vertices` を一度に代入します(要素ごとの `line` にすると 1 こまに数百の代入が要るため)。
- 色は白で、細い暗い灰色の縁(`EdgeColor` [0.25 0.25 0.25]、0.5 pt)をつけます(2026-11-18 のユーザーの依頼。以前は線の色 × 0.45 でほとんど黒)。暗い線・明るい線・白い背景のどれの上でも見えます。面ごとの要素は patch の `UserData.Index`(ブランチ・リンクの中の行)に入れます(§13)。
- 位相: 要素ごとに φ_i ∈ [0, Δ)。1 こまで φ_i ← mod(φ_i + v_i·dt, Δ)。点の位置は経路の弧長 s = φ_i + kΔ(k = 0, 1, …、s ≤ 経路の長さ)で、q_i < 0 なら To 端から測ります。経路の弧長から座標への変換は、`create_scene` で作った各経路の累積の長さで線形補間します。
- **z に沿う(Q9):** 経路は §2.2 の z を含む 3D の折れ線で、弧長も 3D で測ります(傾いた線の上でも点の速さは線に沿って一定)。点の z は経路上のその位置の z です。三角形は経路の接線 t の向きに長さを取り、幅の向きは水平面の中で t に垂直な向き n = normalize(cross(t, e_z)) です(真上から見て今と同じ形。t がほぼ鉛直なら n = e_x)。点は線と同じ z に置き、`SortMethod="childorder"` で線の上に描きます(z をずらさない)。
- 高さが変わったとき(`set_time` で `BusHeightMode` の量が変わる、`BusHeightMode` を変える)は、経路の累積の長さを計算し直します。位相 φ_i は弧長のまま残すので、点は経路の上で少しずれるだけで飛びません。
- 1 こまの計算は全要素の点の頂点をベクトル化して作ります(IEEE68 で点は約 1500 個の見込み)。目標は 5 ms 以下です(§2.6)。
- `set_time` で標本が変わっても位相はそのまま残し、速さと向きだけを変えます(点が飛ばない)。向きが変わった要素は位相を Δ − φ_i にします(点が同じ場所から逆に動く)。

### 3.4 `set_time`、`animate`、`export_video` との関係

- 時間応答の図(`ResultODE.plot_diagram`)では、流れは**表示している標本**の値に従います。`update_scene(k)` が速さと向きを決め直すので、`set_time`、リンクで動いた図、`animate` のこまのどれでも同じです。
- `animate` は `pause` の間に timer も動くので、標本の間も点は動き続けます。変更はありません。
- `export_video` は、書き出しの間 timer を止め、各こまの前に `step_flow(1/FrameRate)` を呼んで点を進めます。動画の 1 秒で、画面と同じだけ点が進みます。書き出しの後は前の状態に戻します。
- 1 標本の図(潮流、平衡点)でも点は動きます(`animate` は今と同じく `GUILDA:GraphBase:OneSample`)。この使い方が主な目的です。

### 3.5 後片付け

timer は次のどれでも止めて消します:

- `G.FlowAnimation = false`、`Dimension = "3D"`、`FlowMode = "none"`、
- 軸が消えたとき(軸の `ObjectBeingDestroyed` のリスナー。figure を閉じた、`cla`、GUI が `delete(h_parent.Children)` した)、
- 図のオブジェクトが消えたとき(新しいメソッド `delete`(デストラクター)を GraphNetDiagram に置く)、
- `TimerFcn` が、弱い参照の先の図か軸が無効だと分かったとき(自分を止めて消す)。

`create_scene` は、前の timer があれば消してから作り直します。テストは最後に `timerfindall(Tag="GUILDA:GraphNetDiagram:Flow")` が空であることを確かめます。

### 3.6 バッチとテスト

- `matlab -batch`、隠れた figure、テストでは timer を作りません(§3.2 の条件)。テストが timer を待つことはありません。
- 決定的に確かめるため、**隠しメソッド `step_flow(r_dt)`**(`Hidden`)を置きます。実時間を使わず、r_dt 秒だけ点を進めて頂点を代入します。timer の `TimerFcn` と `export_video` もこれを呼びます。テストは位相・点の数・向きを `G.sct_plt.FlowBranch.Vertices` などで確かめます。
- timer そのものの動作(見える figure で動き、閉じると消える)は、画面のある環境で手で確かめる項目として notes に残します(CI では試さない)。

## 4. 範囲の正規化

### 4.1 写し方の式

**尺度は全標本で 1 つです(Q10)。** 量の行列 V(要素 × 標本、n × n_t。NaN を含みうる)の全標本の最小〜最大を範囲 [a b] に写すので、時間応答の全体で「1 pt が表す量」が同じです。

`rv_w = range_map(rv_v, rv_range, rv_lim)`(GraphBase の protected static):

1. 尺度 `rv_lim = [vmin vmax]` は、V の有限の値の集合 F(**全標本**の全要素)の最小と最大です。F が空(全部 NaN、要素なし)なら `[NaN NaN]`。
2. 表示中の標本 k の値 v_i = V(i, k) を写します。尺度が `[NaN NaN]`: 全要素を (a + b)/2。
3. vmax − vmin ≤ 1e-12 · max(|vmin|, |vmax|, 1)(**全部同じ値**): 有限の要素を (a + b)/2。
4. それ以外: w_i = a + (b − a) · (v_i − vmin)/(vmax − vmin)。全標本の最小〜最大なので、どの標本でも w_i は [a b] に入ります。
5. NaN の要素は a(最も細い・小さい)。
6. 0 は特別扱いしません(ただの値)。量はすべて大きさ(絶対値)で渡します(`"P"` は |q|。符号は流れの向きだけに使う)。

尺度を計算する時と、使う値:

- **いつ:** `load_data`(コンストラクタと `set_data`)と、モード(`BranchWidthMode`、`MarkerSizeMode`)の setter で計算し、私用のプロパティにモードごとに持ちます(例 `sct_scale.BranchWidth = [vmin vmax]`)。`set_time` では計算しません(標本の値を写すだけ)。全標本の量は疎行列の積でまとめて求めます(流れの速さの q_max と同じ計算。§3.1)。
- **`set_data` と新しい状態:** 尺度は**状態に属します**。`set_data`(と `plot_diagram(Graph=G)`)で状態が変わると、新しい状態の全標本から尺度を計算し直します。前の状態の尺度は引き継ぎません(別の解析の結果を同じ図で見るときに、前の結果の最大で今の結果が細く見えないようにするため)。同じ尺度で 2 つの結果を比べたいときは、要素ごとの `BranchLineWidth` などに自分で値を入れます(§4.2)。
- **1 標本の図**(潮流、平衡点、構成だけ): 全標本 = その 1 標本なので、標本ごとの正規化と同じです。
- **時刻によらない量**(`BranchWidthMode` の `"G"`、`"B"`、`"Y"`、`"Ysvd"`)は全標本で同じ値なので、尺度もふつうの最小〜最大です。
- 母線と機器の大きさ(§4.4)は、それぞれ別の尺度です。
- 流れの速さの q_max も同じく全標本の最大です(§3.1)。

- 範囲のプロパティの検査: `(1,2) double`、有限、正、a ≤ b(違えば `GUILDA:GraphNetDiagram:RangeValue`。GraphNetMap は `GUILDA:GraphNetMap:RangeValue`)。a = b なら全要素がその値です(大きさを 1 つにしたいとき)。範囲を変えても尺度は計算し直しません(写す先が変わるだけ)。

### 4.2 ブランチの幅: `BranchWidthRange` と `BranchWidthMode`

- `BranchWidthRange`(既定 **[1 4]** pt)。
- `BranchWidthMode` に流れの量 `"P"`、`"Q"`、`"I"`(§3.1 の |q|)を加えます。今の `"G"`、`"B"`、`"Y"`、`"Ysvd"`、`"none"` は残します。`"none"` は全ブランチが (a + b)/2 = 2.5 pt です(§4.1 の 2)。
- **既定の `BranchWidthMode` を `"P"` に変えます**(Q4)。理由: §1 のとおり Ysvd は変圧器で桁違いに大きく、線形の写しでは大半のブランチが最小の幅に集まります。流れの |P| のほうが分布がなだらかで、流れのアニメーションとも意味がそろいます。構成だけの図(状態が NaN)では全部 NaN なので、全ブランチが 2.5 pt です。
  - **2026-11-18 追記:** 利用者の依頼で、既定は `"Ysvd"` に戻しました(`"P"`、`"Q"`、`"I"` は選べる値として残ります。`BranchWidthRange` は [1 4] のまま)。Ysvd は時刻によらない量なので、構成だけの図でもブランチの幅はアドミタンスに従います(2.5 pt にそろうのは `"P"`、`"Q"`、`"I"` のときです)。
  - **2026-11-18 追記(利用者の依頼):** ブランチの幅の尺度は、最小〜最大ではなく**最小〜95 パーセンタイル**(全ブランチ・全標本の有限の値、最近順位。`GraphNetDiagram.color_percentile`)にしました。自動の `ColorLimits` と同じく上側の外れ値を除くためで、上位 5% は `range_map` が範囲の端に収めて最大の幅になります。`BranchWidthMode` のどのモードでも同じです。値が 20 個未満のとき(`color_percentile` は最大を返す)と、値が異なるのに 95 パーセンタイルが最小と等しいとき(幅が全部中央にならないように)は最小〜最大です。母線と機器の大きさ(`MarkerSizeMode`)は最小〜最大のままです。既定の `net.plot_diagram()` で、幅の 中央値 / 90% 点 / 1.5 pt 未満の割合 / 4 pt の割合は、IEEE14 が 1.64 / 2.95 pt / 25% / 10%(2 本)、IEEE68 が 1.57 / 2.98 pt / 46% / 6%(5 本)です(最小〜最大のときは 1.5 pt 未満が 55% と 87%)。
- `BranchLineWidth`(要素ごと、n×1)の有限の行は、範囲の値を**上書き**します。単位は pt で、範囲で写しません(OPF の `plot_iteration` が入れる 1〜5 はそのまま pt の幅になる)。NaN の行は範囲の値です。
- 最も細いブランチは 1 pt です。画面で 1〜2 画素、150 dpi の書き出しで約 2 画素で、見えます。

### 4.3 リンクの幅: `LinkWidth`

- 新しいプロパティ `LinkWidth`(スカラー、既定 **1** pt)。リンクは全部同じ幅で、範囲・モード・要素ごとのベクトルは持ちません(今もリンクの太さは固定で、set_style の LineWidth もリンクにないため。§9 の Q11)。リンクの流れの大きさは点の速さで分かります。

### 4.4 節点の大きさ: `MarkerSizeRange` と `MarkerSizeMode`

- `MarkerSizeRange`(既定 **[4 8]** pt)。母線と機器が同じ範囲を使います。
- 新しいプロパティ `MarkerSizeMode`(`"none"`(既定)、`"P"`、`"Q"`、`"S"`): 機器は注入の |P|、|Q|、|P + jQ|、母線は母線の注入(その母線の機器の合計)の同じ量。母線と機器は**別々に**正規化します(母線の注入は機器の注入の合計なので、まとめると機器が小さく偏るため)。
- `"none"` は全節点が (a + b)/2 = **6 pt** です。今の既定(span の 2.6% の四角)より小さく、MATLAB の既定のマーカー(6 pt)と同じです。棒の母線の太さはその半分の 3 pt です。
- **`MarkerSize`(スカラー)は削除します**(§9 の Q12)。大きさを 1 つにしたいときは `MarkerSizeRange = [s s]` です。範囲と別にスカラーを残すと、「`"none"` のときだけ効くスカラー」と範囲の 2 つの置き場所ができるためです。
- `BusMarkerSize`、`ComponentMarkerSize` の有限の行は上書きします(pt、写さない)。NaN の行は範囲の値です。

### 4.5 削除するもの(互換なし)

- `BranchWidthScale`、`BranchWidthOffset`、`MarkerSize` を削除します。互換の別名、警告の段階は置きません(プロジェクトの規則)。Name-Value で渡すと、`opt.?GraphNetDiagram` の MATLAB のエラー(知らない名前)になります。
- 直すもの: `ResultOPF.plot_iteration`(`G_net.MarkerSize` → `mean(G_net.MarkerSizeRange)`)、F44 のテスト、`functionSignatures.json`(再生成)、`notes/v4-migration.md`(対応表)、`list_UpdateLog.js` は過去のお知らせなので変えない。
- `notes/graph-base.md` §4.2 の「`BranchLineWidth` の単位は既定の幅 `BranchWidthOffset + BranchWidthScale*値` と同じ」は、実装の後に「pt」に直します。

### 4.6 GraphNetMap にも同じ名前を使う

`GraphNetMap` の流れの幅は今 `0.5 + 4.5 · |流れ| / max`(0 から)、母線は 7 pt 固定です。

- `BranchWidthRange`(既定 [1 4])を GraphNetMap にも加え、流れの |P|(または |Q|、データの `s_arrow`)を §4.1 で写します。`s_arrow = "none"` は全部 (a + b)/2。
- 母線の大きさの量は GraphNetMap にないので、`MarkerSizeRange` は加えません。既定の `BusMarkerSize` を 7 から 6 にします(2 つの図の見かけをそろえる)。
- 同じ名前・同じ既定にすると、パネルの宣言も同じ形になります(§9 の Q13)。

## 5. 操作パネル(GraphBase)

### 5.1 公開の API

| メンバー | 内容 |
|---|---|
| `h = G.show_controls(Parent=[], ChangedFcn=[])` | パネルを作って返す(すでにあれば作り直す)。`Parent` は容器(figure、uifigure、uipanel、uitab、uigridlayout)。空なら図の figure の中で軸の右に置く(§5.3)。`ChangedFcn` はパネルの操作でプロパティを設定した後に `fcn(G, s_property, value)` で呼ぶ(GUI が実行記録に書くため。§5.6) |
| `G.hide_controls()` | パネルを消す(Parent が空のとき、軸を元の大きさに戻す) |
| `h_controls`(読み取り専用) | パネル(`uipanel`)。なければ空 |

- パネルは図のプロパティを設定するだけで、ほかに状態を持ちません。パネルを消しても図は変わりません。
- 軸が消えるとパネルも消えます(軸の `ObjectBeingDestroyed`)。`set_data` と `plot_diagram(Graph=G)` ではパネルは残り、時刻のスライダーの範囲などを合わせ直します。
- `plot_*` の Name-Value に `Controls` などは加えません。新しい figure にもパネルは自動では出しません(Q14)。出すときは `G.show_controls()` を 1 行書きます。

### 5.2 サブクラスの宣言: `control_list()`

新しいフック(protected、既定は空の構造体配列): `sct_ctl = control_list()`。行ごとに 1 つの操作です。

| フィールド | 内容 |
|---|---|
| `Property` | 設定するプロパティの名前(string)。`"<time>"` は基底の時刻の操作(§5.4) |
| `Widget` | `"dropdown"`(選択肢)、`"checkbox"`(logical)、`"slider"`(連続の数値)、`"spinner"`(数値)、`"range"`(1×2 の範囲。2 つの数値の欄)、`"toggle"`(再生・停止のような logical のボタン)、`"time"` |
| `Items` | `"dropdown"` の選択肢(string)。宣言に書きます(プロパティの `mustBeMember` の値は `metaclass` から読めないため) |
| `Limits` | `"slider"`、`"spinner"`、`"range"` の [最小 最大] |
| `Step` | 数値の刻み(`"spinner"`、`"range"`。空は自動) |
| `Label` | 表示する名前(英語。§5.6 の G3) |
| `Group` | 見出し(`"View"`、`"Color"`、`"Size"`、`"Flow"`、`"Label"`、`"Time"`)。同じ `Group` の行をまとめる |
| `EnableFcn` | 空か `@(G) logical`。false の間は操作できない(例: `FlowAnimation` は `@(G) G.Dimension == "2D"`)。パネルのどれかの値が変わるたびに評価し直す |

- 宣言するプロパティは `SetObservable` にします(§5.5 の同期のため)。サブクラスの classdef の、そのプロパティのブロックに属性を付けます。
- 宣言してよいのはスカラーのプロパティ(と範囲の 1×2)だけです。要素ごとのベクトル(`BusColor` など)はパネルに出しません(要素を選んで色を変える操作は GUI の選択と set_style の領分で、この仕様の範囲外)。

### 5.3 配置

- **`Parent` が空:** 図の figure の中で、軸の容器(GraphBase が作った tiledlayout。Parent が軸ならその軸)の右に、幅約 220 px のパネルを置きます。figure の中を `uigridlayout` に入れ直すと tiledlayout を作り直すことになるので、**正規化の位置で分けます**: tiledlayout(または軸)の `OuterPosition` を [0 0 1−f 1]、パネルを [1−f 0 f 1] にします(f = 220 px ÷ figure の幅。`show_controls` のときに 1 回計算し、figure の大きさを変えても比は保つ)。`hide_controls` で元の位置に戻します。
- **`Parent` がある:** その容器を埋めます(GUI がセルや区画を用意する)。
- パネルの中は `uigridlayout`(1 列、行は内容に合わせる、スクロール可)で、`Group` ごとに見出しの `uilabel`、各行に名前と操作の部品を並べます。
- 部品は `uidropdown`、`uicheckbox`、`uislider`、`uispinner`、`uibutton(State)` を使います。**`figure`(uifigure でない)の中にこれらを置けるか**は R2026a で確かめます。置けなければ `figure` では `uicontrol` で同じ部品を作ります(`ResultOPF.plot_iteration` は `figure` に `uicontrol` を置いている)。実装の最初に確かめ、どちらか一方だけで済めばそれにします(§8 の S3 の最初の手順)。

### 5.4 基底が持つ時刻の操作(`"time"`)

> 2026-11-20: 時刻の行はパネルから外し、図の下の再生バーに移しました(`"time"` の部品は廃止)。今の仕様は [graph-playback.md](graph-playback.md) です。この節と §5.6 の Time の行は当時の記録です。

標本が 2 つ以上の図で、宣言に `"<time>"` の行があれば、基底が次の 3 つを作ります。

- スライダー(標本の番号 1〜n_t、刻み 1): 動かすと `set_time(rv_t(k))`。リンクした図も動きます。
- 再生・一時停止のボタン: 再生は `animate`(`Speed=1`)を呼びます。一時停止は、`animate` のループが毎こま見る私用のフラグ(新規、`l_stopAnimate`)を立てて止めます。`animate` の公開の引数は変えません。
- 時刻の表示(`t = 0.25 s`、`TitleFormat` とは別)。

`TimeChanged` のリスナーでスライダーと表示を合わせます(コードから `set_time` しても動く)。1 標本の図では時刻の行を出しません。

### 5.5 2 方向の同期

- **パネル → 図:** 部品の `ValueChangedFcn` が `G.(Property) = value` を設定します。エラー(範囲の検査など)は、パネルの部品をプロパティの今の値に戻し、図が見えていれば `uialert`(uifigure)か `warning`(figure)で知らせます。
- **図 → パネル:** `show_controls` が宣言の各プロパティに `PostSet` のリスナーを付け、値が変わると部品の値を書き換えます(コード、`set_style`、ほかの GUI、どこから変えても)。部品を書き換えても `ValueChangedFcn` は呼ばれない(MATLAB の部品の仕様)ので、ループしません。
- リスナーはパネルの `UserData`(または私用のプロパティ)に持ち、パネルと一緒に消えます。
- `set_data` で標本の数が変わったら、基底がスライダーの範囲を直します(`set_data` の最後に私用の `refresh_controls` を呼ぶ)。

### 5.6 図のクラスごとの操作

| クラス | Group | 宣言(Property: Widget) |
|---|---|---|
| GraphNetDiagram | View | `Dimension`: dropdown、`BusHeightMode`: dropdown(2D・3D のどちらでも操作できる。Q9) |
| | Color | `ColorMode`: dropdown、`ColorLimits`: range |
| | Size | `BranchWidthMode`: dropdown、`BranchWidthRange`: range(Limits [0.5 20])、`MarkerSizeMode`: dropdown、`MarkerSizeRange`: range([1 30])、`LinkWidth`: spinner([0.5 10]) |
| | Flow | `FlowMode`: dropdown、`FlowAnimation`: toggle(2D のときだけ)、`FlowSpeed`: slider([0.1 5]) |
| | Label | `LabelMode`: dropdown、`LabelFontSize`: spinner([3 20]) |
| | Time | `"<time>"` |
| GraphNetMap | Size | `BranchWidthRange`: range |
| | Label | なし(ラベルの表示を切り替えるプロパティがない。加えない) |
| GraphChart | Time | `"<time>"`(時刻のパネルがある図だけ、つまり `l_time` のあるとき) |
| GraphSpringBase(2D・3D 共通) | Label | `ShowLabel`、`ShowValue`、`ShowLegend`: checkbox |
| | View | `RotationScale`: slider([0 1])、`ArrowScaleP`、`ArrowScaleQ`: spinner([0 2]) |
| | Time | `"<time>"` |
| GraphSpring3D(追加) | View | `SurfaceAlpha`: slider([0 1]) |

- GraphNetMap の色(`s_color`)と矢印(`s_arrow`)はデータなので(graph-base §4.5)、パネルに出しません(Q13)。
- GraphChart は見た目がすべて要素ごとのベクトルなので、時刻の操作だけです。

### 5.7 GUI アプリへの埋め込み(GUI の調整役と合意する点)

| | 合意する点 | この仕様の提案 |
|---|---|---|
| G1 | パネルの置き場所。`DrawerGUILDA` の左半分(情報の帯、系統図、実行記録)と、`DrawerResultGUI` の Plot タブ | GUI が区画(uipanel)を用意し、`G.show_controls(Parent=h)` を呼ぶ。系統図の右か下に、たたむことのできる「表示」の区画を置く案。形は GUI の調整役が決める |
| G2 | パネルの操作を実行記録に書くか | `ChangedFcn` で `G.ColorMode = "P";` の形のコードを記録する。ただし `DrawerGUILDA` の系統図の描画は記録しない約束なので(`G` は記録のワークスペースにない)、系統図のパネルの操作は記録しない。`DrawerResultGUI` の `G = res.plot_*(...)` の図は記録する |
| G3 | 部品の表示名の言語 | 図のクラスは英語(クラスのヘルプ、エラーの文と同じ)。GUI が日本語にしたい場合は、`show_controls` の引数ではなく GUI 側の対応表で置き換えるか、ここで決め直す |
| G4 | 隠れた figure と timer | アプリをテストで隠して作ると timer は動かない(§3.2)。流れは自動では始まらない(Q7)ので、アプリを表示した後に系統図の流れを動かすには、GUI が表示の後に `G.FlowAnimation = true` を設定し直す |
| G5 | 図の作り直しとパネル | `plot_diagram(Graph=G)` ではパネルが残る。`delete(h_parent.Children)` の後に新しい `G` を描くタブ(`f_diagram`)では、GUI が `show_controls` を呼び直す |
| G6 | 系統図の作成時間 | 2D は 3D より速くなる見込み(§2.6)で、F55 の時間(約 100 秒)とタブ切り替えの描き直しも短くなるはず。GUI の調整役に、2D を既定にしたあとの F55 の時間を見てもらう |
| G7 | `ResultOPF.plot_iteration` の自前のボタンとスライダー | この仕様では変えない。後で `show_controls` の時刻の操作に置き換えられる(OPF の調整役の担当) |

## 6. 新しいメンバーと削除するメンバー(ブリーフに書く)

| クラス | 加える | 削除・変更 |
|---|---|---|
| GraphNetDiagram | `Dimension`、`BranchWidthRange`、`MarkerSizeRange`、`MarkerSizeMode`、`LinkWidth`、`FlowMode`、`FlowAnimation`、`FlowSpeed`、隠し `step_flow(r_dt)`、`delete`(デストラクター)、protected `control_list`。エラー ID `GUILDA:GraphNetDiagram:RangeValue` | 削除: `BranchWidthScale`、`BranchWidthOffset`、`MarkerSize`。`BranchWidthMode` に `"P"`、`"Q"`、`"I"`(既定 `"P"`、Q4)。`BranchLineWidth`、`BusMarkerSize`、`ComponentMarkerSize` の単位を pt に |
| GraphNetMap | `BranchWidthRange`、protected `control_list`。エラー ID `GUILDA:GraphNetMap:RangeValue` | `BusMarkerSize` の既定 7 → 6 |
| GraphBase | `show_controls`、`hide_controls`、`h_controls`、protected `control_list`(既定は空)、protected static `range_map`(§4.1)、protected `prepare_frame`(§8.2、Q16)、私用 `refresh_controls`、`l_stopAnimate` | `animate` が私用のフラグで止まる(公開の引数は同じ) |
| GraphSpringBase、GraphSpring3D、GraphChart | protected `control_list`。宣言したプロパティに `SetObservable` | なし |
| ResultOPF | なし | `plot_iteration` の `MarkerSize` の参照 |

ほかの公開のメンバーは加えません(memory の規則)。私用の関数(弧長の補間、`range_map`、2D の描画)は `@GraphNetDiagram` のメソッドか private に置き、1 か所でしか呼ばないものは本体に入れます。`range_map` は GraphNetDiagram と GraphNetMap の両方が使うので、GraphBase の protected static にします(graph-base §3 の共通ヘルパーと同じ扱い)。

## 7. テスト(F53 は B、F54・F55 は使用中。2026-11-17: F56〜F58 は GUI の調整役が使うので、計画の F56・F57・F58 は F59(S1)、F60(S2)、F61(S3)にしました)

| 番号 | ファイル | 内容 |
|---|---|---|
| F59 | `test_F59_diagram_2d` | 2D の作成(IEEE14、IEEE68): 要素ごとの `line` の数、棒の母線の線分の長さと中心、変圧器の記号が From 端、立体(`patch` の面、`surface`)と `light` がないこと。2D の高さ(Q9): `BusHeightMode="V"` で母線の `ZData` が |V|、ブランチの端の z が両端の母線の高さ、折れ点の z が弧長の補間、機器とリンクが母線の高さ、`set_time` で図を作り直さず(ハンドルが同じ)`ZData` が変わること、`view(G.ax, 30, 40)` の後に `BusHeightMode` や `Dimension` を変えても視点が残ること。`range_map` の場合(全部同じ、全部 NaN、一部 NaN、0 を含む、a = b)。全標本の尺度(Q10): 2 標本の状態で、どちらの標本でも同じ値の要素が同じ幅になること、全標本の最大の要素だけが b になること、`set_data` で別の状態にすると尺度が新しい状態から決まること、1 標本では標本ごとの写しと一致すること。`BranchWidthRange` を変えると最小・最大の幅が a・b になること。`BranchLineWidth` の有限の行が範囲より優先され、NaN に戻すと範囲の値に戻ること。`MarkerSizeMode` の各モード。`Dimension` を 3D → 2D と切り替えて、位置・ベクトル・選択・表示中の標本・`G` が同じこと、3D の管の半径が span に比例すること。削除したプロパティを Name-Value で渡すとエラー。選択の重ね描きの位置。2D の速さ(§2.6、上限は目標の 5 倍)。`exportgraphics` の画像に余計な線がないこと(F47 と同じ確かめ方) |
| F60 | `test_F60_flow_animation` | 隠れた figure で timer がないこと。`step_flow` で点が流れの向きに進むこと(P の符号を逆にした系統で逆向き)、速さが |q| に比例すること、間隔が 0.25·d0、|q| の小さい要素と構成だけの図で点がないこと、`set_time` の後の速さと向き、高さのある図(`BusHeightMode="V"`)で点の z が経路の z と一致し、弧長が 3D で測られること、`export_video` が timer を残さないこと。`FlowAnimation`、`Dimension`、`delete(G)`、`close(fig)` の後に `timerfindall` の Tag が空。1 こまの計算時間 |
| F61 | `test_F61_graph_controls` | `show_controls`(Parent が空の figure、uifigure の uipanel、uigridlayout): 宣言の行の数の部品、部品の操作 → プロパティ、コードでの設定 → 部品、`EnableFcn`、エラーで部品が戻ること、`ChangedFcn` の引数、時刻のスライダー → `set_time` と `TimeChanged` → スライダー、`set_data` の後のスライダーの範囲、`hide_controls` で軸の位置が戻ること、軸を消すとパネルも消えること。GraphSpring2D、GraphChart(時刻のパネルあり・なし)、GraphNetMap、GraphNetDiagram |

既存のテストで直すもの: F44(`BranchWidthScale` などの削除、既定の大きさ)、F46(速さの確かめは 2D と 3D の両方)、F47(3D の画像の確かめは `Dimension="3D"` を付ける)、F49(GraphNetMap の幅)、OPF の `plot_iteration` のテスト(F5x のうち該当するもの)、F55(GUI の系統図が 2D になる)。

## 8. 実装の計画

### 8.1 順序

配置データの B(`refactor/graph-layout-netdiagram`)が `@GraphNetDiagram`、`@GraphNetMap`、`@GraphBase`(`get_layout`)を変えているので、**どのサブセッションも B のマージの後に始めます。** 2D の描画は B の新しい列(`X`、`Y`、`Shape`、`Length`、`Path`、`FromOffset`、`Style`、`DX`、`Offset`)を直接読みます。

```
B マージ ─┬─ S1 2D と範囲 ── S2 流れ ──┐
          └─ S3 パネルの基底 ───────────┴─ S4 図ごとの宣言 ── S5 文書
```

| | ブランチ(案) | 変えるファイル | テスト |
|---|---|---|---|
| S1 | `feature/graph-diagram-2d` | `@GraphNetDiagram/`(`GraphNetDiagram.m`、`create_scene.m`、`update_scene.m`、`apply_style.m`、`apply_selection.m`、`draw_graph_network.m` → 3D 専用、新規の 2D の描画、`reflect_*`、`hover_*`、`private/*`)、`@GraphNetMap/`(`GraphNetMap.m`、`load_data.m`、`create_scene.m`)、`@GraphBase/GraphBase.m` と新規 `@GraphBase/range_map.m`(中身だけ。宣言は S3)、`@ResultOPF/plot_iteration.m`、`@PowerNetwork/plot_diagram.m`・`@ResultPF/plot_diagram.m`・`@ResultODE/plot_diagram.m` のヘルプ(「3D」の記述)、`SystemTools/GUILDA/en/GraphNetDiagram.xml`・`GraphNetMap.xml`、`resources/functionSignatures.json`(再生成) | 新規 F59。F44、F46、F47、F49、OPF の図のテストを直す |
| S2 | `feature/graph-flow-animation`(S1 の後) | `@GraphNetDiagram/`(`GraphNetDiagram.m`、新規 `step_flow.m`、`delete`、timer の私用の関数、`update_scene.m`、`load_data.m`、`reflect_arrow_forward.m`)、`@GraphBase/export_video.m`(書き出しの間の timer の停止と `step_flow` の呼び出しを、サブクラスのフック経由で。§8.2) | 新規 F60 |
| S3 | `feature/graph-controls`(B の後、S1 と並行) | `@GraphBase/`(`GraphBase.m`、新規 `show_controls.m`、`hide_controls.m`、`refresh_controls.m`、`control_list.m`、`animate.m`、`set_data.m`)、新規メッセージ `GraphBase.xml` の追加分、`@GraphSpringBase/`(`GraphSpringBase.m`、新規 `control_list.m`)、`@GraphSpring3D/GraphSpring3D.m`(`SurfaceAlpha` の宣言)、`@GraphChart/`(`GraphChart.m`、新規 `control_list.m`) | 新規 F61(GraphSpring と GraphChart の分) |
| S4 | `feature/graph-controls-net`(S2 と S3 の後) | `@GraphNetDiagram/GraphNetDiagram.m`(`SetObservable`)と新規 `control_list.m`、`@GraphNetMap/GraphNetMap.m` と新規 `control_list.m` | F61 に GraphNetDiagram と GraphNetMap を足す |
| S5 | `docs/graph-diagram-2d-pages`(S4 の後) | 図の機能を説明している For Developer のページ(`_GUILDAdoc/developer/` の該当ページ。日英)、`class.html`(生成)、`notes/graph-base.md` §4.2 の単位の記述、`notes/v4-migration.md`(削除したプロパティの表)、この文書の状態、Update log | なし |

- S1 と S3 は `@GraphBase/GraphBase.m` を両方変えます(S1 は `range_map` の宣言 1 行、S3 はパネルのメンバー)。**ファイルを共有しないため、`range_map` の宣言は S3 が入れ、S1 は `range_map.m` の中身だけを書く**か、S1 を先にマージしてから S3 を始めます。前者にします(Q15。S3 のブリーフに「`methods (Static, Access = protected)` に `rv_w = range_map(rv_v, rv_range, rv_lim)` を宣言する。中身は S1」と書き、S1 は `@GraphBase/range_map.m` だけを作る。S1 と S3 のマージの順はどちらでもよい。両方そろうまで S1 は単独で動かないので、**S1 のテストは S3 のマージの後に流す**)。実装の途中で調整が重いと分かれば、S1 → S3 の順に直列にします。
- GUI(`@DrawerGUILDA`、`@DrawerResultGUI`)への埋め込みは S4 の後に GUI の調整役が行います。この計画のサブセッションは GUI のファイルを変えません。
- テストの水準(memory の規則): 各サブセッションは手順ごとに small の `run_all` とコミット、マージの前に medium を 1 回。large は行いません。

### 8.2 `export_video` と流れ(S2 の詳細)

`export_video` は GraphBase のメソッドで、GraphNetDiagram 専用の処理を書きたくありません。GraphBase に protected のフック `prepare_frame(r_dt)`(既定は何もしない)を加え、`export_video` が各こまの前に呼びます。GraphNetDiagram はこれを上書きして timer を止め、`step_flow(r_dt)` を呼びます(書き出しの後の再開は `export_video` が最後に `prepare_frame(NaN)` を呼んで知らせる)。Q16 で加えることが決まりました。

### 8.3 実装の状況

| | 状況 |
|---|---|
| S1 | `feature/graph-diagram-2d` で実装、マージ済み(1ec24cde、F2 の修正 53386d50)。§11.1 |
| S2 | `feature/graph-flow-animation` で実装、マージ済み(33f55e29)。§11.2 |
| S3 | `feature/graph-controls` で実装、マージ済み(6812d85e)。下の「S3 の実装メモ」 |
| S4 | `feature/graph-controls-net` で実装、マージ済み(921e6135)。§11.3 |
| S5 | `docs/graph-diagram-2d-pages` で文書を更新(2026-11-17)。§11.4 |

S3 の実装メモ:

- **部品:** R2026a では `figure`(uifigure でない)の中にも `uipanel`、`uigridlayout`、`uidropdown`、`uicheckbox`、`uislider`、`uispinner`、`uibutton(state)` を置けることを確かめたので、`uicontrol` は使わず、どの容器でも同じ `ui*` の部品にしました(§5.3)。`exportgraphics` は UI の部品を画像に入れないので、パネルごとの画像は `exportapp(fig, file)` で撮ります。
- **状態の置き場所:** 宣言(欠けたフィールドを埋めたもの)、部品のハンドル、リスナー、`Parent`、`ChangedFcn`、軸の元の位置はパネルの `UserData` に持ちます。§6 にない私用のプロパティは加えていません。パネルの `DeleteFcn` が軸の位置を戻し、`h_controls` を空にするので、`hide_controls`、`delete(G.h_controls)`、軸の削除のどれでも同じ後片付けになります。
- **宣言の検査:** `show_controls` は、宣言のプロパティが public で `SetObservable` でなければ `GUILDA:GraphBase:ControlProperty`、知らない `Widget` は `GUILDA:GraphBase:ControlWidget` で止まります。省いたフィールドは既定(`Label` はプロパティ名、`Group` は `"View"`、`Limits` は slider が [0 1]、spinner と range が [-Inf Inf])。
- **値の表示:** プロパティの値が `Limits` の外のときは、部品の範囲を広げて値を表示します(値を丸めて見せない)。dropdown の `Items` にない値は `Items` に足して表示します。
- **エラー:** 部品をプロパティの今の値に戻し、見える figure なら `uialert`、見えない figure なら警告 `GUILDA:GraphBase:ControlValue`(`show_msg`)。
- **時刻:** スライダーは標本の番号(1〜n_t、目盛りなし)で、離したときに `set_time`。再生のボタンは `animate()`(既定の引数、最初の標本から)を呼び、もう一度押すと私用の `l_stopAnimate` で次のこまで止まります。`animate` は始めにフラグを下ろすので、止めた後の `animate` は普通に最後まで再生します。`set_data` で標本が 1 つになる(または 1 つから増える)と、時刻の行を出し入れするためにパネルを同じ `Parent` と `ChangedFcn` で作り直します。
- **宣言のない図:** 宣言が空の図(時刻のパネルのない GraphChart、1 標本の GraphChart)では、パネルに「No controls for this graph.」だけを出します(エラーにはしない。GUI が図の種類を問わず `show_controls` を呼べるように)。
- **`Parent` が空で、軸が uigridlayout や tiledlayout の中にあるとき**(axes を Parent にして描いた図など)は、軸の隣に置けないので `GUILDA:GraphBase:ControlsPlace`(`Parent` を渡すように案内)。axes を Parent にした図は、その axes の `OuterPosition` を横に `1 − f` 倍に縮めます(同じ figure のほかの軸の配置を壊さないため)。
- **`prepare_frame`:** `export_video` が各こまの `set_time` の前に `prepare_frame(1/FrameRate)` を呼び、`onCleanup` で最後(エラーで止まったときも)に `prepare_frame(NaN)` を呼びます。基底は何もしません(S2 が上書き)。
- **`range_map`:** ブリーフの指示で、宣言も S1 が入れます(§8.1 の Q15 と違う。S3 は `GraphBase.m` の static の宣言の部分に触れていない)。
- **テスト:** F56〜F58 は GUI の調整役、F59 は S1、F60 は S2 が使うので(調整役の指示、2026-11-17)、この分は `test_F61_graph_controls`(GraphSpring2D/3D と GraphChart、11 件)にしました。S4 は GraphNetDiagram と GraphNetMap の分を F61 に足します。`EnableFcn` を使う宣言は S3 の図にないので、テストはパネルの `UserData` の宣言を差し替えて確かめています。

## 9. 決定事項(2026-11-16、ユーザー)

Q9 と Q10 は提案と違う決定です。ほかは提案のとおりです。

| | 問い | 決定 | 理由・本文 |
|---|---|---|---|
| Q1 | 2D・3D を切り替えるプロパティの名前 | `Dimension`(`"2D"`/`"3D"`) | `GraphSpring3D.View` がカメラの角度の意味で使われている(MATLAB の `view` も同じ)。§2.4 |
| Q2 | 流れの量を `ColorMode` と共有するか | 別のプロパティ `FlowMode`(`"P"` 既定、`"Q"`、`"I"`、`"none"`) | `ColorMode` には向きのない `"Loss"`、`"user"` がある。§3.1 |
| Q3 | 3D でも流れの点を動かすか | 2D だけ(3D は今の円錐の矢印) | 3D は立体の描画を残すオプション。§2.4 |
| Q4 | `BranchWidthMode` の既定 | `"P"`(`"P"`、`"Q"`、`"I"` を加える) | IEEE68 の Ysvd は 3〜905 と偏り、線形の写しでは 87% が 1.5 pt 未満になる。§4.2。**2026-11-18 に利用者の依頼で既定を `"Ysvd"` に戻した** |
| Q5 | 点の密度も量に比例させるか | させない(間隔は 0.25·d0 で一定、速さだけ比例) | 小さい流れの線でも向きが読める。§3.1 |
| Q6 | こまの数をプロパティにするか | しない(25 こま/秒固定) | 速さは実時間で決まる。§3.2 |
| Q7 | 隠れた figure で作った図を、後で表示したときに流れを自動で始めるか | 始めない(`G.FlowAnimation = true` を設定し直す。パネルの再生ボタンでも同じ) | figure の監視が要らない。§3.2、§5.7 の G4 |
| Q8 | ラベルの既定の文字の大きさ | 今のまま 5 | 実装後の画像を見て決め直す |
| Q9 | 2D と高さ | **2D でも z を使う。** 2D は「3D 空間に置いた平らな記号」(線とマーカー、立体・照明なし)で、`BusHeightMode`(と母線の z)は 2D でも効く。記号はその z に描き、ブランチとリンクは端の高さに従う。既定の視点は真上で、利用者は回せる。`Dimension="3D"` は立体の描画 | §2.1(視点、重ね順)、§2.2(z の付け方)、§2.3(選択)、§2.5(`ZData` の更新)、§3.3(点が z に沿う)、§5.6(パネルで 2D でも操作できる) |
| Q10 | 幅・大きさの正規化を標本ごとにするか | **全標本で 1 つの尺度**(時間の全体の最小〜最大)。シミュレーションの全体で単位が同じ。`set_data` で状態が変われば新しい状態から計算し直す。1 標本の図では標本ごとと同じ | §4.1 |
| Q11 | リンクの幅 | スカラー `LinkWidth`(既定 1 pt)だけ | §4.3 |
| Q12 | スカラーの `MarkerSize` | 削除(`"none"` は範囲の中央、1 つの大きさは `[s s]`) | §4.4 |
| Q13 | GraphNetMap の範囲と、色・矢印 | `BranchWidthRange` を加え、既定の母線を 6 pt にする。色と矢印はデータのまま(パネルに出さない) | §4.6、§5.6 |
| Q14 | `plot_*` が新しい figure を作ったとき、パネルを自動で出すか | 出さない(`G.show_controls()` を呼ぶ) | §5.1 |
| Q15 | S1 と S3 の `GraphBase.m` の共有 | S3 が宣言、S1 が中身 | §8.1 |
| Q16 | `export_video` のための protected のフック `prepare_frame(r_dt)` | 加える | §8.2 |
| Q17 | 既定の範囲の値 | `BranchWidthRange = [1 4]`、`MarkerSizeRange = [4 8]`、`LinkWidth = 1`(pt) | §4.2〜4.4 |

GUI の調整役と合意する点は §5.7 の G1〜G7 です。

## 10. この仕様の範囲外

- 要素を選んで色・大きさを変えるパネル(要素ごとのベクトルの編集)。GUI の選択と `set_style` の領分です。
- `plot_network` を `plot_diagram` にまとめること(役割は §0 の決定のとおり分ける)。
- 3D の見た目の改良(3D は今のまま残すだけ。大きさの換算 §2.4 だけ変える)。
- ラベルの重なりの解消(`resolve_overlap` の 2D への適用)は、実装後の画像を見て必要なら別に扱います。

## 11. 実装の状態

### 11.1 S1(2026-11-17、`feature/graph-diagram-2d`)

実装したもの:

- GraphNetDiagram: `Dimension`(既定 `"2D"`)、`BranchWidthRange`([1 4])、`MarkerSizeRange`([4 8])、`MarkerSizeMode`(`"none"`)、`LinkWidth`(1)、`BranchWidthMode` の `"P"`/`"Q"`/`"I"`(既定 `"P"`。2026-11-18 に `"Ysvd"` に戻した)、エラー `GUILDA:GraphNetDiagram:RangeValue`。`BranchWidthScale`、`BranchWidthOffset`、`MarkerSize` を削除。`BranchLineWidth`、`BusMarkerSize`、`ComponentMarkerSize` は pt で範囲より優先。尺度は全標本で 1 つ(Q10)、`set_data` で計算し直す。
- 2D の描画(`draw_diagram_2d`)、共通の位置と高さ(`diagram_geometry`)、2D の高さの更新(`update_heights`)、量と尺度(`size_values`、`update_scale`、`update_sizes`)。3D(`draw_graph_network`)は pt の大きさ(1 pt = span/400)と、ブランチの z の弧長の補間にそろえた。
- GraphBase: protected static `range_map`(宣言も S1 で `GraphBase.m` に 1 行。§8.1 の Q15 から変更、コーディネーターの指示)。
- GraphNetMap: `BranchWidthRange`、`GUILDA:GraphNetMap:RangeValue`、既定の母線 6 pt。
- `ResultOPF.plot_iteration` は `mean(G_net.MarkerSizeRange)`。`plot_diagram` 3 つのヘルプ、`functionSignatures.json`(再生成)。

§2 からの変更:

- ラベルの位置(§2.2): 仕様の (0, 0.3·d0)、(0.25·d0, 0.25·d0) では IEEE14 でラベルが記号から約 50 画素離れ、どの記号のラベルか分からず、上端の母線のラベルが軸の外(題の上)に出ました。要素のすぐ横(0.05·d0)に置きます: 点の母線は上、水平の棒は左端の左、垂直の棒は上端の上、機器は右。
- 機器のマーカーの縁は塗りの色 × 0.6(仕様は塗りだけ)。形 `"square"` などその他の形は `"s"`、既定の色は濃い灰 0.15。

報告された問題の修正:

1. 構成だけの図の色の棒: 色の値(4 つの `*ColorData`)が 1 つも有限でなければ色の棒を出さない(`apply_style` の最後で出し入れ)。F59 で確認。
2. 保存の再帰の警告: 原因は `ButtonDownFcn` とデータチップの関数が図のオブジェクトを捕まえていたこと(`function_handle_workspace` の保存で `MATLAB:loadsave:saveRecursionLimit`。IEEE68 で再現)。コールバックは `matlab.lang.WeakReference` だけを持ち、矢印のグループの `UserData` の円錐のハンドルもやめた(`Tag` で区別)。GraphNetMap の `ButtonDownFcn` も同じ。F59 で IEEE68 の 2D・3D を `savefig` して警告なし(ファイルは 2D 約 0.2 MB、3D 約 1.4 MB)。
3. 作成時間: 下の表。`set_network` の表を要素ごとに作っていた処理をまとめた(IEEE68 で約 0.25 s 短縮)。
4. `plot_lmp` の題と色の棒のラベル: 色の棒を `eastoutside`(既定の幅)にした。F59 で、題を [1 0 1]、ラベルを [0 1 1] の色にして `print` した図の画像で、その画素が図の端から離れていること(2D 560×420・400×300、3D 560×420)と、`exportgraphics` の画像にあることを確かめる。3D で図が 400×300 以下と狭いと、題が図の左端にかかる(列 1)ことがある(3D の軸の配置。未対応)。

作成時間(R2026a、-batch、見えない figure、JIT の後の 5 回の中央値。`net.plot_diagram` 全体で、`struct(net,false)` を含む。IEEE68 ではその約 0.3 s がスナップショットで、図のコンストラクタは約 0.3 s):

| 系統 | 2D | 3D | 以前(3D) |
|---|---|---|---|
| IEEE9 | 0.28 s | 0.47 s | 1.6 s(初回 4.5 s) |
| IEEE14 | 0.25 s | 0.58 s | |
| IEEE68 | 0.57 s | 1.94 s | |

IEEE68 のそのほか(§2.6): `Dimension` の 2D への切り替え 0.18 s(3D へは 1.3 s)、6 つのベクトルの代入 2D 0.016 s・3D 0.083 s、`set_time` 2D 0.008 s(`BusHeightMode="V"` で 0.025 s)、3D 0.065 s(`"V"` は作り直しで 1.5 s)。2D の作成の 0.5 s の目標は、スナップショットの分だけ超えています(図そのものは目標内)。

テスト: 新規 F59(13 件)。F4 の `plot_iteration` の色の確かめを 2D の線の色に、F44・F46・F47 の立体を確かめる箇所に `Dimension="3D"`、F49 の幅と既定の大きさ。F55 は変更なしで通る。

画像(コーディネーター向け、セッションの作業フォルダ): IEEE14 の 2D・3D(潮流)、IEEE14 の 2D(潮流の前)、IEEE68 の 2D、IEEE9 の `plot_lmp`(2D・3D)。

S3 との関係: `GraphBase.m` は `range_map` の宣言 1 行とクラスのヘルプの 1 文だけを変えた。S3 のブリーフに宣言が含まれていればマージで重なるので、どちらかを残す。

### 11.2 S2(2026-11-17、`feature/graph-flow-animation`)

実装したもの:

- GraphNetDiagram の公開のメンバー: `FlowMode`(`"P"` 既定、`"Q"`、`"I"`、`"none"`)、`FlowAnimation`(true)、`FlowSpeed`(1、正の有限の値)、隠し `step_flow(r_dt)`、デストラクター `delete`、protected `prepare_frame(r_dt)` の上書き。ほかの公開のメンバーは加えていません。
- 私用: プロパティ `sct_flow`(全標本の q、q_max、速さ、向き、位相)、`sct_flowPath`(経路をつないだ折れ線と点の候補)、`h_flowTimer`、`lis_flowAxes`、`u_flowTic`、`l_flowHold`。メソッド `flow_values`(全標本の q と q_max、疎行列の積 1 回)、`flow_paths`(経路の累積の長さ。弧長は 3D)、`update_flow`(表示中の標本の速さと向き、向きが変わった要素の位相を Δ − φ)、`flow_timer("auto"|"stop")`(timer の始め・止め。`TimerFcn` と軸の `ObjectBeingDestroyed` のリスナーは `matlab.lang.WeakReference` だけを持つ)。
- 1 こまの計算: 全要素の点の候補(k = 0, 1, …、kΔ ≤ 経路の長さ)を作っておき、こまごとに位相を足して経路の外の候補を落とし、つないだ折れ線の上の位置を `discretize` 1 回で求めます。点はブランチで 1 つ、リンクで 1 つの `patch`(`sct_plt.FlowBranch`、`FlowLink`、Tag も同じ名前)。
- メッセージ: `GUILDA:GraphNetDiagram:FlowTimer`(timer の中のエラーで止まったときの警告)。`functionSignatures.json` は再生成(3 つの `plot_diagram` に 3 つの Name-Value。get_sys/get_ss の Port は `"PI"`/`"PQ"`/`"I"` のまま)。

§3、§8.1 からの変更・補足:

- §8.1 の S2 の行にないファイルも変えました: `create_scene.m`(最初に timer を止め、`flow_paths` の後に描き、最後に `flow_timer("auto")`。3D では `FlowBranch`/`FlowLink` を空にする)、`draw_diagram_2d.m`(空の 2 つの `patch` を変圧器の記号の後・母線の前に作る。§2.2 の重ね順)、`apply_style.m`(ブランチかリンクの色を変えたら `step_flow(0)` で点の色を合わせる。timer のない図・書き出した画像でも色がずれないように)。`@GraphBase/export_video.m` は変えていません(S3 で `prepare_frame` の呼び出しが入っていた)。
- 点の向きは `BranchDirection`/`LinkDirection` の符号から取ります(§3.1。`reflect_arrow_forward` が q の符号を入れる)。利用者がこのベクトルを変えても点はそれに従います。`"I"` で P も Q も 0 の要素は向きがないので点を描きません。
- 経路の終点ちょうどの点は、経路の外に出ないように長さの (1 − 1e-9) 倍に寄せます(約 1e-9·d0 のずれ。F60 の許容は 1e-6·d0)。
- 点の色は描くたびに線の `Color` から取ります(IEEE68 の 1 こまで 0.5 ms 程度なので、別に持たない)。
- `cla` では軸が消えないのでリスナーは呼ばれません。timer は次のこまで点の `patch` がないことに気づいて自分を止めて消します(§3.5 の 4 つ目と同じ扱い)。
- 窓を閉じると、まれに `GUILDA:GraphNetDiagram:FlowTimer` の警告が 1 回出ていました(`plot_iteration` の自動再生中の結果の窓で 40 回に 1 回)。原因は、MATLAB が figure の削除の途中(`timer/stop` や内部の `removeControl` の中)で待っている timer のコールバックを実行し、そのこまでは軸がまだ有効なのに figure から外れていて `ancestor` が空を返し、`fig.Visible` の参照がエラーになったことです。
- `flow_tick` は、図・軸・点がないときに加えて、figure が空・無効・`BeingDeleted` が on、軸の `BeingDeleted` が on のときも、警告なしで timer を止めて消します。catch でも同じ条件を確かめ直し、成り立てば警告を出しません。figure が生きている間のエラーは今までどおり警告します。F60 に 1 件(軸を figure から外す場合と、2 つの軸の窓を閉じる場合)を足しました。
- 同じ削除の途中で再生バーの timer(`GraphBase.play_bar` の `play_tick`)も走り、`GUILDA:GraphBase:PlaybackTimer` の警告が出ていました。`fix/playback-timer-close-warning` で同じ形に直しました(notes/graph-playback.md)。

timer の動作(画面のある MATLAB R2026a、`matlab -nodesktop -r`、手で確かめた項目。CI では試さない):

| 操作 | timer の数(Tag `GUILDA:GraphNetDiagram:Flow`) |
|---|---|
| 見える figure に `net.plot_diagram` | 1(1 秒後に点が動いている) |
| `FlowAnimation = false` / `true` | 0 / 1 |
| `Dimension = "3D"` / `"2D"` | 0 / 1 |
| `FlowMode = "none"` / `"P"` | 0 / 1 |
| `close(fig)` | 0(`G` は有効のまま) |
| `delete(G)` | 0 |
| `clear G`(figure は開いたまま) | 次のこまで 0 |
| 隠れた figure に作る / 後で `Visible="on"` / `FlowAnimation = true` | 0 / 0(Q7) / 1 |
| `cla(G.ax)` | 次のこまで 0 |
| `res.plot_diagram`(ODE)、`set_time` | 1、1 |
| `export_video` の後 | 1(書き出しの間は止め、終わって再開) |

速さ(R2026a、-batch、見えない figure): `step_flow` の 1 こまは IEEE14 で約 1.7 ms、IEEE68 で約 0.5 ms(点 506 + 83。目標 5 ms)。

テスト: 新規 F60(11 件。`test_levels.m` に medium 7 件、large 4 件)。GUI の描き直し 2 通り(GUI の調整役の質問)も確かめます: (a) `delete(h_parent.Children)` で timer が消え、(b) `net.plot_diagram(Graph=G)` で timer が 1 つのまま動き続けます(uifigure の uipanel、画面のある MATLAB でも同じ結果)。-batch では timer を作らないので、この節だけ `batchStartupOptionUsed` を false を返す関数で隠し(一時フォルダを path の先頭に置き、名前の競合の警告を止める。終わりに外す)、見える uifigure で本物の timer を動かします。途中で F55 の 1 件(空の系統から GUI で作る 2 母線の図)が失敗し、原因は点の候補がない組(ブランチもリンクもない図など)で `discretize` に辺が 1 つだけ渡っていたことでした。点がないときは計算を飛ばすように直し、F60 に同じ場合を足しました。F59 の「立体がない」の確かめは、流れの点の `patch`(Tag `FlowBranch`、`FlowLink`)を除くように直しました。

画像(コーディネーター向け、セッションの作業フォルダ): IEEE14 の潮流の点の 4 こま(0.15 s ずつ `step_flow`)と、3 秒の動画(25 こま/秒)。

### 11.3 S4(2026-11-17、`feature/graph-controls-net`)

実装したもの(§6 の S4 の行だけ。ほかのメンバーは加えていません):

- `@GraphNetDiagram/control_list.m`(protected)。行の順と内容:

| Group | Property: Widget | Limits / Step | EnableFcn |
|---|---|---|---|
| View | `Dimension`: dropdown、`BusHeightMode`: dropdown | | なし(高さは 2D・3D の両方で効く。Q9) |
| Color | `ColorMode`: dropdown、`ColorLimits`: range | range は [-Inf Inf]、刻み 0.1 | なし |
| Size | `BranchWidthMode`: dropdown、`BranchWidthRange`: range、`MarkerSizeMode`: dropdown、`MarkerSizeRange`: range、`LinkWidth`: spinner | [0.5 20]、[1 30]、[0.5 10]、刻み 0.5 | なし |
| Flow | `FlowMode`: dropdown、`FlowAnimation`: toggle、`FlowSpeed`: slider | slider [0.1 5] | `FlowAnimation` と `FlowSpeed` は `Dimension == "2D"` のときだけ |
| Label | `LabelMode`: dropdown、`LabelFontSize`: spinner | [3 20]、刻み 1 | なし |
| Time | `"<time>"` | | (2 標本以上の図だけ。基底の規則) |

- `@GraphNetMap/control_list.m`(protected): Size の `BranchWidthRange`: range([0.5 20]、刻み 0.5)だけ。色(`s_color`)と矢印(`s_arrow`)はデータなので出しません(Q13)。ラベルを切り替えるプロパティもないので Label の行はありません。
- 宣言した 14 個(GraphNetDiagram)と 1 個(GraphNetMap)のプロパティに `SetObservable`。名前、既定、検査は変えていません。

§5.6 からの変更・補足:

- **プロパティの順を変えないために、ブロックを分けました。** `opt.?GraphNetDiagram` の Name-Value の順(`functionSignatures.json` の順。F34 が作り直しと比べる)はプロパティの順で決まるので、宣言したプロパティを 1 つのブロックに集めると順が変わり、生成物の作り直しが要ります。Appearance を `SetObservable` のブロックと普通のブロックの交互(7 つ)に分け、順はそのままにしました。GUI の書式(`gui_forms.json` と `DrawerOptionDialog` の classdef の行の読み取り)は属性に関係なく同じ値を読みます(F50、F66 で確認)。
- **`EnableFcn`:** ブリーフは流れの 3 つを 2D だけとしていましたが、`FlowMode` は 3D の円錐の向き(`BranchDirection`、`LinkDirection`)も決めるので、3D でも操作できるままにしました。3D で効かない `FlowAnimation`(点がない)と `FlowSpeed` だけを止めます(§5.6 の「`FlowAnimation`: toggle(2D のときだけ)」に `FlowSpeed` を足した形)。
- **Dimension の切り替え:** `create_scene` は `cla(ax, "reset")` で軸の中身を消すだけで、軸と tiledlayout は残るので、パネル(部品のハンドルとリスナーを含む)はそのまま残り、`PostSet` で部品と `EnableFcn` が合わせ直されます。tiledlayout の `OuterPosition`(パネルに譲った位置)も残ります。timer は S2 の規則(`create_scene` が最初に止め、最後に `flow_timer("auto")`)で、何度切り替えても 1 つです(F61 で、見える uifigure と本物の timer で確認)。
- ラベルの文字は英語(G3): Drawing、Bus height、Color、Color limits、Branch width、Width range [pt]、Marker size、Size range [pt]、Link width [pt]、Flow、Animate the flow、Flow speed、Labels、Font size、Time。

テスト: F61 に 8 件(GraphNetDiagram 7 件、GraphNetMap 1 件)を足しました。宣言の行ごとの部品(dropdown 7、スピナー 8、スライダー 1、トグル 1。dropdown の選択肢がプロパティの検査を通ること)、部品 → プロパティと `ChangedFcn`、プロパティ → 部品、範囲のエラーで部品が戻ること、`EnableFcn`(3D で流れの 2 つが off、ほかは on)、パネルからの `Dimension` の切り替えでパネル・部品・軸・位置が残ること、`plot_diagram(Graph=G)` の後もパネルが残ること、`Dimension` の切り替え(4 往復)とトグルで timer が 1 つ・0 になること(F60 と同じく `batchStartupOptionUsed` を隠し、見える uifigure)、`ResultODE.plot_diagram` の時刻のスライダー(`set_time` との 2 方向、`Dimension` の切り替えで表示中の標本が残る)、Parent(uifigure の uigridlayout と uipanel、axes を Parent にした図)。`test_levels.m` に medium 5 件、large 3 件。

画像(コーディネーター向け、セッションの作業フォルダ、`exportapp`): IEEE14 の 2D の `plot_diagram` とパネル、`res.plot_network` とパネル。

### 11.4 S5(2026-11-17、`docs/graph-diagram-2d-pages`)

変えたもの:

- 新しい For Developer のページ `_GUILDAdoc/developer/feature-graphs.html`(「機能: 図」、日英)。図を説明するページがなかったので、機能のページの 8 つの節の形で作りました: `plot_*` と図のクラスの対応、呼び出しの順、2D と 3D(高さは両方)、pt の範囲と全標本の尺度、流れのアニメーションと timer の規則、操作パネルとクラスごとの操作、エラー、拡張のフック(`control_list`、`prepare_frame`、`range_map`)。カードを `database/list_developer.js` の GUI の前に足しました。
- `feature-model-building.html` の図の配置: GraphNetDiagram が読む列(位置、形、経路、接続位置、線の種類。`MarkerSize` と `Color` の列は GraphSpring だけが読む。コードで確認)、高さは `BusHeightMode` で 2D・3D の両方、新しいページへのリンク。
- `notes/graph-base.md`: 単位と範囲の項(§4.2)、§1 の階層、S3・S4 のマージの記録、3D の棒の記述、GraphNetMap の節の GraphNetDiagram の説明。
- `notes/v4-migration.md`: §1.32(削除したプロパティと置き換えの表、3D → 2D の既定)、§1.27 と §1.30 の表の古い名前の行。
- Update log: 機能全体のまとめを 1 件。
- クラスのリファレンス(`class.html` が読む `database/list_Classes.js`)は生成物でコミットしないので変えていません。MATLAB で `GUILDA.doc` を実行するとクラスのヘルプから作り直されます(公開は `GUILDA.publish_doc`)。

GUI のページ(`feature-gui.html`)は GUI の調整役の担当なので変えていません。古い 3D の図の記述はありません(系統図を `GraphNetDiagram` と書いているだけ)。

## 12. 大きな系統での見た目の調整(2026-11-17、`feature/diagram-look`)

講義・GUI・OPF の調整役から報告された IEEE68 などでの見た目の問題(ラベルの重なり、母線の記号が小さい、0〜2 に固定で飽和した色の棒とラベルなし、余白が大きい、LMP の目盛りの桁、小さな 3D の図の題、Live Editor で遅い)を直しました。方針はユーザーの決定(色の範囲はデータから自動、色の棒のラベルも自動、機器のラベルは既定で隠し、母線のラベルは重ならないようにする)です。

### 12.1 API(新しい公開のメンバーは LabelMode の値 1 つだけ)

| メンバー | 変更 |
|---|---|
| `ColorLimits` | 既定を `[0 2]` から `[NaN NaN]`(自動)に。NaN を含む値は自動、有限の値は固定(今までどおり)。型 `(1,2) double` のままなので、GUI の書式が metaclass から読む既定(`"[NaN NaN]"`)も型に合います |
| `ColorbarLabel` | 既定 `""` のまま、意味を「`ColorMode` の量」に。`"I"` → "\|I\| [pu]"、`"P"` → "P [pu]"、`"Q"` → "Q [pu]"、`"Loss"` → "Loss [pu]"、`"user"`・`"none"` → 空。空でない値は優先 |
| `LabelMode` | 値 `"bus"`(母線のタグだけ)を足し、既定に。`"tag"` は今までどおり母線と機器のタグ |
| `MarkerSizeRange` | 既定を `[4 8]` から `[5 10]` pt に(下の 12.4) |

私用で足したもの: プロパティ `rv_climAuto`、メソッド `color_values`(全標本の色の値。`reflect_color_mode` もこれを使う)、`update_color_scale`(自動の範囲。`load_data` と `ColorMode` の setter)、`color_limits`(使う範囲)、`fit_axes`(軸の範囲とラベル)。`sct_plt` に `DrawBox`、`NodeLabelXYZ`、`CompLabelXYZ`、`CompLabelArgs`。

### 12.2 色の範囲と目盛り

- 自動の範囲は全標本・ブランチとリンクの色の値から、上の外れ値を除いて決めます(2026-11-17 のユーザーの決定。最初は最大にしていた): m を |値| の 95 パーセンタイルとして、大きさ(`"I"`、`"Loss"`)は `[0, m]`、符号つき(`"P"`、`"Q"`。ブランチの値は大きさでも機器の注入は符号つき)は `[-m, m]`、`"user"` は設定した色の値の 5〜95 パーセンタイル(意味が分からないデータなので、0 を含めない)。範囲の外の値は端の色です。
- パーセンタイルは最近順位法(小さい方から `ceil(q·n)` 番目。ツールボックスを使わず、決定的)で、私用の static `color_percentile` が計算します。値が 20 個未満なら最大(5 パーセンタイルは最小)、95 パーセンタイルが 0 か有限でなければ最大、`"user"` で 5 と 95 が同じなら `[最小, 最大]`。値がない・最大が 0 なら `[0 1]` か `[-1 1]`。
- `apply_style` の最初で `color_limits()` を軸の `CLim` と比べ、変わっていれば `clim` を設定してすべての要素を塗り直します(自動の範囲が `ColorMode`・`"user"` の色の値・`set_data` で変わる場合をまとめて扱う)。色の棒のラベルも `apply_style` が書きます。
- 目盛り: 範囲の幅が大きさの 1e-6 以下(丸めの差しかない場)なら、中央 c の `c(1 ∓ 1e-3)`(c = 0 なら `[-1, 1]`)で表します。固定の値にも使います(固定の `[2 2]` もエラーにしない)。`plot_lmp` は価格がほぼ同じとき `[3.1, 3.100000004]` のような範囲を渡していた(幅/値 ≈ 1e-9 で `plot_lmp` 自身の 1e-9 の判定を通る)ので、目盛りが 3.099999999〜3.100000004 になっていました。GraphNetDiagram 側の判定で 3.097〜3.103 の 7 つの目盛りになり、`plot_lmp` は変えていません。1e-6 を超える本当の差(たとえば 1e-4)はそのまま写し、MATLAB の自動の目盛り(3.1、3.1001 など)に任せます。
- IEEE68 の潮流では、自動の範囲は `[0 24.7]` pu です(95 パーセンタイル)。最大で決めていたときは `[0 63.2]` pu で、最大は B017 の負荷のリンクの電流でした(ブランチの最大は ET013 の 36.6 pu、中央値 3.1 pu、10 pu を超えるブランチは 83 本中 7 本)。その範囲ではブランチの多くが色の棒の下の方(濃い青)になったため、ユーザーが外れ値を除くことに決めました。24.7 pu を超えるブランチ(B013–B017–B036、B016–B018 など)とリンクは最上の色です。

### 12.3 ラベルと軸

- 機器のラベルのテキストは、`LabelMode` が表示するとき(`"tag"`、`"value"`、`"user"`)に `reflect_node_label` が作ります(2D・3D とも。位置と書式は描画のときに `CompLabelXYZ`、`CompLabelArgs` に残す)。非表示のテキストも Live Editor の取り込みに時間がかかるため(12.5)。母線のラベルは今までどおり描画のときに作ります(`"none"` では非表示)。
- `fit_axes`(`create_scene` の最後、`LabelMode` と `LabelFontSize` の setter): 軸の範囲は図の箱(母線の中心と棒の両端、機器、ブランチとリンクの経路の点)に、その長い辺の 3% の余白です(2D・3D)。以前の「少なくとも [0 1]、5% + 0.05」をやめたので、座標が 0.25〜0.9 の IEEE14 でも余白が小さくなりました。2D では表示するラベルを元の位置(`NodeLabelXYZ`、`CompLabelXYZ`)に戻し、`GraphBase.resolve_overlap`(縦にずらす、50 回まで)で重なりをなくし、ラベルの箱が入るまで範囲を広げます。範囲を広げると座標でのテキストの長さが変わるので、範囲が変わらなくなるまで最大 3 回くり返します。
- テキストの箱は、そのときの軸の範囲と画素の大きさで測ります(`drawnow` は呼ばない)。軸の範囲や大きさが後で変わったときは、自動で配置し直します(§13。以前は描き直しが必要でした)。3D はテキストの箱が視点で変わるので、ずらしません。
- 2D の描く順を「機器 → 母線」に変えました(母線のすぐ横に置いた機器の記号の上に母線を描く。IEEE68 では機器が母線にほとんど重なっていた)。

### 12.4 大きさ(数値)

`MarkerSizeRange` の既定を `[5 10]` pt にしました(`MarkerSizeMode="none"` では中央)。

| 系統 | 母線の記号 | 以前 | 機器 |
|---|---|---|---|
| IEEE68(点の母線 square) | 7.5 pt の四角 | 6 pt | 7.5 pt(以前 6) |
| IEEE9(点の母線 square、配置なし) | 7.5 pt の四角 | 6 pt | 7.5 pt |
| IEEE14(棒の母線 hbar/vbar) | 棒の太さ 3.75 pt(大きさの半分) | 3 pt | 7.5 pt |

棒は長さが座標なので太さだけが変わり、IEEE9/14 では控えめのままです。3D は基準の 6 pt から倍率で描くので同じ範囲に従います。`GraphNetMap` の母線の既定 6 pt は変えていません。

### 12.5 Live Editor の時間

測り方: `matlab.internal.liveeditor.executeAndSave` で .mlx を実行し(R2026a、`-batch`)、各セクションの最初と最後の時刻をファイルに書いて、「セクション」(コードの実行)と「取り込み」(次のセクションの開始までの時間。Live Editor が図を取り込む時間)に分けました。同じ .mlx を変更前(a9031c45 の worktree)と変更後で 2 回ずつ実行した値(2 回目の呼び出し、単位 s)です。

| 図 | 変更前 セクション + 取り込み | 変更後 セクション + 取り込み |
|---|---|---|
| IEEE9(最初の図、冷えた状態) | 1.30 + 1.24 = 2.5 | 1.47 + 1.08 = 2.6 |
| IEEE9 | 0.37 + 0.86 = 1.2 | 0.36 + 0.78 = 1.1 |
| IEEE14 | 0.33 + 1.15 = 1.5 | 0.39 + 0.97 = 1.4 |
| IEEE68 | 0.59 + 2.93 = 3.5 | 0.88 + 2.29 = 3.2 |

分かったこと:

- **時間の大半は Live Editor の取り込みで、図のオブジェクトの数に比例します。** 比べるための図: 線 40 本とテキスト 20 個の図で 0.55 s、tiledlayout と色の棒だけで 0.78 s。IEEE68 では、テキストを全部消すと 3.6 → 1.9 s、さらにリンクを消すと 1.7 s。テキスト 1 つで約 14 ms(119 個で 1.7 s)、線 1 本で約 5 ms(リンク 51 本で 0.26 s)です。**非表示のテキストも同じだけかかります**(`LabelMode="none"` で 4.5 s)。datacursormode を切ると IEEE68 で約 0.4 s 減りましたが IEEE9 では差がなく、データチップの機能を残すため変えていません。`ButtonDownFcn` と `UserData` を消しても変わりません。取り込みそのものは GUILDA の外です。
- 変更でしたこと: 機器のラベルを表示するまで作らない(IEEE68 で 51 個減り、取り込みが約 0.6 s 減る)。代わりに 2D のラベルの重なりをなくすためにテキストの箱を測るので、セクションが IEEE68 で約 0.3 s 増えます(最初の `Extent` の取得で図のテキストの配置が計算される。この計算は後の描画・取り込みでも必要なものが前に出ただけ)。`resolve_overlap` の箱は 1 回の `get(hv, "Extent")` で測ります(1 つずつ `Extent` を読むと 1 つ約 2 ms)。
- セクションの内訳(IEEE68、-batch、2 回目): `struct(net, false)`(`@LayerPackage/private/snapshot`)0.39 s、`set_network` 0.23 s、`create_scene` 0.49 s(うち `fit_axes` 0.23 s)。スナップショットはモデルの側のコードなので変えていません。
- IEEE9 は母線の位置がない(`X`、`Y` が NaN)ので、毎回 `tools.layout_place_buses` が見えない figure に MATLAB の force の配置を描いていました(冷えた状態でその figure の作成に約 1 s、温まっても約 0.1〜0.2 s)。配置は決定的なので、グラフごとの結果を persistent に 20 個まで残すようにしました(同じセッションでもう一度描くと figure を作らない)。最初の 1 回は変わりません。IEEE9 のデータに位置を入れれば、この処理はなくなります(モデルの調整役に提案)。
- 報告の「IEEE9 で約 7 s」は、この測り方では再現しませんでした(冷えた状態で 2.5 s、見える figure の `drawnow` を含めても 4.6 s)。残りは Live Editor の画面への表示(この測り方の外)と、最初のセッションの読み込みと思われます(未確認)。また、本物の Live Editor で図が `Visible="on"` なら流れのアニメーションの timer が動き、こまごとの図の変更を取り込み直す可能性があります。`executeAndSave` では figure が見えないので timer は作られず、確かめられていません(要確認)。

### 12.6 3D の題

S1 で未対応だった「3D で図が 400×300 以下だと題が左端にかかる」は、軸の範囲を図の箱 + 3% にしたことで 3D の描画が軸いっぱいになり、題が図の中に収まるようになりました。F59 の `plot_lmp` の確かめに 3D 400×300 を足しました。

### 12.7 GraphBase の操作パネル

自動(NaN)にできる range の行は、`control_list` の `Items` に使っている値を返す関数 `@(G) [a b]` を書きます。その行には 2 つのスピナーの右に Auto のチェックボックスが付き、チェックで `[NaN NaN]`、外すとスピナーの値(チェック中はスピナーが使っている値を出すので、外した時点の自動の範囲)を設定します。スピナーを変えると固定の値になり、チェックは外れます。GraphNetDiagram の `ColorLimits` は `@(G) G.ax(1).CLim`。

### 12.8 テストと画像

- F59: 自動の色の範囲(大きさ・符号つき・全標本の 95 パーセンタイル・固定・NaN で戻る・`ColorbarLabel`・`"user"` の 5〜95 パーセンタイルと 20 個未満、1 つの外れ値(ブランチの色の値、機器 1 つの電流 100 倍)が上限を決めず最上の色になること)、ほぼ一定の場の目盛り、`LabelMode="bus"` の既定と IEEE68(560×420・1000×750)・IEEE14 で母線のラベルの箱が重ならないこと、軸の範囲、`plot_lmp` の 3D 400×300。既定の大きさの確かめを [5 10] に。F61: `ColorLimits` の Auto のチェックボックス。F66: `ColorLimits` の書式の既定 `"[NaN NaN]"`。F46: コメントの既定の大きさ。`test_levels.m` に medium 4 件、large 1 件。
- 画像(コーディネーター向け、セッションの作業フォルダの `png/`): `before_*.png` と `after_*.png` の組で、IEEE68 の 2D(潮流の後、560×420 と 1000×750)、IEEE14 の 2D、IEEE9 の `plot_lmp`(DC・AC、3D 400×300)。

## 13. ラベルの配置し直しと白い流れの点(2026-11-18、`feature/diagram-look`)

ユーザーの報告と依頼: 「GUI で画面を移ると、タグ(ラベル)の位置がよくずれる」(主に `GUILDA.launch_gui` の左の図)、「流れの黒い矢印を白に」。

### 13.1 原因(確認済み)

- 2D の母線のラベルは、`fit_axes` が描いたときに 1 回だけ縦にずらして重なりをなくしていました(`resolve_overlap`、§12.3)。ずらす量はデータの単位ですが、テキストの箱の大きさ(データの単位)は軸の範囲と画素の大きさで決まります。描いた後に範囲や大きさが変わると、ずらした量が合わなくなり、ラベルが母線から離れたり重なったりします。
- 原因になる変化は 3 つありました:
  1. **uifigure の配置は非同期。** `plot_diagram` の時点では uipanel の大きさがまだ決まっていない(IEEE68 で 134×154 px など)。その小さな軸で重なりをなくすので大きくずらし、その後の本当の大きさ(579×418 px)ではラベルが母線から最大 30 行ぶん離れていました。
  2. **GUI が範囲を変える。** `@DrawerGUILDA/redraw.m`(98〜107 行)が描くたびに `axis tight` と 4% の余白を設定します。
  3. **GUI がパネルの大きさを変える。** Display options の列(0 ↔ 230 px)、Hide log の行(130 ↔ 0 px)、ウィンドウの大きさ。
- タブを移ると図を描き直すので、そのときの大きさでまた別のずれ方になり、「画面を移ると位置がずれる」ように見えました。`GUILDA.launch_gui(network.IEEE68bus())` を見える状態で動かして確かめました(下の表。値は母線のラベルの元の位置からの縦のずれの最大を、テキストの高さの何行ぶんかで表したもの)。

| 操作 | 変更前 | 変更後 |
|---|---|---|
| 起動直後(Model) | 29.7 行 | 0 |
| Power flow のタブ | 4.6 行 | 0 |
| OPF・CPF のタブ | 29.7 行 | 0 |
| Model に戻る、Display options、Hide log、ウィンドウを縮める | 0 | 0 |

IEEE14 では起動直後 2.2 行、変更後 0。どの場合も重なりは 0 です。

### 13.2 直し方

- `fit_axes` に私用の引数 `s_mode` を足しました。`"fit"`(既定、今までどおり範囲を合わせてラベルを入れる)と `"labels"`(範囲はそのままで、ラベルを元の位置に戻して重なりをなくすだけ)。
- `fit_axes` は配置したときの「軸の見え方」(`XLim`、`YLim`、軸の画素の幅と高さ)を `sct_plt.LabelView` に、自分で設定した範囲を `sct_plt.FitLim` に残します。
- 軸の `MarkedClean` イベント(軸が描かれた後に出る)にリスナーを 1 つ付けます(私用プロパティ `lis_labelAxes`、`matlab.lang.WeakReference` で図を持つ)。描かれるたびに見え方を比べ、変わっていれば配置し直します。範囲が `FitLim` のままなら `"fit"`(新しい大きさに範囲も合わせ直す)、外から変えられていれば `"labels"`(GUI やズームの範囲を尊重する)。
- `SizeChanged` のリスナーは使いませんでした。uipanel と uifigure には `SizeChanged` イベントがあるものの、R2026a で uigridlayout の列幅やウィンドウの大きさを変えても、リスナーには届きませんでした(確かめた)。`MarkedClean` は範囲の変更、大きさの変更、隠れたタブの表示のどれでも出ます。
- 間引き: 1 回の描画の前の複数の変化(`XLim` と `YLim` を別々に設定するなど)は 1 回の配置になります。変化がないときの確かめは `getpixelposition` 1 回(約 0.14 ms)で、流れのアニメーションの毎こまでも負担になりません。配置し直している間は私用の `l_labelBusy` でリスナーを止めます(配置でテキストを動かすと再び `MarkedClean` が出るため)。
- 可視性はキーに入れていません。隠れたタブを表示すると画素の大きさが変わるので、それで配置し直されます(確かめた)。大きさが同じなら箱も同じです。
- 失敗したときは `GUILDA:GraphNetDiagram:LabelLayout` の警告を出します(メッセージを `en/GraphNetDiagram.xml` に追加)。
- 新しい公開のメンバーはありません。私用のプロパティ 2 つ(`lis_labelAxes`、`l_labelBusy`)、`fit_axes` の私用の引数、`sct_plt` のフィールド 2 つ(`LabelView`、`FitLim`)、流れの patch の `UserData`(`struct("Type", "Flow", "Index", 面ごとの要素)`)です。

### 13.3 GUI への提案(GUI の調整役へ。GUI のファイルは変えていない)

- `@DrawerGUILDA/redraw.m` の 98〜107 行(`axis(ax, "tight")` と 4% の余白)は**消すのがよい**です。
  - この処理は「範囲が少なくとも [0 1] になる」以前の動作のためのものでした。§12.3 で `fit_axes` が図の箱 + 3% にしたので、もう要りません。
  - 残すと、`fit_axes` がラベルのために広げた範囲を切ってしまい、上下の端のラベルが軸の外にはみ出します(テキストは切り取られないのでパネルには描かれる)。また範囲が「外から設定されたもの」になるので、パネルの大きさが変わっても範囲を合わせ直さず、ラベルだけを動かします。
  - 消せば、図は描いたときもパネルの大きさが変わったときも、図の箱 + 3% にラベルを入れた範囲になります。代わりに呼ぶものはありません。
- 余白を設定する公開のメンバー(`Padding` など)は、今は**足さない**ことを勧めます。GraphBase に余白に関係するメンバーはなく(`fit` もない)、GUI が `axis tight` をやめれば 3% で足ります。4% にしたい場合など、必要になったら `AxesPadding`(図の箱の長い辺に対する割合、既定 0.03)を提案します(ユーザーの承認が要る)。

### 13.4 テストと画像

- F59 に 2 つの節:
  - 「Labels stay next to their elements after the limits and the size change (GUI)」: GUI と同じ入れ子(uifigure → uigridlayout → 1x/0 の列 → uipanel)の IEEE68 で、描いた後、`axis tight` + 4%、操作パネルの列を 230 px、閉じてログの行を 0、figure を縮める、のそれぞれでラベルが重ならず、元の位置から縦に 3 行以内・横はそのまま。外から設定した範囲が残ること、同じ大きさ・範囲で描き直した図と同じ位置(変化の順によらない)、範囲を外から変えていない図は大きくすると範囲もラベルに合わせ直すこと。uifigure の配置は非同期なので、(大きさを変えたときは軸の画素の大きさが変わるのを待ってから)範囲と大きさが 0.3 s 変わらず、ラベルがその範囲と大きさで配置されるまで待ちます(`wait_layout`、最大 5 s ずつ)。変更前のコードでは「描いた後: ラベルが母線から 17.1 行離れた」で失敗します。
  - 「A diagram drawn in a hidden tab lays its labels out when the tab is shown」: 隠れた uitab に描いて表示する。変更前のコードでも通る(この場合は描いたときの大きさが表示後と同じだった)ので、退行の確かめです。
  - どちらも uifigure の配置を待つので 1 件 4〜13 s かかり、`test_levels.m` に large で登録しました(F59 の IEEE68 のラベルの節と同じ)。
- F60: 点が白・縁が暗い灰色・0.5 pt で、線の色を変えても白のままであること。点の数・間隔・進みを測るときの要素の見分けを、色から `UserData.Index` に変えました(重なる経路の上の点は形では見分けられないため)。
- 画像(セッションの作業フォルダの `png/`。コーディネーター向け): `before_ieee68_app_*.png` / `after_ieee68_app_*.png`(`GUILDA.launch_gui` の起動直後・Display options・縮めた後。IEEE14 も同じ名前で)、`before_ieee68_[0-3]_*.png` / `after_ieee68_[0-3]_*.png`(GUI と同じ入れ子の手順)、`before_flow_*.png` / `after_flow_*.png`(IEEE14 の流れのこま、拡大、書き出した動画の 2 こま目)。


## 14. 描画の速さ(2026-11-18、`feature/diagram-look`)

コーディネーター経由の依頼: GUI が遅い。GUI の調整役の測定では `plot_diagram` が大半(uifigure の新しい uipanel で IEEE14 2.3 s、IEEE68 4.0 s、`Graph=G` の描き直しも同じくらい。忙しいマシンなので相対値)。目標は IEEE68 で新しい描画・描き直しとも 1 s 未満。

### 14.1 測り方と内訳

見える uifigure(uifigure → uigridlayout → uipanel、GUI と同じ)で、同じ系統を 3 回ずつ描いて測りました(R2026a、このマシン。1 回目はセッションで最初の描画でクラスの読み込みなどを含む)。内訳は `profile` の行ごとの時間と、`create_scene` に一時的に入れた `tic`/`toc`(実時間)です。

IEEE68 の 1 回の新しい描画(変更前、実時間の目安):

| 部分 | 時間 | 中身 |
|---|---|---|
| `struct(net, false)` | 0.25〜0.55 s | すべての層のすべてのプロパティを写す。`tab_parameter` の getter(表を作る)、`rv_Uoffset`、`get_variable_map`、制御器など。図が読むのはその一部(読むだけなら 0.04 s) |
| `fit_axes` | 0.24 s | ラベルの `Extent` を 1 回の描画で最大 6 回取得(取得のたびにテキストの配置を計算。uifigure では遅い) |
| `draw_diagram_2d` | 0.125 s | 要素ごとの `line`(約 300 本)と母線のラベル 68 個。同じ数の線とテキストを素の MATLAB で作ると 0.11 s で、ほぼ下限 |
| `set_network` | 約 0.1 s | `tab_parameter` の部分表を縦につなぐ(`vcellfun`)、配置 |
| `apply_style` | 0.06 s | 全要素の色・大きさ、色の棒 |
| `cla reset` | 0.036 s | |
| `drawnow` | 0.2〜0.3 s | 描画そのもの(MATLAB 側)。同じ数の線とテキストの素の図でも 0.23 s |

### 14.2 したこと

1. **`PowerNetwork.plot_diagram` の軽いスナップショット。** `struct(obj, false)` の代わりに、`GraphNetDiagram.set_network` が読むフィールドだけの同じ形の構造体を作ります(網: `class`、`s_tag`、`a_Bus`、`a_Branch`。母線: `class`、`s_tag`、`s_bustype`、`tab_parameter`、`a_Component`。機器: `class`、`s_tag`、`tab_parameter`。ブランチ: `class`、`s_tag`、`tab_parameter`、`a_Bus`(`"net.a_Bus{i}"`)、`cm_Y`)。`GraphNetDiagram` の契約(`struct(net, false)` を受ける)はそのままで、`ResultPF`/`ResultODE` の `plot_diagram` は持っているスナップショットを使うので変わりません。F59 で、軽いスナップショットと `struct(net, false)` から描いた図が同じ(要素、範囲、色、幅)ことを確かめます。
2. **ラベルの箱を 1 回だけ測る。** `fit_axes("fit")` は `Extent` を 1 回だけ取得し、テキストの位置からの箱を画素の単位で残します。範囲を広げた次の回は、データの単位 / 画素(`max(dx/幅, dy/高さ)`。データの縦横比が 1 なので)を掛けて箱を計算します。`GraphBase.resolve_overlap`(protected static)に、測った箱を渡す省略可能な入力と、動かした後の箱を返す出力を足しました(`GraphSpring2D` の呼び出しはそのまま)。F59 の IEEE68 のラベルの節は、本当の `Extent` で重ならないことを確かめていて、通ります。
3. **`Graph=G` の描き直しでオブジェクトを残す。** `GraphBase.set_data` は、`create_scene` の間だけ前の描画を protected の `sct_pltPrevious` に残します(終われば、エラーでも、空に戻す)。2D の `GraphNetDiagram.create_scene` は、形(`diagram_geometry`)、タグ、母線・ブランチ・機器の graph のパラメーター、`LinkWidth`、ラベルのフォントが前と同じ(`sct_plt.ReuseKey`、`isequaln`)で、前のオブジェクトがすべてその軸にあれば、`cla` と線・ラベルの作り直しをせず、色、大きさ、ラベル、流れの点、範囲だけを設定し直します。違えば今までどおり描き直します。F59 で、同じオブジェクトが残る・数が増えない・`set_style` と選択が残る・新しい `ColorMode` で塗り直す・同じ大きさの軸に新しく描いた図と同じ色・幅・範囲、別の系統では描き直して古いオブジェクトが残らない、を確かめます。

公開の API は変わりません(新しいメンバーは GraphBase の protected プロパティ `sct_pltPrevious` だけ)。

### 14.3 結果(見える uifigure、このマシン、2〜3 回目)

| | 変更前(a0d0d22b) | 変更後 |
|---|---|---|
| IEEE14 新しい描画 | 0.37〜0.48 s(+drawnow 0.53〜0.64) | 0.30〜0.35 s(+drawnow 0.46〜0.50) |
| IEEE14 `Graph=G` | 0.34〜0.38 s(+drawnow 0.39〜0.44) | 0.22〜0.23 s(+drawnow 0.26〜0.27) |
| IEEE68 新しい描画 | 0.63〜0.67 s(+drawnow 0.82〜0.88) | 0.49〜0.50 s(+drawnow 0.68〜0.73) |
| IEEE68 `Graph=G` | 0.67〜0.68 s(+drawnow 0.74〜0.76) | 0.29〜0.34 s(+drawnow 0.33〜0.41) |

セッションで最初の描画は IEEE14 で 1.2〜1.4 s(+drawnow 1.5〜1.8)、IEEE68 で 0.8〜0.9 s(+drawnow 1.05〜1.2)かかります(クラスの読み込み、uifigure の最初の軸とツールバー。GUILDA の外)。GUI の調整役の 2.3 s / 4.0 s との差の多くはマシンの忙しさとこの初回の分と思われます(未確認)。

### 14.4 まだ残るもの(提案、未実装)

- **線を種類ごとに 1 つのオブジェクトにまとめる**(NaN で区切る)と、`draw_diagram_2d` の 0.125 s と `drawnow` の一部が減る見込みです。ただし要素ごとの色・幅・表示(`apply_style`、`set_style`)、クリック(`ButtonDownFcn` と `UserData` の要素)、選択の重ね描き、データチップ、テスト(`sct_plt.EdgeMain(k)` などのハンドル)をすべて作り直す大きな変更です。`Graph=G` はもうオブジェクトを作らないので、効くのは新しい描画だけです。やるなら別の作業として仕様から。
- `set_network` の表の連結(約 0.1 s)は `table` の縦の連結の費用で、配列にすると減りますが、`tab_bus` などの表はほかの多くのメソッドが使うので効果に比べて変更が大きいです。

### 14.5 GUI への API(GUI の調整役へ)

- `@DrawerGUILDA/redraw.m` の `axis tight` と余白(98〜107 行)は消してください(§13.3)。代わりに呼ぶものはありません: `plot_diagram` が図の箱 + 3% にラベルを入れた範囲にし、範囲がそのままならパネルの大きさが変わるたびに合わせ直します(§13.2)。
- 描き直しは今までどおり `net.plot_diagram(Graph=G, State="auto", …)`(`res_pf.plot_diagram(Graph=G, …)` も同じ)で、同じ系統ならオブジェクトが残って速くなります。`delete(h_parent.Children)` してから `Parent=` で描くと新しい描画になり遅いので、図を残せる場合は `Graph=G` を勧めます。
- 余白を決める公開のメンバーは足していません。必要なら `AxesPadding`(図の箱の長い辺に対する割合、既定 0.03)か、範囲を合わせ直す公開メソッド `fit()`(GraphNetDiagram の私用 `fit_axes("fit")` を呼ぶ。ズームの後などに)を提案します(ユーザーの承認が要る)。

## 15. large の F46・F47 の失敗(2026-11-18、`feature/diagram-look`)

開発ブランチ(fe3feb69)で large の F46 `set_styleByTagAndByVectorGiveTheSameGraphics` と F47 `ClickingAnElementRaisesElementClickedAndCallsElementClickedFcn` が失敗していました。どちらも e8775954(§13・§14)より前からの失敗で、e8775954 の第 1 親(054b46d3)でも同じく失敗します(確認済み)。

### 15.1 原因(確認済み)

- **F47: `delete(G)` で図が消えない。** フロー動画のマージ(33f55e29)で足した `GraphNetDiagram.delete` に `arguments` ブロックがありました。MATLAB は `arguments` ブロックのある `delete` をデストラクタとして扱わず、普通のメソッドとして呼ぶだけなので、`delete(G)` の後も `isvalid(G)` が true のままで、古い線のクリックが `ElementClickedFcn` を呼んでいました(最小のクラスで再現。33f55e29^1 は通り、33f55e29 から失敗)。
- **F46: 隠れた機器のラベルの text が無い。** 機器のラベルを表示するまで作らない変更(00c5e603、§12 の LabelMode "bus")の後、既定の "bus" で `set_style(tag, Label=...)` や `ComponentLabel` で設定したラベルは、text が無いので `apply_style` が書かずに飛ばしていました。テストは `sct_plt.CompLabel(i).String` を読むので `GraphicsPlaceholder` のエラーになりました。表示は変わりません("user" に切り替えると設定したラベルで作られる)。

### 15.2 直し方

- `GraphNetDiagram.delete` の `arguments` ブロックを外しました(理由をコメントに書いた)。同じ書き方の `ProgressGUILDA.delete` も同じ不具合があるはずですが、図の外なので変えていません(別の作業)。
- 機器のラベルは必要になったときに作ります: LabelMode が表示するとき(今までどおり)と、利用者がラベルを設定したとき(`set.ComponentLabel`。`set_style` の Label もここを通る)。設定した行だけを隠れた text として作り、LabelMode が表示を決めます。`reflect_node_label` が LabelMode のラベルを書くときは作りません(私用のフラグ `l_labelAuto`)。作る処理は私用メソッド `make_component_labels(obj, iv_comp)` にまとめました。"bus" の既定で機器のラベルを作らない速さ(§14)は変わりません。
- 公開のメンバーは足していません。

### 15.3 テスト

- F59 に「設定した機器のラベルは表示の前に text ができる」を足しました(medium): 設定した行だけ作る、隠れたまま、`LabelFontSize`、"bus" での書き直し、"user"、3D への描き直し、"none"。F47 に `delete` の後 `~isvalid(D)` を足しました。
- graph の large と graph・gui の medium の結果はセッションの報告にあります。

## 16. Loss の色の値を厳密な損失に(2026-11-20、`fix/diagram-loss-exact`)

- `ColorMode="Loss"` の値を `R|I_from|^2` から、両端からブランチへ流れ込む有効電力の和 `P_from + P_to`(`S_end = V_end·conj(I_end)`)に変えました。線路の充電容量と変圧器のタップを含みます。`color_values.m` の "P" と同じ `cm_Vbus2Vbranch * cm_V` と `cm_Ibranch` から作ります。
- 端の値が NaN なら 0 として足し、両端 NaN は NaN です。`|v| < 1e-12*max(1, |P_from| + |P_to|)` は 0 にします(損失のない変圧器の丸めの負の値)。`max(v, 0)` は使っていません(大きな負の値が出たら隠さないため)。
- IEEE68 で変化の大きい 5 本(前 → 後 [pu]): B040-B041 0.1235 → 0.1429、B042-B018 0.0142 → 0.0083、B018-B050 0.0912 → 0.0865、B041-B042 0.0397 → 0.0354、B004-B019 0.0281 → 0.0322。和は 1.6587 → 1.6683 で、潮流計算の全損失(`tab_branch.Ploss` の和、注入の和)と一致します。
- テスト: F59 `LossColorsAreTheExactBranchLossesOnIEEE68`(medium)。片端で開いたブランチは `c_Ybranch` で与えて有限、NaN の端は 0 も確認します。

## 17. 機器の印もカラーマップで塗る(2026-11-20、`fix/diagram-component-color`)

- ユーザーの指摘: 解析結果の図で、カラーマップを使うのに機器の印が種類の色(発電機は金色など)のままで紛らわしい。
- `ColorMode` が `"I"`、`"P"`、`"Q"` のとき、`reflect_color_mode` が `ComponentColorData` を接続線の値(`LinkColorData` と同じ)にします。同じ colormap と `ColorLimits` で塗ります。自動の範囲はもともとブランチと接続線の値から決めており、機器の値は接続線と同じなので変わりません。
- カラーマップを使っているとき(`ColorMode` が `"none"` でなく、有限の色の値を持つ要素があるとき)、値が NaN の機器(`"Loss"`、停止した機器、`"user"` の NaN の行)は黒です(2D の縁も 0.6 倍で黒)。`"none"` では `ComponentColorData` を NaN にし、種類の色(`CompColor0`)のままです。`ComponentColor` の行は今までどおり優先します。
- この状態が変わったときは `apply_style` がすべての機器を塗り直します(`sct_plt.CompColormap` に前の状態を持つ。公開メンバーは増やしていません)。2D と 3D、`set_time`、`Graph=G` の描き直し(`create_scene` が全要素に `apply_style`)で同じです。
- テスト: F59 `ComponentsTakeTheColormapColorOfTheirLinksAndAreBlackWithoutAValue`(medium)。

## 18. 色で描いた値を読めるようにする(2026-11-22、`feature/diagram-value-readout`)

- ユーザーの要望: 地図に色で描いた値(LMP、損失、電流など)は、すべてデータチップかラベルで数値として読めること。
- データチップ: `create_scene` の `customhover` が、タグの行の下に「`<名前> = <値>`」を 1 行加えます(先頭にその色の四角 `\color[rgb]{…}■`)。値は表示中の標本で要素を塗っている値です。母線は `BusColorData`、ブランチは `BranchColorData`(`"I"`/`"P"`/`"Q"`/`"Loss"` では `reflect_color_mode` が入れたその量)、機器は `ComponentColorData`、接続線は `LinkColorData` です。書式は `%.5g`(有効数字 5 桁。`%.4g` では LMP 3901.6 が 3902 になるため 2026-11-23 に変更)、NaN(行がないときも)なら行を出しません。
- 名前はカラーバーのラベルです。`ColorbarLabel`、`""` なら `ColorMode` の量(`"|I| [pu]"` など)、どちらもなければ `color`。新しい private メソッド `color_readout` が名前・値・行を作り、`apply_style` のカラーバーのラベルもこれを使います(ローカル関数 `color_label` は削除)。公開メンバーは増やしていません。
- 重複の扱い(決めたこと): 同じ量がデータチップの下にあっても(`"I"` の from 端の |I|、`"Loss"` の P_loss、機器の P・Q)、この行は省きません。いつもタグの下の同じ場所に、カラーバーと同じ名前と色の四角で「色の値」として出すので、見分けられます。量ごとに省く規則にすると、`"P"` のブランチ(両端の |P| の平均)や `"Q"`(|Q_from + Q_to|)のように下の行と少しだけ違う量で、どれが色の値か分かりにくくなるためです。
- ラベル: `LabelMode="value"` では、母線(∠V、|V| の後)と機器(P、Q の後)のラベルの最後に「` <名前>=<値>`」を加えます(有限のときだけ)。ブランチにはラベルがありません。`reflect_node_label(obj, iv_bus, iv_comp)` に書く行を渡せるようにしました。
- |V| の重複(2026-11-23 修正): 母線の色の値が |V| か ∠V のとき(`BusColorMode` が `"V"`/`"angle"`、または `ColorMode="user"` で `ColorbarLabel` が空白を除いて `|V|`/`∠V` で始まるとき。`ResultOPF.plot_iteration` は `"|V| [pu]"`)、`"value"` ラベルは固定の「`|V|=`」(または「`∠V=`」)の行を省き、色の行だけを残します。色の値が NaN の母線は固定の行を残します。データチップは変えていません。
- 追従: `set.BusColorData` と `set.ComponentColorData` は変わった行だけ、`set.ColorbarLabel` と `set.ColorMode` はすべての `"value"` ラベルを書き直します(ローカル関数 `refresh_value_labels`)。行が増減したラベルがあれば 2D では配置し直します(範囲が `fit_axes` のままなら "fit"、外から設定した範囲なら "labels")。`TimeChangedFcn` で `BusColorData` を変える図(`ResultOPF.plot_iteration`)でもラベルが追従します。
- ResultLIN: `section_diagram` の `datatip_wrap`(`bus_text`)が母線の行「`<s_value>: <値>`」を末尾に足すので、plot_kernel と plot_participation の母線のデータチップには同じ値が 2 回出ます(例: `left kernel at \theta = 0.1167` と `Left kernel at \theta: 0.1167`、`participation = 0.8121` と `Participation in the mode: 0.8121`)。ResultLIN は編集していません。線形化の調整役が wrapper を外し `ColorbarLabel` を設定すれば 1 行になります。
- 結果メソッドの既定: `ColorMode="user"` や `BusColorData` で母線・機器を塗るのは ResultOPF(plot_lmp、plot_iteration)と ResultLIN だけでした。ほかに変えたメソッドはありません。plot_lmp・plot_iteration の `LabelMode="value"` の既定は OPF の調整役が変えます。
- テスト: F59 `TheDataTipOfABusGivesItsColorValueNamedByColorbarLabel`、`TheDataTipOfABranchWithColorModeLossGivesTheColoredLoss`、`TheNameOfTheColorValueFallsBackToTheLabelOfColorMode`、`LabelModeValueLabelsEndWithTheColorValueOfBusesAndComponents`、`LabelModeValueLabelsFollowBusColorDataSetByATimeChangedFcn`(すべて medium)。

## 19. 3D の母線の高さを読めるようにする(2026-11-22、`feature/bus-height-readable`)

ユーザーの指摘: `Dimension="3D"` で `BusHeightMode` を使うと、母線が宙に浮いているように見え、高さを直感的に読めない。`BusHeightMode="none"` の図は今のまま変えない。

### 19.1 原因(確認済み)

- 最初の描画が真上から見るので、高さがまったく見えない(変更前の画像は `"V"` でも `"none"` とほぼ同じ)。
- z が量の値そのもの(|V| ≈ 1)で、`daspect [1 1 1]` のため、IEEE9 の |V| の差(約 0.08)は配置の幅(約 1)に比べて小さすぎる。逆に P は数十 pu で、配置より何十倍も高い塔になる。
- 地面も目盛りもないので、どの高さが基準か分からない。

### 19.2 設計(採用)

- **尺度(3D だけ):** 基準 ref(`"V"` は 1 pu、`"angle"`・`"Vimag"`・`"P"`・`"Q"` は 0)を中心に `z = ref + scale·(値 − ref)`。scale は全標本の値と ref が span の 4 分の 1 に収まるように決める(全部同じなら 1)。`diagram_geometry` が 3D のときだけ掛け、`sct_g.sct_height`(Ref、Scale、Lim)を返す。2D の z は値のまま(Q9、F59 の 2D の高さのテストはそのまま通る)。
- **床:** 全標本と ref の最小より、その幅の 15%(少なくとも span の 3%)下。負の値があっても床はすべての母線の下にあり、柱は必ず下向き(床を 0 に置いて上下に棒を立てる案は、床の下の母線が床に隠れるので採らなかった)。床は全標本で同じ高さなので、柱の長さを時刻の間で比べられる。
- **描くもの(`draw_graph_network`、`sct_plt.HeightGuide`):** 薄い灰色の床(patch、Tag `HeightFloor`)、約 10 本の 1-2-5 の刻みの格子(`HeightGrid`)、棒・ブランチ・リンクの影(`HeightShadow`、床のすぐ上)、母線の中心から床までの柱(`HeightPost`)、半透明の青い基準面とその値の文字(`HeightReference`、例 `|V| = 1`)。それぞれ NaN で区切った 1 つの line か patch なので、IEEE68 でも 6 個しか増えない。
- **z 軸(`create_scene`):** 3D で高さがあるときだけ `ZColor` を出し、目盛りは値の 1-2-5 の刻み(位置は z、文字は値)、ラベルは量と単位(`|V| [pu]`、`∠V [rad]`、`Im V [pu]`、`P [pu]`、`Q [pu]`)。軸の範囲(`DrawBox`)は床と全標本の最大を含むので、時刻を動かしても範囲が変わらない。
- **視点:** 3D の図に高さが付いたとき(最初の描画も含む)に真上から見ていれば、方位角 −37.5、仰角 30 にする。その視点のまま高さがなくなると真上に戻す。利用者が回した視点は残す。前の描画に案内があったかは、描き直す前の `sct_plt`(`set_data` では `sct_pltPrevious`)の `HeightGuide` で判断する(新しい私用プロパティは作らない)。
- **選べない:** 案内はすべて `PickableParts="none"`、`HitTest="off"`、`HandleVisibility="off"`。`ButtonDownFcn` も `UserData` も持たないので、クリック(`ElementClicked`)にもデータチップにもならない。
- **時刻:** 3D の高さのある図は今も標本ごとに `create_scene` で作り直すので、案内も標本ごとに描き直す。

### 19.3 採らなかった案

- **高さを色でも示す:** 色は `ColorMode` の量と色の棒に使っているので、もう 1 つのカラーマップは読み違いのもとになる。基準面と z 軸の目盛りで足りると判断した。
- **`daspect` の z だけを変える:** 立体(球、直方体、円錐)が縦に伸びる。
- **縦の倍率を利用者が決めるプロパティ:** 公開メンバーを増やさない指示のため入れていない。自動の尺度で足りないときの提案として残す。

### 19.4 速さ

案内は 6 個のグラフィックスオブジェクトと全標本の高さの計算(n_bus × 標本数)だけで、作り直しの時間に比べて小さい。IEEE68 の 3D(`"V"`)の `set_time` の測定値は §19.6 に書く。

### 19.5 テスト

F59 に 4 件: `test3DBusHeightModeNoneDrawsNoHeightGuide`(medium)、`test3DHeightsStandOnPostsDownToAFloor`(large。母線ごとに 1 本の柱、上は母線の中心、下は床、基準面は 1、z の目盛り、視点の規則、angle の負の値)、`test3DPostsFollowSet_timeOnTwoSamples`(large。2 標本で尺度と床が 1 つ、柱が新しい高さに)、`TheHeightGuideIsNotPickable`(medium。母線のクリックはそのまま)。

### 19.6 画像と測定

- 画像(コーディネーター向け、セッションの作業フォルダ `scratchpad/busheight/`): `before_*` と `after_*` の IEEE9bus・IEEE68bus の `"V"`・`"angle"`(潮流)、IEEE9bus の地絡の ODE(`"V"`、t = 0.05 s と 0.12 s)、IEEE9bus の `"none"`(変更前後で画素が一致することを確かめた)。
- IEEE68 の 3D の `set_time`(0.5 s の地絡の ODE、隠れた figure、6 標本の平均): `"V"` 1.69 s/標本、`"none"` 0.12 s/標本。`"V"` の時間は標本ごとの作り直し(§14 の以前の測定は 1.5 s)がほとんどで、案内の分は小さい。作り直しをやめる(立体の `ZData` だけ動かす)のは別の課題。
- テスト: graph small・gui small 38 件、graph medium 108 件、F44・F47・F59 の large 57 件がすべて PASS。

### 19.7 z 軸のラベルの切れ(2026-11-23 修正、`feature/single-line-diagram`)

- 症状: 幅 900 px の figure で、3D の高さの図の z 軸のラベル「|V| [pu]」の左が figure の端で切れる(ラベルの左端が figure の左端より 8 px 外)。
- 原因: `make_axes` の tiledlayout は `Padding="compact"`。3D(`vis3d`)の軸は `TightInset` が 0 なので、レイアウトは z ラベルの場所を取らない。
- 修正: `create_scene` で、高さの案内を描くとき tiledlayout の `Padding` を `"loose"`、それ以外は `"compact"` にする(変わるときだけ設定)。軸の親が tiledlayout でないとき(軸を Parent に渡したとき)と単線結線図では触らない。`Position` などはタイルの中の軸には設定できない(警告)ので使わない。
- 確かめ: 修正後のラベルの左端は figure の左から 51 px。画像 `scratchpad/singleline/zlabel_before.png`、`zlabel_after.png`。

## 20. 母線の色(BusColorMode)と論文用の単線結線図(2026-11-23、`feature/single-line-diagram`)

ユーザーが承認した公開メンバーは 3 つだけ: `PowerNetwork.plot_single_line_diagram`、`ResultPF.plot_single_line_diagram`、`GraphNetDiagram.BusColorMode`。`ResultPF.plot_network` と `GraphNetMap` は削除した。

### 20.1 BusColorMode

- 値: `"none"`(既定)、`"V"`(|V| [pu])、`"angle"`(V の位相 [deg]。データチップの ∠V と同じ度)。`SetObservable` で、`show_controls` の Color のグループに dropdown(Bus color)を足した。
- 色の値: `color_values` の 3 つ目の出力 `rm_bus` が母線の量を返し、`reflect_color_mode` が表示中の標本の値を `BusColorData` に書く(標本ごと。ODE・CPF の `set_time` でも追従)。`"none"` に戻すと setter が `BusColorData` を NaN にする。
- **ColorMode との組み合わせ(決めたこと):** `BusColorMode` が `"none"` でなければ、母線の量がカラーバーを使い、ブランチ・接続線・機器には色の値を入れない(`ColorMode="none"` と同じ扱い。機器はクラスの色のまま)。`ColorMode` は値を保ち、`BusColorMode="none"` に戻すとまたその量で塗る。理由: |V| と |I|・P は単位が同じ pu でも別の量で、1 つのカラーマップと範囲に載せると色が読めない。単位が同じときだけ共有する案は、pu どうしでも意味が違うので採らなかった。2 本のカラーバーは公開メンバーが増えるので採らなかった。
- 範囲: 自動の範囲(`update_color_scale`)は全標本・全母線の最小〜最大(等しければ `color_limits` が広げる)。|V| は 1 付近に集まるので、`ColorMode` の 95 パーセンタイルや ±m の規則は使わない。`ColorLimits` の数値は今までどおり優先。
- ラベル: `ColorbarLabel` が `""` なら `"|V| [pu]"` か `"∠V [deg]"`(`color_readout`)。データチップの色の行と `LabelMode="value"` の行も同じ名前。`"value"` のラベルは固定の `|V|=`(または `∠V=`)の行を省く(§18 の修正、2026-11-23)。
- 機器の黒: `apply_style` の「カラーマップ使用中は値のない機器を黒」は `ColorMode` の色のときだけにした(`BusColorMode` が `"none"` のとき)。
- `plot_network` の置き換え: `res.plot_diagram(BusColorMode="V", ColorMode="none")`。P の流れは流れの点(`FlowMode="P"`、既定)と `BranchWidthMode="P"` の幅で示す。矢印はないが、流れの点の向きが同じ情報を持つ。

### 20.2 plot_single_line_diagram

- 引数は `Parent` だけ。`PowerNetwork` 版は `plot_diagram(State="topology", …)`、`ResultPF` 版は `plot_diagram(…)`(解の状態はデータチップにだけ出る)を固定の公開設定で呼ぶ: `Dimension="2D"`、`ColorMode="none"`、`BusColorMode="none"`、`FlowMode="none"`、`FlowAnimation=false`、`BranchWidthMode="none"`、`BranchWidthRange=[0.6 0.6]`、`MarkerSizeMode="none"`、`MarkerSizeRange=[4 4]`(棒は 2 pt、点と三角は 4 pt)、`LinkWidth=0.6`、`LabelMode="bus"`、`LabelFontWeight="normal"`、`TitleFormat=""`。
- 非公開のプロパティ 1 つ: `GraphNetDiagram.l_singleLine`(`Access = {?PowerNetwork, ?ResultPF}`)。setter が描き直す。そのため描画は 2 回(通常の図 → 単線結線図)。IEEE68 でも 1〜2 s。
- `draw_diagram_2d` の単線結線図モード: すべて黒、ラベルは枠なし・Helvetica。発電機(`component.generator.*` のクラス)は円と正弦波 1 周期を NaN で区切った 1 本の line(Tag `GeneratorGlyph`、UserData は機器なのでクリックとデータチップはそのまま)。半径は `min(0.025·span, 0.8·接続線の最初の区間)`(d0 基準では IEEE68 で小さすぎた)。接続線は円の縁で止める(点の数は変えないので `update_heights` もそのまま)。負荷(`component.load.*`)は接続線の向き(母線から離れる向き)の塗った三角のマーカー(`<`、`>`、`v`、`^`)。ほかの機器(インバータなど)は `Shape` のマーカーを黒で。
- `apply_style`: 色の値のない母線・ブランチ・接続線を灰色(0.2)ではなく黒に。`set_style` の色は今までどおり優先。
- `create_scene`: 発電機の円を `DrawBox` に含める(IEEE14 の B003 の発電機が切れていた)。`fit_axes` の余白は 3% → 1%。
- 図の大きさ(Parent が空のとき): `figure("Units","centimeters")` の幅 8.5 cm(2 段組の 1 段)、高さは描いた範囲の縦横比 × 8.5 cm を 3〜12 cm に収める。tiledlayout の `Padding="tight"`。ラベルは 6 pt、30 母線を超えると `6·sqrt(30/n_bus)`(最小 4 pt、IEEE39 は 5 pt、IEEE68 は 4 pt)。8 pt のままでは IEEE68 のラベルが重なって読めなかった。2026-11-26 に既定を 8 pt(最小 5 pt)から 6 pt(最小 4 pt)へ小さくしました(利用者の依頼。IEEE14 でラベルが図に対して大きすぎたため)。
- 画像(600 dpi、`exportgraphics(G.ax, …)`): `scratchpad/singleline/IEEE{9bus,14bus,68bus}_{net,res}.png`。

### 20.3 置き換えたもの

- テスト: F2(plot_network の節 → `plot_diagram` の BusColorMode の節)、F49 を削除(`test_categories.m`・`test_levels.m` からも)、F53(`get_layout` の比較)、F61(GraphNetMap の節 → BusColorMode の dropdown の節、dropdown 8 個)、F52(結果 GUI のメソッド一覧)、新規 F114(単線結線図と BusColorMode)。
- コード: `@GUILDA/update_keymap.m`(結果 GUI の一覧)、`resources/gui_forms.json`(plot_network を削除、plot_single_line_diagram と BusColorMode を追加)、両方の `functionSignatures.json`(`GUILDA.update_keymap(Signature=true)` で再生成)、`ResultPF.xml` の `NoNetworkSnapshot`、ヘルプ(`ResultPF.m`、`plot_diagram.m`、`GraphBase`、`GraphSpringBase.get_layout`、`tools.layout_place_buses`)。
- 文書: feature-graphs(表、母線の色、単線結線図の節、操作パネル)、feature-data-io、feature-model-building、feature-power-flow、folder-structure、Update log(2026-11-23)。

