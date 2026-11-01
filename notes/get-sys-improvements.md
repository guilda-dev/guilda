# `PowerNetwork.get_sys` と周辺ワークフローの改善案

調査ノート [get-sys-workflow.md](get-sys-workflow.md)(以下 **WF**)と [get-sys-linearization.md](get-sys-linearization.md)(以下 **LN**)を基にした提案です。採否は利用者が決めます。ソースは変更していません。

**ラベル**

- **[事実]** コードを読んで確認
- **[再現]** ベースのコピーで実行して確認
- **[試作]** スクラッチのコピーに試作を当てて実行(コミットしていません)
- **[見積]** 判断による推定で、計測していません
- **[未確認]** 調べていません

**パス** 先頭が `_GUILDAobject/`、`+DebugScript/`、`_GUILDAdoc/` 以外は `_GUILDAsystem/` からの相対パスです。

## 1. 結論

**推奨する方向: API の形は変えず、まず「黙って間違う経路」を止めます。** 線形化の数値は正しいことが確認済みです(LN §5.4)。問題は線形化そのものではなく、その前後にあります。平衡点でない点を平衡点として通す経路、編集後に古い答えを返す経路、機器を黙って落とす経路です。大きな設計変更は不要で、多くは小さな修正で済みます。

**最初に行う 5 件**

| 順 | ID | 内容 | 根拠 |
|---|---|---|---|
| 1 | EQ1, EQ2 | `initialize(Method="OPF")` / `"equilibrium"` で機器ごとの P, Q を使う | 試作で KCL 残差 0.39 → 1.2e-12、5 秒の状態変動 9.4 → 2.6e-11(IEEE9) |
| 2 | EQ3 | `initialize` の最後の KCL 検査と、途中失敗を stale にする処理 | 同じ種類の不具合を今後も止める安全装置 |
| 3 | ED1 | 層別 `get_sys` に編集の検査を入れる | 試作で 3 例とも正しいエラーに変わり、既存テスト 110 件が合格 |
| 4 | NU1 | `NonUnit` を「機器を落とす」から「静的機器を Y に吸収する」へ | 試作で最大実部 +1.09 → 0、Kron との差 2e-12(要判断) |
| 5 | PF1 | 変数表を列から 1 回だけ組み立てる | `linearize` 735 → 270 ms(IEEE68)、結果は完全一致 |

EQ6(AVR 付き発電機のトリップで例外)も 1 行単位の修正で試作が動いたので、同時に行うことを勧めます。

**性能について:** 疎行列化は今は勧めません。Kron の計算は 18.5 → 0.27 ms と速くなりますが、`linearize` 全体の約 2% にすぎません。先に表の処理を直すほうが効きます(§5.8)。

## 2. 調査ノートの再確認

主要な指摘はコードと実行で再確認しました。

**再現できたもの [再現]:** E01 系(層別 `get_sys` が古い答えを返す)、E05(読み込み後の母線数 0)、E06(`MATLAB:TooManyOutputs`)、E11(残差 0.392)、E21(残差 0.196)、E10、B1、B2、B6、`NonUnit=[7 9]` の +1.09、NaN の `Point` で `dss` の例外。

**修正・補足が必要なもの**

| # | 調査ノートの記述 | 再確認の結果 |
|---|---|---|
| 1 | LN「性能」: `get_admittance_matrix` は `table` のラベル添字を枝ごとに使っている(`:27-28`)と、負荷の要因のように挙げている | **主因ではありません。** 枝のループを数値添字に変えても 57 → 57 ms で変わりませんでした [試作]。プロファイルでは 0.69 s 中 0.60 s が母線シャントの `b.tab_parameter.dynamics{...}`(`@PowerNetwork/get_admittance_matrix.m:31`)です |
| 2 | WF §6.1: `get_variable_map` は約 42%、`linearize` は 2.12 s | LN の 65%、861 ms のほうが実態に合います。今回は 717〜763 ms で、表の処理を外すと 63% 減りました。WF の値は初回 1 回の測定で、プロファイラの負荷を含みます |
| 3 | LN R1: `Vst` が消えるのは `connect` の `Simplify` によると考える [推測] | **確認できました。** `connectOptions("Simplify",false)` で IEEE9 は 24 → 27、IEEE68 は 128 → 144 状態になります [試作] |
| 4 | LN §5.1: `dss` / `ss` が疎行列を保持するかは [未確認] | `dss` は疎行列を密に変換し、`sparss` を使うよう警告します [再現] |
| 5 | WF 問題 8: `operation.baseMVA` の編集が stale にならないのは問題 | **重要度を下げます。** `x`, `u` は保持している V, I, P, Q から計算済みなので、保持している点は現在のモデルの平衡点のままです [事実]。「再度 `initialize` すると別の配分になる」だけです(EQ5) |
| 6 | WF 問題 9: `net.rv_Xequilibrium` は `Bus` にプロパティが無いため失敗 | そのとおりですが、**それだけではありません。** `Component.rv_Xequilibrium_all` は PSS を含まず(IEEE9 の発電機で 6 個、変数表は 9 個 [再現])、`@PowerNetwork/PowerNetwork.m:230` が読む `Branch` の値もコード上で見つかりません [事実]。名前だけ足しても直りません(DF1) |

**調査ノートに無かった新しい指摘 [事実]**

- `class-design.html:221` の作業データ一覧に、削除済みの `l_isNonUnit`, `rv_odeX0` が残っています(`notes/v4-migration.md:85-86,498`)。
- `solver_LIN.NonUnit` は `a_Bus` の添字を保存します(`_auxiliary/@odeLinearizer/odeLinearizer.m:29`)。`class-design.html` の Identity にある「添字は保存しない」と矛盾します(NU3)。
- `@PowerNetwork/check_edit.m:21-24` は編集記録から理由を作ります。EQ3 で記録なしの stale を作る場合は、理由の文言が別に必要です。

## 3. UX 定義シートとの対応

`GUILDA_主機能UX定義シート.xlsx` を読み取り専用で確認しました。**決定欄はすべて空欄です。** そのため、シートから読める要件は次の範囲です。

