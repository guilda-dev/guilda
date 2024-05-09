classdef organizer_net_index < handle

    properties
        network
        ignore_disconncted_mac = false;
        ignore_disconncted_con = false;
    end

    properties(Dependent)
        idx_x
        idx_u
        idx_xcl
        idx_xcg

        logical_x
        logical_u
        logical_xcl
        logical_xcg

        logimat_x
        logimat_u
        logimat_xcl
        logimat_xcg
    end

    methods
        function obj = organizer_net_index(net, ignore_disconnected)
            obj.network = net;
            if nargin == 2
                obj.ignore(ignore_disconnected)
            end
        end

        function ignore(obj,tf)
            obj.ignore_disconncted_mac = tf;
            obj.ignore_disconncted_con = tf;
        end

        function out = get_i(obj)
            idx_empty = tools.hcellfun(@(b) ~isa(b.component,'component.empty'), obj.network.a_bus);
            if obj.ignore_disconncted_mac
                idx = tools.hcellfun(@(b) strcmp(b.component.parallel,'on'), obj.network.a_bus);
            else
                idx = true( 1, numel(obj.network.a_bus) );
            end
            out = find(idx_empty & idx);
        end

        function out = get_ic(obj,lg)
            p = ['a_controller_',lg];
            if obj.ignore_disconncted_con
                idx = tools.hcellfun( @(c) strcmp(c.parallel,'on'), obj.network.(p) );
                out = find(idx);
            else
                out = 1:numel(obj.network.(p));
            end
        end

        function out = get.idx_x(obj)
            out = tools.varrayfun(@(i) i*ones(obj.network.a_bus{i}.component.get_nx,1), obj.get_i);
        end
        
        function out = get.idx_u(obj)
            out = tools.varrayfun(@(i) i*ones(obj.network.a_bus{i}.component.get_nu,1), obj.get_i);
        end
        
        function out = get.idx_xcl(obj)
            out = tools.varrayfun(@(i) i*ones(obj.network.a_controller_local{i}.get_nx,1), obj.get_ic('local'));
        end
        
        function out = get.idx_xcg(obj)
            out = tools.varrayfun(@(i) i*ones(obj.network.a_controller_global{i}.get_nx,1), obj.get_ic('global'));
        end

        function out = get.logical_x(obj)
            allidx = tools.varrayfun(@(i) i*ones(obj.network.a_bus{i}.component.get_nx,1), 1:numel(obj.network.a_bus));
            out = ismember(allidx,obj.get_i);
        end
        
        function out = get.logical_u(obj)
            allidx = tools.varrayfun(@(i) i*ones(obj.network.a_bus{i}.component.get_nu,1), 1:numel(obj.network.a_bus));
            out = ismember(allidx,obj.get_i);
        end
        
        function out = get.logical_xcl(obj)
            allidx = tools.varrayfun(@(i) i*ones(obj.network.a_controller_local{i}.get_nx,1), 1:numel(obj.network.a_controller_local));
            out = ismember(allidx,obj.get_ic('local'));
        end
        
        function out = get.logical_xcg(obj)
            allidx = tools.varrayfun(@(i) i*ones(obj.network.a_controller_global{i}.get_nx,1), 1:numel(obj.network.a_controller_global));
            out = ismember(allidx,obj.get_ic('global'));
        end
        
        function out = get.logimat_x(obj)
            data = obj.idx_x;
            out  = tools.harrayfun(@(i)data==i,1:numel(obj.network.a_bus));
        end

        function out = get.logimat_u(obj)
            data = obj.idx_u;
            out  = tools.harrayfun(@(i)data==i,1:numel(obj.network.a_bus));
        end

        function out = get.logimat_xcl(obj)
            data = obj.idx_xcl;
            out  = tools.harrayfun(@(i)data==i,1:numel(obj.network.a_controller_local ));
        end

        function out = get.logimat_xcg(obj)
            data = obj.idx_xcg;
            out  = tools.harrayfun(@(i)data==i,1:numel(obj.network.a_controller_global));
        end

        
    end

end