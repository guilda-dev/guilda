% F25 Ishizaki6Bus のソースデータの検査 (Issue #108)
%
% network.Ishizaki6Bus は生成した branch 表を一時フォルダへ書いて読み込む。
%   - 構築してもクラスフォルダのファイルは変わらない
%   - 一時フォルダは構築の後に残らない
%   - アドミタンス行列は branch_origin の値と alpha, line の指定から決まる
%
% 実行: runtests("DebugScript.test_F25_ishizaki_source_data")  または  DebugScript.run_all("Features","F25")

% 共通設定 (各テストの前に毎回実行される)
s_class = fileparts(which("network.Ishizaki6Bus"));


%% Construction leaves the class folder unchanged
tab_before = snapshot_folder(s_class);
DebugScript.helper.quiet(@() network.Ishizaki6Bus(0.1, line="None"));
DebugScript.helper.quiet(@() network.Ishizaki6Bus(2.5, line="L23"));
assert(isequal(snapshot_folder(s_class), tab_before))


%% Construction removes its temporary folder
% 共有の tempdir は他の処理も使うので, tempname の代役で専用のフォルダへ向ける
s_tmp = tempname;  mkdir(s_tmp);
c_dir = onCleanup(@() rmdir(s_tmp, "s"));
writelines(["function str = tempname"
            "    s_dir = fileparts(mfilename('fullpath'));"
            "    fclose(fopen(fullfile(s_dir,'called'),'w'));"
            "    str = fullfile(s_dir,['work_',char(java.util.UUID.randomUUID())]);"
            "end"], fullfile(s_tmp, "tempname.m"));
addpath(s_tmp);
c_path = onCleanup(@() rmpath(s_tmp));
net = DebugScript.helper.quiet(@() network.Ishizaki6Bus(0.1, line="None"));
assert(numel(net.a_Bus) == 6)
assert(isequal(sort(setdiff({dir(s_tmp).name}, {'.','..'})), {'called','tempname.m'}))


%% Admittance matrix with all lines
assert_admittance(0.1, "None", zeros(0,2), s_class)


%% Admittance matrix of each line option
assert_admittance(1,   "Both", [2,3;4,6], s_class)
assert_admittance(2.5, "L23",  [2,3],     s_class)
assert_admittance(0.5, "L46",  [4,6],     s_class)


function tab = snapshot_folder(s_dir)
% 配下の全ファイルのパス, 更新時刻, 内容
    sct = dir(fullfile(s_dir, "**", "*"));
    sct = sct(~[sct.isdir]);
    sv_path  = string(fullfile({sct.folder}, {sct.name}))';
    r_date   = [sct.datenum]';
    c_data   = arrayfun(@(p) fileread(p), sv_path, "UniformOutput", false);
    tab = table(sv_path, r_date, c_data);
end


function assert_admittance(alpha, s_line, FromTo_removed, s_class)
    net = DebugScript.helper.quiet(@() network.Ishizaki6Bus(alpha, line=s_line));
    tab_Y = net.get_admittance_matrix();

    % branch_origin から直接組み立てる
    tab = readtable(fullfile(s_class, "branch_origin", "parameter.csv"));
    tab.R(5:end) = alpha * tab.X(5:end);
    tab = tab(~ismember([tab.From, tab.To], FromTo_removed, "rows"), :);
    Y = zeros(6);
    for i = 1:height(tab)
        k = [tab.From(i), tab.To(i)];
        y = 1 / (tab.R(i) + 1j*tab.X(i));
        Y(k,k) = Y(k,k) + [y,-y;-y,y];
    end
    assert(norm(tab_Y{:,:} - Y, "fro") < 1e-12)
end
