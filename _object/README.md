# GUILDA object (編集中)

## 目次
- ["_object" フォルダとは](#anchor1)
- [+branch](#anchor2)
- [+bus](#anchor3)
- [+component](#anchor4)
	- [+ConstSource](#anchor4-1)
	- [+generator](#anchor4-2)
		- [+abstract](#anchor4-2-1)
		- [+avr](#anchor4-2-2)
		- [+governor](#anchor4-2-3)
		- [+pss](#anchor4-2-4)
	- [+GFM](#anchor4-3)
		- [+controller](#anchor4-3-1)
		- [+DCsource](#anchor4-3-2)
		- [+ReferenceModel](#anchor4-3-3)
	- [+load](#anchor4-4)
- [+controller](#anchor5)
- [+network](#anchor6)
	- [16-machine 68bus system](#anchor6-1)
	- [3-machine 9bus system](#anchor6-2)
	- [3bus test system](#anchor6-3)


<a id="anchor1"></a>
## "_object" フォルダとは

本フォルダは GUILDA で事前に用意された各種オブジェクトを格納しています。<br>
本READMEでは各種オブジェクトの詳細をまとめています。

GUILDAについては [こちら](../README.md) を参照ください。<br>
以下、説明文における「教科書」は [電力系統のシステム制御工学 (2022年11月コロナ社)](https://lim.ishizaki-lab.jp/guilda#h.66rvn04iyvio) を指します。


<a id="anchor2"></a>
## +branch


<a id="anchor3"></a>
## +bus


<a id="anchor4"></a>
## +component


<a id="anchor4-1"></a>
### +component/+ConstSource


<a id="anchor4-2"></a>
### +component/+generator


<a id="anchor4-2-1"></a>
#### +component/+generator/+abstract


<a id="anchor4-2-2"></a>
#### +component/+generator/+avr
- empty
	- モデル定義 : Vfd = u_avr1
	- 実行方法 : ``component.generator.avr.empty()``
- IEEE_DC1
	- モデル定義 : 教科書 p221~224, Robust Control in Power Systems p.43
	- 実行方法 : ``component.generator.avr.IEEE_DC1(parameter)``
	- parameter
		- string型 : "Anderson", "Sauer" (IEEE_DC1_DataSheet.csvで定義)
		- table型 : ``Ttr, Kap, Tap, Vap_max, Vap_min, Kst, Tst, Aex, Tex, a_ex, b_ex``を列名として定義
			- ただし、``Tex~=0, Tst~=0, Tap~=0``とする。``Tex=0``のときはIEEE_ST1を使うこと。
- IEEE_ST1
	- モデル定義 : 教科書 p.224~226
	- 実行方法 : ``component.generator.avr.IEEE_ST1(parameter)``
	- parameter
		- string型 : "Kundur", "Board", "Chow", "Sadamoto" (IEEE_ST1_DataSheet.csvで定義)
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


<a id="anchor4-3-1"></a>
#### +component/+GFM/+controller


<a id="anchor4-3-2"></a>
#### +component/+GFM/+DCsource


<a id="anchor4-3-3"></a>

#### +component/+GFM/+ReferenceModel


<a id="anchor4-4"></a>

#### +component/+load


<a id="anchor5"></a>
## +controller


<a id="anchor6"></a>
## +network
例えば、``net = network.IEEE68bus;``などで事前に用意されたネットワークオブジェクトを呼び出すことができる。

<a id="anchor6-1"></a>
### 16-machine 68bus system
- IEEE68bus
	- 教科書 p.253~255
- IEEE68bus_original
	- Robust Control in Power Systems p.171~178
- IEEE68bus_past
	- GUILDAの前身となるシミュレータで使用していたモデル

以下は、IEEE68busを基準にしたときのネットワークを構成する各要素の比較です。

||母線番号|IEEE68bus|IEEE68bus_original[^1]|IEEE68bus_past[^1]|
|:--:|:--:|:--:|:--:|:--:|:--:|
|送電網|1-16|変圧器なし|一部変圧器あり|一部変圧器あり<br>(IEEE\_68bus\_originalと同じ)|
|発電機|1-12|-|Mの値が68busの値の2倍|Mの値が68busの値の2倍|
|発電機|13-16|-|Mの値が68busの値の2倍|Mの値が68busの値の4倍|
|負荷|1-16|-|変更なし|変更なし|
|avr|1-9|IEEE_ST1|IEEE_DC1|IEEE\_ST1<br>(IEEE\_68busとは異なるパラメータ)|
|avr|10|IEEE_ST1|IEEE_ST1|IEEE\_ST1<br>(IEEE\_68busとは異なるパラメータ)|
|avr|11-16|IEEE_ST1|avrなし|IEEE\_ST1<br>(IEEE\_68busとは異なるパラメータ)|
|pss|1-9,11-16|IEEE_PSS1|pssなし|IEEE\_PSS1<br>(IEEE\_68busとは異なるパラメータ)|
|pss|10|IEEE_PSS1|IEEE_PSS1|IEEE\_PSS1<br>(IEEE\_68busとは異なるパラメータ)|

[^1]: IEEE\_68bus\_originalとIEEE\_68bus\_past

<a id="anchor6-2"></a>                
### 3-machine 9bus system


<a id="anchor6-3"></a>
### 3bus test system

