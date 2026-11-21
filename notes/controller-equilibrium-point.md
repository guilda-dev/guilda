# ローカル制御器の get_equilibrium を引数だけの関数にする (提案)

ブランチ: `fix/controller-equilibrium-point`(`refactor/design-alignment` から作成)。
`notes/cpf-operating-points.md` の未解決の点 1 の続きです。前半は調査と提案です。ユーザーの判断(2026-11-19)と実装は末尾の「決定事項」と「実装」にまとめています。

## 結論

- 保存された平衡点を get_equilibrium の中で読む組み込みの制御器は `pss-retrofit` と `local-LQR` の 2 つだけです。
- 機器の状態 x を `get_equilibrium(obj, V, u, x)` の 4 番目の引数で渡せば、この 2 つは引数だけの関数になります。3 引数で書かれた利用者の制御器は、呼び出し側が 3 引数で呼び直すので、今までどおり動きます。
- ただし、この変更だけでは、依頼にあるテスト(ステップ k の `net.get_sys({res, k})` が、負荷を (1+λ) 倍して `initialize` した系統の `get_sys()` と一致する)は**成り立ちません**。2 つの制御器は、`initialize` のときの平衡点でゲイン K などを設計し、その値をモデル関数の f_* ハンドルに入れています。`initialize` し直すと K が設計し直されるので、A 行列が変わります(下の「実験」)。
- 推奨は **案 1(設計は initialize のときのまま、x を引数で渡す)** です。テストは「ステップ k の点の制御器の行が、その点の機器の x と一致する」ことと、「`get_sys({res, k})` が、同じ系統(設計は変えない)をその点で線形化した結果と一致する」ことで確かめます。

## 調査: get_equilibrium が読む値

`_GUILDAobject/+controller` のすべての get_equilibrium を確認しました。

| 制御器 | 引数以外に読むもの | 判定 |
|---|---|---|
| `avr-DC1`, `avr-ST1`, avr の abstract | `tab_parameter`(パラメータ) | 問題なし |
| `avr-static`, `gov-static` | `a_Component.sv_u`(入力の名前。値ではない) | 問題なし |
| `gov-LPT1/3/4` | `tab_parameter`、`initial_output(u)` | 問題なし |
| `pss-PSS1`, pss の abstract | `tab_parameter` | 問題なし |
| **`pss-retrofit`** | `observed_component().rv_Xequilibrium`(発電機の保存された x) | hat_x と uc が保存値 |
| **`local-LQR`** | `a_Component.rv_Xequilibrium`(機器の保存された x) | uc が保存値 |
| `agc-broadcast-PI`(グローバル) | `controlledUnits` の数 | 問題なし |

`c_Vequilibrium`、`rv_Uequilibrium`、`parent` を get_equilibrium で読む組み込みの制御器はありません。

### get_equilibrium 以外で平衡点に依存するもの

2 つの制御器は、`initialize` のときの平衡点で設計した値を f_* ハンドルの param に入れています。

- `pss-retrofit`(`set_odefcn.m`): K = lqr(E\A_d, E\B)、A_d = df/dx、補償器が使う u* = 発電機の `rv_Uequilibrium`。いずれも平衡点での値です。線形化の値も A_d、K、u*(`f_JacobiDx(t, x, V, u*)`)に依存します。
- `local-LQR`(`initialize.m`、`design_gain.m`、`set_odefcn.m`): K(機器と無限大母線のモデルで設計)、x0 = 自分の `rv_Uequilibrium`(= 機器の x*)、u0 = 機器の入力の平衡値。出力は `y = u0 - K (x - x0)` でアフィンなので、線形化は K だけに依存します。

### 呼び出し側

ローカル制御器の get_equilibrium を呼ぶのは次の 3 か所です。

