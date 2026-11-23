# 講義ノート（`_GUILDAdocPages/lecture/`）の書き方

基準: ブランチ `docs/lecture-notes-base`（2026-11-16）、改訂の土台はブランチ `docs/lecture-notes-revise-base`（2026-11-17）。

2026-11-20 から、講義ノートとその画像はサイトのリポジトリ guilda-dev/guilda-doc（サブモジュール `_GUILDAdocPages`）にあり、そこでコミットします（[docs-repo-split.md](docs-repo-split.md)）。以下の場所はこの移動に合わせて書き換えています。

GUILDA の講義ノート（全 9 Part、1 Part ＝ 1 ページ）の作業ノートです。講義動画を公開するかは未定なので、ページは講義ノートとして単独で読めるように書き、動画には触れません。ページは電力系統工学の知識を説明するもので、スクリプトの使い方の説明ではありません。Part1〜8 の本文を書くセッションは、このメモだけを読めば書き始められるようにしています。

## 1. 決まっていること

- 対象は初学者です。図と直感的な説明を中心にし、式は説明の芯になるものだけを正確に書きます（下の「数式の方針」）。
- 可視化（図）は各 Part で積極的に見せます。
- 細かいオプション設定はライブスクリプトの注意書きに回し、知識ページでは扱いません。
- 演習や受講者からの受け付けはありません（説明と実演だけ）。
- Part2 以降のライブスクリプトは同梱の IEEE9bus から始めて単独で見られるようにする予定です。ページも、ほかの Part を前提にしすぎない書き方にします（「Part N で説明したように」に頼らず、必要なことは短く言い直す）。
- 各 Part に対応するライブスクリプト（`_GUILDAtutorial/PartN_*.mlx`）があり、ページの「関連する Part とライブスクリプト」の欄で案内します。スライドは別の機会に作ります。

### 改訂の方針（2026-11-17、ユーザー依頼と訂正）

内容は高く評価されたうえで、次の点を全ページで直します。Part0 は改訂済みで、見本になります。

1. **ライトモードに統一**: 講義ノートもドキュメントページ（For Developer）と同じ配色・レイアウトです。OS のダークテーマには従いません（§4）。
2. **数式を少しだけ増やす**: 説明の芯になる式を正確に書きます（下の「数式の方針」）。
3. **GUILDA のコードはコマンドブロック**: 本文の「GUILDA で確かめるときは…」のコードは、文中の `<code>` ではなく `pre.lec-cmd` のブロックにします。続けて実行するコマンドは 1 つのブロックにまとめます（§4）。
4. **図はイメージ図（SVG）とグラフ（MATLAB）に分ける**（ユーザーの訂正、2026-11-17）: 電力系統のモデル図、系統図、ブロック線図、流れ図などのイメージ図（ふつう MATLAB のプロットで作らないもの）は、ページ内の SVG で描きます。数値の関係や時間応答などのグラフは、対応する Part のライブスクリプト（`_GUILDAtutorial/PartN_*.mlx`）で描いた PNG にします。グラフはできる限り GUILDA の機能で描きます（§5）。
5. **グラフを描くコードはライブスクリプトに置く**: 知識ページのグラフは、対応する Part のライブスクリプトを実行すると描けます。ページには描いたコードへのリンクを付けません（ページの「関連する Part とライブスクリプト」の欄で、その Part のライブスクリプトを案内します）。
6. **図の枠は白**: 図は白い背景に細い枠の箱で、説明（`figcaption`）の上に細い罫線が入ります。SVG にも PNG にも同じ枠を使います（`style.css` が描くので、ページ側の作業はありません）。

一度「すべての図を MATLAB で」として、イメージ図を MATLAB で描き直したものがあります。それらは改訂前の SVG に戻し、その PNG を削除します（手順は §5.6）。

### 数式の方針

