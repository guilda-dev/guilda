# 発電機の制御器の枠(案 A、`refactor/generator-controller-slots`)

ブランチは `refactor/generator-controller-slots` です(未 push、分岐元 `refactor/design-alignment` の `9e4a5b19`)。2026-11-17 にユーザーが選んだ案 A の仕様と、潮流計算のコーディネーターとの取り決めをまとめます。

**ラベル**: [事実] = コードを読んで確認しました。[計測] = MATLAB R2026a で実行して確認しました。[合意] = 潮流計算のコーディネーターと決めた内容で、向こうが実装します。

## 1. 決定事項(ユーザー、2026-11-17)

- 制御器の置き場は `a_LocalController` の役割の枠だけです。退けた案は、別のリスト `a_SpecificController` と、`a_AVR` / `a_GOV` / `a_PSS` のプロパティです。LQR を発電機以外に付けられなくなり、PSS を AVR の子にする親子関係も崩れるためです。
- `set_avr` / `set_pss` / `set_governor` は残します(以前のユーザーの決定)。

## 2. 枠の仕様 [事実]

| 置き場 | 入るもの |
|---|---|
| 機器の `a_LocalController` | 役割 `"avr"` か `"local"` を 1 つ以下、その後に `"governor"` を 1 つ以下。この順に並びます |
| 制御器の `a_LocalController` | 役割 `"avr"` の制御器の下に、`"pss"` を 1 つだけ。ほかの制御器の下には何も入りません |

- 付ける順に関係なく、並びは「AVR か local → 調速機」です。2 つ目の AVR・PSS・調速機は、前のものを置き換えます(`GUILDA:Component:ReplaceController` の警告)。
- **検査の場所**: プロパティの set メソッドです。どの書き込み口から入っても検査されます。
  - `Component.m` の `set.a_LocalController` → `@Component/private/check_controller_slots.m`(`GUILDA:Component:ControllerSlots`)
  - `LocalController.m` の `set.a_LocalController` → `@LocalController/private/check_nested_slot.m`(`GUILDA:LocalController:NestedControllerSlot`)
  - 書き込み口は `Component.add_local_controller`、`remove_local_controller`、`move_local_controllers`(`Bus.replace_component` から)、`LocalController.add_local_controller` / `remove_local_controller` です。サブクラスからの直接の書き込みも同じ検査を通ります(テスト F64 のスタブで確認)。
- AVR の `set_PSS`(`AVR_ST1`、`AVR_DC1`、`controller.avr.abstract`)は削除しました。役割の確認、親(`a_Component`)、stale、ログをすべて飛ばしていたためです。PSS は `add_local_controller("pss-...")` か `gen.set_pss` で付けます。

## 3. 発電機の入口 [事実]

- `gen.avr` / `gen.pss` / `gen.governor` は、`a_LocalController` から役割で探して返す読み取り専用の Dependent プロパティです(無ければ `[]`)。`gen.avr` は役割 `"avr"` だけを返し、`"local"`(LQR など)は返しません。
- `gen.set_avr(Key, parameter=...)` などは、キーのクラスの `s_role` を確かめてから `add_local_controller` を呼ぶだけです。役割が違うキーは `GUILDA:Component:ControllerRoleMismatch` で止まり、機器は変わりません。戻り値は付けた制御器です。
- 以前の宣言 `set_avr(obj, con)`(制御器のオブジェクトを受け取る形)は、実装ファイルがなく動いていませんでした。新しい形はキーを受け取ります。`<@Deprecated>` の印は外しました。

## 4. 1 つの入力を 2 つの制御器が出すとき [事実]

検出を足しただけです。入力の組み立て方(入力 = 平衡点 + 制御器の出力など)、変数の並び、オフセットの扱いは変えていません。

制御器の出力は、名前で親の入力につながります。今までは、同じ入力を 2 つの制御器が出すと、変数マップでは前のほうが、`initialize` の残差の計算では後のほうが黙って使われていました。どちらもエラーにしました。

- `Component.get_variable_map` の connections: `GUILDA:Component:InputDrivenTwice`
- `PowerNetwork.initialize` の残差(`nested_outputs`): `GUILDA:PowerNetwork:InputDrivenTwice`

