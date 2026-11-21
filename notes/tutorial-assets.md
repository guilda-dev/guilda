# チュートリアルの画像素材と埋め込み方

基準: ブランチ `docs/tutorial-assets`（`refactor/design-alignment` の `727a7924` から）、2026-11-18。

チュートリアル（`_GUILDAtutorial` の Step1〜12、Part0〜8、Main）の UX の改善（Main の流れ図と目次の表、全ページ末尾の前後ボタン、各 Step 冒頭の赤枠つきの流れ図、旧版のイラストの描き直し）のための共通の素材です。Step・Part・Main を書き直すセッションは、このメモを読んで素材を埋め込みます。

## 1. 置き場所

`_GUILDAtutorial/images/`。

- For Developer の folder-structure には画像の置き場所の規則がない。チュートリアルの付属データなので `_GUILDAtutorial/` の下に置いた。
- `_GUILDAtutorial` はパス上にある（`@GUILDA/config/ListPath.txt`）が、`images/` はそこに載らないのでパス外になる。中身は画像と SVG だけ。
- 名前はドキュメントの画像（`_GUILDAdocPages/images/tutorial/basic-workflow.ja.svg`、`main.gif`）に合わせて、小文字とハイフンにした。

## 2. 素材の一覧

PNG はすべて 2 倍の解像度で書き出した。ライブスクリプトでは「表示サイズ」の列の大きさ（`width`/`height`）で表示する。

| ファイル | PNG の大きさ | 表示サイズの目安 | 中身 |
|---|---|---|---|
| `button-prev.png`（`.svg`） | 480×128 | 210×56 | 「◀ 前のステップへ」。青の塗り（`#0059A7`）、白の文字、背景は透明 |
| `button-next.png`（`.svg`） | 480×128 | 210×56 | 「次のステップへ ▶」。同上 |
| `button-main.png`（`.svg`） | 480×128 | 210×56 | 「目次へ（Main）」。白地に青の枠と文字 |
| `workflow.png` | 1440×2064 | 480×688 | 基本的な流れの図（`_GUILDAdocPages/images/tutorial/basic-workflow.ja.svg` をそのまま PNG にしたもの）。Main 用 |
| `workflow-step1.png`〜`workflow-step12.png` | 1440×2064 | 480×688 | 基本的な流れの図に、その Step の部分の赤枠（`#D0312D`）と「Step N」の札を足したもの（3 節） |
| `bus-types.png`（`.svg`） | 1720×940 | 760×415 | 母線の種類（Slack・PV・PQ・機器のない母線）と、系統・母線・ブランチ・機器の積み木の図。各母線で決める量と求める量、どこで決まるか（`bus.l_isSlack = true`、発電機、負荷） |
| `model-structure.png`（`.svg`） | 1920×1224 | 760×485 | 系統モデルの中身の格納構造。`net` → `a_Bus{1}` → `a_Component{1}` → `a_LocalController{1}`（AVR）→ `a_LocalController{1}`（PSS）、`a_LocalController{2}`（ガバナ）、`a_Branch`、`a_GlobalController`、`a_Scenario` → `a_Event`。右に取り出し方（`gen.avr`、`gen.pss`、`gen.governor` など）、下に親へのたどり方（`a_PowerNetwork`、`a_Bus`、`a_Component`） |
| `controller-connection.png`（`.svg`） | 1840×1100 | 760×455 | 制御器の付き方と信号の向き。発電機に付くローカル制御器（PSS → AVR → `Vfield`、AVR は発電機の `Ifield` を観測、ガバナ → `Pmech`）と、系統に付くグローバル制御器（AGC が各発電機の `omega` を観測し、`Pmech` を出す）。駆動（実線）と名前での観測（破線）、同じ入力に入る出力の足し合わせ（⊕） |

名前と構造は 2026-11-18 の実物で確かめた（`PowerNetwork`・`Bus`・`Component`・`LocalController`・`GlobalController`・`Scenario` のプロパティ、`generator.abstract` の `avr`/`pss`/`governor`、各制御器の `sv_u`/`sv_y`（2026-11-18 の `ddc2f87a` で発電機の出力が `omega, Ifield`、avr-ST1 の入力が `Vref, Vpss, Ifield` になったのに合わせた）、`notes/controller-signal-routing.md` の GC の出力の振り分け）。旧版の画像は使っていない。

