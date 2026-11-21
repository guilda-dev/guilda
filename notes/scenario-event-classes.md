# シナリオのイベントのクラス(仕様)

この文書のブランチは `refactor/scenario-events` です。調査の基準は `refactor/design-alignment` の `baf9ee56`(`f8c20aaf` を含みます)です。**この文書は仕様です。** §0 の決定に従い、§6 の手順でサブセッションに分けて実装しました(状況は §6.1)。

**根拠の区別**

- **[事実]** 基準コミットのコードを読んで、または MATLAB R2026a で動かして確認しました。
- **[決定]** 利用者が決めた方針です(2026-11-16、§0)。GUI のコーディネーターからの制約(2026-11-17)も含みます。
- **[提案]** この文書の提案で、決定の具体化です。
- **[未確認]** 調べていない、または MATLAB で動かしていない事項です。

**関連ノート:** [branch-status-events.md](branch-status-events.md)(`tab_event` の行、Fault/Parallel のタグ、検査の ID、JSON version 2、解列した源の規則)、[launch-gui.md](launch-gui.md)(`DrawerOptionDialog` と `Default:` の文)。

## 0. 目的と決定

### 0.1 目的

今のシナリオの外乱は 3 つの表(`tab_event`, `tab_offset`, `tab_input`)の行で、追加した後に変えるには、消して足し直すしかありません。故障・解列・開放・オフセット・入力を **1 つずつのオブジェクト(イベント)** にして、追加した後に `edit` で変えられるようにします。表は残し、イベントから組み立てます。表を読むコード(`compile`、JSON の書き出し、GUI)は変えません。

### 0.2 利用者の決定(2026-11-16)

| # | 決定 |
|---|---|
| Q1 | 抽象ハンドルクラス **`EventBase`** と 5 つのサブクラス **`EventFault`**, **`EventTrip`**, **`EventOpenBranch`**, **`EventOffset`**, **`EventInput`** を `_GUILDAsystem/_auxiliary` に置きます(パッケージなし、フラット)。それぞれ Scenario の `add_*` の 1 つに対応します。 |
| Q2 | **`add_disturbance` を削除**します。`add_offset` と `add_input` が代わりです。 |
| Q3 | イベントは **`ev.edit(Name=Value)` だけ**で変わります。オプションは対応する `add_*` と同じです。イベントのプロパティは読み取り専用(SetAccess private か protected)です。`edit` の後、シナリオは**すべてのイベントを検査し直し**(重なり、系統に対する対象)、エラーなら変更を**元に戻します**。 |
| Q4 | `add_fault`, `add_trip`, `add_open_branch`, `add_offset`, `add_input` は、タグの文字列ではなく**イベントのオブジェクトを返します**。 |
| Q5 | **`net.add_scenario(tag, Event={EventFault(...), EventTrip(...)})`**。イベントのコンストラクターは公開で、系統なしで呼べます。渡したオブジェクトはシナリオに**複製**され、追加の時点で対象を検査します。コンストラクターでは系統がないので、対象のタグの補完はできません。 |
| Q6 | **`remove_disturbance` を `remove_event` に改名**します。 |
| 表 | `Scenario.tab_event`, `tab_offset`, `tab_input` は `a_Event`(cell、`SetAccess=private`)を集めた **Dependent** プロパティにします。表を読むコード(`compile`、JSON の書き出し)は変えず、JSON の形式(version 2)も変えません。 |
| タグ | 今のままです。`Fault<n>`/`Parallel<n>` はシナリオが付けます。オフセットと入力のタグの付け方も今のままにします(§2.6)。 |
| 補完 | 新しいメソッドと変わるメソッドは、生成する `functionSignatures.json` でタブ補完を保ちます。`net.a_Scenario{1}.a_Event{1}.edit(` は補完されません(MATLAB は 2 つの波括弧の添字を解決しない)。`ev = sc.add_fault(...); ev.edit(` は補完されます。`_GUILDAsystem/_auxiliary/resources/functionSignatures.json` の修正はブランチ `fix/aux-signatures` にあり、実装の前に統合されます。 |
| 既定の文 | GUI は引数のコメントの `Default: ...` の文を既定値に使います(`update_keymap` が `purpose` に入れ、`DrawerOptionDialog` が読む)。`Scenario.add_fault` の `Status`/`Point`、`PowerNetwork.add_scenario` の `From`、新しい `edit` と `Event` の引数の既定の文を §2.8 に挙げます。 |

### 0.3 GUI のコーディネーターからの制約(2026-11-17)

1. **`tab_event`, `tab_offset`, `tab_input` の列と列の順を、Dependent にした後もそのまま保ちます。** 未統合の GUI のブランチ `feature/guilda-app-sim-tab` がこれらを読み、ネットワーク図の要素を強調します [事実: `tab_sim_diagram.m` が `sc.tab_event.Target`, `sc.tab_offset.OffsetUnit`, `sc.tab_input.InputUnit` を読む]。
2. Scenario の GUI の `add_*` のボタンの変わり方を書きます(`add_disturbance` の削除、`add_*` がオブジェクトを返すこと)。`gui_content.m` は `add_*` を変える手順に入れます(§3.4、§6)。
3. **署名を変える手順では、`GUILDA.update_keymap(Signature=true)` を実行し、2 つの JSON ファイルをコミットします**(`test_F34` を通すため)。
4. 最後の手順で、GUI のコーディネーターに作業が終わったことを知らせます(コーディネーターが行います)。

## 1. 現状 [事実]

### 1.1 Scenario

- `Scenario < LayerPackage`(Sealed)。外乱は 3 つの表 `tab_event`, `tab_input`, `tab_offset`(`SetAccess=private`)に入っています。
  | 表 | 列(順) | 型 |
  |---|---|---|
  | `tab_event` | `Tag`, `Target`, `Time`, `Status`, `Point` | string, string, double, string, double |
  | `tab_offset` | `Tag`, `TimeSpan`, `OffsetUnit`, `OffsetState`, `OffsetValue` | string, double(n×1), string, cell(string 列), cell(double 列) |
  | `tab_input` | `Tag`, `TimeSpan`, `InputUnit`, `InputName`, `InputValue`, `InputMethod` | string, double(n×2), string, cell(string 列), cell(定数の列か時系列の行列), string |

  空の表の型は `private/empty_disturbances.m` が決めます。
