classdef gridcode < handle

    properties(SetAccess=protected)
        observe = true;
        control = false;
        OutputFcn
    end

    properties(Dependent)
        tlim
    end

    properties(Access=protected)
        parent % odefactoryクラスの格納
    end


    properties(SetAccess=private)
        record = struct('time',[],'mac',struct,'branch',struct,'controller',struct);
    end

    properties(Access = protected)

        % ネットワークの情報を格納
        flag_HasCode   = struct('mac',[],'branch',[],'lcon',[],'gcon',[])
        flag_calculated= struct('mac',[],'branch',[],'lcon',[],'gcon',[])

        % プロットで使用するプロパティ
        axGraph
    end

    methods
        function obj = gridcode(net, tlim, mode)
            arguments
                net
                tlim
                mode {mustBeMember(mode,{'ignore','monitor','control'})} = 'ignore';
            end

            obj.parent = net;
            obj.tlim   = [tlim(1),tlim(end)];
            
            % モードの設定
            switch mode
                case 'ignore'
                    obj.observe = false;
                    obj.control = false;
                case 'monitor'
                    obj.observe = true;
                    obj.control = false;
                case 'control'
                    obj.observe = true;
                    obj.control = true;
            end
        end

        function initialize(obj)
            if obj.observe
                net = obj.parent.network;
    
                % グリッドコードを持っている機器・制御器・ブランチを取得
                if obj.observe
                    check = @(cls) isa(cls.grid_code,'function_handle') && strcmp(cls.parallel,'on');
                    obj.flag_HasCode.mac  = tools.vcellfun( @(c) check(c.component), net.a_bus              );
                    obj.flag_HasCode.bra  = tools.vcellfun( @(c) check(c)          , net.a_branch           );
                    obj.flag_HasCode.lcon = tools.vcellfun( @(c) check(c)          , net.a_controller_local );
                    obj.flag_HasCode.gcon = tools.vcellfun( @(c) check(c)          , net.a_controller_global);
                else
                    obj.flag_HasCode.mac  = false(numel(net.a_bus              ),1);
                    obj.flag_HasCode.bra  = false(numel(net.a_branch           ),1);
                    obj.flag_HasCode.lcon = false(numel(net.a_controller_local ),1);
                    obj.flag_HasCode.gcon = false(numel(net.a_controller_global),1);
                end
    
                % 計算すべき制御器のインデックスを取得
                  VIList = obj.flag_HasCode.mac;
                 macList = obj.flag_HasCode.mac;
                lconList = obj.flag_HasCode.lcon;
                gconList = obj.flag_HasCode.gcon;
    
                    % ブランチが
                    with_branch = tools.vcellfun(@(br) [br.from;br.to], net.a_branch(obj.flag_HasCode.bra) );
                    VIList(unique(with_branch,'sorted') ) = true;
        
    
                obj.flag_calculated.VI   = VIList;
                obj.flag_calculated.mac  = macList;
                obj.flag_calculated.lcon = lconList;
                obj.flag_calculated.gcon = gconList;

                obj.OutputFcn = @obj.Fcn;
            else
                obj.OutputFcn = @(t,y,flag) true;
            end
        end

        function out = get.tlim(obj)
            out = obj.parent.time;
        end


        %%%%%%%%%%%%%%%%%%%%%  odeソルバー内でEventFcnとして実行される関数　%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [value,isterminal,direction] = Fcn(obj,t)
            if obj.observe
                obj.record.time = [obj.record.time;t];
                change_mac = obj.judge_gridcode(t, 'mac'       ,obj.vargin.mac       );
                change_bra = obj.judge_gridcode(t, 'branch'    ,obj.vargin.branch    );
                change_con = obj.judge_gridcode(t, 'controller',obj.vargin.controller);
                value = ~(change_mac||change_bra||change_con);
            end
            
            isterminal = true;
            direction  = [];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%　  解析中のライブ用メソッド　　%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function garaph_init(obj)
            net = obj.parent;
            figure('Position',[400,300,1700,850]);
            ax = subplot(1,3,[1,2]);
            obj.Graph = supporters.for_graph.map_forAnime2(net,ax);

        end


    end
end


