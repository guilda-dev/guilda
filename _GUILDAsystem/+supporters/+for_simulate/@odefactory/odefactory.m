classdef odefactory < handle
    
    properties
        time            %開始時間/終了時間を格納
        network         %networkクラスを格納

        % 外部からシミュレーション条件を割り込みで入れる際に使用する
        additional_V0bus  = [];
        additional_I0bus  = [];
        additional_odeopt = {};

        % 必ずシミュレーションする必要のある時間ステップ（離散システムや遅れ時間系などの切り替え時点）
        tstep

        % このプロパティがtrueになるとodeソルバーが一度終了し、次のサイクル(while分のループ)に進む
        ToBeStop = false;
    end

    properties(SetAccess=protected)
        options
        Reporter
        StateProcessor
    end

  
    methods
        dx  = fx(obj, t, x)
        out = run(obj)
        f   = EventFcn(obj,varargin)

        function obj = odefactory(net, t, varargin)
            obj.time = [t(1),t(end)];
            obj.network  = net;

            if nargin < 3 || isstruct(varargin{1}) || ischar(varargin{1})
                obj.options = supporters.for_simulate.OptionFactory(obj,t,net,[],[],varargin{:});
            else
                obj.options = supporters.for_simulate.OptionFactory(obj,t,net,varargin{:});
            end
            obj.StateProcessor = supporters.for_simulate.StateProcessor(net,obj.options.initial);
            
            % Todoリスト
            % obj.Reporter       = supporters.for_simulate.reporter.Factory_Reporter(net,obj.options);
        end 

        function add_fault(obj,varargin)
            obj.options.fault.add(varargin{:})
        end

        function add_parallel(obj,varargin)
            obj.options.parallel.add(varargin{:})
        end

        function add_input(obj,varargin)
            obj.options.input.add(varargin{:})
        end

    end

end


