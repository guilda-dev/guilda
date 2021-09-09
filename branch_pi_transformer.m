classdef branch_pi_transformer < branch
    
    properties(SetAccess = private)
        x
        y
        tap
        phase
    end
    
    methods
        function obj = branch_pi_transformer(from, to, x, y, tap, phase)
            obj@branch(from, to);
            if numel(x) == 2
                x = x(1) + 1j*x(2);
            end
            obj.x = x;
            obj.y = y;
            obj.tap = tap;
            obj.phase = phase;
        end
        
        function Y = get_admittance_matrix(obj)
            x = obj.x;
            y = obj.y;
            tap = obj.tap;
            phase = obj.phase;
            Y = [(1j*y+1/x)/tap^2, -1/x/tap/exp(-1j*phase);
                -1/x/tap/exp(1j*phase), 1j*y+1/x ];
        end
    end
    
end