// For Developer cards, in the order a developer should read them.
// "Group: Title" — the group is the English prefix of title; title_ja uses the matching Japanese prefix.
const developerData = [
{
    title: "Coding: Naming Conventions",
    title_ja: "コーディング: 命名規則",
    description: "Review variable prefixes, size notation, composition examples, and fixed prefixes for special data types.",
    description_ja: "変数の接頭辞、サイズの表記、組み合わせの例、特別なデータ型に使う固定の接頭辞を確認します。",
    link: "developer/naming-conventions.html"
    },
{
    title: "Coding: API Design",
    title_ja: "コーディング: API 設計",
    description: "Follow the rules for analysis APIs: net.verb_noun() entry points, [result, flag, output] outputs, side effects by verb, and common Name-Value options.",
    description_ja: "解析 API の規則に従います: net.verb_noun() の入口、[result, flag, output] の出力、動詞ごとの副作用、共通の Name-Value オプション。",
    link: "developer/api-design.html"
    },
{
    title: "Coding: Class Documentation",
    title_ja: "コーディング: クラスのドキュメント",
    description: "Write MATLAB help comments and five tags to document classes, properties, and methods, add a figure and math, and check the generated reference pages.",
    description_ja: "MATLAB のヘルプコメントと 5 つのタグでクラス・プロパティ・メソッドを記述し、図と数式を加え、生成されたリファレンスのページを確認します。",
    link: "developer/class-documentation.html"
    },
{
    title: "Coding: Model Implementation",
    title_ja: "コーディング: モデルの実装",
    description: "Add a new generator, load, or controller: the contracts of each model kind, a minimal generator and AVR, and how to test them with validate.",
    description_ja: "発電機・負荷・制御器を新しく追加します: 各モデル種別の約束事、最小限の発電機と AVR の例、validate による確認方法。",
    link: "developer/model-implementation.html"
    },
{
    title: "Codebase: Folder Structure",
    title_ja: "コードベース: フォルダ構成",
    description: "Learn what each folder contains, which folders are on the MATLAB path, where to place new files, and which files are generated.",
    description_ja: "各フォルダの内容、MATLAB パスに含まれるフォルダ、新しいファイルの置き場所、自動生成されるファイルを確認します。",
    link: "developer/folder-structure.html"
    },
{
    title: "Codebase: Class Design",
    title_ja: "コードベース: クラス設計",
    description: "See how the model classes relate as a whole and the rules that span them: ownership, parent references, identity, solver defaults, edit handling, variable order, and unit conventions.",
    description_ja: "モデルクラスが全体としてどう関係し合うかと、クラスをまたぐ規則 (所有、親参照、識別、ソルバーの既定値、編集時の扱い、変数の順序、単位の規約) を確認します。",
    link: "developer/class-design.html"
    },
{
    title: "Features: Model Building",
    title_ja: "機能: モデル構築",
    description: "How a network is built from buses, branches, components, and controllers, and the references the objects keep to each other.",
    description_ja: "母線・ブランチ・機器・制御器からネットワークを組み立てる流れと、オブジェクト間で保持する参照の構造。",
    link: "developer/feature-model-building.html"
    },
{
    title: "Features: Data Import and Export",
    title_ja: "機能: データの入出力",
    description: "Reading and writing network data as CSV and MATPOWER cases: the call order, the mapping of each field, and what is checked on import.",
    description_ja: "ネットワークデータの CSV・MATPOWER 形式での読み書き: 呼び出し順、各項目の対応、読み込み時の検査。",
    link: "developer/feature-data-io.html"
    },
{
    title: "Features: Power Flow",
    title_ja: "機能: 潮流計算",
    description: "Solving the power flow: the call order between classes, the inputs each step reads, the results it returns, and where they are stored.",
    description_ja: "潮流計算の解法: クラス間の呼び出し順、各段階が読む入力と返す結果、結果の保存先。",
    link: "developer/feature-power-flow.html"
    },
{
    title: "Features: Initialization",
    title_ja: "機能: 初期化",
    description: "Finding the operating point and then the equilibria of components and controllers: the call order, the values each class reads, and the initial states it returns.",
    description_ja: "動作点を求め、続いて機器と制御器の平衡点を求める処理: 呼び出し順、各クラスが読む値と返す初期状態。",
    link: "developer/feature-initialize.html"
    },
{
    title: "Features: Optimal Power Flow",
    title_ja: "機能: 最適潮流計算",
    description: "Solving the optimal power flow: how the problem is assembled from the network, the call order, and the results it returns.",
    description_ja: "最適潮流計算の解法: ネットワークから問題を組み立てる方法、呼び出し順、返す結果。",
    link: "developer/feature-opf.html"
    },
{
    title: "Features: Continuation Power Flow",
    title_ja: "機能: 連続潮流計算",
    description: "Tracing the power flow solution as the power of the components on selected buses is scaled up: the call order, the inputs each step reads, and the curve it returns.",
    description_ja: "選んだ母線の機器の電力を増やしながら潮流解を追跡する処理: 呼び出し順、各段階が読む入力、返す曲線。",
    link: "developer/feature-cpf.html"
    },
{
    title: "Features: Time-Domain Simulation",
    title_ja: "機能: 時間応答シミュレーション",
    description: "Running a time-domain simulation: how events split it into phases, the call order between classes in each phase, and the results it returns.",
    description_ja: "時間応答シミュレーションの実行: イベントによる区間の分割、各区間でのクラス間の呼び出し順、返す結果。",
    link: "developer/feature-simulation.html"
    },
{
    title: "Features: Linearization",
    title_ja: "機能: 近似線形化",
    description: "Obtaining a linear model around an equilibrium: how each class contributes its matrices, the call order, and the system it returns.",
    description_ja: "平衡点まわりの線形モデルの導出: 各クラスが行列を提供する方法、呼び出し順、返すシステム。",
    link: "developer/feature-linearization.html"
    },
{
    title: "Features: GUI",
    title_ja: "機能: GUI",
    description: "Showing a model in a GUI: the screen, the pages each abstract class provides, parameter editing, and embedding in another app.",
    description_ja: "モデルの GUI 表示: 画面構成、抽象クラスごとのページ、パラメータの編集、別のアプリへの埋め込み。",
    link: "developer/feature-gui.html"
    }
];
