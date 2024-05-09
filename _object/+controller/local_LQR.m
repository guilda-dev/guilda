classdef local_LQR < controller
% 一つのcomponentクラスに付加することを想定

    properties(SetAccess=protected)
        type = 'local';
        port_input   = 'all';
        port_observe = 'all';
    end

    properties
        Q
        R
        V0 = 1; % 1 + 0j
    end

    properties(SetAccess = private)
        sys
        DX
    end

    properties(Access = private)
        xss
        uilab
        default_Q
        default_R
    end
    
    methods

        function obj = local_LQR(net, idx, default_Q, default_R, port_input)
            obj@controller(net,idx,idx)

            obj.set_index(idx);
            
            if nargin < 3; default_Q = []; end
            if nargin < 4; default_R = []; end
            if nargin ==5; obj.port_input = port_input; end

            obj.default_Q = default_Q;
            obj.default_R = default_R;
        end

        function nx = get_nx(~)
            nx = 0;
        end

        function initialize(obj)
            xidx = obj.idx_state{1};
            uidx = obj.idx_port{1};
            
            obj.Q = xidx.'* obj.default_Q * xidx  ;
            obj.R = uidx  * obj.default_R * uidx.';

            if ~isempty(obj.Q) && ~isempty(obj.R)
                i = obj.connected_index_observe;
                obj.xss = obj.network.a_bus{i}.component.x_equilibrium;
            end
        end
        
        function [dx, u] = get_dx_u(obj, ~, ~, X, ~, ~, ~)
            dx = [];
            u{1} = obj.system_matrix.DX * (X{1} - obj.xss); % + obj.Du*u_global;
        end
        
        function [A, BX, BV, BI,  Bu, C, DX, DV, DI, Du] = get_linear_matrix(obj)

            idx =  obj.connected_index_observe;

            c = obj.network.a_bus{idx}.component;
            Vst = c.V_equilibrium;
            Ist = c.I_equilibrium;
            
            [A, B, C, D, BV, DV, BI, DI, ~, ~] = c.get_linear_matrix;

            y   = Ist / (Vst - obj.V0);
            y   = tools.complex2matrix(y);
            Bred  = BV + BI*y;
            Dred  = DV + DI*y;
            Acon = A - Bred / Dred * C;
            Bcon = B - Bred / Dred * D;
            Bcon = blkdiag( obj.idx_state{:} ) * Bcon;
                
            K = lqr(Acon, Bcon, obj.Q, obj.R);

            DX = - blkdiag( obj.idx_port{:} ) * K;


            nx = size(DX,2);
            ny = size(DX,1);
            nVI = 2 * numel(obj.connected_index_observe);
            nu = sum(tools.varrayfun(@(i) obj.network.a_bus{i}.component.get_nu, obj.connected_index_input));

            A  = [];
            BX = zeros(0,nx);
            BV = zeros(0,nVI);
            BI = zeros(0,nVI);
            Bu = zeros(0,nu);
            C  = zeros(ny,obj.get_nx);
            DV = zeros(ny,nVI);
            DI = zeros(ny,nVI);
            Du = zeros(ny,nu);

        end

    % インデックスの設定メソッド
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function set_index(obj,idx)
            if isscalar(idx)
                obj.connected_index_input = idx;
                obj.connected_index_observe = idx;
            else
                error('This controller cannot be attached to more than one device.')
            end
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    % 行列Q,RのSetメソッド
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function set.default_Q(obj,Q)
            s = size(Q);
            if any(s==1); Q = diag(Q); 
            elseif s(1)~=s(2); error('Q must be vector or square matrix');
            end
            obj.default_Q = Q;
        end

        function set.default_R(obj,R)
            s = size(R);
            if any(s==1); R = diag(R); 
            elseif s(1)~=s(2); error('R must be vector or square matrix');
            end
            obj.default_R = R;
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    % parameterの設定をUIで行うためのメソッド(開発中)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function set_parameter(obj,fig)
            i = obj.connected_index_input;
            c = obj.network.a_bus{i}.component;
            port = c.get_port_name;
            state = c.get_state_name;

            if nargin<2
                fig = uifigure('Position',[200,200,400,300]);
            end
            uilabel(fig,'Position',[30 260 270 40], ...
                        'Text',class(obj), ...
                        'FontSize',20,...
                        'FontWeight','bold');
            uilabel(fig,'Position',[30 250 270 15], ...
                        'Text',['  connect to 「', class(c),' @bus', num2str(i),'」'], ...
                        'FontSize',12,...
                        'FontWeight','bold');
            obj.uilab = uitextarea(fig,...
                        'Position'  , [50 120 300 120], ...
                        'Value'     , word_factory(obj), ...
                        'FontSize'  , 10,...
                        'FontWeight', 'bold',...
                        'Editable'  , 'on');
            Q_val = diag(obj.Q);
            xtab = table(Q_val);
            xtab.Properties.RowNames = state;
            xtab = uitable(fig, 'Data', xtab, 'Position',[20,10,120,100]);
            xtab.ColumnEditable = true;
            set(xtab, 'CellEditCallback', @obj.refresh_xtab);

            R_val = zeros(numel(obj.uidx),1);
            R_val(obj.uidx) = diag(obj.R);
            check = obj.uidx(:);
            utab = table(check,R_val);
            utab.Properties.RowNames = port;
            utab = uitable(fig, 'Data', utab, 'Position',[150,10,230,100]);
            utab.ColumnEditable = [true,true];
            s = uistyle('BackgroundColor',[0.8 0.8 0.8]);
            addStyle(utab,s,'cell',[find(~obj.uidx(:)),2*ones(sum(~obj.uidx),1);find(~obj.uidx(:)),ones(sum(~obj.uidx),1)]);
            set(utab, 'CellEditCallback', @obj.refresh_utab);
        end

        function refresh_xtab(obj, tab, ~)
            obj.set_Q(tab.Data{:,1})
            obj.uilab.Value = word_factory(obj);
        end
        function refresh_utab(obj, tab, data)
            if data.Indices(2)==1
                idx = tab.Data{:,1};
                k = uistyle('BackgroundColor',[0.7 0.7 0.7]);
                w = uistyle('BackgroundColor',[1 1 1]);
                addStyle(tab,k,'cell',[find(~idx),2*ones(sum(~idx),1);find(~idx),ones(sum(~idx),1)]);
                addStyle(tab,w,'cell',[find(idx) ,2*ones(sum(idx),1) ;find(idx) ,ones(sum(idx),1)]);
                obj.uidx = idx;
            end
            obj.set_R(tab.Data{:,2}(obj.uidx));
            obj.uilab.Value = word_factory(obj);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end

end

function word = word_factory(obj)
    Kword = evalc('vpa(obj.DX(obj.uidx,:),2)');
    idx   = find(Kword == newline);
    Kword =  Kword(idx(3)+1:end);
    Kword = strrep(Kword,newline,[newline,repmat(sprintf('\t'),1,2)]);
    word  = ['>> Q = diag(',mat2str(diag(obj.Q)),')',newline,...
             '>> R = diag(',mat2str(diag(obj.R)),')',newline,...
             newline,...
             '%% Solve for LQR based on matrices Q and R %%', newline,...
             newline,...
             '>> K = ',Kword];
end
