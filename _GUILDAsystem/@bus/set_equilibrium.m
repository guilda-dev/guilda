function set_equilibrium(obj,data)
    arguments
        obj 
        data.Vbus  (1,1) double = obj.V_equilibrium;
        data.Ibus  (1,1) double = obj.I_equilibrium;
        data.Pcomp (1,:) double = real( obj.I_equilibrium * conj( obj.I_equilibrium ))/sum(obj.ratePcomp) * obj.ratePcomp;
        data.Qcomp (1,:) double = imag( obj.V_equilibrium * conj( obj.I_equilibrium ))/sum(obj.rateQcomp) * obj.rateQcomp;
    end
    obj.V_equilibrium = data.Vbus;
    obj.I_equilibrium = data.Ibus;

    wst = obj.w_equilibrium .* [obj.ratePcomp,obj.rateQcomp].';
    vst = obj.v_equilibrium;

    PQmat = [data.Pcomp;data.Qcomp];
    valid = wst - sum(PQmat,2);
    assert(norm(valid)<1e-5,config.lang("Pcomp,QcompのデータとVeq,Ieqの整合が取れません。","Pcomp,Qcomp data does not match Veq,Ieq."))

    arrrayfun(@(i) obj.Components{i}.set_equilibrium( vst, PQmat(:,i) ), 1:numel(obj.Components))
    obj.onEdit("set equilibrium");
end