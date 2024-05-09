classdef power_network  < base_class.handleCopyable & base_class.Edit_Monitoring

    properties(Dependent)
        x_equilibrium
        V_equilibrium
        I_equilibrium
    end

    properties(SetAccess = protected)
        a_bus = {}
        a_branch = {}
        a_controller_global = {}
        a_controller_local = {}
    end

    properties(Dependent)
        x0_controller_local
        x0_controller_global
    end

    properties
        omega0 = 2*pi*60;
        linear = false;
    end

    methods

        % 微分方程式の求解に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [out,sim] = simulate(obj, t, u, index_u, varargin);
        [cost_total,cost_branch,cost_component] = get_cost_function(obj,varargin)



        % 潮流計算に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [V, I, flag, output] = calculate_power_flow(obj, varargin)
        function initialize(obj)
            obj.reflected;
            [V, I] = obj.calculate_power_flow();
            for i = 1:numel(obj.a_bus)
                obj.a_bus{i}.set_equilibrium(V(i), I(i)); 
            end
            cellfun(@(c) c.update_idx, obj.a_controller_local)
            cellfun(@(c) c.update_idx, obj.a_controller_global)
            obj.linear = obj.linear;
        end



        % 近似線形化システムの取得に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        sys = get_sys(obj, with_controller)
        sys = get_sys_polar(obj, with_controller)
        sys = get_sys_controllers(obj, controllers, controllers_global)
        [sys_local, sys_env] = get_sys_area(obj, idx_area, with_controller, is_polar)



        % アドミタンス行列の取得に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [Y, Ymat] = get_admittance_matrix(obj, a_idx_bus, a_idx_branch)
        [Y, Ymat, A, Amat] = reduce_admittance_matrix(obj, Y, index);



        % ユーザインタフェースに関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        data   = information(obj, varargin);
        controller_list(obj,fig)

        function app = GUI(obj,varargin)
            app = supporters.for_GUI.GUI(obj,varargin{:});
        end



        % DependentプロパティのGetメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function x = get.x_equilibrium(obj)
            obj.check_EditLog;
            x = tools.vcellfun(@(b) b.component.x_equilibrium, obj.a_bus);
        end

        function x = get.V_equilibrium(obj)
            obj.check_EditLog(["bus";"branch"]);
            x = tools.vcellfun(@(b) b.V_equilibrium, obj.a_bus);
        end

        function x = get.I_equilibrium(obj)
            obj.check_EditLog(["bus";"branch"]);
            x = tools.vcellfun(@(b) b.I_equilibrium, obj.a_bus);
        end

        function x0 = get.x0_controller_local(obj)
            obj.check_EditLog("controller");
            x0 = tools.vcellfun(@(c) c.get_x0, obj.a_controller_local);
        end

        function x0 = get.x0_controller_global(obj)
            obj.check_EditLog("controller");
            x0 = tools.vcellfun(@(c) c.get_x0, obj.a_controller_global);
        end



        % 母線の追加・削除に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function add_bus(obj, bus)
            bus = check_class(bus,'bus');
            bus_num = numel(obj.a_bus);
            arrayfun(@(i) bus{i}.register_index(bus_num+i), 1:numel(bus));
            cellfun(@(b)b.register_parent(obj,'overwrite'),bus)
            obj.register_child(bus,'stack')
            obj.a_bus = [obj.a_bus,bus];
        end

        function remove_bus(obj,index)
            if nargin<2
                index = 1:numel(obj.a_bus);
            end
            obj.remove_branch(index,'bus')
            obj.a_bus(index) = [];
            arrayfun(@(i) obj.a_bus{i}.register_index(i), 1:numel(obj.a_bus));
        end



        % ブランチの追加・削除に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function add_branch(obj, branch)
            branch = check_class(branch,'branch');
            branch_num = numel(obj.a_branch);
            for i = 1:numel(branch)
                branch{i}.register_parent(obj,'overwrite');
                branch{i}.from = branch{i}.from;
                branch{i}.to   = branch{i}.to;
                branch{i}.register_index(branch_num+i);
            end
            obj.register_child(branch,'stack')
            obj.a_branch = [obj.a_branch,branch];
        end

        function remove_branch(obj,index,type)
            if nargin<2
                index = 1:numel(obj.a_branch);
            end
            if nargin<3
                type = 'branch';
            end
            switch type
                case 'branch'   %typeが'branch'なら指定されたindexのブランチを削除
                    obj.a_branch(index) = [];
                case 'bus'      %typeが'bus'なら指定されたindexの母線と接続するブランチを削除
                    func = @(br) ismember(br.from,index) || ismember(br.to,index);
                    idx  = tools.vcellfun(@(br) func(br), obj.a_branch);
                    obj.a_branch(idx) = [];
            end
            arrayfun(@(i) obj.a_branch{i}.register_index(i), 1:numel(obj.a_branch));
        end



        % 制御器の追加・削除に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function add_controller_local(obj, c)
            obj.add_controller(c,'local')
        end

        function add_controller_global(obj, c)
            obj.add_controller(c,'global')
        end

        function remove_controller_local(obj,index)
            obj.a_controller_local(index) = [];
        end

        function remove_controller_global(objindex)
            obj.a_controller_global(index) = [];
        end

        function add_controller(obj,c,type)
            c = check_class(c,'controller');
            cellfun(@(ic)ic.register_parent(obj,'overwrite'),c)
            obj.register_child(c,'stack');
            if nargin==3; cellfun(@(con) con.set_glocal(type), c);end
            for i = 1:numel(c)
                switch c{i}.type
                    case 'local' ; obj.a_controller_local = [obj.a_controller_local,c(i)];
                    case 'global'; obj.a_controller_global = [obj.a_controller_global,c(i)];
                end
            end
        end



        % 線形・非線形の切り替え
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function set.linear(obj,linear)
            cellfun(@(c) c.set_function(linear), obj.a_controller_local)    %#ok
            cellfun(@(c) c.set_function(linear), obj.a_controller_global)   %#ok
            cellfun(@(b) b.component.set_function(linear), obj.a_bus)       %#ok
            obj.linear = linear;
        end

    end

    methods(Access=protected)
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end

        function check_EditLog(obj,type)
            if nargin==2 && ~isempty(obj.Edit_Log)
                idx = ismember(obj.Edit_Log.cls,type);
                Log = obj.Edit_Log(idx,:);
            else
                Log = obj.Edit_Log;
            end

            if ~isempty(Log)
                w_temp = warning('backtrace');
                warning('off','backtrace')
                warning(['Some elements have been edited. Data may not be matched.',newline,...
                         'To be sure, power flow calculations and equilibrium point calculations are recommended to be rerun.'],'verbose')
                warning(w_temp.state,'backtrace')
                flag = [];

                disp('Edit Log')
                disp(Log)
                while isempty(flag)
                    flag = input('Recalculate again?(y/n) : ','s');
                    switch flag
                    case {'y','yes',true,1}; flag = true;
                    case {'n','no',false,0}; flag = false;
                    otherwise; flag = [];
                    end
                end
                if flag
                    obj.initialize;
                end
            end
        end
    end
end

function data = check_class(data,classname)
    if ~iscell(data)
        data = {data};
    end
    if any(tools.vcellfun(@(l) ~isa(l, classname),data))
        error(['must be a child of ',classname]);
    end
end