- **`A_横断ルール` 5(前提条件):** 「(a) 明示エラー+メッセージ」が選択肢の先頭にあり、`api-design.html` の rule 5 と同じです。ED1、NU1、EQ3 はこれに従います。
- **`A_横断ルール` 6(副作用):** `get_` は値を変えません。ED1 の `f_*` 再構築は `api-design.html` が例外とする「内部キャッシュ」の範囲です。
- **`A_横断ルール` 7(共通オプション):** `plot`, `verbose`, `progress` を共通化します。`linearize` の `Plot` は対応済みです。
- **`B_機能別UX定義` の「近似線形化」行:** 現在の戻り値が `[sys, lin]` のままで、実装(`[sys, flag, output]`)より古い内容です。決定欄の案を §7 に示します。
- **`使い方` の手順 C:** 機能ごとに `+DebugScript/` の正規デモを 1 本作り、受け入れ基準にするとあります。TS2 で対応します。
- **新規機能「Direct Methods」「ヘシアン」:** 未実装です。任意の点での線形化と `LinearizationResult` を保つ方針は、これらを妨げません。PT1(固定項の保存)はこの用途にも役立つと考えます [見積]。

## 4. 全提案の一覧

**種別:** (a) 仕様判断が不要なバグ修正、(b) 利用者の判断が必要な設計変更、(c) 性能、(d) 整理。**工数**(S: 半日以内、M: 1〜2 日、L: 3 日以上)は [見積] です。

| ID | カテゴリ | 種別 | 問題と根拠 | 影響 | 工数 | 互換リスク | 優先 |
|---|---|---|---|---|---|---|---|
| EQ1 | 平衡点 | a | OPF の配分が機器に渡らない。WF 問題 1、`@Bus/set_equilibrium.m:24,63` | 高: 平衡でない点で解析が通る | S | OPF 初期化の数値が変わる(正しくなる) | 1 |
| EQ2 | 平衡点 | a+b | `"equilibrium"` が編集を無視して stale を解除。WF 問題 2 | 高 | S | 低 | 1 |
| EQ3 | 平衡点 | a | 最終検査が無く、途中失敗で混在。WF 問題 13 | 高: 予防 | S | 低 | 1 |
| EQ4 | 平衡点 | a | Hz 編集で `local_LQR.K` が古い。WF 問題 3 | 中 | S | 低 | 2 |
| EQ5 | 平衡点 | b | `baseMVA`, OPF の編集と stale の意味。WF 問題 8 | 低 | S | なし | 3 |
| EQ6 | 平衡点 | a | AVR / PSS 付きのトリップで例外。WF 問題 6 | 高: 機能が使えない | S | 低 | 1 |
| ED1 | 編集検査 | b | 層別 `get_sys` に検査なし。WF 問題 4 | 高 | M | 中: 動いていた呼び出しがエラーになる | 1 |
| ED2 | 編集検査 | a | `get_hessian` も同じ構造。WF 問題 4 | 中 | S | 低 | 2 |
| ED3 | 編集検査 | a | `remove/replace_component` で GC の参照が古い。WF 問題 7 | 中 | S | 低 | 2 |
| ED4 | 編集検査 | a | `.mat` 読み込みで網が空。WF 問題 5 | 中 | M | 低 | 2 |
| ED5 | 編集検査 | b | 結果が編集の有無を持たない。`notes/status.md:208-210` | 中 | M | 低(追加のみ) | 3 |
| NU1 | NonUnit | b | 機器を黙って落とす。LN R4、§5.5 | 高 | M | 中: 入力数と数値が変わる | 1 |
| NU2 | NonUnit | a | Kron, DAE, `Plot` で無視される。LN R5 | 中 | S | 低 | 2 |
| NU3 | NonUnit | b | 添字を保存する。§2 | 低 | S | 低(追加のみ) | 3 |
| PT1 | Point | b | 固定項を捨てる。LN R3 | 中 | M | なし(追加のみ) | 3 |
| PT2 | Point | a | 故障中の `Y`、NaN の点。LN R2、WF 問題 10 | 中 | S | 低 | 2 |
| FL1 | flag | b | `flag` が数値的失敗を表さない。LN B4 | 中 | S | 低 | 2 |
| FL2 | flag | a | B1, B3, B4, B6 の分かりにくい失敗 | 中 | S | 低 | 2 |
| SH1 | モデル形状 | b | 入出力を選べない。V, I, y を取れない。LN §3.4 | 中 | M | なし(追加のみ) | 2 |
| SH2 | モデル形状 | b | Feedback が負荷の入力を落とす。LN B5 | 中 | S | 中 | 2(NU1 と一体) |
| SH3 | モデル形状 | b | Feedback の `Vst` 消去。LN R1 | 低 | S | 変更すれば高 | 3 |
| SH4 | モデル形状 | a | `Coordinate` を `get_sys` で渡せない。LN §1.5 | 低 | S | なし | 3 |
| SH5 | モデル形状 | a | 完全な名前で添字指定できない。LN B2 | 中 | S | 低 | 2 |
| SH6 | モデル形状 | d | 文書と v3 互換の矛盾。LN §3.1, §4 | 中 | S | なし | 2 |
| AR1 | 引数 | d | 内部用の `rec`, `full`, `con` が公開。WF 問題 14 | 中 | M | 低 | 2 |
| AR2 | 引数 | b | 層で戻り値が違う。LN §4 | 低 | S | 低 | 3 |
| AR3 | 引数 | a | 分かりにくいエラーと黙った無視。WF E14, E16, E24、問題 17 | 低 | S | 低 | 3 |
| DF1 | データ | a | `rv_Xequilibrium_all` と `net.rv_Xequilibrium`。§2 | 中 | S | 低 | 2 |
| DF2 | データ | d | 作業データの後始末が不揃い。WF 問題 16 | 低 | S | なし | 3 |
| PF1 | 性能 | c | 表の再構築。LN §5.2 | 中 | S | なし | 1 |
| PF2 | 性能 | c | 制御器モデルの二重計算。WF §6.1 | 低 | S | なし | 2(AR1 と一体) |
| PF3 | 性能 | c | シャントの表アクセス。§2 | 低 | S | なし | 2 |
| PF4 | 性能 | c | 疎行列化。LN §5.1 | 今は低 | L | 中 | 4(保留) |
| DU1 | 重複 | d | I2V 3 か所など。LN「重複」 | 低 | M | 低 | 3 |
| DU2 | 未使用 | b | v2 コード、`tools.for_ss`、`port_vw`。LN「未使用」 | 低 | S | 共同開発者次第 | 3 |
| TS1 | テスト | d | 現行テストが上記を検出しない。WF 付録 | 高 | 各項目に含む | なし | 1 |
| TS2 | テスト | d | 正規デモが無い。UX シート | 中 | S | なし | 3 |
| TS3 | 文書 | d | 文書の誤り。WF §6.4、§2 | 中 | S | なし | 各段階 |

