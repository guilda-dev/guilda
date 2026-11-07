classdef GuiContentStub < PowerNetwork
% gui_content に表のページと未知の種類のページを加える系統 (DrawerModelGUI のページの描画を確かめるため)
%
%   net = DebugScript.helper.GuiContentStub();
%   h = net.gui();
%
% PowerNetwork のページ (Summary, Equilibrium) の後に "Table" (table) と "Unknown" (未知の種類) を加える。
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
                sct_page (:,1) struct  % ページ (s_title, s_type, content)
            end
            sct_page = gui_content@PowerNetwork(obj);
            sct_page(end+1,1) = struct("s_title","Table", "s_type","table", "content",table([1;2], ["a";"b"]));
            sct_page(end+1,1) = struct("s_title","Unknown", "s_type","latex", "content","x");
        end
    end
end
