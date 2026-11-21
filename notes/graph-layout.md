# ネットワーク図の配置データの形式(graph パラメータ)と net.get_layout / net.set_layout

基準: ブランチ `docs/graph-layout-spec`(`refactor/design-alignment` の c6307b7d から分岐)、2026-11-16。仕様です。2026-11-16 にユーザーが §9 の D1〜D10 を決め、座標のない要素の配置(§4.7)を承認しました。

状態(2026-11-16): §8.1 の A(モデルの列、検査、`get_layout`/`set_layout`、変換スクリプト、同梱 CSV の変換)をブランチ `refactor/graph-layout-columns` で実装しました。B・C・D はまだです。図のクラスは古い列名を読むので、A は読む所に一時的な橋渡しを置きました(`@GraphNetDiagram/set_network.m` の `old_graph_columns` で新しい列を古い列に戻す、`+tools/spring_model_data.m` は `Shape` を読み、棒を `""`、`"circle"` を `"o"` にする(MATLAB のマーカーに `"square"` はあるが `"circle"` はないため。§4.6 の「そのまま渡す」は C で見直す)。どちらも `BRIDGE(graph-layout A)` の印)。B・C はこれを外します。`@ResultPF/plot_network.m` は母線の `X`、`Y`(中心)を読むように直しました(§4.6 の最終の形)。

B の状態(2026-11-16): ブランチ `refactor/graph-layout-netdiagram` で実装しました。GraphNetDiagram は新しい列を直接読み(`old_graph_columns` の橋渡しは削除)、§4.6 のとおり棒を中心 `(X, Y)` に描き、ブランチと機器の接続を棒の中心線の上に置き、`Style="transformer"` の記号を From 端に描きます。座標のない母線は新しい `tools.layout_place_buses`(§4.7)で置き、GraphNetDiagram と GraphNetMap(`load_data`)の両方が使います。`GraphBase`・`GraphNetDiagram`・`GraphNetMap` の `get_layout`(§5.4)を足しました。座標のない機器の半径は 0.3·d0 にしました(§4.7「機器とブランチ」、§9 の最後)。実装で決めた細部: (1) `tools.layout_place_buses` は 2 つ目の出力に d0 を返す(機器の半径に使う)。全母線に座標がないときの d0 は `"force"` の結果から同じ規則で求める。(2) GraphNetMap のデータに省略可の `rv_length`、`c_path` を足し、`plot_network` が渡す(§4.7 のテスト 6 で両方の図の位置を一致させるため)。(3) 変圧器の 2 つの球は From 端から 0.05 の位置が基準だが、経路の長さの 1/4 がそれより短ければそちらにする(IEEE14 の B004→B007 は経路が 0.075 しかなく、0.05 では球が To 端の近くに出ていた)。(4) 点の形の母線では接続は中心(§4.6 どおり。以前は立体の外接箱に押し込んだ点)。

状態(C、2026-11-16): §8.1 の C をブランチ `fix/graph-layout-spring` で実装しました。`+tools/spring_model_data.m` の `BRIDGE(graph-layout A)` を外し、§4.6 の最終の写像(`"circle"` → `"o"`、`"square"` → `"s"`、棒 → `""`)にしました。IEEE14 の `net.plot_spring_model()` と `res.plot_spring_model()`(2D・3D、潮流計算と時間応答の結果)はエラーになりません。`GraphSpringBase.get_layout` を足し、`GUILDA:GraphSpringBase:PositionPhysical` で止めます(B の `GraphBase.get_layout` の既定は `PositionNotSupported` なので、§5.4 のとおり上書きが要る)。メッセージは `set_position` と共用で、「設定も配置としての保存もできない」に直しました。

母線の棒、ブランチの折れ点、節点の大きさと位置、ブランチが母線のどこにつながるかを、各 Bus・Branch・Component の `graph` パラメータに持ちます。GraphNetDiagram、GraphNetMap、GraphSpring がそれを読んで描きます。この文書は、その列を「1 列が 1 つの意味」になるように作り直す仕様と、系統全体の配置をまとめて読み書きする `net.get_layout` / `net.set_layout` の仕様です。

ユーザーが承認した方向(2026-11-16):

- データは今までどおり各要素の `graph` パラメータに置く。列の意味を 1 つずつにする(形と棒の長さを分ける、折れ点を 1 列にする、接続位置を明示する、線の種類、機器の位置を母線からの相対にする)。
- 系統全体の配置を編集するための `get_layout` / `set_layout` を PowerNetwork に加える。
- 別の配置ファイルや、系統が持つ 1 つの構造体にはしない(ファイル管理と同期が複雑になるため。§3)。

## 1. 今の形式(コードで確認したこと)

### 1.1 列と既定値

| 要素 | 列(`tab_parameter.graph`) | 既定値(`add_*` の引数) | 意味 |
|---|---|---|---|
| Bus | `Xaxis`、`Yaxis` (double) | NaN | 位置。NaN の母線が 1 つでもあると、全母線を `"force"` レイアウトで置く |
| | `Marker` (string) | `"s"` | `"s"`、`"o"`、`"^"`、`"v"`、`">"`、`"<"`、`"none"`、または `"_"`/`"|"` に長さを続けた棒(`"_0.1"` は長さ 0.1 の水平の棒) |
| | `MarkerSize` (double) | NaN | GraphSpring のために追加。NaN は描画側の既定 |
| | `Color` (string) | `""` | 同上。色の名前か `"#RRGGBB"`。`""` は描画側の既定 |
| Branch | `MidXaxis`、`MidYaxis` (string) | `[]`(`(1,:) string`) | 折れ点の x、y を別々の文字列で(`"[0.23,0.36]"`、`"[0.5,0.33]"`) |
| | `Marker` (string) | `"-"` | 線の種類。`"-"`、`"oo-"`(from 端に変圧器の記号)、`"-oo"`(to 端)、`"-oo-"` |
| Component | `Xaxis`、`Yaxis` (double) | NaN | 位置(**絶対座標**)。NaN は母線のまわりに自動で置く |
| | `Marker` (string) | `"o"` | 形 |
| | `MidXaxis`、`MidYaxis` (string) | `""` | 母線への接続線の折れ点(絶対座標) |
| | `MarkerSize`、`Color` | NaN、`""` | Bus と同じ |