## 5. 主な提案の詳細

### 5.1 平衡点の正しさ

#### EQ1, EQ2: 機器ごとの P, Q を渡す

**問題 [事実]:** `Bus.set_equilibrium` は常に `para_powerflow` から機器の P, Q を読みます。OPF の解と保持している電流のどちらも、`V` 以外は捨てられます。原因は EQ1 と EQ2 で同じです。

**選択肢(EQ1)**

| 案 | 内容 | 利点 | 欠点 | 失敗する条件 |
|---|---|---|---|---|
| A(推奨) | `result.tab_cub` の P, Q を `set_equilibrium` に渡す | モデルデータを書き換えない。呼び出し形は不変 | 後で `initialize()` すると設定値の潮流に戻る | `tab_cub` が機器を網羅しない場合(AC OPF は網羅 [事実]) |
| B | 配分を `para_powerflow` に書き戻す | 次の潮流でも再現する | 「解析はシステムデータを変えない」に反し、編集記録も汚れる | Q=NaN の仕様が失われる |
| C | `Method="OPF"` をエラーにする | 変更が最小 | `notes/opf-requirements.md:9` の要件を満たさない | — |

**スケッチ(試作で動作確認済み)**

```matlab
% @Bus/set_equilibrium.m: 既定は [] で、従来どおり
opt.rm_PQ double = []   % [pu] 機器ごとの [P Q]。指定時はスラックと NaN の配分を行わない

% @PowerNetwork/initialize.m
c_PQ = component_power(obj, str_method, result);   % "powerflow" は空
obj.a_Bus{i_bus}.set_equilibrium(c_Vbus, c_Ibus, r_Pbus, r_Qbus, "rm_PQ", c_PQ{i_bus})
```

`component_power` は、OPF では `tab_cub{機器タグ, ["P","Q"]}`、`"equilibrium"` では `V*conj(I)` を返します。

**試作の結果 [試作]**

| 系統 | 手順 | KCL 残差 | 5 秒の状態変動 | 続く `Method="equilibrium"` |
|---|---|---|---|---|
| IEEE9 | 現行 OPF | 3.92e-1 | 9.39 | `InitializeEquilibriumFailed` |
| IEEE9 | 案 A | 1.21e-12 | 2.55e-11 | 成功(1.25e-12) |
| IEEE14 | 現行 OPF | 2.83e-1 | 24.65 | `InitializeEquilibriumFailed` |
| IEEE14 | 案 A | 5.34e-14 | 2.70e-12 | 成功(5.34e-14) |
| 3 母線 | P 編集後の `"equilibrium"`、現行 | 1.96e-1 | — | — |
| 3 母線 | 同、案 A | 1.39e-14 | — | — |

試作では同一母線に複数の機器がある系統を試していません [未確認]。

**EQ2 の追加の判断:** 案 A だけでは、P を編集した後の `"equilibrium"` は整合した点を返しますが、**編集は黙って無視されます。**

| 案 | 内容 | 利点 | 欠点 |
|---|---|---|---|
| 1(推奨) | 記録に powerflow / Topology / Slack の編集があればエラーにし、`net.initialize()` を案内する。dynamics の編集は許す | 編集が消えない。rule 5 に合う | 古い点を保ちたい使い方ができない |
| 2 | 通して INFO を出す | 止まらない | INFO を見落とすと気づかない |

dynamics の編集を許すのは、V, I を固定して `x`, `u` を再計算すれば、新しいモデルの平衡点になるためです。これが `"equilibrium"` の本来の用途だと考えます。

**テスト:** `+DebugScript/test_F3_initialize.m`。OPF 初期化の残差と `max_state_drift`(現行テストは V の一致だけです)、OPF → equilibrium の連続実行、同一母線の複数機器、P 編集後のエラー。

**移行:** OPF 初期化の後の数値が変わります。従来の値は平衡点ではなかったため、`v4-migration.md` の silent change 欄に載せます。

#### EQ3: 最終検査と途中失敗の扱い

**案:** `set_equilibrium` の前に stale を立て、最後に KCL 残差を確認してから `reset_edit` します。

```matlab
obj.l_staleEquilibrium = true;          % 途中で失敗しても「有効」にならない
% ... 既存の設定ループ ...
r = max(abs(Y*obj.cv_Vequilibrium - obj.cv_Iequilibrium));
if r >= 1e-6, error('GUILDA:PowerNetwork:InitializeNotEquilibrium', ...); end
obj.reset_edit()
```

**しきい値の根拠 [再現]:** 潮流初期化の残差は全 6 系統で最大 7.9e-11(`TEST31bus`)、OPF の試作は最大 1.2e-12 です。既存の `"equilibrium"` の許容値 1e-6(`@PowerNetwork/initialize.m:171`)に揃えても余裕があります。

**選択肢:** 失敗時に以前の平衡点へ完全に戻す案もあります。`initialize` の help と `api-design.html` の「失敗時は変更しない」に完全に合いますが、機器と制御器の全平衡点(`local_LQR.K` を含む)の保存が必要です。**推奨は stale にする案で、**文書を「解析の失敗では変更なし、設定段階の失敗では再初期化が必要」に直します。誤った結果を防ぐ目的はこれで足ります。

**注意:** stale の理由の文言が必要です(§2)。**テスト:** `test_F3_initialize.m`(WF E17 の再現)。

#### EQ4: Hz 編集と `local_LQR.K`

| 案 | 内容 | 利点 | 欠点 |
|---|---|---|---|
| A(推奨) | `local_LQR` が `rebuild_odefcn` で `K` も再設計する。未初期化なら行わない | 「Hz は `initialize` 不要」を保てる | `K` が編集後に変わる |
| B | LQR があれば Hz 編集で stale にする | 単純 | 編集表に条件が増える |

機器が先に再構築され(`check_edit` は親が先 [事実])、設計は保持済みの平衡点だけを使うので、案 A は成立すると考えます。**試作していません。テスト:** `test_F3_edit_handling.m`(WF E03 で `K` が再初期化時の値と一致すること)。

#### EQ5: stale の意味を明文化する

stale を **「保持している点が現在のモデルの平衡点でなくなった」** と定義することを提案します。すると、`operation.baseMVA` と OPF 関連の編集は stale にしないという現行の動作が正しくなります。文書に「再初期化すると Q 配分や OPF の解は変わり得る」と書くだけで済みます。

