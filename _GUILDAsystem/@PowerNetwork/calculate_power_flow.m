function [dataSheet, flag, output] = calculate_power_flow(obj, options)
    arguments
        obj 
        options.MaxIteration (1,1) double  = config.systemFunc.get("PF","MaxIteration","Value")
        options.MaxFunEvals  (1,1) double  = config.systemFunc.get("PF","MaxFunEvals" ,"Value")
        options.UseParallel  (1,1) logical = config.systemFunc.get("PF","Useparallel" ,"Value");
        options.PlotFcn      (1,1) string {mustBeMember(options.PlotFcn,["optimplotx","optimplotfunccount","optimplotfval","optimplotstepsize","optimplotfirstorderopt"])} = config.systemFunc.get("PF","PlotFcn","Value");
        options.Display      (1,1) string {mustBeMember(options.Display,["none","iter","iter-detailed","final","final-detailed"])} = config.systemFunc.get("PF","Display","Value");
        options.warning      (1,1) string {mustBeMember(options.warning,["WARN","DISP","ERROR","OFF"])} = config.systemFunc.get("PF","warning" ,"Value");
        options.dataSheet    (1,1) string {mustBeMember(options.dataSheet,["detailed","simple"])} = "detailed";
    end

    % set options
    if options.PlotFcn=="none"
        options.PlotFcn = [];
    end
    opt = optimoptions('fsolve', ...
                       'MaxFunEvals'  , options.MaxFunEvals,...
                       'MaxIterations', options.MaxIterations, ...
                       'Display'      , options.Display,...
                       'PlotFcn'      , options.PlotFcn,...
                       'UseParallel'  , options.UseParallel);
    % set parameter
    Ymat = obj.get_admittance_matrix();
    [svec_x, rvec_x0, svec_V, svec_P, svec_Q] = tools.cellfun(@(b) b.generate_PF_constraint(), obj.Buses);

    svec_xall  =  vertcvat( svec_x{:} );
    svec_Vall  =  vertcvat( svec_V{:} );
    svec_PQall = [vertcvat( svec_P{:} );...
                  vertcvat( svec_Q{:} )];

    PQfunc = matlabFunction( svec_PQall, "Vars",svec_xall);
    Vfunc  = matlabFunction( svec_Vall , "Vars",svec_xall);

    % solve
    x0 = vertcat(rvec_x0{:});
    [xsol,~,flag,output] = fsolve(@(x) func_eq(Ymat, PQfunc, Vfunc, x), x0, opt);
    
    % format data
    Vvec = Vfunc(xsol);
    Ivec = Ymat*V;
    PQvec = Vvec.*conj(Ivec);
    nbus = numel(obj.Buses);

    dataSheet.Bus(nbus) = struct('Vbus',[],'Ibus',[],'Pcomp',[],'Qcomp',[]);
    for i = 1:nbus
        Prate = obj.Buses{i}.ratePcomp;
        Qrate = obj.Buses{i}.rateQcomp;
        dataSheet.Bus(i).Vbus  = Vvec(i);
        dataSheet.Bus(i).Ibus  = Ivec(i);
        dataSheet.Bus(i).Pbus  = real(PQvec(i));
        dataSheet.Bus(i).Qbus  = imag(PQvec(i));
        dataSheet.Bus(i).Pcomp = real(PQvec(i))/sum(Prate) * Prate;
        dataSheet.Bus(i).Qcomp = imag(PQvec(i))/sum(Qrate) * Qrate;
    end

    if options.dataSheet == "detailed"
        nline = numel(obj.Branches);
        dataSheet.Branch(nline) = struct('Pij',[],'Qij',[],'Iij',[],'traffic',[]);
        Pmat = zeros(nbus,nbus);
        Qmat = zeros(nbus,nbus);
        Imat = zeros(nbus,nbus);
        for i = 1:nbranch
            br   = obj.Branches{i};
            yij  = br.get_admittance_matrix;
            Vij  = Vvec([br.from;br.to]);
            Iij  = yij * Vij;
            PQij = Vij .* conj(Iij);
            Pmax = max(real(PQij));
            dataSheet.Branch(i) = struct('Pij',real(PQij),'Qij',imag(PQij),'Iij',Iij,'traffic',Pmax/br.parameter.Pmax);
            idx  = [br.from,br.to];
            Pmat(idx,idx) = real( [0,PQij(1);PQij(2),0] );
            Qmat(idx,idx) = imag( [0,PQij(1);PQij(2),0] );
            Imat(idx,idx) = [0,Iij(1);Iij(2),0];
        end
        dataSheet.Pmat = Pmat + diag( real(PQvec) - sum(Pmat,2) );
        dataSheet.Qmat = Qmat + diag( imag(PQvec) - sum(Qmat,2) );
        dataSheet.Imat = Imat + diag(       Ivec  - sum(Imat,2) );
    end

    % report solve result
    switch string(options.warning)
        case "WARN";  options.warning = @warning;
        case "ERROR"; options.warning = @error;
        case "DISP";  options.warning = @disp;
        case "OFF";   options.warning = @none; % "none()" function is defined at the bottom
    end
    switch flag
        case 0       
            options.warning(config.lang('潮流計算が解けませんでした。>> 反復回数が options.MaxIterations を超えているか、関数の評価回数が options.MaxFunctionEvaluations を超えています。',...
                                       'Power equation could not be solved. >> The number of iterations exceeds options.MaxIterations or the number of function evaluations exceeds options.MaxFunctionEvaluations.'))
        case {-2,-3}
            options.warning(config.lang('潮流計算が解けませんでした。潮流設定を見直してください。',...
                                       'Power equation could not be solved. Please review the power flow settings'))
    end
end


% Function for fsolve 
function out = func_eq(Ymat, PQfunc, Vfunc, xvec)
    Vvec  = Vfunc(xvec);
    PQvec = Vvec .* conj( Ymat*Vvec );
    out   = PQfunc(xvec) - [real(PQvec);imag(PQvec)];
end

% Dammy Function
function none(varargin)
end