定義の場所: `_GUILDAsystem/@Bus/Bus.m:87-104`、`@Branch/Branch.m:119-141`、`@Component/Component.m:181-213`、引数は `@PowerNetwork/add_bus.m:35-39`、`@PowerNetwork/add_branch.m:39-41`、`@Bus/add_component.m:34-40`。

同梱データで使われている値(`_GUILDAobject/+network/**/*.csv` を数えた結果):

- Bus の `Marker`: `"s"` が 439 行、`"_0.06"`〜`"_0.16"` が約 50 行、`"|0.06"` が 3 行。`MarkerSize`・`Color` の列はどの CSV にもない。
- Branch の `Marker`: `"-"` が 820 行、`"oo-"` が 12 行。`"-oo"`、`"-oo-"` は使われていない。折れ点があるのは 74 行。
- Component の `Marker`: `"o"`、`"^"`、`">"`、`"<"`、`"v"`。位置があるのは 60 行、折れ点があるのは 26 行。
- graph の列を持つ CSV: IEEE14bus(3 種)、IEEE9bus、IEEE68bus、IEEJ_EAST10/30、IEEJ_WEST10/30(night/peak)、Ishizaki6Bus(`branch_origin` を含む)、Txt3Bus。IEEJ のいくつかの bus CSV は `Marker` の列だけを持つ。
- 座標の範囲はネットワークごとに違う(IEEE14 は 0〜1、IEEE68 は -1〜9 など)。単位はない。

IEEE14bus の例(`_GUILDAobject/+network/@IEEE14bus/`):

```
bus/parameter.csv        … Xaxis,Yaxis,Marker  →  0.2,0.56,_0.1
branch/parameter.csv     … MidXaxis,MidYaxis,Marker  →  "[0.23,0.36]","[0.5,0.33]",-
component/load-power/main.csv … Xaxis,Yaxis,Marker,MidXaxis,MidYaxis  →  0.31,0.25,<,[0.36],[0.25]
```

### 1.2 読む側

| ファイル | 読み方 |
|---|---|
| `_auxiliary/@GraphNetDiagram/set_network.m` | `struct(net,false)` の `tab_parameter(:, ["operation","graph"])` をそのまま `obj.tab_bus.graph` などに写す。NaN の母線があると `"force"` で全母線を置く。位置のない機器は母線から半径 0.05 の円周上に置く。前に描いた同じタグの位置を引き継ぐ |
| `_auxiliary/@GraphNetDiagram/draw_graph_network.m` | 母線: `Xaxis`、`Yaxis`、`Marker` を `plot_node` に渡す。ブランチ: `MidXaxis`、`MidYaxis` を `parse_points` で数値にし、数が違えば描くときに `GUILDA:GraphNetDiagram:MidPointsBranch`。端点は母線の立体の外接箱に、最初・最後の折れ点を押し込んだ点(clamp)。折れ点がなければ外接箱の中心。機器: 絶対位置 → 折れ点 → 母線の外接箱に押し込んだ最後の点、の順の線 |
| `…/private/plot_node.m` | `Marker` を形と棒の長さに分ける(`parse_node_marker`)。知らない値は四角か球 |
| `…/private/plot_edge.m` | 線の種類 `"-"`、`"oo-"`、`"-oo"`。**`"-oo-"` は `"-oo"` と同じに描く**(plot_edge.m:63-65) |
| `…/private/draw_cuboid_horizontal.m`、`draw_cuboid_vertical.m` | **棒は `Xaxis`(縦の棒は `Yaxis`)が棒の左端(下端)で、そこから長さ分のびる**(中心ではない) |
| `…/set_position.m`、`apply_selection.m` | 描画の中の `Xaxis`、`Yaxis` を書き換える。母線を動かすと、その機器を同じだけ動かす(機器が絶対座標のため) |
| `+tools/spring_model_data.m` → `@GraphSpringBase/load_data.m` → `@GraphSpring2D/create_scene.m` | `Marker`、`MarkerSize`、`Color` を `sv_marker` などに渡し、2D は MATLAB の `plot` の Marker にそのまま渡す。**IEEE14 の `"_0.1"` は MATLAB のマーカーでないので `res.plot_spring_model()` がエラーになる**(報告済みの不具合)。3D は `"v"` だけ円錐、ほかは球 |
| `_auxiliary/@ResultPF/plot_network.m:46-50` → `@GraphNetMap` | 母線の `Xaxis`、`Yaxis` を `rm_xy` にする(棒の母線は左端の点になる) |
| `@PowerNetwork/import.m:84,100,234` | CSV の列名 = `add_*` の Name-Value 名として受け付ける。`Color` の空欄を `""` にする |
| `@PowerNetwork/export.m:152,173,220` | `tab_parameter.graph` の列をそのまま書く |
| `@Bus/replace_component.m:50` | `[powerflow, operation, graph]` の表を `table2struct` して `add_component` の Name-Value に渡す |
| `resources/functionSignatures.json` | `add_bus`、`add_branch`、`add_component` の graph の引数がある(`GUILDA.update_keymap` が生成)。`DrawerOptionDialog`(GUI の追加ボタンの入力欄)はこれを読む |
| `@DrawerModelGUI/private/build_parameter_tab.m`、`edit_parameter.m` | graph も含め、各 Parameter の表を汎用の `uitable` で見せ、編集したセルで表全体を `tab_parameter` に書く。graph 専用の処理はない |
| `_auxiliary/@Parameter/Parameter.m` | 書き込みで確かめるのは列名・行数・列のクラスだけ。値の検査はない |

ほかに分かったこと:

- GraphNetDiagram は graph の `MarkerSize` と `Color` を読まない(GraphSpring だけが使う)。機器の色は形で決まる(`plot_node` の球は黄、円錐は赤)。
- 棒の端点は外接箱に押し込むので、線は棒の中心線ではなく棒の縁(y が ±0.0025)につながる。
- graph の列名は `add_*` の Name-Value 名と同じでなければならない(`import` と `replace_component` がそれを前提にしている)。新しい列名もこの制約を守る。
- `add_branch` には線路定数の `X`(リアクタンス)がある。ブランチの配置の列名に `X` は使えない。

