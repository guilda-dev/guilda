function publish_doc(option)
% Publish the documentation site to the gh-pages branch (GitHub Pages).
%
% >> GUILDA.publish_doc                    % rebuild, commit to gh-pages, ask before pushing
% >> GUILDA.publish_doc("confirm", false)  % push without the dialog
% >> GUILDA.publish_doc("push", false)     % dry run: build and commit locally only
%
% Run it on main or a versionX.Y branch with no uncommitted changes. It
% rebuilds the class reference, writes the site into gh-pages through a
% temporary git worktree, and commits "docs: publish <branch>@<sha>".
% gh-pages layout: _GUILDAdoc/, LICENSE, index.html (redirect), .nojekyll.
% User classes (database/User) and database/manifest.json are local data and
% are never published.
%
% confirm : ask with a dialog before "git push origin gh-pages" (default true).
% push    : false builds and commits locally without pushing (default true).
    arguments
        option.confirm (1,1) logical = true
        option.push    (1,1) logical = true
    end

    s_root     = GUILDA.pwd();
    s_branch   = "gh-pages";
    s_site     = "https://guilda-dev.github.io/guilda/";

    fprintf('\n === Publish Documentation === \n')

    % 1. Checks (no side effects before all of them pass)
    [s_source, s_sha] = check_source_repository(s_root, option.push);
    fprintf('  Source : %s@%s\n', s_source, s_sha)

    % 2. Rebuild the class reference (without user classes)
    sct_summary = export_class_database(find_doc_classes("user", false), "strict", false, "full", true);
    if sct_summary.ErrorCount > 0
        error(msg("GUILDA:publish_doc:ExportErrors", string(sct_summary.ErrorCount)));
    end

    % 3. Check out gh-pages into a temporary worktree
    fprintf('  Preparing %s ...\n', s_branch)
    run_git(s_root, 'worktree prune');
    check_branch_free(s_root, s_branch);
    bln_new = prepare_branch(s_root, s_branch, option.push);
    s_tmp   = string(tempname);
    if bln_new
        run_git(s_root, sprintf('worktree add --detach %s HEAD', quote(s_tmp)));
        wt_cleanup = onCleanup(@() remove_worktree(s_root, s_tmp));
        run_git(s_tmp, sprintf('checkout -q --orphan %s', s_branch));
        run_git(s_tmp, 'rm -r -q --cached .');
    else
        run_git(s_root, sprintf('worktree add %s %s', quote(s_tmp), s_branch));
        wt_cleanup = onCleanup(@() remove_worktree(s_root, s_tmp));
    end

    % 4. Replace the contents
    write_site(s_root, s_tmp);
    if ~bln_new
        keep_published_index(s_tmp);
    end

    % 5. Commit
    run_git(s_tmp, 'add -A');
    s_changes = run_git(s_tmp, 'status --porcelain');
    if strlength(strtrim(s_changes)) == 0
        fprintf('  No changes: %s already matches %s@%s.\n\n', s_branch, s_source, s_sha)
        return
    end
    s_message = sprintf('docs: publish %s@%s', s_source, s_sha);
    run_git(s_tmp, sprintf('commit -q -m "%s"', s_message));
    fprintf('  Committed to %s : %s\n', s_branch, s_message)
    clear wt_cleanup

    % 6. Push
    s_push = sprintf('git push origin %s', s_branch);
    if ~option.push
        fprintf('  Push skipped. To publish, run in %s:\n    %s\n\n', s_root, s_push)
        return
    end
    if option.confirm
        s_answer = questdlg( ...
            sprintf('Push "%s" to origin/%s?\nThe site %s will be updated.', s_message, s_branch, s_site), ...
            'Publish documentation', 'Push', 'Cancel', 'Cancel');
        if ~strcmp(s_answer, 'Push')
            fprintf('  Push cancelled. The commit stays on the local %s branch.\n', s_branch)
            fprintf('  To publish later, run in %s:\n    %s\n\n', s_root, s_push)
            return
        end
    end
    [r_status, s_out] = system(sprintf('git --no-pager -C %s push --no-progress origin %s', quote(s_root), s_branch));
    fprintf('%s', s_out)
    if r_status ~= 0
        error(msg("GUILDA:publish_doc:PushFailed", s_branch));
    end
    fprintf('  Published : %s\n\n', s_site)
end