色はドキュメントの図と同じ（PowerNetwork 灰、Bus 橙、Branch 黄、Component 緑、制御器 青、Scenario 白）。PNG は 64 色に減色している（見た目は変わらず、大きさは約 1/3。workflow で 1 枚約 100 KB）。

## 3. 各 Step の赤枠

| Step | 赤枠で囲む部分（図の中の名前） |
|---|---|
| 1 系統と機器 | 「1 系統モデルの構築・読み込み」の区画全体と、「母線に機器を Key で追加」の箱 |
| 2 制御器 | 「3 制御器の追加（任意）」の区画全体 |
| 3 系統データの見方と編集 | 「1 系統モデルの構築・読み込み」の区画全体と、「潮流計算の条件を設定」〜「初期化」の 3 つの箱（パラメータの表と平衡点の値） |
| 4 潮流計算 | 「2 動作点の設定と初期化」の区画全体 |
| 5 時間シミュレーションの条件 | 「シナリオで外乱を定義」と「時間応答シミュレーション」の 2 つの箱（まとめて 1 つの枠） |
| 6 シミュレーションの結果 | 「時間応答シミュレーション」の箱 |
| 7 可視化 | 「潮流計算の解を確認（任意）」の箱と、「4 解析」の区画全体 |
| 8 近似線形化 | 「近似線形化」の箱 |
| 9 最適潮流計算 | 「最適潮流計算」の箱 |
| 10 連続潮流計算 | 「連続潮流計算」の箱 |
| 11 設定 | 図に設定の箱はない。設定が既定値を決める解析の箱（「潮流計算の解を確認」、「時間応答シミュレーション」、右列の「近似線形化」〜「最適潮流計算」）を囲んだ |
| 12 データの入出力 | 図に入出力の箱はない。入出力が関わる箱（「同梱の系統モデルを読み込み」＝フォルダからの読み込み、「シナリオで外乱を定義」＝シナリオの保存、「時間応答シミュレーション」＝結果の書き出し）を囲んだ |

Step11・12 は図の箱と 1 対 1 に対応しないので、使うかどうかは書き直すセッションが判断してよい（使わない場合は、冒頭の図を置かずに本文で説明する）。

## 4. 置く場所の案

### 全 Step・Part に共通

- **冒頭**（Step のみ）: タイトルと導入の直後、「この Step で分かること」の前に `workflow-stepN.png` を置き、「この Step は、GUILDA の基本的な流れの赤枠の部分です。」と 1 行添える（旧版の Step1・2・4・6 と同じ方式）。Part には流れ図を置かない（Part は解析の背景を学ぶテキストで、流れ図の段階と対応しないため）。
- **末尾**: 「まとめ」（と「次の Step」）の後に、ボタンを横に並べる: `button-prev` 　　 `button-main` 　　 `button-next`（間は全角空白 2 つ）。
  - Step: Step1 の前は Main、Step12 の次は Main（または Part0）。
  - Part: Part0 の前は Main、Part8 の次は Main。
  - 端では、無いほうのボタンを省いて `button-main` を置く。

### Main

- 冒頭の説明の後に `workflow.png`（表示 480×688、または 560×803）を置き、その下に目次の表を置く。

### イラスト

| 素材 | 置く場所の案 |
|---|---|
| `bus-types.png` | Step1 の「2. 系統を組み立てる」の冒頭（または「2.5 Slack 母線を決める」）。Part1 の「1. 系統をつくる 4 つの部品」と「5. 母線の種類：Slack・PV・PQ」 |
| `model-structure.png` | Step1 の「3.1 階層を表示する」（`disp_tree` の出力と並べる）。Step3 の「1. 部品を取り出す」の冒頭（「1.3 親へたどる」で再び参照） |
| `controller-connection.png` | Step2 の「4. ローカル制御器」の冒頭（「4.4 信号のつながりを確かめる」で再び参照）と「5. グローバル制御器」。Part1 の「8. 制御器：ローカルとグローバル」。Part8 の冒頭 |

