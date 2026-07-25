function flag = validate(obj, l_message)
    arguments
        obj 
        l_message (1,1) logical = true
    end


    if obj.str_editFlag == "unset"
        rv_V = rand(2,1);
        rv_I = rand(2,1);
        c_V  = [1,1j]*( rv_V/norm(rv_V) );
        c_I  = [1,1j]*( rv_V/norm(rv_I) );
        [rv_x,rv_u] = obj.get_equilibrium(c_V,c_I);
    else
        c_V = obj.c_Vequilibrium;
        c_I = obj.c_Iequilibrium;
        rv_V = [real(c_V); imag(c_V)];
        rv_I = [real(c_I); imag(c_I)];
        rv_x = obj.rv_Xequilibrium;
        rv_u = obj.rv_Uequilibrium;
    end

    
    r_omega0 = 2*pi*60;
    r_t      = 0;
    rr_param = obj.para_dynamics.tab_parameter{:,obj.sv_para};
    
    % make variable
    sv_x  = obj.sv_x;
    sv_u  = obj.sv_u;
    sv_y  = obj.sv_y;
    sv_i  = ["Ire"; "Iim"];
    sv_v  = ["Vre"; "Vim"];
    nx = numel(sv_x);
    nu = numel(sv_u);
    ny = numel(sv_y);


    com2vec = @(c) [real(c);imag(c)];

    % validate dx=0 and I=Ist at the equilibrium point
    dx_test = reshape( obj.fcn_dx(r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0), nx, 1);
    I_test  = com2vec( obj.fcn_I( r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0) ) -rv_I;

    % make flag
    mktab = @(flag,r,v) array2table(flag,"RowNames",r,"VariableNames",v);
    flag = struct( ...
        "dx" , mktab(      abs(dx_test)      ,  sv_x, "diff" ),...
        "I"  , mktab(      abs( I_test)      ,  sv_i, "diff" )...
        );

    % validate linearized matrix
    if ismethod(obj,"Jacobi_dx")
        [Axx_test , Bxv_test , Bxi_test , Bxu_test ] = Jacobi_dx_num(obj,r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
        [Axx_valid, Bxv_valid, Bxi_valid, Bxu_valid] = obj.Jacobi_dx(r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
        Axx_valid = reshape( Axx_valid, nx, nx);
        Bxv_valid = reshape( Bxv_valid, nx,  2);
        Bxi_valid = reshape( Bxi_valid, nx,  2);
        Bxu_valid = reshape( Bxu_valid, nx, nu);

        flag.Axx = mktab( abs(Axx_test-reshape(Axx_valid, nx, nx)), sv_x, sv_x);
        flag.Bxv = mktab( abs(Bxv_test-reshape(Bxv_valid, nx,  2)), sv_x, sv_v);
        flag.Bxi = mktab( abs(Bxi_test-reshape(Bxi_valid, nx,  2)), sv_x, sv_v);
        flag.Bxu = mktab( abs(Bxu_test-reshape(Bxu_valid, nx, nu)), sv_x, sv_u);
    end
    if ismethod(obj,"Jacobi_I")
        [Cix_test, Div_test, Dii_test, Diu_test] = Jacobi_I_num( obj,r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
        [Cix_valid, Div_valid, Dii_valid, Diu_valid] = obj.Jacobi_I( r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
        flag.Cix = mktab( abs(Cix_test-reshape(Cix_valid,  2, nx)), sv_i, sv_x);
        flag.Div = mktab( abs(Div_test-reshape(Div_valid,  2,  2)), sv_i, sv_v);
        flag.Dii = mktab( abs(Dii_test-reshape(Dii_valid,  2,  2)), sv_i, sv_v);
        flag.Diu = mktab( abs(Diu_test-reshape(Diu_valid,  2, nu)), sv_i, sv_u);
    end
    if ismethod(obj,"Jacobi_Y")
        [Cyx_test , Dyv_test , Dyi_test , Dyu_test ] = Jacobi_Y_num( obj,r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
        [Cyx_valid, Dyv_valid, Dyi_valid, Dyu_valid] = obj.Jacobi_Y( r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0);
        flag.Cyx = mktab( abs(Cyx_test-reshape(Cyx_valid,ny,nx)), sv_y, sv_x);
        flag.Dyv = mktab( abs(Dyv_test-reshape(Dyv_valid,ny, 2)), sv_y, sv_v);
        flag.Dyi = mktab( abs(Dyi_test-reshape(Dyi_valid,ny, 2)), sv_y, sv_v);
        flag.Dyu = mktab( abs(Dyu_test-reshape(Dyu_valid,ny,nu)), sv_y, sv_u);
    end

    % message
    if l_message
        sv_fn = string(fieldnames(flag))';
        disp(repmat('=',1,100))
        for fn = sv_fn
            disp(" ")
            if fn =="dx"
                disp(">> obj.f_dx(0,xst,Vst,ust)"+newline)
            elseif fn == "I"
                disp(">> Ist - obj.f_I(0,xst,Vst,ust)"+newline)
            elseif ismember(fn ,["Axx","Bxu","Bxv"])
                disp(">> obj.Jacobi"+fn+"(0,xst,Vst,ust) - (Numerical differentiation @obj.f_dx)"+newline)
            elseif ismember(fn ,["Cix","Diu","Div"])
                disp(">> obj.Jacobi"+fn+"(0,xst,Vst,ust) - (Numerical differentiation @obj.f_I)"+newline)
            elseif ismember(fn ,["Cyx","Dyu","Dyv"])
                disp(">> obj.Jacobi"+fn+"(0,xst,Vst,ust) - (Numerical differentiation @obj.f_Y)"+newline)
            end

            if isempty(flag.(fn))
                disp("   No Variables"+newline)
            else
                disp(flag.(fn))
            end
        end
        disp(repmat('=',1,100))
    end

end