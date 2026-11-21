# 解析の進捗表示 (Progress)

基準: ブランチ `feature/analysis-progress-default`(`refactor/design-alignment` の f8c20aaf から分岐)、2026-11-16。

## 背景

既定の設定では、解析を始めてからしばらく何も表示されず、実行中かどうかが分からなかった。既定で進捗を表示し、設定で止められるようにした。

## 決定事項

- 潮流計算・入力固定の潮流計算・最適潮流計算・連続潮流計算に `Progress`(`"none"|"disp"|"dialog"`、既定 `"dialog"`、`true`/`false` は `"dialog"`/`"none"`)を加えた。`simulate` の `TimeSimulation.Progress` と同じ形。設定は `PowerFlowCalculation`・`OptimalPowerFlow`・`ContinuationPowerFlow` の各セクションの `Progress`(`FromLogical` あり)。
- `Verbose` は従来どおりコマンドウィンドウへの詳細表示で、既定 `false` のまま。
- ダイアログは実行が 0.5 秒以上続いたときだけ開く(短い計算でちらつかない)。終了時とエラー時に `onCleanup` で閉じる。
- GUILDA アプリ(`GUILDA.launch_gui`)の画面(Tag `"GUILDA:app"`)が見えていれば、その `uiprogressdlg` に表示する。なければ `waitbar`。
- `matlab -batch` では `"dialog"` は何も表示しない(テストでダイアログが開かない)。
- 内部の呼び出しは `Progress="none"`: `initialize`(呼び出しで `Progress` を渡したときはそれを使う)、入力固定の潮流計算の初期点の潮流計算、安定度制約付き OPF の潮流計算(`stability_point`)。安定度制約付き OPF は外側の反復だけを表示し、内側の OPF は `"none"`。

## 実装

- `ProgressODE` を `ProgressGUILDA` に改名・一般化した(`_auxiliary/@ProgressGUILDA`)。追加: メソッド `update(s_text, r_fraction)`、プロパティ `s_title`・`s_text`・`r_fraction`・`t_draw`・`n_draw`・`h_timer`。コンストラクターは `ProgressGUILDA(mode, s_title, t_simulate, timelimit)`。`"dialog"` では timer(開始 0.5 秒、間隔 0.25 秒)がダイアログを開き、新しい表示がない間もバーを動かす(MATLAB のコードの実行中も timer は割り込める: 実測でループ中 0.59 秒に発火)。
- `simulateFcn_mustBeProgress` を共有の検証関数 `mustBeProgress`(`@PowerNetwork/private`)に改名した。
- 解析の関数(`simulate` と 4 つの関数)は、データを集める前に `ProgressGUILDA` を作り、`sct_options.Progress` にそのオブジェクトを入れてソルバーに渡す。ソルバー(`SolverODE`・`SolverPF`・`SolverCPF`・`SolverOPF`)は、オブジェクトならそれを使い、モード文字列なら自分で作る(フィールドがなければ `"none"`)。
- `simulate` のダイアログは `build_simulation_data` の前から表示する。実測(IEEE68bus、2 秒のシナリオ)では `build_simulation_data` が約 1.1 秒、全体が約 3.7 秒で、以前は積分が始まるまでダイアログが出なかった。
- 潮流計算は Method クラスの `f_iter` に `update` を入れる(`PlotFcn` と併用時は両方を呼ぶ)。`MethodBase.f_iter` のアクセスに `?PowerNetwork` を加えた(`calculate_fixed_input_powerflow` が設定するため)。
- OPF は `fmincon` の反復記録の `OutputFcn`(`record`)から更新する。`linprog`/`quadprog` はソルバー名だけを表示する。

## 未確認・残り

- アプリの中のダイアログは `uiprogressdlg` が作られることをコードで確認した。`exportapp` はダイアログを写さないため、画面の画像は未取得。
- `DrawerGUILDA.run_code` の `Progress` メッセージ(不定の `uiprogressdlg`)と解析のダイアログが同時に出る場合の見え方は未確認。解析タブ(別ブランチ)では解析のコードに `run_code` の `Progress` を付けなくてよい。
