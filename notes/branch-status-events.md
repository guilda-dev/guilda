# ブランチの状態とシナリオのイベント(仕様)

ブランチは `docs/branch-status-events` です。調査の基準は `refactor/design-alignment` の `06656d9d`(simulate の再設計 S0-S7 と #121 を統合済み)です。**この文書は仕様で、コードは変えていません。** §9 の問いに回答をもらってから、§7 の手順でサブセッションに分けて実装します。

**根拠の区別**

- **[事実]** 基準コミットのコードを読んで確認しました。
- **[決定]** 利用者が決めた方針です(§0)。
- **[提案]** この文書の提案で、決定の具体化です。
- **[要確認]** §9 の問いの回答を待つ提案です。
- **[未確認]** 調べていない、または MATLAB で動かしていない事項です。この文書のために MATLAB は実行していません。

**関連ノート:** [simulate-redesign.md](simulate-redesign.md)(§0.6 の実装の状況、§3.4 の `sct_event`、§2.8 のシナリオの JSON、§8.3 の基準)、[variable-connection-map.md](variable-connection-map.md)(接続表の `local` と `equilibrium`)、[controller-signal-routing.md](controller-signal-routing.md)。

## 0. 利用者の決定

### 0.1 ブランチの状態(A)

1. **すべてのブランチのクラスの `get_admittance_matrix(Status=, Point=)`。** `Status` は次の 5 つです。
   | Status | 意味 |
   |---|---|
   | `"close"`(既定) | 現在の行列 |
   | `"3LG"` | 1 回線を `Point` で地絡 |
   | `"6LG"` | 全回線(2 回線なら両回線)を `Point` で地絡 |
   | `"3open"` | 1 回線を開放 |
   | `"6open"` | 全回線を開放 |
2. **`Point`** はスカラーで `0 < Point < 1`(0 が送電端 = from、1 が受電端 = to)。`"3LG"` と `"6LG"` だけで使います。端の故障は母線の故障(BG)で与えます。
3. **回線数のパラメータ**(既定 2)をブランチに加えます。今の R, X, C は全回線をまとめた値なので、1 回線は 2R, 2X, C/2 です(n 回線に一般化)。**1 回線のブランチの `"3LG"` と `"3open"` はエラー**です。
4. **故障抵抗はなし**(完全地絡)。
5. **変圧器**(`pi_transformer`, `two_winding_transformer`)もすべての状態を受け付けます。理想変圧器(タップと位相)は送電端に付いているとみなし、`Point` はその先の直列部分の位置です。ヘルプと文書にこれを書きます(一般のシミュレータは変圧器を開放だけにし、故障は端子の母線に置きますが、利用者は許すことを選びました)。
6. 4 クラス(pi, T, pi_transformer, two_winding_transformer)の 2x2 行列(故障点のクロン縮約)を導き、式をこの文書に書きます。故障した回線のシャント C の `Point` での分け方の仮定と n 回線への一般化も書きます。`"6open"` は零行列です。**`"close"` は今の行列と完全に一致**させます。

### 0.2 シナリオのイベント(B)

1. **期間のある外乱を、2 つの表のイベントにします。** どちらも列は `Tag`, `Target`, `Time`, `Status`, `Point` です。
   | 表 | Tag | Target | Status | Point |
   |---|---|---|---|---|
   | 故障 | `"Fault<番号>"`(3 桁、`Fault001`) | 母線かブランチのタグ | ブランチ: `3LG`/`6LG`/`none`、母線: `BG`/`none` | ブランチ: 0..1(開区間)、母線: NaN |
   | 並列 | `"Parallel<番号>"`(`Parallel001`) | 機器、グローバル制御器、**ローカル制御器**、ブランチ | 機器・制御器: `open`/`close`、ブランチ: `3open`/`6open`/`close` | 常に NaN |
2. **オフセットと入力**は今のまま別の表に残します(列と動作を保つ)。
3. 状態は**同じ対象の次のイベントまで続きます。** 既存の `add_*` は残します: `add_fault(target, [t1 t2], ...)`(ブランチの対象に `Status` と `Point` を加える)、`add_open_branch`、`add_trip` は **1 つのタグを共有する 2 行**(開始の状態と終了の状態)を加えます。そのタグで消すと(remove の API はこの文書で設計)2 行とも消えます。**利用者はタグを指定できません**(`Tag` オプションを削除)。期間の終わりがシミュレーションの終わりと同じか後のときの動作を決めて書きます。
4. 1 つのブランチで、**3LG の後の 3open** は故障した回線を開放します(3open と同じ)。**6LG の後の 3open** は他の回線の地絡を残します。ブランチの合成した状態(故障の状態 × 並列の状態 → `get_admittance_matrix` の 1 つの Status/Point)を表にします。
5. **ローカル制御器の解列:** 解列中の状態は NaN、機器への出力は 0(機器は平衡の入力を保つ)。再閉路では機器や GC と同じく平衡点から再開します。
6. **シナリオの JSON**(`scenario/<タグ>.json`)は新しい形式にし、version を上げ、古い形式は読みません。

### 0.3 構成の制約(C)

1. **`SolverODE` は系統を読みません**(simulate の再設計 §0.1-6)。`build_simulation_data` が、シナリオで使う (ブランチ, Status, Point) ごとの 2x2 行列を前もって計算し、データとして渡します(スタンプ = `Y_status - Y_close`)。母線の故障は今どおり V = 0 を保ちます。
2. **各イベントの時刻を区間の境界**にします。
3. **既存のシナリオの軌道**(母線の地絡、旧 OpenBranch と同じ `"6open"` のブランチ、解列)は基準 `DebugScript.helper.simulate_baseline(Mode="compare")`(`/Users/taku/GUILDA/simulate-baseline/baseline_s0.mat`)と**同一**でなければなりません。旧 OpenBranch はブランチ全体を外したので、新しい `"6open"` と同じです。
4. 変える呼び出し元・文書・テストをすべて挙げます(§6)。

## 1. 現状 [事実]

### 1.1 ブランチの行列

| クラス | `get_admittance_matrix()`(`y = 1/(R+jX)`, `c = jC`) | C の意味 |
|---|---|---|
| `branch.pi` | `[c+y, -y; -y, c+y]` | 各端のシャント(全充電容量の半分) |
| `branch.T` | `Y = 2y`, `b = c` として `[Y(Y+b), -Y²; -Y², (Y+b)Y]/(2Y+b)`(中点を縮約) | 中点のシャント(全充電容量) |
| `branch.pi_transformer` | `r = tap·e^{jφ}` として `[(c+y)/tap², -y/conj(r); -y/r, c+y]` | 理想変圧器の先の pi 線路の各端 |
| `branch.two_winding_transformer` | `ym = [c + y/tap², -y/tap; -y/tap, y]`, `E = diag(1, e^{jφ})`, `ym·E` | 送電端の母線側のシャント |

- `Branch` の抽象メソッドは `Ymat = get_admittance_matrix(obj)` で、`tab_parameter.dynamics`(R, X, C, tap, phase)だけを読みます。回線数のパラメータはありません。
- `get_admittance_matrix()` は引数なしで、`PowerNetwork.get_admittance_matrix`、`Branch.struct`(`cm_Y`)、`cv_Iequilibrium`、`get_opf_condition`、潮流計算・OPF・連続潮流計算・線形化(`get_linear_port`)、`DrawerNetDiagram`、`tools.network_to_mpc` から呼ばれます。これらは変えません(既定の `"close"`)。
- IEEJ の系統は回線を別のブランチにしています: `IEEJ_EAST10` と `IEEJ_WEST10` は 1 回線が 1 ブランチ(`EL(2k-1)`, `EL(2k)`、`LINE20_1`, `LINE20_2`)、`IEEJ_WEST30` は 1 枚のカードの n 回線を 1 ブランチ(`R/n`, `X/n`, `C = YC·n`)にしています。`two_winding_transformer` の `phase` は同梱の系統ではすべて 0 です。

### 1.2 シナリオ

- `Scenario.tab_disturbance`(12 列: `Tag`, `TimeSpan`, `FaultBus`, `TripUnit`, `OpenBranch`, `OffsetUnit`, `OffsetState`, `OffsetValue`, `InputUnit`, `InputName`, `InputValue`, `InputMethod`)の 1 行が 1 つの外乱です。外乱は期間 `[t_start, t_end]` の間だけ有効で、同じ対象の 2 つの外乱が重なっても和集合になります(`compile.m` の `phase_table`)。
- `add_fault(bus, time, Tag=)`, `add_trip(unit, time, Tag=)`, `add_open_branch(branch, time, Tag=)`, `add_offset`, `add_input` は `add_record` を通り、タグの既定は `fault<n>`, `trip<n>`, `open<n>`, `offset<n>`, `input<n>` です。`add_disturbance(tag, TimeSpan=, FaultBus=, TripUnit=, OpenBranch=, Offset*=, Input*=)` は 1 つの期間で複数の種類を組み合わせられます。`remove_disturbance(tag)` はタグで行を消します。
- ローカル制御器は解列できません(`GUILDA:Scenario:UnknownTripUnit` の本文)。
- `compile(sct_dae, time)` は区間の表 `tab_phase`(`output.phases`: `t1`, `t2`, 外乱のタグごとの論理の列、`NoAction<k>`)と `sct_event`(区間ごと: `iv_tripComp`, `iv_tripGC`, `iv_faultBus`, `iv_openBranch`(昇順), `iv_offset`, `rv_offset`, `c_input`, `sr_event`)を返します。
- `build_simulation_data` は `sct_dae.cm_Y`(全ブランチを閉じた行列)、`im_branchBus`、`c_branchY{k}`(各ブランチの `get_admittance_matrix()`)を作り、`check_islands` は `iv_openBranch` で開いたブランチの島を検査します。
- `SolverODE.set_admittance(ctx, iv_open, l_force)` は `Yc(iv,iv) = Yc(iv,iv) - c_branchY{k}` を `iv_open` の昇順に引きます。
- シナリオの JSON は version 1(`Format` "GUILDAscenario", `Description`, `Time`, `Disturbances` は `add_disturbance` の Name-Value の名前)。`read_scenarios` は version が 1 より大きいと `GUILDA:PowerNetwork:ScenarioJson` で止まります。
- `add_scenario(tag, From=sc0)` は `sc0.tab_disturbance` の行を `add_disturbance` で写します。

## 2. ブランチの状態

### 2.1 回線数のパラメータ [決定 A3、名前は提案(§9 Q6)]

- `tab_parameter.dynamics` に列 **`circuit`** を加えます(`tap`, `phase` と同じく小文字)。正の整数、既定 2。
- `PowerNetwork.add_branch` に Name-Value **`Circuit`**(`(1,1) double {mustBeInteger, mustBePositive} = 2`)を加えます(`Tap`/`Phase` と同じ対応)。
- R, X, C は**全回線をまとめた値**のままです。1 回線の値は `n·R`, `n·X`, `C/n` です。`"close"` の行列は回線数によりません。
- `export` は `branch/parameter.csv` に `circuit` の列を書きます(dynamics の表をそのまま書くため)。`import` は `circuit` と `Circuit` を受け付け、列がなければ 2 にします(同梱の系統の CSV は変えなくてよい)。
- `dynamics` に置くので、編集は今と同じく潮流計算を stale にします。`"close"` の行列は変わらないので不要な stale ですが、`get_admittance_matrix` が `dynamics` だけを読む約束を保つためにここに置きます [提案]。

### 2.2 公開 API [決定 A1, A2、検査は提案]

```matlab
Ymat = br.get_admittance_matrix();                          % "close"(今と同じ)
Ymat = br.get_admittance_matrix(Status="3open");
Ymat = br.get_admittance_matrix(Status="3LG", Point=0.3);
```

```matlab
function Ymat = get_admittance_matrix(obj, opt)
    arguments (Input)
        obj
        opt.Status (1,1) string {mustBeMember(opt.Status, ["close","3LG","6LG","3open","6open"])} = "close"  % State of the branch.
        opt.Point  (1,1) double = NaN   % Fault position from the from end (0) to the to end (1), 0 < Point < 1; only for "3LG" and "6LG".
    end
    arguments (Output)
        Ymat (2,2) double   % [pu] 2-by-2 complex admittance matrix (from, to).
    end
```

- `Branch.m` の抽象メソッドの宣言を `Ymat = get_admittance_matrix(obj, opt)` にし、ヘルプに 5 つの状態、`Point` の向き、回線数、変圧器の扱い(§2.5)を書きます。
- 検査(エラー ID は `GUILDA:Branch:*`、カタログ `SystemTools/GUILDA/en/Branch.xml` を新設。サブクラスのメソッドから `msg` で出せる [事実: `msg.m` のヘルプ]):
  | 条件 | ID |
  |---|---|
  | `"3LG"`/`"6LG"` で `Point` が NaN・`0 < Point < 1` でない | `GUILDA:Branch:InvalidPoint`(本文: 端の故障は母線の故障 `add_fault(<bus>, ...)` で与える) |
  | `"close"`/`"3open"`/`"6open"` で `Point` が NaN でない | `GUILDA:Branch:PointWithoutFault` [要確認 §9 Q9] |
  | `circuit = 1` で `"3LG"`/`"3open"` | `GUILDA:Branch:SingleCircuit` |
- **実装は各クラスに書きます** [提案、§9 Q8]: 4 つの `get_admittance_matrix.m` がそれぞれ arguments ブロックと §2.4 の合成を持ちます(重複は数行)。新しいメンバーは加えません。
- 自作のブランチのクラスで引数を受けない古い `get_admittance_matrix(obj)` は、引数なしの呼び出し(潮流計算など)では今どおり動き、シナリオでそのブランチの状態を変えたときだけ `build_simulation_data` でエラーになります(MATLAB の「引数が多すぎます」)。移行の注意として v4-migration に書きます。

### 2.3 1 回線の行列と地絡の仮定 [決定 A4, A6、仮定は提案]

記号: `y = 1/(R + jX)`(全回線の直列アドミタンス)、`n` = 回線数、`p` = `Point`、`q = 1 - p`。1 回線の直列アドミタンスは `y/n`、シャントは `C/n` です。

- **線形性:** 4 クラスとも行列はアドミタンス(y, jC)について 1 次で、理想変圧器の変換も各回線で同じなので、**1 回線の閉じた行列は `Y_close/n`** です。n 回線の並列はその和です。
- **シャントの分け方の仮定:** 故障した回線のシャントは**長さに比例**して分けます。故障点で 2 つの区間(送電端側の長さ p、受電端側の長さ q)に分け、**各区間を元のクラスと同じ形(pi なら pi、T なら T)の区間**にします。区間の直列インピーダンスは 1 回線の値の p 倍・q 倍、シャントも p 倍・q 倍です。
- **故障点の縮約:** 故障点 F を送電端 S、受電端 R と並べた 3 節点の行列 `[Y_SS Y_SF; Y_FS Y_FF]`(S, R を 1 つのブロック)を、F の地絡アドミタンス `y_f` で縮約すると `Y_red = Y_SS - Y_SF (Y_FF + y_f)^{-1} Y_FS` です。完全地絡(`y_f → ∞`)では第 2 項が消え、`Y_red = Y_SS`、つまり **S と R の結合が 0 の対角行列**になり、各対角は「その区間の、先を接地したときの駆動点アドミタンス」です。故障点に付くシャントは接地で短絡されるので行列に入りません。
- 区間が元のクラスの形なので、p, q のどちらかを 0 に近づけると、その端のアドミタンスは無限大(母線の地絡)に近づきます。端の故障を母線の故障で与える決定(A2)と合います。

### 2.4 各クラスの行列 [提案]

`G1` を「1 回線を p で地絡したときのその回線の行列」とします(対角)。合成は 4 クラスで共通です。

| Status | 行列 |
|---|---|
| `"close"` | **今の式をそのまま**(計算の順序も変えない。完全一致) |
| `"6open"` | `zeros(2)` |
| `"3open"` | `((n-1)/n)·Y_close`(n = 1 はエラー) |
| `"3LG"` | `((n-1)/n)·Y_close + G1(p)`(n = 1 はエラー) |
| `"6LG"` | `n·G1(p)` |

n = 2 では `(n-1)/n = 1/2` で、`Y_close/2` は浮動小数点でも誤差なく計算されます。

**pi**(各端のシャント `jC/n`、区間 ℓ ∈ {p, q} の各端のシャントは `jℓC/n`、直列は `y/(nℓ)`)

```
G1(p) = diag( jpC/n + y/(n p),  jqC/n + y/(n q) )
6LG   = diag( jpC   + y/p,      jqC   + y/q     )      % n によらない
```

**T**(1 回線: 直列の半分ずつ `n(R+jX)/2`、中点のシャント `jC/n`。区間 ℓ は直列の半分 `nℓ(R+jX)/2`、中点のシャント `jℓC/n` の T)

区間 ℓ の先を接地した駆動点アドミタンスは、`Ya(ℓ) = 2y/(nℓ)`、`b(ℓ) = jℓC/n` として、今の T の式の対角と同じ形です。

```
d(ℓ)  = Ya(ℓ)·(Ya(ℓ) + b(ℓ)) / (2·Ya(ℓ) + b(ℓ))
G1(p) = diag( d(p), d(q) )
6LG   = n·G1(p) = diag( D(p), D(q) ),  D(ℓ) = (2y/ℓ)(2y/ℓ + jℓC)/(4y/ℓ + jℓC)
```

**pi_transformer**(送電端の理想変圧器 `r = tap·e^{jφ}`、その先が pi 線路)

今の行列は `Y_close = Dᴴ·Y_line·D`、`D = diag(1/r, 1)`、`Y_line = [c+y, -y; -y, c+y]` と書けます(`Y11 = (c+y)/|r|²`, `Y12 = -y/conj(r)`, `Y21 = -y/r` で今の式と一致)。故障は線路の部分だけに起き、`G1` は pi の `G1` を同じ D で変換します。

```
G1(p) = Dᴴ·diag( jpC/n + y/(n p), jqC/n + y/(n q) )·D
      = diag( (jpC/n + y/(n p))/tap²,  jqC/n + y/(n q) )
6LG   = diag( (jpC + y/p)/tap²,        jqC + y/q )
```

**two_winding_transformer**(送電端の母線側のシャント `c`、送電端のタップ、直列 y、今の位相の掛け方 `E = diag(1, e^{jφ})` を右から)

今の行列は `Y_close = (S + Dt·Y_line·Dt)·E`、`S = diag(c, 0)`、`Dt = diag(1/tap, 1)`、`Y_line = [y, -y; -y, y]` と書けます(今の `ym` と一致)。直列部分にシャントはないので、区間 ℓ の先を接地した駆動点は `y/(nℓ)` です。母線側のシャント `c/n` は地絡では残ります(理想変圧器より母線側にあるため)。開放では回線ごと外れます。

```
G1(p) = ( diag(c/n, 0) + Dt·diag( y/(n p), y/(n q) )·Dt )·E
      = diag( c/n + y/(n p tap²),  e^{jφ}·y/(n q) )
6LG   = diag( c + y/(p tap²),       e^{jφ}·y/q )
```

- [事実] 今の `ym·E` は φ ≠ 0 で電力を保存しない形です(受電端の電流に位相が戻らない)。同梱の系統の φ はすべて 0 です。上の式は**今の形をそのまま拡張**し、`"close"` の一致と `"3open" = Y_close·(n-1)/n` を保ちます。位相の掛け方を直すかは別の問いです(§9 Q5)。
- **変圧器の説明(ヘルプと文書):** 「理想変圧器は送電端に付いているとみなし、`Point` はその先の直列部分(two_winding_transformer では直列インピーダンス、pi_transformer では pi 線路)の位置。一般のシミュレータは変圧器の故障を端子の母線に置き、変圧器は開放だけにする」と書きます [決定 A5]。

**確かめる性質(テスト §8.1)**

- `"close"` が今の式と `isequal`(4 クラス、n = 1, 2, 3、tap と位相あり)。
- `"6open"` が零、`"3open"` が `Y_close·(n-1)/n`。
- `G1` を独立に作った値と一致: 1 回線を S–F–R の 2 区間(pi・T は区間を元の形、F の地絡アドミタンス 1e12)の 3 節点の行列で作り、F を `Y_SS - Y_SF/(Y_FF+y_f)·Y_FS` で縮約した値と相対 1e-9 以内。
- pi・T の `"6LG"` は p と q の入れ替えで対角が入れ替わる。

### 2.5 合成した状態 [決定 B4、表は提案]

同じブランチに故障の表と並列の表の状態が同時にあるとき、区間ごとに次の表で 1 つの行列にします。`Yst(...)` は `get_admittance_matrix(Status=..., Point=...)` です。

| 故障の状態 | 並列 `close` | 並列 `3open` | 並列 `6open` |
|---|---|---|---|
| `none` | `"close"`(スタンプなし) | `Yst("3open")` | `Yst("6open")` |
| `3LG` @p | `Yst("3LG", p)` | `Yst("3open")`(故障した回線を開放) [決定] | `Yst("6open")` |
| `6LG` @p | `Yst("6LG", p)` | `((n-1)/n)·Yst("6LG", p)`(残りの回線の地絡が残る) [決定、式は提案] | `Yst("6open")` |

- 右下の `(6LG, 3open)` は 5 つの状態のどれでもないので、`get_admittance_matrix` に状態を加えず、`build_simulation_data` の private 関数が上の式で作ります(n = 2 なら 1 回線だけの地絡 `G1(p)`) [提案、§9 Q11]。
- `3open` と `3LG` の「どの回線か」は区別しません(回線は同じなので、故障した回線を開放する = 健全な回線が残る)。
- 母線の故障(BG)とそのブランチの状態は独立です(母線は V = 0 を保ち、ブランチのスタンプも入る)。
- この表は 1 か所(`@PowerNetwork/private/branch_state_matrix.m`、§4.2)にだけ書きます。

## 3. シナリオのイベント

### 3.1 表 [決定 B1, B2、型と名前は提案]

```matlab
properties (SetAccess=private) % Disturbances
    tab_fault       table   % Fault events (Tag, Target, Time, Status, Point), in the order added. <@Type> table (n x 5)
    tab_parallel    table   % Parallel (connection) events (Tag, Target, Time, Status, Point), in the order added. <@Type> table (n x 5)
    tab_disturbance table   % Offsets and inputs, one row each (as today without FaultBus, TripUnit, OpenBranch). <@Type> table (n x 9)
end
```

| 列 | 型 | 内容 |
|---|---|---|
| `Tag` | string | `Fault001` / `Parallel001`。1 回の追加の行がすべて共有 |
| `Target` | string | 1 行に 1 つの対象のタグ |
| `Time` | double | [s] 状態が変わる時刻(`Inf` も可) |
| `Status` | string | §0.2 の表の値 |
| `Point` | double | 故障の表のブランチ: `0 < Point < 1`、それ以外: NaN |

- `tab_disturbance` は `FaultBus`, `TripUnit`, `OpenBranch` の 3 列を除いた 9 列(`Tag`, `TimeSpan`, `OffsetUnit`, `OffsetState`, `OffsetValue`, `InputUnit`, `InputName`, `InputValue`, `InputMethod`)にし、名前は残します [提案、§9 Q10]。`sr_field` も合わせます。
- 故障の表の、ブランチの `none` の行(期間の終わり)の `Point` は開始の行と同じ値にします(列の規則「ブランチは 0..1」を保つ。行列には使わない) [提案]。
- 行は追加の順に置きます(開始の行、終了の行の順。対象が複数なら対象ごとに 2 行)。`compile` が時刻で並べます。
- `Scenario.Ver` を 3.0 から 4.0 にします [提案]。

### 3.2 追加の API [決定 B3、詳細は提案]

| メソッド | 加える行(対象ごと) | タグ |
|---|---|---|
| `add_fault(target, [t1 t2])`(母線) | `(t1, "BG", NaN)`, `(t2, "none", NaN)` | `Fault<n>` |
| `add_fault(target, [t1 t2], Status="3LG"\|"6LG", Point=p)`(ブランチ) | `(t1, Status, p)`, `(t2, "none", p)` | `Fault<n>` |
| `add_open_branch(branch, [t1 t2], Status="6open"\|"3open")` | `(t1, Status, NaN)`, `(t2, "close", NaN)` | `Parallel<n>` |
| `add_trip(unit, [t1 t2])`(機器・GC・LC) | `(t1, "open", NaN)`, `(t2, "close", NaN)` | `Parallel<n>` |

```matlab
s_tag = add_fault(obj, target, time, opt)
    target (:,1) string          % Tags of the faulted buses, or of the faulted branches.
    time   (1,2) double          % [s] [t_start, t_end] of the fault.
    opt.Status (1,1) string {mustBeMember(opt.Status, ["BG","3LG","6LG"])}   % "BG" (buses, the default) or "3LG"/"6LG" (branches; required).
    opt.Point  (1,1) double      % Fault position along a branch, 0 < Point < 1 (branches; required).
s_tag = add_open_branch(obj, branch, time, opt)
    opt.Status (1,1) string {mustBeMember(opt.Status, ["6open","3open"])} = "6open"   % All circuits (as the old OpenBranch) or one.
s_tag = add_trip(obj, unit, time)
    unit (:,1) string            % Tags of components, global controllers or local controllers.
```

- **`Tag` オプションを 3 つのメソッドから削除**します [決定]。`add_offset`, `add_input` の `Tag` は残します(表と動作を保つ)。
- 番号は同じ表の `Fault`/`Parallel` の最大の番号 + 1、`%03d`(1000 以上は 4 桁)。消した番号は再利用しません(今の `add_record` と同じ) [提案]。
- `add_fault` の対象は全部母線か全部ブランチ(混在は `GUILDA:Scenario:MixedFaultTarget`)。ブランチで `Status` か `Point` がない、母線で `"3LG"`/`"6LG"` や `Point` がある、は `GUILDA:Scenario:InvalidFaultStatus` [提案、§9 Q3]。`Point` の範囲は `GUILDA:Scenario:InvalidPoint`。
- `add_open_branch` の既定 `"6open"` は旧 OpenBranch と同じ(ブランチ全体を外す)です。
- `t1 < t2` が必要です(今の `ZeroLengthTimeSpan`)。`t2 = Inf` も受け付けます。
- 加える前に、系統に対して検査します(今の `validate_disturbance` と同じ時点): 対象の種類と Status の組、未知のタグ、同じ対象の期間の重なり(§3.4)。回線数(1 回線の `3LG`/`3open`)は追加の時点と `compile` の時点の両方で `GUILDA:Scenario:SingleCircuit` で検査します(追加の後に `circuit` を変えられるため)。
- **`add_disturbance` から `FaultBus`, `TripUnit`, `OpenBranch` を削除**し、オフセットと入力だけの一般形にします [要確認 §9 Q1]。

### 3.3 削除の API [決定 B3、設計は提案]

- **`remove_disturbance(tag)` 1 つで全部の表を扱います。** `tag (:,1) string` のそれぞれについて、`tab_fault`, `tab_parallel`, `tab_disturbance` のうちそのタグの**すべての行**を消します(`add_fault` の 2 行、対象が複数なら 2N 行)。どの表にもないタグは今どおり `GUILDA:Scenario:DisturbanceNotFound`。
- `remove_fault` などの新しいメソッドは加えません(`remove_disturbance` の名前が 3 つの表すべての外乱を表すため)。

### 3.4 状態の決め方 [決定 B3、規則は提案]

- **対象 X の時刻 t の状態は、`Time <= t` の X の行のうち最後の行の Status** です。行がなければ既定(故障 `none`、並列 `close`)。
- **同じ表で同じ対象の期間の重なりはエラー** `GUILDA:Scenario:OverlappingEvents`(追加の時点と `validate` の時点) [要確認 §9 Q2]。今は重なった 2 つの期間が和集合になりますが、新しい規則では「次のイベントまで続く」ので、`add_fault(B, [1 2])` と `add_fault(B, [1.5 3])` が `[1, 2]` の故障になってしまうためです。端だけが接する期間(`[1 2]` と `[2 3]`)は重なりではありません。
- **同じ時刻・同じ対象**の終了の行と開始の行(接する 2 つの期間)は、**終了を先、開始を後**に適用します(後の期間が勝つ)。行がどちらかはタグの中の順(先が開始)で分かります。
- 故障の表と並列の表は独立で、同じブランチでは §2.5 の表で合成します。異なる表のイベントの重なり(地絡の間に開放など)は許します。

### 3.5 シミュレーションの時間との関係 [決定 B3「決めて書く」、内容は提案]

- **期間の終わりがシミュレーションの終わり `tend` と同じか後**(`Inf` を含む)のとき: 行は表に残り、その実行では効果がありません(`tend` 以後の時刻は区間の境界にしない)。状態は `tend` まで続きます。旧 `add_open_branch(br, [0.17, 20])` を `Time = [0, 10]` で実行したときと同じです。シナリオは時間と独立に保存されるので(`Time` は呼び出しで上書きできる)、行を切りません。
- `t0` より前の行は `t0` の状態に入ります(期間 `[-1, 2]` は `t0` から有効。今と同じ)。
- 期間全体が `[t0, tend]` の外にあるタグ(`t_end < t0` か `t_start > tend`)は今どおり `GUILDA:Scenario:OutsideTimeSpan` の警告です(タグごとに 1 回)。
- 区間の境界は `t0`、`(t0, tend)` の中の故障・並列の行の `Time`、オフセットの時刻、`"zoh"` の点、`tend` です(今の `phase_table` の `times(:)` を行の `Time` に置き換える)。

### 3.6 `output.phases` [提案]

- 列は `t1`, `t2`、**故障の表のタグ(表の順)、並列の表のタグ(表の順)、`tab_disturbance` のタグ(表の順)**、`NoAction<k>` です。
- タグの列は、区間の開始 `t1` がそのタグの期間 `[最初の行の Time, 最後の行の Time)` に入るとき true です(今の重なりの判定 `fti < etj && ftj < eti` と同じ結果)。
- [事実] 基準の 6 例は、外乱の種類が 1 つか、オフセットと入力(同じ表)だけなので、列の順は今と同じで、**名前だけが変わります**(`fault1` → `Fault001`、`trip1`/`open1` → `Parallel001`、F18 の構成の `trip1`, `trip2` → `Parallel001`, `Parallel002`)。
- `Fault` + 数字、`Parallel` + 数字は `add_offset` / `add_input` / `add_disturbance` の `Tag` に使えません(`GUILDA:Scenario:ReservedTag` の本文に加える)。

### 3.7 ローカル制御器の解列 [決定 B5、解釈は §9 Q4, Q7]

- 並列の表の `Target` に LC のタグ(入れ子を含む、`sct_dae.sv_lc`)を許します。`UnknownTripUnit` の本文の「a local controller cannot be tripped」を削除します。
- 解列中:
  - LC の状態 x と入力 uc を DAE から外し(GC と同じく `initial_condition` の縮約)、結果の状態は NaN にします(`phase_result`、`struct_result` の `x`, `u`)。
  - LC の出力が届いていた入力(接続表の `local` の行の先。機器の入力か親の LC の入力)は、その接続の寄与をなくし、**その入力の平衡値**にします(接続が `equilibrium` だったときと同じ)。PSS のように平衡の出力が 0 の LC では「出力 0」と同じ、AVR のように出力そのものが入力になる LC では「機器は平衡の入力(界磁電圧)を保つ」になります [要確認 §9 Q4]。同じ入力への `global` の接続(GC の出力)と入力イベントは今どおり足されます。
  - 解列した LC の子の LC は動き続けます(出力は外した入力に入るだけ) [要確認 §9 Q7]。
- 再閉路: `getNextPhase` で、直前の区間で解列していた LC の状態を平衡点(`rv_z0`)と質量行列から再開します(GC と同じ)。
- 機器の解列は今のまま(その LC は動き続け、機器の再接続で平衡点から再開)。

### 3.8 シナリオの JSON(version 2) [決定 B6、形は提案]

```json
{
  "Format": "GUILDAscenario",
  "version": 2,
  "Description": "fault EL003, then one circuit opened",
  "Time": [0, 20],
  "Fault": [
    {"Tag": "Fault001", "Target": "EL003", "Time": 0.1,  "Status": "3LG",  "Point": 0.3},
    {"Tag": "Fault001", "Target": "EL003", "Time": 0.17, "Status": "none", "Point": 0.3}
  ],
  "Parallel": [
    {"Tag": "Parallel001", "Target": "EL003", "Time": 0.17, "Status": "3open", "Point": NaN},
    {"Tag": "Parallel001", "Target": "EL003", "Time": Infinity, "Status": "close", "Point": NaN}
  ],
  "Disturbances": [
    {"Tag": "offset1", "TimeSpan": [0], "OffsetUnit": "B001SG1", "OffsetState": ["delta"], "OffsetValue": [0.1]}
  ]
}
```

- `Fault`, `Parallel` は 1 行 1 つの物体の配列、`Disturbances` はオフセットと入力だけ(項目は今の `add_disturbance` の名前から `FaultBus`, `TripUnit`, `OpenBranch` を除いたもの)。空の表の項目は書きません。`Inf`/`NaN` は今どおり `Infinity`/`NaN`(`ConvertInfAndNaN=false`)。
- `read_scenarios`: `version` が 2 でなければ `GUILDA:PowerNetwork:ScenarioJson`。1 は「version 1 の形式はもう読みません。シナリオを作り直して `net.export` で書き直してください」、2 より大きいは今どおり「新しすぎる」。トップの項目は `Format`, `version`, `Description`, `Time`, `Fault`, `Parallel`, `Disturbances`。`Fault`/`Parallel` の行に `Tag`, `Target`, `Time`, `Status` がない、`Tag` が `Fault`/`Parallel` + 数字でないものも `ScenarioJson`。
- `add_from_json_struct`: `Fault`/`Parallel` の行をタグのまま、private メソッド `add_events(obj, s_table, tab)` で加えます(§3.9 の検査: タグと対象ごとに 2 行、`t_start < t_end`、Status と対象の種類、重なり、系統のタグ)。

### 3.9 新しいメンバーと変わるメンバー [提案]

公開メンバーの追加は `tab_fault`, `tab_parallel`(SetAccess=private)と `add_branch` の `Circuit`, `get_admittance_matrix` の `Status`/`Point` だけです。

| 対象 | 変更 |
|---|---|
| `Scenario` | プロパティ `tab_fault`, `tab_parallel`。`add_fault`(`Status`, `Point` を追加、`Tag` を削除)、`add_trip`・`add_open_branch`(`Tag` を削除、`add_open_branch` に `Status`)、`add_disturbance`(3 項目を削除)、`remove_disturbance`(3 つの表)。private メソッド `add_events(obj, s_table, tab)`(`add_*`, JSON, `From` の共通の入口。`add_record` はオフセットと入力だけに)。`Ver` 4.0 |
| `Branch` | 抽象メソッドの引数 `opt`、`dynamics` の `circuit` |
| `branch.*` の 4 クラス | `get_admittance_matrix(obj, opt)` |
| `PowerNetwork` | `add_branch` の `Circuit`。private 関数 `branch_state_matrix.m`(新規) |
| `SolverODE` | `set_admittance(ctx, iv_stamp, l_force)`(引数の意味が変わる) |

## 4. シミュレーションのデータ

### 4.1 `compile` の出力 [提案]

`sct_event(k)` の項目:

| 項目 | 変更 |
|---|---|
| `iv_faultBus` | 状態 `BG` の母線(`sct_dae.sv_bus` の位置)。意味は今と同じ |
| `iv_tripComp`, `iv_tripGC` | 状態 `open` の機器・GC。今と同じ |
| `iv_tripLC` | **新規**: 状態 `open` の LC(`sct_dae.c_lc` の位置) |
| `tab_branch` | **新規**: 状態が `(none, close)` でないブランチ。列 `Branch`(`sv_branch` の位置、昇順)、`Fault`、`Point`、`Parallel` |
| `iv_openBranch` | **削除**(`build_simulation_data` が `iv_stamp` に置き換える) |
| `iv_offset`, `rv_offset`, `c_input`, `sr_event` | 今と同じ |

`compile` は `sct_dae.sv_branch`, `sv_lc` などのタグの並びだけを読み、ブランチの物体は読みません(今と同じ)。

### 4.2 `build_simulation_data` のスタンプ [決定 C1、形は提案]

1. `compile` の後、全区間の `tab_branch` の異なる (Branch, Fault, Point, Parallel) を集めます。
2. 各組について `@PowerNetwork/private/branch_state_matrix.m`(新規)が §2.5 の表で `Y_state` を作り、**スタンプ `Y_state - Y_close`** にします。`Y_close` は `c_branchY` と同じ `get_admittance_matrix()` の値です。回線数のエラー(`GUILDA:Branch:SingleCircuit`)はここでも起きます。
3. `sct_dae` に `c_stamp`(2x2 の複素数のセル)、`iv_stampBranch`(各スタンプのブランチの位置)、`tab_stamp`(`Branch` のタグ, `Fault`, `Point`, `Parallel`。デバッグ用)を置き、`c_branchY` を削除します。
4. `sct_event(k).iv_stamp` に、その区間のスタンプの位置を**ブランチの位置の昇順**で入れます(1 つのブランチは 1 区間に 1 つのスタンプ)。`tab_branch` はデバッグ用に残します(ソルバーは読まない)。
5. `check_islands` は「ブランチが両端を結ばない状態」(`(any, 6open)`, `(6LG, close)`, `(6LG, 3open)`)を開いたブランチとして島を検査します [提案、§9 Q12]。メッセージ `OpenBranchIsland` の本文を「開いた、または両端で地絡したブランチ」にします(ID は変えない)。

### 4.3 `SolverODE` [決定 C1、提案]

- `set_admittance(ctx, iv_stamp, l_force)`: `Yc(iv,iv) = Yc(iv,iv) + ctx.c_stamp{s}`(`iv = im_branchBus(iv_stampBranch(s),:)`)を `iv_stamp` の順に足します。
- `solve`: `ph.iv_openBranch` を `ph.iv_stamp` に、`ctx.c_branchY` を `ctx.c_stamp`, `ctx.iv_stampBranch` に。
- LC の解列(§3.7): `build_index` が LC ごとに、その出力が `local` の接続で届く入力の行(`iv_in` の中の位置)と、出力の `s` の位置を持ちます。`set_phase` は `ctx.lv_lcOn` を作り、解列中の LC について `S_sig` の該当の要素を 0、`rv_e` の該当の行を平衡値(`rv_z0(iv_in)`)にします(`rv_e0`, `S_sig0` から毎区間作る)。`initial_condition` は解列中の LC の `iv_x`, `iv_u` を縮約で外し、`getODEFunction`/`getODEJacobian` は GC と同じく解列中の LC を評価しません。`getNextPhase` は再開、`phase_result` は状態を NaN に。
- 解列中の LC がなければ `S_sig`, `rv_e` は今と同じ値・同じ計算なので、軌道は変わりません。

### 4.4 軌道が同じであること [決定 C3]

- **母線の地絡・解列・GC の解列・オフセット・入力**: 計算の経路は今と同じです。
- **旧 OpenBranch = `"6open"`**: スタンプは `zeros(2) - Y_close = -Y_close` で、`a + (-b)` は IEEE の浮動小数点で `a - b` と同じ値です(符号の反転は誤差がない)。足す順序も今の `iv_open` の昇順と同じです。したがって `Ymat` は今と `isequal` です。
- `output.phases` は列の名前だけが変わります(§3.6)。`simulate_baseline` の比較を「`t1`, `t2` と論理の値は `isequaln`、列の名前は新旧の対応表(`fault1`→`Fault001` など)で一致」にします(§7 の E2)。`rv_t`, `rm_variable`, `rm_I`, `flag` は `isequaln` のままです。

### 4.5 結果 [提案]

- `struct_result`(`Format="struct"`)は解列中の LC の `x`, `u` を NaN にします(`sct_event.iv_tripLC`)。
- `ResultODE` は状態が NaN のブロックの出力を NaN にする今の処理で LC も扱えるか確かめます [未確認]。

## 5. 文書とヘルプ [提案]

- `Branch.m`、4 クラスのヘルプ: 5 つの状態、`Point` の向きと開区間、回線数(R, X, C は全回線の値)、§2.3 の仮定、変圧器の扱い(§2.4 の説明)、例。
- `Scenario.m` のヘルプ: 3 つの表、行の意味、状態の決め方(§3.4)、期間の終わりと `tend`(§3.5)、LC の解列(§3.7)、例(ブランチの地絡と 1 回線の開放)。
- `add_fault.m`, `add_trip.m`, `add_open_branch.m`, `add_disturbance.m`, `remove_disturbance.m`, `add_branch.m` のヘルプと例。
- 開発者ページ: `feature-simulation.html`(外乱の表、`sct_event`, `c_stamp`, LC の解列、エラー ID)、`feature-data-io.html`(JSON の version 2、`branch/parameter.csv` の `circuit`)、`feature-model-building.html`(`add_branch` の `Circuit`)、`model-implementation.html`(ブランチのクラスの `get_admittance_matrix` の約束、`add_fault`/`add_trip` の例)、`class-design.html`(`Branch` の役割)。クラスのページは自動生成。
- `_GUILDAdoc/index.html` の例は API が残るので変えなくてよいか確かめます(`Tag=` を使っていない [事実: grep])。
- Update log に 1 件(ブランチの地絡と回線の開放、LC の解列、シナリオの JSON version 2)。`v4-migration.md`(`Tag` オプションの削除、`add_disturbance` の 3 項目、JSON version 1 を読まない、自作のブランチのクラスの引数、`output.phases` の列名)、`status.md`。

## 6. 変える箇所の一覧 [事実: grep、基準 `06656d9d`]

`notes/` は除きます(この文書と `simulate-redesign.md` などの記録は更新しない)。`+DebugScript/archive/` は対象外です。

### 6.1 コード

| ファイル | 内容 | 手順 |
|---|---|---|
| `_GUILDAobject/+branch/@pi, @T, @pi_transformer, @two_winding_transformer/get_admittance_matrix.m` | §2.2-2.4 | B1 |
| 同 4 クラスの `pi.m`, `T.m`, `pi_transformer.m`, `two_winding_transformer.m` | ヘルプ | B1 |
| `_GUILDAsystem/@Branch/Branch.m` | 抽象メソッドの引数、`circuit`、ヘルプ | B1 |
| `_GUILDAsystem/@PowerNetwork/add_branch.m` | `Circuit` | B1 |
| `_GUILDAsystem/@PowerNetwork/import.m`, `export.m` | `circuit` の列(`export.m` のヘルプの `FaultBus` も) | B1(`export.m` のヘルプの 1 行は E1) |
| `SystemTools/GUILDA/en/Branch.xml`(新規) | `InvalidPoint`, `PointWithoutFault`, `SingleCircuit` | B1 |
| `functionSignatures.json`(`GUILDA.update_keymap(Signature=true)`) | `add_branch` の `Circuit`、`get_admittance_matrix`、`add_fault` などの引数(`sig_methods` にあれば) [未確認] | B1, E1 |
| `_GUILDAsystem/_auxiliary/@Scenario/Scenario.m`, `add_fault.m`, `add_trip.m`, `add_open_branch.m`, `add_disturbance.m`, `add_record.m`, `remove_disturbance.m`, `validate.m`, `to_json_struct.m`, `add_from_json_struct.m`, `gui_content.m`(ページ「Faults」「Parallel」を追加), `record.m`, `blank.m`, `private/*`(`validate_disturbance`, `empty_disturbances`, `blank_record`, `get_record` と新規 `add_events.m` の本体、`validate_events.m`) | §3 | E1 |
| `_GUILDAsystem/_auxiliary/@Scenario/compile.m` | E1: 新しい表から今と同じ `sct_event` を作る。E2: §4.1 | E1, E2 |
| `SystemTools/GUILDA/en/Scenario.xml` | `UnknownFaultBus` → `UnknownFaultTarget`、`UnknownTripUnit`・`UnknownOpenBranch` → `UnknownParallelTarget`(LC を含む)、新規 `MixedFaultTarget`, `InvalidFaultStatus`, `InvalidPoint`, `OverlappingEvents`, `SingleCircuit`、`ReservedTag`・`ZeroLengthTimeSpan`・`OutsideTimeSpan`・`DuplicateTag` の本文 | E1 |
| `_GUILDAsystem/@PowerNetwork/add_scenario.m` | `From` で 3 つの表を写す(`add_events`) | E1 |
| `_GUILDAsystem/@PowerNetwork/private/read_scenarios.m`, `write_scenarios.m` | version 2 | E1 |
| `_GUILDAsystem/@PowerNetwork/build_simulation_data.m`, `private/simulation_blocks.m`, `private/check_islands.m`, `private/struct_result.m`, `private/branch_state_matrix.m`(新規) | §4.2, §4.5 | E2 |
| `SystemTools/GUILDA/en/PowerNetwork.xml` | `OpenBranchIsland` の本文 | E2 |
| `_GUILDAsystem/_auxiliary/@SolverODE/solve.m`(`set_phase` を含む), `set_admittance.m`, `SolverODE.m`(宣言), `build_index.m`, `initial_condition.m`, `getNextPhase.m`, `getODEFunction.m`, `getODEJacobian.m`, `phase_result.m` | §4.3 | E2 |
| `_GUILDAsystem/_auxiliary/@ResultODE/*` | LC の出力の NaN(必要なら) | E2 |
| `_GUILDAverification/IEEJ_EAST10/compare_table4_3.m`, `IEEJ_EAST30/compare_table4_9.m`, `IEEJ_WEST10/compare_table4_5.m`, `IEEJ_WEST30/compare_table4_13.m`, `_GUILDAverification/README.md` | `add_csv_scenarios` の `FaultBus`/`TripUnit`/`OpenBranch` を `add_fault`/`add_trip`/`add_open_branch` に。WEST30 の `tab_disturbance.FaultBus`/`OpenBranch` の検査を `tab_fault`/`tab_parallel` に | E1 |
| `_GUILDAobject/+network/@IEEJ_EAST10, @IEEJ_WEST10, @IEEJ_WEST30`(とクラスのデータ) | 回線数(§9 Q13) | N1 |
| ヘルプの例(`add_fault` など。API が残るので確かめるだけ): `+controller` の 6 クラス、`+network` の 13 ファイル、`PowerNetwork.m`, `add_scenario.m`, `simulate.m`, `ResultODE.m`, `get_point.m`, `SolverODE.m`, `IEEJ_LPT1.m`(`add_trip`)、`IEEJ_WEST10.m` の「Scenario.add_open_branch」 | 変える必要がないことを確かめる | E1 |

### 6.2 テスト(`+DebugScript/`)

| ファイル | 内容 | 手順 |
|---|---|---|
| `+helper/scenario.m` | Name-Value の `FaultBus`/`TripUnit`/`OpenBranch` を `add_fault`/`add_trip`/`add_open_branch` に振り分け、残りを `add_disturbance` に(呼び出し側の 26 ファイル 約 160 か所を変えずにすむ)。外乱のタグは指定できなくなるので、返り値か `sc.tab_fault.Tag` で読む | E1 |
| `+helper/combine.m` | 3 つの表を写す | E1 |
| `+helper/simulate_baseline.m` | `phases` の比較(§4.4) | E2 |
| `test_F31_scenario.m` | `Tag=` の 5 か所、`remove_disturbance`、`tab_disturbance` の 19 か所、JSON | E1 |
| `test_F16_csv_io.m` | シナリオの往復(version 2)、`circuit` の列 | B1, E1 |
| `test_I52_validate_events.m`, `test_I53_scalar_timespan.m`, `test_I60_event_network.m` | 検査の ID、LC の解列が許されること | E1 |
| `test_F32_model_gui.m` | シナリオの GUI のページ | E1 |
| `test_F6_simulation.m`, `test_F29_open_branch.m`, `test_F39_simulation_data.m`(`c_branchY`, `iv_openBranch`), `test_I55_time_limit.m`, `test_I62_keep_completed_phases.m`, `test_I64_simulate_sparse.m` | `output.phases` の列名、`sct_event`/`sct_dae` の項目 | E1(列名), E2(項目) |
| `test_F38_result_judge.m`, `test_F40_stop_and_sample_time.m`, `test_F36_tutorial_all_models.m` | `add_fault`/`add_trip` の呼び出しが通ること | E1 |
| `test_F1_model_building.m`, `test_F22_model_contract.m`, `test_F2_powerflow.m` など `get_admittance_matrix` を使う 17 ファイル | 引数なしの呼び出しは変わらない。F22 は抽象メソッドの約束(引数) | B1 |
| `test_levels.m` | 新しいテストの行、F29 の節の名前 | B1, E1, E2 |

### 6.3 `get_admittance_matrix` の引数なしの呼び出し(変えない)

`PowerNetwork.get_admittance_matrix`, `calculate_powerflow`, `initialize`, `get_linear_port`, `private/solve_fixed_input`, `private/simulation_blocks`, `Branch.struct`, `Branch.get_opf_condition`, `Branch.cv_Iequilibrium`, `SolverPF`, `SolverCPF`(`solve`, `limit_set`), `ResultPF`, `MethodDynamic`, `DrawerNetDiagram/set_network`, `tools.network_to_mpc`。

## 7. 実装の手順

各手順は 1 つのサブセッションの大きさです。各コミットで `DebugScript.run_all('Level','small','FailOnUnexpected',true)`、統合の前に medium を 1 回実行します。E1 と E2 の後は `simulate_baseline(Mode="compare")` も実行します。

| 手順 | 内容 | 持つファイル | テスト | 依存 |
|---|---|---|---|---|
| **B1** ブランチの状態 | §2: `circuit` と `Circuit`、4 クラスの `get_admittance_matrix`、`Branch.xml`、CSV の列、ヘルプ | `_GUILDAobject/+branch/*`, `@Branch/Branch.m`, `@PowerNetwork/add_branch.m`, `import.m`, `export.m`(列だけ), `Branch.xml`, `functionSignatures.json` | 新規 F41(§8.1)、F16 の `circuit`、F22 | §9 の回答 |
| **E1** シナリオの表と API | §3: 3 つの表、`add_*`、`remove_disturbance`、重なり、JSON version 2、`From`、GUI、検証スクリプト、補助関数。`compile` は新しい表から**今と同じ `sct_event`** を作る(`"6open"` は `iv_openBranch`。`3open`/ブランチの地絡/LC の解列は E2 までの暫定で `GUILDA:Scenario:NotYetSupported` [提案、E2 で削除]) | `@Scenario/*`, `Scenario.xml`, `add_scenario.m`, `read_scenarios.m`, `write_scenarios.m`, `export.m` のヘルプ, `_GUILDAverification/*`, `+helper/scenario.m`, `combine.m`, §6.2 の E1 のテスト | F31, F16, I52, I53, I60, F32, 列名を読むテスト、`simulate_baseline`(列名の対応を暫定でこの手順に入れてもよい) | §9 の回答 |
| **E2** シミュレーション | §4: `compile` の出力、スタンプ、`branch_state_matrix`、島の検査、`SolverODE` の LC の解列とスタンプ、`struct_result`、`simulate_baseline` の比較、`NotYetSupported` の削除 | `@Scenario/compile.m`, `build_simulation_data.m`, `@PowerNetwork/private/`(4 ファイル), `PowerNetwork.xml`, `@SolverODE/*`, `@ResultODE/*`(必要なら), `+helper/simulate_baseline.m`, F39, F29 | 新規 F42(§8.2)、F39, F29, F6, I62、基準の 6 例 | B1, E1 |
| **N1** IEEJ の回線数 | §9 Q13 の回答に従い、IEEJ の系統の `Circuit` を設定(`"close"` は変わらないので軌道も潮流計算も変わらない) | `_GUILDAobject/+network/@IEEJ_*/`(クラスとデータ) | F25 など系統のテスト、`_GUILDAverification` の 1 例 | B1 |
| **D1** 文書 | §5 | `_GUILDAdoc/`, `notes/v4-migration.md`, `notes/status.md`, Update log | `GUILDA.doc` の警告 | E2(利用者向けの部分は E1 の後に並行可) |

**並行できる組 [提案]**

- **B1 と E1 は並行できます。** 重なるファイルは `export.m`(B1 は列、E1 はヘルプの 1 行)と `functionSignatures.json` だけなので、`export.m` のヘルプは E1、`functionSignatures.json` の再生成は後に統合する方だけが行います。E1 は回線数を読みません(1 回線の検査は E2)。
- E2 は B1 と E1 の統合の後です(`compile.m` を E1 から引き継ぎ、`get_admittance_matrix(Status=...)` を使う)。
- N1 は B1 の後、E1・E2 と並行できます(`+network` は他の手順が触らない。ヘルプの例の確認は E1 が読むだけ)。
- D1 の `feature-data-io.html`, `feature-model-building.html` は E1・B1 の後、`feature-simulation.html` は E2 の後です。

## 8. テスト計画

### 8.1 新規 F41: ブランチの状態(B1、small)

- 4 クラス × n = 1, 2, 3 × (tap, φ) = (1, 0), (0.97, 0.1): `"close"` が今の式(テストに写した式)と `isequal`、引数なしと `isequal`。
- `"6open"` が `zeros(2)`、`"3open"` が `Y_close·(n-1)/n`(n ≥ 2)。
- `"3LG"`, `"6LG"` を p = 0.01, 0.3, 0.5, 0.99 で、§2.4 の性質(3 節点の縮約、`6LG = n·G1`、`3LG - 3open = G1`、pi・T の対称)。
- エラー: `Point` が 0, 1, NaN, 1.2(`InvalidPoint`)、`"close"` に `Point`(`PointWithoutFault`)、n = 1 の `"3LG"`/`"3open"`(`SingleCircuit`)。
- `add_branch(..., Circuit=3)` と既定 2、`export` → `import` の往復で `circuit` が保たれる、列のない CSV で 2。

### 8.2 新規 F42: ブランチのイベントと LC の解列(E2、medium)

- `add_open_branch(br, [1 3])` と `add_open_branch(br, [1 3], Status="6open")` の軌道が `isequaln`(F29 の旧 OpenBranch の期待値と同じ)。
- n = 2 の `"3open"` で `sct_dae.c_stamp` が `-Y_close/2`、潮流が半分の線路で流れる(定常の電流の確認)。
- ブランチの `"3LG"` を p = 1e-6 で与えた軌道が、送電端の母線の地絡 `BG` と相対 1e-3 以内 [未確認: 許容は実装時に決める]。
- 合成の表(§2.5)の 6 通りの `tab_branch` とスタンプ(`(6LG, 3open)` を含む)。3LG [1, 1.1] と 3open [1.1, Inf] が 3open だけと同じ行列になること。
- 島の検査: `"6LG"` で切り離した部分が `OpenBranchIsland`。
- LC の解列: AVR を [1, 1.5] で解列 → 状態が NaN、機器の `Vfield` が平衡値、1.5 で状態が平衡点から再開。PSS の解列 → 機器の `Vpss` 相当の入力が 0。LC の解列の `Format="struct"` の NaN。
- 期間の終わりが `tend` 以後(`[1, 20]` を `Time=[0,10]`、`[1, Inf]`)で区間の境界が増えず、終わりまで開放。

### 8.3 既存のテストの書き換え(E1)

- F31: `Tag=` の削除、タグ `Fault001`/`Parallel001`、1 つのタグの 2 行、`remove_disturbance` が 2 行を消す、重なり(`OverlappingEvents`)と接する期間、`add_fault` のブランチの `Status`/`Point` の検査、`add_trip` の LC、`ReservedTag`(`Fault001` を `add_offset` の `Tag` に)、JSON version 2 の往復と version 1 の拒否、`From` で 3 つの表が写る。
- F16: シナリオの往復(version 2、`Fault`/`Parallel` の `NaN`/`Infinity`)。

### 8.4 軌道が変わらないこと(E1, E2)

- `simulate_baseline(Mode="compare")` の 6 例で `rv_t`, `rm_variable`, `rm_I`, `flag` が `isequaln`、`phases` は値が `isequaln` で列名が対応表どおり(§4.4)。E1 の後と E2 の後に実行し、結果をこの文書の実装の状況に記録します。
- `_GUILDAverification` の IEEJ の比較の 1 例(EAST10 の peak の 2 例など、S6 と同じ)で報告との一致が変わらないこと(E1)。

## 9. 問い

すべて推奨案を付けます。回答までは [要確認] の提案として扱います。

| # | 問い | 推奨 |
|---|---|---|
| Q1 | `add_disturbance` の `FaultBus`/`TripUnit`/`OpenBranch` をどうするか。タグを利用者が決める一般形と、「タグは自動」の決定が合わず、1 つの期間で故障と開放を組み合わせると 2 つの表にまたがる | **削除**し、`add_disturbance` はオフセットと入力の一般形にする。呼び出し元(検証スクリプト 4 つ、`+helper/scenario.m`)は `add_fault`/`add_trip`/`add_open_branch` に |
| Q2 | 同じ表・同じ対象の期間の重なり(例: `add_fault(B,[1 2])` と `add_fault(B,[1.5 3])`)。「次のイベントまで続く」では `[1, 2]` の故障になり、今の和集合 `[1, 3]` と違う | **エラー**(`OverlappingEvents`)。接する期間は許す。期間の API しかないので、重なりを意味のある形で書く手段がない |
| Q3 | `add_fault` のブランチで `Status`/`Point` を省いたとき | **必須(エラー)**。既定(例: `"6LG"`, 0.5)を置くと、母線の故障のつもりでブランチのタグを渡した誤りに気づけない |
| Q4 | LC の解列中、出力が届いていた入力を「0」と「平衡値」のどちらにするか。PSS(平衡の出力 0)では同じだが、AVR(出力が界磁電圧そのもの)では 0 だと界磁が 0 になる | **平衡値**(接続を `equilibrium` に切り替えたのと同じ)。「機器は平衡の入力を保つ」の決定に合う |
| Q5 | `two_winding_transformer` の位相の掛け方 `ym·E` は φ ≠ 0 で電力を保存しない(受電端の電流に位相が戻らない) | **この作業では変えない**(`"close"` の一致の決定と、同梱の系統はすべて φ = 0)。別の Issue として記録し、直すなら全状態の式を `Dᴴ·Y·D` の形にする |
| Q6 | 回線数の名前と置き場所 | `tab_parameter.dynamics` の **`circuit`**、`add_branch` の **`Circuit`**(既定 2) |
| Q7 | 解列した LC の子の LC も解列するか | **しない**(子の出力は外した入力に入るだけで、子の状態は観測から正しく動く)。親子とも止めたいときは両方を `add_trip` に渡す |
| Q8 | `get_admittance_matrix` の検査と合成(§2.4 の表)を各クラスに書くか、`Branch` に共通の関数を置くか | **各クラスに書く**(新しいメンバーを足さない。重複は 4 ファイルで数行)。`Branch` に protected の補助メソッドを置く案は、自作のクラスが 1 回線の `G1` だけを書けばよくなる利点があるので、望むなら代わりにそれにする |
| Q9 | `"close"`/`"3open"`/`"6open"` に `Point` を与えたとき | **エラー**(`PointWithoutFault`)。黙って無視すると、`Status` の書き間違いに気づけない |
| Q10 | オフセットと入力の表の名前 | **`tab_disturbance` のまま**(3 列を除くだけ)。`tab_input` などへの改名は呼び出し元が増えるだけ |
| Q11 | `(6LG, 3open)` の行列 | **`get_admittance_matrix` に状態を足さず**、`build_simulation_data` 側で `((n-1)/n)·Y("6LG", p)` を作る。5 つの状態という決定を保つ |
| Q12 | 島の検査で、両端を結ばない地絡(`6LG`)を開放と同じに扱うか。地絡したブランチでつながる部分は V = 0 に解けるので DAE は特異ではない | **開放と同じに扱う**(エラー)。部品のない部分が地絡だけで残る状況は入力の誤りがほとんどで、メッセージで気づける |
| Q13 | IEEJ の系統の回線数。EAST10・WEST10 は 1 回線を 1 ブランチ、WEST30 はカードの n 回線を 1 ブランチにしている。既定 2 のままだと EAST10・WEST10 の `"3open"` が「回線の半分」の誤った意味になる | **N1 で設定**: EAST10・WEST10 の回線のブランチは `Circuit=1`、WEST30 はカードの n。変圧器は 1(バンク数が分かれば その数)。`"close"` は変わらないので結果は変わらない |
