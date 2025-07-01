<img src="https://github.com/guilda-dev/guilda/assets/54563775/20094d9b-22f5-4fb8-aff8-d80dc3cde31b" width="800">

# GUILDA: Grid & Utility Infrastructure Linkage Dynamics Analyzer

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=guilda-dev/guilda&project=./GUILDA.prj)

## About
GUILDAは、本研究室と川口助教（群馬大）を中心に開発を進めているスマートエネルギーマネジメントの数値シミュレータです。システム制御分野の学生や研究者に対して、最小限の電力システムの知識だけで利用可能な先端的な数値シミュレーション環境を提供することを目的としています。関連知識をシステム制御分野のことばで解説した[教科書（2022年11月コロナ社）](https://lim.ishizaki-lab.jp/guilda#h.66rvn04iyvio)とも密に連携させることで、数学的な基礎と数値シミュレーション環境の構築を並行して学習できるように工夫しています。

このような活動を通して、電力システムを身近なベンチマークモデルとしてシステム制御分野に定着させることにより、本分野の技術や知見が電力システム改革を推進する一助となることを目指しています。

## Requirement
- MATLAB
- Control system toolbox
- Optimization toolbox

## Usage

使用する際は必ず初めにプロジェクトファイル``GUILDA.prj``を起動してください。
「現在のフォルダー」のウィンドウ内の``GUILDA.prj``をダブルクリックすると起動できます。

<img src="https://github.com/guilda-dev/guilda/assets/54563775/a83a40cc-8cff-4f8e-a466-6189f7e563fc" width="500">
  

- プロジェクトを起動すると必要なファイルのパスが追加されGUILDA内の各種クラスが使用可能になります。
- またプロジェクト開始時に自動的にTutorial用のライブエディタが開きます。

※Tutorialが毎回開くのが不要である場合は、ソースコード内の``config.json``ファイルを開き``Tutorial``の項目を``off``にしてください。

## Pre-Prepared Objects
``_object``フォルダを参照のこと。<br>
具体的な各種オブジェクトの説明は[こちら](./_object/README.md)をご覧ください。 

## Reference

#### ▶Tutorial
本リポジトリ、ソースコード内の``_Tutorial``フォルダにTutorial用のライブエディタが作成されています。
GUILDAの基本的な使用方法はそちらを参照ください。

[**<span style="color: red; "><u>研究室HP</u></span>**](https://lim.ishizaki-lab.jp/guilda)**<span style="color: red; ">のTutorialサイトは旧バージョンのGUILDAに対応するため、現バージョンでは一部実行できません。
現在はソースコード内にライブエディタとしてTutorialが組み込まれています。</span>**


#### ▶関連書籍
[ 電力系統のシステム制御工学- システム数理とMATLABシミュレーション - ](https://www.jstage.jst.go.jp/article/sicejl/62/10/62_640/_pdf/-char/ja)

## Author
- [川口貴弘（群馬大学）](http://hashi-lab.ei.st.gunma-u.ac.jp/~hashimotos/member/kawaguchi/)
- [石崎孝幸（東京工業大学）](https://lim.ishizaki-lab.jp)

と，石崎研究室の多くの学生が携わっています．
