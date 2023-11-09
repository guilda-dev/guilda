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

    properties
        omega0 = 2*pi*60;
        linear = false;
    end

    methods

        % 微分方程式の求解に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        out    = simulate(obj, t, u, index_u, varargin);
        [cost_total,cost_branch,cost_component] = get_cost_function(obj,varargin)

        

        % 潮流計算に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [V, I] = calculate_power_flow(obj, varargin);
        function initialize(obj)
            [V, I] = obj.calculate_power_flow();
            for i = 1:numel(obj.a_bus)
               obj.a_bus{i}.set_equilibrium(V(i), I(i)); 
            end
            obj.reflected;
            obj.linear = obj.linear;
        end

        

        % 近似線形化システムの取得に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        sys =get_sys(obj, with_controller)


        
        % アドミタンス行列の取得に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [Y, Ymat] = get_admittance_matrix(obj, a_idx_bus, a_idx_branch)
        [Y, Ymat, A, Amat] = reduce_admittance_matrix(obj, Y, index);



        % ユーザインタフェースに関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        data   = information(obj, varargin);
        controller_list(obj,fig)

        function app = GUI(obj,varargin)
            app = supporters.for_user.GUI(obj,varargin{:});
        end



        % DependentプロパティのGetメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function x = get.x_equilibrium(obj)
            x = tools.vcellfun(@(b) b.component.x_equilibrium, obj.a_bus);
        end

        function x = get.V_equilibrium(obj)
            x = tools.vcellfun(@(b) b.V_equilibrium, obj.a_bus);
        end
        
        function x = get.I_equilibrium(obj)
            x = tools.vcellfun(@(b) b.I_equilibrium, obj.a_bus);
        end
    


        % 母線の追加・削除に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function add_bus(obj, bus)
            bus = obj.check_class(bus,'bus');
            bus_num = numel(obj.a_bus);
            arrayfun(@(i) bus{i}.setprop('index',bus_num+i), 1:numel(bus));
            cellfun(@(b)b.register_parent(obj,'overwrite'),bus)
            obj.register_child(bus,'stack');
            obj.a_bus = [obj.a_bus,bus];
        end

        function remove_bus(obj,index)
            obj.a_bus(index) = [];
            arrayfun(@(i) obj.a_bus{i}.setprop('index',i), 1:numel(obj.a_bus));
        end



        % ブランチの追加・削除に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function add_branch(obj, branch)
            branch = obj.check_class(branch,'branch');
            branch_num = numel(obj.a_branch);
            for i = 1:numel(branch)
                branch{i}.register_parent(obj,'overwrite');
                branch{i}.from = branch{i}.from;
                branch{i}.to   = branch{i}.to;
                branch{i}.setprop('index',branch_num+i);
            end
            obj.register_child(branch,'stack');
            obj.a_branch = [obj.a_branch,branch];
        end

        function remove_branch(obj,index)
            obj.a_branch(index) = [];
            arrayfun(@(i) obj.a_branch{i}.setprop('index',i), 1:numel(obj.a_branch));
        end



        % 制御器の追加・削除に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function add_controller_local(obj, c)
            obj.add_controller(c,'local')
        end

        function remove_controller_local(obj,type,index)
            if nargin == 2
                index = type;
                type  = 'local_controller';
            end
            obj.remove_controller(type,index);
        end
        
        function add_controller_global(obj, c)
            obj.add_controller(c,'global')
        end
        
        function remove_controller_global(obj,busidx,conidx)
                
            if nargin == 3
                obj.controller_global(conidx) = [];
            end
            cidx = tools.vcellfun(@(c) ~isempty(intersect(c.index_all,busidx)), obj.controller_global);
            obj.a_controller_global(cidx) = [];
        end

        function add_controller(obj,c,gl)
            c = obj.check_class(c,'controller');
            cellfun(@(ic)ic.register_parent(obj,'overwrite'),c)
            obj.register_child(c,'stack');
            if nargin==3 
                if ismember(gl,{'local','global'})
                    for i=1:numel(c)
                        c{i}.type = gl;
                    end
                else
                    error('The controller type must be specified as either local or global.')
                end
            end
            for i = 1:numel(c)
                switch c{i}.type
                    case 'local'
                        obj.a_controller_local = [obj.a_controller_local,c(i)];
                    case 'global'
                        obj.a_controller_global = [obj.a_controller_global,c(i)];
                end
            end
        end

        

        % 線形・非線形の切り替え
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function set.linear(obj,linear)
            if linear
                for i = 1:numel(obj.a_controller_global)    %#ok
                    c = obj.a_controller_global{i};         %#ok
                    c.get_dx_u_func = @c.get_dx_u_linear;
                end
                for i = 1:numel(obj.a_controller_local )    %#ok
                    c = obj.a_controller_local{i};          %#ok
                    c.get_dx_u_func = @c.get_dx_u_linear;
                end
                for i = 1:numel(obj.a_bus)                  %#ok
                    c = obj.a_bus{i}.component;             %#ok
                    c.get_dx_con_func = @c.get_dx_constraint_linear;
                end
            else
                for i = 1:numel(obj.a_controller_global)    %#ok
                    c = obj.a_controller_global{i};         %#ok
                    c.get_dx_u_func = @c.get_dx_u;
                end
                for i = 1:numel(obj.a_controller_local )    %#ok
                    c = obj.a_controller_local{i};          %#ok
                    c.get_dx_u_func = @c.get_dx_u;
                end
                for i = 1:numel(obj.a_bus)                  %#ok
                    c = obj.a_bus{i}.component;             %#ok
                    c.get_dx_con_func = @c.get_dx_constraint;
                end
            end
            obj.linear = linear;
        end

    end
    
    methods(Access=protected)
        function data = check_class(obj,data,classname)%#ok
            if ~iscell(data)
                data = {data};
            end
            if any(tools.vcellfun(@(l) ~isa(l, classname),data))
                error(['must be a child of ',classname]);
            end
        end
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end
    end
    
end


