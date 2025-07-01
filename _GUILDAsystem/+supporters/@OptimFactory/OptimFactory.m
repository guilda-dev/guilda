classdef OptimFactory < handle

    properties(Dependent)
        solver
    end
    properties(SetAccess = protected)
        x       (:,1) sym
        xsub    (:,1) sym
    end
    properties
        H       (:,:) table
        f       (:,1) table
        nonlobj (1,1) table = array2table(sym(0),"VariableNames","obj")
        x0      (:,1) table
        lb      (:,1) table
        ub      (:,1) table
    end
    properties(SetAccess = protected)
        A       (:,:) table
        b       (:,1) table
        Aeq     (:,:) table
        beq     (:,1) table
        nonleq  (:,1) table
        nonlneq (:,1) table
    end
    properties
        Tag     (:,1) string = []
    end

    methods
        function obj = OptimFactory(str_x,str_xsub)
            arguments
                str_x    (:,1) string
                str_xsub (:,1) string
            end
            obj.x    = sym(str_x);
            obj.xsub = sym(str_xsub);
            assume(obj.x,    'real')
            assume(obj.xsub, 'real')

            nx  = obj.nx;
            
            obj.H   =  zeros(nx,nx);
            obj.f   =  zeros(nx, 1);
            obj.Aeq =  zeros( 0,nx);
            obj.beq =  zeros( 0, 1);
            obj.x0  =  zeros(size(str_x));
            obj.lb  = -inf*ones(size(str_x));
            obj.ub  =  inf*ones(size(str_x));
            obj.nonlobj = 0;

            obj.add_eq( zeros(0,nx),zeros(0,1),[],"method","overwrite")
            obj.add_neq(zeros(0,nx),zeros(0,1),[],"method","overwrite")
            obj.add_nonleq( sym(zeros(0,1)),string(zeros(0,1)),"method","overwrite")
            obj.add_nonlneq(sym(zeros(0,1)),string(zeros(0,1)),"method","overwrite")
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%
    %%% OptimFactoryの統合 %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        out = blkdiag(obj,varargin)
    end


    %%%%%%%%%%%
    %%% 求解 %%%
    %%%%%%%%%%%
    methods
        [x,fval,exitflag,output,lambda,grad,hessian] = solve(obj,opt)

        function solType = get.solver(obj)
            % ソルバーの選択
            %=======================================================
            %           nonlobj==0  nonleq==[]  nonlneq==[]  H==0  %
            % linprog      must         must       must      must  % 
            % quadprog     must         must       must       -    %
            % fmincon       -            -          -         -    %
            %=======================================================

            is0 = @(var) isequal(sym(var.Variables),sym(0));
            flag_cond   = [ ~is0(obj.nonlobj)             ;...
                            ~isempty(obj.nonleq )         ;...
                            ~isempty(obj.nonlneq)         ;...
                            ~all(obj.H.Variables==0,"all")];
            flag_solver = [ 1, 1, 1, 1 ;...
                            1, 1, 1, 0 ;... %　上の表に対応
                            0, 0, 0, 0 ] * flag_cond;
            switch find(flag_solver==0,1,"first")
                case 1; solType = "linprog";
                case 2; solType = "quadprog";
                case 3; solType = "fmincon";
            end
        end
    end
    methods(Access=protected)
        [x,fval,exitflag,output,lambda,grad,hessian] = fmincon(obj,option,KeepFiles)
        [x,fval,exitflag,output,lambda] = quadprog(obj,option)
        [x,fval,exitflag,output,lambda] = linprog(obj,option)
    end


    %%%%%%%%%%%%%%%%%%%%
    %%% 制約条件の追加 %%%
    %%%%%%%%%%%%%%%%%%%%
    methods
        add_eq( obj, Aeq, beq,opt)
        add_neq(obj,Aneq,bneq,opt)
        add_nonlneq(obj,cond,opt)
        add_nonleq( obj,cond,opt)
        function set.nonlobj(obj,val); obj.nonlobj.Variables = obj.validsym(val.Variables); end
        function set.x0(obj,val); obj.x0 = obj.validmat(val,           obj.x ,             "x0"); end %#ok
        function set.lb(obj,val); obj.lb = obj.validmat(val,           obj.x ,             "lb"); end %#ok
        function set.ub(obj,val); obj.ub = obj.validmat(val,           obj.x ,             "ub"); end %#ok
        function set.H( obj,val); obj.H  = obj.validmat(val, [obj.x;obj.xsub], [obj.x;obj.xsub]); end %#ok
        function set.f( obj,val); obj.f  = obj.validmat(val, [obj.x;obj.xsub],              "f"); end %#ok
    end

    

    %%%%%%%%%%%%%%%%%%%%%%%
    %%% 内部呼び出し用関数 %%%
    %%%%%%%%%%%%%%%%%%%%%%%
    methods(Access=private)
        function n = nx(obj)
            n = numel([obj.x; obj.xsub]);
        end
        function s = str(obj)
            s = string([obj.x; obj.xsub]);
        end
        function func = validsym(obj,func)
            arguments
                obj 
                func (:,1) sym
            end
            xsym = [obj.x; obj.xsub];
            flag = all(ismember(symvar(func),xsym) );
            assert( flag, config.lang( "制約条件はx,xsubの変数で定式化されている必要があります。",...
                                       "Constraints must be formulated in x,xsub variables."));
        end
        function mat = validmat(~, mat,rvec,cvec)
            arguments
                ~
                mat  (:,:) table
                rvec (:,1) 
                cvec (:,1) 
            end
            mat = mat.Variables;
            assert(size(mat,1)==numel(rvec),config.lang("行数が一致しません。","The number of rows does not match."));
            assert(size(mat,2)==numel(cvec),config.lang("列数が一致しません。","The number of columns does not match."));
            mat = array2table(mat,"RowNames",string(rvec),"VariableNames",string(cvec));
        end
    end
end
