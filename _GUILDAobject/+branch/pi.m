classdef pi < Branch

    properties(Constant)        
        key = "pi"
    end

    methods(Access={?PowerNetwork})
        function obj = pi(index, varargin)
            obj@Branch("EL"+index, varargin{:})
        end
    end

    methods
        function Ymat = get_admittance_matrix(obj)
            para  = obj.para_dynamics;
            yij   = 1/(para.R+1j*para.X);
            cij   = 1j * para.C;
            Ymat  = [ cij+yij,    -yij ;
                         -yij, cij+yij ];
        end
    end
    
    % methods        
    %     function [sv_x, s_cI, s_cV] = get_odeVars(obj)
    %         sv_x = sym( obj.attach_tag( ["Vre";"Vim"] ) );
    %         s_cI = sym( obj.attach_tag( "Iphaser" ) );
    %         s_cV = sym( obj.attach_tag( "Vphaser" ) );                       
    %     end
    %     function [dict_Diff, dict_IO, dict_x0, dict_M, dict_para] = get_odefcn(obj, cls, dict_Diff, dict_IO, dict_x0, dict_M, dict_para, opt)
    %         arguments
    %             obj 
    %             cls
    %             dict_Diff (1,1) dictionary = dictionary
    %             dict_IO   (1,1) dictionary = dictionary
    %             dict_x0   (1,1) dictionary = dictionary
    %             dict_M    (1,1) dictionary = dictionary
    %             dict_para (1,1) dictionary = dictionary
    %             opt.controller (1,1) logical = false
    %         end
    %         if opt.controller
    %             % nothing
    %         end
    %         bus = obj.a_Bus;
    %         cub = obj.a_Cubicle;
    %         [bsv_x,bs_cI,cs_cI,bs_cV,bs_is] = deal(cell(numel(bus),1));            
    %         for i=1:numel(bus)
    %             [svb_x, sb_cI, sb_cV, sb_isfault] = bus{i}.get_odeVars();      
    %             [    ~, sc_cI,     ~,          ~] = cub{i}.get_odeVars();
    %             bsv_x{i} = svb_x;
    %             bs_cI{i} = sb_cI;
    %             cs_cI{i} = sc_cI;
    %             bs_cV{i} = sb_cV;                
    %             bs_is{i} = sb_isfault;                
    %         end                       
    %         [svb_x, sb_cI, sb_cV] = obj.get_odeVars();
    %         obj.rm_odeMass = obj.get_symMass();            
    %         obj.fv_odeDiff = obj.get_symDiff();
    %         obj.fv_odeOut  = obj.get_symOut();
    %         obj.fv_odeI    = obj.get_symI([], [], bs_cV, bs_cI, []);
    %         % mass
    %         dict_M = dict_M.insert([], obj.rm_odeMass);            
    %         % input and output               
    %         r_tag = cls.a_Bus.str_tag;
    %         p_tag = cellfun(@(d) string(d.a_Bus.str_tag), obj.a_Cubicle);
    %         l_tag = r_tag==p_tag;
    %         Vphaser = (1-cell2mat(bs_is)).*cellfun(@(d) [1,1j]*d, bsv_x);            
    %         Iphaser = subs(obj.fv_odeI, cell2mat(bs_cV), Vphaser);         
    %         dict_IO(cs_cI{l_tag}) = Iphaser(l_tag);            
    %         dict_IO = dict_IO.insert(sb_cI, Iphaser(l_tag));
    %         dict_IO = dict_IO.insert(sb_cV, Vphaser(l_tag));
    %         % initial value
    %         Veq = obj.cv_Vequilibrium(l_tag);
    %         dict_x0 = dict_x0.insert(svb_x, [real(Veq);imag(Veq)]);            
    %         % differential equation 
    %         dict_Diff = dict_Diff.insert([], obj.fv_odeDiff);                       
    %     end
    % end
    
end