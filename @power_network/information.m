function out = information(obj,varargin)
    %引数に与えられたネットワークのモデルのパラメータを調べる用の関数

    p = inputParser;
    p.CaseSensitive = false;
    addParameter(p, 'do_report', true);

    addParameter(p, 'bus'           , true);
    addParameter(p, 'branch'        , true);
    addParameter(p, 'component_para', true);
    addParameter(p, 'x_equilibrium' , true);

    addParameter(p, 'plot_graph'     , false);
    addParameter(p, 'graphVisible'   , 'wheather_plot_or_not');
    addParameter(p, 'export_tex_data', false);
    
    %addParameter(p, 'pdf', false);
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

    if options.export_tex_data
        options.bus            = true;
        options.branch         = true;
        options.component_para = true;
        options.x_equilibrium  = true;
        options.plot_graph     = true;
    end

    except_Variable = {'CostFunction','grid_code','is_connected','edited','component'};
    %潮流状態の情報を取得
    if options.bus
        out.bus = my_class2table(obj.a_bus,'bus',except_Variable);
        out.bus{:,'Vabs'}   =   abs(out.bus{:,'V_equilibrium'});
        out.bus{:,'Vangle'} = angle(out.bus{:,'V_equilibrium'});
        out.bus{:,'P'}      =  real(out.bus{:,'V_equilibrium'}.*conj(out.bus{:,'I_equilibrium'}));
        out.bus{:,'Q'}      =  imag(out.bus{:,'V_equilibrium'}.*conj(out.bus{:,'I_equilibrium'}));
        connected_component = tools.vcellfun(@(b) {class(b.component)}, obj.a_bus);
        out.bus = [out.bus,table(connected_component)];
    end

    %ブランチの情報を取得
    if options.branch
        out.branch = my_class2table(obj.a_branch,'branch',except_Variable);
    end
    
    %コンポーネント名リスト取得
    component_names = tools.vcellfun(@(b) {class(b.component)},obj.a_bus);
    [component_names,~,idx] = unique(component_names,'stable');

    for comp_idx = 1:numel(component_names)
        
        component_name = component_names{comp_idx};
        idx_dot = find(component_names{comp_idx}=='.',1,'last');
        if ~isempty(idx_dot)
            component_name = component_name(idx_dot+1:end);
        end

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
                    if numel(temp)==0
                        temp = struct();
                    end
                    fname = fieldnames(temp);
                    temp.bus_idx = bus_idx;
                    temp = orderfields(temp,[{'bus_idx'};fname]);
                    para = [para,temp];
                end
                para = struct2table(para);
            end
            out.component_para.(component_name) = para;
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
            out.x_equilibrium.(component_name) = ss;
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
            fn = fieldnames(out.component_para);
            for i = 1:numel(fn)
                if ~isempty(out.component_para.(fn{i}))
                    disp(fn{i})
                    disp(out.component_para.(fn{i}))
                    fprintf('\n\n')
                end
            end
        end
        if options.x_equilibrium
            fprintf(['状態の平衡点\n',bar,'\n'])
            fn = fieldnames(out.x_equilibrium);
            for i = 1:numel(fn)
                if ~isempty(out.x_equilibrium.(fn{i}))
                    disp(fn{i})
                    disp(out.x_equilibrium.(fn{i}))
                    fprintf('\n\n')
                end
            end
        end
    end


    if options.plot_graph
        out.graph = tools.graph.plot(obj);
        out.graph.GCF = gcf;    
    end

    if options.export_tex_data
        tools.make_tex_data.main(obj,out);
    end

end


function out = my_class2table(prop,rowindex,except_Var)

    field_i = tools.cellfun(@(prop_i) setdiff(fieldnames(prop_i),except_Var),prop);
    [field,~,idx] = unique(vertcat(field_i{:}),'stable');
    isthere = tools.cellfun(@(idx) ismember(field,idx),field_i);
    isthere = horzcat(isthere{:});
    
    for prop_i = 1:numel(prop)
        data(prop_i).class = class(prop{prop_i});
        for idx_field = 1:numel(field)
            fname = field{idx_field};
            if isthere(idx_field,prop_i)
                data(prop_i).(fname) = prop{prop_i}.(fname);
            else
                data(prop_i).(fname) =nan;
            end
        end
    end

    [~,idx] = sort(arrayfun(@(a) sum(idx==a),(1:numel(field))'),'descend');
    field = [{'class'};field(idx)];
    data = orderfields(data,field);

    out = struct2table(data);
    out.Properties.RowNames = tools.arrayfun(@(i) [rowindex,num2str(i)], 1:numel(prop));     

end