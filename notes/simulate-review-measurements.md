# net.simulate の実測結果

`PowerNetwork.simulate` の挙動と性能を実際に動かして確認した記録です。改善案は含みません。

## 結論

- **編集検知、再現性、副作用は設計どおりに動きました。** 平衡点に影響する編集はすべて停止し、古い値で走るケースはありませんでした。同じ呼び出しの結果は完全に一致し、エラーや TimeLimit 停止の後の再実行も正常でした。
- **問題は実行の設定と事象の入力にあります。** `Solver` 指定が効かない、制御器付き発電機の trip で必ず落ちる、誤った指定が黙って無視される、という高重要度の問題があります。
- **ボトルネックは規模で変わります。** IEEE14 は右辺評価が約68%を占めます。IEEE68 は右辺評価が約49%、線形代数(`odesolve` と `odefactorize`)が約29%です(いずれもプロファイラあり)。

## 測定条件

| 項目 | 内容 |
|---|---|
| 環境 | macOS (Apple Silicon, MACA64)、MATLAB R2026a (26.1.0.3203278)、論理12コア |
| 対象コード | コミット `951800e` |
| 再現方法 | [simulate-review-measurements.m](simulate-review-measurements.m) の先頭に記載 |
| 実行の範囲 | 1, 2, 6節と 3, 4, 5節は別の実行です。両者の間で変えたのは、回数の集計、線形比較、負荷の記録だけです |
| 負荷 | 他のセッションと同じマシンで測定しました。1節開始時の load average は 2.2、測定中は 5〜8 です |
| 既定の設定 | `Tolerance=1e-4`、`AbsoluteTolerance=1e-6`、`Progress="none"`。特記がなければ `TimeLimit=Inf` |

**時間の精度には注意が必要です。** 同じケース(IEEE68、fault、`ode15s`)の中央値が、負荷の高い回で 18.3 s、今回の表で 7.6 s でした。系統間やケース間の大まかな比較にとどめ、小さな差は判断に使わないでください。

**回数の取得方法は次のとおりです。**

- 右辺評価回数とヤコビアン評価回数は、`profile` の `NumCalls` から取りました(コアを変更しないため)。
- ステップ数は直接取得できないので、出力点数 `n_t` で代用しました。

**IEEE14 の制御器は測定側で付けました。** `network.IEEE14bus` は制御器なしの系統なので、「制御器あり」は全発電機に既定値の `AVR_ST1` と `PSS1` を付けたものです。

## 1. 性能

条件は `time=[0,10]`、fault は先頭母線 `[1,1.05]` です。反復回数は IEEE9 と IEEE14 が5回、IEEE68 が3回で、ウォームアップ後の中央値を示します。

- 制御器: AVR と PSS の有無です。
- ソルバ: `ode23t*` は `Solver` と `SolverOptions=ODE23t` の両方を指定したものです。`Solver="ode23t"` だけの指定は `ode15s` で動くため(問題 H1)、比較には `ode23t*` を使います。
- 結果: `rm_variable`、`rm_I`、`rv_t` の合計です。

| 系統 | 制御器 | 外乱 | ソルバ | 変数数 | initialize [s] | simulate 初回 [s] | simulate 中央値 [s] | n_t | 右辺評価 | ヤコビアン | 結果 [MB] |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| IEEE9 | あり | fault | ode15s | 57 | 0.39 | 1.36 | 0.37 | 368 | 707 | 10 | 0.22 |
| IEEE9 | あり | なし | ode15s | 57 | 0.14 | 0.51 | 0.22 | 13 | 20 | 1 | 0.01 |
| IEEE9 | あり | fault | ode23t* | 57 | 0.19 | 1.88 | 1.07 | 769 | 1540 | 10 | 0.47 |
| IEEE9 | あり | なし | ode23t* | 57 | 0.19 | 0.69 | 0.23 | 13 | 22 | 2 | 0.01 |
| IEEE9 | なし | fault | ode15s | 39 | 0.16 | 1.06 | 0.38 | 313 | 860 | 55 | 0.15 |
| IEEE14 | あり | fault | ode15s | 122 | 0.25 | 3.19 | 2.20 | 919 | 2013 | 29 | 1.11 |
| IEEE14 | あり | なし | ode15s | 122 | 0.22 | 0.87 | 0.36 | 11 | 13 | 1 | 0.01 |
| IEEE14 | あり | fault | ode23t* | 122 | 0.22 | 6.72 | 5.84 | 2317 | 5243 | 46 | 2.80 |
| IEEE14 | なし | fault | ode15s | 92 | 0.21 | 1.57 | 0.79 | 523 | 1121 | 21 | 0.51 |
| IEEE14 | あり+AGC | fault | ode15s | 123 | 0.24 | 3.00 | 1.98 | 715 | 1497 | 11 | 0.87 |
| IEEE68 | あり | fault | ode15s | 382 | 0.81 | 9.03 | 7.62 | 702 | 1245 | 3 | 2.92 |
| IEEE68 | あり | なし | ode15s | 382 | 0.79 | 1.66 | 1.09 | 11 | 13 | 1 | 0.05 |
| IEEE68 | あり | fault | ode23t* | 382 | 0.79 | 15.08 | 12.94 | 1294 | 2125 | 4 | 5.37 |
| IEEE68 | なし | fault | ode15s | 286 | 0.78 | 3.94 | 2.93 | 286 | 648 | 20 | 0.97 |