function [s_source, s_sha] = check_source_repository(s_root, bln_push)
    [r_status, ~] = system('git --version');
    if r_status ~= 0
        error(msg("GUILDA:publish_doc:NoGit"));
    end
    [r_status, s_out] = system(sprintf('git --no-pager -C %s rev-parse --is-inside-work-tree', quote(s_root)));
    if r_status ~= 0 || ~strcmp(strtrim(s_out), 'true')
        error(msg("GUILDA:publish_doc:NoRepository", s_root));
    end

    s_source = strtrim(run_git(s_root, 'rev-parse --abbrev-ref HEAD'));
    if ~(strcmp(s_source, 'main') || ~isempty(regexp(s_source, '^version\d+\.\d+$', 'once')))
        error(msg("GUILDA:publish_doc:WrongBranch", s_source));
    end

    s_tracked = run_git(s_root, 'status --porcelain --untracked-files=no');
    if strlength(strtrim(s_tracked)) > 0
        error(msg("GUILDA:publish_doc:UncommittedChanges", s_tracked));
    end
    s_untracked = run_git(s_root, 'status --porcelain --untracked-files=all -- _GUILDAdoc');
    if strlength(strtrim(s_untracked)) > 0
        error(msg("GUILDA:publish_doc:UntrackedDocFiles", s_untracked));
    end

    if bln_push
        [r_status, ~] = system(sprintf('git --no-pager -C %s remote get-url origin', quote(s_root)));
        if r_status ~= 0
            error(msg("GUILDA:publish_doc:NoOrigin"));
        end
    end
    s_sha = strtrim(run_git(s_root, 'rev-parse --short HEAD'));
end


function bln_new = prepare_branch(s_root, s_branch, bln_push)
    % Bring the local branch up to date with origin. Returns true when the
    % branch exists neither locally nor on origin.
    bln_remote = false;
    [r_status, ~] = system(sprintf('git --no-pager -C %s remote get-url origin', quote(s_root)));
    if r_status == 0
        [r_status, s_out] = system(sprintf('git --no-pager -C %s ls-remote --exit-code --heads origin %s', quote(s_root), s_branch));
        if r_status == 0
            bln_remote = true;
        elseif r_status ~= 2 && bln_push
            error(msg("GUILDA:publish_doc:RemoteUnreachable", string(s_out)));
        end
    end
    s_remote_ref = "refs/remotes/origin/" + s_branch;
    if bln_remote
        run_git(s_root, sprintf('fetch -q origin +refs/heads/%s:%s', s_branch, s_remote_ref));
    end

    [r_status, ~] = system(sprintf('git --no-pager -C %s show-ref --verify --quiet refs/heads/%s', quote(s_root), s_branch));
    bln_local = r_status == 0;

    bln_new = ~bln_local && ~bln_remote;
    if ~bln_remote
        return
    end
    if ~bln_local
        run_git(s_root, sprintf('branch %s %s', s_branch, s_remote_ref));
        return
    end
    [r_behind, ~] = system(sprintf('git --no-pager -C %s merge-base --is-ancestor %s %s', quote(s_root), s_branch, s_remote_ref));
    [r_ahead, ~]  = system(sprintf('git --no-pager -C %s merge-base --is-ancestor %s %s', quote(s_root), s_remote_ref, s_branch));
    if r_behind == 0
        run_git(s_root, sprintf('branch -f %s %s', s_branch, s_remote_ref));
    elseif r_ahead ~= 0
        error(msg("GUILDA:publish_doc:Diverged", s_branch, s_branch, s_branch, s_branch));
    end
end


function check_branch_free(s_root, s_branch)
    % A worktree left by an interrupted run keeps the branch checked out.
    s_list = run_git(s_root, 'worktree list --porcelain');
    cell_blocks = strsplit(strrep(s_list, char(13), ''), [newline newline]);
    for i_block = 1:numel(cell_blocks)
        if contains(cell_blocks{i_block}, "branch refs/heads/" + s_branch)
            s_path = regexp(cell_blocks{i_block}, '(?<=^worktree )[^\n]*', 'match', 'once', 'lineanchors');
            error(msg("GUILDA:publish_doc:BranchInUse", s_branch, s_path, s_path));
        end
    end
end


