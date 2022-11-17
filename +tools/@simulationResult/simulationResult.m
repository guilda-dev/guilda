classdef simulationResult < handle
%
%ーフィールドー
%       既存の"net.simulate()"の出力結果に以下のフィールドを追加
%         Vabs : 母線電圧の絶対値の応答
%        Vangle: 母線電圧の偏角の応答
%         Iabs : 母線電流の絶対値の応答
%        Iangle: 母線電流の偏角の応答
%          P   : 有効電力の応答
%          Q   : 無効電力の応答
%

    properties(SetAccess = protected)
        t
        X
        V
        I
        Xk
        U
        Xk_global
        U_global
        power

        simulated_bus
        fault_bus
        Ymat_reproduce
        sols
        linear
    end

    properties(Access=private)
        net_data
    end

    methods

        function obj = simulationResult(out,net,varargin)
            if nargin==3
                obj.readme
            end
            %母線電圧/電流の絶対値/偏角、また電力P,Qの時間応答を追加する。
            bus_num = numel(out.V);
            V_Phasor = tools.arrayfun(@(b) out.V{b}(:,1)+1j*out.V{b}(:,2), (1:bus_num)');
            I_Phasor = tools.arrayfun(@(b) out.I{b}(:,1)+1j*out.I{b}(:,2), (1:bus_num)');
            PQ       = tools.arrayfun(@(b) V_Phasor{b}.*conj(I_Phasor{b}), (1:bus_num)');

            fdata = @(data,idx) [real(data{idx}),imag(data{idx}),abs(data{idx}),angle(data{idx})];
            fname = {'real','imag','abs','angle'};
            obj.V  = tools.arrayfun(@(b) array2table(fdata(V_Phasor,b),'VariableNames',fname),(1:bus_num)');
            obj.I  = tools.arrayfun(@(b) array2table(fdata(I_Phasor,b),'VariableNames',fname),(1:bus_num)');
            obj.X  = tools.arrayfun(@(b) array2table(out.X{b},'VariableNames',net.a_bus{b}.component.get_state_name),(1:bus_num)');
            obj.power = tools.arrayfun(@(b) array2table([real(PQ{b}),imag(PQ{b}),abs(PQ{b}),angle(PQ{b})],"VariableNames",{'P','Q','S','Factor'}),(1:bus_num)');
            
            fport = @(name,idx) tools.cellfun(@(c) [c,'(bus',num2str(idx),')'],name);
            fname = @(con) tools.harrayfun(@(idx) fport(reshape(net.a_bus{idx}.component.get_port_name,1,[]),idx), con.index_input);
            obj.U  = tools.arrayfun(@(b) array2table(out.U{b},'VariableNames',fname(net.a_controller_local{b})),(1:numel(out.U))');
            obj.Xk = tools.arrayfun(@(b) array2table(out.Xk{b},'VariableNames',net.a_controller_local{b}.get_state_name),(1:numel(out.U))');
            obj.U_global  = tools.arrayfun(@(b) array2table(out.U_global{b},'VariableNames',fname(net.a_controller_global{b})),(1:numel(out.U_global))');
            obj.Xk_global = tools.arrayfun(@(b) array2table(out.Xk_global{b},'VariableNames',net.a_controller_global{b}.get_state_name),(1:numel(out.U_global))');

            %解析を行ったpower_networkの情報を抽出
            obj.net_data = net.information('do_report',false);
            [tag,~,idx] = unique(tools.cellfun(@(idx) class(idx.component), net.a_bus),'stable');
            obj.net_data.component_list.tag = tag;
            obj.net_data.component_list.idx = idx;
            obj.net_data.admittance_matrix  = net.get_admittance_matrix;
            obj.net_data.state_list = tools.cellfun(@(idx) idx.component.get_state_name, net.a_bus);
            obj.net_data.equilibrium_list = tools.cellfun(@(idx) idx.component.x_equilibrium, net.a_bus);
            obj.net_data.bus_list = tools.cellfun(@(idx) class(idx), net.a_bus);


            field = fieldnames(out);
            for i =1:numel(field)
                if isempty(obj.(field{i}))
                    obj.(field{i}) = out.(field{i});
                end
            end

        end

        function data = get_NetData(obj)
            data = obj.net_data;
        end
        
        %応答プロットに関するmethod
        function UIplot(obj)
            %ー実行方法ー
            %>> obj.UIplot()
            %
            tools.UIplot(obj);
        end
        varargout = plot(obj,para,bus_idx,varargin);
        data = plot_reference(obj,statename,set);

        %応答のアニメーションに関するmethod
%         function UIanime(obj)
%             %＊＊＊未実装＊＊＊
%             %ー実行方法ー
%             %>> obj.UIanime()
%             %
%             tools.UIanime(obj);
%         end
        anime(obj)

        
        %使い方の表示
        function readme(obj)
            fprintf(['\n' ...
                '==================================\n',...
                '  シミュレーション結果出力の補助ツール  \n',...
                '      SimulationResultクラス       \n',...
                '==================================\n\n'])
            answer = input('使い方を表示しますか？(y/n)：',"s");
            if strcmp(answer,'y')
                help(class(obj))
                disp('応答プロットを表示したい場合')
                disp('------------------------')
                disp('● UIを使う場合')
                help([class(obj),'.UIplot'])
                disp('● コマンドで実行する場合')
                disp('ー実行方法ー')
                disp(' >> obj.plot();')
                fprintf(' >> obj.plot(Name,Value,...)')
                fprintf([' <a href="matlab:' ,...
                        'disp('' '');',...
                        'disp([''コマンドでプロットの実行をする場合'']);',...
                        'disp(''==================================================='');',...
                        'help([''',class(obj),''',''.plot'']);',...
                        'disp(''==================================================='');',...
                        'disp('' '');',...
                        '">[引数の指定方法]</a>\n\n\n'])
                disp('アニメーションを表示したい場合')
                disp('-------------------------')
                disp('● コマンドで実行する場合')
                disp('ー実行方法ー')
                disp(' >> obj.anime();')
                fprintf(' >> obj.anime(Name,Value,...)')
                fprintf([' <a href="matlab:' ,...
                        'disp('' '');',...
                        'disp([''コマンドでプロットの実行をする場合'']);',...
                        'disp(''==================================================='');',...
                        'help([''',class(obj),''',''.anime'']);',...
                        'disp(''==================================================='');',...
                        'disp('' '');',...
                        '">[引数の指定方法]</a>\n\n'])
                disp(' ')
            end
            
        end
        
    end

end

