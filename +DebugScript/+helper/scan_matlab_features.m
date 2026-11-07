function tab = scan_matlab_features(sv_folder, opt)
% 実行時コードが使う MATLAB の組み込み関数・クラス・Name=Value オプション・言語機能を一覧にする (最低バージョン調査用)
%
%   tab = DebugScript.helper.scan_matlab_features();
%   tab = DebugScript.helper.scan_matlab_features(["@GUILDA","_GUILDAsystem"], csv="scan.csv");
%
% mtree で各ファイルを構文解析し、次を集める。
%   id         : 識別子 (which が MATLAB 本体またはツールボックスを指すもの)
%   package    : matlab.* などのパッケージ名 (matlab.ode.SolverID など)
%   namevalue  : Name=Value 構文の名前 (呼び出し先の関数名と組)
%   stringarg  : 組み込み関数へ文字列で渡した引数 ("Name",value 形式のオプション名の候補)
%   field      : obj.name の name で、組み込み関数・メソッドと同名のもの (要目視確認)
%   syntax     : 言語機能 (arguments (Output)/(Repeating)、opt.?Class、"..." 文字列、dictionary の {} など)
% "未" を含むフォルダと archive/ は対象外。which は GUILDA のパスを通した状態で引くので、
% GUILDA 側の同名関数は除かれる。
    arguments (Input)
        sv_folder (1,:) string = ["@GUILDA","_GUILDAsystem","_GUILDAobject"]  % 対象フォルダ (GUILDA.pwd からの相対)
        opt.csv (1,1) string = ""                                              % 書き出す CSV (空なら書かない)
    end
    arguments (Output)
        tab table  % item, kind, func, where, count, location
    end
    s_root = string(GUILDA.pwd);
    sv_file = strings(0,1);
    for s = sv_folder
        d = dir(fullfile(s_root, s, "**", "*.m"));
        sv_path = string(fullfile({d.folder}, {d.name}))';
        sv_file = [sv_file; sv_path(~contains(sv_path, "未") & ~contains(sv_path, filesep+"archive"+filesep))]; %#ok<AGROW>
    end

    rows = cell(0,4);  % {item, kind, func, location}
    for f = sv_file'
        s_rel = erase(f, s_root+filesep);
        t = mtree(char(f), '-file', '-comments');
        if count(t.mtfind('Kind','ERR')) > 0
            warning("scan_matlab_features:parse", "構文解析に失敗: %s", s_rel); continue
        end
        rows = [rows; scan_tree(t, s_rel)]; %#ok<AGROW>
        rows = [rows; scan_text(fileread(f), s_rel)]; %#ok<AGROW>
    end

    % which で組み込み (MATLAB 本体・ツールボックス) を判定
    sv_item = string(rows(:,1)); sv_kind = string(rows(:,2));
    sv_func = string(rows(:,3)); sv_loc = string(rows(:,4));
    sv_check = unique([sv_item(ismember(sv_kind,["id","field"])); sv_func(sv_func~="")]);
    map_where = dictionary(string.empty, string.empty);
    for s = sv_check'
        map_where(s) = where_builtin(s);
    end
    l_keep = true(size(sv_item));
    sv_where = strings(size(sv_item));
    for i = 1:numel(sv_item)
        switch sv_kind(i)
            case {"id","field"}
                sv_where(i) = map_where(sv_item(i));
                l_keep(i) = sv_where(i) ~= "";
            case {"namevalue","stringarg"}
                if sv_func(i) ~= "" && isKey(map_where, sv_func(i)), sv_where(i) = map_where(sv_func(i)); end
                l_keep(i) = sv_where(i) ~= "" || sv_kind(i) == "namevalue";
            otherwise
                sv_where(i) = "language";
        end
    end
    sv_item = sv_item(l_keep); sv_kind = sv_kind(l_keep); sv_func = sv_func(l_keep);
    sv_loc = sv_loc(l_keep); sv_where = sv_where(l_keep);

    [~, ~, ic] = unique(sv_kind + "|" + sv_func + "|" + sv_item, "stable");
    n = max([ic; 0]);
    item = strings(n,1); kind = item; func = item; where = item; location = item; cnt = zeros(n,1);
    for k = 1:n
        j = find(ic == k);
        item(k) = sv_item(j(1)); kind(k) = sv_kind(j(1)); func(k) = sv_func(j(1)); where(k) = sv_where(j(1));
        cnt(k) = numel(j);
        location(k) = strjoin(unique(sv_loc(j), "stable"), "; ");
    end
    tab = table(item, kind, func, where, cnt, location, VariableNames=["item","kind","func","where","count","location"]);
    tab = sortrows(tab, ["kind","item"]);
    if opt.csv ~= ""
        writetable(tab, opt.csv);
    end
end