#### EQ6: 制御器付き発電機のトリップ

**問題 [事実]:** `_auxiliary/@odeSimulator/odeSimulator.m:661,669` は 2 出力で呼びますが、制御器の `get_equilibrium` は出力を持たず、自分の平衡点へ書き込みます。単純に呼ぶように直すと、平衡点と `local_LQR.K` が上書きされます(WF §5.3)。

| 案 | 内容 | 利点 | 欠点 |
|---|---|---|---|
| A(推奨) | `x0 = a_LC.rv_Xequilibrium`。保持している平衡点から再開 | モデルに書かない。GC の再開方法と同じ(`:687` 付近のコメント) | 再接続時の電圧との差で過渡が出る |
| B | 保存・実行・復元で再計算する | 状態は現在の電圧に近い | 復元すると `Vref` は元の値なので結局整合せず、LQR の `K` も再設計される |
| C | 制御器に計算だけの新メソッドを追加 | 明快 | 「Controllers keep their own contract」に反し、共同開発者のモデルに影響する |

**試作 [試作]:** 案 A で IEEE9 の AVR + PSS 付き発電機をトリップすると `flag=1`、`A` の差 0、平衡点の差 0 でした。再接続後の応答の物理的な妥当性は評価していません。**テスト:** `test_F6_simulation.m`(`:317-319` はこの経路を通らないので、制御器付きの機器をトリップする節を追加)。

### 5.2 層をまたぐ編集の検査

#### ED1: 層別 `get_sys` の検査

| 案 | 内容 | 利点 | 欠点 | 失敗する条件 |
|---|---|---|---|---|
| A(推奨) | 公開の入口で再構築と検査を行う。`Point` 指定時は再構築だけ | 「古い平衡点はエラー」が全層で同じ意味になる | 編集後の呼び出しがエラーになる | ネットワークに未接続の機器(検査を省略) |
| B | 警告だけ | 既存スクリプトが止まらない | 決定済みの「エラーで止める」に反する | 警告を見落とす |
| C | 現状維持 + 文書 | 変更なし | 黙って間違う | — |

```matlab
% _auxiliary/@LayerPackage/LayerPackage.m (Hidden)
function check_layer(obj, l_needEquilibrium)
    net = obj;
    while ~isa(net,"PowerNetwork") && isa(net,"LayerPackage"), net = net.parent; end
    obj.check_edit();                       % この層以下の f_* を再構築
    if l_needEquilibrium && isa(net,"PowerNetwork") && ...
            (net.str_editFlag == "unset" || net.l_staleEquilibrium)
        error('GUILDA:PowerNetwork:EquilibriumStale', ...)   % 文言は既存のものを共有
    end
end
```

位置引数 `x, V, I, u` を与えた `comp.get_sys` でも、制御器は平衡点で線形化されます(`@Component/get_sys.m:47-48`)。そのため、**平衡点を要らないものとして扱うのは `Point` 指定時だけ**にします。

**内部呼び出し:** `local_LQR` の設計は `initialize` の途中(stale の状態)で `rec=false` により呼ばれるので、検査は `rec=true` の経路だけに置きます。コストは親をたどる分だけで、全体で O(N) です [見積]。

**試作 [試作]:** 未初期化は `MATLAB:badsubscript` → `EquilibriumStale`、編集後の `comp` / `bus` は無言(`A` の差 0、つまり古いモデル)→ `EquilibriumStale` に変わりました。`local_LQR` の初期化も通りました。**F3, F6, F7 の 110 件すべて合格**です(EQ1, EQ2, EQ3 の stale 部分, EQ6, PF1, PF2, Y のループ変更も適用した状態)。`con.get_sys` と `gc.get_sys` には試作で入れていません。

**テスト:** `test_F3_edit_handling.m`(全層の検査、失敗した `net.get_sys` の後に答えが変わらないこと)。

**移行:** silent change ではなくエラーで気づきます。`_GUILDAtutorial` と保留中のチュートリアルブランチを確認してください。

#### ED3, ED4, ED5

- **ED3 [a]:** `Bus.remove_component` / `replace_component` に `remove_bus` と同じ確認(`@PowerNetwork/remove_bus.m:34-42`)を入れます。`replace` で GC の対象を引き継ぐかは要判断ですが、**まず拒否**を推奨します。挙動が単純で、切り離した機器の古い `iv_ode*` を読む問題(E09)も防げます。テスト: `test_F1_model_building.m`。
- **ED4 [a]:** `set.a_Bus` などの `dbstack` 検査(`@PowerNetwork/PowerNetwork.m:248-268`)を `SetAccess` の制限に置き換えます。読み込み後のリスナーと `f_*` の動作は [未確認] で、読み込みだけ直しても編集検査が効かない恐れがあります。まずテスト(`test_F8_utilities.m`)を書き、直らない場合は保存自体をエラーにする案に切り替えます。
- **ED5 [b]:** ネットワークが編集ごとに増える `i_modelStamp` を持ち、`AnalysisResult` が実行時の値を保存して、`result.l_stale` で比較します。`notes/status.md:208-210` の未解決事項と、古い `{sim, t}` の問題(WF §5.3 [未確認])を解決できます。「結果はモデルデータをコピーしない」には反しません。

### 5.3 `NonUnit` と `Point` の意味

#### NU1, SH2: `NonUnit` の意味(`v3` 互換と衝突)

**問題 [再現]:** `NonUnit` は電流が流れている機器も落とします。IEEE14 の `NonUnit=[7 9]` で最大実部 +1.09、警告なしです。一方、利用者向けの説明は「Buses without dynamic units can be specified」です(`_GUILDAdoc/index.html:435`)。この説明の意図と実装が合っていません。

**提案は `net.get_sys` の v3 互換(`notes/v4-migration.md:30-31`)と衝突します。** 案 B はその例外を認めるものなので、独立した判断として扱います。

| 案 | 内容 | 利点 | 欠点 | 失敗する条件 |
|---|---|---|---|---|
| A | 動作を変えず、電流がある母線の指定で警告する | v3 と一致 | 不安定なモデルを返し続ける | 警告を見落とす |
| **B(推奨)** | 静的機器は線形化した `Div`, `Diu` を `Y` に吸収する。状態を持つ機器のある母線はエラー | 物理的に等価で全方式と一致。SH2 も解決 | 入力数と数値が変わる。動的機器を落とす使い方は不可 | v3 の結果の再現が必須の場合 |
| C | `NonUnit` を廃止して自動判定のみ | 単純 | 文書の用例が壊れる | — |

