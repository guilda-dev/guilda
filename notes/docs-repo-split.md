# ドキュメントの分割（`_GUILDAdoc` と `_GUILDAdocPages`）

基準: `refactor/design-alignment` の ca378070（2026-11-20）。作業ブランチ `docs/guilda-doc-pages`。

## 1. 目的と決定事項

ドキュメントを、互いにリンクする 2 つのサイトに分けます。

| サイト | リポジトリ（このリポジトリでの場所） | 中身 | 公開 |
|---|---|---|---|
| <https://guilda-dev.github.io/guilda/> | guilda-dev/guilda の `gh-pages`（`_GUILDAdoc`） | クラスリファレンス、For Developer、更新履歴（コードと一緒に変わるもの） | `GUILDA.publish_doc` がローカルの `gh-pages` にコミットし、利用者がプッシュ |
| <https://guilda-dev.github.io/guilda-doc/> | guilda-dev/guilda-doc の `main`（サブモジュール `_GUILDAdocPages`） | Home、About、Getting Started、Tutorial、講義ノート | サブモジュールの中でコミットし、利用者がプッシュ |

利用者の決定（変更しない）:

1. `_GUILDAdoc` に残すもの: Reference（`class.html`、`method.html`、`reference.css`、生成されるクラスと呼び出しグラフのデータ、`doc-*.js`、`vendor/`）、For Developer（`developer/`、`database/list_developer.js`）、更新履歴（`database/list_UpdateLog.js`、`updatelog.html`、`doc-updatelog.js`）。`index.html` は Reference と For Developer（更新履歴を含む）のタブだけの小さな版にし、guilda-doc の各タブへリンクします。
   - 経緯: 2026-11-18 の案では更新履歴も guilda-doc に置く予定でしたが、2026-11-20 に利用者が `_GUILDAdoc` に残す（guilda-doc には出さない）と変更しました。
2. `_GUILDAdocPages`（guilda-doc）に置くもの: Home、About、Getting Started、Tutorial のタブ（`index.html`）、`lecture/`、それらが使う `images/`、`database/list_Lectures.js`、`database/list_Tutorials.js`、共通の CSS/JS/vendor の自前のコピー（共通の素材は各リポジトリで別々に持つ）。Reference と For Developer のタブ、クラスリファレンスのファイル、更新履歴は置かず、ヘッダーから guilda の Pages へリンクします。
3. `GUILDA.publish_doc` は guilda の Pages（`gh-pages`）に `_GUILDAdoc` を公開します（§4）。`_GUILDAdocPages` には触れません。`GUILDA.doc` は今までどおりローカルの `_GUILDAdoc/index.html` を開きます。
4. guilda-doc の main は古い MkDocs のサイトです。履歴は移さず、1 つのコミットで main の中身を置き換えます（`LICENSE` は残し、短い `README.md` と `.nojekyll` を追加し、MkDocs のファイルとワークフローを削除）。Pages の公開元は利用者が main / root に切り替えます。
5. `_GUILDAtutorial` のライブスクリプトなど、講義ノートをパスで開くコードは、サブモジュールの有無に依存しないよう公開サイトの URL（`https://guilda-dev.github.io/guilda-doc/lecture/...`）に向けます。クラスとメソッドのページへのリンク（`_GUILDAdoc/class.html`、`method.html`）はローカルの `_GUILDAdoc` を開くので、そのままです。

### 1.1 2026-11-20 の質問への回答（コーディネーター経由）

最初の案（7f55d1fc）では、`publish_doc` がクラスリファレンスを guilda-doc に複製し、guilda-doc に Reference タブを置く予定でした。利用者の回答で次のように変えました。

