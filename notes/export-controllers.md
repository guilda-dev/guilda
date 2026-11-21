# 制御器の書き出しと読み込み(仕様)

この文書のブランチは `feature/export-controllers` です。調査の基準は `refactor/design-alignment` の `e315064d` です。**この文書は仕様です。コードはまだ変えていません。** §8 の未決事項に利用者が答えた後、§7 の手順でサブセッションに分けて実装します。

**根拠の区別**

- **[事実]** 基準コミットのコードを読んで、または MATLAB R2026a で動かして確認しました。
- **[依頼]** 利用者の依頼(2026-11-18)です。
- **[提案]** この文書の提案です。
- **[未確認]** 調べていない、または MATLAB で動かしていない事項です。

**関連ノート:** [generator-controller-slots.md](generator-controller-slots.md)(役割の枠、既定の Static)、[retrofit-controller.md](retrofit-controller.md)(`pss-retrofit` を `avr-static` の下に付けること)、[scenario-event-classes.md](scenario-event-classes.md)(シナリオの JSON)、[model-building-improvements.md](model-building-improvements.md) の CT3(以前は「警告のみ」を推奨しました。今回の依頼でこれを改めます)。

## 0. 目的

**[依頼]** 「制御器もシナリオも出力するようにしてください」。いまの `net.export` はシナリオを保存しますが、制御器を保存しません(警告 `GUILDA:PowerNetwork:ControllersNotSaved`)。そのため、制御器を対象にするシナリオは読み込めません。`export` がローカル制御器とグローバル制御器を保存し、`import` がそれらを戻して、`export` → `import` でネットワークがシナリオごと往復するようにします。方針は「単純に、後方互換のためのコードは書かない」です。

## 1. 現状 [事実]

### 1.1 export と import

- `net.export(path)` は次を書きます: `network/parameter.csv`(Hz、baseMVA)、`bus/parameter.csv`、`branch/parameter.csv`、`component/<key>/main.csv`・`dynamics.csv`・`opf.csv`、`scenario/<tag>.json`、フォルダ名が `@` で始まるときはクラスファイル `<Name>.m`。母線・ブランチ・機器の表には完全なタグの列 `FullTag` があります。機器は `Bus`(母線の表の行番号)で母線を指し、`ParameterID`・`OpfID` で `dynamics.csv`・`opf.csv` の行を指します(同じ行はまとめます)。
- 最後に `warn_controllers_not_saved` が、既定の Static(`avr-static`、`gov-static`)以外のローカル制御器と、すべてのグローバル制御器を警告に並べます。
- `Overwrite=true` は `network`, `bus`, `branch`, `component`, `scenario` のフォルダとクラスファイルを消してから書きます。
- `PowerNetwork.import(path)` は、まずすべての表とシナリオのファイルを読んで検査し(`read_csv`, `check_cols`, `check_bus_rows`, `read_components`, `read_scenarios`)、その後で系統を変えます。順序は Hz・baseMVA → `add_bus` → `add_branch` → `add_component` → slack → `add_scenario` + `add_from_json_struct` → `initialize`(`Initialize=true` のとき)です。ブランチと機器は追加の直後に `set_full_tag` で `FullTag` のタグにします。キーの誤りや潮流の失敗など、検査の後の失敗では系統が途中まで作られます(ヘルプに書いてあります)。
- 機器を作ると、同期発電機は `avr-static` と `gov-static` を持ちます(`add_component` の時点)。読み込んだ発電機も同じです。

### 1.2 組み込み系統の制御器の持ち方

組み込み系統は、クラスのコンストラクタで `PowerNetwork.import(..., Network=obj, Initialize=false)` を呼んだ後、`private/` の関数で制御器を付けます。

| 系統 | ファイル | 列 | 付け方(`private/`) |
|---|---|---|---|
| IEEE9bus(3 台)、IEEE68bus(16 台) | `controller/avr/parameter.csv` | `Bus`, `ttr`, `tap`, `kap`, `Vap_max`, `Vap_min`, `tst`, `kst`, `Limiter` | `add_avr_pss.m`: `a_Component{1}` に `"avr-ST1"`(キーはコードに固定) |
| 同上 | `controller/pss/parameter.csv` | `Bus`, `kpss`, `tWS`, `tn1`, `td1`, `tn2`, `td2`, `Vpss_min`, `Vpss_max` | 同じ関数で `"pss-PSS1"` |
| IEEJ_EAST10/EAST30/WEST10/WEST30(各 `peak`・`night`) | `<section>/controller/avr/parameter.csv` | `Bus`, AVR_DC1 の 14 列(`Limiter` を含む) | `add_avr.m`: `"avr-DC1"` |
| 同上 | `<section>/controller/governor/parameter.csv` | `Bus`, `LPT`, `Prate`, `PLM` | `add_governor.m`: キーは `"gov-LPT" + LPT` |