1. `@Component/set_equilibrium.m`(`initialize`): 機器の平衡点を保存した**後**に呼ぶので、保存値を読んでも正しい値になります。
2. `@SolverCPF/private/operating_points.m`(連続潮流計算の各ステップ): 観測している入力(`iv_obsX` / `iv_obsY` が正)はステップの x と y で置き換えるので、uc は正しくなります。`pss-retrofit` の状態 hat_x だけが平衡点の値のまま残ります。
3. `@PowerNetwork/private/stability_point.m`(安定度制約付き OPF の点): 観測している入力を**置き換えていません**。そのため `local-LQR` の uc も `pss-retrofit` の hat_x と uc も、`initialize` のときの x のままです。依頼の範囲(「別の点を渡す呼び出し側」)に含まれるので、同じ変更で直すことを提案します。

## 実験 (3 母線、gen-1axis、ノーズの半分のステップ、λ = 1.54)

`calculate_continuation_powerflow(LoadBus="B003")` のステップ k と、負荷を (1+λ) 倍して `initialize` した系統を比べました。

| 制御器 | 運転点の最大差 | A の相対差 | K(初期) | K(ステップ k で再設計) |
|---|---|---|---|---|
| pss-retrofit (R=0.01) | 0.51(`hat_Eq`) | 0.50 | [-1.96 -1463 7.63] | [0.98 -966 6.73] |
| avr-ST1 + local-LQR | 2e-7 | 0.075 | 2 行 3 列 | 値が変わる |

- `local-LQR` は、uc がすでに置き換えられているので運転点は一致しますが、K の違いで A が 7.5% 変わります。
- `pss-retrofit` は、hat_x の違いと K、A_d、u* の違いの両方で A が変わります。固有値も変わります(例: -9.57 と -7.35)。

## 提案: 引数の追加(どの案でも必要)

- 抽象メソッドを `[x, u] = get_equilibrium(obj, V, u, x)` にします。`x` は制御器の木の根にある機器(入れ子の PSS でも発電機)の、その点での状態です(`sv_x` の順)。
- `pss-retrofit`: `hat_x = x`、`uc = x`。`local-LQR`: `uc = x`。どちらもモデルを読みません。
- 3 か所の呼び出し側は 4 つの引数で呼びます。`set_equilibrium` は保存する x、`operating_points` はステップの x、`stability_point` はその点の x を渡します。`stability_point` は `operating_points` と同じく、観測している入力をその点の x と y で置き換えます。
- 利用者の制御器(3 引数)との互換: 4 引数で呼んで `MATLAB:TooManyInputs` になったら 3 引数で呼び直します。この処理は 1 か所にまとめたいので、新しいメンバーが 1 つ要ります(下の判断 2)。`metaclass` の `InputNames` は @フォルダーのメソッドでは `varargin` になるので、引数の数の判定には使えません(確認済み)。
- export / import: 変更はありません。利用者の制御器のクラスファイルはそのままコピーされ、3 引数でも動きます。組み込みの制御器は既に変換済みで、get_equilibrium を書き出していません。
- テンプレート: 専用のテンプレートはありません。`_GUILDAdoc/developer/model-implementation.html` の表の行(`[x,u] = get_equilibrium(obj,V,u)`)と例 `simple_avr` を更新します(4 番目の引数は省略できる、と書きます)。`LocalController.m` の抽象メソッドの help も同様です。
- グローバル制御器の `get_equilibrium(obj)` は変えません。組み込みの AGC は保存値を読みません(ただし下の「範囲外の気づき」)。

## 判断が必要な点

### 判断 1: ステップ k での制御器の設計