- Q1: `publish_doc` のブランチの制限（`main` か `versionX.Y` だけ）をなくし、どのブランチからでも公開できるようにします。コミットメッセージにブランチ名が残ります。
- Q2: Reference と For Developer は guilda リポジトリの Pages で公開し、guilda-doc には入れません。guilda-doc から guilda の Pages へ、guilda の Pages から guilda-doc へ、それぞれ適宜リンクします。公開した `class.html` と `method.html` の Class Documentation へのリンクは普通のリンクのままです（開発者向けのページも同じサイトにあるため）。
- Q3: guilda の `gh-pages` は Reference と For Developer のサイトとして使います。2026-11-20 時点で guilda-dev/guilda に `gh-pages` ブランチはなく、Pages も有効でない（guilda-dev.github.io/guilda/ は 404）ので、guilda 側の古い URL の転送は不要です [事実: `git ls-remote`、GitHub API の `has_pages=false`]。`_GUILDAdoc/index.html` の、移ったタブへのフラグメントの転送だけは残します。
- 公開の手順（2026-11-20、コーディネーター経由）: 新しい guilda-doc は、まず一時的な公開のプレビュー用リポジトリ（例: guilda-dev/guilda-doc-preview）でレビューしてもらいます。サイトは相対パスだけで動くので、プレビューでも同じに見えます（guilda の Pages へのリンクは本番の URL のまま）。レビューの間、guilda-doc の `gh-pages`（古い MkDocs のサイト）はそのままにします。了承後、guilda-doc の配信を新しいサイトに置き換え、古い MkDocs の各ページの URL には新しいページへの転送ページを置きます（§6）。最後にプレビュー用リポジトリを削除します。

## 2. ファイルの振り分け

「両方」は、それぞれのリポジトリが別々のコピーを持つ共通の素材です。以後は別々に更新します。

| ファイル | `_GUILDAdoc`（guilda） | `_GUILDAdocPages`（guilda-doc） | 備考 |
|---|---|---|---|
| `index.html` | 小さな版（Reference、For Developer と更新履歴。ヘッダーに guilda-doc の各タブへのリンク。移ったタブへの古いリンクの転送） | 今の版から Reference と For Developer のタブ、更新履歴を除き、ヘッダーに guilda の Pages の Reference と For Developer へのリンクを置いたもの | ヘッダーの並びは両方とも Home、About、Getting Started、Tutorial、Reference、For Developer。他方のサイトへのリンクには ↗ を付ける |
| `lecture/*.html`、`lecture/lecture.js` | 削除 | 移動 | |
| `images/GUILDAicon.png` | 残す | 両方 | |
| `images/` のその他 | 削除 | 移動 | Home、About、Getting Started、Tutorial、講義ノートだけが使う |
| `database/list_Lectures.js`、`database/list_Tutorials.js` | 削除 | 移動 | |
| `database/list_developer.js`、`database/list_UpdateLog.js`、`developer/`、`updatelog.html`、`doc-updatelog.js` | 残す | なし | |
| `class.html`、`method.html`、`reference.css`、`doc-render.js`、`doc-tree.js`、`doc-colresize.js`、`doc-loader.js` | 残す | なし | |
| `style.css`、`doc-lang.js`、`vendor/katex/`、`vendor/README.md` | 残す | 両方 | 講義ノートとリファレンスが KaTeX を使う |
| 生成データ（`database/list_Classes.js` など） | 生成（git 管理外のまま）。`publish_doc` が `gh-pages` に公開 | なし | `database/User/`、`manifest.json`、`callgraph_cache.mat` は公開しない |
| guilda-doc の `docs/`、`mkdocs.yml`、`readthedocs.yml`、`.github/` | — | 削除 | |
| guilda-doc の `README.md`、`.gitignore` | — | 書き直し（`.gitignore` は OS のファイルだけ） | |
| guilda-doc の `LICENSE` | — | 残す | |
| `.nojekyll` | — | 追加 | |

## 3. リンクの書き換えと転送

