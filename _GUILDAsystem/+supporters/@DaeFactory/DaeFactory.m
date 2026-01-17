classdef DaeFactory < handle
    properties
        Comment
    end
    
    properties(SetAccess=protected)
        % variables
        x     (:,1) sym
        u     (:,1) sym
        y     (:,1) sym

        % equilibrium
        xst   (:,1) double
        ust   (:,1) double
        yst   (:,1) double

        % Mass matrix
        Mass

        % dynamics
        eq_diff   (:,1) sym = [];
        eq_output (:,1) sym = [];
        eq_const  (:,1) sym = [];

        % index(logical)
        x_id (:,:) logical
        u_id (:,:) logical
        y_id (:,:) logical
    end

    methods
        new = blkdiag(obj,varargin)
        sys = get_sys(obj,with_controller)
        out = get_dae(obj,time,x0,opt)
    end

    methods
        function obj = DaeFactory(sv_stateVariables, sv_inputVariables, sv_outputVariables, opt)
            arguments
                sv_stateVariables     (:,1) sym = [];
                sv_inputVariables     (:,1) sym = [];
                sv_outputVariables    (:,1) sym = [];
                opt.VariableTypes     (:,1) string {mustBeMember(opt.VariableTypes,["algebraic","state"])}= "state";
                opt.idx_state         (:,:) logical = true(size(sv_stateVariables));
                opt.idx_input         (:,:) logical = true(size(sv_inputVariables));
                opt.idx_output        (:,:) logical = true(size(sv_outputVariables));
            end
            obj.x   = sv_stateVariables;
            obj.u   = sv_inputVariables;
            obj.y   = sv_outputVariables;

            obj.x_id = opt.idx_state;
            obj.u_id = opt.idx_input;
            obj.y_id = opt.idx_output;

            obj.set_equilibrim;
        end

        function set_equilibrim(obj, rv_stateEquilibrium, rv_inputEquilibrium, rv_outputEquilibrium)
            arguments
                obj
                rv_stateEquilibrium     (:,1) double = zeros(size(obj.x));
                rv_inputEquilibrium     (:,1) double = zeros(size(obj.u));
                rv_outputEquilibrium    (:,1) double = zeros(size(obj.y));
            end
            assert(numel( rv_stateEquilibrium)==numel(obj.x),config.lang("状態の配列数が変数名と一致しません。","Number of state arrays does not match variable name."))
            assert(numel( rv_inputEquilibrium)==numel(obj.u),config.lang("入力の配列数が変数名と一致しません。","Number of input arrays does not match variable name."))
            assert(numel(rv_outputEquilibrium)==numel(obj.y),config.lang("出力の配列数が変数名と一致しません。","Number of output arrays does not match variable name."))
            obj.xst   = rv_stateEquilibrium;
            obj.ust   = rv_inputEquilibrium;
            obj.yst   = rv_outputEquilibrium;
        end

        function set_equations(obj, fcn_diff, fcn_output, fcn_const, opt)
            arguments
                obj 
                fcn_diff   (:,1) sym = sym(zeros(size(obj.x)))
                fcn_output (:,1) sym = sym(zeros(size(obj.y)))
                fcn_const  (:,1) sym = zeros(0,1);
                opt.Mass   (:,:) logical
            end
            assert( numel(fcn_diff)  ==numel(obj.x), config.lang("微分方程式の個数が状態変数と一致しません。","The number of differential equations does not match the state variable."))
            assert( numel(fcn_output)==numel(obj.y), config.lang("出力方程式の個数が出力ポート数と一致しません。","The number of output equations does not match the output ports."))

            sv_varDiff   = symvar(fcn_diff);
            sv_varOutput = symvar(fcn_output);
            sv_varConst  = symvar(fcn_const);

            sv_allState  = [ obj.x; obj.u];
            lv_hasDiff   = ismember(sv_varDiff  , sv_allState);
            lv_hasout    = ismember(sv_varOutput, sv_allState);
            lv_hasConst  = ismember(sv_varConst , sv_allState);

            str_unknown  = tools.hcellfun(@(c) [char(c),','], sv_varDiff(lv_hasDiff));
            assert(any(lv_hasDiff), config.lang("状態方程式に未知の変数("+str_unknown(1:end-1)+")が含まれています。", "The state equation contains an unknown variable ("+str_unknown(1:end-1)+").") )

            str_unknown  = tools.hcellfun(@(c) [char(c),','], sv_varOutput(lv_hasout));
            assert(any(lv_hasout), config.lang("出力方程式に未知の変数("+str_unknown(1:end-1)+")が含まれています。", "The output equation contains an unknown variable ("+str_unknown(1:end-1)+").") )

            str_unknown  = tools.hcellfun(@(c) [char(c),','], sv_varConst(lv_hasConst));
            assert(any(lv_hasout), config.lang("制約条件式に未知の変数("+str_unknown(1:end-1)+")が含まれています。", "The constraint equation contains an unknown variable ("+str_unknown(1:end-1)+").") )

            obj.eq_diff   = fcn_diff;
            obj.eq_output = fcn_output;
            obj.eq_const  = fcn_const;

            szM = size(opt.Mass);
            nx  = numel(obj.x);
            assert(all(szM==nx),config.lang("配列の行数と列数はともに状態変数の個数と一致する必要があります。","The number of rows and columns in the array must both match the number of state variables."))
            obj.Mass = opt.Mass;
        end

    end
end