- 説明の芯になる式だけを、正確に書きます。記号はすべて本文で意味と単位を説明します。
- 曖昧な式（「だいたいこういう関係」を式の形にしたもの）、飾りの式（本文で使わない式）は書きません。近似を含む式は、何を省いたかを一言添えます（例: 「制御と負荷の周波数特性を除くと、近似的に」）。
- 量の目安（ユーザー了承済み）: Part1 は π 型等価回路とアドミタンス行列、Part2 は電力方程式とニュートン法の更新式、Part3 は動揺方程式、Part5 は線形化の式、Part7 はヤコビアンによる感度の式。Part0 は需給と周波数の関係（系統全体の動揺方程式）の 1 本だけです。ほかの Part は今の式のままでかまいません。
- 書き方は KaTeX です（§4 の `lec-math` / `lec-math-inline`）。`data-tex` の中では `\mathrm{d}`（微分の d）、添字の名前は `P_\mathrm{G}` のように立体にします。HTML の属性の中なので `"` は使わず、`<` `>` は `\lt` `\gt` と書きます。
- 式は日英で共通なので、`lang` を付けずに 1 つだけ置きます。式の前後の文は日英で書きます。
- 式を図の計算に使ったときは、図の関数のヘルプに同じ式を書き、図の説明（`figcaption`）で「上の式から求めた」と書きます（Part0 の `#balance` が見本）。

### ドキュメント共通の規則（For Developer のページと同じ）

- 1 つの HTML ファイルに日英を併記します。`<span lang="en">…</span><span lang="ja">…</span>`、または段落ごとに `<p lang="en">` と `<p lang="ja">` を並べます（`doc-lang.js` が表示しない側を隠します）。
- 日本語の本文は「です・ます」で書きます。
- 版の履歴の書き方（「〜から変わった」「新しく〜」）はしません。時間に依らない書き方にします。
- 用語: 連続潮流計算（「連続型」とは書かない）、グローバル制御器／ローカル制御器（「広域」「大域」「局所」とは書かない）。Part5 の振動モードの「局所モード」のように、電力系統工学の用語として定着しているものは、制御器の呼び名とは別なので使ってかまいません。
- GUILDA の機能について書くときは、実装済みのものだけを書きます。
- 2 列のレイアウトで不自然な折り返しが起きないようにし、広い画面での表示にも配慮します。

## 2. ファイルと担当

| もの | 場所 | 誰が触るか |
|---|---|---|
| Part ごとのページ | `_GUILDAdocPages/lecture/partN-<slug>.html` | その Part のセッションだけ |
| Part ごとの画像 | `_GUILDAdocPages/images/lecture/partN/` | その Part のセッションだけ |
| Part ごとのグラフを描くコード | `_GUILDAtutorial/PartN_*.mlx`（その Part のライブスクリプト） | その Part のセッションだけ |
| 共通の CSS（`lec-*`） | `_GUILDAdocPages/style.css` の「Lecture notes」の節 | 土台のセッションだけ。後続のセッションは触らない |
| 数式とコマンドの表示 | `_GUILDAdocPages/lecture/lecture.js` | 土台のセッションだけ |
| 一覧のデータ | `_GUILDAdocPages/database/list_Lectures.js` | coordinator（マージのときに `ready` を切り替える） |
| 一覧の表示 | `_GUILDAdocPages/index.html`（チュートリアルタブの「講義ノート」） | 触らない |

ファイル名（決定済み・作成済み）:

| Part | ファイル | 題 |
|---|---|---|
| 0 | `part0-introduction.html` | 導入（本文あり） |
| 1 | `part1-network-components.html` | 電力系統の作成と機器の種類 |
| 2 | `part2-power-flow.html` | 潮流計算 |
| 3 | `part3-time-simulation.html` | 時間シミュレーション |
| 4 | `part4-spring-mass-model.html` | 可視化機能：ばね質点モデル |
| 5 | `part5-linearization.html` | 近似線形化 |
| 6 | `part6-optimal-power-flow.html` | 最適潮流計算と定態安定度制約付き OPF |
| 7 | `part7-continuation-power-flow.html` | 連続潮流計算と電力方程式のヤコビアン |
| 8 | `part8-controller-design.html` | 制御器の設計と自作の方法 |

9 ページとも共通の型で作成済みです。Part1〜8 は本文の代わりに「準備中」の表示が入っています。

### 一覧の「準備中」の切り替え

