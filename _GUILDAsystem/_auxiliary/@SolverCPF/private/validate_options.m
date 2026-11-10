function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments (Input)
        opt.LoadBus          {mustBeText}
        opt.MaxIteration     (1,1) double  {mustBePositive,mustBeInteger}
        opt.Tolerance        (1,1) double  {mustBePositive}
        opt.StepSize         (1,1) double  {mustBePositive}
        opt.ArcLength        (1,1) double  {mustBePositive}
        opt.InitialLambda    (1,1) double
        opt.UseInternalState (1,1) logical
        opt.Verbose          (1,1) logical
        opt.Limits           {mustBeLimits}
        opt.PlotFcn                        % checked by tools.check_plotfcn
    end
end


function mustBeLimits(sv)
% Limits: distinct members of "Q", "V", "S", or "all" / "none" alone
    l_ok = (isstring(sv) || ischar(sv) || iscellstr(sv)) && ~isempty(sv);
    if l_ok
        sv = reshape(string(sv), 1, []);
        l_ok = all(ismember(sv, ["Q","V","S"])) && numel(unique(sv)) == numel(sv) ...
               || isscalar(sv) && ismember(sv, ["all","none"]);
    end
    if ~l_ok
        error(msg("GUILDA:SolverCPF:InvalidLimits"));
    end
end
