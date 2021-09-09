classdef branch_pi < branch
    
    properties(SetAccess = private)
       x
       y
    end
    
    methods
        function obj = branch_pi(from, to, x, y)
           obj@branch(from, to);
           if numel(x) == 2
               x = x(1) + 1j*x(2);
           end
           obj.x = x;
           obj.y = y;
        end
        
        function Y = get_admittance_matrix(obj)
            x = obj.x;
            y = obj.y;
            Y = [1j*y+1/x,     -1/x;
                     -1/x, 1j*y+1/x ];
        end
    end
    
end