チュートリアルタブの一覧は `list_Lectures.js` から作ります。`ready: false` の Part はリンクなしで「準備中」と表示され、`ready: true` にするとリンクになります。後続のセッションはこのファイルを触りません。coordinator が、その Part のブランチをマージするときに `ready` を `true` にします（1 行の変更）。題や概要を変えたい場合は、報告でその文面を coordinator に伝えてください。

## 3. ページの書き始め方

自分の Part のファイルを開くと、共通の型が入っています。次の順で置き換えます。

1. `<section class="lec-goals" id="goals">` の `<li>` を、「このPartで分かること」の箇条書き（3〜5 個）に書き換えます。
2. `<div class="lec-draft">…</div>`（「このページは準備中です。」）を消し、その位置に本文の節を `<section id="…">` で並べます。節ごとに `<h2>` を 1 つと、できるだけ図を 1 つ置きます。
3. 目次 `<nav class="lec-toc">` のコメント `<!-- one <li> per body section … -->` の位置に、本文の節の `<li>` を同じ順で入れます。目次の文言は、1440px 以上の画面で本文の右に出る欄（幅 228px、ドキュメントページの「このページの内容」と同じ）で 1 行に収まる短さにします（日本語で 14 字程度まで、英語で 24 字程度まで）。共通の項目「関連する Part とライブスクリプト」だけは 2 行になりますが、そのままにします。
4. 「まとめ」（`#summary`）の「準備中」を箇条書きに書き換えます。
5. 「関連する Part」（`#related` のカード）は仮の組み合わせが入っています。内容に合わせて増減してかまいません。ライブスクリプトの行には、その Part のライブスクリプトを書きます。
6. 「参考文献」（`#references`）の「準備中」を `<ol class="lec-refs">` に書き換えます（書き方は Part0 を参照）。
7. ページ固有の CSS が要るときだけ、`<head>` の `<style>` に接頭辞 `lecN-`（例: `lec3-`）を付けて書きます。共通にしたいものがあれば、`style.css` は触らずに報告で提案してください。

変えないもの: 上の戻るボタン（`../index.html#tab-tutorial`）、`Part N / 8` の表示、下の前後の移動（`lec-pager`）、`<head>` の読み込み（`doc-lang.js`、`style.css`、KaTeX）、末尾の `lecture.js`。

`<title>` は `GUILDA Lecture Notes - Part N: <英語の題>` で、`data-title-ja` に日本語の題が入っています。

## 4. 使える CSS クラス（`style.css` の `lec-*`）

`<body class="lec">` のページだけに効きます。講義ノートは、ドキュメントページ（For Developer）と同じライトの配色とレイアウトです。OS のダークテーマには従いません。

- 共通の部分: 背景（`--surface-subtle`）、本文の白い枠（`main` の最大幅 900px、余白も同じ）、見出し（`h1`、`h2` は上の罫線と 1.45rem）、表、文中の `code`、`pre`、言語の切り替えは、ドキュメントページと同じ作りです。
- 目次（`lec-toc`）: 1440px 未満は本文の上に置いた枠、1440px 以上はドキュメントページの「このページの内容」と同じ位置（本文の右、幅 228px）に固定して出ます。
- 講義ノート固有の部品（目次、ページ送り、カード、まとめ、補足の枠）の色は、ドキュメントページの変数（`--brand`、`--ink`、`--line` など）で決まります。色は必ず変数かクラスで指定し、`#fff` などの直書きはしません。

