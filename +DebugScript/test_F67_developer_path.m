% F67 開発者向けのフォルダ _GUILDAsystem/_admin のパス (設定 Startup.DeveloperPath)
%
% DeveloperPath が false (既定) なら GUILDA.addpath は _admin をパスに入れず、true なら入れる。
% GUILDA.rmpath は _admin も外す。フォルダが無いときは何もしない。
% 利用者の設定ファイル (@GUILDA/user) は helper.user_config で書き、終了時に元へ戻す
% (GUILDA.setting を使うテストは @GUILDA/user 全体を退避して戻す)。
% _admin が無いときは一時的に作り、終了時に消す。パスは各テストの前の状態に戻す。
%
% 実行: runtests("DebugScript.test_F67_developer_path")  または  DebugScript.run_all("Features","F67")

% 共通設定 (各テストの前に毎回実行される)
s_root  = GUILDA.pwd;
s_admin = fullfile(s_root, "_GUILDAsystem", "_admin");
s_path0 = path;
c_path  = onCleanup(@() path(s_path0)); %#ok<NASGU>   % パスを元に戻す


%% DeveloperPath is false by default
sct = jsondecode(fileread(fullfile(s_root, "@GUILDA", "config", "DefaultStartup.json")));
assert(isfield(sct, "DeveloperPath") && sct.DeveloperPath.Value == false && sct.DeveloperPath.Type == "logical")


%% addpath leaves _admin out while DeveloperPath is false
c_dir = make_admin(s_admin); %#ok<NASGU>
c_set = DebugScript.helper.user_config("Startup", struct("DeveloperPath", false)); %#ok<NASGU>
addpath(s_admin);   % 前に入っていても外す
evalc("GUILDA.addpath");
assert(~on_path(s_admin), "DeveloperPath=false で _admin がパスにある")


%% addpath adds _admin while DeveloperPath is true
c_dir = make_admin(s_admin); %#ok<NASGU>
c_user = backup_user_config(); %#ok<NASGU>   % GUILDA.setting は全カテゴリのファイルを書く
GUILDA.setting("Startup", DeveloperPath=true);
evalc("GUILDA.addpath");
assert(on_path(s_admin), "DeveloperPath=true で _admin がパスに無い")
% GUILDA.setting で値を変えると、次の GUILDA.addpath で外れる
GUILDA.setting("Startup", DeveloperPath=false);
evalc("GUILDA.addpath");
assert(~on_path(s_admin), "DeveloperPath=false に戻したあとも _admin がパスにある")


%% rmpath removes _admin
c_dir = make_admin(s_admin); %#ok<NASGU>
c_set = DebugScript.helper.user_config("Startup", struct("DeveloperPath", true)); %#ok<NASGU>
evalc("GUILDA.addpath");
assert(on_path(s_admin))
evalc("GUILDA.rmpath");
assert(~on_path(s_admin), "GUILDA.rmpath のあとも _admin がパスにある")
assert(on_path(s_root), "GUILDA.rmpath がルートを外した")


%% addpath does nothing for a missing _admin
% _admin がある場合は確かめられないので、無い場合だけ確かめる
if ~isfolder(s_admin)
    c_set = DebugScript.helper.user_config("Startup", struct("DeveloperPath", true)); %#ok<NASGU>
    evalc("GUILDA.addpath");
    assert(~on_path(s_admin))
end


%% Class lists leave _admin out
% GUILDA.dictionary と find_doc_classes (クラスリファレンス) は _admin のクラスを載せない
c_dir = make_admin(s_admin); %#ok<NASGU>
s_pkg = fullfile(s_admin, "+F67AdminCheck");
mkdir(s_pkg);
c_pkg = onCleanup(@() isfolder(s_pkg) && rmdir(s_pkg, "s")); %#ok<NASGU>
writelines(["classdef AdminStub < auxiliary", "end"], fullfile(s_pkg, "AdminStub.m"));
addpath(s_admin);
rehash path
tab = GUILDA.dictionary("auxiliary", "disp", false, "output", "auxiliary");
assert(~any(contains(string(tab.filename), "F67AdminCheck")), "dictionary に _admin のクラスがある")
s_cwd = cd(fullfile(s_root, "@GUILDA", "private"));
c_cwd = onCleanup(@() cd(s_cwd)); %#ok<NASGU>
sct_scan = find_doc_classes("user", true);
assert(~any(contains({sct_scan.Classes.File}, [filesep '_admin' filesep])), "クラスリファレンスに _admin のクラスがある")


function l = on_path(s_folder)
    l = ismember(s_folder, string(strsplit(path, pathsep)));
end


function c_restore = make_admin(s_admin)
% _admin が無ければ作り、終了時 (c_restore の削除) に消す
    if isfolder(s_admin)
        c_restore = [];
        return
    end
    mkdir(s_admin);
    c_restore = onCleanup(@() remove_admin(s_admin));
end


function remove_admin(s_admin)
    if ismember(s_admin, string(strsplit(path, pathsep)))
        rmpath(s_admin);
    end
    rmdir(s_admin, "s");
end


function c_restore = backup_user_config()
% @GUILDA/user の Default*.json を退避し、終了時 (c_restore の削除) に元へ戻して設定を読み直す
    s_dir = fullfile(GUILDA.pwd, "@GUILDA", "user");
    sct   = struct("name", {}, "text", {});
    for f = dir(fullfile(s_dir, "Default*.json"))'
        sct(end+1) = struct("name", f.name, "text", fileread(fullfile(s_dir, f.name))); %#ok<AGROW>
    end
    c_restore = onCleanup(@() restore_user_config(s_dir, sct));
end


function restore_user_config(s_dir, sct)
    for f = dir(fullfile(s_dir, "Default*.json"))'
        if ~ismember(f.name, {sct.name})
            delete(fullfile(s_dir, f.name))
        end
    end
    for k = 1:numel(sct)
        fid = fopen(fullfile(s_dir, sct(k).name), "w");  fwrite(fid, sct(k).text);  fclose(fid);
    end
    GUILDA.config([], [], "reset", true);
end