`initialize` はネットワーク構築込みの時間から構築のみの時間を引いた値です。初回の測定で先頭行だけ大きいのは、ウォームアップの影響と考えられます(推測)。

その他の測定値は次のとおりです。

| 項目 | 結果 |
|---|---|
| 模擬時間 `[0,100]`(IEEE14、制御器あり、fault) | 中央値 6.94 s、n_t=3254、結果 3.93 MB |
| 計算スレッド1(fault、`ode15s`、5回) | IEEE14 は 2.46 s、IEEE68 は 5.20 s |
| 結果オブジェクトのシリアライズ量 | IEEE68 の外乱なしで 6.19 MB、fault で 9.06 MB。`n_t` が小さくても大きいのは、ネットワークへの参照を含むためと考えられます(未確認) |
| `sol.odeResults` の読み取り 1回 | IEEE9 は約0.18 s、IEEE14 は約0.24 s、IEEE68 は約0.42 s |
| 線形化ブロックの非零率 | IEEE9 は 9.9%、IEEE14 は 6.1%、IEEE68 は 1.8% |

IEEE68 は計算スレッド1の方が既定のスレッド数より速い結果でした(5.20 s 対 7.62 s)。ただし他プロセスの負荷がある状態の測定なので、スレッド数そのものの効果とは断定できません。

### 既定の TimeLimit (10 s) の影響

IEEE68、fault、新規ネットワーク、`TimeLimit` は既定のままです。

| time | 負荷の高い回 | 負荷の低い回 |
|---|---|---|
| `[0,10]` | flag=0、tEnd=2.79 | flag=1、tEnd=10 |
| `[0,30]` | flag=0、tEnd=3.02 | flag=0、tEnd=19.50 |

どちらの場合も、停止時に画面表示や警告はありませんでした。

## 2. ボトルネック

条件は `time=[0,10]`、fault は先頭母線 `[1,1.05]`、`ode15s` で、プロファイラを1回かけました。プロファイラありの時間は IEEE14 が 4.19 s(なしで 2.34 s)、IEEE68 が 10.76 s(なしで 7.86 s)です。プロファイラの分だけ、MATLAB コードの比率は実際より大きく出ます。

### 時間配分(total、重複あり)

| 処理 | IEEE14 [s] | IEEE14 [%] | IEEE68 [s] | IEEE68 [%] |
|---|---:|---:|---:|---:|
| `ode.solve`(下記の右辺評価、ヤコビアン、線形代数を含む) | 3.29 | 78.5 | 8.94 | 83.1 |
| 右辺評価 `getODEFunction` | 2.84 | 67.9 | 5.29 | 49.1 |
| ヤコビアン `getODEJacobian` | 0.15 | 3.7 | 0.09 | 0.8 |
| 結果構築 `odeSimulationResult` | 0.42 | 10.1 | 0.95 | 8.8 |
| 前処理 `get_admittance_matrix` | 0.19 | 4.5 | 0.35 | 3.3 |

このほかの前処理(`require_equilibrium`、`initialize_index`、`table`、`setEventCondition`、`getInitialCondition`)は、IEEE14 で合計 0.15 s(約3.5%)でした。`CalculateInitialCondition` はどちらの fault ケースでも呼ばれていません。

### IEEE68 の self time 上位

| 順位 | 関数 | 呼出数 | self [s] | self [%] |
|---:|---|---:|---:|---:|
| 1 | `odesolve` | 1245 | 2.07 | 19.2 |
| 2 | `odefactorize` | 128 | 1.07 | 9.9 |
| 3 | `Component.get_dx_algebraic` | 63495 | 0.65 | 6.0 |
| 4 | `getODEFunction` | 1245 | 0.63 | 5.9 |
| 5 | `PSS1.fcn_dx` | 19920 | 0.56 | 5.2 |
| 6 | `ismemberR2012a` | 40644 | 0.51 | 4.7 |
| 7 | `PSS1.fcn_y` | 19920 | 0.49 | 4.5 |
| 8 | `LocalController.get_dx_algebraic` | 39840 | 0.43 | 4.0 |

### IEEE14 の self time 上位

| 順位 | 関数 | 呼出数 | self [s] | self [%] |
|---:|---|---:|---:|---:|
| 1 | `Component.get_dx_algebraic` | 34221 | 0.38 | 9.1 |
| 2 | `getODEFunction` | 2013 | 0.29 | 7.0 |
| 3 | `PSS1.fcn_dx` | 10065 | 0.27 | 6.5 |
| 4 | `LocalController.get_dx_algebraic` | 20130 | 0.26 | 6.2 |
| 5 | `ismemberR2012a` | 20378 | 0.24 | 5.8 |
| 6 | `PSS1.fcn_y` | 10065 | 0.24 | 5.7 |

