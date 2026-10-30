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
%
% confirm : ask with a dialog before "git push origin gh-pages" (default true).
% push    : false builds and commits locally without pushing (default true).
    arguments
        option.confirm (1,1) logical = true
        option.push    (1,1) logical = true
    end

    str_root   = GUILDA.pwd();
    str_branch = "gh-pages";
    str_site   = "https://guilda-dev.github.io/guilda/";

    fprintf('\n === Publish Documentation === \n')

    % 1. Checks (no side effects before all of them pass)
    [str_source, str_sha] = check_source_repository(str_root, option.push);
    fprintf('  Source : %s@%s\n', str_source, str_sha)

    % 2. Rebuild the class reference
    sct_summary = export_class_database(find_doc_classes(), "strict", false);
    if sct_summary.ErrorCount > 0
        error('GUILDA:publish_doc:ExportErrors', ...
            'The class reference has %d error(s). Fix them before publishing.', sct_summary.ErrorCount);
    end

    % 3. Check out gh-pages into a temporary worktree
    fprintf('  Preparing %s ...\n', str_branch)
    run_git(str_root, 'worktree prune');
    check_branch_free(str_root, str_branch);
    bln_new = prepare_branch(str_root, str_branch, option.push);
    str_tmp = string(tempname);
    if bln_new
        run_git(str_root, sprintf('worktree add --detach %s HEAD', quote(str_tmp)));
        wt_cleanup = onCleanup(@() remove_worktree(str_root, str_tmp));
        run_git(str_tmp, sprintf('checkout -q --orphan %s', str_branch));
        run_git(str_tmp, 'rm -r -q --cached .');
    else
        run_git(str_root, sprintf('worktree add %s %s', quote(str_tmp), str_branch));
        wt_cleanup = onCleanup(@() remove_worktree(str_root, str_tmp));
    end

    % 4. Replace the contents
    write_site(str_root, str_tmp);
    if ~bln_new
        keep_published_index(str_tmp);
    end

    % 5. Commit
    run_git(str_tmp, 'add -A');
    str_changes = run_git(str_tmp, 'status --porcelain');
    if strlength(strtrim(str_changes)) == 0
        fprintf('  No changes: %s already matches %s@%s.\n\n', str_branch, str_source, str_sha)
        return
    end
    str_message = sprintf('docs: publish %s@%s', str_source, str_sha);
    run_git(str_tmp, sprintf('commit -q -m "%s"', str_message));
    fprintf('  Committed to %s : %s\n', str_branch, str_message)
    clear wt_cleanup

    % 6. Push
    str_push = sprintf('git push origin %s', str_branch);
    if ~option.push
        fprintf('  Push skipped. To publish, run in %s:\n    %s\n\n', str_root, str_push)
        return
    end
    if option.confirm
        str_answer = questdlg( ...
            sprintf('Push "%s" to origin/%s?\nThe site %s will be updated.', str_message, str_branch, str_site), ...
            'Publish documentation', 'Push', 'Cancel', 'Cancel');
        if ~strcmp(str_answer, 'Push')
            fprintf('  Push cancelled. The commit stays on the local %s branch.\n', str_branch)
            fprintf('  To publish later, run in %s:\n    %s\n\n', str_root, str_push)
            return
        end
    end
    [r_status, str_out] = system(sprintf('git --no-pager -C %s push --no-progress origin %s', quote(str_root), str_branch));
    fprintf('%s', str_out)
    if r_status ~= 0
        error('GUILDA:publish_doc:PushFailed', 'git push failed. The commit stays on the local %s branch.', str_branch);
    end
    fprintf('  Published : %s\n\n', str_site)
end


