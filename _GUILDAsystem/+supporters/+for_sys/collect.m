function sys = collect(sys)
%
% Combine overlapping port names into a single port.
%
%  u1 --> ┌-----┐ --> y1
%  u2 --> | SYS | --> y1
%  u2 --> |     | --> y2
%  u3 --> └-----┘ --> y3
%
%           v
%           v
%
%  u1 --> ┌--------┐ --> u1 --> ┌-----┐ --> y1 --> ┌--------┐ --> y1 
%  u2 --> |   in   | --> u2 --> | SYS | --> y1 --> |  out   | --> y2
%  u3 --> | filter | --> u2 --> |     | --> y2 --> | filter | --> y3
%         └--------┘ --> u3 --> └-----┘ --> y3 --> └--------┘  
%
%>> in filter
%
% |u1|   |1,0,0| |u1|
% |u2| = |0,1,0|*|u2|
% |u2|   |0,1,0| |u3|
% |u3|   |0,0,1|
%
%
%>> out filter
%
% |y1|  |+1,+1, 0, 0| |y1|
% |y2|= | 0, 0, 1, 0|*|y1|
% |y3|  | 0, 0, 0, 1| |y2|
%                     |y3|
%

    m = @(a) 1:numel(a);
    
    [~,ia,ic] = unique(sys.InputName);
    [~,oa,oc] = unique(sys.OutputName);

    out_filter = ss( m(oa)'== oc'   );
    in_filter  = ss(    ic == m(ia) );

    sys_temp = sys(oa,ia);
    sys      = out_filter * sys * in_filter;

    prop = properties(sys);
    for i = 1:numel(prop)
        propi = prop{i};
        if ~ismember(propi,{'A','B','C','D','E'})
            sys.(propi) = sys_temp.(propi);
        end
    end

end