## 2. 問題点

1. **`Marker` が形と棒の長さを兼ねている。** `"_0.1"` は形(水平の棒)と長さ(0.1)を 1 つの文字列に詰めている。大きさの考えも 2 つある(棒の長さと `MarkerSize`)。文字列を MATLAB に渡す GraphSpring がエラーになるのはこのため。
2. **折れ点が 2 列の文字列に分かれている。** x と y の数の食い違いは描くときまで分からない。`"[0.23,0.36]"` のコンマのために CSV で引用符が要る。
3. **ブランチが母線の棒のどこにつながるかが暗黙。** 最初・最後の折れ点を棒に押し込む規則で決まる。棒の上の位置を直接指定できず、データからは読み取れない。
4. **ブランチの `Marker` は実は線の種類。** `"oo-"` などの記号は意味が分かりにくい。`"-oo-"` は今は `"-oo"` と同じに描かれる。
5. **機器の位置が絶対座標。** 母線を動かすと、その機器の `Xaxis`、`Yaxis` と折れ点をすべて書き直す必要がある(`set_position` はそのための処理を持っている)。
6. **棒の位置が棒の端。** `Xaxis` は水平の棒の左端、`Yaxis` は縦の棒の下端。棒の母線だけ「位置」の意味が違い、GraphNetMap では端の点に描かれる。
7. **値の検査がない。** `Parameter` はクラスしか見ないので、壊れた折れ点や知らない形は描くまで分からない。

## 3. 置き場所: 各要素の graph パラメータのまま(決定済み)

配置データは今までどおり各 Bus・Branch・Component の `graph` パラメータに置きます。退けた案と理由:

| 案 | 退けた理由 |
|---|---|
| ネットワークごとの別ファイル(`layout.json` など) | ファイルとパスの管理が要る(編集後のコピー、利用者が作ったネットワーク、削除)。要素の追加・削除・名前の変更のたびにファイルと同期する必要がある |
| 系統(`PowerNetwork`)が持つ 1 つの構造体 | 要素の追加・削除・名前の変更のたびに同期が要る。`replace_component` や `import`/`export` が要素ごとに graph を持ち運ぶ今の流れとも合わない |
| (共通) | どちらも速くならない。図は描くたびに `struct(net,false)` のスナップショットを 1 回読むだけなので、データがどこにあっても読む回数は同じ |

各要素に置くと、要素を足す・消す・置き換えると配置も一緒に動き、CSV の 1 行に配置も入るので、同期の処理が要りません。全体をまとめて扱いたいときは §5 の `get_layout` / `set_layout` を使います。

## 4. 新しい形式

### 4.1 座標系

- 単位のない図の座標です。x は右、y は上(MATLAB の軸、`view(0,90)` と同じ)。範囲は決めません(同梱データは 0〜1 のものと、もっと広いものがある)。
- 母線の位置 `X`、`Y` は**図形の中心**です。棒もその中心(今の左端・下端から変わる。§7 の変換で `X + Length/2` などにする)。
- 機器の位置 `DX`、`DY` と機器の `Path` は、**母線の中心からの相対**です(D1。§4.4)。
- 棒の上の位置(`FromOffset`、`ToOffset`、`Offset`)は、棒の中心からの符号つきの距離です。水平の棒は右が正、縦の棒は上が正。座標と同じ単位。
- 高さ(z、`BusHeightMode`)は図の設定で、配置データには持ちません。

### 4.2 Bus

| 列 | クラス | 既定 | 意味 |
|---|---|---|---|
| `X`、`Y` | double | NaN | 図形の中心。どちらかが NaN の母線は §4.7 の規則で置く(座標のある母線は動かさない) |
| `Shape` | string | `"square"` | `"hbar"`(水平の棒)、`"vbar"`(縦の棒)、`"circle"`、`"square"`、`"^"`、`"v"`、`"<"`、`">"`、`"none"` |
| `Length` | double | NaN | 棒の長さ。棒では正の有限値が必須。点の形では NaN(値があっても使わない) |
| `MarkerSize` | double | NaN | 今と同じ(NaN は描画側の既定) |
| `Color` | string | `""` | 今と同じ |

`Shape` の値の決め方: 点の形は MATLAB のマーカー名(`"circle"`、`"square"`、`"^"`、`"v"`、`"<"`、`">"`、`"none"`)にそろえ、MATLAB にない形は棒の 2 つだけにしました。こうすると GraphSpring などは棒以外をそのまま MATLAB に渡せます。`"o"`、`"s"` の短い名前は受け付けず(書き方を 1 つにするため)、変換スクリプトが直します。今の描画にない形(`"diamond"` など)は入れません(D4)。

### 4.3 Branch

| 列 | クラス | 既定 | 意味 |
|---|---|---|---|
| `Path` | string | `""` | 折れ点を 1 列に。`"x y; x y"`(点は `;`、x と y は空白で区切る)。`""` は折れ点なし |
| `FromOffset`、`ToOffset` | double | NaN | from・to 母線の棒の上の接続位置(§4.1)。NaN は今の規則(最初・最後の折れ点を棒に押し込む。折れ点がなければ中心) |
| `Style` | string | `"line"` | `"line"` か `"transformer"`(From 端の近くに変圧器の記号)。D5 |

- `Path` は CSV でコンマを含まないので、引用符が要りません。
- `add_branch(..., Path=)` は文字列のほか n×2 の double も受け付け、文字列に直して保存します(表の列のクラスは string に固定のため)。
- 点の形の母線では `FromOffset`、`ToOffset` を使いません(中心につなぐ)。棒の長さの半分を超える値は、描くときに棒の端に押し込みます(母線の `Length` は後から変えられるので、ブランチ側の検査では止めない)。
- `Style` の値は 2 つだけです(D5)。GUILDA のブランチのモデルではタップが From 端にあるので、変圧器の記号は常に From 端に描きます。記号の位置を図にした今の書き方(`"oo-"`、`"-oo"`、`"-oo-"`)は、両端なのか中央なのか読み取れず、実装は `"-oo-"` を To 端に描いていました。名前で書き、位置を 1 つに決めれば読み違えがありません。

### 4.4 Component