### 右辺評価の内訳として分かること

- 右辺1回あたりの呼び出しは、IEEE68 で `Component.get_dx_algebraic` が51回、`LocalController.get_dx_algebraic` が32回です(呼出数を1245で割った値)。
- `ismember` は右辺1回あたり32回呼ばれており、IEEE68 では total 0.78 s(7.2%)です。入力名の対応付けを毎回行っているためです([get_dx_algebraic.m:29](../_GUILDAsystem/@Component/get_dx_algebraic.m:29)、[LocalController/get_dx_algebraic.m:27](../_GUILDAsystem/@LocalController/get_dx_algebraic.m:27))。
- `rv_Uoffset` の無名関数は呼び出しあたり約3 µs(プロファイラなし)で、モデル関数 `f_dx` の約4〜5 µs に近い大きさです。
- ヤコビアンは密行列で組み立てて返しています([odeSimulator.m:495](../_GUILDAsystem/_auxiliary/@odeSimulator/odeSimulator.m:495))。IEEE68 の線形化ブロックの非零率は 1.8% です。疎行列にしたときの効果は測っていません。

外乱なしのケース(右辺評価13回)でも IEEE14 は 0.36 s、IEEE68 は 1.09 s かかっており、これが積分以外の固定費の目安です。

## 3. 編集検知

条件は IEEE9(AVR+PSS)、fault B007 `[1,1.05]`、`time=[0,3]`、`Tolerance=1e-6`、`AbsoluteTolerance=1e-8` です。編集前の応答と、編集後に `initialize` した応答の両方と比較し、差が 1e-5 未満なら一致としました。

| 編集 | 結果 | 補足 |
|---|---|---|
| 発電機 D、M(`tab_parameter.dynamics`) | 停止 | |
| 発電機 D(`tab_parameter` 全体の代入) | 停止 | |
| 発電機 D(`para_dynamics.D` を直接) | 停止 | |
| 発電機 D を変更して元の値へ戻す | 停止 | 値が同じでも編集として扱います |
| 複製した表だけを変更(代入なし) | 影響なしで実行 | モデルは変わっていません |
| ブランチ X、tap(`tab_parameter`)、X(`para_dynamics`) | 停止 | |
| PV→PQ(発電機 Q を NaN から値へ) | 停止 | |
| PQ→PV(負荷 Q を NaN へ) | 停止 | |
| 負荷 P、母線 V | 停止 | |
| スラック母線の変更 | 停止 | |
| Hz を 60→50 | **新しい値で実行** | `initialize` 後の応答と差 0、事故前の変化 4.7e-15。設計どおりです |
| baseMVA を 100→200 | 停止 | |
| AVR、PSS、AGC のパラメータ(`para_dynamics`) | 停止 | |
| AVR の追加、差し替え | 停止 | |
| LQR の追加(AVR を置換) | 停止 | |
| 大域制御器の追加、削除 | 停止 | |
| 負荷の削除、ブランチの削除 | 停止 | |
| 母線 Vmax(`operation`)の編集 | 影響なしで実行 | 設計どおりです |

停止時のメッセージはすべて `GUILDA:PowerNetwork:EquilibriumStale` で、編集箇所と対処を示します。

> The equilibrium of 'PowerNetwork' is out of date: edited since the last initialize (SG1B002/B002/PowerNetwork: edit D). Run net.initialize() first to recompute the equilibrium.

**古い値で走るケースはありませんでした。**

直接の書き込みも確認しました。

- 拒否されるもの: `gen.rv_Xequilibrium`、`gen.f_dx`、`net.a_Bus`、`net.solver_ODE`、`bus.c_Vequilibrium`。
- 書き込めるもの: `gen.rv_Xoffset`(Hidden)。
- 制御器のパラメータ: `avr.tab_parameter.dynamics.X = ...` は `MATLAB:class:noSetMethod` で失敗します(問題 L2)。

## 4. 再現性と副作用

条件は IEEE14(全発電機に AVR+PSS)と AGC(SG1B001、SG1B002)、`time=[0,3]` です。発電機 trip は AVR 付きだと落ちるため(問題 H2)、制御器なし+AGC で測りました。

### 同じ呼び出しを2回

| 事象 | 完全一致 | n_t | flag |
|---|---|---:|---:|
| 外乱なし | 一致 | 11 | 1 |
| fault | 一致 | 194 | 1 |
| 発電機 trip(途中まで) | 一致 | 146 | -1(t=1.90 で停止) |
| 発電機 trip(最後まで) | 一致 | 146 | -1(t=1.90 で停止) |
| AGC trip | 一致 | 33 | 1 |
| offset | 一致 | 111 | 1 |
| input | 一致 | 96 | 1 |

複数の事象を実行した後のネットワークと、新規ネットワークの結果も完全に一致しました。事象の順序を入れ替えても完全に一致します。

### 実行前後のプロパティ

Hidden でない public プロパティは、どのケースでも変わりませんでした。変わったのは次の作業用データです。

