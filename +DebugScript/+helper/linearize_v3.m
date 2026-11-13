function sys = linearize_v3(net, NonUnit, Algorithm)
% v3 の SolverLIN (get_sys / get_DAE / get_LTI_viaKron) をそのまま写したもの。v4 の
% net.get_sys / result.get_ss の行列を比べる基準にする (テスト専用)。v3 の Feedback は v4 で
% 廃止したので写さない。
% 変更点は、obj.odeNetwork を net に、bus.l_isNonUnit をこの関数内の配列にしたことだけ
% (母線の l_isNonUnit は書き換えない)。
    arguments (Input)
        net
        NonUnit (1,:) double = []
        Algorithm (1,1) string {mustBeMember(Algorithm, ["Kron","DAE"])} = "Kron"
    end
    arguments (Output)
        sys  % v3 の SolverLIN と同じ線形化モデル
    end
    obj = struct();
    obj.odeNetwork = net;
    lv_nonUnit = false(numel(net.a_Bus),1);
    for i = 1:numel(net.a_Bus)
        lv_nonUnit(i) = ismember(i,NonUnit) || isempty(net.a_Bus{i}.a_Component);
    end
    obj.lv_nonUnit = lv_nonUnit;
    switch Algorithm
        case "Kron"
            sys = get_LTI_viaKron(obj);
        case "DAE"
            sys = get_DAE(obj);
    end
end

