// For Developer cards, in the order a developer should read them.
// "Group: Title" — the group is the English prefix of title; title_ja uses the matching Japanese prefix.
const developerData = [
{
    title: "Overview: Architecture",
    title_ja: "概要: アーキテクチャ",
    description: "One UML class diagram of the model and analysis classes, with ownership and parent references, and the rules that span them: tags, model edits, variable order and the analysis API.",
    description_ja: "モデルクラスと解析クラスを、所有関係と親への参照とともに 1 枚の UML クラス図で示します。タグ、モデルの編集、変数の順序、解析 API など、クラスをまたぐ規則もまとめます。",
    link: "developer/architecture.html"
    },
{
    title: "Overview: Analysis Flows",
    title_ja: "概要: 解析の流れ",
    description: "A use-case diagram of what users do, and a short sequence diagram for each analysis: net.verb_noun() → solver → result, returned as [result, flag, output].",
    description_ja: "ユーザーが行うことをユースケース図で示し、各解析を短いシーケンス図で示します。どの解析も net.verb_noun() → ソルバー → 結果の順に進み、[result, flag, output] を返します。",
    link: "developer/analysis.html"
    },
{
    title: "Overview: Debugging Guide",
    title_ja: "概要: デバッグガイド",
    description: "Where to look at each stage, from model building to plotting: entry method and solver, result fields, settings, and typical messages.",
    description_ja: "モデル構築から描画までの各段階で見る場所をまとめます。入口のメソッドとソルバー、結果のフィールド、設定、よく出るメッセージを確認します。",
    link: "developer/debugging.html"
    },
{
    title: "Rules: Coding Rules",
    title_ja: "規則: コーディング規則",
    description: "Naming conventions, folder structure, placement of new files, generated files, and how to add and test a new model.",
    description_ja: "命名規則、フォルダ構成、新しいファイルの置き場所、自動生成ファイル、新しいモデルの追加とテストの方法をまとめます。",
    link: "developer/coding-rules.html"
    },
{
    title: "Rules: Class Documentation",
    title_ja: "規則: クラスのドキュメント",
    description: "Write MATLAB help comments and tags to document classes, properties, and methods, add a figure and math, and check the generated reference pages.",
    description_ja: "MATLAB のヘルプコメントとタグで、クラス、プロパティ、メソッドを説明する方法です。図や数式の加え方と、生成されたリファレンスページの確かめ方も扱います。",
    link: "developer/class-documentation.html"
    },
{
    title: "Rules: Git Workflow and Project Management",
    title_ja: "規則: Git ワークフローとプロジェクト管理",
    description: "Branches, commit messages, pull requests, snapshot integration and release, publishing the documentation, Issues, bilingual pages, the Update Log, and the Definition of Done.",
    description_ja: "ブランチ、コミットメッセージ、プルリクエスト、スナップショットの統合とリリース、ドキュメントの公開、Issue、日英併記のページ、Update Log、完了の定義をまとめます。",
    link: "developer/git-workflow.html"
    }
];