図の例は特定の Key（`"gen-1axis"`、`"avr-ST1"`、`"pss-PSS1"`、`"gov-LPT1"`、`"agc-PI"`、`"load-power"`、`"pi"`）を使っている。本文のコードと Key が違うときは、「図は一例です」と添えるか、図に合わせる。

## 5. ライブスクリプトへの埋め込み方（R2026a で確認）

### `.m`（`%[text]` 形式）での書き方

```matlab
%[text] この Step は、GUILDA の基本的な流れの赤枠の部分です。
%[text] ![基本的な流れ（Step 1 の部分）](text:image:a001)
x = 1;
%[text] [![前のステップへ](text:image:b001)](matlab:open('Main.mlx'))　　[![目次へ](text:image:b003)](matlab:open('Main.mlx'))　　[![次のステップへ](text:image:b002)](matlab:open('Step2_ComponentController.mlx'))
%[appendix]{"version":"1.0"}
%---
%[text:image:a001]
%   data: {"align":"baseline","height":688,"src":"data:image\/png;base64,<PNG の base64>","width":480}
%---
%[text:image:b001]
%   data: {"align":"baseline","height":56,"src":"data:image\/png;base64,<PNG の base64>","width":210}
%---
```

- 本文では `![代替テキスト](text:image:<id>)` と書き、ファイルの最後の `%[appendix]` に、同じ id の `%[text:image:<id>]` ブロックを置く。`data` の `src` は PNG の base64（`base64 -i file.png | tr -d '\n'`）、`width`/`height` は表示サイズ（ピクセル）。
- id は 4 桁の 16 進で、ファイルの中で一意ならよい。MATLAB は保存し直すと id を振り直す（`a001` → `66e2` など）。
- 画像にリンクを付けるときは、画像の記法全体を Markdown のリンクで包む: `[![alt](text:image:<id>)](matlab:open('X.mlx'))`。
- 画像を横に並べるときは、同じ `%[text]` の行に続けて書く（間は全角空白など）。
- `%[appendix]` は 1 つだけで、ファイルの最後に置く。すでに appendix がある（`%[metadata:view]` など）ときは、その中にブロックを足す。

### リンクの書き方

- `.mlx` の中には `matlab:open('X.mlx')` のまま保存される（`docLocation="matlab:open('X.mlx')"`）。
- `.mlx` を `.m` に保存し直すと、MATLAB は `matlab:open('./X.mlx')` を `file:./X.mlx`、`matlab:open('X.mlx')` を `file:X.mlx` と書く。`file:./X.mlx` と書いた `.m` を `.mlx` にすると `matlab:open('./X.mlx')` に戻る。どちらで書いても同じ。
- 今の Main.mlx は `matlab:open('Part0_Introduction.mlx')` のように `./` を付けていない。`_GUILDAtutorial` はパス上にあるので、現在のフォルダーによらず開ける。ボタンもこれに合わせて `./` を付けない形を勧める（`./` 付きは現在のフォルダーからの相対パスなので、現在のフォルダーに依存する。旧版はこの形だった）。

### リファレンスへのリンク

決定（2026-11-19、`docs/step-structure-01-02`）。「ほかに xxx・yyy も指定できます」と並べる代わりに、メソッドの HTML リファレンス（`_GUILDAdoc/method.html`）へリンクする。`.m`（`%[text]` 形式）には次のように書く（`class` と `method` だけを差し替える）:

```matlab
%[text] その他のオプションは、`add_bus` のリファレンスで確かめられます: [その他のオプションはこちら](matlab:writelines("<script>location.replace('file://"+replace(fullfile(GUILDA.pwd,"_GUILDAdoc","method.html"),filesep,"/")+"#class=PowerNetwork&method=add_bus')</script>",fullfile(tempdir,"guilda_doc.html"));web(fullfile(tempdir,"guilda_doc.html"),"-browser"))（ブラウザで開きます）
```

