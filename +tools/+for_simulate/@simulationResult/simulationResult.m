classdef simulationResult < dynamicprops & matlab.mixin.CustomDisplay
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

    properties
        data_format = 'array';
        plot_default
    end

    properties%(Access=private)
        out
        net
        net_data
    end

    methods
        export_csv(obj)

        function obj = simulationResult(out,net,print_readme)
            arguments
                out
                net
                print_readme = [];
            end
        
        % 本クラスの使用方法を表示
            obj.readme(print_readme)

        % outデータを下処理
            %母線電圧/電流の絶対値/偏角、また電力P,Qの時系列データを追加する。
            bus_num = numel(out.V);
            V_Phasor = tools.arrayfun(@(b) out.V{b}(:,1)+1j*out.V{b}(:,2), (1:bus_num)');
            I_Phasor = tools.arrayfun(@(b) out.I{b}(:,1)+1j*out.I{b}(:,2), (1:bus_num)');
            PQ       = tools.arrayfun(@(b) V_Phasor{b}.*conj(I_Phasor{b}), (1:bus_num)');

            farray2table = @(data,fdata,fname) tools.arrayfun(@(i) array2table(fdata(data,i), 'VariableNames', fname(data,i)), (1:numel(data))');
            
            fdata  = @(data,idx) [real(data{idx}),imag(data{idx}),abs(data{idx}),angle(data{idx})];
            out.V  = farray2table(V_Phasor, fdata, @(~,~) {'real','imag','abs','angle'});
            out.I  = farray2table(I_Phasor, fdata, @(~,~) {'real','imag','abs','angle'});

            fdata     = @(data,idx) [real(data{idx}),imag(data{idx}),abs(data{idx}),cos(angle(data{idx}))];
            out.power = farray2table(PQ, fdata, @(~,~) {'P','Q','S','Factor'});

            fdata = @(data,idx) data{idx};
            out.X          = farray2table(out.X,           fdata, @(~,i) net.a_bus{i}.component.get_state_name    );
            out.Xcon.local = farray2table(out.Xcon.local,  fdata, @(~,i) net.a_controller_local{i}.get_state_name );
            out.Xcon.global= farray2table(out.Xcon.global, fdata, @(~,i) net.a_controller_global{i}.get_state_name);
            
            funame = @(con) tools.harrayfun(@(idx) strcat(reshape(net.a_bus{idx}.component.get_port_name,1,[]),['_',num2str(idx)]), con.index_input);
            out.Ucon.local=  farray2table(out.Ucon.local , fdata, @(~,i) funame(net.a_controller_local{i}));
            out.Ucon.global= farray2table(out.Ucon.global, fdata, @(~,i) funame(net.a_controller_global{i}));

            fnames = fieldnames(out.input.data);
            for i=1:numel(fnames)
                out.input.data.(fnames{i}) = farray2table(out.input.data.(fnames{i}), fdata, @(~,i) net.a_bus{i}.component.get_port_name);
            end

            equipment = {'bus','branch','component','controller_local','controller_global'};
            fname = @(data,i) [{},cellfun(@(c) {['Cost',num2str(c)]}, num2cell(1:size(data{i},2)))];
            for i = 1:5
                out.CostFcn.(equipment{i}) = farray2table(out.CostFcn.(equipment{i}), fdata, fname);
            end
            

        % プロパティへのデータ格納　及び　Dependentプロパティの生成
            obj.net = net;
            obj.out = out;
            allfield = fieldnames(out);
            for i = 1:numel(allfield)
                Prop  = obj.addprop(allfield{i});
                Prop.Dependent = true;
            end

        % 解析を行ったpower_networkの情報を抽出
            data = struct;

            % クラス名
            data.className = struct;
            data.className.bus = tools.cellfun(@(b) class(b), net.a_bus);
            data.className.mac = tools.cellfun(@(b) strrep(class(b.component),'component.' ,''), net.a_bus);
            data.className.c_l = tools.cellfun(@(c) strrep(class(c)          ,'controller.',''), net.a_controller_local );
            data.className.c_g = tools.cellfun(@(c) strrep(class(c)          ,'controller.',''), net.a_controller_global);
            obj.net_data = data;

        % プロットプロパティのデフォルト値を設定
            obj.plot_default.para             = {'X','Vabs','P'};
            obj.plot_default.bus_idx          = 'all_bus';
            obj.plot_default.legend           = true;
            obj.plot_default.disp_command     = false;
            obj.plot_default.LineWidth        = 2;
            obj.plot_default.plot             = true;
            obj.plot_default.para_unique      = true;
            obj.plot_default.angle_unwrap     = false;
            obj.plot_default.colormap = {...
            ...%カラーユニバーサルデザイン
            '#FF4B00', '#005AFF', '#03AF7A', '#4DC4FF','#F6AA00', '#FFF100', '#000000', '#990099','#84919E',...
            ...%Paul Tol氏提案 Muted
            '#332288', '#88CCEE', '#44AA99','#117733', '#999933', '#DDCC77', '#CC6677','#882255', '#AA4499', '#DDDDDD',...
            ...%MATLABの代表的な指定色
            'red', 'green', 'blue', 'cyan', 'magenta', 'yellow',...
            '#0072BD','#D95319','#EDB120','#7E2F8E','#77AC30','#4DBEEE','#A2142F'};

            obj.initialize;
        end


    % データ形式の変換に関するメソッド
        function set.data_format(obj,format)
            arguments
                obj
                format {mustBeMember(format,{'array','table'})} = 'array';
            end
            obj.data_format = format;
            obj.initialize;
        end
        function initialize(obj)
            allfield = fieldnames(obj.out);
            for i = 1:numel(allfield)
                field = allfield{i};
                prop  = findprop(obj,field);
                prop.GetMethod = @(~) obj.(strcat('get_',obj.data_format))(field);
            end
        end


    % データへのGetMethodを定義
        function val = get_array(obj,name)
            val = obj.out.(name);
            val = obj.any2array(val);
        end
        function val = get_table(obj,name)
            val = obj.out.(name);
        end

        function val = any2array(obj,val)
            if iscell(val)
                val = tools.cellfun(@(c) obj.any2array(c), val);
            elseif istable(val)
                val = table2array(val);
            elseif isstruct(val)
                fd = fieldnames(val);
                for i = 1:numel(fd)
                    val.(fd{i}) = obj.any2array(val.(fd{i}));
                end
            end
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
        anime(obj,varargin)

        
        %使い方の表示
        function readme(obj, yes_no)
            
            while ~islogical(yes_no)
                yes_no = input('使い方を表示しますか？(y/n)：',"s");
                if      strcmp(yes_no,'y'); yes_no = true;
                elseif  strcmp(yes_no,'n'); yes_no = false;
                end
            end
            
            if yes_no
                fprintf(['\n' ...
                '==================================\n',...
                '  シミュレーション結果出力の補助ツール  \n',...
                '      SimulationResultクラス       \n',...
                '==================================\n\n'])
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
    methods(Access=protected)
        function propgrp = getPropertyGroups(obj)
            proplist = [{'data_format','plot_default'},fieldnames(obj.out)'];
            propgrp = matlab.mixin.util.PropertyGroup(proplist);
        end
    end

end