| プロパティ | アクセス | 変わる場面 |
|---|---|---|
| `iv_odeX`、`iv_odeU`、`iv_odeY`、`iv_odeI` | public/Hidden | 毎回 |
| `rv_Xoffset`、`rv_Uoffset` | public/Hidden | 毎回 |
| `Bus.l_isFault` | 限定 | fault が最後まで続いたとき、true のまま残ります |
| `Component.l_isConnect` | 限定 | 発電機 trip が最後まで続いたとき、false のまま残ります |

残った値の影響は見つかりませんでした。事象が最後まで続いた後でも、`linearize` の行列、`get_sys` の A、潮流計算の差はいずれも 0 で、次の外乱なし実行は基準と完全に一致しました。

### エラーと TimeLimit 停止の後

| 場面 | 結果 | 再実行 |
|---|---|---|
| 入力関数のエラー(t>0.5) | `GUILDA:odeSimulator:PhaseFailed`、モデルの差分なし | flag=1、基準と完全一致 |
| 事故+trip 中に停止(下記) | `l_isFault=1`、`l_isConnect=0` が残り、AGC は `l_isConnect=1` に戻ります | flag=1、基準と完全一致 |
| `TimeLimit=1e-3` | flag=0、tEnd=0.1、表示も警告もなし | flag=1、基準と完全一致 |
| 制御器付き発電機の trip で異常終了(IEEE9) | `l_isConnect=0` が残ります | flag=1、変化 1.3e-14 |

「事故+trip 中」のケースは入力関数のエラーを狙いましたが、ソルバがその前に停止したため、エラーは発生しませんでした。したがって「事故中にエラーで抜けた後」は直接には確認できていません。

`TimeLimit` はフェーズごとの制限です。`TimeLimit=0.3` で17フェーズのとき、全体で 2.25 s かかっても flag=1 でした。

### net.solver_ODE と制御器の状態

- オプションを指定して実行した後も `net.solver_ODE` は同じハンドルで、値も変わりません。
- 渡した `SolverOptions` にも `OutputFcn` は書き戻されません。
- fault 実行の末尾で制御器状態は平衡点から 0.28 ずれていましたが、次の外乱なし実行の初期値は1回目と差 0、制御器の変化は 6.8e-13 でした。**内部状態は持ち越されません。**

### 事象オブジェクトの使い回し

| 場面 | 結果 |
|---|---|
| 同じ事象オブジェクトで2回 | 完全一致 |
| 大域制御器の追加、AVR の追加、負荷の削除の後に古い事象を使う | `MATLAB:innerdim`(一般的な次元エラー) |
| 別ネットワークの事象(同じ構成で D だけ違う) | **エラーなし**、flag=1。自分の応答との差 4.1e-7 |
| 別ネットワークの事象(負荷が違い、simulate 未実行) | `PhaseFailed`: 配列インデックスは正の整数… |
| 別サイズのネットワークの事象 | `MATLAB:subsassigndimmismatch` |
| 別ネットワークを実行した影響 | なし |

## 5. 引数と境界ケース

条件は IEEE14(AVR+PSS)、各ケース `TimeLimit=30`、ケースごとに新規ネットワークです。

### time

| 入力 | 結果 | メッセージの質 |
|---|---|---|
| 省略、`[]` | t=10 まで実行 | 事象なしのとき |
| `[]` + 事象 `[1,1.05]` | t=30 まで実行 | 事象 `[10,10.05]` なら 60、`[20,20.05]` なら 90 |
| 列ベクトル `[0;3]`、`[-1,2]`、`[1,3]` | 正常 | |
| スカラー `5` | `MATLAB:badsubscript` | 悪い: 原因が分かりません |
| `[3,0]`、`[0,NaN]`、`[NaN,3]` | `MATLAB:table:RowIndexOutOfRange` | 悪い |
| `[1,1]` | `MATLAB:badsubscript` | 悪い |
| `"abc"` | `MATLAB:badsubscript` | 悪い |
| `[0,1;2,3]`、`{0,1}`、事象を第1引数に | `MATLAB:validation:*`(位置1の引数が無効) | 普通 |
| `[0,1+1i]` | `PhaseFailed`: 値は実数でなければ… | 普通 |
| `[0,Inf]`(`TimeLimit=5`) | flag=0、t=5.5e8 まで積分 | 拒否されません |
| **`[0,1,2]`** | **flag=1、t=1 で終了** | **なし: 黙って短くなります** |
| **`[0,2,1]`** | **flag=1、t=2 で終了** | **なし** |
| **`[0,0.5,1,2,3]` + 事象 `[1,1.05]`** | **flag=1、t=0.5 で終了、事象は実行されず警告もなし** | **なし** |

### オプション

