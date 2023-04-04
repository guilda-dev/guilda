classdef GridCode_checker < handle

    properties    
        observe = true;
        control = false;

        record_time
        record_component
        record_branch

        Continue = true;

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
        tlim
        tnow
        live_data
        tcnt
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
            obj.tnow = tlim(1);
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
            value = obj.Continue;
            isterminal = 1;
            direction  = [];
        end


        function newline(obj, time)
            if isempty(obj.record_time) || time >= obj.record_time(end)+0.1
                obj.record_component = [obj.record_component,nan(obj.nbus,1)];
                obj.record_branch    = [obj.record_branch   ,nan(obj.nbr ,1)]; 
                obj.record_time      = [obj.record_time, time];
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
            if obj.observe
                if comp.is_connected && obj.abus_grid_code(i)
                    status = comp.grid_code(comp,t,x,V,I,u);
                    if status == false
                        obj.Continue = false;
                        if obj.control
                            comp.disconnect;
                        end
                    elseif isnan(status)
                        status = comp.is_connected;
                    end
                elseif (~comp.is_connected) && obj.abus_restoration(i)
                    status = comp.restoration(comp,t,x,V,I,u);
                    if status == true
                        obj.Continue = false;
                        if obj.control
                            comp.connect;
                        end
                    elseif isnan(status)
                        status = comp.is_connected;
                    end
                else
                    status = comp.is_connected;
                end
                obj.record_component(i,end) = status;
            end
        end

        function report_branch(obj, Varray)
            if obj.observe
                Vfrom = obj.culcV_mat_from * Varray;
                Vto   = obj.culcV_mat_to   * Varray;
                for i = 1:obj.nbr
                    br = obj.net.a_branch{i};
                    if br.is_connected
                        status = br.grid_code(br, Vfrom([2*i-1, 2*i]), Vto([2*i-1, 2*i]));
                        if status == false
                            obj.Continue = false;
                            br.disconnect;
                        elseif isnan(status)
                            status = br.is_connected;
                        end
                    else
                        status = false;
                    end
                    obj.record_branch(i,end) = status;
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



        %%%%%%%%%%%%%%%%%%%%%%%%%%%   解析結果のVisualization  %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function view(obj)
            figure('WindowState','maximized')

            subplot(1,2,1)
            hold on
            for i = 1:obj.nbus
                idx = find( diff([obj.record_component(i,:),2]) ~= 0 );
                tidx = diff( [0,obj.record_time(idx)] );
                b = barh(obj.nbus+1-i,tidx,'stacked');
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0, 0.4470, 0.7410]), find(obj.record_component(i,idx)==true  ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[0.8500, 0.3250, 0.0980]), find(obj.record_component(i,idx)==false ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0,      0,      0]), find(isnan(obj.record_component(i,idx)) ))
            end
            yticklabels( arrayfun(@(i) ...
                        [class(obj.net.a_bus{obj.nbus+1-i}.component),'_',num2str(obj.nbus+1-i)], 1:obj.nbus, ...
                        'UniformOutput',false));
            yticks(1:obj.nbus)
            obj.set_axis;

            subplot(1,2,2)
            hold on
            for i = 1:obj.nbr
                idx = find( diff([obj.record_branch(i,:),2]) ~= 0 );
                tidx = diff( [0,obj.record_time(idx)] );
                b = barh(obj.nbr+1-i,tidx);
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0, 0.4470, 0.7410]), find(obj.record_branch(i,idx)==true  ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[0.8500, 0.3250, 0.0980]), find(obj.record_branch(i,idx)==false ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0,      0,      0]), find(isnan(obj.record_branch(i,idx)) ))
            end
            yticklabels( cellfun(@(br) ['branch',num2str(br.from),'-',num2str(br.to)], obj.net.a_branch, 'UniformOutput',false));
            yticks(1:obj.nbr)
            obj.set_axis;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





        %%%%%%%%%%%%%%%%%%%%%%%%%%%　  解析中のライブ用メソッド　　%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function live_init(obj)
            tlim_format  = floor(obj.tlim(1)):1:ceil(obj.tlim(2));
            arrayfun(@(idx) barh(idx,nan), 1:obj.nbus);
            obj.live_data = cell(obj.nbus,1);
            tdiff = obj.tnow - tlim_format(1);
            figure
            hold on
            for i = 1:obj.nbus
                obj.live_data{i} = barh( obj.nbus+1-i, [tdiff, ones(1,ceil(diff(obj.tlim)))],'stacked','FaceColor','None');
            end            
            yticklabels( arrayfun(@(i) [class(obj.net.a_bus{obj.nbus+1-i}.component),'_',num2str(obj.nbus+1-i)], 1:obj.nbus, 'UniformOutput',false) );
            yticks(1:obj.nbus)
            obj.set_axis
            drawnow
            obj.tcnt = 2;
        end

        function out = live(obj,t,~,flag)
            if ~isempty(t)
                if (t(end) - obj.tnow) >= 1
                    temp = obj.record_component(:,end);
                    for i = 1:obj.nbus
                        if temp(i)==true
                            c = [     0, 0.4470, 0.7410];
                        elseif temp(i)==false
                            c = [0.8500, 0.3250, 0.0980];
                        else
                            c = [0,0,0];
                        end
                        obj.live_data{i}(obj.tcnt).FaceColor = c;
                    end
                    drawnow
                    obj.tcnt = obj.tcnt + 1;
                    obj.tnow = obj.tnow + 1;
                end
                if strcmp(flag,'done')
                    obj.live(ceil(obj.tlim(2)),[],[]);
                end
            end
            out = false;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end

    methods(Access =  private)

        function set_axis(obj)
            tlim_format  = floor(obj.tlim(1)):1:ceil(obj.tlim(2));
            h_axes = gca;
            h_axes.YAxis.FontSize = 7;
            %h_axes.YAxis.FontWeight = 'bold';
            h_axes.YAxis.TickLabelInterpreter = 'none';
            xlabel('second(s)')
            xticks(tlim_format)
            xlim([tlim_format(1),tlim_format(end)])
            grid on
        end
    end
end