- どれも `Bus` の母線の **1 番目の機器** に付けます。キーはファイルになく、コードが決めます(`avr` が IEEE では ST1、IEEJ では DC1)。
- 調速機を書かない IEEE9bus/68bus は、発電機の既定の `gov-static` をそのまま使います。
- `LocalController=false` はすべての制御器(既定の Static も)を外します。IEEJ の `Governor=false` は `add_governor` を呼ばず、`gov-static` を残します。
  - (2026-11-20 変更、`feature/local-controller-default-false`)今の `LocalController=false` は `local_controller/` の制御器だけを外し、`avr-static` と `gov-static` を残します。既定も `false` になりました。[generator-controller-slots.md §8](generator-controller-slots.md) を見てください。
- `private/` の補助関数は 6 クラスにあり、`add_avr.m`・`add_governor.m` は IEEJ の 4 クラスに同じものがあります。
- `Tutorial10bus` はコードで制御器を付けます: すべてのローカル制御器のクラスと `agc-PI` です(`Tutorial10bus.m:122-133`)。

### 1.3 制御器のクラス

`GUILDA.keymap` の制御器のキーは次のとおりです(MATLAB で確認)。

| キー | クラス | 役割 `s_role` | `tab_parameter.dynamics` の列 | 表の外のコンストラクタ引数 |
|---|---|---|---|---|
| `avr-static` | `controller.avr.Static` | avr | なし | なし |
| `avr-ST1` | `controller.avr.AVR_ST1` | avr | 8 列(`Limiter` は logical) | なし |
| `avr-DC1` | `controller.avr.AVR_DC1` | avr | 14 列(`Limiter` は logical) | なし |
| `pss-PSS1` | `controller.pss.PSS1` | pss | 8 列 | なし |
| `pss-retrofit` | `controller.pss.Retrofit` | pss | なし | `Q`, `R`(行列) |
| `local-LQR` | `controller.local_LQR` | local | なし | `Q`, `R`(行列)、`Input`(string 列)、`V0`(複素数) |
| `gov-static` | `controller.governor.Static` | governor | なし | なし |
| `gov-LPT1` / `gov-LPT3` / `gov-LPT4` | `controller.governor.IEEJ_LPT*` | governor | 13 / 9 / 14 列(`Prate` は NaN が既定) | なし |
| `agc-PI`(グローバル) | `controller.agc.broadcast_PI_AGC` | agc | 制御対象 1 台につき 1 行(行名は機器のタグ): `alpha`, `beta`, `kP`, `kI` | なし(`kP`, `kI` は引数ではスカラー、表では各行に同じ値) |

- **ローカル制御器の `a_Parameter` は `dynamics` だけ**です。表のあるローカル制御器は、コンストラクタの引数名が表の列名と同じです。`add_local_controller(key, parameter=<表の 1 行>)` で同じ表ができることを、`Tutorial10bus` の全制御器で確かめました(`local-LQR` を除く 11 個で `isequaln` が真)。
- `local-LQR` の表は空なので、表だけでは `Input="Vfield"` が失われ、すべての入力を駆動する LQR になります(`Tutorial10bus` では調速機と `Pmech` が重なってエラー)。`K` と `sys_design` は `initialize` が計算するので保存は不要です。
- 関数ハンドルを利用者から受け取る制御器のクラスはありません(`+controller`, `@LocalController`, `@GlobalController` に `function_handle` の型の宣言はありません)。`f_*` はクラスから `set_odefcn` が作るキャッシュです。
- **入れ子の枠は AVR の下の PSS だけ**です(`GUILDA:LocalController:NestedControllerSlot`)。`Component.add_local_controller` は、`pss` の役割を機器の AVR の下に付けます。親は役割で決まります。
- **タグ:** ローカル制御器は「機器のタグ + ヘッダー(`CA`, `CP`, `CG`, `CL`)+ 番号」(例 `B001SG1CA1`, `B001SG1CP2`, `B001SG1CG3`)。番号は機器の中の最大 + 1 で、既定の Static は数えません。グローバル制御器は「ネットワークのタグ + `AGC` + 番号」で、組み込み系統のネットワークのタグは `"PowerNetwork"` なので `PowerNetworkAGC1` です。どちらも `s_tag` に代入して改名できます(`LayerPackage.set.s_tag`、兄弟と重なると番号を付ける)。
- グローバル制御器の観測(`sv_u` を各制御対象のどこで読むか)と出力の行き先(`get_variable_map` の `"global"` の行)は、クラス、制御対象、その時点で付いているローカル制御器から `add_global_controller` が決めます。保存する値はありません。
- `con.tab_parameter.dynamics = tab` は型を検査します。`Limiter` に double を入れると `'Limiter' must be logical` で拒まれます。`writetable` は logical を `1`/`0` と書き、`readtable` は double で読みます。