**吸収の式:** 非 unit 母線 n では `Ybar_nn = Y_nn - Div_n`、`Diu_n u_n = Ybar_nu V_u + Ybar_nn V_n` なので、

```
I_u = (Ybar_uu - Ybar_un Ybar_nn⁻¹ Ybar_nu) V_u + Ybar_un Ybar_nn⁻¹ Diu_n u_n
```

**試作の結果 [試作]** (IEEE14、Kron との比較。周波数応答は s=j の全チャネルの最大差)

| `NonUnit` | 現行: 最大実部 / 固有値差 / 入力数 | 案 B: 最大実部 / 固有値差 / 入力数 / 周波数応答差 |
|---|---|---|
| `7` | -0.000 / 2.0e-12 / 32 | -0.000 / 2.0e-12 / 34 / 7.2e-13 |
| `[7 9]` | **+1.091 / 1.09** / 30 | -0.000 / 1.6e-12 / 34 / 6.6e-13 |
| 静的母線すべて(9 個) | **+1.905 / 1.90** / 16 | -0.000 / 2.8e-12 / 34 / 6.1e-13 |

P=Q=0 の負荷も同じ処理で入力が残ります(Ishizaki6Bus: 8 → 12 入力、周波数応答差 2.7e-12、IEEE14: 32 → 34)。状態を持つ母線の指定は試作でエラーになりました。

**テスト:** `test_F7_linearization.m`。現行の `Non unit bus`(`:62-67`)は P=Q=0 の B007 だけなので、`[7 9]` を追加します。`LinearizeMatchesV3Get_sys...`(`:279-315`)は NonUnit を含む系統で v3 との一致を固定しており、**案 B では期待値の変更が必要です。**

**移行:** `InputName` で引くコードは動きます。入力の位置に頼るコードは silent change になるので、移行ガイドの先頭の欄に載せます。

#### NU2, NU3

- **NU2 [a]:** `Algorithm` が Kron / DAE で `NonUnit` が空でなければ、INFO を出して無視していることを明示します。`Plot` は `options.Algorithm` を使います(`_auxiliary/@LinearizationResult/Plot.m:10`)。案 B を採るなら Kron, DAE への適用も検討できますが、固有値は変わらないので必須ではありません。
- **NU3 [b]:** `NonUnit=["B007","B009"]` を追加で受け付けます。数値も残します。`set.NonUnit` の検証の変更だけです。添字の保存を禁止すると v3 の呼び方が使えなくなるので、禁止はしません。

#### PT1, PT2

- **PT2 [a]:** NaN を含む点は、`dss` に届く前に `GUILDA:odeLinearizer:PointNotFinite` で止め、変数のラベルを示します(トリップ中の `{sim,t}` が該当)。故障中の `{sim,t}` は `Y` が反映されないので(LN R2)、`output.phases` と照合して INFO を出します。**故障を `Y` に反映する案は採りません。** 「`Point` は変数の点で、網はモデルのもの」と定義するほうが単純です。テスト: `test_F7_linearization.m`。
- **PT1 [b]:** `result.rv_residual`(点での `dx` と母線の電流収支)を保存し、平衡点でなければ `output.message` に示します。`get_ss` は変えません。アフィン項を使うエネルギー解析にも使えます。別案の「`get_ss` にアフィン項を返す」は `ss` で表せないので採りません。

### 5.4 `flag` と診断

#### FL1

**問題 [事実]:** `flag` の判定は有限性だけです(`_auxiliary/@odeLinearizer/solve.m:96`)。ところが NaN は先に `dss` で例外になるので(WF 問題 10)、**`flag=false` の経路は実質的に使われていません。** 一方、特異な `Avv` では `flag=true` のまま `get_ss` が分かりにくいエラーになります。

| 案 | 内容 | 利点 | 欠点 |
|---|---|---|---|
| A(推奨) | logical のまま「`Avv` が数値的に正則で、全要素が有限」とする。理由は `output.message` と `output.str_issue` に入れる | `if flag` が有効なまま。`l_success` も変更不要 | 段階は表せない |
| B | `simulate` のように 1 / 0 / -1 | 近特異を区別できる | v4 で形が変わる。`if flag` の意味が曖昧になる(`simulate` で既に注意が必要) |

- **しきい値:** `rcond_Avv < 1e-14` を `false` とします。出荷系統の最小は 1.4e-4(LN §5.1)なので十分離れています。値は [見積] です。
- **`net.get_sys`:** `flag=false` なら `get_ss` の前に `GUILDA:LinearizationResult:SingularAvv` で止めます。`linearize` は結果を返し、DAE はそのまま取り出せます。

**テスト:** `test_F7_linearization.m`(LN B4 のスタブ)。

#### FL2

| LN | 修正 |
|---|---|
| B1 | 全母線が非 unit なら `GUILDA:LinearizationResult:NoUnitBus` |
| B3 | `GC.get_sys` で対象の `sv_y` を確認し、`GlobalControllerPort` を出す(`@GlobalController/GlobalController.m:150`) |
| B4 | `has_I2V` で `D` の可逆性も見る。可逆でなければ機器名を示す(`_auxiliary/@LinearizationResult/get_ss.m:221`)。ただし案 B の吸収で一部は不要になる |
| B6 | `I2V` で `D` が特異なら `GUILDA:Bus:NoI2V` で止める(`@Bus/get_sys.m:87`, `@Component/get_sys.m:176`) |

`R6` の `1e-12` は `FL1` のしきい値と併せて定数にまとめます。

### 5.5 モデルの形、名前、入出力の選択

**基本方針:** `net.get_sys` の既定の出力は v3 互換のまま変えません(LN §4 の不統一は意図されたものです)。追加のオプションで解決します。

#### SH1: 入出力の選択

| 案 | 内容 | 利点 | 欠点 |
|---|---|---|---|
| A(推奨) | `get_ss(Algorithm, Input=, Output=)` と `net.get_sys(Input=, Output=)` を追加。値は変数表の `Label`、または種類 `"x"`, `"V"`, `"I"`, `"y"` | 既定は不変。V, I, y を取れる | 実装が 3 方式に必要 |
| B | Kron の `OutputName` を埋める | 小さい | v3 テスト(F7 `:310-311`)に反する。V, I は取れない |
| C | 利用者が `rm_*` から組み立てる | 変更なし | 毎回同じ計算を書くことになる |

