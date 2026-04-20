<img src="https://github.com/guilda-dev/guilda/assets/54563775/20094d9b-22f5-4fb8-aff8-d80dc3cde31b" width="800">

# GUILDA: Grid & Utility Infrastructure Linkage Dynamics Analyzer

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=guilda-dev/guilda&project=./GUILDA.prj)


## About
GUILDA is a numerical simulator for smart energy management, developed primarily by our laboratory in collaboration with Assistant Professor Takahiro Kawaguchi (Gunma University). 
Its goal is to provide an advanced simulation environment that students and researchers in systems and control can use with only minimal background knowledge of power systems. 

It is also closely linked with a [textbook (Publishing, November 2022)](https://lim.ishizaki-lab.jp/guilda#h.66rvn04iyvio) that explains related concepts in the language of systems and control, so that users can learn mathematical foundations and simulation modeling in parallel.
Through these efforts, we aim to establish power systems as an accessible benchmark domain in systems and control, and to help apply the field’s technologies and insights to power system reform.

---

## Requirement
- MATLAB
- Control system toolbox
- Optimization toolbox
- Symboric Math toolbox
---

## Setup

First, run `GUILDA` to set up the environment and add necessary paths. 
```matlab
>> GUILDA
```
In this process, the following steps are automatically executed:
- If cloned from Git, the latest version is pulled.
- Paths for functions and class files necessary for analysis are added.
- The installation of toolboxes that support functions used in GUILDA is checked.
- A live editor for tutorials is opened.
If you do not want to pull every time you start, or if you do not want the tutorial to open every time, you can change the settings from the environment settings.
```matlab
>> GUILDA.setting
```
Start the environment settings screen and change the values of the corresponding items in the `startup` tab.

If you want to use any utility functions, you can call them as follows:
```matlab
>> GUILDA.rmpath()      % Remove GUILDA paths if needed 
>> GUILDA.addpath()     % Re-add GUILDA paths if needed
>> GUILDA.setting()     % Check settings and environment
>> GUILDA.tutorial()    % Access tutorials
>> GUILDA.dictionary()  % dictionary for GUILDA-specific classes
```

## Basic Workflow
For users who want to learn through hands-on experience, please refer to the [**Tutorial section**](./Tutorial.md).

### 1. Modeling
First, create a power system model by 
- building a network using either manual construction
- predefined templates in `_GUILDAobject/+network/`. 

This involves defining buses, branches, and components, and connecting them together to form a complete power system model.

### 2. Power Flow Calculation
Next, we perform power flow calculations to determine the voltage and current distribution in the system. 
Power flow calculations can be done using the `calculate_powerflow(obj)` method.
But if you want to set the operating points easily, it is recommended to use the `initialize(obj)` method, which not only performs power flow calculations but also sets up equilibrium points for dynamic simulations.

### 3. Analysis
After setting up the power flow conditions, you can perform various analyses such as dynamic simulations using the `simulate(obj)` method, or optimal power flow calculations using the `optimize_powerflow(obj)` method.

#### _**・Dynamic Simulation**_
Dynamic simulations can be performed using the `simulate(obj)` method, which simulates the time-domain
response of the system to various disturbances or inputs.

#### _**・Linearization**_
Linearization around an operating point can be performed using the `get_sys(obj)` method, whichreturns the linearized state-space representation of the system. 
This is useful for control design and stability analysis.

More detailed instructions and examples for each of these analysis types can be found in the [**PowerNetwork Class**](./PowerNetwork.md) methods.

---

## Development Guidelines

### 1. Folder Structure

| Folder Name        | Description                               |
|--------------------|-------------------------------------------|
| `@GUILDA/`|GUILDA's utility functions|
|`_GUILDAsystem/`|Analysis framework and common base classes|
|`_GUILDAobject/`|Specific device models, transmission line models, and network templates|
|`_GUILDAtutorial/`|Tutorial live script files|

### 2. Class Structure
Main classes are as follows, with `PowerNetwork` serving as the central class that defines and contains various components to build the model.
GUILDA is constructed with object-oriented programming (OOP) principles, and the class structure is organized into several layers.
See the [**Class Structure section**](./GUILDAsystem.md) for details.

| Class | Description | 
|------------|-------------|
| `PowerNetwork` | Represents the entire power network. This is the central class for model management and analysis execution. | 
| `Bus` | Represents a bus in the power system. Multiple components can be attached to each bus. |
| `Branch` | Represents transmission lines and transformers, and serves as the base class for concrete branch models. |
| `Cubicle` | Represents connection points between buses and other objects. |
| `Component` | Represents devices such as generators, loads, and inverters, and serves as the base class for concrete component models. | 
| `LocalController` | Represents local controllers attached to components, such as AVR and PSS. | 
| `GlobalController` | Represents global controllers that can coordinate multiple components, such as AGC. |
|`Cubicle` | Represents connection points in the network, such as links between buses and branches/components. |


### 3. Naming Conventions
In internal scripts, variables should generally be defined with prefixes.
Use the naming format **`[variableType][size]_[variableDescription]`** (snake_case).
See the quick reference [**[here]**](./NamingConventions.md).


## Related Book
[電力系統のシステム制御工学- システム数理とMATLABシミュレーション - ](https://www.jstage.jst.go.jp/article/sicejl/62/10/62_640/_pdf/-char/ja)

## Authors
- [Takahiro Kawaguchi (Gunma University)](http://hashi-lab.ei.st.gunma-u.ac.jp/~hashimotos/member/kawaguchi/)
- [Takayuki Ishizaki (Tokyo Institute of Technology)](https://lim.ishizaki-lab.jp)

Many students from the Ishizaki Laboratory have also contributed to this project.



<!-- <img src="https://github.com/guilda-dev/guilda/assets/54563775/20094d9b-22f5-4fb8-aff8-d80dc3cde31b" width="800">

# GUILDA: Grid & Utility Infrastructure Linkage Dynamics Analyzer

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=guilda-dev/guilda&project=./GUILDA.prj)

## About
GUILDAは、本研究室と川口助教（群馬大）を中心に開発を進めているスマートエネルギーマネジメントの数値シミュレータです。システム制御分野の学生や研究者に対して、最小限の電力システムの知識だけで利用可能な先端的な数値シミュレーション環境を提供することを目的としています。関連知識をシステム制御分野のことばで解説した[教科書（2022年11月コロナ社）](https://lim.ishizaki-lab.jp/guilda#h.66rvn04iyvio)とも密に連携させることで、数学的な基礎と数値シミュレーション環境の構築を並行して学習できるように工夫しています。

このような活動を通して、電力システムを身近なベンチマークモデルとしてシステム制御分野に定着させることにより、本分野の技術や知見が電力システム改革を推進する一助となることを目指しています。

## Requirement
- MATLAB
- Control system toolbox
- Optimization toolbox
- Symboric Math toolbox

## Usage

はじめに``GUILDA``と実行します。
```
>> GUILDA
```
これにより、GUILDAが起動されます。起動時に以下の処理が自動的に実行されます。
- Gitからcloneしている場合、最新バージョンをpull
- 解析に必要な関数・クラスファイルのパスを追加
- GUILDA内で使用する関数をサポートするtoolboxのインストールの確認
- Tutorial用のライブエディタを開く

※起動するたびにpullをしたくない場合、またTutorialが毎回開くのが不要である場合は環境設定から変更できます。
```matlab
>> GUILDA.setting
```
環境設定画面を起動し、``startup``タブの各種対応項目の値を変更してください。


## Pre-Prepared Objects
``_GUILDAobject``フォルダを参照のこと。<br>
具体的な各種オブジェクトの説明は[こちら](./_object/README.md)をご覧ください。 

## Reference

#### ▶Tutorial
はじめて使用する方向けにライブエディタを使用したTutorialを用意しています。
```matlab
>> GUILDA.tutorial
```

[**<span style="color: red; "><u>研究室HP</u></span>**](https://lim.ishizaki-lab.jp/guilda)**<span style="color: red; ">のTutorialサイトは旧バージョンのGUILDAに対応するため、現バージョンでは一部実行方法が変更されています。
Tutorialサイトの代替として現在はソースコード内にライブエディタのutorialが組み込まれています。</span>**


#### ▶関連書籍
[ 電力系統のシステム制御工学- システム数理とMATLABシミュレーション - ](https://www.jstage.jst.go.jp/article/sicejl/62/10/62_640/_pdf/-char/ja)

## Author
- [川口貴弘（群馬大学）](http://hashi-lab.ei.st.gunma-u.ac.jp/~hashimotos/member/kawaguchi/)
- [石崎孝幸（東京工業大学）](https://lim.ishizaki-lab.jp)

と，石崎研究室の多くの学生が携わっています． -->