| 入力 | 結果 | メッセージの質 |
|---|---|---|
| `Foo=1` | `UnknownName`、有効な名前の一覧つき | 良い |
| 奇数個 | `InvalidPairs` | 良い |
| オプションの後の事象、位置引数 `123`、`{ev}` | `SimulateArguments`、正しい呼び方を表示 | 良い |
| 範囲外の `Tolerance`、`TimeLimit`、`Progress`、`Verbose`、`Export` | MATLAB の検証エラー、引数名つき | 良い |
| `Tolerance="a"` | 「値は正でなければなりません」 | 普通: 型の問題が伝わりません |
| `tolerance=1e-5`(小文字) | 受理 | 大文字と小文字を区別しません |
| `RelativeTolerance`(v3 の名前) | 動作し、`GUILDA:Deprecated:SimulateOptionName` の警告 | 良い |
| `Solver="ode99"` | 有効な値の一覧つきエラー | 良いが、一覧に DAE に使えない値も含まれます |
| `Solver="stiff"`、`"auto"` | `MATLAB:ode:SolverOptionsCannotBeModified` | 悪い: 受け付けないと言わず、原因が内部の設定です |
| `[ev1,ev2]`(事象の配列) | `MATLAB:maxrhs`: 入力引数が多すぎます | 悪い |

### ソルバ指定の効果

IEEE9、fault B007、`time=[0,3]` です。

| 指定 | n_t | `options.Solver` の記録 | 実際の動作 |
|---|---:|---|---|
| `Solver="ode15s"` | 193 | ode15s | ode15s |
| **`Solver="ode23t"`** | 193 | **ode23t** | **ode15s と時刻が完全一致** |
| **`Solver="ode23tb"`、`"ode23s"`、`"ode45"`** | 193 | **指定どおり** | **ode15s と時刻が完全一致** |
| **`net.solver_ODE.Solver="ode23t"` と保存** | 193 | **ode23t** | **ode15s と時刻が完全一致** |
| `Solver="ode23t"` + `SolverOptions=ODE23t` | 363 | ode23t | ode23t |
| `SolverOptions=ODE23t` のみ | 363 | **ode15s** | ode23t |
| `Solver="ode15s"` + `SolverOptions=ODE23t` | 363 | **ode15s** | ode23t |
| `Solver="ode23t"` + `SolverOptions=ODE15s` | 193 | **ode23t** | ode15s |
| `ode23tb`、`ode23s`、`ode45` + 対応する `SolverOptions` | - | - | `PhaseFailed`: MassSingular を 'yes' にできません |

### 事象

| 入力 | 結果 | メッセージの質 |
|---|---|---|
| 完全に範囲外 `[5,6]`、`[-2,-1]` | flag=1、`OutsideTimeSpan` の警告 | 良い |
| 一部範囲外 `[2,5]`、t0 より前から `[-1,0.1]` | 正常 | |
| 未知の `InputUnit`、`InputName` | `UnknownInputUnit`、`UnknownInputName` | 良い |
| **未知の `FaultBus`、`TripUnit`** | **flag=1、外乱なしと差 1.1e-12** | **なし: 黙って無視します** |
| **未知の `OffsetUnit`、`OffsetState`** | **flag=1** | **なし** |
| **逆順 `TimeSpan=[2,1]`** | **flag=1、外乱なしと差 1.1e-12** | **なし** |
| **`TimeSpan=[NaN,2]`** | **flag=1** | **なし** |
| **`InputValue` が名前より多い(3個対2個)** | **flag=1** | **なし** |
| **fault の `TimeSpan=1` または `[1,1]`** | **最後まで継続(`[1,3]` と差 0)** | **なし** |
| **同上 + 別の事象 `[1.5,2]`** | **t=1.5 で fault が終わります**(t=1.2 で \|V\|=0、t=1.7 で \|V\|=2.1) | **なし: 無関係な事象で結果が変わります** |
| `TimeSpan` が3要素、列ベクトル | MATLAB の検証エラー | 良い |
| 同じ tag の2事象、tag が `t1` や `NoAction1` | `MATLAB:table:DuplicateVarNames` | 普通: 事象の問題だと分かりにくいです |
| `OffsetState` と `OffsetValue` の個数違い | `MATLAB:sizeDimensionsMustMatch` | 悪い |
| 入力関数が行列を返す | `MATLAB:cellfun:NotAScalarOutput` | 悪い |
| 全発電機の trip | `UnfeasibleDAE`: ode15s に tspan と y0 が… | 悪い: 内部の呼び出しエラーが見えます |
| AVR の tag の trip | flag=1、外乱なしと差 1.06 | 何らかの効果がありますが、正しさは確認していません |
| 重なる fault(別母線 B008 と B009) | flag=-1、t=1.15 で停止 | 物理的な不安定か不具合かは未判定です |
| 重なる fault(同じ母線) | flag=1 | |
| 未初期化 | `EquilibriumStale`、編集ログと対処を表示 | 良い |

## 6. 精度の整合

### Tolerance と誤差

`time=[0,10]`、fault、`ode15s` で、基準は `Tolerance=1e-10`、`AbsoluteTolerance=1e-12`、時間は3回の中央値です。誤差は終了時刻の x と V の最大差(補間なし)です。

