# AVR のリミッタと ON/OFF の切り替え(`feature/avr-limiter`)

ブランチは `feature/avr-limiter` です(未 push、分岐元 `refactor/design-alignment` の `ee007c26`)。この文書は実装前の仕様です。§8 の問いには、2026-11-17 にユーザーが回答しました(§1.1)。残っているのは、IEEE9bus と IEEJ の値の選択(§5.2)と、他のコーディネーターとの調整(§9)です。

**ラベル**: [事実] = コードを読んで確認しました。[計測] = MATLAB R2026a で実行して確認しました。[文献・確認] = 出典を取得し、値を読んで確認しました。[文献・未確認] = 出典を取得できず、確認していません。[提案] = この文書の提案で、まだ承認されていません。

パスは次のように省略します。`C/` = `_GUILDAobject/+controller/+avr/`、`N/` = `_GUILDAobject/+network/`、`D/` = `+DebugScript/`。

## 0. 要点

1. **リミッタの値**: IEEE68bus の 16 台の AVR_ST1 には `Vap_max = 5`、`Vap_min = -5` [pu] を提案します。この値は、68 母線系統のデータのうち静止励磁器に当たるもの(PST v3 の G9、SNL PSTess の全 16 台、PSS/E 版 dyr の G9 の SEXS)で共通です(§2)。
2. **切り替え**: AVR_ST1 と AVR_DC1 の `dynamics` パラメータに、論理値の列 `Limiter` を 1 つ追加します。既定値は `true` です。`false` にすると、その AVR の上下限をすべて無視します(DC1 では `Vap` と `Vfld` の両方)。追加するメンバーはこの列だけです(§3)。
3. **既定値**: IEEE68bus の CSV では `Limiter = 1`、上下限を ±5 にします。Q4 の回答により、IEEE9bus と IEEJ の 4 系統の CSV にも `Limiter` を明示します。推奨は、どちらも `Limiter = 1` で今の上下限のまま(IEEE9bus は ±Inf、IEEJ は報告書の値)とすることで、結果は変わりません(§5.2)。自作の AVR は既定の `true` と ±Inf のままです。
4. **影響**: IEEE68bus で結果が変わるのは、平衡点から外れる時間応答だけです。平衡点はすべて上下限の内側にあるため(最大 2.43 pu)、平衡点と線形化は変わりません。simulate の基準 6 例のうち、変わるのは `ieee68_fault` の 1 例です。既存のテストで直す必要があるのは 1 件(F28 の `sv_para` の並び)です(§6)。
5. **回答**: Q1〜Q7 には回答があります(§1.1)。AVR_ST1 は non-windup にします。残っているのは IEEE9bus の値の選択(§5.2)と、他のコーディネーターとの調整(§9)です。

## 1. 決定事項(ユーザー、2026-11-17)

- 実機の AVR にはリミッタがあります。そこで AVR にリミッタを付け、**AVR のプロパティだけで** ON/OFF を切り替えられるようにします。系統のコンストラクタにはオプションを設けません。上下限の値はパラメータに残し、スイッチはそれを適用するかどうかだけを決めます。
- IEEE68bus は、リミッタ ON と現実的な上下限を既定として構築します。OFF にすると、これまでの版(v2/v3)の結果を再現できます。
- 上下限の値は出典のある文献から取ります。この文書で提案し、ユーザーの承認を受けてから実装します。
- 方針は単純さを優先します。後方互換のためのコードは書きません。

### 1.1 未決事項への回答(ユーザー、2026-11-17)

§8 の問いへの回答です。

| # | 回答 |
|---|---|
| Q1 | IEEE68bus の 16 台に ±5 pu を使います |
| Q2 | AVR_ST1 を non-windup にします。スイッチとは別のコミットにし、simulate の基準を記録し直す前に行います |
| Q3 | 列名は `Limiter` にします |
| Q4 | **推奨と変わりました。** 「他の系統も一貫性を持たせるために Limit を持っていいようにおもいます」。IEEE9bus と IEEJ の 4 系統の AVR の CSV にも、列 `Limiter` を明示します。値の案は §5.2 にあります |
| Q5 | `Te = 0.05` は変えません |
| Q6 | AVR_DC1 の `Jacobi_dx` の不一致は、別の課題として扱います(今回は直しません) |
| Q7 | `InvalidValueRange` のメッセージに、`Limiter` を false にする対処を加えます |

### 1.2 背景 [計測]

IEEE68bus で B029 に 1.00〜1.07 s の地絡を与えると、除去直後に B009 の電圧が 1.97 pu になります。AVR_ST1(`kap = 200`、`tap = 0.05`)には上下限がない(±Inf)ため、地絡の間に B009SG1 の界磁電圧が 2 pu から 163 pu まで上がります。v2.1 でも同じ値になります。

## 2. 文献の値

GUILDA の IEEE68bus は、全 16 台を同じ静止励磁器 `Ka/(1 + s Te)`(`Ka = 200`、`Te = 0.05`、v2 の `avr_sadamoto2019.csv`)としてモデル化しています [事実]。一方、ベンチマークの原典では機械ごとに励磁器の形式が異なります。そのため「GUILDA の 1 次遅れの出力上下限に、どの値を当てるか」が問題になります。

### 2.1 出典ごとの値