- なぜ一時ページを経由するか: macOS では `web(<ファイル URL>, "-browser")` がハッシュ（`#class=...`）もクエリ（`?class=...`）も落とす（R2026a で、開いたページが自分の `location.href` を送る試しのページで確かめた）。`GUILDA.doc("class", ...)` の `open_class_page` と同じく、`tempdir` に置いた小さな HTML が `location.replace` で目的のページへ移る。
- `"\"` は Markdown のエスケープとして消えるので、区切り文字の置き換えには `filesep` を使う。
- クラスのページへリンクするときは `class.html#class=<クラス名>` にする（`method=` を付けない）。
- リファレンスのデータベース（`_GUILDAdoc/database/list_Classes.js`、git の対象外）は、`GUILDA` の起動時（`GUILDA.doc(update="auto", open=false)`）に作られる。作られていないとページは空になる。
- 確かめたこと（R2026a、2026-11-19）: `.m` → `.mlx` でリンクが `docLocation` にそのまま残る。リンクのコマンドを `eval` すると、一時ページを経てハッシュ付きの URL が開く（ハッシュが届く）。`method.html#class=PowerNetwork&method=add_bus` などをヘッドレス Chrome で開くと、そのメソッドのページ（引数の表）が描かれる。
- 確かめていないこと: Live Editor の画面でリンクをクリックしたとき（GUI の操作が要る）、Windows・Linux。

### `.mlx` への変換

- `matlab.desktop.editor.openDocument(<.m の絶対パス>)` → `saveAs(<.mlx の絶対パス>)` → `closeNoPrompt` で変換できる。エディタが必要なので、デスクトップ付きで起動する（MATLAB のウィンドウが開く）:
  `/Applications/MATLAB_R2026a.app/bin/matlab -nosplash -r "cd('<作業フォルダ>'); try, <変換スクリプト>; catch e, disp(e.message); end; exit" -logfile <ログ>`
- `-batch` では `openDocument` が「The MATLAB Editor is not available on the current platform.」で失敗する。`matlab.internal.liveeditor.openAndSave(src.m, dst.mlx)` は `-batch` でエラーにならないが、テキストをそのまま写すだけで `.mlx`（zip）にならない。`export` は旧形式の `.m` を書き、画像を落とす。

### 確かめたこと（R2026a 26.1.0.3203278、2026-11-18）

- `%[text]` 形式の `.m`（流れ図 1 枚とボタン 3 つ、リンク付き）を `openDocument` → `saveAs` で `.mlx` にすると、`matlab/media/` に PNG が 4 つ入り、`document.xml` に表示サイズ（`width`/`height`）、代替テキスト（`altText`）、リンク（`w:hyperlink w:docLocation="matlab:open(...)"` が画像を包む）が残る。
- その `.mlx` を開いて `.m` に保存し直すと、同じ構造の `%[text]` と appendix に戻る（往復で画像とリンクが残る）。
- 同じバイト列の画像は `.mlx` の中で 1 つにまとめられる。
- 試しの `.mlx` はコミットしていない。

### 確かめていないこと

- Live Editor の画面でボタンをクリックして、目的のファイルが開くこと（GUI の操作が要るため）。
- ダークテーマでの見え方（PNG の背景は白、ボタンは背景が透明）。
- R2025a での変換（最小バージョン。`%[text]` 形式は R2025a から）。

## 6. 作り直し方

- ボタンとイラストは、同じ名前の `.svg` を直して PNG にする。流れ図の PNG は `_GUILDAdocPages/images/tutorial/basic-workflow.ja.svg` から作る（赤枠は、`</svg>` の前に枠の `<rect>`（`stroke="#D0312D"`、`stroke-width="3.5"`、`fill="none"`、箱から 4px 外）と札を足す。座標は 3 節の箱のもの）。ドキュメントの図が変わったら作り直す。
- PNG にするのはヘッドレス Chrome（日本語のフォントがそのまま使える）:
  `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --window-size=<幅>,<高さ> --screenshot=<out.png> file://<in.svg>`（ボタンは `--default-background-color=00000000` で背景を透明に）。その後 `magick <out.png> -colors 64 -strip -define png:compression-level=9 <out.png>`（ボタンは減色しない）。
- 生成に使った Python のスクリプトはコミットしていない（開発者用のスクリプトの置き場所 `_GUILDAsystem/_admin/` はこの作業の範囲外のため）。置くかどうかは未決。

## 7. チュートリアルタブの GIF（`main.gif`）