- guilda-doc の `index.html`: For Developer と Reference のタブ、更新履歴、それらの読み込みと描画の JS を削除し、ヘッダーに `https://guilda-dev.github.io/guilda/_GUILDAdoc/index.html#tab-reference` と `#tab-developer` へのリンクを置きます。Getting Started の `GUILDA.doc()` の説明を「手元のクラスリファレンスを開く」に直します。Home の LICENSE のリンクを guilda の GitHub の `LICENSE` に向けます。guilda-doc のページに `class.html?class=...` へのリンクはありません [事実: grep]。
- `_GUILDAdoc/index.html`: ヘッダーに guilda-doc の各タブへのリンクを置きます。`#tab-home`、`#about-...` のように、このページにない id を指すリンク（移ったタブとその中の見出し）は、同じフラグメントと `?lang=` を付けて guilda-doc の `index.html` に転送します（`<head>` の小さなスクリプト）。`#tab-reference` と `#tab-developer` の id は残すので、`class.html`、`method.html`、`developer/*.html`、`updatelog.html` のリンクは変わりません。
- guilda の Pages はまだ公開されたことがない（guilda-dev.github.io/guilda/ は 404）ので、`_GUILDAdoc/lecture/` に転送用のページは置きません。
- guilda-doc の `index.html` は、フラグメントがタブの中の要素（`#about-references`、`#step1_buildnetwork_mlx` など）を指すとき、そのタブを開いてその要素までスクロールします（画像の読み込み後にもう一度スクロール）。§6 の転送はこれを使います。
- `_GUILDAtutorial/*.mlx` の講義ノートへのリンク 38 か所（`matlab:web(fullfile(GUILDA.pwd,"_GUILDAdoc","lecture","partN-*.html"),"-browser")`）を `matlab:web("https://guilda-dev.github.io/guilda-doc/lecture/partN-*.html","-browser")` に置き換えます。guilda-doc を切り替える（§5.3）までは、古い MkDocs のサイトにそのページがないので 404 になります。`class.html` と `method.html` へのリンク（45 か所）は変えません。
- `notes/lecture-anim/make_part4_spring_animations.m` と `notes/tutorial-gif/*` の出力先、`notes/lecture-notes.md` と `notes/tutorial-assets.md` の場所の説明を `_GUILDAdocPages` に直します（過去の調査ノートの本文は基準時点の記録なので直しません）。
- For Developer の `folder-structure.html`、`project-management.html`、`class-documentation.html`、`git-workflow.html` を新しい構成に合わせます。`.codex/config.toml` と `.github/copilot-instructions.md` の `list_Tutorials.js` の場所も直します。

## 4. `GUILDA.publish_doc` の流れ

```text
>> GUILDA.publish_doc     % 再生成し、_GUILDAdoc をローカルの gh-pages にコミット（プッシュしない）
```

オプションはありません（`confirm` と `push` は廃止）。

1. 検査: git がある、`GUILDA.pwd` が git リポジトリ、追跡ファイルに未コミットの変更がない（サブモジュールは除く）、`_GUILDAdoc` の下に追跡されていないファイルがない。ブランチは問いません。
2. クラスリファレンスを再生成（`export_class_database(find_doc_classes("user", false), "strict", false, "full", true)`）。エラーがあれば中止。
3. 一時的な git worktree に `gh-pages` を用意します。origin に `gh-pages` があれば取り込み、origin が読めなければ警告してローカルのブランチで続けます。どこにもなければ orphan で作ります。
4. 中身を置き換えます: `_GUILDAdoc/`（`database/User/`、`manifest.json`、`callgraph_cache.mat`、OS のファイルを除く）、`LICENSE`、`_GUILDAdoc/index.html` へ転送するルートの `index.html`、`.nojekyll`。`list_Classes.js` の `generatedAt` だけが変わったときは前の版に戻します。
5. `docs: publish <branch>@<short-sha>` をコミットします。変更がなければコミットしません。
6. `git -C <GUILDA> push origin gh-pages` を表示して終わります。

## 5. 利用者の手作業

コマンドは guilda のフォルダで実行します。作成、プッシュ、設定、削除はすべて利用者が行います。

### 5.0 最初に: サブモジュールのコミットを guilda-doc に置く

guilda の `_GUILDAdocPages` の gitlink は、サブモジュールのコミット fcb1c8f を指します。このコミットが guilda-doc にないまま guilda をプッシュすると、clone で `git submodule update --init` がそのコミットを取得できずに失敗します。そこで、**guilda をプッシュする前に**、Pages が配信しないブランチへこのコミットを置きます:

- `git -C _GUILDAdocPages push git@github.com:guilda-dev/guilda-doc.git HEAD:refs/heads/new-site`

