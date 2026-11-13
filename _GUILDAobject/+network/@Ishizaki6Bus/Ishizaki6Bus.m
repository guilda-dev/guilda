classdef Ishizaki6Bus < PowerNetwork
% 6-bus test system with two classical generators.
% It has 6 buses, 2 generators (gen-classical) at buses 1 and 5 and 4 loads
% (load-power) at buses 2, 3, 4 and 6 (the loads at buses 2 and 4 have zero
% power), on a 100 MVA base. The original data (`branch_origin`) have 7 pi
% lines; lines 1-2, 1-3, 2-3 and 2-4 are lossless, and the resistance of lines
% 4-5, 4-6 and 5-6 is set to `alpha` times their reactance. The `line` option
% removes lines 2-3 and 4-6.
%
% The constructor writes the resulting branch table to a temporary folder and
% reads the network from there, so the class folder does not change. The tracked
% `branch/parameter.csv` keeps the default setting as a reference.
%
% <@Examples>
% Build the network with different line settings and simulate a rotor-angle offset
% of the generator at bus 1:
%
% ```matlab
% net = network.Ishizaki6Bus();                % R = X on lines 4-5, 5-6; no 2-3, 4-6
% net = network.Ishizaki6Bus(0.1, line="None"); % R = 0.1*X; all 7 lines
% res = net.calculate_powerflow();
% sc  = net.add_scenario("offset");
% sc.add_offset("B001SG1", "delta", 0.1, 1);
% sol = net.simulate("offset");
% ```
%
% See also network.Txt3Bus

 
    properties(Constant) % Data
        ver = 1  % Version of the bundled network data.
    end

    methods
        function obj = Ishizaki6Bus(alpha,opt)
            % Create the network with the given resistance ratio and lines.
            arguments (Input)
                alpha (1,1) double = 1; % [pu/pu] Ratio R/X of lines 4-5, 4-6 and 5-6.
                opt.line {mustBeMember(opt.line, {'L23','L46','Both','None'})} = 'Both' % Lines to remove: 'L23' (2-3), 'L46' (4-6), 'Both' or 'None'.
            end            
            arguments (Output)
                obj % Ishizaki6Bus network.
            end
            s_filepath = mfilename("fullpath");

            new_path = replace(s_filepath,[filesep,'Ishizaki6Bus'],'');
            bra_path = [new_path,[filesep,'branch_origin',filesep,'parameter.csv']];

            tab_branch = readtable(bra_path);

            tab_branch.R(5:end) = tab_branch.X(5:end) * alpha;            
            FromTo = tab_branch{:,["From","To"]};            
    
            switch opt.line
                case 'L23'
                    lv_FT = ismember(FromTo,[2,3],"rows");
                    tab_branch = tab_branch(~lv_FT,:);
                case 'L46'
                    lv_FT = ismember(FromTo,[4,6],"rows");
                    tab_branch = tab_branch(~lv_FT,:);
                case 'Both'
                    lv_FT = ismember(FromTo,[2,3;4,6],"rows");
                    tab_branch = tab_branch(~lv_FT,:);
                case 'None'
            end
            
            s_tmp = tempname;
            mkdir(fullfile(s_tmp,'branch'));
            c_tmp = onCleanup(@() rmdir(s_tmp,'s'));
            copyfile(fullfile(new_path,'bus'),fullfile(s_tmp,'bus'));
            copyfile(fullfile(new_path,'component'),fullfile(s_tmp,'component'));
            writetable(tab_branch,fullfile(s_tmp,'branch','parameter.csv'));

            PowerNetwork.import(s_tmp, Network=obj);
        end
    end
end
