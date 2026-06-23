function func = get_PFeq_GBus(obj,x,Ymat)            
    net = obj.CPFNet;
    bus = net.a_Bus;

    lambda = x(end);            
    x = obj.rm_BusEM * x(1:end-1) + obj.CONSTANT;                        

    V = x(1:3:end) .* exp(1j * x(2:3:end));
    I = Ymat * V;

    delta = x(3:3:end);

    PQ = V .* conj(I);

    nbus = numel(bus); 
    func = cell(nbus,1);                                          
    for i=1:nbus                

        i_Bus = bus{i};

        Veq = i_Bus.c_Vequilibrium;
        Ieq = i_Bus.c_Iequilibrium;
        Peq = real(Veq*conj(Ieq));                

        a_Comp = i_Bus.a_Component{1};                
        Ueq = a_Comp.cv_Uequilibrium;
        PQG = a_Comp.PQ2BusG(delta(i),V(i),Ueq);
        PQL = a_Comp.PQ2BusL(delta(i),V(i),Ueq);

        isLoad  = ismember(i_Bus.str_tag,obj.CPFBus);
        func{i} = [ [real(PQ(i));imag(PQ(i))] - (PQG + PQL * (1 + lambda * isLoad)); PQG(1) - Peq ];                
    end

    func = obj.rm_BusRM * vertcat(func{:});            
end                 