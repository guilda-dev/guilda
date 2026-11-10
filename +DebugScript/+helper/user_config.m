function c_restore = user_config(s_section, sct_value)
% GUILDA.setting の 1 セクションをユーザー設定ファイルへ書き、終了時 (c_restore の削除) に元へ戻す
%
%   c = DebugScript.helper.user_config("PowerFlowCalculation", struct("Solver", "dynamic"));
%   ...                % GUILDA.config("PowerFlowCalculation","Solver") == "dynamic"
%   clear c            % 元のファイルに戻して設定を読み直す
    arguments (Input)
        s_section (1,1) string  % セクション (ファイル名の Default と .json を除いた部分)
        sct_value (1,1) struct  % 書くキーと値 (ほかのキーは既定値)。version は既定ファイルのものを付ける
    end
    arguments (Output)
        c_restore  % onCleanup: 元のファイルに戻して設定を読み直す
    end
    s_file = fullfile(GUILDA.pwd, "@GUILDA", "user", "Default" + s_section + ".json");
    if isfile(s_file)
        s_old = string(fileread(s_file));
    else
        s_old = string(missing);
    end
    c_restore = onCleanup(@() restore(s_file, s_old));
    % 既定ファイルと同じ version を書く (違うと get_config が既定値で上書きする)
    sct_def = jsondecode(fileread(fullfile(GUILDA.pwd, "@GUILDA", "config", "Default" + s_section + ".json")));
    if isfield(sct_def, "version")
        sct_value.version = sct_def.version;
    end
    writelines(jsonencode(sct_value), s_file);
    GUILDA.config([], [], "reset", true);
end


function restore(s_file, s_old)
    if ismissing(s_old)
        delete(s_file)
    else
        fid = fopen(s_file, "w");  fwrite(fid, s_old);  fclose(fid);
    end
    GUILDA.config([], [], "reset", true);
end
