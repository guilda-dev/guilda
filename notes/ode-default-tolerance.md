# 時間応答の既定の相対許容誤差を 1e-6 にした理由と影響（2026-11-21）

- 基準：guilda `c08d691b`（測定）、`471e9497`（実装）。検証リポジトリ `66346bce`。
- ブランチ：guilda `fix/ode-default-tolerance`、検証リポジトリ `test/ode-default-tolerance`。
- 測定：R2026a、`matlab -batch` で行いました。

## 変更

- `@GUILDA/config/DefaultTimeSimulation.json` の `Tolerance`（`ode` オブジェクトの `RelativeTolerance`）を 1e-4 から 1e-6 にしました。`AbsoluteTolerance`（1e-6）と `MaxStep`（NaN = ソルバーの既定）は変えていません。
- SolverODE は設定を持っていません（`net.simulate` の Name-Value の既定値をそのまま受け取ります）。そのため、変えたのはこの設定ファイルだけです。
- 同じファイルの `"version"` を 2 から 3 に上げました（案 A。ユーザーが決めました）。
  - GUILDA は起動のたびに、全部の値をユーザー設定ファイル `@GUILDA/user/DefaultTimeSimulation.json` へ書きます。そのため、ファイルに 1e-4 が入っていても、ユーザーが選んだ値なのか、古い既定値が書かれただけなのかを区別できません。
  - version が違うと、`get_config` の今の仕組みが TimeSimulation の全項目を既定に戻します。このとき `INFO GUILDA:GUILDA:ConfigReset` を 1 回出します。コードは足していません。
  - ユーザーが変えていた Progress、Solver なども既定に戻ります。このことは Update log に書きました。
  - 確認済みです：version 2 のユーザー設定ファイルがある状態で起動しました。INFO が 1 回出て、ファイルは version 3、Tolerance 1E-6 で書き直されました。
- `@PowerNetwork/simulate.m` の例と、`_GUILDAdoc/developer/feature-simulation.html` の既定値の表を、新しい値に合わせました。例の `Tolerance=1e-6`（「この呼び出しだけ」の例）は、既定と同じ値になるので 1e-8 にしました。

## 理由（測定は c08d691b）

- 既定の LocalController が false になりました。そのため、ガバナのない IEEE9bus で Pmech を -0.1 変えると、60 s の時間応答が 31.6 s で止まりました。
  - ode15s のメッセージ：「最小のステップサイズより小さくせずに許容誤差を満たせません」。
  - ガバナがないので周波数が戻りません。角度と系統座標の電圧が約 15 rad/s で回り続けます。
  - モデルのバグではありません。
- 外乱を -0.4〜+0.2 で 20 例変えて、各候補を比べました（Time=[0,60]）。
  - 今の既定（Tol 1e-4、Abs 1e-6）は、6 例中 3 例と、14 例中 5 例で止まりました。
  - Tolerance 1e-5 と 1e-6 は、全 20 例で 60 s まで流れました。1e-6 は、-0.1 と -0.2 を 600 s にしても流れました。
  - AbsoluteTolerance を 1e-7 や 1e-8 に締める案と、MaxStep を 0.05〜0.2 にする案は、外乱の値によって止まったり流れたりしました。Tolerance を締めたうえで AbsoluteTolerance も締めると、かえって止まりやすくなりました（Tol 1e-6 + Abs 1e-8 は 14 例中 8 例、Tol 1e-5 + Abs 1e-7 は 14 例中 11 例が止まった）。
  - 相対許容誤差が効く理由は確かめていません。仮説は「回り続ける δ が大きくなるほど、相対許容誤差で決まる δ の誤差の幅が広がる」ことです。
- 計算時間：simulate の Category（medium、301 件）を、既定と候補で交互に流しました（負荷平均 4〜9）。
  - 既定は 5 回で 362〜398 s、Tolerance 1e-6 は 323 s でした。遅くはなりませんでした。
  - 上の -0.1 の例では、1e-6 のほうが刻みが少なくなります（60 s までで 7599 点。1e-5 では 20931 点）。
- 測定の表は、検証用の作業ファイルにまとめてあります（コミットはしていません）。

