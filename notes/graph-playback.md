# 図の再生バー(PlaySpeed、play、pause)

基準: ブランチ `feature/graph-playback-bar`(`refactor/design-alignment` の 8f271d33 から分岐)、2026-11-20。実装済みです(マージ前)。

関連: [graph-base.md](graph-base.md)(GraphBase の約束)、[graph-diagram-2d.md](graph-diagram-2d.md) §5(操作パネル。§5.4 の時刻の行はこの変更で廃止)。

## 0. ユーザーの要望と決定(2026-11-20)

要望: 「解析結果クラスで plot_diagram を実行しても再生が始まりません。再生ボタンも備えた Figure としてプロットしてしまった方がいいと思います。GUI の Display の項目の一番下にありますが、上記の実装ができるならこの枠からは削除してしまっていいと思います。あと再生速度の調整機能もほしいです。」

決定(Graph の取りまとめのセッション経由):

- **Q1 範囲。** 標本が 2 つ以上ある GraphBase のすべてのサブクラス(ネットワーク図、ばね質点、GraphNetMap、GraphMatrix、時刻のある GraphChart)に再生バーを付ける。
- **Q2 置き場所。** バーは常に図の下。新しい figure にも、`Parent` で渡した容器(GUI の図の区画)にも付ける。`show_controls` のパネルからは時刻の行(`"time"` の部品、`"<time>"` の行)を全クラスで削除する。1 標本の図にはバーを付けない。
- **Q3 自動再生。** しない。バーの Play で始める。
- **Q4 速度。** バーに速度のドロップダウン(0.1×、0.25×、0.5×、1×、2×、5×、10×)。新しい公開プロパティ `PlaySpeed`(既定 1)とドロップダウンは同じ値を示し、一覧にない値はそれだけの項目として出す。`animate` は `Speed` を渡さないとき `PlaySpeed` を使う。
- **Q5 play/pause。** 公開メソッド `play()` と `pause()` を足す。`play` はバーの Play と同じ timer の再生を始めてすぐ戻り、`pause` で止める。`animate` は今のまま(戻らない再生)。
- 新しい公開メンバーは `PlaySpeed`、`play`、`pause` だけ。
- GUI の取りまとめの条件: (a) figure を閉じる、軸を消す、図を置き換える(同じ容器に別の図を描いて前の図を消す)のどれでも timer を止めて消す。(b) `matlab -batch` と見えない figure では timer を作らない(FlowAnimation と同じ規則)。バーとスライダーは動く。(c) バーの部品すべてに決まった `Tag` を付ける。

## 1. 作り