function sys = get_DAE(obj,opt)                                     
    arguments (Input)
        obj 
        opt (1,1) string {mustBeMember(opt,["theta&V","theta&rho","Vre&Vim"])} = "theta&rho"%"theta&V"
    end

    arguments (Output)
        sys  % 記述子形式の線形化モデル
    end
    bus = obj.odeNetwork.a_Bus;
    ssFromBus = tools.cellfun(@(bs) v3_ports(bs), bus);    

    [input, output] = get_IO_port;

    Axx = tools.dcellfun(@(SS) SS.A         , ssFromBus);
    Axv = tools.dcellfun(@(SS) SS.B(:,1:2)  , ssFromBus);
    Avx = tools.dcellfun(@(SS) SS.C         , ssFromBus);
    Avv = tools.dcellfun(@(SS) SS.D(:,1:2)  , ssFromBus);
    Bxu = tools.dcellfun(@(SS) SS.B(:,3:end), ssFromBus);
    Bvu = tools.dcellfun(@(SS) SS.D(:,3:end), ssFromBus);

    Y = obj.odeNetwork.get_admittance_matrix;
    Ymat = tools.complex2matrix( Y.Variables );

    x = tools.cellfun(@(s) string(s.StateName),  ssFromBus);        
    % state names come from the bus models, so that controller states are included
    output = vertcat(x{:});

    Ex = tools.dcellfun(@(SS) SS.E, ssFromBus);

    % global controllers (all of them; their states come first)
    [Axx, Axv, Bxu, Avx, Ex, SN] = add_global_controllers(obj.odeNetwork, output, input, Axx, Axv, Bxu, Avx, Bvu, Ex);
    output = [SN; output];

    Ev = zeros(size(Avv));

    n_b = numel(bus);
    n_x = size(Axx,1);
    n_v = size(Avx,1);
    n_u = size(Bxu,2);

    A_temp = [Axx, Axv; -Avx, Ymat - Avv];
    B_temp = [Bxu; Bvu];
    
    A_dae = A_temp([1:n_x,(n_x+1):2:end,(n_x+2):2:end],[1:n_x,(n_x+1):2:end,(n_x+2):2:end]);
    B_dae = B_temp([1:n_x,(n_x+1):2:end,(n_x+2):2:end],:);
    C_dae = [eye(n_x),zeros(n_x,n_v)];
    D_dae = zeros(n_x,n_u);
    E_dae = blkdiag(Ex, Ev);

    ir_x   = 1:n_x;
    ir_Vre = n_x + (1:n_b);
    ir_Vim = n_x + n_b + (1:n_b);

    A_dae = [ A_dae(ir_x  ,:);
             -A_dae(ir_Vim,:);
              A_dae(ir_Vre,:)];
    B_dae = [ B_dae(ir_x  ,:);
             -B_dae(ir_Vim,:);
              B_dae(ir_Vre,:)];

    Vc_st = tools.vcellfun(@(b) b.c_Vequilibrium, bus);
    Ic_st = tools.vcellfun(@(b) b.c_Iequilibrium, bus);
    S_st  = Vc_st .* conj(Ic_st);
    
    rm_P  = diag(real( S_st));
    rm_Q  = diag(imag( S_st));
    rm_Vr = diag(real(Vc_st));
    rm_Vi = diag(imag(Vc_st));
    rm_V  = diag(abs( Vc_st));


    switch opt
        case "theta&V" 
            rm_S = [-rm_Q     , rm_P/rm_V;...
                     rm_P/rm_V, rm_Q     ];

            filt_o = [-    rm_Vi,       rm_Vr ;
                       rm_V\rm_Vr, rm_V\rm_Vi];
            filt_i = [-    rm_Vi,  rm_V\rm_Vr ;
                           rm_Vr,  rm_V\rm_Vi];

            sv_busvar = ["theta";"V"];
        case "theta&rho" 
            rm_S = [-rm_Q, rm_P;...
                     rm_P, rm_Q];

            filt_o = [-rm_Vi,  rm_Vr ; 
                       rm_Vr,  rm_Vi];
            filt_i = [-rm_Vi,  rm_Vr ; 
                       rm_Vr,  rm_Vi];
            
            sv_busvar = ["theta";"rho"];
        case "Vre&Vim"
            rm_S = zeros(n_v, n_v);

            filt_o = eye(n_v);
            filt_i = eye(n_v);

            sv_busvar = ["Vre";"Vim"];
    end

    A_dae = blkdiag(eye(n_x),filt_o)      ...
            * A_dae                       ...
            * blkdiag(eye(n_x),filt_i);
    B_dae = blkdiag(eye(n_x),filt_o)      ...
            * B_dae;

    sv_busvar  = reshape(sv_busvar+(1:n_b),2,[]);
    sv_busvar  = reshape(sv_busvar',1,[]);

    G = real( Y.Variables );
    B = imag( Y.Variables );







    sys = dss(A_dae, B_dae, C_dae, D_dae, E_dae);
    sys.InputName  = input;
    sys.StateName  = [output(:)',sv_busvar];
    sys.OutputName = output;    



    function [input, output] = get_IO_port()
        
        input  = cell(numel(bus),1);
        output = cell(numel(bus),1);
        for argi = 1:numel(bus)
            COMP = bus{argi}.a_Component;
                          
            sv_x = cell2mat( cellfun(@(C) C.attach_tag(C.sv_x), COMP, 'UniformOutput', false) );
            sv_u = cell2mat( cellfun(@(C) C.attach_tag(C.sv_u), COMP, 'UniformOutput', false) );                                                      

            input{argi}  = sv_u;
            output{argi} = sv_x;
        end

        input  = cell2mat(input);
        output = cell2mat(output);
   end

end

function sys = get_LTI_viaKron(obj)                                     
    arguments (Input)
        obj
    end
    arguments (Output)
        sys  % Kron 縮約で求めた線形化モデル
    end

    bus = obj.odeNetwork.a_Bus;
    ssFromBus = tools.cellfun(@(bs) v3_ports(bs), bus);       

    busInames = cell2mat( tools.cellfun(@(bi) bi.attach_tag(["Ire";"Iim"]), bus) );
    busVnames = cell2mat( tools.cellfun(@(bi) bi.attach_tag(["Vre";"Vim"]), bus) );

    x = tools.cellfun(@(s) string(s.StateName),  ssFromBus);
    i = tools.cellfun(@(s) string(s.InputName),  ssFromBus);
    o = tools.cellfun(@(s) string(s.OutputName), ssFromBus);   

    input  = vertcat(i{:});
    output = vertcat(o{:});          
    

    Ax = tools.cellfun(@(SS) SS.A         , ssFromBus);
    Bv = tools.cellfun(@(SS) SS.B(:,1:2)  , ssFromBus);
    Bu = tools.cellfun(@(SS) SS.B(:,3:end), ssFromBus);
    Cx = tools.cellfun(@(SS) SS.C         , ssFromBus);
    Dv = tools.cellfun(@(SS) SS.D(:,1:2)  , ssFromBus);
    Du = tools.cellfun(@(SS) SS.D(:,3:end), ssFromBus);

    E = tools.cellfun(@(SS) SS.E, ssFromBus);

    Ymat = obj.odeNetwork.get_admittance_matrix;
    Ymat = tools.complex2matrix( Ymat.Variables );
           
    Ax_dae = blkdiag(Ax{:});    
    Bv_dae = blkdiag(Bv{:}); 
    Bu_dae = blkdiag(Bu{:});
    Cx_dae = blkdiag(Cx{:});
    
    Du_dae = blkdiag(Du{:});
    E_dae  = blkdiag(E{:});

    % global controllers (all of them; their states come first)
    sv_u = tools.cellfun(@(s) s(3:end), i);    % component inputs (the columns of Bu)
    [Ax_dae, Bv_dae, Bu_dae, Cx_dae, E_dae, SN] = add_global_controllers( ...
        obj.odeNetwork, vertcat(x{:}), vertcat(sv_u{:}), Ax_dae, Bv_dae, Bu_dae, Cx_dae, Du_dae, E_dae);
    
    lv_input  = ismember(input, busVnames);
    lv_output = ismember(output,busInames);

    Dv_dae = blkdiag(Dv{:}) - Ymat;
    
    mat_v2x = Bv_dae / Dv_dae;
    
    n_x = size(Ax_dae,1); 
    n_u = size(Bu_dae,2);

    Ax_ode = Ax_dae - mat_v2x * Cx_dae;
    Bx_ode = Bu_dae - mat_v2x * Du_dae;
    Cx_ode = eye(n_x);
    Dx_ode = zeros(n_x,n_u);
    E_ode  = E_dae;


    sys = dss(Ax_ode, Bx_ode, Cx_ode, Dx_ode, E_ode);
    sys.InputName  = input(~lv_input);
    sys.StateName  = [SN;vertcat(x{:})];
    sys.OutputName = output(~lv_output);    



end

function sys = gc_v3_ports(gc, sv_x)
% v4 の制御器の線形モデルを v3 の入出力にそろえる。v4 の入出力は自分の uc・yc の Label なので、
% 接続表で入力を観測する源の名前に、出力を駆動する入力ごとの行 (先の名前) にする。v3 の制御器は
% 電圧を読まず状態を読んだので、母線電圧の入力を除き、機器の出力 "Y_" + 状態名の入力を状態名に戻す
    arguments (Input)
        gc    % グローバル制御器
        sv_x  % 状態の名前
    end
    arguments (Output)
        sys  % v3 と同じ入力の線形モデル (ss)
    end
    sys  = gc.get_sys("Format", "ss");
    [~, ~, ~, tab_c] = gc.a_PowerNetwork.get_variable_map();
    lv_V = startsWith(string(sys.InputName), ["Vre_","Vim_"]);
    assert(~any(sys.B(:,lv_V), "all") && ~any(sys.D(:,lv_V), "all"), ...
           "The global controller '%s' reads bus voltages, which v3 cannot compare.", gc.s_tag)
    sys  = sys(:, ~lv_V);
    sv_w = string(sys.InputName);
    tab_o = tab_c(tab_c.Kind == "observe", :);
    [lv_o, iv_o] = ismember(sv_w, tab_o.Target);
    sv_w(lv_o) = tab_o.Source(iv_o(lv_o));
    tab_g = tab_c(tab_c.Kind == "global" & ismember(tab_c.Source, string(sys.OutputName)), :);
    [~, iv_ord] = sort(tab_g.SourceIndex);
    tab_g = tab_g(iv_ord, :);
    [~, iv_y] = ismember(tab_g.Source, string(sys.OutputName));
    sys  = sys(iv_y, :);
    sys.OutputName = cellstr(tab_g.Target);
    lv_Y = startsWith(sv_w, "Y_") & ismember(extractAfter(sv_w, 2), sv_x);
    sv_w(lv_Y) = extractAfter(sv_w(lv_Y), 2);
    sys.InputName = cellstr(sv_w);
end

function [Axx, Bxv, Bxu, Cix, E, sv_z] = add_global_controllers(net, sv_x, sv_u, Axx, Bxv, Bxu, Cix, Diu, E)
% Add the global controllers of net to the linear model of the components (used by Kron and DAE)
%
%   E dx/dt = Axx x + Bxv v + Bxu u,   i = Cix x + ... + Diu u
%   x: component states (names sv_x), u: component inputs (names sv_u)
%
% Global controller k:  E_k dz_k/dt = A_k z_k + B_k w_k,  y_k = C_k z_k + D_k w_k
%   its inputs w_k are component states (InputName in sv_x): w_k = S_k x
%   its outputs y_k add to component inputs (OutputName in sv_u): u <- u + T_k y_k
%
% The states z of all controllers are put before x, in the order of a_GlobalController.
% The returned matrices are for [z; x]; Bxu keeps the external input u. sv_z: names of z.
    arguments (Input)
        net    % Power network.
        sv_x   % Names of the component states x.
        sv_u   % Names of the component inputs u.
        Axx    % Jacobian of the states with respect to x.
        Bxv    % Jacobian of the states with respect to V.
        Bxu    % Jacobian of the states with respect to u.
        Cix    % Jacobian of the bus currents with respect to x.
        Diu    % Jacobian of the bus currents with respect to u.
        E      % Mass matrix of x.
    end
    arguments (Output)
        Axx    % Jacobian of the states with respect to [z; x].
        Bxv    % Jacobian of the states [z; x] with respect to V.
        Bxu    % Jacobian of the states [z; x] with respect to u.
        Cix    % Jacobian of the bus currents with respect to [z; x].
        E      % Mass matrix of [z; x].
        sv_z   % Names of the controller states z.
    end
    a_GC  = net.a_GlobalController;
    sv_z  = string.empty(0,1);
    if isempty(a_GC)
        return
    end
    nx = size(Axx,1);
    nv = size(Bxv,2);
    nu = size(Bxu,2);

    Az    = cell(numel(a_GC),1);
    Bzx   = cell(numel(a_GC),1);
    Cuz   = cell(1,numel(a_GC));
    Ez    = cell(numel(a_GC),1);
    sv_z  = cell(numel(a_GC),1);  % (cell while collecting)
    Dux   = zeros(nu,nx);
    for k = 1:numel(a_GC)
        sysGC = gc_v3_ports(a_GC{k}, sv_x);
        [lv_w, iw] = ismember(string(sysGC.InputName),  sv_x);
        [lv_y, iy] = ismember(string(sysGC.OutputName), sv_u);
        if ~all(lv_w) || ~all(lv_y)
            error("GUILDA:SolverLIN:GlobalControllerPort", ...
                  "The ports of the global controller '%s' are not found in the linearized system.", a_GC{k}.s_tag)
        end
        S = zeros(numel(iw), nx);  S(sub2ind(size(S), 1:numel(iw), iw(:)')) = 1;
        T = zeros(nu, numel(iy));  T(sub2ind(size(T), iy(:)', 1:numel(iy))) = 1;

        Az{k}    = sysGC.A;
        Bzx{k}   = sysGC.B * S;
        Cuz{k}   = T * sysGC.C;
        Dux      = Dux + T * sysGC.D * S;
        Ez{k}    = sysGC.E;
        sv_z{k} = string(sysGC.StateName);
    end
    Az    = blkdiag(Az{:});
    Bzx   = vertcat(Bzx{:});
    Cuz   = horzcat(Cuz{:});
    sv_z  = [string.empty(0,1); vertcat(sv_z{:})];
    nz    = size(Az,1);

    Axx = [Az, Bzx; Bxu*Cuz, Axx + Bxu*Dux];
    Bxv = [zeros(nz,nv); Bxv];
    Bxu = [zeros(nz,nu); Bxu];
    Cix = [Diu*Cuz, Cix + Diu*Dux];
    E   = blkdiag(Ez{:}, E);
end

function sys = v3_ports(bus)
% v4 の bus.get_sys には制御器の入出力と機器の出力があるので、v3 と同じ入力
% [ポート; 機器の入力 u] と出力 (電流 I) だけにする
    arguments (Input)
        bus
    end
    arguments (Output)
        sys  % v3 と同じ入出力の母線モデル
    end
    sys  = bus.get_sys(Format="ss");
    sv_u = tools.cellfun(@(c) string(c.attach_tag(c.sv_u)), bus.a_Component);
    [~, iv_u] = ismember(vertcat(strings(0,1), sv_u{:}), string(sys.InputName));
    sys  = sys(1:2, [1, 2, reshape(iv_u, 1, [])]);
end