| クラス | 用途 |
|---|---|
| `lec-goals` | 「このPartで分かること」の枠 |
| `lec-summary` | 「まとめ」の節 |
| `lec-callout` | 補足の枠（左に橙の線）。`is-key` を付けると要点の枠（青） |
| `lec-terms` | 用語と説明の 2 列の `dl`（狭い画面では 1 列）。用語の欄は 11rem |
| `lec-split` | 文と図を左右に並べる 2 列（900px 以上だけ）。図が小さくなりすぎるので、文字の多い図や横長の図には使わない |
| `lec-figure` | 図の枠（`figure`）。白い背景、細い枠、説明の上に細い罫線。中にイメージ図の SVG（`<svg class="lec-svg">`）か、グラフの PNG（`<img>`）を置く。説明は `figcaption` を `lang="en"` と `lang="ja"` の 2 つ置く |
| `lec-figure is-scroll` | 中に `<div class="lec-scroll">` を置き、その中に SVG か `<img>` を入れる。狭い画面では図を縮めずに横スクロールにする。最小幅は `style="--lec-min-w: 560px;"` で指定（§5） |
| `lec-figure is-compact` | 小さな図が広がりすぎないように最大幅を 560px にする（`--lec-fig-max` で変更可） |
| `lec-cmd` | MATLAB のコマンドのブロック。`<pre class="lec-cmd"><code>` の中に 1 行に 1 つずつコマンドを書く。`lecture.js` が各行の前に `>>` を付け（コピーには含まれない）、クリックでブロック全体が選択される |
| `lec-math` | 別行の数式。`<div class="lec-math" data-tex="P = \frac{V_1 V_2}{X}\sin\delta"></div>` |
| `lec-math-inline` | 文中の数式。`<span class="lec-math-inline" data-tex="\delta"></span>` |
| `lec-cards` / `lec-card` | Part へのリンクのカード（`ul.lec-cards > li > a.lec-card`、中に `small`（Part 番号）と `b`（題）、必要なら `span`（説明））。`is-c2`〜`is-c4` で上の線の色を変える |
| `lec-pending` | 「準備中」の小さな札 |
| `lec-refs` | 参考文献の `ol`。書名は `cite`、補足は `span.lec-ref-note` |

「GUILDA で確かめるときは…」のコードは、文中の `<code>` に入れず、説明の文（日英）のあとに `pre.lec-cmd` のブロックで書きます。続けて実行するコマンドは、1 行ずつ別のブロックにせず、1 つのブロックに改行で並べます。ブロックには、そのままコマンドウィンドウに貼って動くコマンドだけを書きます（`>>` は書かない。コメントや出力も書かない。結果の値に触れるときは本文に書く）。実行できることを R2026a で確かめてから書きます。メソッドの名前に触れるだけの文中の `<code>`（例: 「`ResultPF` の `plot_voltage` が描きます」）はそのままでかまいません。コマンドではない例（関数の定義など）は、ふつうの `<pre><code>` にします。

```html
<p lang="en">To see such a mesh in GUILDA, load the bundled IEEE 68-bus system and draw its buses and branches:</p>
<p lang="ja">GUILDA で確かめるときは、同梱の IEEE 68 母線系統を読み込み、母線とブランチを図にします。</p>
<pre class="lec-cmd"><code>net = network.IEEE68bus();
net.plot_diagram();</code></pre>
```

`</code></pre>` の前で改行しません（空の行ができるため。`lecture.js` は末尾の空行を除きますが、書かないのが確実です）。改訂の途中で 1 行ずつのブロックが続いているページは、続くブロックの間が詰まって表示されますが、改訂のときに 1 つにまとめます。

イメージ図の SVG のクラス（`lec-svg` と `t-*`、`s-*`、`f-*`、`m-arrow`）は §5.2 にあります。

数式は `lecture.js` が `data-tex` を KaTeX（`_GUILDAdocPages/vendor/katex/`、`file://` でも動く）で描きます。数式は日英で共通なので、`lang` を付けずに 1 つだけ置きます。

## 5. 図の描き方

### 5.1 イメージ図とグラフの線引き

| 種類 | 例 | 描き方 |
|---|---|---|
| **イメージ図** | 電力系統のモデル図、系統図、等価回路、ブロック線図、流れ図、講義の地図、設備の模式図 | ページ内の SVG（§5.2）。MATLAB では描かない |
| **グラフ（GUILDA で描けるもの）** | 時間応答、潮流の結果、固有値、PV カーブ、LMP、ばね質点モデルの図 | Part のライブスクリプトで、GUILDA の `plot_*` を使って描いた PNG（§5.3〜5.5） |
| **グラフ（GUILDA にない概念）** | P–δ 曲線、ニュートン法の反復、等面積法、時間スケールの比較、ヤコビアンの感度の模式 | Part のライブスクリプトで、MATLAB の計算とプロットで描いた PNG |