| 系統 | Tolerance | AbsoluteTolerance | 時間 [s] | n_t | 右辺評価 | 終了時刻の誤差 |
|---|---:|---:|---:|---:|---:|---:|
| IEEE9 | 1e-3 | 1e-6 | 0.60 | 324 | 670 | 8.0e-4 |
| IEEE9 | **1e-4** | **1e-6** | 0.87 | 408 | 826 | 8.2e-5 |
| IEEE9 | 1e-5 | 1e-6 | 0.92 | 473 | 946 | 7.3e-5 |
| IEEE9 | 1e-6 | 1e-6 | 1.00 | 529 | 1075 | 3.4e-5 |
| IEEE9 | 1e-7 | 1e-6 | 1.00 | 540 | 1098 | 2.8e-5 |
| IEEE9 | 1e-4 | 1e-8 | 0.93 | 493 | 976 | 5.6e-5 |
| IEEE9 | 1e-6 | 1e-8 | 1.30 | 811 | 1606 | 3.5e-6 |
| IEEE9 | 1e-8 | 1e-10 | 2.30 | 1693 | 3344 | 4.7e-8 |
| IEEE14 | 1e-3 | 1e-6 | 1.32 | 458 | 865 | 4.0e-3 |
| IEEE14 | **1e-4** | **1e-6** | 1.67 | 556 | 1030 | 1.1e-3 |
| IEEE14 | 1e-5 | 1e-6 | 1.90 | 661 | 1279 | 4.8e-4 |
| IEEE14 | 1e-6 | 1e-6 | 2.28 | 849 | 1603 | 1.1e-4 |
| IEEE14 | 1e-7 | 1e-6 | 2.29 | 875 | 1643 | 1.0e-4 |
| IEEE14 | 1e-4 | 1e-8 | 1.92 | 700 | 1243 | 4.7e-4 |
| IEEE14 | 1e-6 | 1e-8 | 3.01 | 1178 | 2350 | 2.5e-5 |
| IEEE14 | 1e-8 | 1e-10 | 5.19 | 2273 | 4401 | 5.3e-7 |
| IEEE68 | 1e-3 | 1e-6 | 6.04 | 466 | 846 | 6.0e-5 |
| IEEE68 | **1e-4** | **1e-6** | 8.02 | 702 | 1245 | 1.8e-3 |
| IEEE68 | 1e-6 | 1e-8 | 12.27 | 1200 | 1972 | 2.0e-5 |

太字が既定値です。読み取れることは次のとおりです。

- 既定の設定での終了時刻の誤差は、IEEE9 で 8e-5、IEEE14 と IEEE68 で 1〜2e-3 です。
- `Tolerance` を `AbsoluteTolerance` より小さくしても、誤差はほとんど減りません(IEEE9 と IEEE14 の 1e-6 と 1e-7)。
- IEEE68 は誤差が単調ではなく、1e-3 より 1e-4 の方が大きくなりました。1点の比較なので、位相のずれなどの影響がありえます(原因は未確認)。

ソルバ間の差(IEEE9、本当の `ode23t` との比較)は、`Tolerance=1e-4` で終了時刻 7.8e-4、`Tolerance=1e-8` で 1.1e-6 でした。許容誤差を小さくすると一致に近づきます。

### 線形化と小外乱応答

t=0 に SG1B002 の状態へ offset を与えた応答を比較しました。非線形側は `Tolerance=1e-8`、`AbsoluteTolerance=1e-10`、`time=[0,10]` です。線形側は `net.linearize` のブロックから代数変数を消去し、`expm` で自由応答を計算しました。比較は t≥0.05 の x と V です。

E が特異(ttr=0 の AVR などで質量が 0 の状態がある)なので、零行の状態も消去しています。微分状態は IEEE9 が 21/27、IEEE14 が 50/60 です。

| 系統 | 状態 | offset | 相対誤差 |
|---|---|---:|---:|
| IEEE9 | delta | 1e-4 | 5.9e-4 |
| IEEE9 | delta | 1e-3 | 5.0e-3 |
| IEEE9 | delta | 1e-2 | 4.9e-2 |
| IEEE9 | delta | 1e-1 | 0.45 |
| IEEE9 | omega | 1e-4 | 1.5e-2 |
| IEEE9 | omega | 1e-3 | 0.18 |
| IEEE14 | delta | 1e-4 | 1.3e-3 |
| IEEE14 | delta | 1e-3 | 9.3e-4 |
| IEEE14 | delta | 1e-2 | 9.3e-3 |
| IEEE14 | delta | 1e-1 | 9.4e-2 |
| IEEE14 | omega | 1e-4 | 1.7e-2 |
| IEEE14 | omega | 1e-3 | 0.17 |

**線形化と時間応答は整合しています。** 相対誤差は offset にほぼ比例しており、誤差が非線形項(2次)から来ているときの挙動です。例外の IEEE14 delta 1e-4 は、差の絶対値が 3e-7 と小さく、積分誤差の水準に近いと考えられます(推測)。

このほか、次のことも確認しました。

- `get_ss("Kron")` の有限固有値21個は、上記の手計算の固有値と最大 2.6e-12 で一致します。
- 固有値の実部の右端は、IEEE9 が 2.7e-12、IEEE14 が -4.2e-11 で、ほぼ 0 です。