| 列 | クラス | 既定 | 意味 |
|---|---|---|---|
| `DX`、`DY` | double | NaN | 母線の中心からの相対位置。NaN は今と同じく母線のまわりに自動で置く |
| `Shape` | string | `"circle"` | Bus と同じ値(棒を除く) |
| `Path` | string | `""` | 接続線の折れ点。`DX`、`DY` と同じく母線の中心からの相対 |
| `Offset` | double | NaN | 母線の棒の上の接続位置。NaN は今の規則(最後の折れ点、なければ機器の位置を棒に押し込む) |
| `MarkerSize`、`Color` | | NaN、`""` | 今と同じ |

**相対にした理由(D1):**

| | 相対(`DX`、`DY`) | 絶対(`X`、`Y`) |
|---|---|---|
| 母線を動かす | 機器と接続線もついてくる。何も書き直さない | 機器ごとに位置と折れ点を書き直す |
| 機器を別の母線に移す | 位置の意味が新しい母線からに変わる(同じ形の配置ならそのまま使える) | 絶対位置はそのまま |
| データを読む | 母線の位置を足さないと図の上の位置は分からない | そのまま読める |
| `set_position` | 母線の移動で機器を動かす処理が要らない | 今の処理が残る |

標準図を作るときは母線を動かすことが多く、機器は母線の近くに置くのがふつうなので、相対にしました。母線の位置が NaN(自動レイアウト)でも、機器の相対位置はそのまま意味を持ちます。

列名 `DX`、`DY` の理由: Name-Value 名は UpperCamelCase(api-design の規則 7)なので `dX` ではなく `DX` にし、母線の `X`、`Y` と違う名前にして相対だと分かるようにしました。`Offset` は棒の上の位置で、`DX`、`DY` とは別の意味です(ブランチの `FromOffset` と同じ言葉。D3)。

### 4.5 入力時の検査

壊れた値は、描くときではなく**値を入れたときに**エラーにします。

- `add_bus`、`add_branch`、`add_component` の arguments ブロックに検証関数を付けます: `Shape` は `mustBeMember`、`Style` も同じ、`Path` は新しい `tools.layout_mustBePath`(§4.8、§8 の A)、`Length` は正の有限値か NaN、オフセット・`DX`・`DY` は有限値か NaN、`Color` は既存の色の検査。
- 列をまたぐ検査(棒なら `Length` が正の有限値)は各クラスのコンストラクタで行います。
- 表を直接書く場合(`bus.tab_parameter.graph.Path = "..."`、GUI の Parameter タブ、`set_layout`)も止めるために、`Parameter` に検査の関数を持たせ、`set.tab_parameter` が保存の前に呼ぶようにします(新しいメンバー。D6)。graph 以外の Parameter には付けません。
- `Path` の文法: 空白を除いて空なら折れ点なし。それ以外は `;` で区切った各点が 2 つの有限の数。1 つでも外れたら `GUILDA:layout_parse_path:InvalidPath`(どの要素のどの値かを示す。ID は `GUILDA:<ファイル名>:<キー>` の規約どおり、メッセージは `SystemTools/GUILDA/en/layout_parse_path.xml`)。`tools.layout_parse_path(s)` が n×2 の double を返し、検査と描画の両方が使います。

### 4.6 描き方の規則

- **母線**: 棒は中心 `(X, Y)`、長さ `Length`、太さと高さは今と同じ。点の形は今と同じ立体。
- **ブランチの端点**: 棒の母線で `FromOffset` が有限なら、棒の中心線の上の `X + FromOffset`(縦の棒は `Y + FromOffset`)。NaN なら最初の折れ点を棒の範囲に押し込んだ点(今の規則。ただし縁ではなく中心線の上)。点の形の母線は中心。to 端も同じ。
- **機器**: 位置は母線の中心 + `(DX, DY)`、接続線は機器 → `Path` の各点(母線の中心を足す)→ 母線の上の点(`Offset`、NaN なら今の規則)。
- **変圧器の記号**: `Style="transformer"` なら、今の `"oo-"` と同じく From 端の近くに 2 つの球を描きます。
- **GraphNetMap**(`ResultPF.plot_network`): 母線の位置は `X`、`Y`(棒の中心)。座標のない母線は §4.7。形・長さ・折れ点は使いません(MATLAB の graph plot のため)。
- **GraphSpring**(`tools.spring_model_data`): `Shape` を MATLAB のマーカーに写します。MATLAB のマーカーに `"square"` はあるが `"circle"` はないので、`"circle"` → `"o"`、`"square"` → `"s"`(短い名前にそろえる)。`"^"`、`"v"`、`"<"`、`">"`、`"none"` はそのまま。`"hbar"`、`"vbar"` は `""`(GraphSpring の既定 `"o"`、D8)。3D は今までどおり `"v"` だけ円錐、ほかは球。これで IEEE14 の `plot_spring_model` のエラーはなくなります。
- `MarkerSize`、`Color` を GraphNetDiagram の初期の見た目にするかは、この仕様の範囲外です(単位が GraphSpring のポイントと違うため。§10)。

### 4.7 座標のない要素の配置(2026-11-16 承認)

今の規則「NaN の母線が 1 つでもあると全母線を `"force"` で置く」(`set_network.m`、`GraphNetMap/create_scene.m`)をやめます。座標のある系統に母線を 1 つ足しただけで標準図の配置がすべて崩れるためです。新しい規則では、**座標のある母線は決して動きません。**

#### 担当と置き場所

- 計算は `tools.layout_place_buses`(新規、`+tools`)に置き、GraphNetDiagram の `set_network` と GraphNetMap(`load_data` / `create_scene`)の両方が呼びます。どちらも同じ規則で母線を置く必要があり、図のクラスどうしで依存させないためです。
- 図形は作りません(全母線に座標がないときの `"force"` だけは、今と同じく見えない figure の graph plot を使う)。

```matlab
rm_xy = tools.layout_place_buses(rm_xy, im_edge, Length=rv_len, Path=c_path, Iteration=50, StepSize=0.1)
```

