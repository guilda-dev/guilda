# ばね質点モデルの図(GraphSpring と plot_spring_model)

基準: ブランチ `feature/spring-model-entry`(`refactor/design-alignment` の b11fbae2 から分岐)、2026-11-13。

系統を「ばね質点モデル」として描く図の設計の記録です。ノードは電圧フェーザ(母線と、発電機の内部電圧)、ばねは送電線と機器のリアクタンスです。複素平面(2D)か、曲面 z = log|V| の上(3D)に描きます。ユーザーの IEEJ2026 のライブスクリプト(Swing_6bus*.mlx、voltage_collapse 2D/3D)のアニメーションを GUILDA に取り込むことが目的です。

## 1. クラスとデータの約束

`_GUILDAsystem/_auxiliary` の 3 クラスです。データだけを受け取って描き、系統のオブジェクトは読みません。

- `GraphSpringBase`(抽象): データの検査、既定値、回転の除去(`RotationScale`)、`set_time` / `animate` / `export_video`。
- `GraphSpring2D`: 複素平面(極座標の格子は `RMax` まで)。
- `GraphSpring3D`: 曲面 z = log|V| の上(`v` のマーカーは円錐、ほかは球)。

データ `sct_data`(構造体。詳しくは `GraphSpringBase` のクラスヘルプ):

| フィールド | 大きさ | 意味 |
|---|---|---|
| `rv_t` | 1 × n_t | 時刻 [s](非減少。相の境界の重複を許す) |
| `sv_node`, `sv_kind` | n_node × 1 | ノードのタグと種類("bus" / "component") |
| `cm_V` | n_node × n_t | ノードのフェーザ [pu] |
| `im_edge`, `sv_edge` | 2 × n_edge, n_edge × 1 | ばねの両端のノード番号とタグ |
| `iv_arrow` | n_arrow × 1 | 矢印の組を置くノード |
| `rm_P`, `rm_Iq` | n_arrow × n_t | 有効電力 P と無効電流の大きさ Iq [pu] |
| `sv_marker`, `rv_size`, `sv_color`, `rv_circle` | n_node × 1 | マーカー、大きさ(NaN: 既定)、色("": 既定)、破線の |E| の円の半径(NaN: なし) |

既定の大きさは母線 5、機器 15 で固定です。既定の色は母線が黒、機器が青です。

## 2. `Component.get_spring_node`

```matlab
[cv_E, rv_P, rv_Iq, cv_I] = Component.get_spring_node(rm_x, rm_V, rm_I, rm_u, rr_param)
```

静的メソッドで、列が時刻の行列を受け取ります(n_t 列)。`rr_param` は `tab_parameter.dynamics` の `sv_para` の列です。

- 基底クラス: 自身のノードはありません(`cv_E = []`)。渡された電流 I と母線電圧 V で P = real(V·conj(I))、Iq = imag(V·conj(I))/|V|、`cv_I = I` を返します。
- 自身のノードを持つ機器はこのメソッドを上書きし、状態・電圧・入力から E と母線へ注入する電流 I を計算し、P と Iq をノード E で評価します(`rm_I` は使いません)。

dq 座標は `fcn_I` と同じで、Vq + jVd = e^{jδ}·conj(V)、dq の組は X = e^{jδ}(Xq − jXd) で系統の座標に移ります。I = e^{jδ}(Iq − jId)(Id、Iq は `fcn_I` のもの)です。各発電機の E(各 `get_spring_node.m` のヘルプから):