`add_local_controller` は最上位の 2 つの出力の重なりをすでに拒んでいます(`ControllerOutputOverlap`)。そのため、この状態は直接の書き込みでしか作れません。この検査は 2 段目の守りです。

## 5. 潮流計算のコーディネーターとの取り決め [合意]

向こうが、案 A のマージの後に実装します。こちらは、その邪魔をしない形にしてあります。(2026-11-17、潮流計算側でユーザーが Constant を Static に改めました。)

1. `controller.avr.Static`(キー `avr-static`、`Vfd = Vfd_ref`、直達項 1)と `controller.governor.Static`(キー `gov-static`、`Pmech = Pmech_ref`)を作り、同期発電機の既定として最初から付けます。
2. **警告の判断は 1 か所です**: `@Component/add_local_controller.m` のローカル関数 `warn_replace(s_label, new_con, old_con, parent)` だけが、`ReplaceController` の警告を出すかどうかを決めます(AVR・local、調速機、PSS の 3 つの置き換えがすべてここを通ります)。置き換える前の `old_con` が既定の Static のときに警告を出さない判定は、向こうがここに足します。今は Static が存在しないため、常に警告します。
3. `avr.Static` の `s_role` は `"avr"` のままです。そのため、枠の検査(§2)では Static の AVR の下にも PSS を付けられます。
   - **許す(2026-11-17 決定、ee170fc6 で実装)**: Static の AVR の下にも PSS を付けられます。Static は `Vfield = Vfd_ref + Vpss` なので、PSS の出力がそのまま界磁電圧に加わります。Retrofit 制御(`pss-retrofit`)は、逆に Static の下にしか付けられません(`notes/retrofit-controller.md`)。

## 6. テスト [計測]

- 新しいテスト `+DebugScript/test_F64_controller_slots.m`(分類 `model`)。9 件です。
- 位置で取り出していた箇所を役割に書き換えました: `Scenario.m` のヘルプの例、`LocalController/get_variable_map.m` の例、`IEEE68bus.m` のヘルプ、テスト F17、I70、F62、I71、F35。役割の並びそのものを確かめるテスト(F1、F21、F30、I66、I67 など)は、位置のままにしてあります。並びは枠で保証されるためです。

## 7. 未確認・残り

- `PowerNetwork.initialize` 側の `InputDrivenTwice` は、テストで発火させていません(重なった状態の系統の平衡点を作るのが大きいため)。
- `set_avr` などは `GUILDA.update_keymap` のコード補完(`functionSignatures.json`)の対象に入れていません。

## 8. 組み込み系統の `LocalController` の既定(2026-11-20)

ブランチ `feature/local-controller-default-false`。基準コミットは 07084cd5 です。

### 決定事項(ユーザー、2026-11-20)

- 研究室では制御器なしで解析するのが標準なので、組み込み系統のコンストラクタ引数 `LocalController` の既定を `true` から `false` にしました。引数の名前は変えません。
  - 対象は `network.IEEE9bus`、`IEEE68bus`、`IEEJ_EAST10`、`IEEJ_EAST30`、`IEEJ_WEST10`、`IEEJ_WEST30` の 6 つです。
  - 付属の制御器がない系統(IEEE14bus の 3 種類、IEEE39Bus、TEST31bus、Txt3Bus、Tutorial3/6/10bus)は変えていません。
- 「制御器なし」の意味を変えました。ユーザーの言葉は「制御器なしとはガバナとAVRをstaticにしたままでいいと言うことです」です。
  - 前の `false` は、既定の Static の AVR とガバナまで外していました。
  - 今の `false` は、`local_controller/` の AVR・PSS・ガバナを付けないだけです。同期発電機には `avr-static` と `gov-static` が残ります。
- IEEJ の `Governor` は、前と同じく `LocalController=true` のときだけ効きます。
- 既存の使い方は「`LocalController=true` を書いて守る」方針です。制御器付きでないと成り立たない呼び出しに `LocalController=true` を書き足し、結果と基準値を保ちます。

### 実装 [事実]

