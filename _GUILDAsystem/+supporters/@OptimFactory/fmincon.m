function [x,fval,exitflag,output,lambda,grad,hessian] = fmincon(obj, option, KeepFiles)
    x   = obj.x;
    H   = obj.H.Variables;
    f   = obj.f.Variables;
    A   = obj.A.Variables;
    b   = obj.b.Variables;
    Aeq = obj.Aeq.Variables;
    beq = obj.beq.Variables;
    lb  = obj.lb.Variables;
    ub  = obj.ub.Variables;
    x0  = obj.x0.Variables;

    fun     = simplify( obj.nonlobj.Variables + x.'*H*x + f.'*x);
    nonleq  = simplify( obj.nonlneq.Variables);
    nonlneq = simplify( obj.nonleq.Variables);

    date = string(datetime("now","Format","uuuuMMddHHmmss"));
    file = fullfile("_CodegenScript","OptimFactory"+date);

    Comment = [" OptimFactory @"+date; " Nonlinear Objective Function"; ""; obj.Tag];
    nonlfun = matlabFunction(fun,"File",file+"obj","Optimize",true,"Vars",{x},"Comments",Comment,"Outputs",{'objVal'});
    
    Comment = [" OptimFactory @"+date; " Nonlinear Constraint Function"; ""; obj.Tag];
    nonlcon = matlabFunction(nonlneq,nonleq,"File",file+"con","Optimize",true,"Vars",{x},"Comments",Comment,"Outputs",{'c','ceq'});

    [x,fval,exitflag,output,lambda,grad,hessian] = fmincon(nonlfun,x0,A,b,Aeq,beq,lb,ub,nonlcon,option);
    
    if ~KeepFiles
        delete(file+"con.m")
        delete(file+"obj.m")
    end
end