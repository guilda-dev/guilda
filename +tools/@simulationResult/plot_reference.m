function data = plot_reference(obj,statename,set) 
    uni_state = unique(horzcat(obj.net_data.state_list{set.bus_idx}));
    switch statename
        case 'powerflow' %潮流状態'powerflow'を指定された場合→電圧/電流/電力を指定する。
            data = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,{'V','I','power'});

        case {'V','v'} %電圧Vを指定された場合→母線電圧の絶対値/偏角を指定する。
            data = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,{'Vabs','Vangle','Vreal','Vimag'});

        case {'I','i'} %電流Iを指定された場合→母線電流の絶対値/偏角を指定する。
            data = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,{'Iabs','Iangle','Ireal','Iimag'});

        case {'X','x'} %状態X指定された場合→全種類の状態変数を指定する。
            data = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,uni_state);
            
        case {'power'} %電力'power'を指定された場合→有効電力/無効電力を指定する。
            data =  tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,{'P','Q','S','Factor'});

        case {'Vreal','Vimag','Vabs','Vangle'} %母線電圧フェーザを指定された場合
            data.access  = @(idx) obj.V{idx}{:,statename(2:end)};
            data.legend  = @() flegend(set.bus_idx,set.legend);
            data.bus_idx = set.bus_idx;
            data.command = ">> arrayfun(@(idx) plot(out.t,out.V{idx}{:,'"+statename(2:end)+"'}),"+mat2str(data.bus_idx)+")";
            switch statename(2:end)
                case 'real' %電圧フェーザの実部
                    data.title   = 'real(V)  (V:voltage)';
                    data.st      = @(idx) real(obj.net_data.bus{idx,'V_equilibrium'});
                case 'imag' %電圧フェーザの虚部
                    data.title   = 'imag(V)  (V:voltage)';
                    data.st      = @(idx) imag(obj.net_data.bus{idx,'V_equilibrium'});
                case 'abs' %電圧フェーザの絶対値
                    data.title   = '|V|  (V:voltage)';
                    data.st      = @(idx) abs(obj.net_data.bus{idx,'V_equilibrium'});
                case 'angle' %電圧フェーザの偏角
                    data.title   = '∠V  (V:voltage)';
                    data.st      = @(idx) angle(obj.net_data.bus{idx,'V_equilibrium'});
            end

        case {'Ireal','Iimag','Iabs','Iangle'} %母線電流のフェーザを指定された場合
            data.access  = @(idx) obj.I{idx}{:,statename(2:end)};
            data.legend  = @() flegend(set.bus_idx,set.legend);
            data.bus_idx = set.bus_idx;
            data.command = ">> arrayfun(@(idx) plot(out.t,out.I{idx}{:,'"+statename(2:end)+"'}),"+mat2str(data.bus_idx)+")";
            switch statename(2:end)
                case 'real' %電流フェーザの実部
                    data.title   = 'real(I)  (I:current)';
                    data.st      = @(idx) real(obj.net_data.bus{idx,'I_equilibrium'});
                case 'imag' %電流フェーザの虚部
                    data.title   = 'imag(I) (I:current)';
                    data.st      = @(idx) imag(obj.net_data.bus{idx,'I_equilibrium'});
                case 'abs' %電流フェーザの絶対値
                    data.title   = '|I|  (I:current)';
                    data.st      = @(idx) abs(obj.net_data.bus{idx,'I_equilibrium'});
                case 'angle' %電流フェーザの偏角
                    data.title   = '∠I  (I:current)';
                    data.st      = @(idx) angle(obj.net_data.bus{idx,'I_equilibrium'});
            end

        case {'P','Q','S','Factor'} %電力を指定された場合
            data.access  = @(idx) obj.power{idx}{:,statename}; 
            data.legend  = @() flegend(set.bus_idx,set.legend);
            data.bus_idx = set.bus_idx;
            data.command = ">> arrayfun(@(idx) plot(out.t,out.power{idx}{:,'"+statename+"'}),"+mat2str(data.bus_idx)+")";
            switch statename
                case 'P' %有効電力
                    data.title   = 'P :active power';
                    data.st      = @(idx) obj.net_data.bus{idx,'P'};
                case 'Q' %無効電力
                    data.title   = 'Q :reactive power';
                    data.st      = @(idx) obj.net_data.bus{idx,'Q'};
                case 'S' %皮相電力
                    data.title   = 'S :apparent power';
                    data.st      = @(idx) abs(obj.net_data.bus{idx,'P'}+1j*obj.net_data.bus{idx,'Q'});
                case 'Factor' %力率
                    data.title   = 'cos(θ) :power factor';
                    data.st      = @(idx) angle(obj.net_data.bus{idx,'P'}+1j*obj.net_data.bus{idx,'Q'});
            end

        case uni_state %状態変数を指定された場合
            temp_bus_idx = find(tools.vcellfun(@(state_cell) ismember(statename,state_cell),obj.net_data.state_list));
            temp_bus_idx = intersect(temp_bus_idx,set.bus_idx);
            fstate = @(idx) find(strcmp(obj.net_data.state_list{idx},statename));
            check = arrayfun(@(idx) numel(fstate(idx))>1 ,temp_bus_idx);
            if any(check)
                arrayfun(@(idx) diap(['bus',num2str(idx),'の機器は同一の状態名(',statename,')があるため識別できませんでした']),...
                        temp_bus_idx(check));
                temp_bus_idx(check) = [];
            end
            
            if ismember(statename,tools.arrayfun(@(i) ['state',num2str(i)],1:numel(uni_state)))
                %命名されていないdefaultの状態変数の場合「state1,…,statei」の型の状態変数
                componentlist = unique(obj.net_data.component_list.idx(temp_bus_idx),'stable');
                data = arrayfun(@(i) struct(),1:numel(componentlist));
                for i = 1:numel(componentlist)
                    componentName = obj.net_data.component_list.tag{i};
                    data(i).bus_idx = intersect(temp_bus_idx,find(obj.net_data.component_list.idx==i));
                    data(i).legend  = @() flegend(data(i).bus_idx,set.legend);
                    data(i).access  = @(idx) obj.X{idx}{:,fstate(idx)}; 
                    data(i).title   = [statename,' @',componentName,' < component'];
                    data(i).command = ">> arrayfun(@(idx) plot(out.t,out.X{idx}{:,'"+statename+"')}),"+mat2str(data(i).bus_idx)+")";
                    data(i).st      = @(idx) obj.net_data.equilibrium_list{idx}(strcmp(obj.net_data.state_list{idx},statename));
                end
            else
                data.bus_idx = temp_bus_idx;
                data.legend  = @() flegend(data.bus_idx,set.legend);
                data.access  = @(idx) obj.X{idx}{:,fstate(idx)}; 
                data.title   = statename;
                data.command = ">> arrayfun(@(idx) plot(out.t,out.X{idx}{:,'"+statename+"')}),"+mat2str(data.bus_idx)+")";
                data.st      = @(idx) obj.net_data.equilibrium_list{idx}(strcmp(obj.net_data.state_list{idx},statename));
            end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %ここから下はobj.anime用に設定されたもの%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'flat'
            data.access  = @(idx) ones(numel(obj.t),1);
            data.legend  = @() flegend(set.bus_idx,set.legend);
            data.bus_idx = set.bus_idx;
            data.title   = 'flat';
            data.command = ">> % No data...";
            data.st      = @(idx) 0;

        otherwise
            data = [];
            if numel(statename)>2
                if strcmp(statename(end-2:end),'_pm')
                    temp = plot_reference(obj,statename(1:end-3),set);
                    data.access  = @(idx) sign(temp.access(idx)); 
                    data.legend  = temp.legend;
                    data.bus_idx = temp.bus_idx;
                    data.title   = ['sign ',temp.title];
                    data.command = ">> No Data..";
                    data.st      = @(idx) 0;
                end
            end
            if isempty(data)
                if isa(statename,'double')
                    data = plot_reference(obj,statename(1:end-3),set);
                    data.access  = @(idx) statename*data.access(idx); 
                end
            end
            
    end
    if set.angle_unwrap && (strcmp(statename(2:end),'angle')||strcmp(statename,'Factor'))
        data.access  = @(idx) unwrap(data.access(idx));
        data.st      = @(idx) unwrap(data.st(idx));   
    end
end

function f = flegend(bus_idx,set_legend)
    if set_legend
        f = legend(arrayfun(@(idx) ['bus',num2str(idx)],bus_idx,'UniformOutput',false),'Location','best');
    else
        f = [];
    end
end
    
