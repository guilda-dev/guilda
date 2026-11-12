// Hands-on tutorials in _GUILDAtutorial, in reading order; rendered by renderTutorials() in index.html.
// step: short label of the row; file: path under _GUILDAtutorial; open: command that opens it
// (default: open _GUILDAtutorial/<file>); title/summary: one line each, *_ja for Japanese.
const tutorialData = [
  {
    step: "0",
    file: "Main.mlx",
    open: "GUILDA.tutorial()",
    title: "Introduction",
    title_ja: "はじめに",
    summary: "How a power system is built from buses, branches and components, and the workflow of GUILDA.",
    summary_ja: "電力系統が母線、ブランチ、機器でどう組み立てられているかと、GUILDA での作業の流れを説明します。"
  },
  {
    step: "1",
    file: "Step1_BuildNetwork.mlx",
    title: "Build a network",
    title_ja: "系統モデルの構築",
    summary: "Load a benchmark network such as IEEE68bus, or define a new one bus by bus.",
    summary_ja: "IEEE68bus などのベンチマークモデルを読み込むか、母線から順に新しい系統を定義します。"
  },
  {
    step: "2",
    file: "Step2_AddController.mlx",
    title: "Add controllers",
    title_ja: "制御器の付加",
    summary: "Attach local and global controllers to the network and simulate it.",
    summary_ja: "ローカル制御器とグローバル制御器を取り付け、シミュレーションしてみます。"
  },
  {
    step: "3",
    file: "Step3_NetProperties.mlx",
    title: "Read the network data",
    title_ja: "系統モデルのデータの見方",
    summary: "Reach buses, branches, components and controllers from the network and read their properties.",
    summary_ja: "ネットワークから母線、ブランチ、機器、制御器を取り出し、そのプロパティを読む方法を説明します。"
  },
  {
    step: "4",
    file: "Step4_SimulateCondition.mlx",
    title: "Simulation conditions",
    title_ja: "シミュレーションの条件設定",
    summary: "Initial values, faults, input changes, disconnection and reconnection, and several timed events.",
    summary_ja: "初期値、地絡、入力の変化、解列と並列、複数の時間イベントを設定する方法を説明します。"
  },
  {
    step: "5",
    file: "Step5_SimulateResultData.mlx",
    title: "Simulation results",
    title_ja: "シミュレーション結果",
    summary: "Read the response data, plot it, animate it and export it.",
    summary_ja: "応答データを取り出して、プロットやアニメーション、エクスポートに使います。"
  },
  {
    step: "6",
    file: "Step6_GetLinearSystem.mlx",
    title: "Linear model",
    title_ja: "線形化モデルの導出",
    summary: "Obtain the linearized state-space model and its matrices A, B, C and D.",
    summary_ja: "近似線形化した状態空間モデルを求め、係数行列 A、B、C、D を取り出します。"
  },
  {
    step: "+",
    file: "Supplement_CheetSheet.mlx",
    title: "Command cheat sheet",
    title_ja: "コマンド早見表",
    summary: "The common commands, from defining a network to linearization, on one page.",
    summary_ja: "系統モデルの定義から近似線形化まで、よく使うコマンドを一つにまとめています。"
  },
  {
    step: "+",
    file: "Supplement_Tools.mlx",
    title: "Useful tools",
    title_ja: "便利な機能",
    summary: "List the network data in tables, search the classes and create a new subclass.",
    summary_ja: "ネットワークのデータを表で一覧する方法、クラスの検索、新しい子クラスの作り方を紹介します。"
  },
  {
    step: "+",
    file: "ClassManual/",
    open: "_GUILDAtutorial/ClassManual/",
    title: "Model manuals",
    title_ja: "モデルの解説",
    summary: "The models of branches, buses, generators, loads and controllers such as the AGC and LQR.",
    summary_ja: "ブランチ、母線、発電機、負荷、AGC や LQR などの制御器のモデルを解説します。"
  }
];