### 1.4 再現した失敗

IEEE9bus に PSS の解列のシナリオを足して往復すると、`import` がシナリオの段階で止まります(MATLAB で確認)。

```matlab
net = network.IEEE9bus();
sc  = net.add_scenario("psstrip");
sc.add_trip("B001SG1CP2", [1, Inf]);
net.export(fullfile(tempdir, "probe9"), Overwrite=true);   % ControllersNotSaved の警告
PowerNetwork.import(fullfile(tempdir, "probe9"));
% Parallel event "Parallel001" of scenario "psstrip": B001SG1CP2 is not a component,
% global controller, local controller or branch of network "probe9". ...
```

グローバル制御器を対象にする解列(`sc.add_trip(agc.s_tag, ...)`)も同じです。シナリオの JSON には対象のタグ(`"Target": "B001SG1CP2"`)がそのまま入っています。

### 1.5 組み込み系統の形式を流用できるか

**そのままでは使えません。** 理由は次の 3 つです。

1. キーがファイルにありません(`avr` のキーは系統のクラスのコードで決まり、調速機は `LPT` 列から作ります)。
2. `Bus` の 1 番目の機器にしか付けられず、1 つの母線に制御器を持つ機器が複数あると表せません。
3. タグを保存しません。シナリオの対象を戻すにはタグが要ります。

そこで、`component/<key>/` と同じ考え方(キーごとのフォルダ、行ごとに完全なタグ)の新しい形式を作り、**組み込み系統のフォルダもこの形式に変えます**(§7 の S3、§8 の Q3)。こうすると、組み込み系統のフォルダと書き出したフォルダが同じ形になり、`private/` の補助関数 10 個がなくなります。

## 2. ローカル制御器のファイル形式 [提案]

### 2.1 配置

```
<path>/local_controller/<key>/parameter.csv   キー <key> のローカル制御器 1 個につき 1 行
<path>/local_controller/<key>/option.json     表の外のコンストラクタ引数(あるキーだけ、§2.6)
```

- フォルダ名は keymap の区分(`LocalController`, `GlobalController`)とプロパティ(`a_LocalController`, `a_GlobalController`)に合わせます。`controller/` 1 つにまとめると、ローカルとグローバルの区別が付きません。
- `<key>` は `GUILDA.keymap("LocalController")` のキーです(`avr-ST1`, `pss-PSS1`, `gov-LPT1`, `local-LQR`, `avr-static` など)。役割ごとのフォルダ(`avr/`)にはしません。キーが 1 つに決まり、調速機の `LPT` 列のような特別な読み方が要らなくなります。

### 2.2 parameter.csv の列

| 列 | 内容 |
|---|---|
| `Component` | 制御器が付く機器の完全なタグ(例 `B001SG1`)。PSS もその AVR ではなく**機器**のタグです |
| `FullTag` | 制御器の完全なタグ(例 `B001SG1CP2`) |
| 残りの列 | `tab_parameter.dynamics` の列をそのままの名前と順で(表のない `avr-static`, `gov-static`, `pss-retrofit`, `local-LQR` は `Component` と `FullTag` だけ) |

IEEE9bus の例(S3 で変換した後の組み込み系統も同じ形です):

```
local_controller/avr-ST1/parameter.csv
Component,FullTag,ttr,Vap_max,Vap_min,kap,tap,kst,tst,Limiter
B001SG1,B001SG1CA1,0,Inf,-Inf,2,0.05,0,0,1
...
local_controller/pss-PSS1/parameter.csv
Component,FullTag,kpss,tWS,tn1,td1,tn2,td2,Vpss_max,Vpss_min
B001SG1,B001SG1CP2,20,10,0.05,0.015,0.08,0.01,Inf,-Inf
...
local_controller/gov-static/parameter.csv
Component,FullTag
B001SG1,B001SG1CG1
...
```

