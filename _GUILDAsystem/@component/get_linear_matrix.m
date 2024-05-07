function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj,Vst,Ist,xst,ust)
        
    %%% 引数の補完 %%%
    if nargin < 3
        % use properties
        Vst = obj.V_st;
        Ist = obj.I_st;
        xst = obj.x_equilibrium;
        ust = obj.u_equilibrium;
    else
        % check form of Vst and Ist
        if isscalar(Vst)
            Vst = tools.complex2vec(Vst);
        elseif numel(Vst) ~= 2 || any(~isreal(Vst))
            error('The type of the specified Vst is incorrect')
        end
        if isscalar(Ist)
            Ist = tools.complex2vec(Ist);
        elseif numel(Ist) ~= 2 || any(~isreal(Ist))
            error('The type of the specified Ist is incorrect')
        end

        if nargin<5
            % calculate xst/ust from Vst/Ist
            [xst,ust] = obj.set_equilibrium(Vst,Ist);
        else
            % check form of xst/ust
            if numel(xst) ~= obj.get_nx
                error('The size of the specified x_st does not match the state')
            end
            if numel(ust) ~= obj.get_nu
                error('The size of the specified u_st does not match the state')
            end
        end
    end
    
    %%% 時変システムでないかの検査 %%%
    t_dx = @(t) obj.get_dx_constraint(t,1.01*xst,1.01*Vst,1.01*Ist,ust);
    [dx0,con0] = t_dx(0);
    [dx100,con100] = t_dx(100);
    if ~ ( all((dx0-dx100)<1e-4) && all((con0-con100)<1e-4) )
        warning('時変システムであるようです. t=0において近似線形化を実行します.')
    end
        
    M = diag(obj.Mass);

    % xに関しての近似線形モデル
    [A,C]   =  split_out(...
        tools.linearization(...
        @(x_) stack_out(@(x_) obj.get_dx_constraint(0, x_, Vst,  Ist,  ust),x_),xst),M);
    
    % Vに関しての近似線形モデル
    [BV,DV] =  split_out(...
        tools.linearization(...
        @(V_) stack_out(@(V_) obj.get_dx_constraint(0, xst, V_,  Ist,  ust),V_),Vst),M);

    % Iに関しての近似線形モデル
    [BI,DI] = split_out(... 
        tools.linearization(...
        @(I_) stack_out(@(I_) obj.get_dx_constraint(0, xst,  Vst, I_,  ust),I_),Ist),M);
    
    % uに関しての近似線形モデル
    [B,D]   =  split_out(...
        tools.linearization(...
        @(u_) stack_out(@(u_) obj.get_dx_constraint(0, xst,  Vst,  Ist, u_),u_),ust),M);

    R = zeros(obj.get_nx,0);
    S = zeros(0,obj.get_nx);

        function out = stack_out(func,x)
            [dx,con] = func(x);
            out = [dx;-con];
        end
        
        function [dx,con] = split_out(matrix,M)
            x = M~=0;
            dx  = diag(1./M(x)) * matrix(x,:);
            con = matrix(~x,:);
        end
end