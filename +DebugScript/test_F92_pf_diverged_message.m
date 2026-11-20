% F92 発散した潮流計算のメッセージ
%
%   最大の不平衡量が MethodBase.r_diverged (1e10 pu) を超えるか有限でないとき、flag 0 と -2 の
%   メッセージは大きな数値だけでなく "diverged" と書く。flag の値は変えない。
%
% 実行: runtests("DebugScript.test_F92_pf_diverged_message")  または  DebugScript.run_all("Features","F92")

%% A Newton-Raphson iteration whose mismatch blows up stops with flag -2 and "diverged"
% F = 1e8 x^(1/3): each Newton step doubles |x| and flips its sign, so |F| grows past 1e10
nrm = MethodNewtonRaphson(Fcn=@(x) 1e8*nthroot(x,3), Jac=@(x) 1e8/(3*nthroot(x,3)^2), InitVal=1);
[~, flag, output] = nrm.solve();
assert(flag == -2 && output.iterations > 1 && output.residual > MethodBase.r_diverged)
assert(output.message == sprintf("✘ The process was terminated: the Newton-Raphson iteration diverged (largest mismatch %.3e).", output.residual), output.message)

%% A mismatch that is not finite gives "diverged" without a number
nrm = MethodNewtonRaphson(Fcn=@(x) NaN*x, Jac=@(x) 1, InitVal=1);
[~, flag, output] = nrm.solve();
assert(flag == -2 && output.message == "✘ The process was terminated: the Newton-Raphson iteration diverged.", output.message)

%% MaxIter reached with a blown-up mismatch reads "diverged"; a small mismatch keeps the MaxIterations message
lm = MethodLevenbergMarquardt(Fcn=@(x) 1e12*(x - 1), Jac=@(x) 1e12, InitVal=0, MaxIter=0);
[~, flag, output] = lm.solve();
assert(flag == 0 && output.message == "✘ The Levenberg-Marquardt iteration diverged (largest mismatch 1.000e+12).", output.message)
lm = MethodLevenbergMarquardt(Fcn=@(x) x - 1, Jac=@(x) 1, InitVal=0, MaxIter=0);
[~, flag, output] = lm.solve();
assert(flag == 0 && contains(output.message, "did not converge within MaxIterations"), output.message)

%% The IEEE 9-bus system with 2.5 times the loads diverges in calculate_powerflow
net = network.IEEE9bus();
for k = 1:numel(net.a_Bus)
    for c = 1:numel(net.a_Bus{k}.a_Component)
        tab_c = net.a_Bus{k}.a_Component{c}.tab_parameter.powerflow;
        if ismember("P", tab_c.Properties.VariableNames) && tab_c.P < 0
            net.a_Bus{k}.a_Component{c}.tab_parameter.powerflow{:,["P","Q"]} = 2.5*[tab_c.P, tab_c.Q];
        end
    end
end
w = warning("off"); c_w = onCleanup(@() warning(w));
[res, flag, output] = DebugScript.helper.quiet(@() net.calculate_powerflow(WarmStart=false));
clear c_w
assert(flag == -2 && ~res.l_success && contains(output.message, "Newton-Raphson iteration diverged (largest mismatch"), output.message)