function [str_source, str_sha] = check_source_repository(str_root, bln_push)
    [r_status, ~] = system('git --version');
    if r_status ~= 0
        error('GUILDA:publish_doc:NoGit', 'git was not found. Install git and add it to the system path.');
    end
    [r_status, str_out] = system(sprintf('git --no-pager -C %s rev-parse --is-inside-work-tree', quote(str_root)));
    if r_status ~= 0 || ~strcmp(strtrim(str_out), 'true')
        error('GUILDA:publish_doc:NoRepository', '%s is not a git repository.', str_root);
    end

    str_source = strtrim(run_git(str_root, 'rev-parse --abbrev-ref HEAD'));
    if ~(strcmp(str_source, 'main') || ~isempty(regexp(str_source, '^version\d+\.\d+$', 'once')))
        error('GUILDA:publish_doc:WrongBranch', ...
            'Publish from main or a versionX.Y branch. The current branch is "%s".', str_source);
    end

    str_tracked = run_git(str_root, 'status --porcelain --untracked-files=no');
    if strlength(strtrim(str_tracked)) > 0
        error('GUILDA:publish_doc:UncommittedChanges', ...
            'Commit or discard the changes to tracked files first:\n%s', str_tracked);
    end
    str_untracked = run_git(str_root, 'status --porcelain --untracked-files=all -- _GUILDAdoc');
    if strlength(strtrim(str_untracked)) > 0
        error('GUILDA:publish_doc:UntrackedDocFiles', ...
            'Commit or remove the untracked files under _GUILDAdoc first:\n%s', str_untracked);
    end

    if bln_push
        [r_status, ~] = system(sprintf('git --no-pager -C %s remote get-url origin', quote(str_root)));
        if r_status ~= 0
            error('GUILDA:publish_doc:NoOrigin', 'The repository has no remote named origin.');
        end
    end
    str_sha = strtrim(run_git(str_root, 'rev-parse --short HEAD'));
end


function bln_new = prepare_branch(str_root, str_branch, bln_push)
    % Bring the local branch up to date with origin. Returns true when the
    % branch exists neither locally nor on origin.
    bln_remote = false;
    [r_status, ~] = system(sprintf('git --no-pager -C %s remote get-url origin', quote(str_root)));
    if r_status == 0
        [r_status, str_out] = system(sprintf('git --no-pager -C %s ls-remote --exit-code --heads origin %s', quote(str_root), str_branch));
        if r_status == 0
            bln_remote = true;
        elseif r_status ~= 2 && bln_push
            error('GUILDA:publish_doc:RemoteUnreachable', 'Unable to read origin:\n%s', str_out);
        end
    end
    str_remote_ref = "refs/remotes/origin/" + str_branch;
    if bln_remote
        run_git(str_root, sprintf('fetch -q origin +refs/heads/%s:%s', str_branch, str_remote_ref));
    end

    [r_status, ~] = system(sprintf('git --no-pager -C %s show-ref --verify --quiet refs/heads/%s', quote(str_root), str_branch));
    bln_local = r_status == 0;

    bln_new = ~bln_local && ~bln_remote;
    if ~bln_remote
        return
    end
    if ~bln_local
        run_git(str_root, sprintf('branch %s %s', str_branch, str_remote_ref));
        return
    end
    [r_behind, ~] = system(sprintf('git --no-pager -C %s merge-base --is-ancestor %s %s', quote(str_root), str_branch, str_remote_ref));
    [r_ahead, ~]  = system(sprintf('git --no-pager -C %s merge-base --is-ancestor %s %s', quote(str_root), str_remote_ref, str_branch));
    if r_behind == 0
        run_git(str_root, sprintf('branch -f %s %s', str_branch, str_remote_ref));
    elseif r_ahead ~= 0
        error('GUILDA:publish_doc:Diverged', ...
            'The local %s and origin/%s have diverged. Reset the local branch with "git branch -f %s origin/%s".', ...
            str_branch, str_branch, str_branch, str_branch);
    end
end


function check_branch_free(str_root, str_branch)
    % A worktree left by an interrupted run keeps the branch checked out.
    str_list = run_git(str_root, 'worktree list --porcelain');
    cell_blocks = strsplit(strrep(str_list, char(13), ''), [newline newline]);
    for i_block = 1:numel(cell_blocks)
        if contains(cell_blocks{i_block}, "branch refs/heads/" + str_branch)
            str_path = regexp(cell_blocks{i_block}, '(?<=^worktree )[^\n]*', 'match', 'once', 'lineanchors');
            error('GUILDA:publish_doc:BranchInUse', ...
                '%s is checked out in %s, probably left by an interrupted run.\nRemove it with: git worktree remove --force "%s"', ...
                str_branch, str_path, str_path);
        end
    end