| # | 出典 | 励磁器の形式 | 上下限 | 状態 |
|---|---|---|---|---|
| 1 | PST v3 の `data16m.m`(G. Rogers / J. Chow, Power System Toolbox)。写し: [cuihantao/pst `pdata/data16m.m`](https://github.com/cuihantao/pst)、[sandialabs/snl-pstess `data/archive_data/archive_PSTv3p0_data/data16m.m`](https://github.com/sandialabs/snl-pstess)(2 つは同一) | G1〜G8: DC1(type 1、`KA = 40`、`TA = 0.02`)。G9: 簡易静止励磁器(type 0、`TR = 0.01`、`KA = 200`、`TA = 0`)。G10〜G16: 励磁器なし | G1〜G8: `Vrmax = 10`、`Vrmin = -10`。**G9: `Vrmax = 5.0`、`Vrmin = -5.0`** | [文献・確認](`exc_con` の行を読みました) |
| 2 | SNL PSTess の現行 `data/data16m.m`([sandialabs/snl-pstess](https://github.com/sandialabs/snl-pstess))。[pnnl/GridSTAGE](https://github.com/pnnl/GridSTAGE) も同じ値 | 全 16 台が簡易静止励磁器(type 0、`TR = 0`、`KA = 100`、`TA = 0.01`) | **全台 `5.0` / `-5.0`** | [文献・確認] |
| 3 | TF ベンチマークの PSS/E 版 dyr: [pnnl/LL-risk-assessment `RATLLE_v1.0/PSSE_Cases/NETS-NYPS 68 Bus System.dyr`](https://github.com/pnnl/LL-risk-assessment)、[tdcosim/TDcoSim `tdcosim/data/transmission/68bus/case68.dyr`](https://github.com/tdcosim/TDcoSim)(励磁器の記録は同一) | G1〜G8、G10〜G12: DC4B(`KP = 200`、`KA = 1`、`TA = 0.02`、`KE = 1`、`TE = 0.785`)。G9: SEXS(`TB = 0.01`、`K = 200`、`TE = 0`)。G13〜G16: 励磁器なし | DC4B: `VRMAX = 10`、`VRMIN = -10`、`VEMIN = -10`。**G9 の SEXS: `EMIN = -5`、`EMAX = 5`** | [文献・確認](値は読みました。PSS/E の各フィールドの意味は記憶で対応付けました) |
| 4 | C. Cañizares et al., "Benchmark Models for the Analysis and Control of Small-Signal Oscillatory Dynamics in Power Systems," *IEEE Trans. Power Systems*, vol. 32, no. 1, pp. 715–722, 2017, doi:10.1109/TPWRS.2016.2561263([PDF](https://web.eecs.umich.edu/~hiskens/publications/07463478.pdf)) | 本文: "All generators have DC excitation systems (DC4B), except for Generator 9 which has a static excitation system ST1A." G1〜G12 に PSS あり | 数値なし | [文献・確認](形式の割り当てだけ) |
| 5 | IEEE PES Task Force, "Benchmark Systems for Small-Signal Stability Analysis and Control," PES-TR18, 2015([vdoc.pub の写し](https://vdoc.pub/documents/benchmark-systems-for-small-signal-stability-analysis-and-control-35e21po868mg)) | §4.6 は #4 と同じ割り当て(DC4B と G9 の ST1A) | 68 母線のデータ表(§5.6)は写しが途中で切れていて読めませんでした | 形式: [文献・確認]。上下限: [文献・未確認] |
| 6 | A. K. Singh and B. C. Pal, "IEEE PES Task Force on Benchmark Systems for Stability Controls — Report on the 68-Bus, 16-Machine, 5-Area System," ver. 3.3, Dec. 2013(core.ac.uk ほか) | 検索の抜粋によれば、データは `data16m_benchmark.m` にあり、DC4B と ST1A を使います | 取得できませんでした(403)。#3 の dyr はこの報告を PSS/E に変換したものと考えられますが、推測です | [文献・未確認] |
| 7 | B. Pal and B. Chaudhuri, *Robust Control in Power Systems*, Springer, 2005, pp. 171–178(GUILDA の IEEE68bus が出典として挙げる本) | — | 付録を取得できませんでした。GUILDA の `Ka = 200`、`Te = 0.05`(全台)がこの本から来たのかも確認できていません | [文献・未確認] |
| 8 | [marioap7/QBBT](https://github.com/marioap7/QBBT) の `NETS-NYPS/d16m_mpm.m`(参考) | 全台が `KA = 50`、`TA = 0.02` | ±50 | [文献・確認]。他と大きく異なる外れ値です |

取得したファイルは、作業用ディレクトリの `/private/tmp/claude-501/-Users-taku-GUILDA-GUILDAdev/e02297af-e2de-4540-8362-7528e7c84673/scratchpad/pst/` にあります(リポジトリの外)。

### 2.2 GUILDA への対応と推奨 [提案]

- GUILDA の AVR_ST1 では、1 次遅れ `kap/(1 + tap s)` の出力 `Vap` がそのまま界磁電圧 `Vfield` になります。つまり `Vap_max`/`Vap_min` は、PST の type 0 の `Vrmax`/`Vrmin`(= Efd の上下限)、および SEXS の `EMAX`/`EMIN` に当たります。
- DC 励磁器の ±10(#1 の DC1、#3 の DC4B)は、DC 励磁器の前段にある調整器出力 `VR` の上下限です。界磁電圧そのものの上下限ではありません。したがって、静止励磁器としてモデル化した GUILDA の AVR_ST1 には当てはまりません。
- 静止励磁器の上下限は、確認できたすべての出典(#1 の G9、#2 の全台、#3 の G9)で **±5 pu** です。`KA = 200` の静止励磁器(#1 と #3 の G9)とも一致します。
- そこで、**全 16 台に `Vap_max = 5`、`Vap_min = -5` を推奨します。** 平衡点の界磁電圧は 1.03〜2.43 pu なので [計測]、天井値は平衡点の 2.1〜4.9 倍になります。静止励磁器の天井としてよく使われる範囲です。
- GUILDA の `Te = 0.05` に一致する出典はありません(出典は `TA = 0`、`0.01`、`0.02`)。この時定数は v2 の値のまま変えません(§8 の Q5)。

## 3. 切り替えの設計

### 3.1 候補

| 案 | 内容 | 利点 | 欠点 |
|---|---|---|---|
| **A(推奨)** | `dynamics` の表に論理値の列 `Limiter` を加え、`sv_para` の末尾に置きます | 他のパラメータと同じ経路で扱えます。表、CSV、`add_local_controller(parameter=...)`、GUI の表で読み書きでき、編集は `Parameter` が記録します。`dynamics` の編集なので、`equilibrium` と `odefcn` が古くなります(`LocalController.handle_edit`)。新しい仕組みは要りません | `param` ベクトルの中では 0/1 の double になります(表の `{}` で double に変換されます [計測])。CSV では `true`/`false` ではなく `1`/`0` と書きます(`readtable` は `true`/`false` を cell として読むため [計測]) |
| B | AVR の通常のプロパティ `l_limiter` | 名前が命名規則の論理値の形になります | 値の変更を `log_edit` で知らせるコード、`set_odefcn` で `param` に渡す仕組み、GUI と CSV の扱いを別に作る必要があります。単純さの方針に反します |
| C | 上下限を ±Inf に書き換えて OFF とします | メンバーが増えません | 上下限の値がパラメータに残らないため、決定事項(値は残し、スイッチで適用を決める)に反します |

### 3.2 新しいメンバー(案 A)[提案]

追加するのは次の 2 クラスの 1 列だけです。新しいメソッドとプロパティはありません。

| クラス | 追加 | 位置 |
|---|---|---|
| `controller.avr.AVR_ST1` | コンストラクタ引数 `param.Limiter (1,1) logical = true  % true to apply Vap_min and Vap_max; false ignores them.` と、`dynamics` の列 `Limiter` | `sv_para = ["ttr"; "Vap_max"; "Vap_min"; "kap"; "tap"; "kst"; "tst"; "Limiter"]`(`param(8)`) |
| `controller.avr.AVR_DC1` | コンストラクタ引数 `param.Limiter (1,1) logical = true  % true to apply the limits of Vap and Vfld; false ignores them.` と、`dynamics` の列 `Limiter` | `sv_para` の末尾、`Vfld_min` の後(`param(14)`) |

- 列名は、他のパラメータ(`kap`、`Vap_max`)と同じく接頭辞を付けません。`Limiter` とします(§8 の Q3)。
- 引数の検査 `(1,1) logical` は、`readtable` が読んだ double の 0/1 を論理値に変換します。0/1 以外の値は、コンストラクタの引数の検査でエラーになります。
- 表への書き込みは `avr.tab_parameter.dynamics.Limiter = false` とします。`= 0`(double)は列のクラスが変わるため、`GUILDA:Parameter:ClassNameMismatch` になります [事実: `Parameter.set.tab_parameter` はクラスを検査します。`T.L = 0` で列が double になることは計測で確認]。他の列と同じ規則なので、特別な扱いはしません。

### 3.3 古さ(stale)の扱い [事実]

`Limiter` の編集は、`Parameter` を通じて `dynamics` の編集として記録されます。`LocalController.handle_edit` は、これを `equilibrium` と `odefcn` を古くする編集として扱います。

- 平衡点の値そのものは `Limiter` によって変わりません。ただし、ON にしたときは範囲の検査(§4)をやり直す必要があります。そのため `equilibrium` を古くする扱いは正しく、特別扱いは不要です。再計算の手間は、`Vap_max` を編集した場合と同じです。
- `odefcn` を古くするのは、`param` のベクトルを作り直すために必要です。

## 4. AVR のクラスごとの動作 [提案]

`Limiter = false` のときは、上下限を ±Inf にした場合と同じ式になります。従来の IEEE68bus は ±Inf なので、OFF にすると**ビット単位で同じ結果**になる見込みです(式の上では一致します。実装後に `simulate_baseline` で確かめます)。

### 4.1 AVR_ST1(`C/@AVR_ST1/`)

現状 [事実]: 上下限は**出力だけのクリップ(windup)**です。`fcn_y` は `y = max(min(x(2), Vap_max), Vap_min)` で、状態 `Vap` は上下限を越えて動き続けます。`Jacobi_Y` は `Cyx = [0,1,0]*(heaviside(Vap - Vap_min) - heaviside(Vap - Vap_max))`、`Jacobi_dx` は上下限によりません。

| 関数 | `Limiter = true` | `Limiter = false` |
|---|---|---|
| `fcn_y` | 今のクリップ | `y = x(2)` |
| `Jacobi_Y` | 今の heaviside の係数 | 係数 1 |
| `fcn_dx`、`Jacobi_dx`、`fcn_Mass` | 変更なし | 変更なし |
| `get_equilibrium` | 今の検査(`Vap_st <= Vap_min || Vap_st >= Vap_max` で `GUILDA:AVR_ST1:InvalidValueRange`) | 検査しない |

[計測] ±5 の windup のクリップでは、B029 の地絡の間に状態 `Vap` が 187 pu まで上がります(出力は 5 pu で止まります)。状態がクリップの内側に戻るまで、出力は天井に張り付いたままです(`tap = 0.05` で約 0.1 s と見積もれます。未計測)。

### 4.2 AVR_DC1(`C/@AVR_DC1/`)

現状 [事実]: 2 つの non-windup の上下限があります。

- `Vap`: 範囲の外にあり、さらに外へ向かう間は `dx2 = 0` にします。
- `Vfld`: 上下限に達し、さらに外へ向かう間は `dx3 = 0` にします。

**1 つのスイッチで両方を切り替えます**(推奨)。「AVR のリミッタ」は 1 つの概念で、スイッチを 2 つにすると組み合わせが増えるだけだからです。

| 関数 | `Limiter = false` のとき |
|---|---|
| `fcn_dx` | `dx2 = -Vap + kap*Vcom` と `dx3` を常に使います(凍結の条件を評価しません) |
| `Jacobi_dx` | `rv = 1`、`Bxu` の heaviside の係数を 1 にし、`Axx(3,:)` を 0 にしません |
| `get_equilibrium` | `FieldOutOfRange` と `InvalidValueRange` の検査をしません |
| `fcn_y`、`Jacobi_Y`、`fcn_Mass` | 変更なし |

既存の不整合 [事実、今回の範囲外]: `Jacobi_dx` の `Bxu(2,:)` は `heaviside(Vap - Vap_min) - heaviside(Vap - Vap_max)` だけで決まり、`Axx(2,:)` の条件(`Vap*Vcom <= 0` のときは動く)と一致しません。上下限の外で内側へ戻る点で、`Bxu` が 0 になります。平衡点は上下限の内側なので、線形化には影響しません。

### 4.3 平衡点の検査のメッセージ

`InvalidValueRange`(`_GUILDAsystem/_auxiliary/SystemTools/GUILDA/en/AVR_ST1.xml`、`AVR_DC1.xml`)は「Widen Vap_min and Vap_max, or change the operating point ...」です。これに「or set Limiter to false」を加えることを提案します(§8 の Q7)。I69 のテストは "Widen Vap_min and Vap_max" を含むことだけを確かめているので、文を足しても通ります。

## 5. 系統ごとの既定値

| 系統 | AVR | 今の上下限 [事実] | 平衡点 [計測] | 提案 |
|---|---|---|---|---|
| IEEE68bus | AVR_ST1 × 16 | ±Inf | `Vfield` 1.030〜2.432 pu | CSV(`N/@IEEE68bus/controller/avr/parameter.csv`)に列 `Limiter` を加えて全行 1 とし、`Vap_max = 5`、`Vap_min = -5` にします。クラスのヘルプの「and no limits」を、上下限、出典、OFF の方法に書き換えます |
| IEEE9bus | AVR_ST1 × 3(`kap = 2`) | ±Inf | 1.351〜2.859 pu | Q4 の回答により、列 `Limiter` を明示します。値は §5.2 の案から選んでいただきます(推奨は 9-A: `Limiter = 1` で ±Inf のまま) |
| IEEJ_EAST10、EAST30、WEST10、WEST30(peak と night、計 8 CSV) | AVR_DC1(10/30/10/30 台) | `Vap` ±100、`Vfld` 0〜4 | `Vfld` 1.20〜2.26 pu、`Vap` 0.012〜0.023 pu | Q4 の回答により、列 `Limiter = 1` を明示し、報告書の上下限はそのままにします(§5.2 の J-A)。結果は変わりません |
| 利用者が `add_local_controller("avr-ST1"/"avr-DC1")` で作る AVR | — | クラスの既定は ±Inf | — | `Limiter` の既定は `true`、上下限の既定は ±Inf のまま。結果は変わりません |

クラスの既定の上下限は ±Inf のままにします。有限の値にすると、IEEE14 に AVR を付けるテストや基準(`ieee14_trip` など)が変わるためです。

IEEE68bus で OFF にする(v2/v3 を再現する)方法は、ヘルプに次のように書きます。

```matlab
net = network.IEEE68bus();
for i = 1:16
    avr = net.a_Bus{i}.a_Component{1}.a_LocalController{1};
    avr.tab_parameter.dynamics.Limiter = false;
end
net.initialize();
```

### 5.1 IEEE68bus での効果 [計測]

±5 の上下限を表に書き込み(今の windup のクリップ)、`[0, 10]` s で計算しました(R2026a、既定の設定)。

| 地絡(1.00〜1.07 s) | 上下限 | 除去後の B009 の最大 \|V\| | 除去後の全母線の最大 \|V\| | 界磁電圧(出力)の最大 | 状態 `Vap` の範囲 | 出力点の数 |
|---|---|---|---|---|---|---|
| B029 | ±Inf | 1.9688 | 1.9688 | 163.1 | −201.5〜163.1 | 693 |
| B029 | ±5 | 1.0395 | 1.1097 | 5.00 | −10.9〜187.4 | 1162 |
| B008(基準の `ieee68_fault`) | ±Inf | 1.3814 | 1.7443 | 220.1 | −228.0〜220.1 | 648 |
| B008 | ±5 | 1.0806 | 1.1121 | 5.00 | −29.4〜220.1 | 1319 |
| B040(チュートリアル Part0) | ±Inf | 1.0904 | 1.1150 | 19.6 | −19.8〜19.6 | 629 |
| B040 | ±5 | 1.0698 | 1.1008 | 5.00 | −10.7〜22.1 | 1158 |

どの例も `flag = 1` で 10 s まで計算でき、10 s での母線電圧の範囲(0.8366〜1.0634)は変わりません。上下限に当たる区間で刻みが細かくなるため、出力点がおよそ 2 倍になります。計算時間は 1.3〜3.7 s で、大きな変化はありません。

### 5.2 IEEE9bus と IEEJ の値の案(Q4 の回答を受けて)

Q4 の回答により、5 系統(IEEE9bus と IEEJ の 4 系統)の AVR の CSV にも列 `Limiter` を明示します。CSV は IEEE9bus が 1 つ、IEEJ が 4 系統 × peak/night の 8 つで、計 9 つです。`add_avr_pss.m` と `add_avr.m` は表の列をそのままコンストラクタに渡すため、変える必要はありません [事実]。

#### IEEE9bus

GUILDA の IEEE9bus の AVR(`kap = 2`、`tap = 0.05`)と発電機の値は、v2 の前身のシミュレータ独自のものです。教科書(Anderson & Fouad)の値ではありません [事実: クラスのヘルプ]。そのため、AVR のデータがそのまま対応する文献はありません。

参考として、WSCC 9 母線の値を確認できた出典が 1 つあります [文献・確認]。OPAL-RT, "IEEE 9 Bus System Example," Rev. R0, J.-P. Bérard, 2017-10-23 の Table 2 "Exciter parameters" です([PDF](https://www2.kios.ucy.ac.cy/testsystems/wp-content/uploads/2020/03/IEEE9_model_documentation_R0.pdf)、KIOS のテストシステムのページで公開)。

| 機械 | Kp | Ka | Kf | Tr [s] | Ta [s] | Tf [s] | Vr min/max [pu] |
|---|---|---|---|---|---|---|---|
| SM1 | 5.3 | 200 | 0.0635 | 0 | 0.395 | 1 | −3.84 / 3.84 |
| SM2 | 5.3 | 30 | 0.05 | 0 | 0.4 | 1.3 | −4.59 / 4.59 |
| SM3 | 5.3 | 25 | 0.108 | 0.06 | 0.2 | 0.35 | −3 / 3 |

この出典の励磁器は、速度帰還(Kf、Tf)を持つ別の構造です。ゲインも GUILDA の `kap = 2` と大きく異なります。SM1〜SM3 を GUILDA の母線 1〜3 の発電機に対応させるのも推測です。Sauer & Pai の WSCC 3 機の例(IEEE Type I、`KA = 20`、`TA = 0.2`)は、AVR_DC1 の既定値の元になっていると考えられますが、上下限の数値は確認していません [文献・未確認]。

| 案 | CSV の値 | 計測 [計測] | 影響 |
|---|---|---|---|
| **9-A(推奨)** | `Limiter = 1`、`Vap_max = Inf`、`Vap_min = -Inf`(今の値) | — | 結果は変わりません(既定と同じ値を明示するだけ)。`ieee9_offset` は `isequaln` のままです。F8 の IEEE9bus の確認と線形化の基準値も変わりません |
| 9-B | `Limiter = 1`、OPAL-RT の Vr(母線 1: ±3.84、母線 2: ±4.59、母線 3: ±3) | `ieee9_offset`(`[0, 5]`): `Vap` の最大は 1.849 / 2.908 / 1.399 で、上下限に届きません。B007 の地絡 `[1, 1.05]`(`[0, 10]`): 最大 2.541 / 4.309 / 2.263 で、これも届きません。上下限に届かない 2 つの設定(±1e3 と 9-B)を比べると、軌道は `isequaln` で一致しました | `kap = 2` は低いゲインなので、試した外乱では上下限に届きません。結果は変わらない見込みです。ただし、平衡点の母線 2 の 2.859 pu に対し、上限の余裕は 1.6 倍です。文献の励磁器は構造もゲインも違うため、値の根拠は弱くなります |
| 9-C | `Limiter = 0`、±Inf | — | 結果は変わりません。ただし「実機の AVR にはリミッタがある」という決定と、IEEE68bus(ON)と揃わなくなります |

推奨は **9-A** です。対応する文献がない値を「現実的な値」として載せるより、上下限なし(±Inf)のまま ON と明示する方が正確です。9-B を選んでも、試した範囲では結果は変わりません。ヘルプには出典の機械が GUILDA のデータと違うことを書く必要があります。

注意 [計測]: 構築した後に表を書き換えて計算すると(平衡点を計算し直す経路)、構築時のままの系統と比べて軌道が 1.6e-8 ほど違いました(`ieee9_offset`、±Inf と 9-B の比較)。上下限に届かない 2 つの設定を同じ経路で比べると一致したので、この差は上下限ではなく、平衡点を計算し直す経路から来ています。9-B を CSV に書けば構築の経路は今と同じなので、基準は `isequaln` のままと見込みます(CSV での実行は未確認です)。

#### IEEJ の 4 系統

今の上下限(`Vap` ±100、`Vfld` 0〜4)は、電気学会の報告書の値です [事実: 各クラスのヘルプ]。

| 案 | CSV の値 | 計測 [計測] | 影響 |
|---|---|---|---|
| **J-A(推奨)** | `Limiter = 1`、今の上下限のまま | — | 結果は変わりません(既定の `true` を明示するだけ)。`_GUILDAverification` の 4 系統の比較、IEEJ を使うテスト、F16/I93 の構築の確認は、すべて変わりません |
| J-B | `Limiter = 0` | IEEJ_EAST10 で B001 に `[1, 1.07]` の地絡を与えると、`Vfld` の最大は 4.001(上限で止まる)から 4.122 に変わります | 報告書の上下限が働かなくなり、`_GUILDAverification` の報告書との比較(表 4.3)がずれるおそれがあります。推奨しません |

simulate の基準のうち、`agc_trip`、`ieee14_trip`、`ieee14_open` は IEEE14 を使います(CSV の AVR はありません)。`ieee68_nolc` には AVR がありません。したがって、どの案でもこれらは変わりません。`ieee9_offset` は、9-A と 9-C では変わらず、9-B でも変わらない見込みです。基準で変わるのは、§6.2 のとおり `ieee68_fault` だけです。

## 6. 影響

IEEE68bus の既定を ON にしたとき(§5 の提案)の影響です。

### 6.1 テスト(`D/`)

`IEEE68bus` を使うテストのファイルは 7 つです [事実]。

| テスト | 内容 | 影響 |
|---|---|---|
| `test_F8_utilities` / Template IEEE68bus keeps the v2 data | v2 のパラメータの照合、潮流、ODE の固有値(最大実部 −0.0051275)、B030 の地絡を 1 s 計算して終端時刻を確認 | 通る見込みです(照合するのは `kap`、`tap`、`ttr`、`kst`、`tst` だけ。平衡点は上下限の内側なので固有値は同じ。計算は終端時刻だけを確認)[事実から推定]。`Limiter` と ±5 の確認を加えます |
| `test_F7_linearization`(IEEE68 の 2 か所と、基準値 `linearization_reference.mat`) | 平衡点での線形化 | 変わりません。平衡点で `Jacobi_Y` の係数は 1 です [事実から推定] |
| `test_F46_graph_base`、`test_F16_csv_io`、`test_I93_model_equilibrium` | 作図、構築時の警告、平衡点 | 変わりません |
| `test_F6_simulation`(`LocalController=false`) | AVR なし | 変わりません |
| `test_F28_avr_dc1_field_limit` / Parameters are appended after the existing ones | `sv_para(end-1:end) == ["Vfld_max"; "Vfld_min"]` | **失敗します**(`Limiter` が末尾に来るため)。アサーションを直します(1 件) |
| `test_I69_avr_range_error` | 範囲のエラー | 変わりません(既定が `true` のため) |

新しいテスト(small、4〜6 件の見込み)を加えます。

- ST1 と DC1 で、`Limiter = false` の軌道が ±Inf の軌道と `isequaln` で一致すること。
- ST1 で、`Limiter = true` のとき出力が上下限で止まること。
- `Limiter` の編集で `equilibrium` と `odefcn` が古くなること。
- `Limiter = false` では範囲の外の平衡点がエラーにならないこと。
- `validate` が通り、ヤコビ行列が差分と一致すること(上下限の内側、両方のスイッチ)。

### 6.2 simulate の基準(`D/+helper/simulate_baseline.m`)

6 例のうち変わるのは `ieee68_fault` の 1 例だけです。この例は `a_Bus{8}`(B008)に `[1, 1.07]` の地絡を与え、`[0, 10]` で計算します。§5.1 の B008 の行のとおり、界磁電圧は 220 → 5 pu、除去後の最大 \|V\| は 1.744 → 1.112 pu、出力点は 648 → 1319 になります。残りの 5 例は変わりません。`ieee68_nolc` には AVR がありません。IEEE14 の 3 例は既定の ±Inf、`ieee9_offset` は ±Inf です。

基準の扱いは手順(§7)のとおりです。手順 1 では全例 `isequaln` を確かめ、手順 2 の後で記録し直します(基準の MAT はリポジトリの外にあり、記録し直すかはユーザーの承認によります)。

### 6.3 チュートリアル(`_GUILDAtutorial/`)

`IEEE68bus` を含む mlx は 10 個です [事実]。

| mlx | 内容 | 影響 |
|---|---|---|
| `Part0_Introduction.mlx` | `sc.add_fault("B040", [1.00, 1.07])` で `[0, 10]` を計算 | 応答が変わります(界磁電圧の最大 19.6 → 5 pu、除去後の最大 \|V\| 1.115 → 1.101 pu)。保存された出力と説明文を確認し、実行し直します |
| `Main.mlx`、`Part1_NetworkComponents.mlx`、`Step1_BuildNetwork.mlx` | 説明文と構築だけ | 変わりません |
| `Step2`、`Step4`、`Step5`、`Step6`、`Supplement_CheetSheet`、`ClassManual/Controller_LQR` | 旧 API(`net.simulate([0,10], 'fault', ...)`)。保留中のブランチ #113 で書き換え中 | このブランチでは扱いません。#113 の書き換えの際に、ON の既定で結果が変わることを伝えます |

### 6.4 検証スクリプト、文書

- `_GUILDAverification/` にあるのは IEEJ の 4 系統だけです。J-A(`Limiter = 1` を明示するだけ)なら結果は変わりません(§5.2)。
- `N/@IEEE68bus/IEEE68bus.m` のヘルプ(「and no limits」)を直します。クラスのリファレンス(class.html の自動生成)には、AVR_ST1 と AVR_DC1 のパラメータ `Limiter` が加わります。
- `_GUILDAdoc` の開発者向けページで、IEEE68 の応答の数値を載せているところはありません [事実: feature-linearization の行列の大きさだけで、変わりません]。

## 7. 実装の手順 [提案]

1. **スイッチの追加**(IEEE68bus の CSV は変えません)
   - AVR_ST1 と AVR_DC1 に `Limiter` を加えます(コンストラクタ、`sv_para`、`fcn_y`/`fcn_dx`、`Jacobi_*`、`get_equilibrium`)。
   - クラスのヘルプの式の節に、リミッタと `Limiter` を書きます。
   - F28 のアサーションを直し、§6.1 の新しいテストを加えます。
   - small の `run_all` を実行してコミットします。
   - `simulate_baseline(Mode="compare")` で**全 6 例が `isequaln`** になることを確かめます。
2. **IEEE9bus と IEEJ の CSV に `Limiter` を明示します**(§5.2 で選んだ値。推奨は 9-A と J-A)
   - IEEE9bus の CSV 1 つと IEEJ の CSV 8 つに、列 `Limiter` を加えます。
   - `simulate_baseline` が全 6 例 `isequaln` のままであることを確かめます。
   - IEEJ のテストと `_GUILDAverification` の比較が変わらないことを確かめます。
3. **IEEE68bus の既定を ON にします**
   - CSV に `Limiter = 1`、`Vap_max = 5`、`Vap_min = -5` を入れます。
   - ヘルプに上下限、出典(§2 の #1〜#3)、OFF の方法を書きます。F8 に確認を加えます。
   - `simulate_baseline` で `ieee68_fault` だけが変わることを確かめます。この時点では、基準をまだ記録し直しません。
4. **AVR_ST1 を non-windup にします**(Q2 の回答。別のコミット)
   - `fcn_dx` で、`Vap` が上下限の外にあり、さらに外へ向かう間は `dx2 = 0` にします。`fcn_y` は `y = Vap` とします(状態が上下限の内側に留まるため)。
   - `Jacobi_dx` の `Vap` の行と `Jacobi_Y` を、これに合わせます。
   - 差分のヤコビ行列のテストを加えます。
   - `simulate_baseline` で `ieee68_fault` だけが変わることを確かめ、ユーザーの承認を受けて基準を記録し直します。基準を記録し直すのは、ここで 1 回だけです。
5. **文書**
   - `InvalidValueRange` のメッセージを直します(Q7)。
   - `Part0_Introduction.mlx` を実行し直し、説明文を確認します。
   - クラスのリファレンスを生成し直します。
6. マージの前に medium を 1 回実行します。

## 8. 未決事項と推奨(回答済み、§1.1)

推奨の列は、回答前の提案として残しています。Q4 は推奨と違う回答でした(§5.2)。

| # | 問い | 推奨 |
|---|---|---|
| Q1 | IEEE68bus の 16 台に `Vap_max = 5`、`Vap_min = -5` を使ってよいですか | **はい。** 静止励磁器の上下限はすべての出典で ±5 です(§2.2)。代わりに ±10 も考えられますが、これは DC 励磁器の調整器の上下限で、界磁電圧の上下限ではありません |
| Q2 | AVR_ST1 の上下限は出力だけのクリップ(windup)です。文献のモデルに合わせて non-windup にしますか | **non-windup を推奨します。ただし別のコミットとし、ユーザーの判断で行います。** PST の `smpexc.m`(type 0)は、`TA ≠ 0` のとき状態 `Efd` を上下限で止め、微分を 0 にします [文献・確認: [snl-pstess `pstess/smpexc.m`](https://github.com/sandialabs/snl-pstess)。ただし、ベクトル化した経路で微分の 0 への書き戻しが別の変数になっている、という読み取りがあります]。PSS/E の SEXS の `EMIN`/`EMAX` も non-windup と記憶しています [文献・未確認]。non-windup にすると、出力 = 状態となり、`Jacobi_dx` の `Vap` の行が上下限で 0 になります(DC1 の `Vfld` と同じ形です)。平衡点と線形化は変わりません。ON のときの IEEE68 の地絡後の応答は、§5.1 からさらに少し変わります(状態が 187 pu まで上がらず、天井から早く離れます) |
| Q3 | 列名は `Limiter` でよいですか | **はい。** パラメータの列には接頭辞を付けない規則のため、`l_limiter` にはしません |
| Q4 | IEEE9bus と IEEJ の CSV にも `Limiter` の列を明示しますか | (回答前の推奨)しません。既定の `true` で結果が同じなので、変える理由がありません。**回答: 一貫性のために明示します。** 値の案は §5.2 にあります |
| Q5 | IEEE68bus の `Te = 0.05` を文献の `TA`(0.01〜0.02)に合わせますか | **合わせません。** 今回の決定の範囲外です。v2/v3 の再現性(OFF で同じ結果)を保つためにも、上下限だけを加えます |
| Q6 | AVR_DC1 の `Jacobi_dx` の `Bxu(2,:)` と `Axx(2,:)` の条件の不一致(§4.2)を直しますか | **今回は直しません。** 平衡点では影響がありません。別の課題として記録し、直すなら Q2 と同じ機会に行います |
| Q7 | `InvalidValueRange` のメッセージに「or set Limiter to false」を加えますか | **はい。** 文言を 1 文足すだけで、利用者が対処を見つけやすくなります |

## 9. 他のコーディネーターとの調整

同じ範囲に、他の 2 人のコーディネーターがまもなく手を入れます。

- (a) PF のコーディネーター: 新しい制御器クラスを追加します。ガバナ、直達項 1 の AVR、直達項 0 の PSS です。これらは、IEEE9bus のように制御器を指定しない系統の既定になります。
- (b) 設定のコーディネーター: 発電機ごとに AVR、PSS、ガバナを 1 つずつ持つ構造を設計しています(`a_AVR`/`a_GOV`/`a_PSS`、または `a_LocalController` の予約した枠)。

### 9.1 リミッタの作業で触るファイル [提案]

| 区分 | ファイル | 手順(§7) |
|---|---|---|
| AVR_ST1 | `C/@AVR_ST1/AVR_ST1.m`(コンストラクタ、`sv_para`、ヘルプ)、`fcn_y.m`、`Jacobi_Y.m`、`get_equilibrium.m`。non-windup では `fcn_dx.m`、`Jacobi_dx.m` も | 1、4 |
| AVR_DC1 | `C/@AVR_DC1/AVR_DC1.m`、`fcn_dx.m`、`Jacobi_dx.m`、`get_equilibrium.m` | 1 |
| メッセージ | `_GUILDAsystem/_auxiliary/SystemTools/GUILDA/en/AVR_ST1.xml`、`AVR_DC1.xml`(`InvalidValueRange`) | 5 |
| 系統の CSV | `N/@IEEE68bus/controller/avr/parameter.csv`、`N/@IEEE9bus/controller/avr/parameter.csv`、`N/@IEEJ_{EAST10,EAST30,WEST10,WEST30}/{peak,night}/controller/avr/parameter.csv`(8 つ)、計 10 | 2、3 |
| 系統のヘルプ | `N/@IEEE68bus/IEEE68bus.m`、`N/@IEEE9bus/IEEE9bus.m`、`N/@IEEJ_*/IEEJ_*.m`(4 つ。AVR の説明に `Limiter` を 1 語加える程度) | 2、3 |
| 系統の private | `N/@IEEE68bus/private/add_avr_pss.m`、`N/@IEEE9bus/private/add_avr_pss.m`、`N/@IEEJ_*/private/add_avr.m` | **触りません**(CSV の列をそのまま渡すため) |
| テスト | `D/test_F28_avr_dc1_field_limit.m`(アサーション 1 件)、`D/test_F8_utilities.m`(IEEE68bus の確認)、新しいテストファイル 1 つ(例: `D/test_F??_avr_limiter.m`)、`D/test_levels.m`(新しいテストの登録) | 1、3、4 |
| 基準 | `D/+helper/simulate_baseline.m` は変えません。MAT(リポジトリの外)を手順 4 で 1 回記録し直します | 4 |
| チュートリアル | `_GUILDAtutorial/Part0_Introduction.mlx`(実行し直す) | 5 |
| 抽象クラス、基盤 | `C/@abstract/`、`LocalController`、`Component`、`Parameter` | **触りません** |

### 9.2 (a) との重なり

1. **直達項 1 の新しい AVR にも `Limiter` が必要か**: 上下限を持つ AVR なら、同じ列名 `Limiter`(論理値、既定 `true`)と同じ意味(false で上下限をすべて無視する)を持たせることを推奨します。直達項 1 の AVR の上下限は出力の代数的なクリップになり、状態がないため windup の問題は起きません。ただし、`Jacobi_Y` の `Dyv`/`Dyu` に heaviside の係数が付きます。上下限を持たない AVR なら、列は不要です。どちらにするかは (a) が決めることですが、名前と意味を揃えるよう、この文書の §3.2 と §4 を (a) に渡すことを提案します。
2. **IEEE9bus の既定が途中で変わるか**: IEEE9bus は CSV で AVR_ST1 と PSS1 を指定しています [事実: `N/@IEEE9bus/private/add_avr_pss.m` が `"avr-ST1"` を固定で使います]。(a) が「制御器を指定しない系統」に IEEE9bus を含めて新しいクラスに置き換えると、次の 2 つが起きます。
   - `N/@IEEE9bus/controller/avr/parameter.csv` の列が変わり、この作業の手順 2 と衝突します。
   - `ieee9_offset` の基準、F8 の IEEE9bus の確認、線形化の基準値(`linearization_reference.mat` の IEEE9bus)が、(a) の変更で変わります。
   推奨: IEEE9bus の CSV と `add_avr_pss.m` を同時に編集するのは 1 つのセッションだけにします(共有ファイルの規則)。(a) が IEEE9bus を置き換えるなら、この作業では IEEE9bus の CSV に触らず、`Limiter` の列は (a) の新しい CSV に含めてもらいます。置き換えないなら、この作業の手順 2 をそのまま行います。どちらにするか、(a) に先に確認してください。
3. PSS(直達項 0)とガバナは、この作業と重なりません。

### 9.3 (b) との重なり

1. **AVR へのアクセス**: この文書の OFF の例(§5)と新しいテストは、`gen.a_LocalController{1}` で AVR を取ります。(b) で `a_AVR` などに変わると、これらを書き換える必要があります。`+DebugScript` には、すでに `a_LocalController{1}` を使うファイルが 24 あります [事実]。
2. **ファイルの重なり**: この作業は `LocalController`、`Component`、`C/@abstract/` に触らないので、(b) の構造の変更とはファイルが重なりません。(b) が AVR のコンストラクタや `s_role` を変える場合だけ、`C/@AVR_ST1/AVR_ST1.m` と `C/@AVR_DC1/AVR_DC1.m` が重なります。
3. 推奨: リミッタの作業を (b) より先にマージします。(b) は、AVR へのアクセスを置き換える際に、IEEE68bus のヘルプの OFF の例と新しいテストも合わせて置き換えます。(b) が先になる場合は、この作業の例とテストを (b) のアクセスで書きます。
