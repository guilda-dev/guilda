function str_id = msg_id(x, id)
% エラーや警告の文章から GUILDA のメッセージ ID を調べる
%
%   str_id = DebugScript.helper.msg_id(ME)        % MException など (identifier と message を持つ)
%   str_id = DebugScript.helper.msg_id()          % lastwarn の警告
%   str_id = DebugScript.helper.msg_id(str, id)   % 文章と identifier
%
% error(msg(...)) / warning(msg(...)) には identifier が付かないので、文章が
% SystemTools/GUILDA/en/*.xml のどの entry から作られたかで判定する。プレースホルダは任意の
% 文字列に一致する。identifier があるとき (MATLAB 自身、テスト、MException) はそれを返し、
% どの entry にも一致しないときは空を返す。ME.identifier と同じく char を返す。

    arguments (Input)
        x = []
        id = ""
    end
    arguments (Output)
        str_id  % メッセージ ID (char、見つからなければ空)
    end
    if nargin == 0
        [x, id] = lastwarn();
    elseif ~(ischar(x) || isstring(x))
        id = x.identifier;
        x  = x.message;
    end
    str_id = char(id);
    if ~isempty(str_id)
        return
    end
    str = char(x);
    if isempty(str)
        return
    end
    [sv_id, c_pat] = catalog();
    for k = 1:numel(sv_id)
        if ~isempty(regexp(str, c_pat{k}, "once"))
            str_id = char(sv_id(k));
            return
        end
    end
end


function [sv_id, c_pat] = catalog()
% 全 entry の ID と正規表現。固定部分が長いものを先に調べる (短い entry に誤って一致させない)
    arguments (Output)
        sv_id  % メッセージ ID の一覧
        c_pat  % 各 ID の文章の正規表現
    end
    persistent sv_cache c_cache
    if isempty(sv_cache)
        str_dir = fullfile(fileparts(which("msg")), "GUILDA", "en");
        a_xml   = dir(fullfile(str_dir, "*.xml"));
        sv_cache = strings(0,1);
        c_cache  = cell(0,1);
        rv_len   = zeros(0,1);
        for i = numel(a_xml):-1:1   % 同じ文章の entry は Deprecated.xml を先にする
            s_xml = readstruct(fullfile(str_dir, a_xml(i).name));
            a_ent = s_xml.message.entry;
            for k = 1:numel(a_ent)
                [str_pat, n_len] = to_pattern(a_ent(k).Text);
                if n_len > 0   % "{0}" だけの entry は何にでも一致するので調べない
                    sv_cache(end+1,1) = "GUILDA:" + erase(a_xml(i).name, ".xml") + ":" + a_ent(k).keyAttribute; %#ok<AGROW>
                    c_cache{end+1,1}  = str_pat; %#ok<AGROW>
                    rv_len(end+1,1)   = n_len; %#ok<AGROW>
                end
            end
        end
        [~, iv] = sort(rv_len, "descend");
        sv_cache = sv_cache(iv);
        c_cache  = c_cache(iv);
    end
    sv_id = sv_cache;
    c_pat = c_cache;
end


function [str_pat, n_len] = to_pattern(str_text)
% entry の文章を正規表現へ変換する。msg は引数がないとき文章をそのまま返す
    arguments (Input)
        str_text  % メッセージの文章 (プレースホルダ付き)
    end
    arguments (Output)
        str_pat  % 文章に一致する正規表現
        n_len    % プレースホルダを除いた文字数
    end
    str = char(str_text);
    c_lit = regexp(str, '\{\d+(,.*?)?\}', "split");
    if isscalar(c_lit)
        c_esc = {regexptranslate("escape", str)};
    else
        c_lit = strrep(strrep(strrep(c_lit, "'{'", "{"), "'}'", "}"), "''", "'");
        c_esc = cellfun(@(s) regexptranslate("escape", s), c_lit, "UniformOutput", false);
    end
    str_pat = [strjoin(c_esc, '.*'), '$'];   % 先頭は固定しない (arguments の検証関数のエラーには MATLAB が文を前置する)
    n_len   = sum(cellfun(@numel, c_lit));
end
