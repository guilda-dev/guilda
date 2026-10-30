classdef local_LQR < LocalController
% LQR state-feedback controller for one component.
% The controller observes the state `X` of the component it is attached to and
% feeds back `u = DX*(X - xss)` to the component's input ports, where `xss` is the
% equilibrium state. The gain is designed with `lqr` on the component linearized
% at its equilibrium and connected to an infinite bus of voltage `V0` [pu]. It has
% no state of its own.
%
% This class uses the GUILDA v2 controller interface (`connected_index_*`,
% `get_dx_u`, `get_linear_matrix`); it does not implement the abstract methods
% of LocalController (`fcn_dx`, `fcn_y`, `fcn_Mass`, `Jacobi_dx`, `Jacobi_Y`).
%
% See also controller.local_LQR_retrofit

    properties(SetAccess=protected) % Configuration
        type = 'local'; % Controller type ('local').
        port_input   = 'all'; % Input ports of the component that the controller drives.
        port_observe = 'all'; % Observed ports of the component.
    end

    properties % Design weights
        Q % State weight matrix of the LQR.
        R % Input weight matrix of the LQR.
        V0 = 1; % [pu] Infinite-bus voltage used for the design (1 + 0j).
    end

    properties(SetAccess = private) % Design results
        sys % Reserved for the controller's state-space model; not set by this class.
        DX % Feedback gain from the component state to its input.
    end

    properties(Access = private) % Internal
        xss
        uilab
        default_Q
        default_R
    end
    
    methods

        function obj = local_LQR(net, idx, default_Q, default_R, port_input)
            % Create an LQR controller for the component at one bus.
            %
            % Inputs:
            % - `net` Network in the GUILDA v2 format.
            % - `idx` Index of the bus whose component is controlled (one bus only).
            % - `default_Q` State weights, a vector (diagonal) or a square matrix (default []).
            % - `default_R` Input weights, a vector (diagonal) or a square matrix (default []).
            % - `port_input` Input ports to drive (default 'all').
            arguments (Output)
                obj % local_LQR object.
            end
            obj@LocalController(net,idx,idx)

            obj.set_index(idx);
            
            if nargin < 3; default_Q = []; end
            if nargin < 4; default_R = []; end
            if nargin ==5; obj.port_input = port_input; end

            obj.default_Q = default_Q;
            obj.default_R = default_R;
        end

        function nx = get_nx(~)
            % Return the number of controller states (0).
            arguments (Output)
                nx % Number of states.
            end
            nx = 0;
        end

        function initialize(obj)
            % Set the weights Q and R and the equilibrium state of the controlled component.
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
            % Return the feedback input `u = DX*(X - xss)` for the component state `X`.
            %
            % Outputs:
            % - `dx` Empty state derivative (the controller has no state).
            % - `u` Cell array with the input to the component.
            dx = [];
            u{1} = obj.system_matrix.DX * (X{1} - obj.xss); % + obj.Du*u_global;
        end
        
        function [A, BX, BV, BI,  Bu, C, DX, DV, DI, Du] = get_linear_matrix(obj)
            % Design the LQR gain and return the state-space matrices of the controller.
            % The controller has no state, so only `DX` (the feedback gain) is nonzero.
            arguments (Output)
                A  % State matrix (empty).
                BX % Input matrix for the component state.
                BV % Input matrix for the bus voltage.
                BI % Input matrix for the bus current.
                Bu % Input matrix for the global input.
                C  % Output matrix.
                DX % Feedback gain from the component state to its input.
                DV % Feedthrough from the bus voltage.
                DI % Feedthrough from the bus current.
                Du % Feedthrough from the global input.
            end

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
            % Set the bus index of the controlled component.
            % An error is raised when `idx` has more than one element.
            %
            % Inputs:
            % - `idx` Index of the bus whose component is controlled.
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
            % Open a UI to edit the weights Q and R and show the resulting gain.
            %
            % Inputs:
            % - `fig` UI figure to draw in (default: a new uifigure).
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
            % Update Q from the state weight table of set_parameter (UI callback).
            obj.set_Q(tab.Data{:,1})
            obj.uilab.Value = word_factory(obj);
        end
        function refresh_utab(obj, tab, data)
            % Update R and the driven inputs from the input table of set_parameter (UI callback).
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
    % Gain matrix with 2 significant digits, one "[a, b, ...]" row per line
    K     = obj.DX(obj.uidx,:);
    Krows = arrayfun(@(i) ['[',strjoin(compose('%.2g',K(i,:)),', '),']',newline], ...
                     1:size(K,1), 'UniformOutput', false);
    Kword = ['', Krows{:}];
    Kword = strrep(Kword,newline,[newline,repmat(sprintf('\t'),1,2)]);
    word  = ['>> Q = diag(',mat2str(diag(obj.Q)),')',newline,...
             '>> R = diag(',mat2str(diag(obj.R)),')',newline,...
             newline,...
             '%% Solve for LQR based on matrices Q and R %%', newline,...
             newline,...
             '>> K = ',Kword];
end
