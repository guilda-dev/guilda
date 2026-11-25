function exe_codes_textbook(num)
% 教科書のプログラム（例3.8〜3.19）の GUILDA v4 版を実行します。
%
% 例の番号（"3.11" など）を与えると、codes_textbook/example<番号> の v4 版スクリプトを
% ベースワークスペースで実行し、デスクトップでは エディターにそのスクリプトを開きます。
% 番号を省略すると、コマンド ウィンドウで番号を尋ねます。
% 例3.8〜3.10 と 3.14 は GUILDA を使わない MATLAB の例なので v4 版はありません。
% これらの番号では、旧版（guilda-dev/textbook の codes_textbook）の場所を表示します。
% 対応表は codes_textbook/README.md にあります。
%
% <@Examples>
% ```matlab
% exe_codes_textbook("3.18")   % 母線1の地絡に対する時間応答
% exe_codes_textbook           % 番号を尋ねる
% ```
    arguments (Input)
        num (1,1) string = ""  % 例の番号（"3.8"〜"3.19"）。"" のときは尋ねます。
    end
    if num == ""
        disp('実行したいプログラムに対応する例の番号を入力してください');
        disp('  ex) プログラム3-16（例3.13） → 3.13');
        num = string(input('→ ', "s"));
    end

    sv_v4 = ["3.11", "main_ex4.m"
             "3.12", "main_admittance.m"
             "3.13", "main_power_flow.m"
             "3.15", "main_simulation_3bus_simple.m"
             "3.16", "main_simulation_3bus.m"
             "3.17", "main_simulation_3bus_equilibrium.m"
             "3.18", "main_simulation_3bus_fault.m"
             "3.19", "main_simulation_3bus_input.m"];
    sv_old = ["3.8", "3.9", "3.10", "3.14"];

    if ismember(num, sv_old)
        fprintf('例%s は GUILDA を使わない MATLAB の例のため、v4 版はありません。\n', num);
        fprintf('旧版 codes_textbook/example%s（guilda-dev/textbook）をそのまま実行してください。\n', num);
        return
    end
    i = find(sv_v4(:,1) == num, 1);
    if isempty(i)
        error('入力した番号に対応するファイルは存在しません')
    end
    s_file = fullfile(fileparts(mfilename("fullpath")), "codes_textbook", "example" + num, sv_v4(i,2));
    fprintf('↓↓↓%s の実行結果↓↓↓\n', sv_v4(i,2));
    evalin("base", sprintf("run('%s')", s_file));
    if usejava("desktop")
        edit(s_file);
    end
end
