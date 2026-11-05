function [A, BX, BV, BI, Bu, C, DX, DV, DI, Du] = get_linear_matrix(obj)
% Return empty state-space matrices so that a simulation can run.
    arguments (Input)
        obj
    end
    arguments (Output)
        A  % Empty matrix.
        BX % Empty matrix.
        BV % Empty matrix.
        BI % Empty matrix.
        Bu % Empty matrix.
        C  % Empty matrix.
        DX % Empty matrix.
        DV % Empty matrix.
        DI % Empty matrix.
        Du % Empty matrix.
    end
    % シミュレーションを実行できるようにするための一時的な実装なので要修正
    A = [];
    BX = [];
    BV = [];
    BI = [];
    Bu = [];
    C = [];
    DX = [];
    DV = [];
    DI = [];
    Du = [];
end
