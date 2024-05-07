 % 現状のシミュレーション結果をoutとして出力
function [out,obj] = export_out(obj)
    net = obj.network;
    storage = obj.DataStorage;
    organize = @(d) tools.arrayfun(@(i) transpose(horzcat(d{i,:})), (1:size(d,1))' );

    out = struct();
    out.t   = horzcat(storage.t{:}).';
    out.X   = organize(storage.X);
    out.V   = organize(storage.V);
    out.I   = organize(storage.I);
    out.Xcon.local  = organize(storage.Xcl);
    out.Xcon.global = organize(storage.Xcg);
    out.Ucon.local  = organize(storage.ucl);
    out.Ucon.global = organize(storage.ucg);
    out.Uinput      = organize(storage.uin);
    out.Utotal      = organize(storage.uall);
    out.sols = storage.sol;

    try
        file = mfilename("fullpath");
        id = load(replace(file,'+supporters/+for_simulate/@odefactory/export_out','_version_support/version_id.mat'));
    catch
        id.ver = 'latest';
    end
    switch id.ver
        case '1'
            out.Xk        = out.Xcon.local;
            out.U         = out.Ucon.local;
            out.Xk_global = out.Xcon.global;
            out.U_global  = out.Ucon.global;
            out.linear      = net.linear;            
            out.fault_bus    = storage.fault_bus;
            out.simulated_bus = storage.simulated_bus;
            out.Ymat_reproduce = storage.Ymat_reproduce;
            out = rmfield(out,{'Ucon','Xcon'});
    
        case {'2','latest'}
            out.options  = obj.export_option;
            out.input    = obj.input.copy;
            out.parallel = obj.parallel.copy;
            out.fault    = obj.fault.copy;

            net.reflected;
            out = supporters.for_simulate.solfactory.DataProcessing(out, net, obj.readme);
    end
end