- 公開の追加: `add_fault(target, time, Status=, Point=)`, `add_trip(unit, time)`, `add_open_branch(branch, time, Status="6open")` は `private/new_event_rows` で 1 つのタグの 2 行(開始と終了)× 対象を作り、`add_events` で `tab_event` に足します。`add_offset(unit, state, value, time=0, Tag="")`, `add_input(unit, name, value, time, Method=, Tag="")`, `add_disturbance(tag, TimeSpan=, Offset*=, Input*=)` は `add_record` を通ります。どれも**タグの文字列を返します**。
- `add_fault` の `Status` と `Point` は arguments ブロックに既定値がなく、本体で与えられなければ `"BG"` と `NaN` にします。`functionSignatures.json` の `purpose` に `Default:` がありません。
- `add_disturbance` はオフセットと入力を **1 つのタグで両方の表に**入れられます。オフセットも入力もないときは区間の目印として、1 つの時刻なら `tab_offset`、期間なら `tab_input` に 1 行を入れます(`output.phases` の列だけになる)。
- `add_record` のタグ: 空なら `<kind><n>`(`offset1`, `input2`、`n` はその接頭辞で使われている最大の番号 + 1、ゼロ埋めなし)。`t1`, `t2`, `Properties`, `Row`, `Variables`, 空、`NoAction`/`Fault`/`Parallel` + 数字は `ReservedTag`、3 つの表にあるタグは `DuplicateTag`。
- `new_event_rows` のタグ: `Fault`/`Parallel` + (その接頭辞の最大の番号 + 1)の 3 桁(`Fault001`)。対象は `unique(..., "stable")`。行は対象ごとに開始、終了の順。
- `remove_disturbance(tag)`: タグの行を 3 つの表から消します。ないタグは `GUILDA:Scenario:DisturbanceNotFound`。
- 検査: `add_events` は追加後の `tab_event` 全体に `private/validate_events`(対象、行の形、Status と Point、`SingleCircuit`、重なり)を実行します。`add_record` は `private/normalize_input`(表を行列に、時系列の既定 `"foh"`、`MethodWithoutSeries`)と `private/validate_disturbance`(系統に対する対象、状態名・入力名、値の数、時系列)を新しい記録だけに実行します。`validate()` は全体を検査し、`compile` の最初に呼ばれます。
- `compile`, `to_json_struct`, `gui_content` は 3 つの表だけを読みます(`private/get_record`, `blank_record`)。
- `Scenario.sr_field`(Constant, Hidden)は `add_disturbance` のオフセットと入力の名前で、`read_scenarios` が JSON の既知の項目に使います。

### 1.2 PowerNetwork

- `add_scenario(s_tag, Time=, Description=, From=)`。`From` は arguments ブロックに既定値がなく、`purpose` に `Default:` がありません。`From` の複製は `sc.add_events(sc0.tab_event)` とタグごとの `sc.add_record(d, "")` で、**タグを保ちます**。失敗すればシナリオを消します。
- `import` は `read_scenarios` で `scenario/*.json` を検査し、`Scenario.add_from_json_struct` で足します。`Event` の行は `add_events` でタグのまま、`Offset` と `Input` はタグごとに 1 つの記録として `add_record` で足します。同じタグのオフセットと入力の開始時刻が違うと `ScenarioJson` です。
- `export` は `write_scenarios` → `to_json_struct`(表の行ごと)です。

### 1.3 GUI とタブ補完

- **Scenario の GUI の追加のボタンは `@DrawerModelGUI/render.m` にあります**(105-106 行の `sm_add`: `+ Fault`, `+ Trip`, `+ Open branch`, `+ Offset`, `+ Input`, `+ Disturbance`)。表の行のコンテキストメニュー `Remove disturbance` も `render.m`(160-166 行と局所関数 `remove_disturbance`)です。`@Scenario/gui_content.m` は 3 つの表と Settings のページを作るだけで、ボタンは持ちません(GUI のコーディネーターの説明と違うため、§3.4 で両方を扱います)。
- `@GUILDA/update_keymap.m` の `sig_methods` が、`Scenario.add_disturbance`, `add_fault`, `add_trip`, `add_open_branch`, `add_offset`, `add_input`, `remove_disturbance` と `PowerNetwork.add_scenario` の項目を `functionSignatures.json` に書きます。タグの選択肢は `obj.a_PowerNetwork` からの式です。`method_entry` は `<クラス>.<メソッド>` を鍵にし、**1 番目の入力を常に `obj`(型 = クラス)**とします。`purpose` は行末のコメントで、arguments ブロックに既定値があれば ` Default: <式>.` を足します。
- `DrawerOptionDialog` は `purpose` の末尾の `Default: (.*)\.$` を評価して初期値にします(呼び出しの対象 `obj` の上でも評価できる)。評価できなければ欄は空で、文はプレースホルダーになります。

## 2. クラス

### 2.1 置き場所と継承 [決定 Q1、継承は提案]

```
_GUILDAsystem/_auxiliary/@EventBase/EventBase.m
_GUILDAsystem/_auxiliary/@EventFault/EventFault.m       (edit.m など、メソッドのファイルは @クラスに)
_GUILDAsystem/_auxiliary/@EventTrip/EventTrip.m
_GUILDAsystem/_auxiliary/@EventOpenBranch/EventOpenBranch.m
_GUILDAsystem/_auxiliary/@EventOffset/EventOffset.m
_GUILDAsystem/_auxiliary/@EventInput/EventInput.m
_GUILDAsystem/_auxiliary/@EventInput/private/normalize_input.m   (Scenario/private から移す)
```

- `classdef (Abstract) EventBase < auxiliary & matlab.mixin.Copyable`。`auxiliary` は解析を助けるクラスの基底(`handle`)、`matlab.mixin.Copyable` は複製の `copy` を与えます(どちらも `handle` なので両立します)。サブクラスは `Sealed` です。
- イベントは `LayerPackage` ではありません(系統のタグの名前空間を使わず、`Scenario.children` は空のまま)。
- メソッドの置き方は「Method files rule」に従います: classdef にはプロパティ、コンストラクター、アクセサー、署名を置き、`edit` などは `@クラス` のファイルにします。すべての関数に `arguments (Input)`/`(Output)` ブロックを書きます。

### 2.2 EventBase

**プロパティ**

```matlab
properties (SetAccess={?Scenario, ?EventBase}) % Identity
    s_tag (1,1) string = ""     % Tag in the scenario (Fault<n>, Parallel<n>, or the tag of an offset or input); "" until the event is added. <@Type> string
end
properties (SetAccess={?Scenario}) % Layer structure
    a_Scenario                  % Scenario that holds the event ([] for an event not in a scenario). <@Type> Scenario
end
properties (Abstract, Constant, Hidden) % Kind
    s_prefix                    % Prefix of the automatic tag: "Fault", "Parallel", "offset" or "input".
    s_table                     % Table the event contributes to: "event", "offset" or "input".
end
```

- `s_tag` と `a_Scenario` はシナリオが付けます。`?EventBase` はサブクラスを含むので、`EventOffset`/`EventInput` のコンストラクターと `edit` は `Tag` から `s_tag` を設定できます。
- `a_Scenario` は親への読み取り専用の参照です(class-design の「親の参照」と同じ名前の付け方)。`remove_event` で外したイベントと `copy` で作ったイベントは `[]` です。

**メソッド**(新しいメンバーはこれだけです)