| 入力 | 内容 |
|---|---|
| `rm_xy`(n_bus×2) | 母線の中心。NaN を含む行が座標のない母線 |
| `im_edge`(n_branch×2) | 各ブランチの from・to 母線の行番号。並行のブランチ(同じ組)は 1 本として数える |
| `Length`(n_bus×1、省略可) | 棒の長さ(水平の棒を正、縦の棒を負、点の形は NaN で渡す)。重なりの判定で棒を線分として扱うため |
| `Path`(n_branch×1 の cell、省略可) | 各ブランチの折れ点(n×2)。両端に座標のあるブランチの線を障害物にするため |
| `Iteration`(既定 50)、`StepSize`(既定 0.1) | §「手順 3」の回数と歩幅 |

出力は全行が有限の `rm_xy` です。座標のあった行は入力と**同じ値**(`isequal`)です。

#### 「座標のある母線」の集合 P

図の側が次の順に決めてから helper を呼びます。

1. モデルの `X`、`Y`(両方が有限)。
2. 同じ図で前に描いた同じタグの位置(`set_data`、`plot_diagram(Graph=G)` の描き直し、`set_position` の結果)。今の「前の位置を引き継ぐ」規則と同じです。

ここで P が空なら(全母線に座標がない)、今と同じく全母線を `"force"` で置き、以下の手順は行いません。

#### 長さの基準 d0

- 両端が P にあるブランチの、母線の中心どうしの距離の中央値。
- そのようなブランチがなければ、P の外接箱の長い辺の 0.1 倍。
- それも 0(P が 1 点)なら 0.1。

#### 手順 1: 幅優先の順に初期位置を置く

1. P から出発して幅優先探索(BFS)をし、座標のない母線を P からの段数の順に並べます。同じ段数の中は母線の順(`net.a_Bus` の順)です。
2. その順に 1 つずつ置きます。母線 i の「置いた隣」N_i は、i とブランチでつながる母線のうち P か既に置いたものです(BFS の順なので必ず 1 つ以上ある)。
3. 重心 c = N_i の位置の平均。候補を c + 0.5·d0·(cos θ_k, sin θ_k)、θ_k = 2πk/8(k = 0..7、k = 0 は右)の 8 点とし、「置いた全母線(棒は線分)と、両端が置いてあるブランチの線(Path があれば折れ線)」までの最短距離がいちばん大きい候補を選びます。同点なら k が小さいもの。
4. 置いた母線は P に加えます(次の母線の隣になれる)。

#### 手順 2: P とつながらない母線

BFS で届かない母線(P のどれともブランチでつながらない連結成分)は、図の外接箱の右に置きます。

- 外接箱 = 手順 1 の後の全母線(棒は両端)の範囲。列の x は `xmax + d0`、最初の y は `ymax`。
- 成分ごとに(成分の最小の母線の順に)上から置きます。孤立した母線(ブランチなし)は 1 点、y を d0 ずつ下げます。
- 2 つ以上の母線の成分は、その最小の母線を根にした BFS の層を右へ d0 ずつ、同じ層の中を母線の順に下へ d0 ずつ並べ、成分の後は d0 あけて次の成分を置きます。
- これらの母線は手順 3 で動かしません。

#### 手順 3: 新しい母線だけを動かすばねの緩和

手順 1 で置いた母線(集合 F)だけを、`Iteration` 回まで同時に(全母線の力を先に計算してから)動かします。もとの P の母線と手順 2 の母線は固定です。

母線 i ∈ F にかかる力(r = d0/2):

- ばね: i の隣 j ごとに `(|p_j − p_i| − d0) · u_ij`(u_ij は i から j への単位ベクトル)。
- 節点の反発: i 以外の全母線 j(棒は線分上の最も近い点)で距離 s < r のとき `d0 · (r − s)/r · u_ji`。
- 線の反発: i を端に持たないブランチの線(両端の位置と Path による折れ線)で、最も近い点までの距離 s < r のとき、同じ形でその点から離れる向き。

更新は `Δ_i = StepSize · F_i` を長さ `StepSize · d0` で打ち切り、`p_i ← p_i + Δ_i`。全 i で `|Δ_i| < 1e-6 · d0` になったら途中で止めます。

- 乱数は使いません。2 点が重なったとき(距離 < 1e-12·d0)の向きは θ = 2π·(i mod 8)/8 に固定します。同じ入力なら同じ出力です。
- 機器は障害物に入れません(母線の位置が決まった後に今の規則で置くため)。

#### 機器とブランチ

- `DX`、`DY` が NaN の機器は、母線のまわり(半径 0.3·d0、機器の順に等間隔の角度)に置きます。前に同じ図で描いた同じタグの機器は、その位置を引き継ぎます。半径は以前の絶対値 0.05 から d0 に比例する値に変えました(2026-11-16 ユーザー決定。座標の範囲が広い系統で小さすぎないように)。
- 新しいブランチは Path が空なので、両端を結ぶ直線です。

#### モデルには書かない

自動で決めた位置は図の中にだけあり、モデルには書きません(api-design の規則 6)。保存は利用者が明示的に `net.set_layout(G.get_layout())` で行います(§5.3)。

#### テスト(B の F53 `test_F53_layout_placement`)

1. 座標のそろった IEEE14 に、B014 とつながる母線 B015 を 1 つ足す: 元の 14 母線は `isequal` で不変。B015 は有限で、B014 との距離が 0.5·d0〜2·d0、ほかの母線との距離が 0.25·d0 以上。
2. B015 を B013 と B014 の 2 つにつなぐ: B015 は 2 つの重心から d0 以内、線分 B013–B014 から 0.1·d0 以上離れる。
3. ブランチのない母線を足す: x が元の外接箱の `xmax` より右、y が `ymax` 以下。
4. 2 つの新しい母線の鎖(B015–B014、B016–B015): 順が B015、B016 であること、どちらも隣との距離が 0.5·d0〜2·d0、ほかの母線と 0.25·d0 以上離れること。
5. 同じ入力で 2 回呼んで `isequal`(決定的)。全母線に座標があれば入力をそのまま返す。全母線に座標がなければ全部有限(`"force"`)。
6. `net.plot_diagram()` の後もモデルの `X`、`Y` は NaN のまま。`G.get_layout()` は有限の位置を返し、`net.set_layout` で書ける。GraphNetMap(`res.plot_network()`)でも 1 と同じ母線が同じ位置になる。