迷ったときの目安: 軸に量と単位があり、数値が計算で決まるものはグラフです。箱と矢印で関係を示すもの、ものの形や配置を示すものはイメージ図です。

### 5.2 イメージ図（SVG）の書き方

イメージ図はページ内の SVG で描きます。改訂前のページの SVG はこの書き方で作ってあり、そのまま使えます（ライトモードだけの今の配色でも読めることを Part0 で確かめ済み）。

基本の形（Part0 の「発電所から需要家まで」の図が見本になります）:

```html
<figure class="lec-figure is-scroll" style="--lec-min-w: 620px;">
  <div class="lec-scroll">
    <svg class="lec-svg" viewBox="0 0 780 240" role="img" aria-label="英語の短い説明">
      <defs>
        <marker id="p3-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path class="m-arrow" d="M0 0 L10 5 L0 10 Z"/></marker>
      </defs>
      <rect class="f-brand" x="20" y="20" width="140" height="60" rx="5"/>
      <text lang="en" class="t-strong" x="32" y="56">Power flow</text>
      <text lang="ja" class="t-strong" x="32" y="56">潮流計算</text>
      <line class="s-ink" x1="160" y1="50" x2="220" y2="50" marker-end="url(#p3-arrow)"/>
    </svg>
  </div>
  <figcaption lang="en">…</figcaption>
  <figcaption lang="ja">…</figcaption>
</figure>
```

- 文字は日英で別の `<text>` 要素にし、`lang="en"` と `lang="ja"` を付けます（`<tspan>` では切り替えません）。数字や記号だけの文字は `lang` なしで 1 つ置きます。
- `marker` などの `id` は、ページ内で重ならないように `pN-` を付けます（例: `p3-arrow`）。
- 幅は `viewBox` の横 600〜780 を目安にします。文字は 12〜15px（クラスの既定は 14px）。横長の図には `is-scroll` を付け、`--lec-min-w` を「文字が 10px 程度より小さくならない幅」にします（viewBox 780 なら 620〜640px）。
- 英語の文は日本語より長くなりやすいので、両方の言語で箱からはみ出さないか確かめます。

SVG で使えるクラス（色はドキュメントページの変数に従います）:

| 種類 | クラス |
|---|---|
| 文字 | `t-strong`（太字）、`t-muted`（灰色・小）、`t-small`（12px）、`t-brand` / `t-c2` / `t-c3` / `t-c4`（色付きの太字）、`t-mid` / `t-end`（中央・右寄せ） |
| 線 | `s-line`（薄い線）、`s-ink`（本文色）、`s-brand` / `s-c2` / `s-c3` / `s-c4`（色付き）、`is-dashed`（破線） |
| 面 | `f-card`（白い箱）、`f-brand` / `f-c2` / `f-c3` / `f-c4`（淡い色の箱と枠）、`f-group`（破線の枠のグループ）、`f-tint`（淡い青の帯）、`f-bg`（図の背景と同じ白）、`f-ink` / `f-brand-solid`（塗りつぶし） |
| 矢印 | `marker` の中の `path` に `m-arrow` |
| 色を直接使う | `fill="var(--lec-c2)"` のように変数で指定（`--brand`、`--lec-c2`〜`--lec-c4`、`--ink`、`--muted`、`--line-strong`） |

色の使い分けの目安: `brand`（青）＝主役・GUILDA の量、`c2`（緑）＝動的な現象・時間応答、`c3`（橙）＝比較の相手・静的な解析、`c4`（紫）＝制御。

### 5.3 グラフの描き方（Part のライブスクリプト）

知識ページのグラフは、対応する Part のライブスクリプト（`_GUILDAtutorial/PartN_*.mlx`）で描きます。描いた図を PNG に書き出し、`_GUILDAdocPages/images/lecture/partN/` に置きます。グラフを描くためだけの関数やスクリプトを別に置くことはしません。受講者がライブスクリプトを実行すれば、ページと同じグラフが手元で描けるようにするためです。