| メソッド | アクセス | 内容 |
|---|---|---|
| `edit(obj, opt)` | public、Abstract | 各サブクラスが arguments ブロックとともに実装(§2.5) |
| `copy(obj)` | public(`matlab.mixin.Copyable`) | 複製。`s_tag` は保ち、`a_Scenario` は `[]` |
| `cp = copyElement(obj)` | protected(Copyable の上書き) | 複製の `a_Scenario` を `[]` にする |
| `tab = table_rows(obj)` | `Access={?Scenario}`、Abstract | `s_table` の表の列(§1.1 の順と型)で、このイベントの行 |
| `apply_edit(obj, sct)` | protected | `edit` の共通処理: 値を入れ、シナリオで検査し、失敗なら元に戻す(§2.5) |

- 系統に対する検査はイベントに置きません。シナリオが今の `private/validate_events` と `private/validate_disturbance` を、イベントから組み立てた表に実行します(§4)。検査の規則は 1 か所のままです [提案]。
- JSON の読み書きもイベントに置きません。書き出しは今の `to_json_struct` が表を読み、読み込みは `add_from_json_struct` が公開のコンストラクターでイベントを作ります(§3.3)。

### 2.3 サブクラスのプロパティとコンストラクター [決定 Q1, Q5、名前は提案]

プロパティはすべて `SetAccess=private` です(`edit` だけが変える)。コンストラクターの引数は対応する `add_*` と同じです(位置引数、Name-Value、既定値)。

**EventFault**(`s_prefix = "Fault"`, `s_table = "event"`)

```matlab
properties (SetAccess=private)
    sv_target (:,1) string      % Tags of the faulted buses, or of the faulted branches (repeated ones once).
    rr_time (1,2) double        % [s] [t_start, t_end] of the fault.
    s_status (1,1) string       % "BG" (buses), "3LG" or "6LG" (branches).
    r_point (1,1) double        % Fault position along a branch, 0 < r_point < 1 (NaN for buses).
end
```

`ev = EventFault(target, time, Status="BG", Point=NaN)`

**EventTrip**(`"Parallel"`, `"event"`)

```matlab
    sv_unit (:,1) string        % Tags of the tripped components, global controllers or local controllers.
    rr_time (1,2) double        % [s] [t_start, t_end] of the trip.
```

`ev = EventTrip(unit, time)`

**EventOpenBranch**(`"Parallel"`, `"event"`)

```matlab
    sv_branch (:,1) string      % Tags of the opened branches.
    rr_time (1,2) double        % [s] [t_start, t_end] of the opening.
    s_status (1,1) string       % "6open" (all circuits) or "3open" (one circuit).
```

`ev = EventOpenBranch(branch, time, Status="6open")`

**EventOffset**(`"offset"`, `"offset"`)

```matlab
    s_unit (1,1) string         % Tag of the component whose states are offset.
    sv_state (:,1) string       % Names of the states (e.g. "delta").
    rv_value (:,1) double       % Offsets, one per state or one for all.
    r_time (1,1) double         % [s] Time of the offset.
```

`ev = EventOffset(unit, state, value, time=0, Tag="")`

**EventInput**(`"input"`, `"input"`)

```matlab
    s_unit (1,1) string         % Tag of the component.
    sv_name (:,1) string        % Names of the inputs (e.g. "Pmech").
    rm_value double             % Constants (a column: one per input or one for all), or a time series [t, v_1, ..., v_n].
    rr_time (1,2) double        % [s] [t_start, t_end] of the input.
    s_method (1,1) string       % Interpolation of a time series: "zoh", "foh" or "spline"; "" for constants.
end
```

`ev = EventInput(unit, name, value, time, Method=, Tag="")`。`value` は今の `add_input` と同じく定数、行列 `[t, v_1, ..., v_n]`、表(`Time` と入力名)を受け付け、コンストラクターと `edit` が `normalize_input` で保存の形(定数の列か時系列の行列と `s_method`)にします。

- `EventFault`, `EventTrip`, `EventOpenBranch` には `Tag` がありません(シナリオが付ける、§2.6)。
- **コンストラクターの検査**は arguments ブロック(型、大きさ、`mustBeMember`)と、`EventInput` の `normalize_input`(`InvalidInputSeries`, `MethodWithoutSeries`)だけです。系統を使う検査と、系統なしでもできる残りの検査(`t_start < t_end`, `Point` の範囲、値の数、時系列の値)は**シナリオに追加した時点**で行います(§4)。`EventFault("B008", [2 1])` はコンストラクターでは通り、追加でエラーになります [提案: 検査の規則を 1 か所に保つため]。
- イベントがシナリオにないときのメッセージの `{0}`(タグ)と `{1}`(シナリオ)は、タグが空ならクラス名(`EventInput`)、シナリオは `(none)` にします [提案]。

### 2.4 表への行 [決定「表」、制約 0.3-1]

`table_rows` が返す行は、今の `add_*` が足す行と**列、型、値、順が同じ**です。

| クラス | 表 | 行 |
|---|---|---|
| `EventFault` | `tab_event` | 対象ごとに `(s_tag, 対象, t_start, s_status, r_point)` と `(s_tag, 対象, t_end, "none", r_point)`。母線の `Point` は NaN |
| `EventTrip` | `tab_event` | 対象ごとに `(…, t_start, "open", NaN)` と `(…, t_end, "close", NaN)` |
| `EventOpenBranch` | `tab_event` | 対象ごとに `(…, t_start, s_status, NaN)` と `(…, t_end, "close", NaN)` |
| `EventOffset` | `tab_offset` | `(s_tag, r_time, s_unit, {sv_state}, {rv_value})` の 1 行 |
| `EventInput` | `tab_input` | `(s_tag, rr_time, s_unit, {sv_name}, {rm_value}, s_method)` の 1 行 |

- `Scenario` の `get.tab_event` などは、`a_Event` の順に `s_table` の合うイベントの `table_rows` を縦につなぎます。イベントがなければ `empty_disturbances` の空の表(今と同じ型)を返します。
- 行の順は「追加した順」のままです(`a_Event` の順)。`compile` の `output.phases` の列の順(`tab_event` のタグ、`tab_offset`、`tab_input`)も変わりません。
- **列名と列の順を保つことをテストで確かめます**(§7)。

### 2.5 edit [決定 Q3、詳細は提案]

```matlab
ev.edit(Time=[1, 1.2])
ev.edit(Target="EL003", Status="3LG", Point=0.3)
```

| クラス | `edit` のオプション(すべて任意) |
|---|---|
| `EventFault` | `Target`, `Time`, `Status`, `Point` |
| `EventTrip` | `Unit`, `Time` |
| `EventOpenBranch` | `Branch`, `Time`, `Status` |
| `EventOffset` | `Unit`, `State`, `Value`, `Time`, `Tag` |
| `EventInput` | `Unit`, `Name`, `Value`, `Time`, `Method`, `Tag` |

