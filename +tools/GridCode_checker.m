classdef GridCode_checker < handle

    properties    
        observe = true;
        control = false;
        Continue = true;
    end

    properties(SetAccess=private)
        record_sampling_time
        record_gridcode_component
        record_gridcode_branch
        record_connected_component
        record_connected_branch
    end

    properties(Access = private)
        net
        nbus
        nbr

        abr_grid_code
        abus_grid_code
        abus_restoration

        separate_Vmat_from
        separate_Vmat_to
        culcV_mat_from
        culcV_mat_to


        % liveのためのプロパティ
        ax
        tlim
        t_last
        t_interval = 1;
    end

    methods
        function obj = GridCode_checker(net, mode, tlim)

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

            obj.net = net;
            obj.nbus = numel(net.a_bus);
            obj.nbr  = numel(net.a_branch);
            obj.t_last = floor(tlim(1));
            obj.tlim = tlim;
            obj.separate_Vmat_from = zeros(2*obj.nbr,2*obj.nbus);
            obj.separate_Vmat_to   = zeros(2*obj.nbr,2*obj.nbus);

            obj.abus_grid_code   = true(obj.nbus,1);
            for i = 1:obj.nbr
                br = net.a_branch{i};
                obj.separate_Vmat_from(2*i+[-1,0],2*br.from+[-1,0]) = eye(2);
                obj.separate_Vmat_to(  2*i+[-1,0],  2*br.to+[-1,0]) = eye(2);

                Vfr = obj.net.a_bus{br.from}.V_equilibrium;
                Vto = obj.net.a_bus{br.to  }.V_equilibrium;
                obj.abr_grid_code(i) = ~isnan(br.grid_code(br,Vfr,Vto));
            end

            obj.abus_grid_code   = true(obj.nbus,1);
            obj.abus_restoration = true(obj.nbus,1);
            for i = 1:obj.nbus
                c = obj.net.a_bus{i}.component;
                x = c.x_equilibrium;
                V = tools.complex2vec(c.V_equilibrium);
                I = tools.complex2vec(c.I_equilibrium);
                u = zeros(c.get_nu,1);
                obj.abus_grid_code(i)   = ~isnan(c.grid_code(c,0,x,V,I,u));
                obj.abus_restoration(i) = ~isnan(c.restoration(c,0,x,V,I,u));
            end
            
        end

        function [value,isterminal,direction] = EventFcn(obj)
            if numel(obj.record_sampling_time)>1
                pre_connected = [obj.record_connected_component(:,end-1); obj.record_connected_branch(:,end-1)];
                now_connected = [obj.record_connected_component(:, end ); obj.record_connected_branch(:, end )];
                if any(pre_connected ~= now_connected)
                    obj.Continue = false;
                end
            end
            value = obj.Continue;
            isterminal = 1;
            direction  = [];
        end


        function newline(obj, time)
            if isempty(obj.record_sampling_time) || time > obj.record_sampling_time(end)
                if isempty(obj.record_sampling_time)
                    obj.record_connected_component = tools.vcellfun(@(bus) bus.component.is_connected, obj.net.a_bus   );
                    obj.record_connected_branch    = tools.vcellfun(@(br)             br.is_connected, obj.net.a_branch);
                else
                    obj.record_connected_component = [obj.record_connected_component, obj.record_connected_component(:,end)];
                    obj.record_connected_branch    = [obj.record_connected_branch   , obj.record_connected_branch(:,end)   ]; 
                end
                obj.record_sampling_time       = [obj.record_sampling_time,      time];
                if obj.observe
                    obj.record_gridcode_component  = [obj.record_gridcode_component, nan(obj.nbus,1)];
                    obj.record_gridcode_branch     = [obj.record_gridcode_branch   , nan(obj.nbr ,1)]; 
                end
            end
        end
        

        function set_Ymat_reproduce(obj, Ymat_reproduce)
            obj.culcV_mat_from = obj.separate_Vmat_from * Ymat_reproduce;
            obj.culcV_mat_to   = obj.separate_Vmat_to   * Ymat_reproduce;
        end

       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%  get_dx内で呼び出される関数軍　%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function report_component(obj, i, t, x, V, I, u)
            comp = obj.net.a_bus{i}.component;
            is_connected = comp.is_connected;
            if obj.observe
                if is_connected && obj.abus_grid_code(i)
                    check = comp.grid_code(comp,t,x,V,I,u);
                    if (~check) && obj.control
                        comp.disconnect;
                        obj.Continue = false;
                    end
                elseif (~is_connected) && obj.abus_restoration(i)
                    check = comp.restoration(comp,t,x,V,I,u);
                    if check && obj.control
                        comp.connect;
                        obj.Continue = false;
                    end
                else
                    check = nan;
                end
                obj.record_gridcode_component(i,end) = check;
            end
            obj.record_connected_component(i,end) = is_connected;
        end

        function report_branch(obj, Varray)
            if obj.observe
                Vfrom = reshape( obj.culcV_mat_from * Varray, 2, []);
                Vto   = reshape( obj.culcV_mat_to   * Varray, 2, []);
            end
            for i = 1:obj.nbr
                br = obj.net.a_branch{i};
                if obj.observe
                    if br.is_connected && obj.abr_grid_code(i)
                        check = br.grid_code(br, Vfrom(:,i), Vto(:,i));
                        if (~check) && obj.control
                            obj.Continue = false;
                            br.disconnect;
                        end
                    else
                        check = nan;
                    end
                    obj.record_gridcode_branch(i,end) = check;
                end
                obj.record_connected_branch(i,end) = br.is_connected;
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



        %%%%%%%%%%%%%%%%%%%%%%%%%%%   解析結果のVisualization  %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function view_result(obj)
            obj.set_axis;
            hold(obj.ax{1},'on')
            for i = 1:obj.nbus
                idx = find( diff([obj.record_gridcode_component(i,:),2]) ~= 0 );
                tidx = diff( [0,obj.record_sampling_time(idx)] );
                b = barh(obj.ax{1}, obj.nbus+1-i, tidx, 'stacked');
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0, 0.4470, 0.7410]), find(obj.record_gridcode_component(i,idx)==true  ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[0.8500, 0.3250, 0.0980]), find(obj.record_gridcode_component(i,idx)==false ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0,      0,      0]), find(isnan(obj.record_gridcode_component(i,idx)) ))
            end

            hold(obj.ax{2},'on')
            for i = 1:obj.nbr
                idx = find( diff([obj.record_gridcode_branch(i,:),2]) ~= 0 );
                tidx = diff( [0,obj.record_sampling_time(idx)] );
                b = barh(obj.ax{2}, obj.nbr+1-i, tidx, 'stacked');
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0, 0.4470, 0.7410]), find(obj.record_gridcode_branch(i,idx)==true  ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[0.8500, 0.3250, 0.0980]), find(obj.record_gridcode_branch(i,idx)==false ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0,      0,      0]), find(isnan(obj.record_gridcode_branch(i,idx)) ))
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





        %%%%%%%%%%%%%%%%%%%%%%%%%%%　  解析中のライブ用メソッド　　%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function out = live(obj,t,~,~)
            if isempty( obj.ax{1} ) || ~isgraphics( obj.ax{1} )
                obj.set_axis;
            end

            hold(obj.ax{1},'on')
            hold(obj.ax{2},'on')

            if numel(t) == 1
                if obj.tlim(2) == t
                    obj.add_point(ceil(obj.tlim(2)));
                    hold(obj.ax{1},'off')
                    hold(obj.ax{2},'off')
                else
                    obj.add_point(t)
                end
            end
            out = false;
        end

        function add_point(obj,t)
            if (t - obj.t_last) >= obj.t_interval
                t = obj.t_last + obj.t_interval/2;
                obj.t_last = obj.t_last + obj.t_interval;

                data = obj.record_connected_component(:,end);
                scatter(obj.ax{1}, t, obj.nbus+1-find(data==1), 50, 'Marker', 'o', 'MarkerEdgeColor', [     0, 0.4470, 0.7410], 'LineWidth', 2);
                scatter(obj.ax{1}, t, obj.nbus+1-find(data==0), 50, 'Marker', 'x', 'MarkerEdgeColor', [0.8500, 0.3250, 0.0980], 'LineWidth', 2);
    
                data = obj.record_connected_branch(:,end);
                scatter(obj.ax{2}, t, obj.nbr+1-find(data==1), 50, 'Marker', 'o', 'MarkerEdgeColor', [     0, 0.4470, 0.7410], 'LineWidth', 2);
                scatter(obj.ax{2}, t, obj.nbr+1-find(data==0), 50, 'Marker', 'x', 'MarkerEdgeColor', [0.8500, 0.3250, 0.0980], 'LineWidth', 2);

                drawnow limitrate
                obj.add_point(t)
            end
        end
            
        function set_axis(obj)
            tlim_format = floor(obj.tlim(1)):obj.t_interval:ceil(obj.tlim(2));
            list{1}     = arrayfun(@(i) [' ',class(obj.net.a_bus{obj.nbus+1-i}.component),' @bus',num2str(obj.nbus+1-i)], 1:obj.nbus, 'UniformOutput',false);
            list{2}     = cellfun(@(br) [' branch @bus',num2str(br.from),' - ',num2str(br.to)], obj.net.a_branch, 'UniformOutput',false);
            num         = [obj.nbus, obj.nbr];
            Title_list  = {'Component', 'Branch'};

            obj.ax = cell(2,1);
            figure('WindowState','maximized')
            for i =1:2
                subplot(1,2,i)
                obj.ax{i} = gca;
                obj.ax{i}.XLabel.String = 'second(s)';

                obj.ax{i}.XTick = tlim_format;
                obj.ax{i}.YTick = 1:num(i);

                obj.ax{i}.XLim = [tlim_format(1),tlim_format(end)];
                obj.ax{i}.YLim = [0,num(i)+0.5];
                
                obj.ax{i}.YTickLabel       = list{i};
                obj.ax{i}.YAxis.FontSize   = 7;
                obj.ax{i}.YAxis.FontWeight = 'bold';
                obj.ax{i}.YAxis.TickLabelInterpreter = 'none';

                obj.ax{i}.Title.FontSize   = 15;
                obj.ax{i}.Title.FontWeight = 'bold';
                obj.ax{i}.Title.String     = {Title_list{i},['○:',Title_list{i},' is connected, ×:',Title_list{i},' is disconnected']};

                grid on

            end
            sgtitle('Live connection status of each device','FontSize',20,'FontWeight','bold')
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end
end