### 4.8 補助関数を `+tools` に置く理由(D10)

`layout_` を頭に付けて `+tools` にそろえます: `tools.layout_parse_path`(文字列 → n×2)、`tools.layout_mustBePath`(arguments ブロックの検証関数)、`tools.layout_convert_columns`(古い列の変換)、`tools.layout_place_buses`(§4.7)。

- 依存の向き: モデルのコンストラクタと `add_*` が Path を検査するので、Bus・Branch・Component が図のクラスに依存してはいけません。図のクラスもモデルも `+tools` を使う形にします。
- 変換は一度だけ使うものなので、図やモデルのクラスのメンバーにしません。
- 検証関数の名前: 命名規則の例(`simulateFcn_mustBeProgress`)と同じく、頭の語を先に、`mustBe` をその後に置きます(`layout_mustBePath`)。

## 5. 系統全体の配置: `net.get_layout` / `net.set_layout`

### 5.1 `sct_layout = net.get_layout()`

全要素の graph をタグで引ける 1 つの構造体にして返します。モデルは変えません(get_)。

| フィールド | 表の列 |
|---|---|
| `tab_bus` | `Tag`、`X`、`Y`、`Shape`、`Length`、`MarkerSize`、`Color` |
| `tab_branch` | `Tag`、`From`、`To`(端の母線のタグ。読むだけ)、`Path`、`FromOffset`、`ToOffset`、`Style` |
| `tab_component` | `Tag`(完全なタグ)、`Bus`(母線のタグ。読むだけ)、`DX`、`DY`、`Shape`、`Path`、`Offset`、`MarkerSize`、`Color` |

- `Tag` は行の名前ではなく列にします(`writetable` でそのまま CSV にでき、表示でも見える)。行は `net.a_Bus` などの順。
- フィールド名は命名規則に従い `tab_` を付けました(`sct_layout.tab_bus`)。

### 5.2 `net.set_layout(sct_layout, IgnoreUnknown=false)`

各表の行を `Tag` で要素に引き当て、その要素の graph に書きます。

- 一部だけ書けます: 表は 1 つでも、行は一部でも、列は `Tag` と一部の列だけでもよい(なかった列・行・表は変えない)。
- `From`、`To`、`Bus` の列は読むだけの情報で、書きません(あっても無視)。
- 系統にないタグは `GUILDA:PowerNetwork:LayoutUnknownTag`。`IgnoreUnknown=true` なら飛ばします(別の系統に配置を写すとき用)。
- 知らない列は `GUILDA:PowerNetwork:LayoutUnknownColumn`。
- 書く前に全行を §4.5 の規則で検査し、1 つでも外れたら何も書きません。
- 書き込みは各要素の `tab_parameter.graph` への代入なので、変わった列ごとに編集の記録(タグ `graph`)が残り、何も古くなりません(今の graph と同じ)。

### 5.3 使い方

```matlab
% まとめて編集
L = net.get_layout();
L.tab_bus.Length(L.tab_bus.Shape == "hbar") = 0.12;
net.set_layout(L);

% 別の系統に写す(タグが同じもの)
net2.set_layout(net.get_layout(), IgnoreUnknown=true);

% 図で動かした位置をモデルに保存する(明示的に)
G = net.plot_diagram();
G.set_position("B001", [0.1 0.9]);
net.set_layout(G.get_layout());
```

`plot_` と `get_` はモデルに書かない(api-design の規則 6)ので、図の位置をモデルに入れるのは `net.set_layout` を呼んだときだけです。

### 5.4 図が描いた位置を出す: `G.get_layout()`

- `GraphNetDiagram.get_layout()`: §5.1 と同じ形の構造体で、**図が今描いている**位置を返します。`tab_bus` は `Tag`、`X`、`Y`(自動レイアウトと `set_position` の結果を含む)、`tab_component` は `Tag`、`DX`、`DY`。ほかの列は入れません(図はほかの列を変えないので、そのまま `set_layout` に渡せば位置だけが書かれる)。
- `GraphNetMap.get_layout()`: `tab_bus`(`Tag`、`X`、`Y`)だけ。
- `GraphBase.get_layout()` の既定は `set_position` と同じく `GUILDA:GraphBase:PositionNotSupported`、GraphSpring は位置が電圧フェーザなので `GUILDA:GraphSpringBase:PositionPhysical`。
- 図の中の位置は図の中だけにあり、図は `net` を持ちません(結果のスナップショットから描くことがあるため)。だから「図から系統へ」は `net.set_layout(G.get_layout())` の 2 段にします。

## 6. タグは削除で振り直されるか(確認の答え)

**振り直されません。** `get_layout` / `set_layout` をタグで引くことはできます。

- `PowerNetwork.remove_bus`(`@PowerNetwork/remove_bus.m`)、`remove_branch`、`Bus.remove_component` は、セル配列から外して削除するだけで、残りの要素の `s_tag` に触れません。
- 自動のタグの番号は使用中の最大 + 1(`+tools/next_tag_number.m`)です。そのため、**番号が最大の要素を消してから足すと、新しい要素が消した要素と同じタグになります**。消す前に保存した配置をそのまま `set_layout` すると、新しい要素にその配置が入ります(多くの場合は望ましい動作ですが、知っておく必要があります)。
- タグは `s_tag` への代入で変えられます(`LayerPackage.set.s_tag`、"Tag" の編集として記録)。変えた後は古い配置の表と一致しません(`IgnoreUnknown=false` ならエラーで気づく)。
- 機器のタグは作ったときの母線のタグを頭に含みます。母線のタグを変えても、機器のタグを変える処理はコードに見当たりません(実行しての確認はしていない)。
- `replace_component` は番号を引き継ぎますが、タグの見出し(クラスごと)が変わるとタグも変わります。graph は引き継がれます。
- `export` は `FullTag` を書き、`import` はそれを読むので、CSV を往復してもタグは変わりません。

## 7. 移行

### 7.1 同梱ネットワークの変換スクリプト

`tools.layout_convert_columns(s_folder)` を作り、`_GUILDAobject/+network/*` の全 CSV(`@IEEJ_*/night`、`peak` と `@Ishizaki6Bus/branch_origin` を含む)を一度変換してコミットします。利用者も自分の CSV に使えるよう、`_GUILDAsystem/+tools` に置きます。