- オプションの名前は `add_*` の位置引数を UpperCamelCase にしたものと、`add_*` の Name-Value です。型と検査は `add_*` の arguments ブロックと同じです。**与えなかったオプションは今の値のまま**です(arguments ブロックに既定値を置かず、`isfield` で判断)。
- `Tag` は `EventOffset` と `EventInput` だけです(`add_offset`/`add_input` の `Tag`)。`Fault`/`Parallel` のタグは変えられません。
- `EventInput`: `Value` を与えて `Method` を与えないときは、`Method` を自動(時系列なら `"foh"`、定数なら `""`)に戻します。`Method` だけを与えたときは今の値に使います(定数なら `MethodWithoutSeries`)。`Name` だけを変えたときの値の数は検査で確かめます。
- **流れ**(`apply_edit`): (1) 変える項目の今の値を保存し、(2) 新しい値を入れ(`EventInput` は `normalize_input` の後)、(3) `a_Scenario` があれば `a_Scenario.validate()`(§4、すべてのイベントとタグ)を実行し、(4) エラーなら保存した値に戻して同じエラーを投げます。シナリオにないイベントは (3) を飛ばします。
- `edit` は何も返しません(ハンドル)。表は Dependent なので、`edit` の後すぐ `sc.tab_event` に反映されます。
- `a_Scenario` の `log_edit` は呼びません(シナリオはモデルのデータではなく、何も stale にしない。今と同じ)。

### 2.6 タグ [決定「タグ」、事実は §1.1]

| 種類 | 付け方 |
|---|---|
| `EventFault` | シナリオに入るとき `Fault%03d`(使われている最大の番号 + 1) |
| `EventTrip`, `EventOpenBranch` | 同じく `Parallel%03d`(2 つで番号を共有) |
| `EventOffset`, `EventInput` | `Tag` を与えればそれ。空なら `offset<n>`/`input<n>`(その接頭辞の最大の番号 + 1、ゼロ埋めなし) |

- タグはシナリオのすべてのイベントで一意です(`DuplicateTag`)。オフセットと入力のタグの予約語は今と同じです(`ReservedTag`)。
- **タグを保つ追加**は `From=` の複製と JSON の読み込みだけです(今と同じく `output.phases` の列名を保つ)。`add_*` と `Event=` で足すイベントの `Fault`/`Parallel` のタグは新しく付け直します(複製元のタグは使わない)。オフセットと入力は `s_tag`(与えた `Tag`)を保ちます。

### 2.7 複製 [決定 Q5、方法は提案]

- `copy(ev)` は値をすべて写し、`a_Scenario` を `[]` にします(`copyElement`)。`s_tag` は保ちます。
- `add_scenario(Event=)` と `From=` はイベントを `copy` してから足します。渡したイベントと `From` のシナリオは変わりません。

### 2.8 既定の文(GUI と補完) [決定「既定の文」、文は提案]

`update_keymap` は arguments ブロックに既定値がある引数に ` Default: <式>.` を足します。既定値のない引数はコメントの末尾に自分で `Default: <式>.` を書きます(二重にしない)。

| メソッド | 引数 | arguments ブロック | `purpose` の末尾 |
|---|---|---|---|
| `Scenario.add_fault`, `EventFault` | `Status` | **既定値 `"BG"` を置く**(今の本体の動作と同じ) | `Default: "BG".` |
| 〃 | `Point` | **既定値 `NaN` を置く**(同上) | `Default: NaN.` |
| `Scenario.add_open_branch`, `EventOpenBranch` | `Status` | `"6open"`(今のまま) | `Default: "6open".` |
| `Scenario.add_offset`, `EventOffset` | `time` | `0`(今のまま) | `Default: 0.` |
| 〃 | `Tag` | `""`(今のまま) | `Default: "".` |
| `Scenario.add_input`, `EventInput` | `Method` | 既定値なし(定数に与えるとエラーのため) | コメントに `Default: "foh".`(今のまま) |
| 〃 | `Tag` | `""` | `Default: "".` |
| `PowerNetwork.add_scenario` | `From` | **既定値 `Scenario.empty` を置く** | `Default: Scenario.empty.` |
| 〃 | `Event` | 既定値 `{}` | `Default: {}.` |
| 〃 | `Time`, `Description` | 今のまま(本体で `From` から) | 今のまま(`Default: From.Time, else [0, 10].` は評価できずプレースホルダー) |
| `*.edit` | すべて | 既定値なし | コメントに **`Default: obj.<プロパティ>.`**(例: `EventFault.edit` の `Target` は `Default: obj.sv_target.`、`Time` は `Default: obj.rr_time.`、`EventInput.edit` の `Value` は `Default: obj.rm_value.`、`Tag` は `Default: obj.s_tag.`) |

- `Status` と `Point` に既定値を置いても動作は変わりません: 今も本体で `"BG"`/`NaN` にしており、ブランチに `Status` を与えなければ `InvalidFaultStatus` です。コメントは `"BG" for buses; "3LG" or "6LG" for branches (required there).` のように「ブランチでは必須」を残します。
- `Scenario.empty` は制限されたコンストラクターでも作れます [事実: R2026a で 0×0 の Scenario]。本体は `isfield(opt, "From") && ~isempty(opt.From)` を `~isempty(opt.From)` にします。
- `edit` の `Default: obj.<プロパティ>.` は `DrawerOptionDialog` が呼び出しの対象の上で評価し、今の値を初期値にします。変えなかった項目は書かれません(既定と比べるため)。将来 GUI がイベントの編集のフォームを `DrawerOptionDialog("EventFault.edit", Object="net.a_Scenario{1}.a_Event{2}", History=...)` で作れます [未確認: 動かしていない。`s_method = ""` の定数の入力で選択肢の欄がどう出るか]。

## 3. Scenario と PowerNetwork の変更

### 3.1 Scenario のメンバー [決定 Q2, Q4, Q6, 表、細部は提案]

| 区分 | メンバー |
|---|---|
| **削除** | `add_disturbance`, `remove_disturbance`(改名), `add_events`, `add_record`, `sr_field`(Constant, Hidden), `private/new_event_rows.m`(番号の付け方は `insert_event` に), `private/validateTimeSpanSize.m`(`add_disturbance` だけが使う), `private/normalize_input.m`(`@EventInput/private` に移す) |
| **改名** | `remove_disturbance(tag)` → **`remove_event(tag)`** |
| **新規** | `a_Event (:,1) cell`(`SetAccess=private`、イベントを追加した順) |
| 〃 | `insert_event(obj, ev, l_keepTag)`(`Access={?PowerNetwork, ?Scenario}`): タグを付け(§2.6)、`ev.a_Scenario` を設定して `a_Event` の末尾に足し、`validate()` を実行し、失敗なら外して(`a_Scenario = []`)同じエラーを投げる。`add_*`, `add_scenario`, `add_from_json_struct` が使う |
| **変更** | `tab_event`, `tab_offset`, `tab_input`: **`properties (Dependent, SetAccess=private)`** と `get.*`(§2.4) |
| 〃 | `add_fault`, `add_trip`, `add_open_branch`, `add_offset`, `add_input`: 引数は今のまま(`add_fault` の `Status`/`Point` に既定値、§2.8)。本体はイベントを作り `insert_event(ev, false)` して **`ev` を返す**(出力 `ev EventFault` など、コメント `The added event (a handle: edit it with ev.edit).`) |
| 〃 | `validate`: 今の検査に**タグの検査**を足す(すべてのイベントの `s_tag` が一意 = `DuplicateTag`、オフセットと入力のタグが予約語でない = `ReservedTag`)。アクセスに `?EventBase` を足す(`apply_edit` が呼ぶ) |
| 〃 | `add_from_json_struct`: イベントをコンストラクターで作る(§3.3) |
| 〃 | ヘルプ: `Scenario.m`(`a_Event`, イベントのクラス, `edit`, 例の `ev = sc.add_fault(...)`)、`remove_event.m`、各 `add_*`(返り値、`remove_event`) |
| **変えない** | `compile`, `to_json_struct`, `gui_content`(コードは変えない。ヘルプの「disturbance」は手順 S2 で見直す), `log_edit`, `private/blank_record`, `get_record`, `empty_disturbances`, `validate_events`, `validate_disturbance`, `checkValueCount` |

