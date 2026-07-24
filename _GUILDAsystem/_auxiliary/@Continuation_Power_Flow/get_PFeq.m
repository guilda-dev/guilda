function func = get_PFeq(obj,x,Ymat)            
    net = obj.CPFNet;
    bus = net.a_Bus;

    lambda = x(end);                
    x = obj.rm_BusEM * x(1:end-1) + obj.CONSTANT;                        

    V = x(obj.rv_BusVi);    
    V = V(1:2:end) .* exp(1j*V(2:2:end));
    I = Ymat * V;    

    PQ = V .* conj(I);

    useInt = obj.CPFUseInternal;

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

            isLoad  = ismember(i_Bus.str_tag,obj.CPFBus);

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

    func = obj.rm_BusRM * vertcat(func{:});            
end                 