## テストの変更（検証リポジトリ）

- F6 `AVRAndPSSResponseIsUnchangedByNameWiring`：点の数の基準を 189 点から 263 点（既定 1e-6 での点数）に変えました。幅は 2 割のままです。
  - 値の assert（1e-3 の幅）は変えていません。そのまま通ります（誤差は x 7.3e-5、u 2.7e-4、V 4.1e-6）。
- F50 `InvalidValuesShowAMessageInTheFormAndGiveNoCode`：「既定と違う値」に使う Tolerance を 1e-6 から 1e-8 にしました。
- F31 `StoredTime_...` は変えていません。「既定と違う値」として使っている 1e-5 は、新しい既定（1e-6）とも違うからです（落ちたのは、候補を 1e-5 にしたときだけでした）。
- F40 `SampleTimeEndsARunTheSolverStopsAtTheTimeItStopped` は、`LocalController=true` のままです。
  - Static の AVR・ガバナでは、発電機が際限なく加速します（2.5 s で ω は約 54 pu）。
  - ode15s は失敗せずに µs の刻みで進むので、10〜15 分かかります。

## simulate_baseline を記録し直した

- 基準：`/Users/taku/GUILDA/simulate-baseline/baseline_s0.mat`。新しい既定で、`471e9497` の上で記録し直しました。
- 前の基準（d81dc99a）は、`baseline_s0_20261121_d81dc99a.mat` に残しました。
- 記録の後の compare は、6 例すべてで isequaln でした。
- 古い既定（c08d691b、Tol 1e-4）の軌道との差です。新しい軌道を、古い軌道の時刻へ pchip で補間して比べました。

| 例 | flag | 点の数 | `rm_variable` の差の最大値 | `rm_I` の差の最大値 |
|---|---|---|---|---|
| ieee68_fault | 1 → 1 | 1057 → 1722 | 1.7e-2 | 2.2e-3 |
| ieee68_nolc | 1 → 1 | 11 → 11 | 0 | 0 |
| ieee14_trip | 1 → 1 | 175 → 283 | 9.4e-4 | 3.9e-4 |
| ieee14_open | 1 → 1 | 202 → 254 | 1.4e-4 | 2.6e-4 |
| ieee9_offset | 1 → 1 | 295 → 329 | 1.4e-4 | 7.6e-5 |
| agc_trip | 1 → 1 | 266 → 196 | 1.6e-3 | 2.1e-3 |

- ieee68_fault の最大の差は、B008SG1 の制御器 `B008SG1CA1` の状態 `Vap` に出ました。t = 1.71 s（故障の除去の直後）で、そのときの値は 3.05 です。
- Tolerance を 1e-5 にした場合も、古い既定との差はほぼ同じ大きさでした（ieee68_fault で 1.7e-2）。このことから、差の大部分は古い既定の解の誤差だとみられます。
- 確認済みの事実です：前の基準ファイル（d81dc99a）の ieee68_nolc の `rm_variable` は、今回より前から c08d691b の古い既定の軌道と isequaln ではありませんでした（rv_t と rm_I は一致）。今回の変更とは関係ありません。

## スライドの fig_control.m（_GUILDAslides）

- 変更の後も最後まで流れます。ただし、governor と AGC の図の 1 つ目の例（ガバナなし、Pmech -0.1）が 46.9 s で止まります（`GUILDA:PowerNetwork:SimulationIncomplete`）。
  - 原因：回避のために渡している `AbsoluteTolerance=1e-8` と、新しい既定 Tol 1e-6 との組み合わせです。上の測定で止まりやすいと分かった組み合わせです。
  - `AbsoluteTolerance=1e-8` を外すと、両方の例が 60 s まで流れます（確認済み）。
  - スライドのリポジトリは、このブランチでは変えていません。

## medium の結果（af77ac59 + 検証リポジトリ 522ae7a）

- 855 件のうち、PASS 854、FAIL 0、SKIP 1 でした。SKIP は F4 の MATPOWER との比較です（MATPOWER がパスにないため）。
- 時間は 660 s、負荷平均は 2.2〜3.0 でした。F91 も含めて流しました。