- `remove_event(tag)`: `tag (:,1) string`。そのタグのイベントを `a_Event` から外し、`a_Scenario` を `[]` にします。ないタグは今と同じ **`GUILDA:Scenario:DisturbanceNotFound`**(ID は再利用。本文の "disturbance" を "event" に直す)。
- `Scenario` は `children` を空のままにします(イベントは `LayerPackage` でない)。

### 3.2 PowerNetwork.add_scenario [決定 Q5]

```matlab
sc = net.add_scenario("case1", Event={EventFault("B008", [0.1, 0.17]), EventOpenBranch("EL003", [0.17, 20])});
```

- 新しい Name-Value **`opt.Event (1,:) cell = {}`**(コメント `Events to copy into the new scenario (EventFault, EventTrip, EventOpenBranch, EventOffset, EventInput), added after those of From.`)。要素が `EventBase` のスカラーでなければ新しい ID **`GUILDA:PowerNetwork:NotAnEvent`**(`PowerNetwork.xml` に追加)。
- `opt.From Scenario {mustBeScalarOrEmpty} = Scenario.empty`(§2.8)。
- 順: シナリオを作る → `From` の `Time`, `Description` → `From.a_Event` の各イベントを `insert_event(copy(ev), true)`(**タグを保つ**) → `Event` の各イベントを `insert_event(copy(ev), false)` → `Time`, `Description` のオプション。どこかで失敗すれば今と同じくシナリオを消します。
- `From` の表を行に分けて `add_record` に渡す今のコード(約 25 行)は消えます。

### 3.3 JSON の読み込み [決定「表」(version 2 のまま)、規則は提案]

書き出し(`to_json_struct`, `write_scenarios`)は変えません。読み込みは `read_scenarios` の検査の後、`add_from_json_struct` がタグごとにイベントを作り、`insert_event(ev, true)` で足します(タグを保つ)。

| JSON | イベント |
|---|---|
| `Event` の `Fault<n>` の行 | `EventFault(対象, [t_start, t_end], Status=, Point=)` |
| `Event` の `Parallel<n>` で開始の `Status` が `open` | `EventTrip(対象, [t_start, t_end])` |
| 同じく `3open`/`6open` | `EventOpenBranch(対象, [t_start, t_end], Status=)` |
| `Offset` の行 | `EventOffset(OffsetUnit, OffsetState, OffsetValue, TimeSpan(1), Tag=)` |
| `Input` の行 | `EventInput(InputUnit, InputName, InputValue, TimeSpan, Method=InputMethod(あれば), Tag=)` |

- 1 つの `Event` のタグの行は、対象ごとに開始と終了の 2 行で、**すべての対象が同じ `[t_start, t_end]`、開始の `Status`、`Point`** を持ち、終了の `Status` が `none`/`close` でなければなりません。外れれば **`GUILDA:Scenario:InvalidEventRows`**(今の ID)。
- `Offset` と `Input` の行は 1 行が 1 つのイベントです。ない項目は空の値(`""`, 空の配列)でコンストラクターに渡し、追加の検査(`UnknownOffsetUnit` など)がそのまま拒否します。`Offset` と `Input` に同じタグがあれば `DuplicateTag` です。**古いファイルのための規則や案内の文は置きません** [決定 §8-1]。
- `read_scenarios` の「同じタグのオフセットと入力の開始時刻が違う」検査は、同じタグが `DuplicateTag` になるので**削除**します。既知の項目は `Scenario.sr_field` の代わりに局所の定数 `["Tag", "TimeSpan", "OffsetUnit", "OffsetState", "OffsetValue", "InputUnit", "InputName", "InputValue", "InputMethod"]` にします。他の検査は今のままです。

### 3.4 GUI(`@DrawerModelGUI/render.m` と `@Scenario/gui_content.m`) [制約 0.3-2、提案]

- **`render.m`:** `sm_add` から `"Disturbance", "Scenario.add_disturbance"` の行を消します(ボタンは `+ Fault`, `+ Trip`, `+ Open branch`, `+ Offset`, `+ Input` の 5 つ)。表の行のコンテキストメニューを `Remove event` にし、局所関数 `remove_disturbance` を `remove_event` に改名して `<シナリオ>.remove_event("<タグ>");` を実行します。確認の文も "event" にします。表の `Tag` プロパティ `"disturbance"` は `"event"` にします。
- **`add_*` がオブジェクトを返すこと:** ボタンが書くコードは `net.a_Scenario{1}.add_fault("B004", [1 1.05]);` のまま(出力の変数なし、末尾にセミコロン)で、返り値は表示されません [事実: `DrawerOptionDialog.get_code` はセミコロンで終わる。F51 の期待値]。出力の変数を付ける変更はしません。
- **`gui_content.m`:** 3 つの表を読むだけなので**コードは変えません**。表は Dependent でも列が同じなので、ページは今と同じです。ヘルプの「disturbance」を「event」に揃えるだけです。`DrawerModelGUI.m` のヘルプ(14 行、`add_fault, add_trip, ...` と `Remove disturbance`)も直します。
- `feature/guilda-app-sim-tab` は `add_*` の返り値を使わず、3 つの表の列だけを読むので、この変更の影響を受けません [事実: 差分を grep]。

### 3.5 タブ補完(`update_keymap`) [決定「補完」、提案]

`sig_methods` の項目を次のようにします。

| 項目 | タグの選択肢 |
|---|---|
| `Scenario.add_fault`, `add_trip`, `add_open_branch`, `add_offset`, `add_input` | 今のまま |
| `Scenario.add_disturbance`, `Scenario.remove_disturbance` | **削除** |
| `Scenario.remove_event` | `tag`: 今の `s_dist`(3 つの表のタグ。Dependent でも同じ式で評価できる) |
| `PowerNetwork.add_scenario` | 今のまま(新しい `Event`, `From` の既定の文が入る) |
| `EventFault`(コンストラクター) など 5 つ | なし(系統がない) |
| `EventFault.edit` | `Target`: `[string(obj.a_Scenario.a_PowerNetwork.a_Bus); string(obj.a_Scenario.a_PowerNetwork.a_Branch)]` |
| `EventTrip.edit` | `Unit`: 今の `s_unit` の `obj.a_PowerNetwork` を `obj.a_Scenario.a_PowerNetwork` に |
| `EventOpenBranch.edit` | `Branch`: `string(obj.a_Scenario.a_PowerNetwork.a_Branch)` |
| `EventOffset.edit`, `EventInput.edit` | `Unit`: 今の `s_comp` の `obj.a_PowerNetwork` を `obj.a_Scenario.a_PowerNetwork` に |

