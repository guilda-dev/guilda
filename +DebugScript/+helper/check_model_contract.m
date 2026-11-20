function sv_issue = check_model_contract(obj, opt)
% 機器やコントローラの validate を実行し、契約に反する点を文字列の一覧で返す (空なら問題なし)
%
%   sv_issue = DebugScript.helper.check_model_contract(comp)
%   assert(isempty(sv_issue), "%s", join(sv_issue, newline))
%
% 検査するのは contract の FAIL、点での残差 (dx, I) と Jacobian の差。計算できなかった
% 値 (NaN) も問題として数える。
    arguments (Input)
        obj
        opt.TolResidual (1,1) double = 1e-8
        opt.TolJacobian (1,1) double = 1e-5
    end
    arguments (Output)
        sv_issue  % 契約に反する点の一覧 (空なら問題なし)
    end
    try
        flag = obj.validate(false);
    catch ME
        sv_issue = "validate stopped: " + DebugScript.helper.msg_id(ME) + " " + strtok(ME.message, newline);
        return
    end

    lv = flag.contract.status == "FAIL";
    sv_issue = "contract: " + string(flag.contract.Properties.RowNames(lv)) + " (" + flag.contract.detail(lv) + ")";

    for fn = ["dx","I"]
        sv_issue = [sv_issue; over_tolerance(flag, fn, opt.TolResidual)]; %#ok<AGROW>
    end
    for fn = ["Axx","Bxv","Bxu","Cix","Div","Diu","Cyx","Dyv","Dyu"]
        sv_issue = [sv_issue; over_tolerance(flag, fn, opt.TolJacobian)]; %#ok<AGROW>
    end
end


function str = over_tolerance(flag, fn, tol)
    arguments (Input)
        flag  % validate の結果
        fn    % 調べるフィールド名
        tol   % 許容誤差
    end
    arguments (Output)
        str  % 許容誤差を超えたときの説明 (超えなければ空)
    end
    str = strings(0,1);
    if ~isfield(flag, fn) || isempty(flag.(fn)) || width(flag.(fn)) == 0
        return
    end
    rm = flag.(fn){:,:};
    if any(isnan(rm), "all")
        str = fn + ": NaN";
    elseif max(rm, [], "all") >= tol
        str = fn + ": " + max(rm, [], "all");
    end
end