| もの | 決まり |
|---|---|
| 描く場所 | 対応する Part のライブスクリプトの中。ページの節と同じ順で、本文の流れの中で描く |
| 書き出し | ライブスクリプトを R2026a で実行して描いた図を、`exportgraphics(fig, file, Resolution=200, BackgroundColor="white")` で PNG にする。書き出しのコードはライブスクリプトに入れない（受講者のフォルダに画像を書かないため） |
| 画像の名前 | 図の内容を表す kebab-case（例: `frequency-after-trip.png`）。言葉を含むグラフは `<name>.en.png` と `<name>.ja.png` |
| 画像の置き場所 | `_GUILDAdocPages/images/lecture/partN/<name>.png` |

見た目の目安:

- 大きさ: 本文の幅いっぱいの図は 18×7.5 cm、2 段の軸などは 18×11 cm、小さなグラフは 12×8 cm（ページ側は `is-compact`）。
- 文字は 9 pt 程度、線は 1.5 pt 程度。白い背景、格子は薄い灰色。ページでの表示はおよそ半分の大きさになり、文字は本文と同じくらいに見えます。
- 色はドキュメントページの配色（`style.css` の `--brand`（青）、`--lec-c2`（緑）、`--lec-c3`（橙）、`--lec-c4`（紫））に合わせます。

### 5.4 グラフの作り方（GUILDA の機能を優先）

- GUILDA で描けるグラフは、GUILDA の `plot_*` で描きます。どれも `Parent=ax` で軸（`tiledlayout` の `nexttile` でもよい）に描けます。描いたあとに `title`、`xlabel`、`ylabel`、軸の範囲、凡例の位置などを整えてかまいません。

  | 結果 | 使える関数 |
  |---|---|
  | 潮流計算（`ResultPF`） | `plot_voltage`、`plot_branch`、`plot_convergence`、`plot_diagram`、`plot_single_line_diagram`、`plot_spring_model` |
  | 時間シミュレーション（`ResultODE`） | `plot_trajectory`、`plot_diagram`、`plot_spring_model` |
  | 近似線形化（`ResultLIN`） | `plot_eigenvalue` |
  | 最適潮流計算（`ResultOPF`） | `plot_dispatch`、`plot_lmp`、`plot_iteration`（4 パネルのチャート。`Parent` は容器） |
  | 連続潮流計算（`ResultCPF`） | `plot_pvcurve` |
  | 系統（`PowerNetwork`） | `plot_diagram`、`plot_spring_model` |

- GUILDA の計算は公開 API（`network.IEEE9bus()`、`net.initialize()`、`net.add_scenario(...)`、`net.simulate(...)` など）で行います。
- `plot_*` に無い描き方が要るとき（2 つの場合を 1 つの軸に重ねるなど）だけ、GUILDA の結果を MATLAB の `plot` で描きます。
- GUILDA にない概念のグラフ（§5.1）は、MATLAB の計算で描きます。手で曲線の形を決めず、式とパラメータをライブスクリプトに書きます。
- 普通の学術的なグラフにします。軸、目盛り、単位付きの軸ラベル（`t (s)`、`f (Hz)`、`|V| (pu)`）、凡例。絵は描きません（絵が要るならそれはイメージ図です）。
- グラフの中の文字は記号と単位を中心にし、言語に依らないものにします（凡例は `H = 6 s`、`P_G − P_D`、GUILDA の機器のタグなど。マイナスは U+2212 の `−`）。言葉がどうしても要るグラフだけ、日英 2 枚を書き出します。
- 読み方は `figcaption` に書き、グラフの中に説明文を入れすぎません。

### 5.5 グラフのページへの貼り方

```html
<figure class="lec-figure is-scroll" style="--lec-min-w: 560px;">
  <div class="lec-scroll">
    <img src="../images/lecture/part0/frequency-after-trip.png" alt="英語で、何がどうなるグラフか" width="1294" height="528">
  </div>
  <figcaption lang="en">…</figcaption>
  <figcaption lang="ja">…</figcaption>
</figure>
```

