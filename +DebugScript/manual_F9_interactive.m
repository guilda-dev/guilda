% F9 GUILDA の環境: 対話操作が必要な機能の手動確認
%
% このスクリプトは runtests / run_all の対象外 (ファイル名が test_ で始まらない)。
% MATLAB のデスクトップで1セクションずつ実行し、画面を目で確認する。

%% 初期設定 (ロゴ、パス追加、Toolbox 確認、キーマップ更新、チュートリアル)
GUILDA

%% パスの取得
GUILDA.pwd

%% 環境設定 (設定ウィンドウが開く)
% 確認: 各タブの値を変更して保存 → @GUILDA/user/*.json に反映される
GUILDA.setting

%% チュートリアルの起動 (_GUILDAtutorial/Main.mlx が開く)
GUILDA.tutorial

%% GUILDA 内のクラスの一覧 (リンク付きのクラスツリー)
GUILDA.dictionary;

%% ドキュメントをブラウザで開く
GUILDA.doc

%% GUILDA クラスの新規作成 ... 未実装
% GUILDA.m に newclass が宣言されているが、実装ファイルは "@GUILDA/未実装newclass.m" のため呼び出せない
% GUILDA.newclass
