classdef LayerPackage < handle
% クラス内のパラメータの変更を管理するためのメソッドを実装＋インデックスとタグの管理
% obj.children : 本クラスの配下にある子クラスを格納。（e.g. PowerNetworkのchildrenにBranch/GlobalController/Bus, BusのChildrenにComponent、ComponentのChildrenにLocalController）
% obj.parent   : 本クラスを配下とする親クラスを格納。（e.g. ComponentのparentにBus、BranchのParentにPowerNetwork）
%
%
%  << プロパティ >>
%
%     prop         class      description
%==========================================================================
%   ・parent   |LayerPackage| 階層構造の上位層にあたるLayerPackageクラス
%   ・parent   |    cell    | 階層構造の下位層にあたるLayerPackageクラス
%   ・tag      |   string   | クラスの呼称
%   ・index    |   double   | インデックス番号、tagともにクラスの命名に使用
%   ・parameter|   table    | ユーザが設定する定数は全てこのプロパティで管理
%   ・editFlag |  logical   | 変更が加えられたかどうかの管理simulate前などに確認
%   ・editLog  |   table    | 変更内容を「変更時間・対象クラス・変更内容」で管理
%==========================================================================
%
%
%  <<子クラスで実装すべきこと>>
%
%   >> コストラクタ内でobj.parameterに規定値を入れること
%    ・ユーザが新しいparameterを設定する際には、このテーブル内のフィールド名と比較して検証します。
%  
%   >> プロパティchildrenをDependentプロパティとして定義＋合わせてgetメソッドを定義
%
%
%  <<親クラスとインデックスの登録>>
%
%   >> 登録：obj.born(parentInstance,index)
%   >> 解除：obj.release()
%
%
%  <<flagの書き換え>>
%
%   >> obj.onEdit(msg) 
%    ・edit_flagを'editted'に書き換え、変更したことを知らせる
%    ・parentに格納された親クラスのobj.onEditも再帰的に呼び出す。
% 
%   >> obj.applyEdit()
%    ・edit_flagを'initialized'に書き換え、変更したログをリセットする
%    ・chidrenに格納された配下のクラスのobj.unEditも再帰的に呼び出す。
% 
%  <<flagの確認>>
%
%   >> obj.check_editted()
%    ・edit_flagを見てクラスに変更が加えられていないか確認
%    ・flagに応じてエラーや警告を出力
%

    % properties(Dependent,Abstract,Access=protected)
    %     children (:,1) cell
    % end
    properties(Access=protected)
        parent   (1,1)  = nan
    end
    properties(SetAccess=private)
        index      (1,1) double = nan;
        editFlag   (1,1) string {mustBeMember(editFlag,["unset","initialized","editted"])} = "unset";
        editLog    (:,3) table  = array2table(zeros(0,3));
    end
    properties
        tag        (1,1) string {mustBeValidVariableName} = "NoTag";
        parameter  (1,:) table  = array2table(zeros(1,0));
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Definition of Layer Structure %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        belong(obj,parentInstance,index)
        disband(obj)
        checkParent(obj)
    end

    methods(Access=protected)
        onEdit(obj, log, time, tab)
        applyEdit(obj)
        flag = checkEdit(obj)
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Class Identification (Tag & Index) %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        out = get_tag(obj,l_with_layer, str_split)
        out = attach_tag(obj,str_name_list)
        [tab_out, struct_out] = information(obj, opt)
        
        function set.parameter(obj,tab)
            arguments
                obj 
                tab (1,:) table
            end
            vars = obj.parameter.Properties.VariableNames;
            tab  = tab(1,vars);
            flag = obj.parameter{1,:}~=tab{1,:};
            log  = tools.hcellfun(@(c) [char(c),','], vars(flag));
            obj.onEdit("edit parameter("+log(1:end-1)+")")
            obj.parameter = val;
        end


    end

end