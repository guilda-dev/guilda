classdef power_network < handle
    
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
    
    methods(Static)
        varargout = get_dx(varargin);
        sys = get_sys_controllers(varargin);
    end
    
    methods
        [V, I] = calculate_power_flow(obj, varargin);
        add_bus(obj, bus);
        add_branch(obj, branch);
        set_equilibrium(obj, V, I);
        out = simulate(obj, t, u, index_u, varargin);
        options = simulate_options(obj, varargin);
        func = get_func_dx(obj, t, u, u_idx, fault, options);
        [Y, Ymat, A, Amat] = reduce_admittance_matrix(obj, Y, index);
        data = information(obj, varargin);

        function initialize(obj)
            [V, I] = obj.calculate_power_flow();
            obj.set_equilibrium(V, I);
        end
        
        function x = get.x_equilibrium(obj)
            x = tools.vcellfun(@(b) b.component.x_equilibrium, obj.a_bus);
        end

        function x = get.V_equilibrium(obj)
            x = tools.vcellfun(@(b) b.V_equilibrium, obj.a_bus);
        end
        
        function x = get.I_equilibrium(obj)
            x = tools.vcellfun(@(b) b.I_equilibrium, obj.a_bus);
        end
        
        function add_controller_local(obj, controller)
            obj.remove_controller_local(controller.index_all);
            obj.a_controller_local{numel(obj.a_controller_local)+1} = controller;
        end
        
        function add_controller_global(obj, controller)
            obj.a_controller_global{numel(obj.a_controller_global)+1} = controller;
        end
        
        function remove_controller_local(obj, idx)
            remove_idx = [];
            for itr = 1:numel(obj.a_controller_local)
                if ~isempty(intersect(obj.a_controller_local{itr}.index_all, idx))
                    remove_idx = [remove_idx; itr]; %#ok
                end
            end
            obj.a_controller_local(remove_idx) = [];
        end
        
        function remove_controller_global(obj, idx)
            remove_idx = [];
            for itr = 1:numel(obj.a_controller_global)
                if ~isempty(intersect(obj.a_controller_global{itr}.index_all, idx))
                    remove_idx = [remove_idx; itr]; %#ok
                end
            end
            obj.a_controller_local(remove_idx) = [];
        end
        
        function check_bus_edited(obj)
            edited = tools.hcellfun(@(bus) bus.edited, obj.a_bus);
            if any(edited)
                disp(['bus',mat2str(find(edited)),'の潮流設定が変更されています.'])
                sw = input('再度,潮流計算しますか？(y/n)：',"str");
                if strcmp(sw,'y')
                    obj.initialize();
                end
            end
        end

    end
    
end