- 言葉を含むグラフは、`<img lang="en" src="….en.png">` と `<img lang="ja" src="….ja.png">` を並べます。
- `width` と `height` には PNG の画素数を書きます（`sips -g pixelWidth -g pixelHeight file.png` で分かる）。表示の大きさは CSS が決めます。描き直して画素数が変わったら、書き直します。
- `alt` は図の結論まで書きます（数値の読み取りが要る図は主な値も）。
- 狭い画面で文字が 10 px より小さくならないように、`is-scroll` と `--lec-min-w` を付けます。目安は `--lec-min-w` ＝ 画像の横の画素数 × 0.42（幅いっぱいの図なら 560px、小さな図なら 360px）。
- 小さな図には `is-compact` を付けます（最大 560px）。少し大きく見せたい図は `--lec-fig-max: 640px;` のように変えます。

### 5.6 改訂の手順（Part1〜8）

1. **MATLAB で描き直したイメージ図を SVG に戻す**: ページの PNG の図のうち、§5.1 でイメージ図にあたるもの（系統図、モデル図、ブロック線図、流れ図など）を探します。改訂前のページは `git show 95b3f4d4^1:_GUILDAdocPages/lecture/<page>.html` で取り出せるので、その中の同じ図の `<figure>…</figure>` をそのまま戻します。戻した図の PNG（`.en.png`・`.ja.png` も）を `git rm` で削除します。
2. **グラフを GUILDA の機能で描き直す**: 残すグラフのうち、GUILDA の `plot_*` で描けるものは、§5.4 のとおり Part のライブスクリプトで描き直します。
3. **コマンドをまとめる**: 続けて実行する `pre.lec-cmd` の 1 行ずつのブロックを、1 つのブロックにまとめます（§4）。
4. ライブスクリプトを実行して描き直したグラフを書き出し、画像と、`width`・`height` を確かめます。
5. ページ・画像・ライブスクリプトを一緒にコミットします。`style.css`、`lecture.js` を変えたいときは、自分では変えずに報告で提案します。

### 5.7 確かめ方（図）

- Part のライブスクリプトを R2026a で最後まで実行でき、ページのグラフと同じ図が描けることを確かめます。書き出した PNG を開いて、文字の切れ・重なり、凡例が線を隠していないか、軸の範囲を確かめます。
- 戻した SVG が、白い図の枠の中で読めること（文字・線・箱の色）を確かめます。

## 6. 確かめ方

MATLAB のテストは不要です（本体のコードは変えません）。グラフを描く Part のライブスクリプトは R2026a で実行して確かめます（§5.7）。次をブラウザ（`file://`）で確かめます。

- ドキュメントページ（例: `developer/naming-conventions.html`）と並べて、背景・本文の幅・見出し・コードの見た目がそろっている。
- 右上の EN／日本語の切り替えで、本文・図の文字（SVG の `<text>`、日英 2 枚の画像）・図の説明がすべて切り替わる。
- 数式が KaTeX で表示される（`data-tex` の文字のまま残っていない）。
- `pre.lec-cmd` の各行の前に `>>` が付き、クリックでブロック全体が選択される。
- 幅 375px 程度でも横にはみ出さない（`is-scroll` の図は横スクロールになる）。
- 1440px 以上で目次が本文の右に出て、文言が 1 行に収まる。

ヘッドレスの Chrome では、`--window-size` の幅に下限があるため、狭い画面は幅 375px の `iframe` にページを入れて撮ると確かめられます。言語は URL に `?lang=ja` / `?lang=en` を付けて選べます。`>>` が付いているかは `--dump-dom` で `span.lec-cmd-line` があるかで確かめられます。

## 7. Part1〜8 の節立ての案

各 Part のセッションはこれを出発点にし、内容は電力系統工学の標準的な教科書で確かめて書きます。