function rows = scan_tree(t, s_rel)
% 構文木から識別子・パッケージ名・Name=Value・文字列引数を集める
    rows = cell(0,4);
    loc = @(nd) s_rel + ":" + string(nd.lineno);
    % 識別子 (パッケージの先頭以外)
    ids = t.mtfind('Kind','ID');
    for i = indices(ids)
        nd = ids.select(i);
        rows(end+1,:) = {string(nd.string), "id", "", loc(nd)}; %#ok<AGROW>
    end
    % obj.name のフィールド名と、matlab.* のパッケージ名
    dots = t.mtfind('Kind','DOT');
    for i = indices(dots)
        nd = dots.select(i);
        s_full = dotted_name(nd);
        if s_full ~= ""
            if any(startsWith(s_full, ["matlab.","containers.","meta.","java."]))
                rows(end+1,:) = {s_full, "package", "", loc(nd)}; %#ok<AGROW>
            end
        end
        r = nd.Right;
        if ~isnull(r) && strcmp(r.kind, 'FIELD')
            rows(end+1,:) = {string(r.string), "field", "", loc(nd)}; %#ok<AGROW>
        end
    end
    % 呼び出しの引数 (Name=Value と文字列)
    calls = t.mtfind('Kind',{'CALL','SUBSCR','DCALL'});
    for i = indices(calls)
        nd = calls.select(i);
        s_fn = call_name(nd.Left);
        a = nd.Right;
        while ~isnull(a)
            switch a.kind
                case 'NAMEVALUE'
                    rows(end+1,:) = {string(a.Left.string), "namevalue", s_fn, loc(a)}; %#ok<AGROW>
                case {'STRING','CHARVECTOR'}
                    s = string(a.string);
                    if strlength(s) < 3, a = a.Next; continue, end
                    s = extractBetween(s, 2, strlength(s)-1);
                    if s_fn ~= "" && ~isempty(regexp(s, '^[A-Za-z]\w*$', 'once'))
                        rows(end+1,:) = {s, "stringarg", s_fn, loc(a)}; %#ok<AGROW>
                    end
            end
            a = a.Next;
        end
    end
end

function rows = scan_text(s_text, s_rel)
% 構文木から取りにくい言語機能を正規表現で拾う (コメントは除く)
    rows = cell(0,4);
    sv_line = splitlines(string(s_text));
    sv_pat = [ ...
        "arguments (Output)",       "^\s*arguments\s*\([^)]*\<Output\>"; ...
        "arguments (Input)",        "^\s*arguments\s*\([^)]*\<Input\>"; ...
        "arguments (Repeating)",    "^\s*arguments\s*\([^)]*\<Repeating\>"; ...
        "arguments block",          "^\s*arguments\>\s*(\(|$|%)"; ...
        "opt.?Class",               "^\s*\w+\.\?\w"; ...
        "double-quoted string",     """[^""]*"""; ...
        "dictionary brace index",   "\<\w+\{[^}]*\}\s*=\s*[^=]"; ...
        "enumeration block",        "^\s*enumeration\>"; ...
        "events block",             "^\s*events\>"; ...
        "properties (Constant)",    "^\s*properties\s*\([^)]*Constant"; ...
        "property validation",      "^\s*\w+\s*\(\s*[\d:,]+\s*\)\s*\w+"; ...
        "local function in script", ""];
    for i = 1:numel(sv_line)
        s = regexprep(sv_line(i), "%.*$", "");  % 粗いコメント除去 ('%' を含む文字列は誤る)
        for k = 1:size(sv_pat,1)
            if sv_pat(k,2) ~= "" && ~isempty(regexp(s, sv_pat(k,2), 'once'))
                rows(end+1,:) = {sv_pat(k,1), "syntax", "", s_rel+":"+i}; %#ok<AGROW>
            end
        end
    end
end

function s = dotted_name(nd)
% a.b.c の形 (先頭が ID、残りが FIELD) なら "a.b.c" を返す
    s = "";
    if strcmp(nd.kind,'ID'), s = string(nd.string); return, end
    if ~strcmp(nd.kind,'DOT'), return, end
    sl = dotted_name(nd.Left);
    if sl == "" || ~strcmp(nd.Right.kind,'FIELD'), return, end
    s = sl + "." + string(nd.Right.string);
end

function s = call_name(nd)
% 呼び出し先の名前 (f(...) の f、obj.f(...) の f、pkg.f(...) の pkg.f)
    s = "";
    if strcmp(nd.kind,'ID'), s = string(nd.string); return, end
    if strcmp(nd.kind,'DOT')
        s_full = dotted_name(nd);
        if any(startsWith(s_full, "matlab.")), s = s_full; return, end
        if strcmp(nd.Right.kind,'FIELD'), s = string(nd.Right.string); end
    end
end

function s = where_builtin(s_name)
% MATLAB 本体・ツールボックスの関数・クラスなら "toolbox/<name>" か "built-in"、そうでなければ ""
    s = "";
    if ~isvarname(s_name) && ~contains(s_name, "."), return, end
    w = string(which(s_name));
    if w == "" || contains(w, string(GUILDA.pwd)) || startsWith(w, "variable"), return, end
    if startsWith(w, "built-in")
        p = regexp(w, "\((.*)\)", "tokens", "once");
        if isempty(p), s = "built-in"; return, end
        w = string(p{1});
    end
    tok = regexp(w, "toolbox[/\\](\w+)[/\\](\w+)", "tokens", "once");
    if isempty(tok)
        s = "built-in";
    else
        s = string(tok{1}) + "/" + string(tok{2});
    end
end
