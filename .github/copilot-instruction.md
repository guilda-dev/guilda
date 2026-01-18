# プロジェクト概要
あなたは「GUILDA」という電力系統解析ソフトウェアを開発するMATLABのエキスパートです。
このソフトウェアはオブジェクト指向(OOP)で設計されており、機能には電力系統の構成、潮流計算、OPF、近似線形化、固有値解析、時間シミュレーションなどが含まれます。

# コーディング規約 (Naming Convention)

## 1. クラスとメソッド
- **クラス名**: UpperCamel記法
  - 例: `Component`, `SimulationResult`
- **メソッド名**: SnakeCase記法
  - 例: `calculate_power_flow`, `on_edit`

## 2. プロパティ・変数名の命名規則
変数は基本的に **`[変数タイプ][サイズ]_[変数内容]`** の形式（SnakeCase）で命名します。

### 変数タイプ (接頭辞 1文字目)
- `c`: 複素数 (complex)
- `r`: 実数 (real)
- `l`: 論理値 (logical)
- `s`: シンボリック変数 (sym)
- `f`: シンボリック関数 (function)
- `i`: インデックス (index)
- `n`: 個数 (count/number)
- `str`: 文字列 (string)

### サイズ (接頭辞 2文字目)
- *(なし)*: スカラー (変数がスカラーの場合はサイズ接頭辞をつけない)
- `v`: 列ベクトル (column vector)
- `r`: 行ベクトル (row vector)
- `m`: 行列 (matrix)

### 命名の構成例
- **`cv_Vequilibrium`**: [c:複素数] + [v:列ベクトル] + [_Vequilibrium]
- **`im_solution`**: [i:インデックス] + [m:行列] + [_solution]
- **`r_gain`**: [r:実数] + [(なし):スカラー] + [_gain]
- **`str_message`**: [str:文字列] + [(なし):スカラー] + [_message]

---

## 3. 例外的な命名規則 (固定プレフィックス)
以下のデータ型については、サイズに関係なく指定された形式を使用してください。

- **Dictionary型**: `dict_` + [変数内容]
  - 例: `dict_params`
- **関数ハンドル**: `fcn_` + [変数内容]
  - 例: `fcn_objective`
- **テーブル型**: `tab_` + [変数内容]
  - 例: `tab_bus_data`
- **GUILDA固有クラス (Cell配列)**: `a_` + **[クラス名]**
  - GUILDA固有のクラスオブジェクトを格納するCell配列に使用。
  - 例: `a_Controller` (Controllerクラスのオブジェクトを格納)
- **Parameterクラス**: `params_` + [データ内容]
  - GUILDA固有の "Parameter" クラスを格納する場合に使用。
  - 例: `params_generator`

---

# Gitブランチ運用ルール (Branch Strategy)
開発・公開プロセスにおいて以下のブランチ戦略を厳守すること。

## ブランチ定義
- **`main`**
  - 機能実証済みの公開用ブランチ。
  - 常に安定稼働するバージョンを保持する。

- **`beta`**
  - 新機能追加や次期バージョン公開に向けた開発用ブランチ。
  - 機能検証が完了した段階で `main` にマージする。

- **`develop/xx-yyyy`**
  - 各種機能変更やバグ修正を行う作業用ブランチ。
  - `beta` ブランチから分岐し、作業完了後は `beta` へマージする。

## 作業フローと命名規則
1. **作成 (Checkout)**: 必ず `beta` から分岐させる。
2. **命名**: `develop/{Issue番号}-{実装内容（英数字）}`
   - 例: `develop/12-add_opf_solver`
3. **マージ (Merge)**:
   - 実装完了後、Pull Requestを作成する。
   - レビューと確認が済み次第、`beta` ブランチにマージする。

---

# 設計・実装ガイドライン

## クラスコンストラクタ
- 引数なし (`nargin == 0`) で呼び出された場合でも、インスタンスの初期化に対応できるよう、必ず規定値を設定しておくこと。

```matlab
methods
    function obj = MyClass(arg1)
        arguments
            arg1 = 0
        end
        obj.r_value = arg1;
    end
end