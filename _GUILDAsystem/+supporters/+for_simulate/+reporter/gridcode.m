classdef gridcode < handle

    properties
        observe = true;
        control = false;
    end

    properties(SetAccess=private)
        record = struct('time',[],'mac',struct,'branch',struct,'controller',struct);
        is_changed = false;
    end

    properties(Access = private)
        % ネットワークの情報を格納
        netdata = struct('obj',[],'num',[]);
        l_hascode  = struct('mac',struct,'branch',struct,'controller',struct)

        % 母線電圧データの復元に使う行列
        Yreproduced

        % プロットで使用するプロパティ
        tlim
        ax
        line_equipment
        live_equipment
        num_division = 25;
        sampling_time
        next_time_idx

        % f(x)内で使用したデータを保存しておくプロパティ
        % このデータをEventFcnで用いて判定を行う．
        vargin

    end

    methods
        function obj = gridcode(net, tlim, stateholder, mode, live_equip)
            arguments
                net
                tlim
                stateholder
                mode        %{mustBeMember(mode,{'ignore','monitor','control'})} = 'ignore';
                live_equip  %{mustBeMember(live_equip,{'component','branch','controller',[]})} = {'component','branch'};
            end

            obj.vargin = stateholder;

            % モードの設定
            switch mode
                case 'ignore'
                    obj.observe = false;
                    obj.control = false;
                case 'monitor'
                    obj.observe = true;
                    obj.control = false;
                case 'control'
                    obj.observe = true;
                    obj.control = true;
            end

            % プロットに必要なプロパティの下準備
            n_equip = numel(live_equip);
            obj.tlim = tlim;
            obj.ax   = cell(n_equip,1);
            obj.line_equipment = cell(n_equip,1);
            obj.live_equipment = live_equip;
            for i = 1:n_equip
                obj.line_equipment{i} = struct('connect',[],'gridcode',[]);
            end
            obj.sampling_time = linspace(obj.tlim(1), obj.tlim(end), obj.num_division);
            obj.next_time_idx = 1;

            % ネットワークデータの抽出
            obj.netdata.obj.mac        = tools.cellfun(@(b)b.component, net.a_bus);
            obj.netdata.obj.branch     = net.a_branch;
            obj.netdata.obj.controller = [net.a_controller_local(:);net.a_controller_global(:)];
            f = fieldnames(obj.netdata.obj);
            for i=1:numel(f)
                obj.netdata.num.(f{i}) = numel(obj.netdata.obj.(f{i})); 
                obj.record.(f{i}).connect  = tools.hcellfun(@(c) c.is_connected, obj.netdata.obj.(f{i}));
                obj.record.(f{i}).gridcode = nan(1,obj.netdata.num.(f{i}));
            end
            obj.netdata.num.bus = numel(net.a_bus);
            obj.record.time = 0;

            % シミュレーションに必要となるパラメータのうち静的な値を予め求めておく
            o = obj.netdata.obj;
            for i = 1:numel(f)
                obj.l_hascode.(f{i}).on  = tools.vcellfun(@(c) ~isempty(c.grid_code.parallel_on ),o.(f{i}) );
                obj.l_hascode.(f{i}).off = tools.vcellfun(@(c) ~isempty(c.grid_code.parallel_off),o.(f{i}) );
            end
        end


        %%%%%%%%%%%%%%%%%%%%%  odeソルバー内でEventFcnとして実行される関数　%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [value,isterminal,direction] = EventFcn(obj,t)
            if obj.observe
                obj.record.time = [obj.record.time;t];
                change_mac = obj.judge_gridcode(t, 'mac'       ,obj.vargin.mac       );
                change_bra = obj.judge_gridcode(t, 'branch'    ,obj.vargin.branch    );
                change_con = obj.judge_gridcode(t, 'controller',obj.vargin.controller);
                value = ~(change_mac||change_bra||change_con);
            else
                value = true;
            end
            obj.is_changed = ~value;
            isterminal = obj.control;
            direction  = [];
        end

        function change = judge_gridcode(obj,t,type,var)
            n = obj.netdata.num.(type);
            if n==0
                change = false;
                return
            end
            o = obj.netdata.obj.(type);
            hascode = obj.l_hascode.(type);
            connect  = obj.record.(type).connect(end,:);
            gridcode = obj.record.(type).gridcode(end,:);

            change = false;
            for i = 1:n
                gridcode_i = nan;
                if isempty(var{i})
                    connect(i) = false;
                else
                    c = o{i};
                    if connect(i) && hascode.off(i)
                        gridcode_i = c.grid_code.parallel_off(c,t,var{i}{:});
                        if ~gridcode_i && obj.control
                            c.disconnect;
                            connect(i) = false;
                            change = true;
                            obj.addline(i,'connect',type,false)
                        end
                    elseif ~connect(i) && hascode.on(i)
                        gridcode_i = c.grid_code.parallel_off(c,t,var{i}{:});
                        if  gridcode_i && obj.control
                            c.connect;
                            connect(i) = true;
                            change = true;
                            obj.addline(i,'connect',type,true)
                        end
                    end
                end

                if gridcode_i ~= gridcode(i)
                    obj.addline(i,'gridcode',type,gridcode_i);
                end
                gridcode(i) = gridcode_i;
            end
            obj.record.(type).connect  = [obj.record.(type).connect(end,:) ;connect ];
            obj.record.(type).gridcode = [obj.record.(type).gridcode(end,:);gridcode];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%　  解析中のライブ用メソッド　　%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% odeソルバーでEventFcnとして使用する関数
        function out = live(obj,t,~,~)
            if isempty( obj.ax{1} ) || ~isgraphics( obj.ax{1} )
                obj.set_axis;
                equipment = obj.live_equipment;
                for ii = 1:numel(equipment)
                    equipment_ii = strrep(equipment{ii},'component','mac');
                    data = obj.record.(equipment_ii).connect(end,:);
                    code = obj.record.(equipment_ii).gridcode(end,:);
        
                    obj.addline(find( data)       , 'connect', equipment_ii, true )
                    obj.addline(find(~data)       , 'connect', equipment_ii, false)
                    obj.addline(find( code==true) ,'gridcode', equipment_ii, true )
                    obj.addline(find( code==false),'gridcode', equipment_ii, false)
                end
            end

            if numel(t) == 1
                obj.add_point(t)
            end
            out = false;
        end

        
        function add_point(obj,t)
            tlast = obj.sampling_time(obj.next_time_idx);
            if t >= obj.sampling_time(obj.next_time_idx)
                for i = 1:numel(obj.ax)
                    for j = 1:numel(obj.ax{i}.Children)
                        c = obj.ax{i}.Children(j);
                        if isa(c,'matlab.graphics.animation.AnimatedLine')
                            [~,y] = getpoints(c);
                            addpoints(c, tlast, y(end));
                        end
                    end
                end
                drawnow limitrate
                if obj.next_time_idx < obj.num_division
                    obj.next_time_idx = obj.next_time_idx + 1;
                    obj.add_point(t)
                end
            end
        end

        % Figureのレイアウトを決定する関数
        function set_axis(obj)
            figure('WindowState','maximized');
            nplot = numel(obj.live_equipment);
            for i = 1:nplot
                switch obj.live_equipment{i}
                    case 'controller'
                        o = obj.netdata.obj.controller;
                        n = obj.netdata.num.controller;
                        list = tools.arrayfun(@(i) [' ',o{i}.Tag,' @mac',mat2str(o{i}.index_all)], n:-1:1);
                    case 'component'
                        o = obj.netdata.obj.mac;
                        n = obj.netdata.num.mac;
                        list = tools.arrayfun(@(i) [' ',o{i}.Tag,' @bus',num2str(i)], n:-1:1);
                    case 'branch'
                        o = obj.netdata.obj.branch;
                        n = obj.netdata.num.branch;
                        list = tools.arrayfun(@(i) [' ',o{i}.Tag,' @bus',num2str(o{i}.from),'-',num2str(o{i}.to)], n:-1:1);
                end
                subplot(1,nplot,i)
                obj.ax{i}                   = gca;
                obj.ax{i}.XLabel.String     = 'second(s)';
                obj.ax{i}.YTick             = 1:n;
                obj.ax{i}.XLim              = [obj.tlim(1),obj.tlim(end)];
                obj.ax{i}.YLim              = [0,n+0.5];
                obj.ax{i}.YTickLabel        = list;
                obj.ax{i}.YAxis.FontSize    = 7;
                obj.ax{i}.YAxis.FontWeight  = 'bold';
                obj.ax{i}.YAxis.TickLabelInterpreter = 'none';
                obj.ax{i}.Title.FontSize    = 12;
                obj.ax{i}.Title.FontWeight  = 'bold';
                obj.ax{i}.Title.String      = ['Live status of each ',obj.live_equipment{i}];
                grid on
            end
            sgtitle({'GreenLine: Equipment is cconnected,  GrayLine: Equipment is disconnected',...
                     'RedLine: Out of Grid code condition,  BlueLine: Within the grid code conditions'},'FontSize',15,'FontWeight','bold')
        end

        function addline(obj,idx,linetype,equip,tf)
            num   = 1+obj.netdata.num.(equip);
            equip = strrep(equip,'mac','component');
            id_ax = find(strcmp(obj.live_equipment,equip));
            for i = id_ax(:)'
                iax = obj.ax{i};
                if isempty(iax); return; end
                hold(iax,'on')
                
                nchild = numel(iax.Children);
                tag    = tools.arrayfun(@(ii) iax.Children(ii).Tag, 1:nchild);
                num_tag= arrayfun(@(i){num2str(i)},idx);
                if isempty(num_tag)
                    return
                end

                id_tag = ismember(tag,num_tag);
                if numel(id_tag)~=0
                    delete(iax.Children(id_tag));%=[];
                end

                if isnan(tf); return; end

                tlast = obj.record.time(end);
                for l = idx(:)'
                    switch linetype
                        case 'connect'
                            if tf; c = [0 1 0];
                            else ; c = [0.8,0.8,0.8];
                            end
                            animatedline(iax,tlast,num-l,'LineWidth',6,'Color',c,'Tag',num2str(l));
                            iax.Children = [iax.Children(2:end);iax.Children(1)];
                        case 'gridcode'
                            if tf; m = 'o'; c = [0, 0.4470, 0.7410];
                            else ; m = 'x'; c = [0.8500, 0.3250, 0.0980];
                            end
                            scatter(iax,tlast,num-l,20,'filled','Marker',m,'MarkerEdgeColor',c,'MarkerFaceColor',c,'LineWidth',2);
                            animatedline(iax,tlast,num-l,'LineWidth',2,'Color',c,'Tag',num2str(l));
                    end
                end
            end
        end

    end
end


