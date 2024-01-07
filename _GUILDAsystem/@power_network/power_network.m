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
            app = supporters.for_GUI.GUI(obj,varargin{:});
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

        function x0 = get.x0_controller_local(obj)
            x0 = tools.vcellfun(@(c) c.get_x0, obj.a_controller_local);
        end

        function x0 = get.x0_controller_global(obj)
            x0 = tools.vcellfun(@(c) c.get_x0, obj.a_controller_global);
        end



        % 母線の追加・削除に関するメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function add_bus(obj, bus)
            bus = check_class(bus,'bus');
            bus_num = numel(obj.a_bus);
            arrayfun(@(i) bus{i}.setprop('index',bus_num+i), 1:numel(bus));
            cellfun(@(b)b.register_parent(obj,'overwrite'),bus)
            obj.register_child(bus,'stack');
            obj.a_bus = [obj.a_bus,bus];
        end

        function remove_bus(obj,index)
            if nargin<2
                index = 1:numel(obj.a_bus);
            end
            obj.remove_branch(index,'bus')
            obj.a_bus(index) = [];
            arrayfun(@(i) obj.a_bus{i}.setprop('index',i), 1:numel(obj.a_bus));
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
                branch{i}.setprop('index',branch_num+i);
            end
            obj.register_child(branch,'stack');
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
            c = check_class(c,'controller');
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