function write_site(s_root, s_tmp)
    % Remove everything except .git, then copy the site.
    sct_items = dir(s_tmp);
    sct_items = sct_items(~ismember({sct_items.name}, {'.', '..', '.git'}));
    for i_item = 1:numel(sct_items)
        s_item = fullfile(s_tmp, sct_items(i_item).name);
        if sct_items(i_item).isdir
            rmdir(s_item, 's');
        else
            delete(s_item);
        end
    end

    copy_or_error(fullfile(s_root, '_GUILDAdoc'), fullfile(s_tmp, '_GUILDAdoc'));
    copy_or_error(fullfile(s_root, 'LICENSE'), fullfile(s_tmp, 'LICENSE'));

    % Local export data: user classes and the incremental-export manifest.
    s_db = fullfile(s_tmp, '_GUILDAdoc', 'database');
    if isfolder(fullfile(s_db, 'User'))
        rmdir(fullfile(s_db, 'User'), 's');
    end
    if isfile(fullfile(s_db, 'manifest.json'))
        delete(fullfile(s_db, 'manifest.json'));
    end

    % OS files are ignored in the source branch, but gh-pages has no .gitignore.
    for s_pattern = ["**/.DS_Store", "**/._*", "**/Thumbs.db", "**/ehthumbs.db", "**/Desktop.ini", "**/*.asv"]
        sct_junk = dir(fullfile(s_tmp, '_GUILDAdoc', s_pattern));
        sct_junk = sct_junk(~[sct_junk.isdir]);
        arrayfun(@(s) delete(fullfile(s.folder, s.name)), sct_junk);
    end

    s_index = "<!doctype html>" + newline + ...
        "<html lang=""en"">" + newline + ...
        "<head>" + newline + ...
        "<meta charset=""utf-8"">" + newline + ...
        "<meta http-equiv=""refresh"" content=""0; url=_GUILDAdoc/index.html"">" + newline + ...
        "<link rel=""canonical"" href=""_GUILDAdoc/index.html"">" + newline + ...
        "<title>GUILDA Documentation</title>" + newline + ...
        "</head>" + newline + ...
        "<body>" + newline + ...
        "<p><a href=""_GUILDAdoc/index.html"">GUILDA Documentation</a></p>" + newline + ...
        "</body>" + newline + ...
        "</html>" + newline;
    write_text(fullfile(s_tmp, 'index.html'), s_index);
    write_text(fullfile(s_tmp, '.nojekyll'), "");
end


function keep_published_index(s_tmp)
    % The exporter stamps generatedAt on every rebuild. Keep the published
    % class index when nothing else in it changed, so an unchanged site
    % makes no commit.
    s_path = '_GUILDAdoc/database/list_Classes.js';
    [r_status, s_old] = system(sprintf('git --no-pager -C %s show HEAD:%s', quote(s_tmp), s_path));
    if r_status ~= 0
        return
    end
    s_new = fileread(fullfile(s_tmp, s_path), 'Encoding', 'UTF-8');
    sr_pattern = {'"generatedAt":\s*"[^"]*"', '\r'};
    if strcmp(regexprep(strtrim(s_old), sr_pattern, ''), regexprep(strtrim(s_new), sr_pattern, ''))
        run_git(s_tmp, sprintf('checkout HEAD -- %s', s_path));
    end
end


function copy_or_error(s_from, s_to)
    [bln_ok, s_msg] = copyfile(s_from, s_to);
    if ~bln_ok
        error(msg("GUILDA:publish_doc:CopyFailed", s_from, string(s_msg)));
    end
end


function write_text(s_file, s_content)
    fid = fopen(s_file, 'w', 'n', 'UTF-8');
    if fid == -1
        error(msg("GUILDA:publish_doc:WriteFailed", s_file));
    end
    fprintf(fid, '%s', s_content);
    fclose(fid);
end


function remove_worktree(s_root, s_tmp)
    [r_status, ~] = system(sprintf('git --no-pager -C %s worktree remove --force %s', quote(s_root), quote(s_tmp)));
    if r_status ~= 0
        if isfolder(s_tmp)
            rmdir(s_tmp, 's');
        end
        system(sprintf('git --no-pager -C %s worktree prune', quote(s_root)));
    end
end


function s_out = run_git(s_dir, s_args)
    [r_status, s_out] = system(sprintf('git --no-pager -C %s %s', quote(s_dir), s_args));
    if r_status ~= 0
        error(msg("GUILDA:publish_doc:GitFailed", s_args, string(s_out)));
    end
end


function s_quoted = quote(s_path)
    s_quoted = """" + string(s_path) + """";
end
