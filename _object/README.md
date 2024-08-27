# GUILDA object

## 目次
- ["_object" フォルダとは](#anchor1)
- [+branch](#anchor2)
- [+bus](#anchor3)
- [+component](#anchor4)
	- [+component/+ConstSource](#anchor4-1)
	- [+component/+generator](#anchor4-2)
		- [+component/+generator/+abstract](#anchor4-2-1)
		- [+component/+generator/+avr](#anchor4-2-2)
		- [+component/+generator/+governor](#anchor4-2-3)
		- [+component/+generator/+pss](#anchor4-2-4)
	- [+component/+GFM](#anchor4-3)
		- [+component/+GFM/+controller](#anchor4-3-1)
		- [+component/+GFM/+DCsource](#anchor4-3-2)
		- [+component/+GFM/+ReferenceModel](#anchor4-3-3)
	- [+component/+load](#anchor4-4)
- [+controller](#anchor5)
- [+network](#anchor6)
	- [16-machine 68bus system](#anchor6-1)
	- [3-machine 9bus system](#anchor6-2)
	- [3bus test system](#anchor6-3)
	- [+network/+past_object](#anchor6-4)


<a id="anchor1"></a>
## "_object" フォルダとは

本フォルダは GUILDA で事前に用意された各種オブジェクトを格納しています。<br>
本READMEでは各種オブジェクトの詳細をまとめています。

GUILDAについては [こちら](../README.md) を参照ください。<br>
以下、説明文における「教科書」は [電力系統のシステム制御工学 (2022年11月コロナ社)](https://lim.ishizaki-lab.jp/guilda#h.66rvn04iyvio) を指します。


<a id="anchor2"></a>
## +branch
- 親クラス : branchクラス
- pi（対地静電容量を持つ送電線のπ型回路モデル）
	- 実行方法 : ``branch.pi(from, to, x, y)``
	- 引数
		- from, to : 接続する母線番
		- x : [1*2 double]の配列, インピーダンスの実部・虚部を並べた配列
		- y : double値, 対地静電容量の値
- pi_transformer（対地静電容量を持つ送電線のπ型回路モデルに位相調整変圧器が組み込まれたモデル）
	- 実行方法 : ``branch.pi_transformer(from, to, x, y, tap, phase)``
	- 引数
		- from, to : 接続する母線番
		- x : [1*2 double]の配列, インピーダンスの実部・虚部を並べた配列
		- y : double値, 対地静電容量の値
		- tap : double値, 電圧の絶対値の変化率
		- phase : double値, 電圧の偏角の変化量
- T（対地静電容量を持つ送電線のT型回路モデル）
	- 実行方法 : ``branch.T(from, to, x, y)``
	- 引数
		- from, to : 接続する母線番
		- x : [1*2 double]の配列, インピーダンスの実部・虚部を並べた配列
		- y : double値, 対地静電容量の値


<a id="anchor3"></a>
## +bus
- 親クラス : busクラス
- dammy（ダミークラス）
	- componentクラスのconnected_busプロパティのデフォルト値に利用される
- PQ（PQ母線）
	- 実行方法 : ``bus.PQ(P, Q, shunt)``
	- 引数
		- P : 有効電力Pの潮流設定値
		- Q : 無効電力Qの潮流設定値
		- shunt : 母線とグラウンドの間のアドミタンスの値
- PV（PV母線）
	- 実行方法 : ``bus.PQ(P, V, shunt)``
	- 引数
		- P : 有効電力Pの潮流設定値
		- V : 電圧の絶対値|V|の潮流設定値
		- shunt : 母線とグラウンドの間のアドミタンスの値
- PVarg（PVarg母線）
	- 実行方法 : ``bus.PQ(P, Vangle, shunt)``
	- 引数
		- P : 有効電力Pの潮流設定値
		- Vangle : 電圧の偏角∠Vの潮流設定値
		- shunt : 母線とグラウンドの間のアドミタンスの値
- slack（Slack母線）
	- 実行方法 : ``bus.slack(Vabs, Vangle, shunt)``
	- 引数
		- Vabs : 電圧の絶対値|V|の潮流設定値
		- Vangle : 電圧の偏角∠Vの潮流設定値
		- shunt : 母線とグラウンドの間のアドミタンスの値


<a id="anchor4"></a>
## +component
- empty（空の機器モデル）
	- 実行方法 : ``component.empty()``
	- 状態 : なし
	- 入力 : なし

<a id="anchor4-1"></a>
### +component/+ConstSource
- power（定電力電源モデル）
	- 実行方法 : ``component.ConstSource.power()``
	- 親クラス : component.load.abstractクラス
	- 状態 : なし
	- 入力 : 2ポート, 「有効電力の倍率, 無効電力の倍率」
	- ダイナミクスはload.powerと同じだが、正のPを持つ（電力を供給する）母線に付加されることを想定

<a id="anchor4-2"></a>
### +component/+generator
- classical（同期発電機の古典モデル）
	- 実行方法 : ``component.generator.classical(parameter)``
	- 状態 : 2変数, 「回転子偏角``delta``, 周波数偏差``omega``」
	- 入力 : 1ポート, 「機械入力``Pmech``」
	- parameter : table型, ``Xd, Xq, M, D``を列名として定義
- one_axis（同期発電機の1軸モデル）
	- 実行方法 : ``component.generator.one_axis(parameter)``
	- 状態 : 3変数, 「回転子偏角``delta``, 周波数偏差``omega``, 内部電圧``Ed``」
	- 入力 : 2ポート, 「界磁入力``Vfield``, 機械入力``Pmech``」
	- parameter : table型, ``Xd, Xd_p, Xq, Td_p, M, D``を列名として定義
- two_axis（同期発電機の2軸モデル）
	- 実行方法 : ``component.generator.two_axis(parameter)``
	- 状態 : 4変数, 「回転子偏角``delta``, 周波数偏差``omega``, 内部電圧``Ed, Eq``」
	- 入力 : 2ポート, 「界磁入力``Vfield``, 機械入力``Pmech``」
	- parameter : table型, ``Xd, Xd_p, Xq, Xq_p, Td_p, Tq_p, M, D``を列名として定義
- park（同期発電機のParkモデル）
	- 実行方法 : ``component.generator.park(parameter)``
	- 状態 : 6変数, 「回転子偏角``delta``, 周波数偏差``omega``, 内部電圧``Eq, Ed``, 鎖交磁束``psiq, psid``」
	- 入力 : 2ポート, 「界磁入力``Vfield``, 機械入力``Pmech``」
	- parameter : table型, ``Xd, Xd_p, Xd_pp, Xq, Xq_p, Xq_pp, X_ls, Td_p, Td_pp, Tq_p, Tq_pp, M, D``を列名として定義

<a id="anchor4-2-1"></a>
#### +component/+generator/+abstract
- Machine
	- すべてのgeneratorクラスの親クラス
	- "Machine_DataSheet.csv"で代表的なパラメータを定義
- SubClass
	- AVR, PSS, Governorを定義するスーパークラス
	- AVR, PSS, Governorモデルを実装する場合はこのクラスを継承する

<a id="anchor4-2-2"></a>
#### +component/+generator/+avr
- empty
	- モデル定義 : Vfd = u_avr1
	- 実行方法 : ``component.generator.avr.empty()``
- IEEE_DC1
	- モデル定義 : 教科書 p221~224, Robust Control in Power Systems p.43
	- 実行方法 : ``component.generator.avr.IEEE_DC1(parameter)``
	- parameter
		- string型 : "Anderson", "Sauer" ("IEEE\_DC1\_DataSheet.csv"で定義)
		- table型 : ``Ttr, Kap, Tap, Vap_max, Vap_min, Kst, Tst, Aex, Tex, a_ex, b_ex``を列名として定義
			- ただし、``Tex~=0, Tst~=0, Tap~=0``とする。``Tex=0``のときはIEEE_ST1を使うこと。
- IEEE_ST1
	- モデル定義 : 教科書 p.224~226
	- 実行方法 : ``component.generator.avr.IEEE_ST1(parameter)``
	- parameter
		- string型 : "Kundur", "Board", "Chow", "Sadamoto" ("IEEE\_ST1\_DataSheet.csv"で定義)
		- table型 : ``Ttr, Tap, Kap, gamma_max, gamma_min, k0``を列名として定義
- avr_sadamoto2019について
	- 現在は IEEE_ST1に統合済み
	- ``Ka``が``Kap``に、``Te``が``Tap``に対応
	- ``Ttr=0, gammma_max=inf, gamma_min=-inf, k0=0``とする

<a id="anchor4-2-3"></a>
#### +component/+generator/+governor
- empty
	- モデル定義 : Pmech = u_gov1
	- 実行方法 : ``component.generator.governor.empty()``

<a id="anchor4-2-4"></a>
#### +component/+generator/+pss
- empty
	- モデル定義 : v_pss = 0*omega
	- 実行方法 : ``component.generator.pss.empty()``
- IEEE_PSS1
	- モデル定義 : 教科書 p.230~232
	- 実行方法 : ``component.generator.avr.IEEE_PSS1(parameter)``
	- parameter
		- string型 : "Kundur", "Kundur12_5", "Kundur12_8", "Board", "Chow" (IEEE_PSS1_DataSheet.csvで定義)
		- table型 : ``Kpss, Tws, Td1, Tn1, Td2, Tn2, V_min, Vmax``を列名として定義

<a id="anchor4-3"></a>
### +component/+GFM
- 不明（編集中）

<a id="anchor4-3-1"></a>
#### +component/+GFM/+controller
- 不明（編集中）

<a id="anchor4-3-2"></a>
#### +component/+GFM/+DCsource
- 不明（編集中）

<a id="anchor4-3-3"></a>
#### +component/+GFM/+ReferenceModel
- 不明（編集中）

<a id="anchor4-4"></a>
#### +component/+load
- abstract
	- すべてのloadクラスの親クラス
- current（定電流負荷モデル）
	- 実行方法 : ``component.load.current()``
	- 状態 : なし
	- 入力 : 2ポート, 「電流フェーザの実部, 虚部」
- impedance（定インピーダンス負荷モデル）
	- 実行方法 : ``component.load.impedance()``
	- 状態 : なし
	- 入力 : 2ポート, 「インピーダンス値の実部, 虚部」
- power（定電力負荷モデル）
	- 実行方法 : ``component.load.power()``
	- 状態 : なし
	- 入力 : 2ポート, 「有効電力, 無効電力」
- voltage（定電圧負荷モデル）
	- 実行方法 : ``component.load.voltage()``
	- 状態 : なし
	- 入力 : 2ポート, 「電圧フェーザの実部, 虚部」


<a id="anchor5"></a>
## +controller
- 親クラスはcontrollerクラス
- broadcast_PI_AGC（AGCコントローラ）
	- 実行方法 : ``controller.broadcast_PI_AGC(net, y_idx, u_idx, Kp, Ki)``
	- 引数
		- net : networkクラスのインスタンス
		- y_idx : double配列, 観測元の機器の番号
		- u_idx : double配列, 入力先の機器の番号
		- Kp : double値, Pゲイン（ネガティブフィードバックの場合は負の値に）
		- Ki : double値, Iゲイン（ネガティブフィードバックの場合は負の値に）
- local_LQR（LQRコントローラ）
	- 実行方法 : ``controller.local_LQR(net, idx, Q, R, port_input)``
	- 引数
		- net : networkクラスのインスタンス
		- idx : double配列, 制御対象の母線番号
		- Q, R : doble配列, 状態量・入力量の重み行列
		- port_input : string型, 入力ポート名 (デフォルトは'all')
- local_LQR_retrofit（内部制御器がLQRのレトロフィットコントローラ（実部虚部））
	- 実行方法 : ``controller.local_LQR_retrofit(net, idx, Q, R, model, model_agc)``
	- 引数
		- net : networkクラスのインスタンス
		- idx : double配列, 制御対象の母線番号
		- Q, R : doble配列, 状態量・入力量の重み行列
		- model : ss型, 環境モデルの一部（(delta, E)->(angleV, absV)）入出力は実部虚部表示
		- model_agc : ss型, AGCのモデル
- local_LQR_retrofit_polar（内部制御器がLQRのレトロフィットコントローラ（極座標））
	- 実行方法 : ``controller.local_LQR_retrofit_polar(net, idx, Q, R, model, model_agc)``
	- 引数
		- net : networkクラスのインスタンス
		- idx : double配列, 制御対象の母線番号
		- Q, R : doble配列, 状態量・入力量の重み行列
		- model : ss型, 環境モデルの一部（(delta, E)->(angleV, absV)）入出力は極座標表示
		- model_agc : ss型, AGCのモデル


<a id="anchor6"></a>
## +network
- build
	- 新規ネットワークの作成を行う関数
	- 実行方法 : ``net = build(filepath, type_generator)``
	- 引数
		- filepath : ネットワークの情報(Excelファイル)をまとめたフォルダのパスを指定
		- type_generator : 発電機の種類を指定 ('classical', '1axis', '2axis', 'park'など)

<a id="anchor6-1"></a>
### 16-machine 68bus system
各モデルの参照先と母線1
- IEEE68bus
	- 教科書 p.253~255
- IEEE68bus_original
	- Robust Control in Power Systems p.171~178
- IEEE68bus_past
	- GUILDAの前身となるシミュレータで使用していたモデル

以下は、IEEE68busを基準にしたときのネットワークを構成する各要素の比較です。

||母線番号|IEEE68bus|IEEE68bus_original|IEEE68bus_past|
|:--:|:--:|:--:|:--:|:--:|:--:|
|送電網[^1]|1-68|変圧器なし|一部変圧器あり|一部変圧器あり<br>(IEEE68bus_originalと同じ)|
|潮流設定|1-68|-|変更なし|変更なし|
|発電機|1-12|-|Mの値が68busの値の2倍|Mの値が68busの値の2倍|
|発電機|13-16|-|Mの値が68busの値の2倍|Mの値が68busの値の4倍|
|負荷|1-16|-|変更なし|変更なし|
|avr|1-9|IEEE_ST1|IEEE_DC1|sadamoto2019|
|avr|10|IEEE_ST1|IEEE_ST1<br>(IEEE68busと異なるパラメータ)|sadamoto2019|
|avr|11-16|IEEE_ST1|なし|sadamoto2019|
|pss|1-9,11-16|IEEE_PSS1|なし|sadamoto2019|
|pss|10|IEEE_PSS1|IEEE_PSS1<br>(IEEE68busと異なるパラメータ)|sadamoto2019|

[^1]: 送電網パラメータはtap(変圧器のパラメータ)を除き、すべて同一

<a id="anchor6-2"></a>                
### 3-machine 9bus system
- IEEE9bus
	- Power System Dynamics and Stability : With Synchrophasor Measurement and Power System Toolbox p.142~144
- IEEE9bus_past
	- GUILDA前身となるシミュレータで使用したモデル

以下は、IEEE9busを基準にしたときのネットワークを構成する各要素の比較です。

||母線番号|IEEE9bus|IEEE9bus_past|
|:-:|:-:|:-:|:-:|
|送電網|1-9|-<br>(変圧器なし, ロスあり)|変更なし|
|潮流設定|1|-|異なるP_genの値|
|潮流設定|2-9|-|変更なし|
|発電機|1-3|-|すべて異なるパラメータ|
|avr|1-3|IEEE\_DC1|sadamoto2019|
|pss|1-3|なし|sadamto2019|

<a id="anchor6-3"></a>
### 3bus test system
- Tutorial3bus
	- GUILDA Doc(Tutorial)で作成した3busテストシステム

<a id="anchor6-4"></a>
### +network/+past_object
- avr_sadamoto2019
	- モデル定義 : T.sadamoto, Dynamic Modeling, Stability, and Control of Power Systems With Distributed Energy Resources: Handling Faults Using Two Control Methods in Tandem, IEEE Control Systems Magazine, 2019.
	- 親クラス : component.generator.avr.IEEE_ST1
	- 実行方法 : ``network.past_object.avr_sadamoto2019``
	- parameter : table型, ``Ka, Te``を列名として定義
- pss_sadamoto2019
	- モデル定義 : T.sadamoto, Dynamic Modeling, Stability, and Control of Power Systems With Distributed Energy Resources: Handling Faults Using Two Control Methods in Tandem, IEEE Control Systems Magazine, 2019.
	- 親クラス : component.generator.abstract.SubClass
	- 実行方法 : ``network.past_object.pss_sadamoto2019``
	- parameter : table型, ``Kpss, Tpss, TL1p, TL1, TL2p, TL2``を列名として定義