```matlab
sys = net.get_sys(Algorithm="Kron", Output=["V","omega_SG1B001_B001_PowerNetwork"]);
% V 出力: V = -Avv \ (Avx x + Bv u) の行を C, D に追加
```

名前は `get_variable_map` の `Label` と同じにし、状態と同名の出力には `Y_` を付けます(下位の層の規則と同じ)。**実装の順序:** 共通の `C`, `D` を組み立てる処理は Kron と DAE で共有し、Feedback は Kron の `Output` 部分を流用できます [見積]。

**テスト:** `test_F7_linearization.m`(3 方式の伝達関数の一致)。

#### SH3: Feedback の `Vst`

`Simplify=false` なら 144 状態で Kron と一致し(固有値差 8.6e-11、周波数応答差 1.8e-10 [試作])、**既定の変更は技術的には簡単です。** ただし F7 の v3 一致に反し、状態名で引くコードの結果も変わります。**推奨は既定を変えず、`get_ss` の help に明記することです。** 形を揃えたい利用者は Kron を使えます。

#### SH4, SH5, SH6

- **SH4:** `solver_LIN.Coordinate` と `OptionMap` の項目を追加します(既定 `"theta&rho"`)。
- **SH5:** 外側の `sys.InputGroup` / `OutputGroup` の設定(`@Component/get_sys.m:105-106`)をやめます。内部の結線に使うのは内側の `rec=false` と `tag=false` の制御器だけです [事実]。`LocalController` は `tag=true` のときだけ省きます(`@LocalController/get_sys.m:67-68`)。Bus は既にグループなしで動いています。テスト: `test_F7_linearization.m`。
- **SH6:** `class-design.html:141` に「`PowerNetwork.get_sys` は v3 互換で、状態を出力とする。Kron, DAE の状態順は大域制御器が先」と明記し、`:278` の「別の順序を定義しない」に `get_ss` の例外を記します。`:202` は「状態も読む」に直します。**次の 2 点は変更しません(v3 互換):** DAE の `theta1` などの番号付きの名前、Kron の空の `OutputName`。

### 5.6 引数と層の API

#### AR1, PF2: 内部オプションの分離

`rec`, `full`, `con` を公開引数から外し、機器単体のモデルを Hidden メソッドにします。

```matlab
methods (Hidden)
    sys = get_sys_alone(obj, x, V, I, u, opt)   % 現在の rec=false の経路。opt.port, opt.tag, opt.controllerPorts
end
```

- `local_LQR.m:138` と `@Component/get_sys.m:55` の呼び出しを置き換えます。これで PF2(二重計算)と SH5 の一部が同時に解決します。
- `Component.full`, `con` は `Bus` と同様に「無視」のまま残します。**`rec` は公開の説明がなく内部用なので、削除します。** `con` を無視する動作は `notes/v4-migration.md:27-29` の方針と同じです。互換フックを足す場合は `test_F10_api_foundation.m` の個数も更新します。
- **別案:** 引数を残して文書化するだけなら変更は不要ですが、「効かない公開引数」が残ります。

#### AR2, AR3

- **AR2 [b]:** `Bus.get_sys` に `Component` と同じ `varargout` の名前を追加し、`LocalController` の名前を `sys` に合わせます(LN §4)。**`net.get_sys` の `[sys, flag, output]` は揃えません。** 解析 API の規則が優先だからです。下位の層の名前の戻り値は `sys.*Name` と重複するので、新たに使わないよう文書に書きます。
- **AR3 [a]:** `simulate` の `time` が 3 要素以上ならエラー(E24)、作成済みイベントとトポロジの不一致を `innerdim` の前で検出(E14)、初期化前の `replace_component`(E16)、制御器の `set.tab_parameter`(問題 17)。

### 5.7 データの流れと一時データ

- **DF1 [a]:** `Component.rv_Xequilibrium_all` を深さ優先にし(`@Component/Component.m:234-236`)、`Bus` に同じ Dependent を追加します。`PowerNetwork.rv_Xequilibrium` は Branch を外して変数表の順に揃えます(`@PowerNetwork/PowerNetwork.m:228-233`)。`class-design.html:131` の例示と合います。テスト: `test_F3_initialize.m` で `net.rv_Xequilibrium` と変数表の `x` の行の一致。
- **DF2 [d]:** 計測では残留データは解析結果に影響しません(WF E07, E08)。**急ぎません。** 所有の決定(モデル側、解析クラスのみ書き込み)は変えず、`odeSimulator.solve` の `onCleanup` を機器の `l_isConnect` と母線の `l_isFault` にも広げるだけです。`rv_*offset` はクロージャを保持するので、これも解放できます。`api-design.html:247` の「Changes net: No」に「作業データを除く」を補います。

### 5.8 性能と疎性

**計測の条件:** MATLAB R2026a、`-batch`。ベースと試作を別のプロセスで交互に 3 組実行し、各 15 回の中央値を取りました。**他のセッションと並行していて(load average 約 14)、絶対値は目安です。** リング系統は発電機とインピーダンス負荷を交互に並べた人工系統です。

| 系統 | `n_x` | `linearize` ベース(3 組) | `linearize` 試作(3 組) | 変数表 ベース → 試作 | Y |
|---|---|---|---|---|---|
| IEEE68 | 144 | 735 / 717 / 751 ms | 318 / 270 / 257 ms | 115-121 → 9-11 ms | 変化なし(約 55 ms) |
| Ring272 | 816 | 2848 / 2660 / 2897 ms | 863 / 822 / 771 ms | 484-524 → 28-30 ms | 変化なし(約 200 ms) |

**結果の一致 [試作]:** IEEE9 と IEEE68 で、`rm_*`、変数表、`c_idxBus` / `c_idxGC`、Y、Kron と Feedback の行列と名前が `isequaln` で完全に一致しました。

**PF1 の案**

| 案 | 内容 | 利点 | 欠点 | 失敗する条件 |
|---|---|---|---|---|
| A(推奨) | キャッシュなし。文字列の列から組み立て、`table` は最後に 1 回。平衡点は表を使わずに作る | 無効化の問題が無い。追加データなし | 系統の表を毎回作る(ただし 10 ms) | — |
| B | 変数表を `net` にキャッシュし、Topology の編集で無効化 | 表の作成がほぼ 0 | タグの変更が記録されない(WF E20)ので古いラベルを返す | タグ変更、未初期化時の編集 |

