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
    description: "Write MATLAB help comments and three tags to document classes, properties, and methods, and check the generated reference.",
    description_ja: "MATLAB のヘルプコメントと 3 つのタグでクラス・プロパティ・メソッドを記述し、生成されたリファレンスを確認します。",
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
    title: "Codebase: PowerNetwork",
    title_ja: "コードベース: PowerNetwork",
    description: "The network that holds buses, branches, and controllers: the data it owns, the solver objects and the analysis entry points it provides, and how it collects the edits of every layer.",
    description_ja: "母線・ブランチ・制御器を保持するネットワーク: 持つデータ、ソルバーオブジェクトと提供する解析の入口、各階層の編集を集める仕組み。",
    link: "developer/class-powernetwork.html"
    },
{
    title: "Codebase: Bus",
    title_ja: "コードベース: Bus",
    description: "A node of the network: bus types and power flow specifications, the components connected to it, and the values it reads from and returns to the network.",
    description_ja: "ネットワークの節点: 母線の種類と潮流計算の指定値、接続される機器、ネットワークとの間で受け渡す値。",
    link: "developer/class-bus.html"
    },
{
    title: "Codebase: Branch",
    title_ja: "コードベース: Branch",
    description: "A line or transformer between two buses: its parameters, the admittance matrix it contributes to the network, and the methods the analyses call.",
    description_ja: "2 つの母線を結ぶ送電線・変圧器: パラメータ、ネットワークのアドミタンス行列への寄与、解析から呼ばれるメソッド。",
    link: "developer/class-branch.html"
    },
{
    title: "Codebase: Component",
    title_ja: "コードベース: Component",
    description: "The base of generators, loads, and other devices on a bus: states and ports, the equations each subclass implements, and how equilibrium and linear models are obtained.",
    description_ja: "母線に接続する発電機・負荷などの基底クラス: 状態とポート、各サブクラスが実装する方程式、平衡点と線形モデルの求め方。",
    link: "developer/class-component.html"
    },
{
    title: "Codebase: LocalController",
    title_ja: "コードベース: LocalController",
    description: "A controller attached to one component, such as an AVR, a PSS, or a governor: where it attaches, the data it owns, and the equations it implements.",
    description_ja: "1 つの機器に取り付ける制御器 (AVR、PSS、ガバナなど): 接続先、持つデータ、実装する方程式。",
    link: "developer/class-localcontroller.html"
    },
{
    title: "Codebase: GlobalController",
    title_ja: "コードベース: GlobalController",
    description: "A controller that reads the states of its controlled units and drives their inputs: how it differs from LocalController, its inputs and outputs, and the equations it implements.",
    description_ja: "制御対象の機器の状態を読み、その入力を駆動する制御器: LocalController との違い、入力と出力、実装する方程式。",
    link: "developer/class-globalcontroller.html"
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
    }
];
