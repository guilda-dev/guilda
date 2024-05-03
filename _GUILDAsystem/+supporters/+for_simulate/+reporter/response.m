classdef response < handle

    properties
        state_list
        state_line

        busidx
        time_interval = 0.1;
        colororder = [colororder;...
                    [ 51,  34, 136;...
                     136, 204, 238;...
                      68, 170, 153;...
                      17, 119,  51;...
                     153, 153,  51;...
                     221, 204, 119;...
                     204, 102, 119;...
                     136,  34,  58;...
                     170,  68, 153;...
                     221, 221, 221]./256 ...
                     ];

        vargin

        last_time = 0;
        stash = struct('time',[],'data',{[]})
        net
        ax
        tlim
        stateidx
    end

    methods
        function obj = response(tlim,net,state_name)
            obj.net = net;
            obj.tlim = tlim;

            state_list = unique(tools.hcellfun(@(b) b.component.get_state_name(:)', net.a_bus));
            state_mat = false(numel(net.a_bus),numel(state_name));
            for i = 1:numel(state_name)
                state_i = state_name{i};
                switch state_i
                    case state_list
                    case {'I','V','P','Q'}
                    otherwise
                end
            end
            
            
            obj.vargin = StateHolder;
            if nargin < 5
                busidx = 1:numel(net.a_bus);
            end
            obj.busidx = busidx;
            obj.state_list = state;
            obj.init_plot;
            obj.stash.time = [];
            obj.stash.data = cell(numel(obj.state_list),1);
            obj.time_interval = (tlim(end)-tlim(1))/100;
        end

        function set.state_list(obj, state)
            state = obj.register_state(state);
            obj.state_list = state;
        end

        function out = register_state(obj,state)
            out = cell(numel(state),1);
            unistate = unique(tools.hcellfun(@(b) b.component.get_state_name, obj.net.a_bus));
            flow = {'real','imag','abs','angle','arg'};
            Vflow = strcat('V',flow);
            Iflow = strcat('I',flow);
            power = {'P','Q','S','Factor'};
            for i = 1:numel(state)
                if ismember(state{i}, [Vflow,Iflow,power])
                    out{i}.tag = state{i};
                    out{i}.busidx = obj.busidx;
                    if contains(state{i},{'real','P'})
                        fdata = @(data) data(1);
                    elseif contains(state{i},{'imag','Q'})
                        fdata = @(data) data(2);
                    elseif contains(state{i},{'abs','S'})
                        fdata = @(data) norm(data(1)+1j*data(2));
                    elseif contains(state{i},{'angle','arg'})
                        fdata = @(data) angle(data(1)+1j*data(2));
                    elseif contains(state{i},{'Factor'})
                        fdata = @(data) data(1)/norm(data);
                    end
                    if ismember(state{i},Vflow)
                        out{i}.access = @(own,ibus) fdata(own.vargin.Vall(:,ibus));
                    elseif ismember(state{i},Iflow)
                        obj.vargin.required.I = true;
                        out{i}.access = @(own,ibus) fdata(own.vargin.Iall(:,ibus));
                    elseif ismember(state{i},power)
                        obj.vargin.required.power = true;
                        out{i}.access = @(own,ibus) fdata(own.vargin.power(:,ibus));
                    end
                elseif ismember(state{i},unistate)
                    out{i}.tag = state{i};
                    obj.stateidx{i} = nan(numel(obj.busidx),1);
                    for ii = obj.busidx(:)'
                        names = obj.net.a_bus{ii}.component.get_state_name;
                        temp  = find(strcmp(names,state{i}));
                        if ~isempty(temp)
                            obj.stateidx{i}(ii) = temp(1);
                        end
                    end
                    out{i}.busidx = obj.busidx(~isnan(obj.stateidx{i}));
                    out{i}.access = @(~,ibus) obj.fdata_for_state(i,ibus);
                end
            end
            out = out(cellfun(@(c)~isempty(c),out));
            obj.busidx = unique(tools.hcellfun(@(c) c.busidx(:)', out), 'sorted');
        end
        
        function out = fdata_for_state(obj,istate,ibus)
            var = obj.vargin.mac{ibus};

            if isempty(var)
                out=nan; 
            elseif isnan(obj.stateidx{istate}(ibus))
                out=nan;
            else
                out =var{1}(obj.stateidx{istate}(ibus));
            end
        end

        
        function init_plot(obj)
            figure();
            obj.ax = tiledlayout('flow','TileSpacing','compact');
            
            for i = 1:numel(obj.state_list)
                nexttile
                hold on
                grid on
                xlim(obj.tlim([1,end]))
                xlabel('Time(s)',    'FontSize', 15, 'FontWeight', 'bold')
                ylabel(obj.state_list{i}.tag,'FontSize', 15, 'FontWeight', 'bold')

                obj.state_line{i} = cell(numel(obj.busidx),1);
                for j = obj.busidx(:)'
                    idx_color = 1+ mod( j-1, size(obj.colororder,1) );
                    obj.state_line{i}{j} = animatedline('LineWidth',1,'Color',obj.colororder(idx_color,:));
                end
            end

            lgd = legend(obj.ax.Children(end).Children(end:-1:1),tools.arrayfun(@(i)['bus/mac ',num2str(i)],obj.busidx));
            lgd.Layout.Tile = 'east';
            lgd.NumColumns = ceil(numel(obj.busidx)/30);
        end

                
        function out = plotFcn(obj, t, ~, ~)
            if isempty(obj.ax) || ~isgraphics(obj.ax)
                obj.init_plot
            end
            if numel(t) ==1
                for i = 1:numel(obj.state_list)
                    d = obj.state_list{i};
                    newdata = tools.varrayfun(@(idx) d.access(obj,idx), obj.busidx);
                    obj.stash.data{i} = [obj.stash.data{i}, newdata];
                end
                obj.stash.time = [obj.stash.time, t];

                if ( t - obj.last_time ) > obj.time_interval
                    obj.add_plot
                    obj.last_time = t;
                end
            end
            out = false;
        end

        function add_plot(obj)
            for iax  = 1:numel(obj.state_list)
                idata = obj.state_list{iax};
                iline = obj.state_line{iax};
                for ibus = 1:numel(obj.busidx)
                    if ismember(ibus,idata.busidx)
                        addpoints(iline{ibus}, obj.stash.time, obj.stash.data{iax}(ibus,:) );
                    end
                end
                obj.stash.data{iax} = [];
            end
            obj.stash.time = [];
            drawnow limitrate
        end
    end
end
