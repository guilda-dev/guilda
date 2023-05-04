function data = plot_reference(obj,statename,set) 
    data_flow = [];
    switch statename
        case 'powerflow' %潮流状態'powerflow'を指定された場合→電圧/電流/電力を指定する。
            data_flow = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,{'V','I','power'});

        case {'V','v'} %電圧Vを指定された場合→母線電圧の絶対値/偏角を指定する。
            data_flow = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,{'Vabs','Vangle','Vreal','Vimag'});

        case {'I','i'} %電流Iを指定された場合→母線電流の絶対値/偏角を指定する。
            data_flow = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,{'Iabs','Iangle','Ireal','Iimag'});

        case {'power'} %電力'power'を指定された場合→有効電力/無効電力を指定する。
            data_flow = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,{'P','Q','S','Factor'});

        case {'Vreal','Vimag','Vabs','Vangle'} %母線電圧フェーザを指定された場合
            data_flow.access  = @(idx) obj.out.V{idx}{:,statename(2:end)};
            data_flow.bus_idx = set.bus_idx;
            data_flow.command = ">> arrayfun(@(idx) plot(out.t,out.V{idx}{:,'"+statename(2:end)+"'}),"+mat2str(data_flow.bus_idx)+")";
            switch statename(2:end)
                case 'real' %電圧フェーザの実部
                    data_flow.title   = 'real(V)  (V:voltage)';
                    data_flow.st      = @(idx) real(obj.net.a_bus{idx}.V_equilibrium);
                case 'imag' %電圧フェーザの虚部
                    data_flow.title   = 'imag(V)  (V:voltage)';
                    data_flow.st      = @(idx) imag(obj.net.a_bus{idx}.V_equilibrium);
                case 'abs' %電圧フェーザの絶対値
                    data_flow.title   = '|V|  (V:voltage)';
                    data_flow.st      = @(idx) abs(obj.net.a_bus{idx}.V_equilibrium);
                case 'angle' %電圧フェーザの偏角
                    data_flow.title   = '∠V  (V:voltage)';
                    data_flow.st      = @(idx) angle(obj.net.a_bus{idx}.V_equilibrium);
            end

        case {'Ireal','Iimag','Iabs','Iangle'} %母線電流のフェーザを指定された場合
            data_flow.access  = @(idx) obj.out.I{idx}{:,statename(2:end)};
            data_flow.bus_idx = set.bus_idx;
            data_flow.command = ">> arrayfun(@(idx) plot(out.t,out.I{idx}{:,'"+statename(2:end)+"'}),"+mat2str(data_flow.bus_idx)+")";
            switch statename(2:end)
                case 'real' %電流フェーザの実部
                    data_flow.title   = 'real(I)  (I:current)';
                    data_flow.st      = @(idx) real(obj.net.a_bus{idx}.I_equilibrium);
                case 'imag' %電流フェーザの虚部
                    data_flow.title   = 'imag(I) (I:current)';
                    data_flow.st      = @(idx) imag(obj.net.a_bus{idx}.I_equilibrium);
                case 'abs' %電流フェーザの絶対値
                    data_flow.title   = '|I|  (I:current)';
                    data_flow.st      = @(idx) abs(obj.net.a_bus{idx}.I_equilibrium);
                case 'angle' %電流フェーザの偏角
                    data_flow.title   = '∠I  (I:current)';
                    data_flow.st      = @(idx) angle(obj.net.a_bus{idx}.I_equilibrium);
            end

        case {'P','Q','S','Factor'} %電力を指定された場合
            data_flow.access  = @(idx) obj.out.power{idx}{:,statename}; 
            data_flow.bus_idx = set.bus_idx;
            data_flow.command = ">> arrayfun(@(idx) plot(out.t,out.power{idx}{:,'"+statename+"'}),"+mat2str(data_flow.bus_idx)+")";
            funcPQ = @(i) obj.a_bus{i}.Veqilibrium * conj(obj.a_bus{i}.I_equilibrium);
            switch statename
                case 'P' %有効電力
                    data_flow.title   = 'P :active power';
                    data_flow.st      = @(idx) real(funcPQ(idx));
                case 'Q' %無効電力
                    data_flow.title   = 'Q :reactive power';
                    data_flow.st      = @(idx) imag(funcPQ(idx));
                case 'S' %皮相電力
                    data_flow.title   = 'S :apparent power';
                    data_flow.st      = @(idx) abs(funcPQ(idx));
                case 'Factor' %力率
                    data_flow.title   = 'cos(θ) :power factor';
                    data_flow.st      = @(idx) cos(angle(funcPQ(idx)));
            end
    end

    uni_state = unique(tools.hcellfun(@(b) b.component.get_state_name, obj.net.a_bus),'stable');
    data_xmac = [];
    switch statename
        case {'X','x'} %状態X指定された場合→全種類の状態変数を指定する。
            data_xmac = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,uni_state);

        case uni_state %状態変数を指定された場合
            fstate = @(idx) find(strcmp(obj.out.X{idx}.Properties.VariableNames,statename));
            idx_have_state = find(arrayfun(@(i) numel(fstate(i))==1, 1:numel(obj.net.a_bus)));
            temp_bus_idx = intersect(idx_have_state,set.bus_idx);
            
            nx = tools.vcellfun(@(b) b.component.get_nx, obj.net.a_bus);
            if ismember(statename,tools.arrayfun(@(i) ['x',num2str(i)],1:max(nx)))
                %命名されていないdefaultの状態変数の場合「x1,…,xi」の型の状態変数
                [componentlist,~,index] = unique(obj.net_data.className.mac(temp_bus_idx),'stable');
                data_xmac = struct;
                for i = 1:numel(componentlist)
                    data_xmac(i).bus_idx = temp_bus_idx(index==i);
                    data_xmac(i).access  = @(idx) obj.out.X{idx}{:,statename}; 
                    data_xmac(i).title   = [statename,' @',componentlist{i}];
                    data_xmac(i).command = ">> arrayfun(@(idx) plot(out.t,out.X{idx}{:,'"+statename+"')}),"+mat2str(data_xmac(i).bus_idx)+")";
                    data_xmac(i).st      = @(idx) obj.net.a_bus{idx}.component.x_equilibrium(fstate(idx));
                end
                data_xmac = data_xmac(:)';
            else
                data_xmac.bus_idx = temp_bus_idx;
                data_xmac.access  = @(idx) obj.out.X{idx}{:,statename}; 
                data_xmac.title   = statename;
                data_xmac.command = ">> arrayfun(@(idx) plot(out.t,out.X{idx}{:,'"+statename+"')}),"+mat2str(data_xmac.bus_idx)+")";
                data_xmac.st      = @(idx) obj.net.a_bus{idx}.component.x_equilibrium(fstate(idx));
            end
    end

    contype = {'local','global'};
    data_xcon = cell(1,2);
    cnt = numel(obj.net.a_bus);
    for GLidx = 1:2
        GL = contype{GLidx};
        con = obj.net.(['a_controller_',GL]);
        uni_state = unique(tools.hcellfun(@(c) c.get_state_name, con),'stable');
        data_xcon{GLidx} = [];
        switch statename
            case {['Xcon_',GL],['xcon_',GL]} %状態X指定された場合→全種類の状態変数を指定する。
                data_xcon{GLidx} = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,uni_state);
    
            case uni_state %状態変数を指定された場合
                fstate = @(idx) find(strcmp(obj.out.Xcon.(GL){idx}.Properties.VariableNames,statename));
                temp_bus_idx = find( arrayfun(@(i) numel(fstate(i))==1, 1:numel(con)) );
                
                nx = tools.vcellfun(@(c) c.get_nx, con);
                if ismember(statename,tools.arrayfun(@(i) ['x',num2str(i)],1:max(nx)))
                    %命名されていないdefaultの状態変数の場合「x1,…,xi」の型の状態変数
                    [componentlist,~,index] = unique(obj.net_data.className.(['c_',GL(1)])(temp_bus_idx),'stable');
                    data_xcon{GLidx} = struct;
                    for i = 1:numel(componentlist)
                        data_xcon{GLidx}(i).bus_idx = cnt+temp_bus_idx(index==i);
                        data_xcon{GLidx}(i).access  = @(idx) obj.out.Xcon.(GL){idx-cnt}{:,statename}; 
                        data_xcon{GLidx}(i).title   = [statename,' @',componentlist{i}];
                        data_xcon{GLidx}(i).command = ">> arrayfun(@(idx) plot(out.t,out.Xcon."+GL+"{idx}{:,'"+statename+"')}),"+mat2str(temp_bus_idx(index==i))+")";
                        data_xcon{GLidx}(i).st      = @(idx) 0; %要検討obj.net.a_bus{idx}.component.x_equilibrium(fstate(idx));
                    end
                    data_xcon{GLidx} = data_xcon{GLidx}(:)';
                else
                    data_xcon{GLidx}.bus_idx = cnt+temp_bus_idx;
                    data_xcon{GLidx}.access  = @(idx) obj.Xcon.(GL){idx-cnt}{:,statename}; 
                    data_xcon{GLidx}.title   = statename;
                    data_xcon{GLidx}.command = ">> arrayfun(@(idx) plot(out.t,out.Xcon."+GL+"{idx}{:,'"+statename+"')}),"+mat2str(data_xcon{GLidx}.bus_idx)+")";
                    data_xcon{GLidx}.st      = @(idx) 0; %要検討obj.net.a_bus{idx}.component.x_equilibrium(fstate(idx));
                end
        end
        cnt = cnt + numel(con);
    end

    uni_port  = unique(tools.hcellfun(@(b) b.component.get_port_name , obj.net.a_bus),'stable');
    data_umac = [];
    switch statename
        case {'U','u'} %Uで指定された場合→全種類の入力ポートを指定する。
            data_umac = tools.hcellfun(@(temp_statename) obj.plot_reference(temp_statename,set) ,uni_port);

        case uni_port %入力ポート名を指定された場合
            fstate = @(idx) find(strcmp(obj.out.input.data.Total{idx}.Properties.VariableNames,statename));
            idx_have_state = find(arrayfun(@(i) numel(fstate(i))==1, 1:numel(obj.net.a_bus)));
            temp_bus_idx = intersect(idx_have_state,set.bus_idx);
            
            nu = tools.vcellfun(@(b) b.component.get_nu, obj.net.a_bus);
            if ismember(statename,tools.arrayfun(@(i) ['u',num2str(i)],1:max(nu)))
                %命名されていないdefaultの状態変数の場合「x1,…,xi」の型の状態変数
                [componentlist,~,index] = unique(obj.net_data.className.mac(temp_bus_idx),'stable');
                data_umac = struct;
                for i = 1:numel(componentlist)
                    data_umac(i).bus_idx = temp_bus_idx(index==i);
                    data_umac(i).access  = @(idx) obj.out.input.data.Total{idx}{:,statename}; 
                    data_umac(i).title   = [statename,' @',componentlist{i}];
                    data_umac(i).command = ">> arrayfun(@(idx) plot(out.t,out.input.data.Total{idx}{:,'"+statename+"')}),"+mat2str(data_umac(i).bus_idx)+")";
                    data_umac(i).st      = @(idx) 0;
                end
                data_umac = data_umac(:)';
            else
                data_umac.bus_idx = temp_bus_idx;
                data_umac.access  = @(idx) obj.out.input.data.Total{idx}{:,statename}; 
                data_umac.title   = statename;
                data_umac.command = ">> arrayfun(@(idx) plot(out.t,out.input.data.Total{idx}{:,'"+statename+"')}),"+mat2str(data_umac.bus_idx)+")";
                data_umac.st      = @(idx) 0;
            end
    end

    data = [data_flow,data_xmac,data_xcon{1},data_xcon{2},data_umac];
       
    if set.angle_unwrap && (strcmp(statename(2:end),'angle')||strcmp(statename,'Factor'))
        data.access  = @(idx) unwrap(data.access(idx));
        data.st      = @(idx) unwrap(data.st(idx));   
    end

    if ~isempty(data)
        return
    end

    switch statename
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %ここから下はobj.anime用に設定されたもの%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'flat'
            data.access  = @(idx) ones(numel(obj.t),1);
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
                    data.bus_idx = temp.bus_idx;
                    data.title   = ['sign ',temp.title];
                    data.command = ">> No Data..";
                    data.st      = @(idx) 0;
                end
            end
            if isempty(data)
                if isa(statename,'double')
                    data = plot_reference(obj,'flat',set);
                    data.access  = @(idx) statename*data.access(idx); 
                else
                    para_list = tools.vcellfun(@(b) ismember(statename,b.component.parameter.Properties.VariableNames), obj.net.a_bus);
                    if any(para_list)
                        idx_haspara = find(para_list);
                        data.access  = @(idx) obj.net.a_bus{idx}.component.parameter{1,statename} * ones(numel(obj.t),1);
                        data.bus_idx = intersect(set.bus_idx, idx_haspara);
                        data.title   = ['parameter : ',statename];
                        data.command = ">> arrayfun(@(idx) plot(out.t([1,end]),[1,1]*net.a_bus{idx}.component.parameter{1,'"+statename+"')}),"+mat2str(data.bus_idx)+")";
                        data.st      = @(idx) obj.net.a_bus{idx}.component.parameter{1,statename};
                    end
                end
            end
    end
end
    