- **Part1 電力系統の作成と機器の種類**: 4 つの部品（母線・ブランチ・機器・制御器）、単位法の考え方、送電線（π 型等価回路）と変圧器、母線の種類（Slack・PV・PQ、機器のない母線）、発電機（回る重い円盤としての慣性、モデルの詳しさの段階: classical／1 軸／2 軸／park）、負荷モデル（定インピーダンス・定電流・定電力）、制御器（ローカル・グローバル）、同梱のベンチマーク系統（IEEE9／14／39／68、IEEJ EAST／WEST）。参考: 旧サイト https://guilda-dev.github.io/guilda-doc/aboutPowerSystem/0TopPage/ と SeriesAnalysis（3 母線の例）。同梱の系統は `_GUILDAobject/+network/` で確かめる（2026-11-16 時点で `IEEE9bus`、`IEEE14bus`（と `_NoTap`、`_lossless`）、`IEEE39Bus`、`IEEE68bus`、`IEEJ_EAST10/30`、`IEEJ_WEST10/30` などがある）。
- **Part2 潮流計算**: 運転状態の「写真」としての潮流、母線ごとに決める量と求める量、有効電力は位相差で、無効電力は電圧差で流れること（P = V1·V2/X·sinδ）、ニュートン法を図で、収束しないとき、結果の読み方、時間シミュレーションの出発点になること。
- **Part3 時間シミュレーション**: 平衡点とずれ、動揺方程式の意味（言葉で）、同期化力と制動、事故の流れ（発生・除去・回復または脱調）、過渡安定度と臨界除去時間、等面積法、周波数の変化（慣性とガバナ）、GUILDA で設定できるイベントの種類。
- **Part4 可視化機能：ばね質点モデル**: 電圧フェーザを質点、リアクタンスをばねに見立てる考え方、潮流をばねのつり合いとして見る、時間応答を質点の振動として見る、3D 表示（z = log|V|）で見る電圧の低下と崩壊。設計は `notes/graph-spring.md`。ユーザーの参考スライドは未入手。
- **Part5 近似線形化**: 小さな揺れは直線で近似できること、状態空間モデル（ブロック図と記号だけ）、固有値は揺れの型であること、複素平面の読み方とダンピング比、振動モードの種類（局所・地域間）、参加係数、大きな揺れでは合わなくなること。
- **Part6 最適潮流計算と定態安定度制約付き OPF**: 経済負荷配分、制約（発電の上下限・電圧・線路容量）、混雑と LMP、安い運転ほど揺れやすくなり得ること、固有値の条件を付けた OPF とその反復（OPF → 線形化 → 制約の追加）。GUILDA の実装は `notes/opf-requirements.md` の「安定度制約付き OPF」の節。
- **Part7 連続潮流計算と電力方程式のヤコビアン**: PV カーブとノーズ点、電圧崩壊の実例、無効電力が大切な理由、無効電力の限界でカーブが変わること、ヤコビアンは感度であり、ノーズ点で特異になること、対策（調相設備）。
- **Part8 制御器の設計と自作の方法**: フィードバックの基本、AVR・PSS・ガバナ、周波数制御の階層（一次・二次（AGC）・三次）、グローバル制御器（広域計測と LQR の考え方）、Retrofit 制御、自作するときの考え方（観測 → 計算 → 入力）。「広域計測」は計測の方式の名前（WAMS）で、制御器の呼び名ではありません。制御器は必ず「グローバル制御器」と書きます。

Part0 の図との対応: Part0 の「講義の地図」は、Part1 → Part2 → 静的（Part6・Part7）／動的（Part3・Part5）→ Part8、Part4 は Part2 と Part3 の結果を見せる、という関係で描いています。この図はページ内の SVG です。節立てを大きく変える場合は、報告に書いてください（Part0 の図の直しは土台の担当が行います）。

## 8. 参考文献

確かめ済みの書誌（Part0 で使用）:

- 石崎孝幸 編著、川口貴弘・河辺賢一 著『電力系統のシステム制御工学 – システム数理と MATLAB シミュレーション –』コロナ社、2022 年（計測・制御セレクションシリーズ 4）。GUILDA の基になった教科書。
- P. Kundur and O. P. Malik, *Power System Stability and Control*, 2nd ed., McGraw Hill, 2022.
- J. Machowski, Z. Lubosny, J. W. Bialek and J. R. Bumby, *Power System Dynamics: Stability and Control*, 3rd ed., Wiley, 2020.

ほかの文献を加えるときは、書名・著者・版・出版社・年を確かめてから書きます。確かめられないものは書きません。章や節の番号を書く場合は、手元の版で確かめます。
