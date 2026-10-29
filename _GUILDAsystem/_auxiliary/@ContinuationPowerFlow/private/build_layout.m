function w = build_layout(net, useInt)
% Variable layout of the CPF equations for net.
%   Writes the analysis working data on the models (bus.iv_CPFV, comp.iv_CPFX,
%   comp.f_PQ2Bus) and returns
%   w.rv_BusVi : rows of [|V|;angle V] of each bus in the full variable vector
%   w.rm_BusRM : selects the equations that are solved
%   w.rm_BusEM : maps the unknowns into the full variable vector
%   w.CONSTANT : fixed part of the full variable vector
%   w.InitVal  : unknowns at the equilibrium

    a_Bus = net.a_Bus;
    n_Bus = numel(a_Bus);
    id_VX = 0;

    R = cell(1,n_Bus);
    E = cell(1,n_Bus);
    C = cell(n_Bus,1);
    I = cell(n_Bus,1);

    for i=1:n_Bus
        i_Bus = a_Bus{i};
        a_Comp = i_Bus.a_Component;
        n_Comp = numel(a_Comp);

        tab_PF = i_Bus.get_pf_set();
        rv_Veq = [abs(i_Bus.c_Vequilibrium);angle(i_Bus.c_Vequilibrium)];

        Ci = cell(n_Comp,1);
        Ri = cell(1,n_Comp);
        Ii = cell(n_Comp,1);

        switch tab_PF{:,"Type"}
            case "slack"
                i_Bus.iv_CPFV = id_VX + (1:2);

                i_BusC = ~useInt * eye(2) * rv_Veq;
                i_BusR = id_VX + zeros(useInt,1) + (1:2);
                i_BusE = i_BusR;
                i_BusI = rv_Veq(repmat(useInt,2,1));

                id_VX = id_VX + 2;

                for j=1:n_Comp
                    i_Comp = a_Comp{j};
                    rv_Xeq = i_Comp.rv_Xequilibrium;
                    r_Xlen = numel(rv_Xeq);

                    if useInt
                        i_Comp.iv_CPFX = id_VX + (1:r_Xlen);
                        iv_CX = 3:r_Xlen;

                        Ci{j} = [rv_Xeq(1);zeros(r_Xlen-1,1)];
                        Ri{j} = id_VX + iv_CX;
                        Ii{j} = rv_Xeq(iv_CX);

                        id_VX = id_VX + r_Xlen;
                    end
                    setPQ2Bus(i_Comp);
                end
            case "PV"
                i_Bus.iv_CPFV = id_VX + (1:2);

                i_BusC = diag([~useInt,0]) * rv_Veq;
                i_BusR = id_VX + [1,ones(useInt,1)*2];
                i_BusE = id_VX + [  ones(1,useInt),2];
                i_BusI = rv_Veq([useInt,true]);

                id_VX = id_VX + 2;

                for j=1:numel(a_Comp)
                    i_Comp = a_Comp{j};
                    rv_Xeq = i_Comp.rv_Xequilibrium;
                    r_Xlen = numel(rv_Xeq);

                    if useInt && ~isempty(rv_Xeq)
                        i_Comp.iv_CPFX = id_VX + (1:r_Xlen);
                        iv_CX = [1,3:r_Xlen];

                        Ci{j} = zeros(r_Xlen,1);
                        Ri{j} = id_VX + iv_CX;
                        Ii{j} = rv_Xeq(iv_CX);

                        id_VX = id_VX + r_Xlen;
                    end
                    setPQ2Bus(i_Comp);
                end
            case "PQ"
                i_Bus.iv_CPFV = id_VX + (1:2);

                i_BusC = zeros(2,1);
                i_BusR = id_VX + (1:2);
                i_BusE = i_BusR;
                i_BusI = rv_Veq;

                id_VX = id_VX + 2;

                for j=1:numel(a_Comp)
                    i_Comp = a_Comp{j};
                    setPQ2Bus(i_Comp);
                end
        end

        R{i} = [i_BusR,Ri{:}];
        E{i} = [i_BusE,Ri{:}];
        C{i} = [i_BusC;Ci{:}];
        I{i} = [i_BusI;Ii{:}];
    end

    iv_BRM_all = horzcat(R{:});
    iv_BEM_all = horzcat(E{:});

    RM = eye(id_VX);
    EM = eye(id_VX);

    iv_BusVi = cell2mat( cellfun(@(b) b.iv_CPFV, a_Bus', 'UniformOutput', false) );

    w = struct();
    w.rv_BusVi = reshape(iv_BusVi,[],1);
    w.rm_BusRM = RM(ismember(1:id_VX,iv_BRM_all),:);
    w.rm_BusEM = EM(:,ismember(1:id_VX,iv_BEM_all));
    w.CONSTANT = vertcat(C{:});
    w.InitVal  = vertcat(I{:});

    function setPQ2Bus(i_Comp)
        CompVeq = i_Comp.c_Vequilibrium;
        CompIeq = i_Comp.c_Iequilibrium;
        CompSeq = CompVeq * conj(CompIeq);

        params = i_Comp.tab_parameter.dynamics{:,i_Comp.sv_para};
        if useInt
            i_Comp.f_PQ2Bus = @(x,V,u) i_Comp.getCompPQ(x,V,u,params);
        else
            i_Comp.f_PQ2Bus = @(x,V,u) [real(CompSeq);imag(CompSeq)];
        end
    end
end
