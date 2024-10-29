function anime(obj,net,varargin)
%ー実行方法ー
%>> obj.anime(net);
%>> obj.anime(net,Name,Value,...)
%
%ー引数ー
%・ Name  : 'style'
%   　      グラフ構造の表示形式
%　 Value : 'style1','style2','style3'
% 　既定値 : 'style3'
%
%
% ・ Name  : 'height'
%   　      グラフプロットのノードのZ座標に対応するパラメータ
%　 Value : V,Vreal,Vimag,Vabs,Vangle
%  　       I,Ireal,Iimag,Iabs,Iangle
% 　        power,P,Q,S
% 　        X,各機器で定義した状態変数名
% 　既定値 : 'P'
%
%・ Name  : 'height_base'
%   　      グラフプロットのノードのZ座標に対応するパラメータのオフセット
%　 Value :　・double値 ・・・指定された値をオフセットとする
%           ・'equilibrium'・・・そのパラメータの平衡点
%           ・'final' ・・・そのパラメータの応答結果の最終値
% 　既定値 : 0
%
%
%
%・ Name  : 'color'
%   　      グラフプロットのノードの色に対応するパラメータ
%　 Value : V,Vreal,Vimag,Vabs,Vangle
%  　       I,Ireal,Iimag,Iabs,Iangle
% 　        power,P,Q,S
% 　        X,各機器で定義した状態変数名
% 　既定値 : 'P'
%
%・ Name  : 'color_base'
%   　      グラフプロットのノードの色に対応するパラメータのオフセット
%　 Value :　・double値 ・・・指定された値をオフセットとする
%           ・'equilibrium'・・・そのパラメータの平衡点
%           ・'final' ・・・そのパラメータの応答結果の最終値
% 　既定値 : 0
%
%
%
%・ Name  : 'size'
%   　      グラフプロットのノードのサイズに対応するパラメータ
%　 Value : V,Vreal,Vimag,Vabs,Vangle
%  　       I,Ireal,Iimag,Iabs,Iangle
% 　        power,P,Q,S
% 　        X,各機器で定義した状態変数名
% 　既定値 : 'P_abs'
%
%・ Name  : 'size_base'
%   　      グラフプロットのノードのサイズに対応するパラメータのオフセット
%　 Value :　・double値 ・・・指定された値をオフセットとする
%           ・'equilibrium'・・・そのパラメータの平衡点
%           ・'final' ・・・そのパラメータの応答結果の最終値
% 　既定値 : 0
%
%
    supporters.for_simulate.solfactory.animator(obj,net,varargin{:});
end