- **役割と枠:** 列には書きません。キーのクラスの `s_role` で決まり、`add_local_controller` がその枠に付けます(`avr`/`local` は機器の 1 つ目の枠、`governor` は 2 つ目の枠、`pss` は機器の AVR の下)。
- **親:** 入れ子は AVR の下の PSS だけなので、`Parent` 列は作りません。PSS の行の `Component` には、役割 `avr` の行(`avr-static` を含む)が同じ `Component` にあることを読み込みの前に検査します(§5.2)。入れ子の枠が増えたら、そのときに `Parent` 列を足します。
- **1 つの母線に複数の機器:** `Component` が機器のタグなので区別できます。組み込み系統の `Bus` 列は使いません。
- **タグと番号:** `FullTag` に完全なタグを書き、読み込みでは追加の直後にそのタグにします(機器と同じ `set_full_tag`)。自動の番号(Static を数えない、`CG3` など)に頼らないので、手で書いたフォルダでも保存時のタグが戻ります。`FullTag` の列がないか空の値なら、自動のタグです(機器と同じ規則)。
- **パラメータの型:** `writetable` は logical を `1`/`0`、`Inf` を `Inf`、`NaN` を `NaN` と書きます。読み込みは、1 行を struct にして `add_local_controller(key, parameter=...)` に渡します。コンストラクタの arguments ブロックが `1` を logical に変えるので、`Limiter` は logical に戻ります(MATLAB で確認)。`Prate = NaN` もそのまま戻ります。
- 行の順は、機器の順(母線の順、母線の中の `a_Component` の順)です。

### 2.3 既定の Static を保存するか

**[提案] すべて書きます(案 A、§8 の Q1)。** `avr-static` と `gov-static` も他のキーと同じく 1 行ずつ書きます。

- 読み込みは、`local_controller/` があるとき、フォルダから作った機器の制御器(作成時の Static)を**先にすべて外し**、ファイルの行だけを付けます。ファイルに行のない機器は制御器なしになります。
- `local_controller/` がないフォルダ(いまの IEEE14bus など、制御器を書いていないフォルダ)では何もしません。発電機は作成時の Static を持ったままです。これは互換のための分岐ではなく、`add_component` のふつうの動作です。
- 案 A の利点: ファイルが付いている制御器をそのまま表します。`LocalController=false` の系統(制御器なし)、`gov-static` だけを外した発電機、`avr-static` の下の `pss-retrofit`(Tutorial10bus の `B004SG1CP1`)、両方の Static を置き換えた `local-LQR` が、特別な規則なしで戻ります。
- 案 A の欠点: 発電機ごとに Static の行が増えます(IEEE14bus なら `avr-static` と `gov-static` が 5 行ずつ)。制御器がまったくない系統の書き出しは空の `local_controller/` になります。空のフォルダは git や zip で消えることがあり、消えると読み込みで Static が戻ります。
- 案 B(Static は書かず、作成時の Static に任せる): 書く行は減りますが、Static を外した状態(`LocalController=false`, `Governor=false` で外したもの)を表せません。

### 2.4 書き出し

`export` は機器ごとに `all_controllers` の順(深さ優先: AVR または local、その PSS、調速機)で制御器を集め、キーごとに表を作って `local_controller/<key>/parameter.csv` に書きます。`warn_controllers_not_saved` と警告 `GUILDA:PowerNetwork:ControllersNotSaved` は削除します。`Overwrite=true` は `local_controller/` と `global_controller/` も消します。

### 2.5 機器のパラメータとの違い

機器は `ParameterID` で同じ行をまとめていますが、制御器では 1 行に 1 個の制御器を書きます。制御器の数は機器より少なく、1 つの表で読めるほうが手で編集しやすいからです。

### 2.6 表の外のコンストラクタ引数(option.json)

`local-LQR` の `Q`, `R`, `Input`, `V0` と `pss-retrofit` の `Q`, `R` は表にありません。これらは次の形で保存します(§8 の Q2)。

- **[提案] 新しいメンバー:** `LocalController` と `GlobalController` に Hidden のメソッド `sct = get_option(obj)` を足します。コンストラクタの Name=Value のうち `tab_parameter.dynamics` にないものを struct で返します。基底クラスは `struct()` を返し、`local_LQR`(`Q`, `R`, `Input`, `V0`)と `Retrofit`(`Q`, `R`)が上書きします。`Input` は private の `sv_input`(与えたとおり、空はすべての入力)を返します。
- `export` は、空でない `get_option` のあるキーだけ `option.json` を書きます。形は `FullTag` をキーにしたオブジェクトです。

  ```json
  {
    "B003SG1CL1": {"Q": [], "R": [], "Input": ["Vfield"], "V0": 1}
  }
  ```

  `jsonencode(..., PrettyPrint=true, ConvertInfAndNaN=false)` で書きます(シナリオと同じ)。行列は入れ子の配列です。`jsonencode` は複素数を書けないので(MATLAB で確認)、複素数の値は `{"re": ..., "im": ...}` と書き、読み込みで戻します。
