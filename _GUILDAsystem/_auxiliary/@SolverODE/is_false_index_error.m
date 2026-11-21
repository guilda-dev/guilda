function l = is_false_index_error(ctx, me)
% With sparse matrices, the index check of the solver can fail for a DAE of index 1:
% condest of the sparse algebraic block can be far above the true condition number
% (daeic12 tests eps*nnz(J)*condest(J) > 1). A DAE of a higher index fails with
% dense matrices too, and that error is reported.
    arguments (Input)
        ctx                    % Context of the run.
        me   (1,1) MException  % Error of the solver.
    end
    arguments (Output)
        l  (1,1) logical  % True when the error is a false index error of the sparse matrices.
    end
    l = ctx.l_sparse && endsWith(string(me.identifier), ":IndexGTOne");
end
