classdef state_holder < handle

    properties
        mac
        branch
        controller

        Ymat
        Yreproduced
        data


        required = struct('I',false,'power',false);
        Yall
        Vall
        Iall
        power
    end

    methods
        function obj = state_holder(net)
            obj.data.obj.branch = net.a_branch;
            obj.data.obj.bus = net.a_bus;
            obj.data.obj.mac = tools.cellfun(@(b) b.component, net.a_bus);

            equip = {'bus','mac','branch'};
            for i=1:3;obj.data.num.(equip{i})=numel(obj.data.obj.(equip{i}));end
        end

        function set_vargin_mac(obj,var)
            obj.mac = var;
        end
        function set_vargin_controller(obj,var)
            obj.controller = var;
        end
        function set_vargin_branch(obj,var)
            obj.branch = var;
        end

        function val = get.branch(obj)
            obj.organize_vargin(obj.branch)
            val = obj.branch;
        end

        function organize_vargin(obj,V)
            if ~iscell(V)
                Vvec = obj.Yreproduced * V;
                obj.Vall = reshape( Vvec, 2,[]);
                obr  = obj.data.obj.branch;
                nbr  = obj.data.num.branch;
                obj.branch = cell(nbr,1);
                for i = 1:nbr
                    br = obr{i};
                    obj.branch{i} = {obj.Vall(:,br.from),obj.Vall(:,br.to),};
                end
            end

            if obj.required.I
                obj.Iall = reshape(obj.Yall*Vvec,2,[]);
                if obj.required.power
                    Vcomplex = tools.vec2complex(obj.Vall);
                    Icomplex = tools.vec2complex(obj.Iall);
                    PQ = Vcomplex.*conj(Icomplex);
                    obj.power = [real(PQ);imag(PQ)];
                end
            end
        end
    end

end