- **`method_entry` のコンストラクターの扱いを直します。** 今は鍵が `<クラス>.<メソッド>` で 1 番目の入力を `obj` にするので、コンストラクターでは鍵を **`EventFault`**(クラス名だけ)にし、1 番目の入力を普通の引数として扱います [未確認: MATLAB R2026a がクラス名の鍵でコンストラクターを補完すること。`_auxiliary/resources` の効き方は `fix/aux-signatures` の後に確かめる]。
- シナリオにないイベントの `edit` では選択肢の式が評価できず(`a_Scenario` が空)、型 `string` だけが残ります(今の `add_*` の空の系統と同じ扱い)。
- 生成した 2 つのファイル `_GUILDAsystem/resources/functionSignatures.json` と `_GUILDAsystem/_auxiliary/resources/functionSignatures.json` をコミットします(制約 0.3-3)。`Event*` は `_auxiliary` のクラスなので、両方のファイルに入ります。

## 4. 検査

### 4.1 いつ実行するか [決定 Q3, Q5、提案]

| 時点 | 内容 |
|---|---|
| コンストラクター | arguments ブロック、`EventInput` の `normalize_input`(§2.3) |
| 追加(`add_*`, `Event=`, `From=`, JSON) | `insert_event` がタグを付けて足し、**`validate()` ですべてを検査**。失敗なら外す |
| `edit` | 値を入れて **`validate()` ですべてを検査**。失敗なら元に戻す(シナリオにないイベントはコンストラクターと同じ検査だけ) |
| `simulate` | 今と同じ(`compile` の最初の `validate()`、その時の系統に対して) |
| `remove_event` | 検査なし |

- 今の `add_record` は新しい記録だけを検査しましたが、すべてを検査する 1 つの流れにします(イベントの数は少なく、規則が 1 か所になる)[提案]。
- `validate()` の中身: (1) タグ(`DuplicateTag`, `ReservedTag`)、(2) `validate_events(tab_event, ...)`(今のまま。対象、行の形、`Status`/`Point`、`SingleCircuit`、`t_start < t_end`、重なり)、(3) `tab_offset` と `tab_input` の各行に `validate_disturbance(get_record(...), ...)`(今のまま)。

### 4.2 エラー ID [事実: `Scenario.xml`、`PowerNetwork.xml`。新規は提案]

すべて今の ID を使います。

| ID | 出る時点 | 変更 |
|---|---|---|
| `GUILDA:Scenario:UnknownFaultTarget`, `MixedFaultTarget`, `InvalidFaultStatus`, `InvalidPoint`, `UnknownParallelTarget`, `InvalidEventRows`, `OverlappingEvents`, `SingleCircuit`, `InvalidTimeSpan`, `ZeroLengthTimeSpan` | 追加、`edit`、`simulate` | なし(`InvalidEventRows` は JSON の 1 つのイベントで表せない行にも使う) |
| `UnknownOffsetUnit`, `UnknownOffsetState`, `UnknownInputUnit`, `UnknownInputName`, `ValueCountMismatch` | 追加、`edit`、`simulate` | なし |
| `InvalidInputSeries`, `MethodWithoutSeries` | `EventInput` のコンストラクター、`edit` | 出す場所が `@EventInput/private/normalize_input` に移る |
| `DuplicateTag`, `ReservedTag` | 追加、`edit(Tag=)` | なし |
| `DisturbanceNotFound` | `remove_event` | 本文の "disturbance" を "event" に |
| `OutsideTimeSpan`(警告) | `compile` | なし |
| `GUILDA:PowerNetwork:ScenarioJson` | `import` | 規則を §3.3 のとおり変える |
| **`GUILDA:PowerNetwork:NotAnEvent`**(新規) | `add_scenario(Event=)` | 新規 |

## 5. 影響する箇所 [事実: grep、基準 `baf9ee56`]

### 5.1 コード

| ファイル | 内容 | 手順 |
|---|---|---|
| `@Scenario/Scenario.m`, `add_fault.m`, `add_trip.m`, `add_open_branch.m`, `add_offset.m`, `add_input.m`, `add_from_json_struct.m`, `validate.m`, `remove_disturbance.m` → `remove_event.m` | §3.1 | S2 |
| `@Scenario/add_disturbance.m`, `add_events.m`, `add_record.m`, `private/new_event_rows.m`, `private/validateTimeSpanSize.m` | 削除 | S2 |
| `@Scenario/private/normalize_input.m` | `@EventInput/private/` に移す | S2 |
| `@Scenario/gui_content.m` | ヘルプだけ | S2 |
| 新規 `@EventBase`, `@EventFault`, `@EventTrip`, `@EventOpenBranch`, `@EventOffset`, `@EventInput` | §2 | S2 |
| `@PowerNetwork/add_scenario.m` | §3.2 | S2 |
| `@PowerNetwork/private/read_scenarios.m` | `sr_field` の局所化、§3.3 の規則 | S2 |
| `@DrawerModelGUI/render.m`(`add_disturbance` 1 か所、`remove_disturbance` 3 か所), `DrawerModelGUI.m`(ヘルプ) | §3.4 | S2 |
| `@GUILDA/update_keymap.m` | §3.5 | S2 |
| `_GUILDAsystem/resources/functionSignatures.json`, `_GUILDAsystem/_auxiliary/resources/functionSignatures.json` | 再生成 | S2 |
| `SystemTools/GUILDA/en/Scenario.xml`(`DisturbanceNotFound`), `PowerNetwork.xml`(`NotAnEvent`) | §4.2 | S2 |
| `@SolverODE/phase_result.m`, `solve.m`(ヘルプ), `@ResultODE/ResultODE.m`(ヘルプ), `@PowerNetwork/private/simulateFcn_struct_result.m`(ヘルプ) | §7 | S3 |

`compile.m`, `to_json_struct.m`, `write_scenarios.m`, `export.m`, `build_simulation_data.m`, `simulate.m`, `_GUILDAobject` のヘルプの `add_fault` などの例(14 ファイル、返り値を使わない)、`_GUILDAverification` の 4 つの比較のスクリプト(返り値を使わない)は変えません。

### 5.2 テストと補助関数(`+DebugScript/`)