- 読み込みは、表の 1 行の struct に `option.json` のその `FullTag` の値を足して `parameter=` に渡します。
- `get_option` の契約は model-implementation のページに書きます: 「コンストラクタの引数は、`tab_parameter.dynamics` の列(同じ名前)か `get_option` の項目のどちらかです。どちらでもない値は保存されません。」

## 3. グローバル制御器 [提案]

### 3.1 配置と列

```
<path>/global_controller/<key>/parameter.csv   制御対象 1 台につき 1 行
<path>/global_controller/<key>/option.json     表の外のコンストラクタ引数(あるキーだけ。agc-PI にはない)
```

| 列 | 内容 |
|---|---|
| `FullTag` | グローバル制御器の完全なタグ(例 `PowerNetworkAGC1`)。同じ制御器の行は同じ値 |
| `Component` | 制御対象の機器の完全なタグ。行の順が `controlledUnits` の順 |
| 残りの列 | `tab_parameter.dynamics` の列(`agc-PI` は `alpha`, `beta`, `kP`, `kI`)。表の行名(制御対象のタグ)は `Component` 列で表します |

例(Tutorial10bus):

```
global_controller/agc-PI/parameter.csv
FullTag,Component,alpha,beta,kP,kI
PowerNetworkAGC1,B001SG1,1,1,100,500
PowerNetworkAGC1,B002SG1,1,1,100,500
PowerNetworkAGC1,B003SG1,1,1,100,500
PowerNetworkAGC1,B004SG1,1,1,100,500
```

- **キー:** フォルダ名です。
- **タグ:** `FullTag` に書きます。ネットワークのタグが前に付くので、別の名前のフォルダに読み込んでも(ネットワークのタグはフォルダ名になる)、保存時のタグ `PowerNetworkAGC1` に戻します。シナリオの対象はこのタグなので、そのまま解決します。
- **制御対象:** `Component` 列の行の順です。
- **観測する信号と出力の行き先:** 保存しません。クラスの `sv_u`/`sv_y`、制御対象、付いているローカル制御器から `add_global_controller` が決めます(§1.3)。ローカル制御器を先に付ければ同じになります(§5)。往復のテストで `get_variable_map` を比べて確かめます(§6)。
- **パラメータ:** `agc-PI` のコンストラクタは `kP`, `kI` をスカラーで受けるので、表の列をそのまま `parameter=` に渡せません。読み込みは、制御対象だけで `add_global_controller(key, units, parameter=<option.json の値>)` を呼び、その後で `con.tab_parameter.dynamics` に読んだ表を代入します。代入の前に、各列を既定の表の列と同じクラスに変えます(logical の列のため、§1.3)。行ごとに違う `kP` も戻ります(MATLAB で表の代入ができることを確認)。
- **行列や関数ハンドル(LQR のゲインなど):** いまのグローバル制御器にはありません。表の列は 1 行に 1 つの値(数、logical、string)に限ります。行列は `get_option` で `option.json` に書きます(§2.6 と同じ)。計算で決まる値(ゲイン)は保存せず、`initialize` で作り直します。MAT ファイルは使いません(§8 の Q2)。
- 制御器の順: 同じキーの中では `FullTag` が最初に出た順です。キーが複数あると、フォルダ名の順になり、`a_GlobalController` の順が変わることがあります。いまのキーは `agc-PI` だけなので、この制約は書くだけにします(機器も、キーの違う機器が 1 つの母線にあると同じ制約があります)。

## 4. 保存できない制御器 [提案]

- **keymap にないクラス:** 制御器は `add_local_controller` / `add_global_controller` でしか作れず、どちらも keymap のキーを要求します(`tools.mustBeKeyOf`)。keymap は GUILDA のフォルダの中のクラスから作ります(`GUILDA.dictionary`)。したがって、付いている制御器は必ずキーを持ちます。保存できないのは、**読み込む側にそのクラスがない**場合(別の環境、消したクラス)です。
- **関数ハンドル:** 利用者が渡す関数ハンドルを持つ制御器はありません(§1.3)。
- **表と `get_option` の外の値:** 利用者のクラスが、表にも `get_option` にもない値をコンストラクタで受けると、その値は保存されません。`export` はこれを検出できないので、§2.6 の契約として文書に書きます。

**推奨: 書き出しは警告もスキップもせず、すべてを書きます。読み込みは、知らないキーで系統を変える前にエラーにします。**

