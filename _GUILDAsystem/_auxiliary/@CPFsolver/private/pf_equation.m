function func = pf_equation(net,w,sv_load,useInt,x,Ymat)
% Power flow equations of the CPF at x = [unknowns; lambda] (layout w, see build_layout).
% The loads of the buses sv_load (all loads when useInt) are scaled by (1 + lambda).
    bus = net.a_Bus;

    lambda = x(end);
    x = w.rm_BusEM * x(1:end-1) + w.CONSTANT;

    V = x(w.rv_BusVi);
    V = V(1:2:end) .* exp(1j*V(2:2:end));
    I = Ymat * V;

    PQ = V .* conj(I);

    nbus = numel(bus);
    func = cell(nbus,1);
    for i=1:nbus

        i_Bus = bus{i};
        V_Bus = x(i_Bus.iv_CPFV);

        a_Comp = i_Bus.a_Component;
        n_Comp = numel(a_Comp);
        f_Comp = cell(n_Comp,1);

        PQG = zeros(2,1);
        PQC = zeros(2,1);

        for j=1:n_Comp
            i_Comp = a_Comp{j};
            X_Comp = x(i_Comp.iv_CPFX);

            compSeq = i_Comp.c_Vequilibrium * conj(i_Comp.c_Iequilibrium);

            isLoad  = ismember(i_Bus.str_tag,sv_load);

            Ueq = i_Comp.rv_Uequilibrium;
            PQG = PQG + i_Comp.f_PQ2Bus(X_Comp,V_Bus,Ueq) * ~isLoad;
            PQC = PQC + i_Comp.f_PQ2Bus(X_Comp,V_Bus,Ueq) * (1 + lambda * or(isLoad, useInt));

            if ~isempty(X_Comp)
                Fdx       = i_Comp.f_dx([],X_Comp,[V_Bus(1)*cos(V_Bus(2));V_Bus(1)*sin(V_Bus(2))],[],Ueq);
                Fdx(1)    = PQG(1)-real(compSeq);
                f_Comp{j} = Fdx;
            end
        end

        func{i} = [ [real(PQ(i));imag(PQ(i))] - PQC; f_Comp{:} ];
    end

    func = w.rm_BusRM * vertcat(func{:});
end
