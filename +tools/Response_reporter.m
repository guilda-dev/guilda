classdef Response_reporter < handle

    properties
        state_tag = 'omega';
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
    end

    properties(SetAccess=private)
        net
        tlim
        idx_state
        idx_bus_num
    end

    properties(Access=private)
        last_time = 0;
        stash
        ax
        plot_line
        time_line
    end


    methods
        function obj = Response_reporter(net,tlim, state)
            obj.net = net;
            obj.tlim = tlim;
            if nargin > 2
                obj.state_tag = state;
            end
            obj.init_plot;
        end

        function set.state_tag(obj, state)
            obj.state_tag = state;
            obj.set_state;
        end

        function set_state(obj)
            
            nbus = numel(obj.net.a_bus);
            cell_state   = cell(nbus,1);
            cell_bus_num = cell(nbus,1);
            for i = 1:nbus
                c = obj.net.a_bus{i}.component;  
                cell_state{i}   = reshape(strcmp(c.get_state_name, obj.state_tag),1,[]);
                cell_bus_num{i} = i * ones(1,c.get_nx);
            end
            index_state   = horzcat(cell_state{:});
            index_bus_num = horzcat(cell_bus_num{:});

            obj.idx_state   = find(index_state);
            obj.idx_bus_num = index_bus_num(index_state);
        end

        function init_plot(obj)
            obj.set_state
            nidx = numel(obj.idx_state);
            obj.plot_line = cell(nidx,1);
            word_legend   = cell(nidx,1);

            figure()
            hold on
            grid on
            xlim(obj.tlim)
            xlabel('Time(s)',    'FontSize', 15, 'FontWeight', 'bold')
            ylabel(obj.state_tag,'FontSize', 15, 'FontWeight', 'bold')
            title('Response reporter', 'FontSize', 20, 'FontWeight', 'bold')
            obj.time_line = xline(0,'LineWidth',0.5);
            for i = 1:nidx
                idx_bus = obj.idx_bus_num(i);
                idx_color = 1+ mod( i-1, size(obj.colororder,1) );

                obj.plot_line{i} = animatedline('LineWidth',1.1,'Color',obj.colororder(idx_color,:));
                word_legend{i}   = [ class(obj.net.a_bus{idx_bus}.component),num2str(idx_bus) ];
            end
            legend([{'time axis'};word_legend], 'Location', 'southoutside', 'Interpreter','none', 'NumColumns',4, 'FontSize',8)
            hold off
            obj.ax = gca;
        end

                
        function out = plotFcn(obj, t, y, ~)
            if isempty(obj.ax) || ~isgraphics(obj.ax)
                obj.init_plot
            end
            if numel(t) ==1
                state = y(obj.idx_state);
                newdata = [t; state(:)];
                obj.stash = [obj.stash, newdata];

                if ( t - obj.last_time ) > obj.time_interval
                    obj.add_plot
                    obj.last_time = t;
                end
            end
            out = false;
        end

        function add_plot(obj)
            for i = 1:numel(obj.idx_state)
                addpoints(obj.plot_line{i}, obj.stash(1,:), obj.stash(i+1,:) );
            end
            obj.time_line.Value = obj.stash(1,end);
            drawnow limitrate
            obj.stash = [];
        end
    end
end
