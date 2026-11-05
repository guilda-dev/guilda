classdef OutputStub < DebugScript.helper.ObserveStub
% 任意の key と出力名を持つ制御器 (Component.add_local_controller の検査を確かめるため)
%
%   con = DebugScript.helper.OutputStub("governor", "Pmech")
    methods
        function obj = OutputStub(key, sv_y)
            arguments (Input)
                key   % 制御器の種類 ("avr", "governor" など)
                sv_y  % 出力名
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@DebugScript.helper.ObserveStub(strings(0,1))
            obj.key  = key;
            obj.sv_y = reshape(string(sv_y), [], 1);
        end
    end
end
