function func = get_PFeq_Bus(obj,x,Ymat)
    net = obj.CPFNet;
    bus = net.a_Bus;

    lambda = x(end);            
    x = obj.rm_BusEM * x(1:end-1) + obj.CONSTANT;                        
    
    V = x(1:2:end) .* exp(1j * x(2:2:end));
    I = Ymat * V;

    PQ = V .* conj(I);

    nbus = numel(bus); 
    func = cell(nbus,1);                                          
    for i=1:nbus                

        Veq = bus{i}.c_Vequilibrium;
        Ieq = bus{i}.c_Iequilibrium;
        Peq = real(Veq*conj(Ieq));
        Qeq = imag(Veq*conj(Ieq));

        isLambda = ismember(bus{i}.str_tag,obj.CPFBus);
                        
        func{i} = [real(PQ(i));imag(PQ(i))] - [Peq;Qeq] * (1 + lambda * isLambda);                        
    end

    func = obj.rm_BusRM * vertcat(func{:});            
end                 