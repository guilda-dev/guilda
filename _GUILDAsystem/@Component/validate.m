function flag = validate(obj, l_message)
    arguments
        obj 
        l_message (1,1) logical = true
    end


    if obj.str_editFlag == "unset"
        rv_V = rand(2,1);
        rv_I = rand(2,1);
        c_V = [1,1j]*( rv_V/norm(rv_V) );
        c_I = [1,1j]*( rv_V/norm(rv_I) );
        obj.set_equilibrium(c_V,c_I)
    else
        c_V = obj.c_Vequilibrium;
        c_I = obj.c_Iequilibrium;
    end

    rv_X = obj.cv_Xequilibrium;
    rv_U = obj.cv_Uequilibrium;
    rv_V = [real(c_V); imag(c_V)];
    rv_I = [real(c_I); imag(c_I)];
    
    time  = 0;
    delta = 1e-5;

    fcn_dx = @(x,v,i,u) obj.fv_odeDiff(time, x, v, i, u);
    fcn_I  = @(x,v,i,u) obj.fv_odeI(   time, x, v, i, u);
    fcn_Y  = @(x,v,i,u) obj.fv_odeY(   time, x, v, i, u);


    % make variable
    sv_x  = obj.str_x;
    sv_u  = obj.str_u;
    sv_y  = obj.str_y;
    sv_i  = ["Ire"; "Iim"];
    sv_v  = ["Vre"; "Vim"];
    nx = numel(sv_x);
    nu = numel(sv_u);
    ny = numel(sv_y);

    % make function
    e = @(i,n) delta/2 * ((1:n)==i).';
    v = @(c)   [real(c); imag(c)];

    % validate dx=0 and I=Ist at the equilibrium point
    dx_test = reshape(          fcn_dx(rv_X,rv_V,rv_I,rv_U), nx, 1);
    I_test  = reshape( v(fcn_I( rv_X,rv_V,rv_I,rv_U) - c_I),  2, 1);

    % get linearized matrix numerically
    Axx_test = reshape(    tools.harrayfun(@(i) fcn_dx(rv_X + e(i,nx), rv_V, rv_I, rv_U) - fcn_dx(rv_X - e(i,nx), rv_V, rv_I, rv_U), 1:nx) / delta , nx, nx);
    Bxv_test = reshape(    tools.harrayfun(@(i) fcn_dx(rv_X, rv_V + e(i, 2), rv_I, rv_U) - fcn_dx(rv_X, rv_V - e(i, 2), rv_I, rv_U), 1: 2) / delta , nx,  2);
    Bxu_test = reshape(    tools.harrayfun(@(i) fcn_dx(rv_X, rv_V, rv_I, rv_U + e(i,nu)) - fcn_dx(rv_X, rv_V, rv_I, rv_U - e(i,nu)), 1:nu) / delta , nx, nu);
    Cix_test = reshape( v( tools.harrayfun(@(i) fcn_I( rv_X + e(i,nx), rv_V, rv_I, rv_U) - fcn_I( rv_X - e(i,nx), rv_V, rv_I, rv_U), 1:nx) / delta),  2, nx);
    Div_test = reshape( v( tools.harrayfun(@(i) fcn_I( rv_X, rv_V + e(i, 2), rv_I, rv_U) - fcn_I( rv_X, rv_V - e(i, 2), rv_I, rv_U), 1: 2) / delta),  2,  2);
    Diu_test = reshape( v( tools.harrayfun(@(i) fcn_I( rv_X, rv_V, rv_I, rv_U + e(i,nu)) - fcn_I( rv_X, rv_V, rv_I, rv_U - e(i,nu)), 1:nu) / delta),  2, nu);
    Cyx_test = reshape(    tools.harrayfun(@(i) fcn_Y( rv_X + e(i,nx), rv_V, rv_I, rv_U) - fcn_Y( rv_X - e(i,nx), rv_V, rv_I, rv_U), 1:nx) / delta , ny, nx);
    Dyv_test = reshape(    tools.harrayfun(@(i) fcn_Y( rv_X, rv_V + e(i, 2), rv_I, rv_U) - fcn_Y( rv_X, rv_V - e(i, 2), rv_I, rv_U), 1: 2) / delta , ny,  2);
    Dyu_test = reshape(    tools.harrayfun(@(i) fcn_Y( rv_X, rv_V, rv_I, rv_U + e(i,nu)) - fcn_Y( rv_X, rv_V, rv_I, rv_U - e(i,nu)), 1:nu) / delta , ny, nu);
    
    % get linearized matrix using methods
    Axx_valid = reshape( obj.JacobiAxx(time, rv_X, rv_V, rv_I, rv_U), nx, nx);
    Bxv_valid = reshape( obj.JacobiBxv(time, rv_X, rv_V, rv_I, rv_U), nx,  2);
    Bxu_valid = reshape( obj.JacobiBxu(time, rv_X, rv_V, rv_I, rv_U), nx, nu);
    Cix_valid = reshape( obj.JacobiCix(time, rv_X, rv_V, rv_I, rv_U),  2, nx);
    Div_valid = reshape( obj.JacobiDiv(time, rv_X, rv_V, rv_I, rv_U),  2,  2);
    Diu_valid = reshape( obj.JacobiDiu(time, rv_X, rv_V, rv_I, rv_U),  2, nu);
    Cyx_valid = reshape( obj.JacobiCyx(time, rv_X, rv_V, rv_I, rv_U), ny, nx);
    Dyv_valid = reshape( obj.JacobiDyv(time, rv_X, rv_V, rv_I, rv_U), ny,  2);
    Dyu_valid = reshape( obj.JacobiDyu(time, rv_X, rv_V, rv_I, rv_U), ny, nu);


    % make flag
    mktab = @(flag,r,v) array2table(flag,"RowNames",r,"VariableNames",v);
    flag = struct( ...
            "dx" , mktab(      abs(dx_test)      ,  sv_x, "diff" ),...
            "I"  , mktab(      abs( I_test)      ,  sv_i, "diff" ),...
            "Axx", mktab( abs(Axx_test-Axx_valid), sv_x, sv_x), ...
            "Bxu", mktab( abs(Bxu_test-Bxu_valid), sv_x, sv_u), ...
            "Bxv", mktab( abs(Bxv_test-Bxv_valid), sv_x, sv_v), ...
            "Cix", mktab( abs(Cix_test-Cix_valid), sv_i, sv_x), ...
            "Cyx", mktab( abs(Cyx_test-Cyx_valid), sv_y, sv_x), ...
            "Diu", mktab( abs(Diu_test-Diu_valid), sv_i, sv_u), ...
            "Div", mktab( abs(Div_test-Div_valid), sv_i, sv_v), ...
            "Dyu", mktab( abs(Dyu_test-Dyu_valid), sv_y, sv_u), ...
            "Dyv", mktab( abs(Dyv_test-Dyv_valid), sv_y, sv_v)  ...
            );

    % message
    if l_message
        sv_fn = string(fieldnames(flag))';
        disp(repmat('=',1,100))
        for fn = sv_fn
            disp(" ")
            if fn =="dx"
                disp(">> obj.fv_odeDiff(0,xst,Vst,ust)"+newline)
            elseif fn == "I"
                disp(">> Ist - obj.fv_odeI(0,xst,Vst,ust)"+newline)
            elseif ismember(fn ,["Axx","Bxu","Bxv"])
                disp(">> obj.Jacobi"+fn+"(0,xst,Vst,ust) - (Numerical differentiation @obj.fv_odeDiff)"+newline)
            elseif ismember(fn ,["Cix","Diu","Div"])
                disp(">> obj.Jacobi"+fn+"(0,xst,Vst,ust) - (Numerical differentiation @obj.fv_odeI)"+newline)
            elseif ismember(fn ,["Cyx","Dyu","Dyv"])
                disp(">> obj.Jacobi"+fn+"(0,xst,Vst,ust) - (Numerical differentiation @obj.fv_odeY)"+newline)
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