`main` と `gh-pages` にはまだ送りません（レビュー後の §5.3）。

**注意:** `_GUILDAtutorial/*.mlx` の講義ノートへのリンク 38 か所は、すでに新しい guilda-doc の URL（`https://guilda-dev.github.io/guilda-doc/lecture/...`）を指しています。guilda-doc をレビュー後に切り替える（§5.3）までは、古い MkDocs のサイトにそのページがないため 404 になります。

### 5.1 guilda の Pages（Reference、For Developer、更新履歴）

1. §5.0 のあとで guilda をプッシュし、この作業ブランチが統合されたあと、公開するブランチ（通常は `main` か `versionX.Y`）で MATLAB から `GUILDA.publish_doc` を実行します。初回はローカルに orphan の `gh-pages` ができ、`docs: publish <branch>@<sha>` がコミットされます。
2. 確かめてからプッシュします: `git push origin gh-pages`
3. guilda-dev/guilda の Settings → Pages で、Build and deployment を Deploy from a branch、ブランチ `gh-pages`、フォルダ `/ (root)` にして有効にします（2026-11-20 時点で `has_pages=false`）。サイトは <https://guilda-dev.github.io/guilda/>（ルートの `index.html` が `_GUILDAdoc/index.html` へ転送）。

### 5.2 guilda-doc のプレビューとレビュー

サブモジュールの中の新しいサイトは、ローカルの作業ブランチ `docs/new-site` のコミット 1 つです（origin/main の上に積んであり、git のフックが detached HEAD でのコミットを禁じるためブランチに載せています）。

1. GitHub で公開のリポジトリ guilda-dev/guilda-doc-preview を空で作ります（README なし）。
2. プッシュします: `git -C _GUILDAdocPages push git@github.com:guilda-dev/guilda-doc-preview.git HEAD:main`
3. guilda-doc-preview の Settings → Pages を Deploy from a branch、ブランチ `main`、フォルダ `/ (root)` にします。プレビューは <https://guilda-dev.github.io/guilda-doc-preview/>。古い URL の転送も `https://guilda-dev.github.io/guilda-doc-preview/SourceCode/bus/` のように確かめられます。
4. レビューの間、guilda-doc の `gh-pages`（古い MkDocs のサイト）と Pages の設定には触れません。

### 5.3 了承後の切り替え

1. サブモジュールのリモートを SSH にします（HTTPS で取得したため）: `git -C _GUILDAdocPages remote set-url origin git@github.com:guilda-dev/guilda-doc.git`
2. 同じコミットを main と gh-pages に送ります。main は fast-forward、gh-pages は MkDocs の履歴を置き換えるので強制です:
   - `git -C _GUILDAdocPages push origin HEAD:main`
   - `git -C _GUILDAdocPages push --force origin HEAD:gh-pages`
   Pages の設定（`gh-pages` / root の legacy 配信）はそのままで新しいサイトに切り替わります。代わりに Settings → Pages を `main` / root に切り替える方法もあり、その場合は `gh-pages` を削除できます（以後の更新は main だけで済みます）。gh-pages のままにする場合は、以後の更新も両方へ送ります。
3. サブモジュールを main に乗り換えます: `git -C _GUILDAdocPages fetch origin && git -C _GUILDAdocPages switch main && git -C _GUILDAdocPages reset --hard origin/main`（ローカルの `main` は clone のときの古い MkDocs の main なので、origin に合わせます）。
4. guilda の `_GUILDAdoc` のリンクを本番に戻します。レビューの間は guilda-doc-preview を指しています（`_GUILDAdoc/index.html` の転送とヘッダーの 4 つのタブ、`developer/folder-structure.html`、`developer/git-workflow.html`）。guilda-doc が新しいサイトを配信するようになったら、これらを `https://guilda-dev.github.io/guilda-doc/` に戻して `publish_doc` を実行します。プレビュー用リポジトリを削除する前に行います。
5. guilda-doc-preview を削除します（Settings → Danger Zone → Delete this repository）。

### 5.4 guilda 側

- guilda の作業ブランチの push は今までどおり利用者が行います。