end


function write_site(str_root, str_tmp)
    % Remove everything except .git, then copy the site.
    sct_items = dir(str_tmp);
    sct_items = sct_items(~ismember({sct_items.name}, {'.', '..', '.git'}));
    for i_item = 1:numel(sct_items)
        str_item = fullfile(str_tmp, sct_items(i_item).name);
        if sct_items(i_item).isdir
            rmdir(str_item, 's');
        else
            delete(str_item);
        end
    end

    copy_or_error(fullfile(str_root, '_GUILDAdoc'), fullfile(str_tmp, '_GUILDAdoc'));
    copy_or_error(fullfile(str_root, 'LICENSE'), fullfile(str_tmp, 'LICENSE'));

    % OS files are ignored in the source branch, but gh-pages has no .gitignore.
    for str_pattern = ["**/.DS_Store", "**/._*", "**/Thumbs.db", "**/ehthumbs.db", "**/Desktop.ini", "**/*.asv"]
        sct_junk = dir(fullfile(str_tmp, '_GUILDAdoc', str_pattern));
        sct_junk = sct_junk(~[sct_junk.isdir]);
        arrayfun(@(s) delete(fullfile(s.folder, s.name)), sct_junk);
    end

    str_index = "<!doctype html>" + newline + ...
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
    write_text(fullfile(str_tmp, 'index.html'), str_index);
    write_text(fullfile(str_tmp, '.nojekyll'), "");
end


function keep_published_index(str_tmp)
    % The exporter stamps generatedAt on every rebuild. Keep the published
    % class index when nothing else in it changed, so an unchanged site
    % makes no commit.
    str_path = '_GUILDAdoc/database/list_Classes.js';
    [r_status, str_old] = system(sprintf('git --no-pager -C %s show HEAD:%s', quote(str_tmp), str_path));
    if r_status ~= 0
        return
    end
    str_new = fileread(fullfile(str_tmp, str_path), 'Encoding', 'UTF-8');
    str_pattern = {'"generatedAt":\s*"[^"]*"', '\r'};
    if strcmp(regexprep(strtrim(str_old), str_pattern, ''), regexprep(strtrim(str_new), str_pattern, ''))
        run_git(str_tmp, sprintf('checkout HEAD -- %s', str_path));
    end
end


function copy_or_error(str_from, str_to)
    [bln_ok, str_msg] = copyfile(str_from, str_to);
    if ~bln_ok
        error('GUILDA:publish_doc:CopyFailed', 'Unable to copy %s: %s', str_from, str_msg);
    end
end


function write_text(str_file, str_content)
    fid = fopen(str_file, 'w', 'n', 'UTF-8');
    if fid == -1
        error('GUILDA:publish_doc:WriteFailed', 'Unable to write %s.', str_file);
    end
    fprintf(fid, '%s', str_content);
    fclose(fid);
end


function remove_worktree(str_root, str_tmp)
    [r_status, ~] = system(sprintf('git --no-pager -C %s worktree remove --force %s', quote(str_root), quote(str_tmp)));
    if r_status ~= 0
        if isfolder(str_tmp)
            rmdir(str_tmp, 's');
        end
        system(sprintf('git --no-pager -C %s worktree prune', quote(str_root)));
    end
end


function str_out = run_git(str_dir, str_args)
    [r_status, str_out] = system(sprintf('git --no-pager -C %s %s', quote(str_dir), str_args));
    if r_status ~= 0
        error('GUILDA:publish_doc:GitFailed', 'git %s failed:\n%s', str_args, str_out);
    end
end


function str_quoted = quote(str_path)
    str_quoted = """" + string(str_path) + """";
end