- 各コンストラクタは今までどおり `PowerNetwork.import` で `local_controller/` の制御器を付けます。`false` のときは、Static 以外の最上位の制御器を `remove_local_controller(..., RemoveNested=true)` で外し(AVR の下の PSS も外れます)、役割が `"avr"` なら `avr-static`、`"governor"` なら `gov-static` を付け直します。外してから付けるので、`ReplaceController` の警告は出ません。枠の並び(AVR、ガバナの順)は `add_local_controller` が保ちます。
- 新しいメソッドやプロパティは足していません。

### 固有値 [計測](R2026a、`net.get_sys().get_eigenvalue()`)

Static の AVR とガバナは状態を持たず、`Vfield` と `Pmech` を平衡点の値に保ちます。そのため、**今の `false` と前の `false`(制御器をすべて外したもの)の固有値は、10 ケースすべてで一致しました**(0 付近の固有値の数値の揺れを除きます)。下表の「最大の実部」は、角度と周波数の共通モードによる 0 付近の固有値(絶対値 1e-4 程度以下)を除いたものです。

| 系統 | `LocalController=false`(今の既定) | `LocalController=true` |
|---|---|---|
| IEEE9bus | 安定、-0.028 ± 0.076i | 安定、-0.0069 |
| IEEE68bus | 不安定、実の固有値 +0.128 | 安定、-0.0051 |
| IEEJ_EAST10 peak | 不安定、+0.033 | 安定、-0.0086 |
| IEEJ_EAST10 night | 不安定、+0.100 | 安定、-0.061 ± 2.90i |
| IEEJ_EAST30 peak | 不安定(とても遅い)、実の固有値 +0.00056、ほかは -0.024 以下 | 安定、-0.0086 |
| IEEJ_EAST30 night | 不安定、実の固有値 +0.073 と +0.039 | 安定、-0.094 ± 3.10i |
| IEEJ_WEST10 peak | 不安定、+0.069 ± 0.036i | わずかに不安定、+0.0011 ± 4.28i |
| IEEJ_WEST10 night | 安定、-0.025 | ほぼ減衰なし、-0.0009 ± 3.01i |
| IEEJ_WEST30 peak | 不安定、実の固有値 +0.20(ほかに +0.038、+0.019) | わずかに不安定、+0.0048 ± 3.88i |
| IEEJ_WEST30 night | 不安定、実の固有値 +0.18 | 安定、-0.061 ± 2.52i |

- IEEJ_EAST30 のヘルプは前に「peak は安定(最大の実部 -0.024)、night は不安定な実の固有値が 1 つ(+0.073)」と書いていました。計算し直すと、peak には +0.00056 の遅い実の固有値があり、night には +0.039 の実の固有値もあります。ヘルプはこの値に直しました。
- peak の +0.00056 は数値の誤差ではなく、実際の遅い不安定なモードです [計測]。
  - 潮流計算の `Tolerance` を 1e-8 から 1e-12 に締めても、6 桁まで変わりません。`Type="ODE"` と `"DAE"` でも同じ値です。
  - 状態行列 A(180 次)の特異値で 0 に近いのは 1 つ(1.1e-14、共通の角度)だけです。次は 6.4e-3 です。
  - `condeig` は 9.9e8 で、条件が悪い固有値です(0 の 2 重のモードに近いため)。誤差の見積もりは eps × 9.9e8 × ‖A‖(314)≈ 7e-5 で、値 5.6e-4 より小さいので、符号は確かです。
  - 右固有ベクトルの向きから `expm(A t)` で計算すると、400 s ごとに 1.25 倍(exp(0.00056 × 400))で指数的に増えます。2 重の 0 のモードなら線形の増え方になるはずなので、別のモードです。
  - 参加率は各発電機の `delta` と `omega` で、B3007SG1(0.107)、B2001SG1(0.055)が大きいです。時定数は約 30 分です。
- 各系統のヘルプの「制御器なし」の記述は、この表の値に合わせて直しました。

### 直した呼び出し [事実]

- テストの呼び出しは「書いて守る」方針で `LocalController=true` を足しました。一覧は §8 の末尾のテストの節にまとめます。
- `_GUILDAtutorial` の mlx と、サブモジュール(`_GUILDAverification`、`_GUILDAslides`、`_GUILDAdocPages`)は、このブランチでは変えていません。必要な箇所は担当のセッションに渡します [未決]。

