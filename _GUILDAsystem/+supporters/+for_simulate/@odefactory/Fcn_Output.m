function out = Fcn_Output(obj,t,x,flag)

    obj.progress.OutputFcn(t,x,flag);

    out = [];
end