案 A で表のコストが約 10 ms になるので、**キャッシュの利点はほとんど残りません。** 指示にあった「キャッシュの試作」の代わりに案 A を計測したのはこのためです。案 B の効果は最大でも案 A との差の約 10 ms と見ています [見積]。

試作のコードは `Bus` / `Component.get_variable_map` と別の組み立てになりましたが、実装では 1 つの内部関数に揃えます。「`get_variable_map` は順序の唯一の定義」(`class-design.html:278`)を守るためです。

**個別の効果は分離していません。** 上の値は PF1 と PF2、Y のループ変更の合計です。Y のループは効果がありませんでした(§2)。PF2 だけの効果は小さいと見ています(制御器 `get_sys` の呼び出しが半分になり、プロファイルで 0.5 s / 4 s 程度 [見積])。

**PF3:** `get_admittance_matrix` のシャントを `b.para_dynamics` から直接読みます。プロファイルの比率から、Y の時間の大部分(約 85%)が消えると推定します [見積。未試作]。

**`Feedback` の時間:** IEEE68 で 90-231 ms、Ring272 で 0.94-3.4 s と、**同じコードでも 2 峰に分かれました。** ベースと試作の両方で出るので、試作の影響ではなく環境の影響と判断します。PF1 の後は Ring272 で `connect` が `linearize` より遅くなり得ます。規模が大きいなら Kron か DAE を勧める程度で十分で、今は `via_feedback` を変更しません。

**PF4(疎行列): 保留を推奨します**

| 系統 | Kron の行列積 密 | 疎 |
|---|---|---|
| IEEE68 | 18.5 ms | 0.27 ms |
| Ring136 | 39.7 / 1.5 ms(2 回の測定) | 5.6 / 3.0 ms |
| Ring272 | 32.9 / 186.9 ms(2 回の測定) | 11.0 / 14.7 ms |

- **利得は全体の 2% 程度です**(18 ms / 770 ms)。Ring272 の密の値はばらつきが大きく、スケールの判断には使えません。
- `dss` は疎行列を受け付けないので、`get_ss` まで通すには `sparss` への変更が必要です(戻り値の型が変わり、`sys.A` が疎になります)。
- 再開の目安は N が数千(`eig` の全計算が現実的でなくなる規模)です [見積]。そのときは `rm_*` だけを疎にして、DAE を `sparss` で返すのが素直です。`LinearizationResult` の help は既に `full(result.rm_Axx)` と書いています。
- **限界:** リング系統は N=544 で潮流が反復上限に達し(`InitializePowerflowFailed`)、それ以上の規模は計測できていません。

### 5.9 重複と未使用のコード

- **DU1 [d]:** `all_controllers`(3 か所)を `LayerPackage` の Hidden メソッドに、`shape`(2 か所)と I2V の変換(3 か所)を `+tools` に、`get_ss` の局所 `complex2matrix` を `tools.complex2matrix` にまとめます。大域制御器の閉ループ(行列と `feedback`)は検算にもなるので**残します。** 動作が変わらないことは F7 で確かめられます。
- **DU2 [b]:** `tools.for_ss.*`, `tools.ssfeedback`, `GUILDA.config("Model","port_vw")`、`local_LQR_retrofit`、`get_environment`。リポジトリの中では使われていません [事実]。共同開発者のスクリプトで使われている可能性があるので、**確認してから削除してください。** v2 の 2 つは作れない / 動かないので、`archive` への移動でも構いません。`class-design.html:345` の記述も一緒に消します。

### 5.10 テストと文書

- **TS1:** 各提案のテストを修正と同じコミットに入れます。方針は「**固有値だけでなく形と残差を見る**」です。F7 の `>=`(`:35`)は等式に近い形に直します。
- **TS2:** UX シートの手順 C に従い、`+DebugScript/Task_linearization.m` を正規デモとして作ります。名前はシートの記入例 `Task_powerflow.m` と `archive/Task6_get_sys.m` に倣います。内容は、初期化、`get_sys`、`linearize` と `get_ss`、`Output` の選択、`Point={sim,t}`、編集後のエラーです。`run_all` は `test_F*` だけを読むので、実行確認は F7 から呼びます。
- **TS3:** `class-design.html`(`:131`, `:141`, `:202`, `:221`, `:278`, `:345`、編集の表)、`api-design.html:247`、`initialize` の help、`v4-migration.md`。HTML は状態を書かず、進捗は `notes/` に書きます。利用者に見える修正は `list_UpdateLog.js` に載せます。

## 6. 段階的な進め方

| 段階 | 内容 | 依存 | 触るファイル | 並行 |
|---|---|---|---|---|
| 0 | §7 の判断 | — | なし | — |
| 1A | EQ1, EQ2, EQ3 | Q2 | `@PowerNetwork/initialize.m`, `@PowerNetwork/check_edit.m`, `@Bus/set_equilibrium.m`, `test_F3_initialize.m` | ○ |
| 1B | EQ6, DF2 | なし | `_auxiliary/@odeSimulator/odeSimulator.m`, `test_F6_simulation.m` | ○ |
| 1C | PF1, PF3 | なし | `@PowerNetwork/get_variable_map.m`, `@Bus/get_variable_map.m`, `@Component/get_variable_map.m`, `@PowerNetwork/get_admittance_matrix.m`, `_auxiliary/@odeLinearizer/point_vector.m` | ○(テストは既存の F7 で確認) |
| 1D | DF1, ED3 | Q7 | `@Component/Component.m`, `@Bus/Bus.m`, `@PowerNetwork/PowerNetwork.m`, `@Bus/remove_component.m`, `@Bus/replace_component.template`, `test_F1_model_building.m` | ○(`test_F3_initialize.m` は使わず、DF1 のテストは F1 に置く) |
| 2 | ED1, ED2, AR1, PF2, SH5, EQ4 | 1A(stale の文言)、Q1 | `@Component/get_sys.m`, `@Component/get_hessian.m`, `@Bus/get_sys.m`, `@LocalController/get_sys.m`, `@GlobalController/GlobalController.m`, `_auxiliary/@LayerPackage/LayerPackage.m`, `_GUILDAobject/+controller/local_LQR.m`, `test_F3_edit_handling.m`, `test_F7_linearization.m` | 直列 |
| 3 | NU1, SH2, NU2, FL1, FL2, PT2 | 2、Q3, Q4 | `_auxiliary/@LinearizationResult/get_ss.m`, `Plot.m`, `_auxiliary/@odeLinearizer/solve.m`, `odeLinearizer.m`, `test_F7_linearization.m` | 直列 |
| 4 | SH1, SH4, PT1, NU3 | 3 | 段階 3 と同じ + `@PowerNetwork/get_sys.m`, `linearize.m` | 直列 |
| 5A | DU1, DU2 | 4、Q8 | `+tools`, `_GUILDAobject/+controller/+modeling/`, `local_LQR_retrofit.m`, `@GUILDA/config/DefaultModel.json` | ○ |
| 5B | AR2, AR3, ED4, ED5 | 2 | `_auxiliary/@AnalysisResult/`, `_auxiliary/@odeEventSet/` など | ○(5A と重ならない範囲。`@PowerNetwork/PowerNetwork.m` は 5B のみ) |
| 5C | SH6, TS2, TS3 | 各段階 | `_GUILDAdoc/developer/*.html`, `notes/*.md`, `list_UpdateLog.js`, `+DebugScript/Task_linearization.m` | ○ |

