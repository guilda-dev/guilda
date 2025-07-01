function [Mass,fcn_diff,fcn_jacobi,fcn_output,fcn_const] = get_dae(obj,opt)
    arguments
        obj 
        opt.ExportDiffFcn   (1,1) logical = false;
        opt.ExportOutputFcn (1,1) logical = false;
        opt.ExportConstFcn  (1,1) logical = false;
        opt.ExportDirName   (1,1) string  = "+DAE"+string(datetime('now','Format','uuuuMMdd_HHmmss'));
    end
    Mass = obj.Mass;

    usym  = obj.u;
    uzero = zeros(size(usym));

    fv_diffFcn  = subs( obj.eq_diff  , usym, uzero);
    fv_outFcn   = subs( obj.eq_output, usym, uzero);
    fv_constFcn = subs( obj.eq_input , usym, uzero);
    fm_jacobian = jacobian(fv_diffFcn, obj.x);

    mopt  = { "Optimize", true, "Comment", obj.Comment , "Vars", {sym("Time"),obj.x} };
    Gpath = fullfile(config.pwd,"_CodegenScript",opt.ExportDirName);
    fname = @(s) fullfile(Gpath,s);
    if opt.ExportDiffFcn
        fcn_diff   = matlabFunction( fv_diffFcn,  "File", fname("diff.m"    ), mopt{:});
        fcn_jacobi = matlabFunction( fm_jacobian, "File", fname("jacobian.m"), mopt{:});
    else
        fcn_diff   = matlabFunction( fv_diffFcn,  mopt{:});
        fcn_jacobi = matlabFunction( fm_jacobian, mopt{:});
    end
    if opt.ExportOutputFcn
        fcn_output = matlabFunction( fv_outFcn, "File", fname("output.m"), mopt{:});
    else
        fcn_output = matlabFunction( fv_outFcn, mopt{:});
    end
    if opt.ExportConstFcn
        fcn_const = matlabFunction( fv_constFcn, "File", fname("const.m"), mopt{:});
    else
        fcn_const = matlabFunction( fv_constFcn, mopt{:});
    end
end

%{
        time          (1,2) double
        opt.x0sys     (:,1) double     = obj.x0;
        opt.TimeLimit (1,1) double     = inf;    
        opt.notify    (1,1) logical    = false;  
        opt.OutputFcn (1,1) function_handle = []; 
        opt.report    (1,1) string {mustBeMember(opt.report,["none","dialog","disp"])} = "disp"; 
        opt.checkConst(1,1) string {mustBeMember(opt.checkConst,["ignore","observe","controlParallel","stopSimulate"])} = "ignore";
%}      