| | 案 1(推奨): 設計は initialize のまま | 案 2: 各ステップで設計し直す |
|---|---|---|
| 意味 | 実際の制御器(K、A_d、u*、x0、u0 は固定)のまま負荷を増やす | 各ステップで `initialize` し直したのと同じ |
| 変更 | 上の引数の追加だけ | 制御器の設計を、モデルに書かずにその点で返すメソッドが要る(新しいメンバー)。`get_sys({res, k})` と `SolverLIN` の区間ごとに、その点で設計した制御器のヤコビアンを使う仕組みが要る |
| `get_sys({res,k})` と再 initialize | 一致しない(K などの差) | 一致する(依頼のテストが成り立つ) |
| 運転点 | `pss-retrofit` は hat_x = x_k、Vpss = 0 だが、補償器は u* を初期の値で使うので dhat_x ≠ 0。`local-LQR` は出力 `u0 - K(x_k - x0)` が、点の機器の入力 u_k と一致しない(閉ループの平衡点ではない) | 閉ループの平衡点 |
| 計算時間 | 変わらない | ステップごと・制御器ごとに lqr |

- 案 1 を推奨する理由: 依頼の目的(「ステップ k の点で、制御器の x と uc が機器の x と合う」)を、新しい公開メンバーを 1 つ(判断 2)だけで満たせます。ゲインは制御器の設計(実機では固定)であり、負荷の増加とともに暗黙に設計し直すのは、CPF の結果の意味を変えます。
- 案 1 の注意点: 上の表のとおり、この 2 つの制御器では、ステップ k の点は厳密には閉ループの平衡点ではありません。これは「設計は固定、基準値はステップごと」という今の CPF の扱い(AVR の Vref、調速機の Pref はステップごとに get_equilibrium で決まる)と、x0、u0、u* を固定値として f_* に入れている 2 つの制御器の作りが合わないためです。ResultCPF と 2 つの制御器の help に書きます。
- 案 1 のテスト(依頼のテストの代わり): (a) ステップ k の点の `pss-retrofit` の hat_x と uc、`local-LQR` の uc が、その点の機器の x と一致する。(b) `net.get_sys({res, k})` が `net.get_sys(rv_point)` と一致する。ここで `rv_point` は、負荷を (1+λ) 倍して `initialize` した別の系統の平衡点(変数マップの Equilibrium)で、`net` の設計は変えません。(c) `stability_point` の点でも同じく一致する。
- 案 2 にする場合は、新しいメンバーの名前と、`SolverLIN` の変更範囲を別に提案します。

### 判断 2: 互換の呼び出しをまとめるメンバー

4 引数で呼び、`MATLAB:TooManyInputs` なら 3 引数で呼び直す処理を、3 か所の呼び出し側で共有します。候補:

- (推奨) `LocalController` の Hidden で Sealed なメソッド `get_equilibrium_at(obj, V, u, x)`。利用者からは見えず、3 か所はこれを呼びます。
- 各呼び出し側に同じ数行を書く(新しいメンバーは不要。ただし「1 回しか使わない局所関数は作らない」規則により、3 か所に同じコードが入ります)。

### 判断 3: stability_point も直すか

上の「呼び出し側」の 3 のとおり、安定度制約付き OPF の点では、観測している入力を置き換えていないので、`local-LQR` と `pss-retrofit` の値が保存値のままです。推奨は、この作業で同じく直すことです。

## 範囲外の気づき (直していません)

- グローバル制御器の x と uc は、CPF の各ステップで平衡点の値のままです(`notes/cpf-operating-points.md` の 6.)。組み込みの AGC は uc = 0(周波数偏差)なので問題ありませんが、母線電圧や発電機の出力を観測する利用者のグローバル制御器では、uc がステップの値と合いません。`operating_points` で、ローカル制御器と同じように `iv_obsX` / `iv_obsY` の入力を置き換えるのが自然です。
- 実験で、`avr-ST1` の後に `local-LQR` を付けると、同じ枠の AVR を置き換える警告(`GUILDA:Component:ReplaceController`)が出ました。`test_I71_layer_get_sys.m` の同じ手順も同じです(仕様どおりですが、テストの意図とずれている可能性があります)。

## 決定事項 (2026-11-19、ユーザーの判断)

ユーザーの言葉: 「案1、内部メソッド追加、stability_pointも直す」。