変換の規則:

| 古い列 | 新しい列 |
|---|---|
| Bus `Marker` = `"_L"` | `Shape="hbar"`、`Length=L`、`X = Xaxis + L/2`、`Y = Yaxis` |
| Bus `Marker` = `"|L"` | `Shape="vbar"`、`Length=L`、`X = Xaxis`、`Y = Yaxis + L/2` |
| Bus・Component `Marker` = `"s"`、`"o"` | `"square"`、`"circle"`(ほかの値はそのまま) |
| Bus `Xaxis`、`Yaxis`(点の形) | `X`、`Y` |
| Branch `MidXaxis`、`MidYaxis` | `Path = "x1 y1; x2 y2; …"`(数が違う行は、その行を示してエラー) |
| Branch `Marker` | `"-"` → `"line"`。`oo` を含む値(`"oo-"`、`"-oo"`、`"-oo-"`)→ `"transformer"`(D5)。`"-oo"`、`"-oo-"` は今は To 端に描かれていたので、その図は記号が From 端に移って変わる(同梱データは `"oo-"` だけなので、同梱の図は変わらない) |
| Branch(新) | 端の母線が棒で折れ点があれば、今の押し込みの規則で求めた値を `FromOffset`、`ToOffset` に書く。そうでなければ NaN |
| Component `Xaxis`、`Yaxis` | `DX = Xaxis − X_bus`、`DY = Yaxis − Y_bus`(母線の**新しい**中心から)。どちらかが NaN なら NaN |
| Component `MidXaxis`、`MidYaxis` | `Path`(各点から母線の中心を引く) |
| Component(新) | 母線が棒なら今の規則で求めた値を `Offset` に、そうでなければ NaN |

オフセットを NaN のままにせず数値で書くのは、データを見れば接続位置が分かるようにするためです(描く図は同じ。今との違いは、線が棒の縁ではなく中心線につながる ±0.0025 だけ)。

### 7.2 変換の例(IEEE14bus)

変換前:

```
bus/parameter.csv
Tag,…,Xaxis,Yaxis,Marker,Slack
B,…,0.2,0.56,_0.1,1
B,…,0.34,0.28,_0.13,0

branch/parameter.csv(1 行目: B001 → B002)
Type,From,To,…,MidXaxis,MidYaxis,Marker
pi,1,2,…,"[0.23,0.36]","[0.5,0.33]",-

component/load-power/main.csv(1 行目: B002 の負荷)
Bus,…,Xaxis,Yaxis,Marker,MidXaxis,MidYaxis,…
2,…,0.31,0.25,<,[0.36],[0.25],…

component/gen-park/main.csv(2 行目: B002 の発電機)
2,…,0.415,0.22,o,,,…
```

変換後:

```
bus/parameter.csv
Tag,…,X,Y,Shape,Length,Slack
B,…,0.25,0.56,hbar,0.1,1
B,…,0.405,0.28,hbar,0.13,0

branch/parameter.csv
Type,From,To,…,Path,FromOffset,ToOffset,Style
pi,1,2,…,0.23 0.5; 0.36 0.33,-0.02,-0.045,line

component/load-power/main.csv
Bus,…,DX,DY,Shape,Path,Offset,…
2,…,-0.095,-0.03,<,-0.045 -0.03,-0.045,…

component/gen-park/main.csv
2,…,0.01,-0.06,circle,,0.01,…
```

確かめ方: 母線 B001 の棒は 0.2〜0.3(中心 0.25)、最初の折れ点 x = 0.23 なので `FromOffset = 0.23 − 0.25 = −0.02`。B002 の棒は 0.34〜0.47(中心 0.405)、最後の折れ点 x = 0.36 なので `ToOffset = −0.045`。負荷は `0.31 − 0.405 = −0.095`、`0.25 − 0.28 = −0.03`。

### 7.3 古い列との互換はない

プロジェクトの規則どおり、古い列名(`Xaxis`、`Yaxis`、`Marker`、`MidXaxis`、`MidYaxis`)は受け付けません。`import` で古い列があれば、`GUILDA:import:OldGraphColumns`(変換スクリプトの呼び方を示す)で止めます(`check_cols` の「知らない列」のエラーより分かりやすくするため)。`add_bus(Xaxis=…)` などは MATLAB の `MATLAB:TooManyInputs`(arguments ブロックの規則どおり)。

自分の CSV を持つ利用者は、次を 1 回実行します:

```matlab
tools.layout_convert_columns("path/to/my_network")
```

スクリプトで `Xaxis=` などを渡している利用者は、§4 の名前に書き直します(`v4-migration.md` に表を載せる)。

## 8. 実装の計画

### 8.1 サブセッション(ファイルを共有しない)

**A は最初に単独で。** 列名を決めるので、B・C・D は A をマージした後に並行で始めます。