## 6. 古い MkDocs のサイトからの転送

古い guilda-doc（mkdocs-material 8.5.10、2023 年、`gh-pages` から legacy 配信）のページはトップを含めて 20 あります（`gh-pages` のツリーで確認。`404.html`、`sitemap.xml`、`search/`、`assets/`、`Figures/` は除く）。各ページの URL（MkDocs のディレクトリ URL `/xxx/yyy/` ＝ `xxx/yyy/index.html`）に、新しいページへ転送するだけのページ（`meta refresh` と `location.replace`、`noindex`）を `_GUILDAdocPages` に置きました。サイト内の転送先は相対パスなのでプレビューでも動きます。トップページ `/` は新しい `index.html`（Home）そのものです。guilda の Pages への転送先は本番の URL です。

| 古い URL（`https://guilda-dev.github.io/guilda-doc/` からの相対） | 古いページ | 新しいページ |
|---|---|---|
| `/`（Tutorial TopPage） | トップ | `index.html`（Home） |
| `aboutPowerSystem/0TopPage/` | 電力系統モデルについて | `lecture/part1-network-components.html` |
| `SetEnvironment/0TopPage/` | GUILDA の環境設定 | `index.html#tab-getting-started` |
| `SeriesAnalysis/0TopPage/` | 一連の解析実行例 | `index.html#tutorial-index`（Step 0 目次） |
| `Reference/0TopPage/` | リファレンス（使い方の目次） | `index.html#tutorial-list`（Step 1〜12） |
| `Reference/defineNet/0TopPage/` | 解析する電力ネットワークを作成する | `index.html#step1_buildnetwork_mlx`（Step 1） |
| `Reference/defineNet/NewPowerNetwork/` | 新しい電力系統モデルの定義 | `index.html#step1_buildnetwork_mlx`（Step 1） |
| `Reference/defineNet/NewComponent/` | 新たな機器モデルの定義 | guilda Pages `_GUILDAdoc/developer/model-implementation.html` |
| `Reference/addController/0TopPage/` | 制御器の付加 | `index.html#step2_componentcontroller_mlx`（Step 2） |
| `Reference/addController/NewController/` | 新たな制御器モデルの実装 | guilda Pages `_GUILDAdoc/developer/model-implementation.html` |
| `Reference/Analysis/net_simulate/` | 数値シミュレーションの実行 | `index.html#step5_simulationscenario_mlx`（Step 5） |
| `Reference/Analysis/SampleCode/` | simulation のコード例 | `index.html#step5_simulationscenario_mlx`（Step 5） |
| `Reference/Analysis/net_getsys/` | 近似線形化モデルの導出 | `index.html#step8_linearization_mlx`（Step 8） |
| `SourceCode/0TopPage/` | ソースコードの解説 | guilda Pages `_GUILDAdoc/index.html#tab-reference` |
| `SourceCode/NetProperties/` | net のパラメータの読み方 | `index.html#step3_networkdata_mlx`（Step 3） |
| `SourceCode/power_network/` | 電力系統クラス | guilda Pages `_GUILDAdoc/class.html?class=PowerNetwork` |
| `SourceCode/bus/` | 母線のクラス | guilda Pages `_GUILDAdoc/class.html?class=Bus` |
| `SourceCode/branch/` | 送電網のクラス | guilda Pages `_GUILDAdoc/class.html?class=Branch` |
| `SourceCode/component/` | 機器のクラス | guilda Pages `_GUILDAdoc/class.html?class=Component` |
| `SourceCode/controller/` | 制御器のクラス（ローカルとグローバル） | guilda Pages `_GUILDAdoc/class.html?class=LocalController` |

- `404.html`（MkDocs の）は新しいサイトにはありません。GitHub Pages の 404 ページは任意のパスで表示されるため相対パスが使えず、プレビューと本番の両方で動かせないので置きません。`sitemap.xml` もなくなります。
- `Figures/*` の画像の URL は転送しません（ページではないため）。
- 2026-11-20 に利用者がこの表を確認し、`SourceCode/controller/` の転送先を Reference タブから `LocalController` のクラスページに変えました。ほかの行はこのままです。