- 判断 1: 案 1。制御器の設計(K、A_d、u*、x0、u0)は `initialize` のときのままにし、機器の x を 4 番目の引数で渡します。ステップ k の点がこの 2 つの制御器では厳密には閉ループの平衡点でないことを、ResultCPF と 2 つの制御器の help に書きます。
- 判断 2: `LocalController` の Hidden で Sealed なメソッド `get_equilibrium_at(obj, V, u, x)` を加えます。新しいメンバーはこれだけで、3 か所の呼び出し側はすべてこれを使います。
- 判断 3: `stability_point` も同じ変更で直します。
- 範囲外: CPF の各ステップでのグローバル制御器の uc。

## 実装

- `@LocalController/get_equilibrium_at.m`(新規): `get_equilibrium(V, u, x)` を呼び、そのメソッド呼び出し自体の `MATLAB:TooManyInputs`(スタックの先頭が get_equilibrium_at)のときだけ `get_equilibrium(V, u)` で呼び直します。get_equilibrium の中のエラーはそのまま出ます。`LocalController.m` の抽象メソッドを `get_equilibrium(obj, V, u, x)` にし、help に「引数だけから計算する」「x は省略できる」と書きました。
- 組み込みの制御器: `pss-retrofit` は hat_x = uc = x、`local-LQR` は uc = x(どちらも x は必須)。ほかの AVR、調速機、PSS の get_equilibrium は `x = zeros(0,1)`(使わない)を加えました(呼び直しの例外を毎回出さないため)。
- 呼び出し側: `Component.set_equilibrium` は保存する x、`operating_points.m` はステップの x を渡します。`stability_point.m` はその点の x を渡し、観測している入力(`iv_obsX` / `iv_obsY`)をその点の x と `f_Y(0, x, V)` で置き換えます(`operating_points` と同じ)。
- help: `ResultCPF`、`Retrofit`、`local_LQR` の class help に、別の点では設計が initialize のままで、点が厳密には平衡点でないことを書きました。
- ドキュメント: `model-implementation.html` の契約の表の行と例 `simple_avr`(`get_equilibrium(obj, V, u, ~)`)、`feature-initialize.html` の INIT-08 と実装すべきものの表(日英)。

## テスト

- F94 `ControllersThatObserveTheStatesGetTheStateOfTheComponentAtAStep`(large に登録): pss-retrofit と local-LQR のそれぞれで、(a) ステップ k の点の制御器の行(Retrofit の hat_x と uc、LQR の uc)がその点の機器の x と一致する、(b) `net.get_sys({res, k})` が、負荷を (1+λ) 倍して initialize した別の系統の平衡点での `net.get_sys(rv_point)` と一致する(相対 1e-5)、設計 K が変わらない。
- F94 `ALocalControllerWithGet_equilibrium_obj_V_U_StillWorksAtTheSteps`(medium): 3 引数の `ObserveStub`(Input="Xall")が `get_equilibrium_at` と CPF の各ステップで動き、uc がステップの x になる。
- F4 `Stability_constrainedOPFGivesTheControllersThatObserveTheStatesTheStateAtItsPoint`(large): (c) IEEE9 の B002 に pss-retrofit、B003 に local-LQR を付け、制約なしの解の点の MinDampingRatio と MaxRealPart が、`initialize(Method="OPF")` の平衡点で同じ系統を線形化した値と一致する(1e-6)。
- 変更前のコードで実行すると、新しい 3 件はすべて FAIL になることを確かめました(F94 の 1 件目は pss-retrofit の hat_x、F4 は MinDampingRatio)。
- small(model, cpf, opf, linearize, env): 190 件、PASS 189、SKIP 1(MATPOWER がない)。
- medium(model, cpf, opf, linearize, env): 521 件、PASS 519、FAIL 1、SKIP 1。FAIL は F36 `TheNetworkHasEveryRegisteredModelKeyAndAnEmptyBus`(「Component のキーが網にない: load-current」)で、この変更の前のコミット d14a36cf でも同じく FAIL します(この作業とは無関係。`test_F95_load_current` が test_categories.m に未登録という警告も出ます)。
