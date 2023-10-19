classdef power_network  < base_class.handleCopyable & base_class.Edit_Monitoring

    properties(Dependent)
        x_equilibrium
        V_equilibrium
        I_equilibrium
    end
    
    properties(SetAccess = protected)
        a_bus = {}
        a_controller_global = {}
        a_controller_local = {}
        a_branch = {}
    end

    properties
        omega0 = 2*pi*60;
    end
    
    methods(Static)
        varargout = get_dx(varargin);
        sys = get_sys_controllers(varargin);
    end
    methods
        [V, I] = calculate_power_flow(obj, varargin);
        out    = simulate(obj, t, u, index_u, varargin);
        func   = get_func_dx(obj, t, u, u_idx, fault, options);
        [Y, Ymat, A, Amat] = reduce_admittance_matrix(obj, Y, index);
        data   = information(obj, varargin);
        [cost_total,cost_branch,cost_component] = get_cost_function(obj,varargin)
        controller_list(obj,fig)

        function initialize(obj)
            [V, I] = obj.calculate_power_flow();
            for i = 1:numel(obj.a_bus)
               obj.a_bus{i}.set_equilibrium(V(i), I(i)); 
            end
            obj.reflected;
        end

        function app = GUI(obj,varargin)
            app = supporters.for_user.GUI(obj,varargin{:});
        end

        % DependentプロパティのGetメソッド
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