- 部品は `uipanel` の中の `uigridlayout` に `uibutton`(state)、`uislider`、`uilabel`、`uidropdown` です。R2026a では `figure` の中にも UI 部品を置けるので(確かめました)、`figure` と uifigure の容器で同じ部品を使います。`uicontrol` は使いません。
- バーは tiledlayout の容器(`ax(1).Parent.Parent`)に置きます。tiledlayout の `OuterPosition` を `[x b w 1−b]`、バーを `[x 0 w b]` にします(b = 34 px ÷ 容器の高さ、上限 0.9)。x と w は tiledlayout のものを使うので、`show_controls` を軸の横に出すとバーも軸の幅になります。容器の `SizeChanged` と tiledlayout の `MarkedClean` のリスナーで置き直します(単位・位置・表示が同じなら設定しません。設定すると描画が繰り返されます)。
- 図の大きさを変えるとバーが縦に伸びることがありました(`fix/playback-bar-fixed-height`)。原因は、正規化単位の b を `SizeChanged` でしか置き直さなかったのに、見えない figure、uifigure・uipanel(`AutoResizeChildren` が on)、uigridlayout のセルのパネルでは `SizeChanged` が来ず、さらに uigridlayout ではセルの配置前の仮の高さで b を決めていたことです。描くたびに来る tiledlayout の `MarkedClean` でも置き直すようにし、描画時に読んだ大きさが古いときは後の `SizeChanged` で直ります。F100 に大きさを小→大→小と変える節を足しました。
- 軸を渡した図(`Parent` が axes)にはバーを付けません。使う人の軸の配置を変えないためです。
- private のメソッド: `refresh_bar`(作る・消す・合わせる)、`place_bar(l_hide)`(置く・隠す)、`play_bar(l_play)`(timer の開始・停止)。protected の `has_playback`(基底は 2 標本以上、GraphChart は時刻で変わる図だけ。前の `control_list` の時刻の条件と同じ)。
- 呼ぶ所: `build` の最後、`set_time` の各図、`set_data` の最後、`animate` の前後、`PlaySpeed` の setter、再生の 1 こま。
- timer: Tag `GUILDA:GraphBase:Playback`、`fixedSpacing` で 0.04 s ごと、`BusyMode` drop。1 こまで `t = r_playFrom + toc(u_playTic) × PlaySpeed` の標本を `set_time` で出し、最後の標本で止めて消します。再生中に `PlaySpeed` を変えると、その時点の位置を新しい起点にします。名前のある標本(ステップなど)は標本値を時刻と同じに扱うので、1 倍で毎秒 1 標本値です(`animate` と同じ)。
- 止める所: Pause / `pause()`、最後の標本、軸の `ObjectBeingDestroyed` のリスナー(figure を閉じる、軸を消す、GUI が容器を空にする)、図の `ObjectBeingDestroyed`(`build` で付ける。`delete(G)`)、1 こまで図か軸がなくなっていたとき(timer が自分を消す)。timer とリスナーは図を `matlab.lang.WeakReference` で持ちます。
- 作らない所: 再生中(`l_animating`。timer でも `animate` でも)、1 標本、`batchStartupOptionUsed`、figure が見えない。このときボタンを押しても `refresh_bar` が Play に戻します。
- `animate`: 始める前にバーの再生を止め、再生中は `l_animating` でボタンを Pause にします。バーの Pause は前と同じく `l_stopAnimate` で次のこまに止めます。`pause()` も、`animate` の再生中ならこのフラグを立てます。
- `export_video`: 書き出す間 `place_bar(true)` でバーを隠して軸を下まで広げ、`onCleanup` で戻します。軸の `exportgraphics` にはもともと入りません。figure の `exportgraphics` も UI 部品を含めません(R2026a の警告が出ます)。
- バーの Tag: `GUILDA:GraphBase:PlaybackBar`(uipanel)、`GUILDA:GraphBase:PlaybackGrid`(uigridlayout)、`GUILDA:GraphBase:Play`(状態ボタン)、`GUILDA:GraphBase:TimeSlider`、`GUILDA:GraphBase:TimeText`(uilabel)、`GUILDA:GraphBase:PlaySpeed`(uidropdown、`ItemsData` が速度)。
- パネル: `show_controls` から `"time"` の部品、`TimeChanged` のリスナー、時刻の行の出入りでの作り直し、`on_play` を除きました。`control_list` に `"time"` を書くと `GUILDA:GraphBase:ControlWidget` です。GraphChart のパネルは「No controls for this graph.」だけになります。
- メッセージ: `GUILDA:GraphBase:PlaybackTimer`(1 こまのエラーで止めたときの警告)。
- 窓を閉じると `GUILDA:GraphBase:PlaybackTimer` の警告が出ることがありました(`ResultOPF.plot_iteration` の自動再生中の結果の窓で 40 回に 21 回。「ターゲットが無効です」「1 番目の引数は、有効な axes ハンドルでなければなりません」など)。原因は FlowTimer と同じで、MATLAB が figure の削除の途中で待っている `play_tick` を実行し、軸が figure から外れたり消える途中だったりする状態で `set_time` が描いた(多くは `TimeChangedFcn` の `title`)ことです。
- `play_tick` は、図・軸がないときに加えて、figure が空・無効・`BeingDeleted` が on、軸の `BeingDeleted` が on のときも、警告なしで timer を止めて消します(ローカル関数 `is_gone`)。catch でも同じ条件を確かめ直し、成り立てば警告を出しません。figure が生きている間のエラーは今までどおり警告します。F100 に 1 件を足しました(`fix/playback-timer-close-warning`)。

## 2. テスト

- 新しい `+DebugScript/test_F100_graph_playback.m`(F98、F99 は使用済み)。分類 graph。バーの有無(2 標本以上・1 標本・set_data での出入り・軸を渡した図・新しい figure)、set_time・link・スライダー・set_data、Play/Pause と timer、二重に再生しない、`PlaySpeed` とドロップダウン、`play`/`pause`(すぐ戻る、速さ、二重、最後で止まる)、timer の後始末(figure を閉じる・軸を消す・置き換える・delete(G)・出力を受け取らない図)、`-batch` と見えない figure、`animate` の間の Pause、uifigure の uipanel・uigridlayout・uitab、パネルに時刻がない、`export_video` と `exportgraphics`、部品の Tag。
- timer を確かめる節は、F61 と同じく `batchStartupOptionUsed` を false を返す関数で隠し、見える figure に描きます。`-batch` の節は隠さずに確かめます。
- 時刻の操作をパネルで確かめていた F46、F48、F61、F82、F84、F97 はバーで確かめるように直しました。
- 注意: スクリプト形式のテストの共有の節は 1 回だけ走るので、共有の `fig` に描くと前の節の図とバーが残ります。F100 は節ごとに figure を作り、ほかのテストでは `uipanel(fig)` の中を探します。

## 3. ほかのセッションへの影響

- `DrawerResultGUI/autoplay.m` と `test_F91_result_gui_autoplay.m`(GUI の取りまとめ): パネルの Play がなくなったので F91 の「Play ボタンが Pause を示す」節は失敗します。`autoplay` は `G.play()` に替える予定です(GUI の取りまとめが行う)。
- `ResultOPF/plot_iteration.m`: 2 つの uipanel に描く GraphChart と GraphNetDiagram にそれぞれバーが付き、自前の Play とスライダー(uicontrol)と並びます。自前の部品を外してバーに任せるか、どちらかの図だけにバーを残すかは未決です。