| ファイル | 使っている API(行数) | 変更 | 手順 |
|---|---|---|---|
| `+helper/scenario.m` | `add_disturbance`(3) | `Offset*` を `add_offset(..., Tag=tag)`、`Input*` を `add_input(..., Tag=tag)` に。`TimeSpan` だけなら外乱を足さない(目印をやめる)。呼び出し側(25 ファイル 155 か所)の Name-Value はそのまま使える | S1 |
| `+helper/combine.m` | `add_disturbance`(2) | オフセットと入力を `add_offset`/`add_input` で足す | S1 |
| `+helper/noop_event.m` | `helper.scenario` の目印 | 外乱のない空のシナリオ(`Time` = 区間)。呼び出し側(8 ファイル 34 か所) | S1 |
| `test_F6_simulation.m` | 目印(723 行)、ヘルプの `add_disturbance`(4 行) | 目印の列 `none` を期待するなら `NoAction1` に | S1 |
| `test_I53_scalar_timespan.m` | `sc.add_disturbance`(44 行)、目印(55 行) | `add_input(..., [1 1])` で `ZeroLengthTimeSpan`。目印は区間の境界の期待を直す | S1 |
| `test_I52_validate_events.m`, `test_I60_event_network.m` | `helper.scenario` の目印・予約語 | 必要なら期待値を直す [未確認: S1 で実行して決める] | S1 |
| `test_F31_scenario.m` | `add_disturbance`(8), `remove_disturbance`(7), 返り値のタグ(6) | `add_offset`/`add_input` に、`remove_event` に、返り値は `ev.s_tag` | S2 |
| `test_F16_csv_io.m` | `remove_disturbance`(2)、JSON の往復 | `remove_event` | S2 |
| `test_F34_signatures.m` | `add_disturbance`, `remove_disturbance`, `add_events`, `add_record` | 期待する項目(`remove_event`, `Event*.edit`, コンストラクター)、ないこと(`insert_event`, `table_rows`) | S2 |
| `test_F51_model_gui_actions.m` | ボタンの一覧(136 行), `remove_disturbance`(4) | 5 つのボタン、`Remove event`、`remove_event` | S2 |
| `test_F32_model_gui.m` | シナリオの GUI のページ | 変わらないことを確かめる | S2 |
| 新規 `test_F58_scenario_events.m`(番号は実装の時点で空いているものに) | §7.1 | 新規 | S2 |
| `test_F39_simulation_data.m`, `test_F42_branch_events.m`, `test_F45_ode_component_current.m` | 解列中の入力 | `ResultODE` の入力も NaN | S3 |

### 5.3 文書

| ファイル | 箇所 | 手順 |
|---|---|---|
| `_GUILDAdoc/developer/feature-simulation.html` | `add_disturbance`(4), `remove_disturbance`(2), `add_events`/`add_record`(2), `sr_field`(2), 表の説明(10)、解列中の入力 | S4 |
| `_GUILDAdoc/developer/feature-data-io.html` | `add_disturbance`(3), `sr_field`(2)、JSON の読み込みの規則 | S4 |
| `_GUILDAdoc/developer/feature-gui.html` | ボタンの表(284 行)、`Remove disturbance`(291, 298 行) | S4 |
| `_GUILDAdoc/developer/class-design.html` | 補助クラスの一覧に `EventBase` と 5 つ、`a_Scenario` の親の参照 | S4 |
| `_GUILDAdoc/database/list_UpdateLog.js` | 1 件を追加(過去の項目は変えない) | S4 |
| `notes/status.md` | 状態 | S4 |
| クラスのページ(`class.html`) | 自動生成。`@Event*/image.svg` は任意 | なし |

`_GUILDAtutorial` と `_GUILDAdoc/index.html` は `add_disturbance`/`remove_disturbance` を使わず、`add_fault` などの返り値も使いません。過去の notes(`branch-status-events.md`, `simulate-redesign.md` など)は記録なので変えません。

## 6. 実装の手順 [提案]

各コミットで `DebugScript.run_all('Level','small','FailOnUnexpected',true)`、統合の前に medium を 1 回実行します(large はサブセッションでは実行しない)。

| 手順 | 内容 | 持つファイル | テスト | 依存 |
|---|---|---|---|---|
| **S1** 補助関数を今の API に | `add_disturbance` を使う補助関数とテストを `add_offset`/`add_input` に移す(今の API にある)。目印の外乱をやめる | `+helper/scenario.m`, `combine.m`, `noop_event.m`, `test_F6`, `test_I53`(と必要なら `I52`, `I60`) | small、F6, I52, I53, I60 と `noop_event` を使う 8 ファイル | なし |
| **S2** イベントのクラス | §2, §3, §4: `Event*`, Scenario, `add_scenario`, `read_scenarios`, `render.m`, `gui_content.m`(ヘルプ), `DrawerModelGUI.m`(ヘルプ), `update_keymap`, xml。**`GUILDA.update_keymap(Signature=true)` を実行し、2 つの JSON をコミット** | §5.1 の S2 の行、§5.2 の S2 の行 | 新規 F58、F31, F16, F34, F32, F51、medium | S1、`fix/aux-signatures` の統合 |
| **S3** 解列中の入力 | §7(両方 NaN) | `@SolverODE/phase_result.m`, `solve.m`, `@ResultODE/ResultODE.m`, `simulateFcn_struct_result.m`, F39, F42, F45 | F39, F42, F45、`simulate_baseline(Mode="compare")` で差が解列中の u, uc だけであることを確かめる(§7.4) | なし |
| **S4** 文書 | §5.3 | §5.3 のファイル | `GUILDA.doc(open=false, update="always")` の警告(既知の 3 件だけ) | S2, S3 |
| **基準の再生成** | S3 の統合の後、`baseline_s0.mat` を退避してから `simulate_baseline(Mode="record")` で作り直す | **コーディネーターが行う**(サブセッションではない) | `simulate_baseline(Mode="compare")` がすべて `isequaln` | S3 |
| **S5** 知らせる | GUI のコーディネーターに、S2(と S3)が統合されたこと、`add_*` の返り値、`remove_event`、ボタンの変更、表の列が同じことを知らせる | なし(コーディネーターが行う) | なし | S2, S3, S4 |

- **並行:** S1 と S3、S2 と S3 は並行できます(同じファイルを持たない)。S2 は S1 の統合の後に始めます(S1 の前に `add_disturbance` を消すと補助関数が壊れる)。S4 は S2 と S3 の後です。
- 署名を変えるのは S2 だけです。S1 と S3 は arguments ブロックを変えないので、`functionSignatures.json` を再生成しません。
- S2 の新しいメンバーは §2.2、§2.3、§3.1、§3.2 の表にあるものだけです。他を足したら統合の前のレビューで指摘します。

### 6.1 実装の状況(2026-11-17)

| 手順 | 状態 |
|---|---|
| S1 | `refactor/design-alignment` に統合済み(マージ `d2fb15c8`) |
| S2 | 統合済み(マージ `1d1fc68b`)。`fix/aux-signatures` は `acf3e216` で先に統合 |
| S3 | 統合済み(マージ `dc285b0a`) |
| 基準の再生成 | `dc285b0a` で作り直し済み(コーディネーター) |
| S4 | ブランチ `docs/scenario-events`(未統合、未 push)。§5.3 のページ、`folder-structure.html` の補助クラスの一覧、Update log の 2026-11-17 の項目(2026-11-16 の「Code suggestions for Scenario and the analysis results」は内容が重なるのでこれにまとめた)、`notes/status.md`。`GUILDA.doc(open=false, update="always")` の警告は既知の 3 件だけ |
| S5 | 未(コーディネーターが行う) |

