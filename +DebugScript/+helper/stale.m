function sv = stale(obj)
% 層とその下の層の古さのメッセージ (sct_stale の全フィールド) を集める。
% LayerPackage.check_edit と同じく、関数ハンドルを作った周波数が系統の周波数と違う
% 機器・制御器には "network frequency changed" を加える。
%
%   sv = DebugScript.helper.stale(net)     % 系統全体 (母線・機器・制御器・大域制御器)
%   sv = DebugScript.helper.stale(bus)     % 母線の機器とその制御器
%   sv = DebugScript.helper.stale(comp)    % 機器とその制御器 (制御器ならその下)
    arguments (Input)
        obj
    end
    arguments (Output)
        sv (:,1) string  % メッセージ (重複を除く、空なら最新)
    end
    if isa(obj, "PowerNetwork")
        sv = fields(obj);
        for i = 1:numel(obj.a_Bus)
            sv = [sv; of_bus(obj.a_Bus{i})]; %#ok<AGROW>
        end
        for k = 1:numel(obj.a_GlobalController)
            sv = [sv; model(obj.a_GlobalController{k})]; %#ok<AGROW>
        end
    elseif isa(obj, "Bus")
        sv = of_bus(obj);
    elseif isa(obj, "Component") || isa(obj, "LocalController") || isa(obj, "GlobalController")
        sv = model(obj);
    else
        sv = fields(obj);
    end
    sv = unique(sv, "stable");
end

function sv = of_bus(bus)
    sv = strings(0,1);
    for j = 1:numel(bus.a_Component)
        sv = [sv; model(bus.a_Component{j})]; %#ok<AGROW>
    end
end

function sv = fields(obj)
    c  = struct2cell(obj.sct_stale);
    sv = vertcat(strings(0,1), c{:});
end

function sv = model(obj)
    sv = fields(obj);
    if isempty(obj.sct_stale.odefcn) && ~isempty(obj.r_odefcnHz) && obj.r_odefcnHz ~= obj.get_Hz()
        sv(end+1,1) = "network frequency changed";
    end
    if isprop(obj, "a_LocalController")
        for k = 1:numel(obj.a_LocalController)
            sv = [sv; model(obj.a_LocalController{k})]; %#ok<AGROW>
        end
    end
end