## 問題点

実測で確認した問題です。原因の説明に「コード読解」とあるものは、該当箇所を読んだ上での判断で、修正して確かめたものではありません。

### 高

**H1. `Solver` 指定が無視され、結果には指定どおりの名前が記録される**
- `Solver="ode23t"` などでも `ode15s` で動きます。`net.solver_ODE.Solver` への保存も同じです。`result.options.Solver` は指定値のままなので、利用者は気づけません。逆に `SolverOptions=ODE23t` のみのときは `ode23t` で動いても記録は `ode15s` です。
- 原因(コード読解と `ode` オブジェクトの単体確認): `makeODE` が `Solver` の後に既定の `SolverOptions`(`ODE15s`)を代入し、`ode` がそれに合わせて `Solver` を戻します。
- 箇所: [makeODE.m:14](../_GUILDAsystem/_auxiliary/@odeSimulator/private/makeODE.m:14)、[odeSimulator.m:32](../_GUILDAsystem/_auxiliary/@odeSimulator/odeSimulator.m:32)、[simulate.m:19](../_GUILDAsystem/@PowerNetwork/simulate.m:19)。
- テストは記録された名前だけを見ているので通ります: [test_F6_simulation.m:151](../+DebugScript/test_F6_simulation.m:151)。

**H2. 制御器を持つ発電機の trip が必ず異常終了する**
- AVR、AVR+PSS、LQR のすべてで `MATLAB:TooManyOutputs`(IEEE9、IEEE14 の8通りとも)になります。trip が最後まで続く場合も同じで、それまでの結果は返りません。同梱の `network.IEEE9bus` の既定構成も該当します。
- 原因(コード読解): `getNextPhase` が2出力を要求しますが、制御器の `get_equilibrium` は出力を持ちません。PSS の呼び出しも同じ形です。
- 箇所: [odeSimulator.m:661](../_GUILDAsystem/_auxiliary/@odeSimulator/odeSimulator.m:661)、[odeSimulator.m:669](../_GUILDAsystem/_auxiliary/@odeSimulator/odeSimulator.m:669)、[AVR_ST1.m:66](../_GUILDAobject/+controller/+avr/@AVR_ST1/AVR_ST1.m:66)。
- テストは制御器のない別の発電機を trip しているので通ります: [test_F6_simulation.m:315](../+DebugScript/test_F6_simulation.m:315)。

**H3. 誤った事象指定が黙って無視され、flag=1 で返る**
- 未知の `FaultBus`、`TripUnit`、`OffsetUnit`、`OffsetState`、逆順や NaN の `TimeSpan` は、外乱なしの結果を成功として返します。tag の打ち間違いで「事故を模擬したつもり」になります。`InputUnit` と `InputName` だけは検証されています。
- 箇所: [odeEventSet.m:435](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:435)(検証は Input のみ)、[odeEventSet.m:187](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:187)、[odeEventSet.m:248](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:248)、[odeEventSet.m:354](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:354)。

**H4. `time` が3要素以上だと黙って2番目の値で終わる**
- `[0,0.5,1,2,3]` は t=0.5 で flag=1 になり、t=1 の事象は実行されず警告もありません。範囲外の警告は `time(end)`、実際の終了は `time(2)` を見ており、判定が食い違っています。
- 箇所: [getTimeSpan.m:13](../_GUILDAsystem/_auxiliary/@odeEventSet/private/getTimeSpan.m:13)、[odeEventSet.m:165](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:165)、[simulate.m:42](../_GUILDAsystem/@PowerNetwork/simulate.m:42)。

**H5. 既定の TimeLimit により、同じ呼び出しの結果がマシンの負荷で変わる**
- IEEE68 の `[0,10]` は、負荷の高い回で t=2.79 で停止し(flag=0)、低い回では完走しました。`[0,30]` は低負荷でも t=19.5 で止まります。`sol = net.simulate(...)` のように flag を受けないと、途中までの結果に気づけません。表示も警告も出ません。この呼び方は `IEEE68bus` のヘルプの例そのものです。
- 箇所: [DefaultTimeSimulation.json:32](../@GUILDA/config/DefaultTimeSimulation.json:32)、[odeSimulator.m:53](../_GUILDAsystem/_auxiliary/@odeSimulator/odeSimulator.m:53)、[odeSimulator.m:304](../_GUILDAsystem/_auxiliary/@odeSimulator/odeSimulator.m:304)、[IEEE68bus.m:50](../_GUILDAobject/+network/@IEEE68bus/IEEE68bus.m:50)。

### 中

**M1. fault の `TimeSpan` がスカラーまたは長さゼロだと、継続時間が他の事象で変わる**
- 次のフェーズ境界まで続くので、単独なら最後まで、別の事象があればその開始時刻までです。
- 箇所: [odeEventSet.m:189](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:189)。