| クラス | E |
|---|---|
| `component.generator.classical` | E = e^{jδ}·Vfield(Eq = Vfield は入力 u、Ed = 0) |
| `component.generator.one_axis` | E = e^{jδ}·Eq(状態 Eq、Ed = 0) |
| `component.generator.two_axis` | E = e^{jδ}(Eq − jEd)(状態 Eq、Ed) |
| `component.generator.park` | E = e^{jδ}(Eq'' − jEd'')、Eq'' = ((Xd''−Xls)Eq + (Xd'−Xd'')ψd)/(Xd'−Xls)、Ed'' = ((Xq''−Xls)Ed − (Xq'−Xq'')ψq)/(Xq'−Xls) |
| `component.generator.droop` | E = e^{jδ}·Vfield(Eq = Vfield は入力 u、Ed = 0) |

## 3. 入口とデータの組み立て

| 入口 | 描くもの |
|---|---|
| `G = net.plot_spring_model(Dimension=2, Parent=[])` | 平衡点(母線の `c_Vequilibrium`、`c_Iequilibrium`、機器の `rv_Xequilibrium`、`rv_Uequilibrium`)。1 時刻 |
| `G = res.plot_spring_model(...)`(`ResultODE`) | 全出力時刻。`G.animate()`、`G.export_video(file)` が使える |
| `G = res.plot_spring_model(...)`(`ResultPF`) | 母線だけ(1 時刻) |

`Dimension` は 2(`GraphSpring2D`)か 3(`GraphSpring3D`)で、出力 G はその図のオブジェクトです。`net.plot_spring_model` は前提条件の規則(`api-design.html#preconditions`)に従い、`initialize` の前や、編集で古くなった系統では `GUILDA:PowerNetwork:SpringModelStale`(「Run net.initialize() first」)で止まります。判定は `simulateFcn_check` と同じで、入力の編集(`set_input`)も古くなった理由に数えます。

### 3.1 共通の組み立て関数 `tools.spring_model_data`

3 つの入口は同じ関数 `_GUILDAsystem/+tools/spring_model_data.m` でデータを作ります。

- 入力はネットワークのスナップショット `struct(net, false)` と、母線の V、I(n_bus × n_t)と機器ごとの x、u(n × n_t)だけです。ネットワークのオブジェクトを読まないので、結果の `sct_network` にもそのまま使えます。`net.plot_spring_model` も `struct(net, false)` を作って渡します。
- 置き場所の理由: 3 つのクラス(`PowerNetwork`、`ResultODE`、`ResultPF`)は別のフォルダにあり、private 関数は共有できません。`GraphSpringBase` の Static Hidden メソッドにすると、データだけを扱う描画クラスが系統のスナップショットの形を知ることになります。`+tools` の関数ならクラスのメンバーを増やさず、3 か所から呼べます。

規則:

- **ノード**: 全母線(種類 "bus"、タグは母線のタグ)。続けて、クラスの `get_spring_node` が空でない `cv_E` を返す機器ごとに種類 "component" のノード(タグは機器のタグ)と、母線 ↔ ノードのばね(`sv_edge` は機器のタグ)。静的メソッドはクラス名から呼びます(`feval(class + ".get_spring_node", ...)`)。結果のスナップショットでも動きます。
- **ブランチのばね**: 各ブランチの両端の母線(`sv_edge` はブランチのタグ)。スナップショットの `a_Bus` は `"net.a_Bus{i}"` の文字列なので、番号を読み取ります。
- **矢印**: 自身のノードごとに 1 組(その `rv_P`、`rv_Iq`)。自身のノードを持たない機器が 1 台でもある母線ごとに 1 組。この組の電流は I_rest = 母線注入電流 − その母線の自身のノードを持つ機器の `cv_I` の和で、基底の `Component.get_spring_node` で母線電圧において評価します。
- **見た目**: `sv_marker`、`rv_size`、`sv_color` は母線または機器の `graph` パラメータの `Marker`、`MarkerSize`、`Color`。自身のノードはその機器の値を使います。
- **|E| の円**: 自身のノードの |E| が全時刻で一定(相対的な幅 < 1e-9。例: AVR のない classical)なら `rv_circle = |E|`、そうでなければ NaN。1 時刻のデータ(平衡点、`ResultPF`)では一定かどうか判断できないので描きません(2 時刻以上のときだけ)。
- **トリップ**: トリップ中の機器の状態は NaN です。自身のノードとそのばね・矢印はその時刻に描かれず、母線の矢印ではその電流を 0 として数えます(`ResultODE.plot_spring_model` のヘルプに記載)。
- **`ResultPF`**: 機器の状態がないので `OwnNode=false` で呼び、機器のある母線ごとに母線注入(`Iphasor`)の矢印を 1 組置きます。

## 4. 決定事項

- クラス名 `GraphSpring*` はユーザーの選択です(役割を先頭にする `DrawerSpring*` ではなく、命名規則の意図的な例外)。
- 入口は `net.plot_spring_model`(平衡点)と、結果の `ResultODE.plot_spring_model`(アニメーション)と `ResultPF.plot_spring_model` です。解析後の図は結果の `plot_*` で描くという api-design の規則に従います。壊れていた旧 `net.plot_spring_model(mode)`(存在しない `GraphMassSpring` を呼んでいた)は置き換えました。
- `ResultPF` は機器の状態を持たないので、母線だけを描きます。
- ノードの既定の大きさは固定です(母線 5、機器 15)。`graph` の `MarkerSize` で個別に変えられます。

## 5. 未決事項

- 慣性 M に応じたノードの大きさ(現在は固定の既定値)。
- 有効電力の矢印に、電気的な P ではなく機械入力 Pmech を使うか(ユーザーの 3D のスクリプトは Pmech)。
- ほかの機器クラス(グリッドフォーミングのインバータ、自身のノードを持つ負荷など)は、`get_spring_node` を上書きすれば後から自身のノードを持てます。
- `GraphSpring2D` の `RMax` の既定 1.5 pu を超える電圧(例: `Tutorial3bus` の 2 pu)は格子の外に描かれます。入口で自動に合わせるかは未決です。