ドキュメントのチュートリアルタブ（`_GUILDAdocPages/index.html` の `#tab-tutorial`）に置く GIF は 1 つだけで、Step0（Main.mlx、`#main_mlx`）の枠の右に出します。Step1〜12 の行には GIF を置きません（1 行ごとの `step<N>.gif` は 2026-11-19 に削除）。Part のカード（`#lecture-list`）にも GIF を置きません（折りたたみの録画 `part<N>.gif` は 2026-11-19 に削除）。

- 中身: MATLAB R2026a のデスクトップ（英語版）で Main.mlx を Live Editor に開き、上から下へスクロールしているイメージ図です。実物の画面の録画ではありません。配置と色は Getting Started の録画 `_GUILDAdocPages/images/getting-started/start-guilda.gif`（実物の R2026a、日本語版）の後半のコマに合わせました。
  - 一番上: macOS のタイトルバー（MATLAB R2026a）と紺の帯のタブ（Home / Plots / Apps / Live Editor / Insert / View、Live Editor が選ばれた状態）、右に検索の欄。
  - リボン: FILE・NAVIGATE・TEXT・CODE・ANALYZE・SECTION・RUN のグループと、New・Open・Save・Run Section・Run などのボタン。アイコンは簡単な図形の SVG で、MathWorks のロゴや画像は使っていない。
  - アドレスバー（`GUILDA ›`）、左に Files（リポジトリ直下のフォルダ）と Workspace（`ans`、`1x1 GUILDA`）、中央にエディター（`Main.mlx` のタブ、Live Script の青い縦線、右に出力の欄）、右に Command Window（`GUILDA` を実行したあとの出力と `>> open _GUILDAtutorial/Main.mlx`）、一番下にステータスバー。
  - 中央の Main.mlx の中身は、Main.mlx の目次（題、基本的な流れの図、Step1〜12 の表、Part0〜8 の表、参考資料、「まず動かしてみる」、「はじめる」）を英語に訳したものです。英語版を作る予定があるので、日本語のページにも同じ GIF を使います。
- 元のファイル: `notes/tutorial-gif/main-mock.html`（モック。流れの図は `_GUILDAdocPages/images/tutorial/basic-workflow.en.svg` を読み込む）と `notes/tutorial-gif/make-main-gif.mjs`（GIF を作るスクリプト）。
- 作り方（リポジトリの直下で）: `node notes/tutorial-gif/make-main-gif.mjs`。引数は順に 1 コマに動かす px（既定 4）、fps（既定 30）、色の数（既定 64）。Google Chrome と ffmpeg（`/opt/homebrew/bin/ffmpeg`）が要ります。
  1. ヘッドレス Chrome でモックを 960×600 で開く。
  2. モックの `setScroll(y)` で、中央の文書（`#doc`）だけを少しずつスクロールし、1 コマずつ PNG に撮る。ほかの部分は動かない。先頭で 1.2 秒止まり、0.6 秒かけて速くなり、一定の速さで進み、0.6 秒かけて遅くなり、最後で 1.8 秒止まる。GIF はそのまま先頭に戻ってループする。
  3. ffmpeg の `palettegen`（全コマから 64 色）と `paletteuse`（ディザなし、`diff_mode=rectangle`）で GIF にする。
- 今の GIF: 960×600、30 fps、1 コマ 4 px（120 px/秒）、491 コマ、16.4 秒、4.5 MB。
- 大きさについて: GIF は変わった部分だけを書くので、動くのは中央の文書の部分（約 330×440）だけになるようにしてあります。それでも文字のアンチエイリアスがあると 1 コマ約 20 KB かかるので、中央の文書だけアンチエイリアスを切り（`-webkit-font-smoothing: none`）、字の間隔が崩れない Lucida Grande で書いています。周りの動かない部分はアンチエイリアスありのままです（試した値: 中央もアンチエイリアスありで 1 コマ 8 px のとき 5.1 MB、なしで 6 px のとき 3.2 MB、4 px のとき 4.5 MB）。小さくするには、1 コマの px を増やします。
- 手本と見比べるには、手本のコマを `ffmpeg -i start-guilda.gif -fps_mode passthrough r%02d.png` で取り出し、新しい GIF のコマと並べます。
- Main.mlx の目次が変わったら、モックの表と文を直して作り直します。
