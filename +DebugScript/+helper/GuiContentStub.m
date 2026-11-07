classdef GuiContentStub < PowerNetwork
% gui_content から全種類のページを返す系統 (DrawerModelGUI のページの描画を確かめるため)
%
%   net = DebugScript.helper.GuiContentStub();
%   h = net.gui();
%
% 基底のページ (PowerNetwork の image.svg) の後に latex, ascii, table, action, custom を加える。
% action を押すと n_action が 1 増え、custom は描画先のコンテナを h_custom に残す。
    properties
        n_action (1,1) double = 0      % action のボタンが押された回数
        h_custom = []                  % custom のページの描画先のコンテナ
        l_fail (1,1) logical = false   % true のとき action がエラーになる
    end
    methods
        function obj = GuiContentStub()
            arguments (Output)
                obj  % 作成した系統
            end
            obj@PowerNetwork("Stub");
        end
    end
    methods (Access = protected)
        function sct_page = gui_content(obj)
            arguments (Input)
                obj
            end
            arguments (Output)
                sct_page (:,1) struct  % ページ (s_title, s_type, content, s_label)
            end
            sct_page = gui_content@PowerNetwork(obj);
            sct_page(end+1,1) = struct("s_title","Equation", "s_type","latex", "content","$\dot{x} = f(x,u)$", "s_label","");
            sct_page(end+1,1) = struct("s_title","ASCII", "s_type","ascii", "content",["+--+"; "|SG|"; "+--+"], "s_label","");
            sct_page(end+1,1) = struct("s_title","Table", "s_type","table", "content",table([1;2], ["a";"b"]), "s_label","");
            sct_page(end+1,1) = struct("s_title","Action", "s_type","action", "content",@() obj.act(), "s_label","Run");
            sct_page(end+1,1) = struct("s_title","Custom", "s_type","custom", "content",@(h) obj.draw(h), "s_label","");
        end
    end
    methods (Access = private)
        function act(obj)
            arguments (Input)
                obj
            end
            arguments (Output)
            end
            if obj.l_fail
                error("GuiContentStub:Fail", "action failed")
            end
            obj.n_action = obj.n_action + 1;
        end
        function draw(obj, h)
            arguments (Input)
                obj
                h  % 描画先のコンテナ
            end
            arguments (Output)
            end
            obj.h_custom = h;
            uilabel(h, "Text", "custom page");
        end
    end
end