| | ブランチ(案) | 変えるファイル | テスト |
|---|---|---|---|
| A | `refactor/graph-layout-columns` | `@Bus/Bus.m`、`@Branch/Branch.m`、`@Component/Component.m`、`@PowerNetwork/add_bus.m`、`add_branch.m`、`@Bus/add_component.m`、`@PowerNetwork/import.m`(古い列の検出)、`_auxiliary/@Parameter/Parameter.m`(検査の関数)、新規 `@PowerNetwork/get_layout.m`、`set_layout.m`(と `PowerNetwork.m` の宣言)、新規 `+tools/layout_parse_path.m`、`layout_mustBePath.m`、`layout_convert_columns.m`、`_GUILDAobject/+network/**/*.csv`(変換の結果)、`resources/functionSignatures.json`(`GUILDA.update_keymap` で再生成)、メッセージ `SystemTools/GUILDA/en/` の `PowerNetwork.xml`、`Parameter.xml`、`import.xml`、`Bus.xml`、`Branch.xml`、`Component.xml` と新規 `layout_parse_path.xml`、`layout_convert_columns.xml`。`export.m`、`replace_component.m` は列名が引数名と同じなので変えずに済む見込み(確認する) | 既存 F2、F3、F17、F19、F50 の graph の列を直す。新規 F54 `test_F54_graph_layout`(F52 は別のテストが使用): 検査(壊れた Path、知らない Shape、棒で Length なし、直接の表の書き込み、GUI 経由と同じ `tab_parameter` の代入)、`get_layout`/`set_layout`(一部の列・行、知らないタグ、`IgnoreUnknown`、書く前の全行検査)、CSV の往復、変換スクリプト(§7.2 の値) |
| B | `refactor/graph-layout-netdiagram` | `_auxiliary/@GraphNetDiagram/`(`set_network.m`、`draw_graph_network.m`、`set_position.m`、`apply_selection.m`、`private/plot_node.m`、`plot_edge.m`、`draw_cuboid_*`、新規 `get_layout.m`、`GraphNetDiagram.m`)、`_auxiliary/@GraphNetMap/`(`load_data.m`、`create_scene.m`、新規 `get_layout.m`、`GraphNetMap.m`)、新規 `+tools/layout_place_buses.m`(§4.7)、`_auxiliary/@ResultPF/plot_network.m`、`_auxiliary/@GraphBase/`(新規 `get_layout.m`、`GraphBase.m`)、`SystemTools/GUILDA/en/GraphNetDiagram.xml`、`GraphNetMap.xml`、`GraphBase.xml` | F44、F47、F49 を直す。追加: 棒の中心と接続位置(オフセットあり・NaN)、`Style="transformer"` が From 端、母線を動かすと機器がついてくる、`net.set_layout(G.get_layout())` で位置だけ書かれる。新規 F53 `test_F53_layout_placement`(§4.7 のテスト) |
| C | `fix/graph-layout-spring` | `+tools/spring_model_data.m`、`_auxiliary/@GraphSpringBase/`(`get_layout` の PositionPhysical を足すなら `GraphSpringBase.m` と新規 `get_layout.m`) | F43 に IEEE14 の `res.plot_spring_model()` がエラーにならないこと、棒の母線が `"o"`、`"circle"` が `"o"`、`"square"` が `"s"` になることを足す。F41 を確認 |
| D | `docs/graph-layout-pages` | `_GUILDAdoc/developer/feature-data-io.html`、`feature-model-building.html`、`notes/v4-migration.md`(新しい節)、この文書の状態の更新。`class.html` は生成 | ページの文言だけ(テストなし)。日英の両方 |

- GUI: `DrawerModelGUI` は graph を汎用の表として見せているので、変更は要らない見込みです。検査は A の `Parameter` で効きます。`DrawerOptionDialog` の追加の入力欄は `functionSignatures.json` から作られるので、A の再生成で新しい引数になります。ただし **`DrawerModelGUI` と `DrawerOptionDialog` は GUI の調整役のファイル**で、`feature/gui-model-actions`(5ceb4641 でマージ)が両方を大きく変えています。GUI に手を入れる必要が出たら、その部分は GUI の調整役と調整し、この計画のサブセッションでは変えません。GUI から `add_bus` などをして新しい引数を確かめるのは D の最後(または GUI の調整役)で行います。
- テストの水準(memory の規則): 各サブセッションは小さい `run_all` を手順ごとに、マージの前に中を 1 回。大は行いません。
- 新しく足してよいメンバー(ブリーフに書く): A は `PowerNetwork.get_layout`、`set_layout`、`Parameter` の検査の関数(1 つ)、`tools.layout_parse_path`、`layout_mustBePath`、`layout_convert_columns`。B は `GraphBase`・`GraphNetDiagram`・`GraphNetMap` の `get_layout` と `tools.layout_place_buses`。C は `GraphSpringBase.get_layout`(PositionPhysical のエラーだけ)。ほかは足さない。

## 9. 決定事項(2026-11-16、ユーザー)

| | 決めたこと |
|---|---|
| D1 | 機器の位置と接続線の折れ点は母線の中心からの相対(`DX`、`DY`、`Path`)。§4.4 |
| D2 | 列名は母線 `X`、`Y`、`Shape`、`Length`、`MarkerSize`、`Color`。ブランチ `Path`、`FromOffset`、`ToOffset`、`Style`。機器 `DX`、`DY`、`Shape`、`Path`、`Offset`、`MarkerSize`、`Color`(`PosX`、`PosY` にはしない) |
| D3 | 機器の接続位置は `Offset` |
| D4 | `Shape` は MATLAB のマーカー名(`"circle"`、`"square"`、`"^"`、`"v"`、`"<"`、`">"`、`"none"`)と `"hbar"`、`"vbar"`。短い名前は受け付けない。`"diamond"` は入れない |
| D5 | `Style` は `"line"` と `"transformer"` の 2 つ。記号は常に From 端(GUILDA のブランチのモデルでタップがある側)。古い `Marker` の `oo` を含む値はすべて `"transformer"` に変換する。今まで To 端に描かれていた `"-oo"`、`"-oo-"` の図は変わる |
| D6 | `Parameter` に検査の関数(新しいメンバー)を加え、表への直接の書き込み(GUI、`set_layout`)でも検査する |
| D7 | 変換スクリプトはオフセットを今の規則で求めた数値で書く |
| D8 | 棒の母線は GraphSpring で既定の `"o"` |
| D9 | `net.get_layout` / `net.set_layout(…, IgnoreUnknown=false)` |
| D10 | 補助関数は図のクラスに入れず、`+tools` に `layout_` を頭に付けて置く(`layout_parse_path`、`layout_mustBePath`、`layout_convert_columns`、`layout_place_buses`)。理由は §4.8 |
| 配置 | 座標のない母線は §4.7 の規則で置き、座標のある母線は動かさない(全母線に座標がないときだけ `"force"`) |

残る未決事項:

- (決定済み 2026-11-16)座標のない機器を置く半径は d0 に比例させ、0.3·d0 にしました(以前の絶対値 0.05 は、座標の範囲が広い系統(IEEE68 は約 10)では小さすぎた)。§4.7。

## 10. この仕様の範囲外

- graph の `MarkerSize`、`Color` を GraphNetDiagram の初期の見た目(`BusMarkerSize`、`BusColor` など)にすること(大きさの単位が GraphSpring と違う)。
- 変圧器の `Style` をブランチのクラスやタップから自動で決めること。
- 母線のタグを変えたときに機器のタグを追随させること(§6)。
