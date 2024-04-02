classdef DataProcessing < dynamicprops & matlab.mixin.CustomDisplay
%
%ーフィールドー
%       既存の"net.simulate()"の出力結果に以下のフィールドを追加
%          t   : サンプリング時間のデータ
%          X   : 各機器の状態の応答データ
%          V   : 各母線の電圧の応答データ
%          I   : 各母線の電流の応答データ
%        Xcon  : 各制御機の状態の応答データ
%        Ucon  : 各制御機の出力の時系列データ
%       Uinput : 条件設定に外部入力の応答データ
%       Utotal : 各機器への入力の時系列データ(Ucon+Uinput)
%       power  : 各母線の電力の応答データ
%

    properties
        data_format(1,:) char {mustBeMember(data_format,{'array','table'})} = 'table';
        setting
        options
    end

    properties(SetAccess=private)
        out_data
        net_data
    end

    properties(Access=private)
        option_class = struct();
    end

    methods
        export_csv(obj)

        function obj = DataProcessing(out,net,print_readme)
            arguments
                out
                net
                print_readme = false;
            end
        
        % 本クラスの使用方法を表示
            while ~islogical(print_readme)
                yes_no = input('使い方を表示しますか？(y/n)：',"s");
                if      strcmp(yes_no,'y'); yes_no = true;
                elseif  strcmp(yes_no,'n'); yes_no = false;
                end
            end
            if print_readme
               obj.readme;
            end


        % オプションに関するデータを取り出す
            obj.options = out.options;
            obj.option_class.input = out.input;
            obj.option_class.fault = out.fault;
            obj.option_class.parallel = out.parallel;
            out = rmfield(out,{'options','input','fault','parallel'});

            
        % outデータを下処理
            %母線電圧/電流の絶対値/偏角、また電力P,Qの時系列データを追加する。
            V_Phasor = tools.cellfun(@(v) v(:,1)+1j*v(:,2), out.V);
            I_Phasor = tools.cellfun(@(v) v(:,1)+1j*v(:,2), out.I);
            PQ       = tools.arrayfun(@(b) V_Phasor{b}.*conj(I_Phasor{b}), (1:numel(out.V))');

            farray2table = @(data,fdata,fname) tools.arrayfun(@(i) array2table(fdata(data,i), 'VariableNames', fname(data,i)), (1:numel(data))');
            
            fdata  = @(data,idx) [real(data{idx}),imag(data{idx}),abs(data{idx}),angle(data{idx})];
            out.V  = farray2table(V_Phasor, fdata, @(~,~) {'real','imag','abs','angle'});
            out.I  = farray2table(I_Phasor, fdata, @(~,~) {'real','imag','abs','angle'});

            fdata     = @(data,idx) [real(data{idx}),imag(data{idx}),abs(data{idx}),real(data{idx})./abs(data{idx})];
            out.power = farray2table(PQ, fdata, @(~,~) {'P','Q','S','Factor'});

            fdata = @(data,idx) data{idx};
            out.X          = farray2table(out.X,           fdata, @(~,i) net.a_bus{i}.component.get_state_name    );
            out.Xcon.local = farray2table(out.Xcon.local,  fdata, @(~,i) net.a_controller_local{i}.get_state_name );
            out.Xcon.global= farray2table(out.Xcon.global, fdata, @(~,i) net.a_controller_global{i}.get_state_name);
            
            out.Ucon.local = farray2table(out.Ucon.local , fdata, @(~,i) net.a_controller_local{i}.get_port_name);
            out.Ucon.global= farray2table(out.Ucon.global, fdata, @(~,i) net.a_controller_global{i}.get_port_name);

            out.Uinput = farray2table(out.Uinput, fdata, @(~,i) net.a_bus{i}.component.get_port_name  );
            out.Utotal = farray2table(out.Utotal, fdata, @(~,i) net.a_bus{i}.component.get_port_name  );


        % プロパティへのデータ格納　及び　Dependentプロパティの生成
                % networkの状態を取得してプロパティに格納
                % power_networkクラスはhandleクラスのため、netが変更されるとバグの原因になるため情報のみをstruct型で取得
                info = net.information('do_report',false);
                obj.net_data = info;

            obj.out_data = out;
            allfield = fieldnames(out);
            for i = 1:numel(allfield)
                Prop = obj.addprop(allfield{i});
                Prop.Dependent = true;
            end


        % プロットプロパティのデフォルト値を設定
            obj.setting.plot.para             = {'X','Vabs','P'};
            obj.setting.plot.bus_idx          = 'all_bus';
            obj.setting.plot.legend           = true;
            obj.setting.plot.disp_command     = false;
            obj.setting.plot.LineWidth        = 2;
            obj.setting.plot.plot             = true;
            obj.setting.plot.para_unique      = true;
            obj.setting.plot.angle_unwrap     = false;
            obj.setting.plot.from_equilibrium = false;
            obj.setting.plot.setting_update   = true;
            obj.setting.plot.colormap = {...
            ...%カラーユニバーサルデザイン
            '#FF4B00', '#005AFF', '#03AF7A', '#4DC4FF','#F6AA00', '#FFF100', '#000000', '#990099','#84919E',...
            ...%Paul Tol氏提案 Muted
            '#332288', '#88CCEE', '#44AA99','#117733', '#999933', '#DDCC77', '#CC6677','#882255', '#AA4499', '#DDDDDD',...
            ...%MATLABの代表的な指定色
            'red', 'green', 'blue', 'cyan', 'magenta', 'yellow',...
            '#0072BD','#D95319','#EDB120','#7E2F8E','#77AC30','#4DBEEE','#A2142F'};

            obj.initialize;
        end
        
    % シミュレーション条件の表示
        function  simulation_condition(obj)
            figure
            f = {'fault','input','parallel'};
            for i = 1:numel(f)
                op = obj.option_class.(f{i});
                ax = subplot(1,numel(f),i);
                op.sentence;
                op.plot(ax);
            end
        end

    %応答プロットに関するmethod
        function UIplot(obj)
            %ー実行方法ー
            %>> obj.UIplot()
            %
            supporters.for_simulate.sol.UIplot(obj);
        end
        varargout = plot(obj,para,bus_idx,varargin);


    %応答のアニメーションに関するmethod
        function UIanime(obj,net)
            %ー実行方法ー
            %>> obj.UIanime(net)
            %
            supporters.for_simulate.solfactory.UIanime(obj,net);
        end

        anime(obj,net,varargin)

        
        %使い方の表示
        function readme(obj)
            
            fprintf(['\n' ...
            '==================================\n',...
            '    シミュレーション結果の解析ツール   \n',...
            '        DataProcessingクラス       \n',...
            '==================================\n\n'])
            help(class(obj))
            
            disp('応答プロットを表示したい場合')
            disp('------------------------')
            
            disp('● UIを使う場合')
            help([class(obj),'.UIplot'])
            
            disp('● コマンドで実行する場合')
            myhref(obj,'[引数の指定方法]','コマンドでプロットの実行をする場合','plot')

            disp('アニメーションを表示したい場合')
            disp('-------------------------')
            
            disp('● コマンドで実行する場合')
            myhref(obj,'[引数の指定方法]','コマンドでプロットの実行をする場合','anime')
        
            function myhref(obj,ref,sentence,method)
                disp('ー実行方法ー')
                disp([' >> obj.',method,'();'])
                fprintf([' >> obj.',method,'(Name,Value,...)'])
                fprintf([' <a href="matlab:' ,...
                        'disp('' '');',...
                        'disp([''',sentence,''']);',...
                        'disp(''==================================================='');',...
                        'help([''',class(obj),''',''.',method,''']);',...
                        'disp(''==================================================='');',...
                        'disp('' '');',...
                        '">',ref,'</a>\n\n'])
                disp(' ')
            end
            
        end
        
    end
    methods(Access=protected)

        data = plot_reference(obj,statename,set);

        function propgrp = getPropertyGroups(obj)
            proplist = [{'data_format','plot_default'},fieldnames(obj.out_data)'];
            propgrp = matlab.mixin.util.PropertyGroup(proplist);
        end

        
        function initialize(obj)
            allfield = fieldnames(obj.out_data);
            for i = 1:numel(allfield)
                field = allfield{i};
                prop  = findprop(obj,field);
                prop.GetMethod = @(~) obj.get_data(field);
            end
        end


    % データへのGetMethodを定義
        function val = get_data(obj,name)
            switch obj.data_format
                case 'array'
                    val = obj.any2array(obj.out_data.(name));
                case 'table'
                    val = obj.out_data.(name);
            end
        end

        function val = any2array(obj,val)
            if iscell(val)
                val = tools.cellfun(@(c) obj.any2array(c), val);
            elseif istable(val)
                val = table2array(val);
            elseif isstruct(val)
                for n = 1:numel(val)
                    fd = fieldnames(val(n));
                    for i = 1:numel(fd)
                        val(n).(fd{i}) = obj.any2array(val(n).(fd{i}));
                    end
                end
            end
        end

    end

end

