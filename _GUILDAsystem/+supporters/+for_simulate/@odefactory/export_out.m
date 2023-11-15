 % 現状のシミュレーション結果をoutとして出力
function [out,obj] = export_out(obj)
    net = obj.network;
    data = obj.DataStorage;
    
    outdata = struct();
    
    outdata.t = data.t;
    
    outdata.X   = organize(data.X  );
    outdata.V   = organize(data.V  );
    outdata.I   = organize(data.I  );
    
    outdata.Xcon = struct();
    outdata.Xcon.local  = organize(data.Xcl);
    outdata.Xcon.global = organize(data.Xcg);
   
    Umac = tools.cellfun(@(b) zeros(numel(data.t),b.component.get_nu), net.a_bus);

    outdata.Ucon = struct();
    [outdata.Ucon.global, Umac] = calc_Ucon(net.a_controller_global, outdata, Umac, 'global');
    [outdata.Ucon.local , Umac] = calc_Ucon(net.a_controller_local , outdata, Umac, 'local' );

    Uuser = tools.cellfun(@(b) tools.cellfun(@(s) zeros(numel(s.x),b.component.get_nu),data.sol), net.a_bus);
    time  = cell(numel(data.sol),1);
    for  is = 1:numel(data.sol)
        sol  = data.sol{is};
        u    = data.u{is};
        for uid = 1:numel(u)
            ui = u(uid);
            uval = tools.harrayfun(@(t) ui.function(t), sol.x);
            for idx = 1:numel(ui.index)
                Uuser{ui.index(idx)}{is} = Uuser{ui.index(idx)}{is} + uval(ui.logimat(:,idx),:).';
            end
        end
        time{is} = sol.x(:);
    end

    outdata.t      = vertcat(time{:});
    outdata.Uinput = tools.cellfun(@(c) vertcat(c{:}), Uuser);
    outdata.Utotal = tools.arrayfun(@(i) outdata.Uinput{i}+Umac{i}, (1:numel(net.a_bus)).'); 
    outdata.sols   = data.sol;
    outdata.options = obj.export_option;
    outdata.input    = obj.input.copy;
    outdata.parallel = obj.parallel.copy;
    outdata.fault    = obj.fault.copy;

    try 
        id = load('_GUILDAsystem/_version_support/version_id.mat');
        ver = id.ver;
    catch 
        ver = 'latest';
    end

    switch ver
        case '1'
            out = struct(...
                't', outdata.t,...
                'X', outdata.X, ...
                'V', outdata.V, ...
                'I', outdata.I, ...
                'Xk_global', outdata.Xcon.global,...
                'U_global',  outdata.Ucon.global,...
                'Xk',        outdata.Xcon.local ,...
                'U',         outdata.Ucon.local ,...
                'simulated_bus', [],...
                'fault_bus', [],...
                'Ymat_reproduce', [],...
                'sols', [],...
                'linear',[]);                        % 編集途中
        case {'2','latest'}
            out = supporters.for_simulate.solfactory.DataProcessing(outdata, net, obj.readme);
    end
    
end

function out = organize(mat_data)
    n = size(mat_data, 1);
    out = cell(n,1);
    for i = 1:n
        out{i} = transpose(horzcat(mat_data{i,:}));
    end
end

function [ucon, uall] = calc_Ucon(a_con, outdata, umac, type)
    ucon = cell(numel(a_con),1);
    uall = umac;
    for i = 1:numel(a_con)
        c = a_con{i};
        in = c.index_input;
        ob = c.index_observe;
        u  = c.get_input_vectorized(       ...
                    outdata.t             ,...
                    outdata.Xcon.(type){i},...
                    outdata.X(ob)         ,...
                    outdata.V(ob)         ,...
                    outdata.I(ob)         ,...
                    umac(ob)          );
        for j = 1:numel(in)
           uall{in(j)} = uall{in(j)} + u{j};
        end
        ucon{i} = horzcat(u{:});
    end
end
