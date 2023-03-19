function out = information(obj,varargin)
    %引数に与えられたネットワークのモデルのパラメータを調べる用の関数

    p = inputParser;
    p.CaseSensitive = false;
    addParameter(p, 'do_report', true);

    addParameter(p, 'bus'           , true);
    addParameter(p, 'branch'        , true);
    addParameter(p, 'component_para', true);
    addParameter(p, 'x_equilibrium' , true);

    addParameter(p, 'plot_graph' , false);
    addParameter(p, 'graphVisible', 'wheather_plot_or_not')
    
    addParameter(p, 'pdf', false);
    if nargin == 2
        if isstruct(varargin{1})
            para = p.Parameters;
            varargin = cell(1,numel(para)*2);
            for i = 1:numel(para)
                varargin{2*i-1} = para{i};
                value = input([para{i},'? (y/n) : '],"s");
                switch value
                    case 'y'
                        varargin{2*i}= true;
                    case 'n'
                        varargin{2*i}= false;
                end
            end
        end
    end
    parse(p, varargin{:});

    options = p.Results;
    if strcmp(options.graphVisible,'wheather_plot_or_not')
        options.graphVisible = options.plot_graph;
    end

    
    %潮流状態の情報を取得
    if options.bus
        bus = class2struct(obj.a_bus);
        out.bus = struct2table(bus);
        out.bus{:,'Vabs'}   =   abs(out.bus{:,'V_equilibrium'});
        out.bus{:,'Vangle'} = angle(out.bus{:,'V_equilibrium'});
        out.bus{:,'P'}      =  real(out.bus{:,'V_equilibrium'}.*conj(out.bus{:,'I_equilibrium'}));
        out.bus{:,'Q'}      =  imag(out.bus{:,'V_equilibrium'}.*conj(out.bus{:,'I_equilibrium'}));
    end

    %ブランチの情報を取得
    if options.branch
        branch = class2struct(obj.a_branch);
        out.branch = struct2table(branch);
    end
    
    %コンポーネント名リスト取得
    component_names = tools.vcellfun(@(b) {class(b.component)},obj.a_bus);
    [component_names,~,idx] = unique(component_names,'stable');

    for comp_idx = 1:numel(component_names)

        % パラメータの取得
        if options.component_para
            para = [];
            if ismember('parameter',properties(component_names{comp_idx}))
                for bus_idx = (find(idx==comp_idx))'
                    comp_i = obj.a_bus{bus_idx}.component;
                    parameter = comp_i.parameter;
                    switch class(parameter)
                        case 'table'
                            temp = table2struct(parameter);
                        case 'struct'
                            temp = parameter;
                        otherwise
                            temp.memo = 'Parameter variable type is not supported.(struct,table)';
                    end
                    fname = fieldnames(temp);
                    temp.bus_idx = bus_idx;
                    temp = orderfields(temp,[{'bus_idx'};fname]);
                    para = [para,temp];
                end
                para = struct2table(para);
            end
            out.component_para.(component_names{comp_idx}) = para;
        end
       
        %平衡点の情報を取得
        if options.x_equilibrium
            ss = [];
            stateNames = tools.arrayfun(@(ii) obj.a_bus{ii}.component.get_state_name,find(idx==comp_idx));
            stateNames = unique(horzcat(stateNames{:}),'stable');
            if numel(stateNames)~=0
                for bus_idx = (find(idx==comp_idx))'
                    comp_i = obj.a_bus{bus_idx}.component;
                    [~,isthere] = ismember(stateNames,comp_i.get_state_name);
                    unknown_itr = 1;
                    for i = 1:numel(stateNames)
                        if isthere(i)==0
                            temp = nan;
                        else
                            temp = comp_i.x_equilibrium(isthere(i));
                        end
                        try
                            ss(bus_idx).(stateNames{i}) = temp;
                        catch
                            ss(bus_idx).(['Unknown',num2str(unknown_itr)]) = temp;
                            unknown_itr = unknown_itr +1;
                        end
                    end
                end
                ss = struct2table(ss);
            end
            out.x_equilibrium.(component_names{comp_idx}) = ss;
        end
    end
    

    if options.do_report
        if options.branch
            bar = '================';
            fprintf(['ブランチのパラメータ\n',bar,'\n'])
            disp(out.branch)
            fprintf('\n\n')
        end
        if options.bus
            fprintf(['潮流状態\n',bar,'\n'])
            disp(out.bus)
            fprintf('\n\n')
        end
        if options.component_para
            fprintf(['機器のパラメータ\n',bar,'\n'])
            for i = 1:numel(component_names)
                if ~isempty(out.component_para.(component_names{i}))
                    disp(component_names{i})
                    disp(out.component_para.(component_names{i}))
                    fprintf('\n\n')
                end
            end
        end
        if options.x_equilibrium
            fprintf(['状態の平衡点\n',bar,'\n'])
            for i = 1:numel(component_names)
                if ~isempty(out.x_equilibrium.(component_names{i}))
                    disp(component_names{i})
                    disp(out.x_equilibrium.(component_names{i}))
                    fprintf('\n\n')
                end
            end
        end
    end

end


function data = class2struct(prop)

    field_i = tools.cellfun(@(prop_i) fieldnames(prop_i),prop);
    [field,~,idx] = unique(vertcat(field_i{:}),'stable');
    isthere = tools.cellfun(@(idx) ismember(field,idx),field_i);
    isthere = horzcat(isthere{:});
    
    for prop_i = 1:numel(prop)
        data(prop_i).idx = prop_i;
        for idx_field = 1:numel(field)
            fname = field{idx_field};
            if isthere(idx_field,prop_i)
                data(prop_i).(fname) = prop{prop_i}.(fname);
            else
                data(prop_i).(fname) =nan;
            end
        end
    end

    number = tools.cellfun(@(i) (1:numel(i))',field_i);
    number = vertcat(number{:});
    [~,idx] = sort(arrayfun(@(a) sum(number(idx==a)),(1:numel(field))'));
    field = [{'idx'};field(idx)];
    data = orderfields(data,field);

end