- `import` は、`local_controller/<key>` と `global_controller/<key>` のキーを keymap で検査し、ないキーは新しいエラー `GUILDA:import:UnknownControllerKey`(ファイルとキーを示し、`GUILDA.update_keymap` を案内)で止めます。系統(`Network=obj`)は変わりません。
- そのため、制御器を対象にするシナリオが読めずに途中で止まることはありません。
- 「警告して飛ばす」案は採りません。飛ばした制御器を対象にするシナリオが今回と同じエラーになり、制御器のない別の系統が黙って作られるからです。
- `ControllersNotSaved` の警告とメッセージの項目は削除します。

## 5. 読み込みの順序 [提案]

### 5.1 順序

1. 表とファイルをすべて読んで検査します(いまの検査 + §5.2)。
2. Hz・baseMVA。
3. `add_bus`。
4. `add_branch` → `set_full_tag`。
5. `add_component` → `set_full_tag`。
6. **ローカル制御器:** `local_controller/` があれば、手順 5 で作った機器の制御器(作成時の Static)を `remove_local_controller` ですべて外します。その後、機器ごとに役割の順(`avr`/`local` → `pss` → `governor`)で `add_local_controller(key, parameter=...)` を呼び、直後に `set_full_tag` します。役割の順で付けるので、PSS の前に AVR があります。`a_LocalController` の並びは枠で決まるので、ファイルの順によらず元と同じになります。
7. slack(いまと同じ位置。機器が必要)。
8. **グローバル制御器:** ローカル制御器の後です。出力の行き先はその時点のローカル制御器で決まるからです。`add_global_controller` → `set_full_tag` → 表の代入。INFO `GUILDA:PowerNetwork:GconRoute` はいまの `add_global_controller` のまま表示します。
9. シナリオ(対象の検査には制御器が必要)。
10. `initialize`(`Initialize=true` のとき)。

`Network=obj` で既存の系統に足すときは、手順 6 で外すのはフォルダから作った機器の制御器だけです。

### 5.2 系統を変える前の検査

| 検査 | エラー |
|---|---|
| キーが keymap にない | `GUILDA:import:UnknownControllerKey`(新) |
| `Component` 列、グローバルの `FullTag` 列がない | `GUILDA:import:MissingColumns`(既存の `check_cols`) |
| `Component` が機器の `FullTag` にない(機器の表のすべての行に `FullTag` があるとき。ないときは追加の時点のエラー) | `GUILDA:import:UnknownComponent`(新) |
| 1 つの機器に同じ枠の行が 2 つ、または `pss` の行の機器に `avr` の役割の行がない | `GUILDA:import:ControllerSlots`(新) |
| `option.json` が読めない、`FullTag` が表にない | `GUILDA:import:OptionJson`(新) |

`dynamics` の列は、機器の `dynamics.csv` と同じく検査しません(クラスによって違うため)。誤った列名はコンストラクタのエラーになります。役割の重なり(調速機と `local-LQR` の `Pmech` など)は `add_local_controller` のエラーに任せます(途中まで作られる失敗。いまのヘルプの説明のとおり)。

### 5.3 平衡点と stale

- 平衡点は保存しません(いまと同じ)。`Initialize=true` なら手順 10 で計算し、`local-LQR` と `pss-retrofit` の `K` もこのとき設計します。
- `Initialize=false` なら、追加した制御器の `sct_stale` は `equilibrium`, `odefcn` とも「initialize has not been run」のままです。組み込み系統のクラスは `Initialize=false` で読み、自分の編集の後で `initialize` を呼ぶので、いまと同じです。
- タグの設定は "Tag" の編集として記録されます(機器と同じ)。

## 6. 往復の保証とテスト [提案]

### 6.1 等しくなるもの

`export` → `import`(`Initialize=true`)の後、次が元の系統と等しくなります。

- 母線、ブランチ、機器、ローカル制御器、グローバル制御器のタグ(`string(...)` の並び)。
- 各制御器のキー、親(機器、PSS なら AVR)、`a_LocalController` の並び。
- すべての層の `tab_parameter`(制御器の `dynamics`、グローバル制御器の行名を含む)と `get_option` の値。
- シナリオの `tab_event`, `tab_offset`, `tab_input`, `Time`, `Description`(いまの F16 と同じ比較)。
- `net.get_variable_map()` の 4 つの出力(変数の並び、ラベル、所有者、`"observe"`・`"global"` の接続)。
- 各シナリオの `simulate` の `rv_t` と `rm_variable`(F16 と同じ比較)。

**等しくならないもの:** ネットワークのタグ(フォルダ名になる。いまと同じ)、クラス(`network.IEEE9bus` が `PowerNetwork` になる)、編集の履歴、キーの違うグローバル制御器の順(§3.1)。