**M2. AGC が制御する発電機の trip でソルバが停止する**
- IEEE14(制御器なし)で SG1B002 を trip すると、AGC ありは flag=-1(t=1.90)、AGC なしは完走します。AGC が制御していない SG1B003 の trip は完走します。
- 原因は未特定です。右辺は `u_connect*u_GC` を使い、ヤコビアンは `u_GC` をそのまま使っている点が候補です(コード読解、未検証)。
- 箇所: [odeSimulator.m:449](../_GUILDAsystem/_auxiliary/@odeSimulator/odeSimulator.m:449)、[odeSimulator.m:514](../_GUILDAsystem/_auxiliary/@odeSimulator/odeSimulator.m:514)。

**M3. 事象が作成時のネットワーク構成を持ち続ける**
- 構成変更後に古い事象を使うと `MATLAB:innerdim` になり、原因が分かりません。別ネットワークの事象は、条件によってはエラーなしで走ります。
- 箇所: [odeEventSet.m:91](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:91)、[odeEventSet.m:118](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:118)、[odeEventSet.m:354](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:354)。

**M4. `time` の不正値が検証されず、内部エラーになる**
- スカラー、逆順、NaN、`[1,1]` は `badsubscript` や `RowIndexOutOfRange` になります。`[0,Inf]` は拒否されません。
- 箇所: [simulate.m:42](../_GUILDAsystem/@PowerNetwork/simulate.m:42)、[getTimeSpan.m:13](../_GUILDAsystem/_auxiliary/@odeEventSet/private/getTimeSpan.m:13)。

**M5. 初期値の再計算に失敗すると、原因と無関係なメッセージになる**
- 全発電機の trip で「ode15s に tspan と y0 が必要」と表示されます。`decic` の失敗を示す `exitFlag` を捨てて、空の初期値で続行しているためです(コード読解)。
- 箇所: [odeSimulator.m:254](../_GUILDAsystem/_auxiliary/@odeSimulator/odeSimulator.m:254)、[CalculateInitialCondition.m:1](../_GUILDAsystem/_auxiliary/@odeSimulator/private/CalculateInitialCondition.m:1)。

### 低

**L1. `sol.odeResults` は読むたびに作り直される**
- 1回あたり 0.18〜0.42 s かかります。ヘルプの `res.odeResults.Bus(1).Component(1).X.omega` の形を繰り返すと、その回数分かかります。
- 箇所: [odeSimulationResult.m:127](../_GUILDAsystem/_auxiliary/@odeSimulationResult/odeSimulationResult.m:127)。

**L2. 制御器のパラメータを `tab_parameter` で編集できない**
- `Component` や `Branch` と違い、`LocalController` と `GlobalController` は `MATLAB:class:noSetMethod` になります。`para_dynamics` なら編集でき、編集検知も働きます。
- 箇所: [LocalController.m:289](../_GUILDAsystem/@LocalController/LocalController.m:289)、[GlobalController.m:191](../_GUILDAsystem/@GlobalController/GlobalController.m:191)。

**L3. 事象の tag の重複や予約名が内部エラーになる**
- 同じ tag、`t1`、`NoAction1` が `DuplicateVarNames` になります。事象の配列は `maxrhs` になります。
- 箇所: [odeEventSet.m:179](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:179)、[odeEventSet.m:207](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:207)。

**L4. `Solver` に DAE で使えない値を渡したときの案内がない**
- 検証を通った後で `MATLAB:ode:SolverOptionsCannotBeModified` や、積分開始後の `PhaseFailed` になります。使えるのは実質 `ode15s` と `ode23t` です。
- 箇所: [odeSimulator.m:704](../_GUILDAsystem/_auxiliary/@odeSimulator/odeSimulator.m:704)。

**L5. `InputValue` の過剰な要素が黙って無視される**
- 箇所: [odeEventSet.m:271](../_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m:271)。

## 測れなかった項目と未確定の点

| 項目 | 理由 |
|---|---|
| `Progress="dialog"` と `"disp"` のコスト | `-batch` では画面がなく、waitbar の時間を測れないため。`"disp"` は測定対象に入れませんでした |
| ソルバの内部統計(正確なステップ数、失敗ステップ数) | `ode` オブジェクトを `solve` の外から取得できないため。`n_t` で代用しました |
| 右辺評価の時間のプロファイラなしの直接測定 | `getODEFunction` が private のため。プロファイラの比率と、個別の呼び出し時間で示しました |
| 疎ヤコビアンにしたときの効果 | コア変更が必要なため |
| IEEE9 と IEEE68 の AGC あり | 今回のケースに含めていません |
| 正確な時間 | 他セッションと同じマシンで測ったため。測定中の load average は 5〜8 で、1節開始時でも 2.2 でした |
| IEEE68 既定構成の trip の flag=-1(t=0.5 で停止) | 原因を調べていません。H2 の箇所に到達する前に止まっています |
| 重なる fault や長い fault での flag=-1 | 物理的な不安定か不具合かを判定していません |
| AVR の tag の trip の正しさ | 応答は変わりますが、期待される応答を定義していません |
| H1、H2 などの修正後の動作 | コアを変更しない条件なので、修正して確かめていません |