**注意**

- 段階 1 の 4 つは共有ファイルがなく、同時に進められます(`.claude/CLAUDE.md` の並行の条件を満たします)。
- `notes/v4-migration.md` は全段階に関係するので、**サブセッションでは編集せず、各段階のブリーフで文案を報告させ、段階の統合時に 1 か所でまとめて反映**してください。
- `@Component/get_sys.m` と `test_F7_linearization.m` は段階 2-4 で共有するので、並行にしないでください。
- `ED1` は `_GUILDAtutorial` の更新ブランチ(保留中)の確認項目になります。

### 6.1 文書の反映状況(SH6, TS3, Issue #87)

2026-11-01、`docs/87-get-sys-docs` で反映しました。R2026a で実測した内容に合わせています。

- **反映済み:** `class-design.html`(各層の出力、変数順の例外、ポート、Hz の表)、`api-design.html`、`get_sys` / `linearize` / `get_ss` / `Component.get_sys` の help、`v4-migration.md`。
- **修正不要:** `class-design.html` の `rv_Xequilibrium` の例、大域制御器が状態を読む記述、作業データの一覧(いずれも統合時点で正しい)。
- **未反映:** `initialize` の help の OPF の記述。IEEE9bus の OPF 初期化で残差は 0.39 のままで、コードの修正(Issue #56)と合わせて直します。
- **v3 互換で残したもの:** DAE の `theta1` などの番号付きの名前、Kron の空の `OutputName`、`Feedback` の `Vst` の出力行。

## 7. 利用者に判断をお願いする事項

| # | 質問 | 推奨 | 理由 |
|---|---|---|---|
| Q1 | 層別 `get_sys` は stale でエラーにしますか(ED1) | **はい** | 決定済みの「古い平衡点は止める」と同名同義の原則に合う。試作で既存テスト合格 |
| Q2 | powerflow / Topology / Slack の編集後の `Method="equilibrium"` をエラーにしますか(EQ2) | **はい。dynamics の編集だけ許す** | 編集が黙って消えない |
| Q3 | `NonUnit` を v3 互換から外し、静的機器の吸収に変えますか(NU1) | **はい** | 現行は不安定なモデルを返す。v3 互換の例外を 1 つ認めることになる |
| Q4 | `flag` は logical のままにしますか(FL1) | **はい**。`Avv` の正則性を含め、理由は `output.str_issue` に | `if flag` を保つ |
| Q5 | 入出力の選択 `Input=`, `Output=` を追加しますか(SH1) | **はい。既定は不変** | v3 互換を保って V, I, y を取れる |
| Q6 | Feedback の既定の形(`Vst` 消去)を変えますか(SH3) | **変えない** | 利益より互換の損失が大きい |
| Q7 | GC の対象の `replace_component` は拒否しますか、引き継ぎますか(ED3) | **拒否** | 単純で、古い添字の問題を防げる |
| Q8 | v2 の `local_LQR_retrofit`, `get_environment`、未使用の `tools.for_ss` を削除しますか(DU2) | **共同開発者に確認してから削除** | リポジトリの外の利用は分からない |
| Q9 | 疎行列化は保留でよいですか(PF4) | **保留** | 全体の 2% で、`sparss` で戻り値の型が変わる |
| Q10 | 結果に編集の刻印を入れますか(ED5) | **入れる(後回しで可)** | `status.md` の未解決事項を解決できる |
| Q11 | UX シートの「近似線形化」行をどう埋めますか | 下の案 | シートは利用者のものなので変更していません |

**UX シート「近似線形化」の記入案**

| 列 | 案 |
|---|---|
| メソッド名 / 置き場所 | `net.linearize()`(主)、`net.get_sys()`(近道) |
| 入力 | `Algorithm`, `NonUnit`, `Point`, `Plot`(Q5 を採れば `Input`, `Output`, `Coordinate`)。既定は `net.solver_LIN` |
| 出力 | `[LinearizationResult, flag, output]`、`get_sys` は `[ss, flag, output]` |
| 副作用 | なし(`f_*` キャッシュの再構築のみ) |
| 前提条件 | 平衡点が最新。そうでなければ `EquilibriumStale`(全層) |
| 正規デモ | `Task_linearization.m` |

## 8. 計測と試作の範囲

- **環境:** MATLAB R2026a、`-batch`、macOS。スクラッチパッドのコピーで実行し、ワークツリーには何も生成していません。試作はコミットしていません。
- **試作に含めたもの:** EQ1, EQ2(案 A のみ), EQ3 の stale 部分のみ(KCL 検査は未実装), EQ6(案 A), ED1(`Component`, `Bus` のみ), PF1, PF2, Y のループ, NU1 / SH2(`LinearizationResult` を読むスクリプトとして)。
- **回帰確認:** 上記のうち NU1 以外を適用したコピーで `DebugScript.run_all("Features",["F3","F6","F7"])` を実行し、110 件すべて合格でした。他の機能のテスト(特に F1, F4, F8, F10)は実行していません。テストの追加はしていないので、**合格は「既存の動作を壊していない」ことだけを示します。**
- **試作していないもの:** EQ4, ED2-ED5, NU2, NU3, PT, FL, SH1, SH4, SH5, AR, DF, PF3, DU。これらの効果と工数は [見積] です。
- **判断の記録:** キャッシュの代わりに案 A を計測しました(§5.8)。UX シートは Python 標準ライブラリで読み、リポジトリにはコピーしていません。