**比較の方法:** `struct(net,false)` は `class` と `ver`(組み込み系統のクラスの定数)が違うので、そのままでは比べられません(MATLAB で確認)。`disp_summary` はネットワークのタグを含みます。そこで、テストは上の項目を個別に比べます。`struct(net,false)` から `class`, `ver`, `s_tag` を除いて `isequaln` で比べる方法は、動くかどうか確かめていません **[未確認]**。動けば補助の検査として足します。

### 6.2 テスト `test_F70_export_controllers.m`(category `io`)

**番号:** F64-F69 はすべてのブランチとワークツリーで使われています(F64 controller_slots/gui_forms、F65 static_controllers/gui_layout、F66 gui_forms、F67 developer_path、F68 pss_retrofit、F69 gui_layout)。**次の空きは F70** です(`git log --all` とワークツリーのファイルで確認)。`+DebugScript/test_categories.m` に `"test_F70_export_controllers", "io"` を登録し、重いケースは `test_levels.m` で `medium` にします。

| ケース | 確かめること |
|---|---|
| IEEE9bus の PSS の解列(依頼の例) | 読み込みが通る。§6.1 のすべて。シナリオを `simulate` して等しい |
| IEEE68bus | タグ、キー、表、変数の対応(`simulate` は medium の 1 ケースだけ) |
| IEEJ_EAST10(`peak`) | `avr-DC1` の `Limiter` が logical、`gov-LPT*` の 3 キー、`Prate`(NaN) |
| Tutorial10bus | すべてのローカル制御器のクラス、`local-LQR` の `Input="Vfield"`(`option.json`)、`avr-static` の下の `pss-retrofit`、`agc-PI`。AGC の `kP` を行ごとに変えて戻ること、AGC の解列のシナリオ |
| IEEE14bus + `agc-PI` | 別の名前のフォルダでも `PowerNetworkAGC1` が戻る |
| IEEE9bus(`LocalController=false`) | 読み込んだ発電機に制御器がない(空の `local_controller/`) |
| 1 つの母線に制御器付きの機器が 2 つ | 制御器が正しい機器に付く |
| 検査 | 知らないキー、知らない `Component`、AVR のない PSS で、系統を変える前にエラー(`Network=obj` が変わらない) |
| `Overwrite=true` | `local_controller/`, `global_controller/` を消して書き直す |

**既存のテストの修正:** `test_F16_csv_io.m:15`、`test_F30_governor.m:344` は `ControllersNotSaved` を確かめているので、往復で制御器が戻ることの確認に書き換えます。`test_F16_csv_io.m:31`(読み込んだ発電機が Static を持つ)は、`local_controller/` のないフォルダの場合として残します。

## 7. 変更するファイルと手順 [提案]

### 7.1 ファイル

| ファイル | 変更 |
|---|---|
| `_GUILDAsystem/@PowerNetwork/export.m` | `local_controller/`・`global_controller/` を書く。`warn_controllers_not_saved` と `local_controller_paths` を削除。`Overwrite` で消すフォルダ。ヘルプ |
| `_GUILDAsystem/@PowerNetwork/import.m` | §5 の検査と手順 6・8。ヘルプ |
| `_GUILDAsystem/@LocalController/LocalController.m`、`@GlobalController/GlobalController.m` | `get_option` の宣言と基底の実装(Q2 で承認されたとき) |
| `_GUILDAobject/+controller/@local_LQR/`、`+pss/@Retrofit/` | `get_option` の上書き |
| `_GUILDAsystem/_auxiliary/SystemTools/GUILDA/en/PowerNetwork.xml` | `ControllersNotSaved` を削除 |
| `_GUILDAsystem/_auxiliary/SystemTools/GUILDA/en/import.xml` | 新しいエラー 4 つ(§5.2) |
| `_GUILDAobject/+network/@IEEE9bus`, `@IEEE68bus`, `@IEEJ_*`(4 クラス × 2 区間) | `controller/` を `local_controller/<key>/parameter.csv` に変換、`private/add_*.m` を削除、コンストラクタとヘルプ(S3) |
| `+DebugScript/test_F70_export_controllers.m`(新)、`test_categories.m`、`test_levels.m`、`test_F16_csv_io.m`、`test_F30_governor.m` | §6.2 |
| `_GUILDAdoc/developer/feature-data-io.html` | ファイルの表、呼び出し順の図の 12・13(`ControllersNotSaved` を削除)、処理ステップ、失敗の表 |
| `_GUILDAdoc/developer/model-implementation.html` | §2.6 の契約。組み込み系統の `controller/avr` の記述 |
| `_GUILDAdoc/developer/feature-model-building.html` | `controller/avr` の記述 |
| `_GUILDAdoc/database/list_UpdateLog.js` | 更新履歴(制御器を保存すること、フォルダの形、`ControllersNotSaved` の削除) |
| `notes/v4-migration.md` | 「保存しない制御器を警告します」の項を置き換え |
| `functionSignatures.json`(2 つ) | 公開の署名は変わりません。`get_option` は Hidden なので `GUILDA.update_keymap(Signature=true)` の差分がないことだけ確かめます |

