classdef GridCode_checker < handle

    properties    
        onoff = false;
        ignore_disconnected_machine = false;


        record_time
        record_component
        record_branch

        Continue = true;

    end

    properties(Access = private)
        net
        nbus
        nbr

        logical_connect_idx

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
        function obj = GridCode_checker(net, onoff, tlim)
            obj.net = net;
            obj.nbus = numel(net.a_bus);
            obj.nbr  = numel(net.a_branch);
            obj.onoff = onoff;
            obj.tnow  = tlim(1);
            obj.tlim  = tlim;

            obj.separate_Vmat_from = zeros(2*obj.nbr,2*obj.nbus);
            obj.separate_Vmat_to   = zeros(2*obj.nbr,2*obj.nbus);
            for i = 1:obj.nbr
                br = net.a_branch{i};
                obj.separate_Vmat_from(2*i-1,2*br.from-1)   =  1;
                obj.separate_Vmat_from(2*i  ,2*br.from)     =  1;
                obj.separate_Vmat_to(2*i-1,2*br.to-1) = 1;
                obj.separate_Vmat_to(2*i  ,2*br.to)   = 1;
            end
        end

        function [value,isterminal,direction] = EventFcn(obj)
            value = obj.Continue;
            isterminal = 1;
            direction  = [];
        end


        function newline(obj, time)
            obj.record_component = [obj.record_component,nan(obj.nbus,1)];
            obj.record_branch    = [obj.record_branch   ,nan(obj.nbr ,1)]; 
            obj.record_time      = [obj.record_time, time];
        end
        
        function [Ymat, Ymat_all, Ymat_reproduce] = get_reproduce_admittance_matrix(obj, simulated_bus)
            simulated_branch = find(tools.vcellfun(@( br) br.is_connected, obj.net.a_branch));
            
            [Y, Ymat_all]                = obj.net.get_admittance_matrix(1:obj.nbus, simulated_branch);
            [~, Ymat, ~, Ymat_reproduce] = obj.net.reduce_admittance_matrix(Y, simulated_bus);

            obj.set_Yreproduce(Ymat_reproduce);
        end
        

        function set_connect_bus(obj,idx)
            obj.logical_connect_idx = false(obj.nbus,1);
            obj.logical_connect_idx(idx) = true;
        end

       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%  get_dx内で呼び出される関数軍　%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function status = report_component(obj, i, t, x, V, I, u)
            comp = obj.net.a_bus{i}.component;
            if obj.onoff
                if comp.is_connected
                    status = comp.grid_code(comp,t,x,V,I,u);
                    if status == false
                        obj.Continue = false;
                        comp.disconnect;
                    elseif isnan(status)
                        status = comp.is_connected;
                    end
                else
                    status = comp.restoration(comp,t,x,V,I,u);
                    if status == true
                        obj.Continue = false;
                        comp.connect;
                    elseif isnan(status)
                        status = comp.is_connected;
                    end
                end
                obj.record_component(i,end) = status;
            else
                status = comp.is_connected;
            end
        end

        function report_branch(obj, Varray)
            if obj.onoff
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

        function [dx,I] = dx_I_filter(obj,idx,status,dx,I)
            if ~isnan(dx)
                if obj.ignore_disconnected_machine
                    if status==false
                        dx = zeros(size(dx));
                        I  = zeros(size(I));
                    end
                end
            end
            if ~ obj.logical_connect_idx(idx)
                I = [];
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
                [sheet, ~] = divide([],obj.record_component(i,:));
                tidx = diff( [0,obj.record_time(sheet(1,:))] );
                b = barh(obj.nbus+1-i,tidx,'stacked');
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0, 0.4470, 0.7410]), find(sheet(2,:)==true  ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[0.8500, 0.3250, 0.0980]), find(sheet(2,:)==false ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0,      0,      0]), find(isnan(sheet(2,:)) ))
            end
            yticklabels( arrayfun(@(i) ...
                        [class(obj.net.a_bus{obj.nbus+1-i}.component),'_',num2str(obj.nbus+1-i)], 1:obj.nbus, ...
                        'UniformOutput',false));
            yticks(1:obj.nbus)
            obj.set_axis;

            subplot(1,2,2)
            hold on
            for i = 1:obj.nbr
                [sheet, ~] = divide([],obj.record_branch(i,:));
                tidx = diff( [0,obj.record_time(sheet(1,:))] );
                b = barh(obj.nbr+1-i,tidx);
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0, 0.4470, 0.7410]), find(sheet(2,:)==true  ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[0.8500, 0.3250, 0.0980]), find(sheet(2,:)==false ))
                arrayfun(@(idx) set(b(idx), 'FaceColor',[     0,      0,      0]), find(isnan(sheet(2,:)) ))
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

        function out = live(obj,t,~,~)
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
                    obj.live(t(end),[],[]);
                end
    %             if strcmp(flag,'done')
    %                 obj.live(ceil(obj.tlim(2)),[],[]);
    %             end
            end
            out = false;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end

    methods(Access =  private)

        function set_Yreproduce(obj,Y)
            obj.culcV_mat_from = obj.separate_Vmat_from * Y;
            obj.culcV_mat_to = obj.separate_Vmat_to * Y;
        end

        function set_axis(obj)
            tlim_format  = floor(obj.tlim(1)):1:ceil(obj.tlim(2));
            h_axes = gca;
            h_axes.YAxis.FontSize = 7;
            %h_axes.YAxis.FontWeight = 'bold';
            h_axes.YAxis.TickLabelInterpreter = 'none';
            xlabel('second(s)')
            xticks(tlim_format)
            xlim([tlim_format(1),tlim_format(end)])
        end
    end
end



function [sheet,data] = divide(sheet,data)
    if numel(data)~=0
        mode = data(1);
        idx = find(data~=mode,1,'first');
        if isempty(sheet)
            preidx = 0;
        else
            preidx = sheet(1,end);
        end
        if isempty(idx)
            sheet = [ sheet, [preidx + numel(data);mode] ];
        else
            sheet = [ sheet, [preidx + idx-1;mode] ];
            [sheet,data] = divide(sheet,data(idx:end));
        end
    else
        sheet = zeros(2,0);
    end
end