## 7. 解列した機器の入力

### 7.1 今の値 [事実: コードと MATLAB R2026a]

| 出力 | 解列中の入力 u(機器)、uc(LC)、GC の u | 状態 x |
|---|---|---|
| `simulate(..., Format="struct")` | **NaN** | NaN |
| `ResultODE.rm_variable`(と `odeResults.Bus(i).Component(j).U`) | **0** | NaN |
| `ResultODE.rm_output` | (出力は NaN) | |

**値の出どころ**

- **0:** `SolverODE.initial_condition` は解列した機器・LC・GC の `iv_x` と `iv_u` を区間の縮約から外し(`lv_FBorTC`)、拡大行列 `EM` を作ります。`solve.m` は区間の解を `EM * sol.Solution` で全体の長さに戻すので、外した要素は **0** になります。`phase_result.m` は解列したブロックの **`iv_x` だけ**を NaN にし、`iv_u` は 0 のまま `rm_variable` に入ります。
- **NaN:** `simulateFcn_struct_result.m` が、解列中の時刻の `u` を自分で NaN にします(機器は `Ub(lv_off, :) = NaN`、LC は局所関数 `local_controllers`、GC も同じ)。
- **確認(2026-11-17、R2026a):** IEEE14、`add_trip("B003LPQ2", [1, 2])`、`Time=[0, 3]`。t = 1.204 で `ResultODE` の `Pload`, `Qload` は `[0 0]`(平衡値は `[-0.942 -0.19]`)、`Format="struct"` は `NaN NaN`。IEEE68 の母線 1 の発電機の 1 つ目のローカル制御器(AVR、状態 `Vtr`, `Vap`, `Vst`)を `[1, 2]` で解列: `rm_variable` の `Vtr`, `Vap`, `Vst` は NaN、`Vref`, `Vpss`(uc)は 0。発電機の `Pmech`, `Vfield` は平衡値(解列した源の規則)。

### 7.2 案

| 案 | 内容 | 利点 | 欠点 |
|---|---|---|---|
| **A. 両方 NaN** | `phase_result` で `iv_x` と `iv_u` を NaN にする | 状態・出力・機器電流(`rm_Icomponent`)と揃い、「解列中は値がない」が 1 つの規則になる。0 という**偽の値**がなくなる(負荷の 0 は「入力が 0 に落ちた」と読めてしまう)。`Format="struct"` と同じになり、`simulateFcn_struct_result` の NaN の処理は不要になる | 和や平均に `omitnan` が要る(状態も同じ)。基準の `ieee14_trip` と `agc_trip` の `rm_variable` が変わる(解列中の u の行だけ)ので、基準を作り直す。`odeResults` の `U` も NaN になる |
| B. 両方 0 | `simulateFcn_struct_result` の NaN をやめる | `ResultODE` と基準は変わらない | 0 は意味のない値で、本当の 0 の入力と区別できない。状態と出力は NaN なので規則が 2 つになる。`Format="struct"` の値と、それを確かめるテスト(F39 128 行、F42 223 行)が変わる |

平衡値にする案も考えられますが、解列した機器には入力が加わっていないので、平衡値は誤解を招きます(解列した**源**の先の入力が平衡値をとる規則とも混ざる)。採りません。

### 7.3 決定

**案 A(両方 NaN)** です [決定 §8-2]。解列した機器の状態は既に NaN で、出力と機器電流も NaN です。入力だけが 0 なのは、`EM` の拡大の副作用で、意図した値ではありません。`get_point({sim, t})` は解列中の時刻では状態が NaN なので、入力が NaN になっても使い勝手は変わりません。

### 7.4 実装(手順 S3)

- `phase_result.m`: `iv = tools.vcellfun(@(b) [b.iv_x; b.iv_u], c_unit)`。ヘルプ「状態と入力は NaN」。
- `simulateFcn_struct_result.m`: u を NaN にする処理は要らなくなるので**削除**します(LC の `lm_off` の引数も整理)。機器電流 `I` の「解列中は 0」は変えません(`ResultODE.rm_Icomponent` は NaN で、これは別の不一致です。今回は扱わず、記録だけにします)。
- `solve.m`, `ResultODE.m` のヘルプ: 「解列した機器の状態と入力は NaN」。
- **基準:** `simulate_baseline.m` に例外の比較は**足しません**。S3 のサブセッションは `simulate_baseline(Mode="compare")` を実行し、`isequaln` でない例(`ieee14_trip`, `agc_trip` の見込み)で、違う要素が**解列中の区間の、解列したブロックの u と uc の行だけ**(基準が 0、新しい値が NaN)であることを確かめて記録します。統合の後、**コーディネーター**が `/Users/taku/GUILDA/simulate-baseline/baseline_s0.mat` を退避し、基準を作り直します(サブセッションは基準のファイルを書きません)。
- テスト: F39 か F42 に「`ResultODE.rm_variable` の解列中の u, uc が NaN、前後は有限」を足します。F45 は機器電流だけなので変わらない見込みです [未確認]。

## 8. 決定事項(2026-11-17)

利用者の回答は「基本推奨通り。ただし後方互換などは考えずシンプルに作る」です。

| # | 問い | 決定 |
|---|---|---|
| 1 | `add_disturbance` が書いた古い JSON(同じタグのオフセットと入力、単位のない目印の行) | **互換の処理を置かない。** 特別な規則も案内の文もなし。version 2 の読み込みと今の検査が拒否するものは、そのまま拒否する(§3.3) |
| 2 | 解列した機器の入力(§7) | **両方 NaN**(案 A)。基準の比較の例外は置かず、差を確かめた後にコーディネーターが基準を作り直す(§7.4) |
| 3 | `Scenario` に公開の `add_event(ev)` を置くか | **置かない** |
| 全体 | 後方互換と移行 | 古い呼び出し元のための別名、移行の処理、特例は置かない。メンバーは §2, §3 の最小のもの。目印の外乱(`TimeSpan` だけの外乱)はなくなり、補助関数とテストからも消す(S1) |

## 9. 確認していないこと

- MATLAB がクラス名の鍵(`"EventFault"`)でコンストラクターを補完すること、`_auxiliary/resources/functionSignatures.json` が `@Event*` に効くこと(§3.5)。
- `DrawerOptionDialog` が `Default: obj.<プロパティ>.` を `edit` のフォームで期待どおりに出すこと(特に `s_method = ""`)。
- `matlab.mixin.Copyable` と `auxiliary` の多重継承で、`copy` の挙動(`copyElement` の上書き)。
- S1 で目印の外乱をやめたとき、I52, I53, I60, F6 のどの期待値が変わるか(実行していません)。
- 案 A で `simulate_baseline` の差が解列中の u, uc の行だけに限られること(コードからの推定で、実行していません。S3 で確かめる)。