1 回だけ呼ぶ補助関数は作りません(`no-single-use-local-functions`)。書き出しと読み込みは `export.m`・`import.m` の節として書き、ローカルとグローバルで共有する部分(表の型を既定に合わせる、`option.json` の読み書き)だけを関数にします。

### 7.2 手順

1 つのサブセッション(ブランチ `feature/export-controllers`)で、手順ごとにコミットします。

- **S1 書き出しと読み込み(表):** §2.1-2.5、§3、§4、§5。テスト F70 のうち `option.json` 以外。F16, F30 の修正。`io` を small で実行。
- **S2 option.json:** Q2 の答えに従い `get_option` と `option.json`。Tutorial10bus の LQR のケース。
- **S3 組み込み系統の変換:** Q3 で承認されたとき。各系統のいまの制御器(タグ、キー、表)を変換の前に記録し、変換の後に一致することを確かめます。IEEE68 の基準の結果(AVR の limiter で記録し直したもの)が変わらないことも確かめます。`io` と `model` を small、マージの前に medium を 1 回。
- **S4 文書:** 開発者ページ、ヘルプ、更新履歴、`v4-migration.md`。

### 7.3 他のコーディネーターとの重なり

- `export.m`・`import.m` の最近のコミットは `124ba6fa`(既定の Static、2026-11-17)、`555549ef`、`c276c284`、`dd192b4b`(グラフの列と `get_layout`/`set_layout`)です。`refactor/design-alignment` に入っていないコミットで、これらのファイル、`+network`、`feature-data-io.html` を変えるものはありません(`git log --all --not refactor/design-alignment`)。
- **グラフの配置の形式**(`graph-layout.md`、仕様は未決)は、`import.m` の列と `export.m` の表を変える予定です。同時に進めるなら、`import.m` は片方ずつ編集します。
- **文書のリポジトリの分割**(`docs-repo-split.md`、相談のみ)は `feature-data-io.html` の置き場所に関わります。
- **生成器の制御器の枠と Static、Retrofit**(F64, F65, F68)の担当: S3 は組み込み系統のコンストラクタを変えます。`LocalController=false`、`Governor=false` の結果が同じであることを確かめます。
- **チュートリアルのブランチ**(`#113`、保留中)と講義の Live Script が `controller/avr` を参照しているかは調べていません **[未確認]**。

## 8. 未決事項

| # | 問い | 推奨 |
|---|---|---|
| Q1 | 既定の Static(`avr-static`, `gov-static`)を書くか | **A: すべて書く。** `local_controller/` があればそれが制御器のすべて(作成時の Static を外す)、なければ作成時の Static のまま(§2.3)。B(書かない)は Static を外した状態を表せません |
| Q2 | 表の外のコンストラクタ引数(LQR の `Q`, `R`, `Input`, `V0`、Retrofit の `Q`, `R`)の保存 | **新しい Hidden のメソッド `get_option` を `LocalController`/`GlobalController` に足し、`option.json` に書く**(§2.6)。MAT は読めず差分も取れないので使いません。CSV のセルに JSON を書く案は、表計算で扱いにくいので勧めません |
| Q3 | 組み込み系統のフォルダを同じブランチで新しい形式に変えるか | **変える(S3)。** フォルダが書き出したものと同じ形になり、`private/add_*.m` の 10 ファイルがなくなります。IEEJ の `Governor=false` は、読み込んだ後に調速機を `gov-static` に置き換えます(そのタグは `CG2` などになり、いまの `CG1` と変わることがあります) |
| Q4 | フォルダ名 | **`local_controller/` と `global_controller/`**(keymap の区分に合わせる)。組み込み系統の `controller/` の名前は使いません |

## 9. 確認していないこと

- `struct(net,false)` から `class`, `ver`, `s_tag` を除いた比較が往復で成り立つか(§6.1)。
- `jsondecode` が 1 要素の string 配列(`["Vfield"]`)を cell で返したとき、`local_LQR` の `Input` の検証がそのまま受けるか(`(:,1) string` への変換)。
- IEEE68bus の往復の `simulate` の時間(medium にするかの判断)。
- チュートリアルと講義の資料に、組み込み系統の `controller/` の参照があるか。
