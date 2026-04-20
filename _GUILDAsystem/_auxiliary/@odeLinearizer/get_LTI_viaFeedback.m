function [A, B, C, D] = get_LTI_viaFeedback(obj)           
              
   bus = obj.odeNetwork.a_Bus;          
   n_bus = numel(bus);

   A = cell(n_bus,1);
   B = cell(n_bus,1);
   C = cell(n_bus,1);
   D = cell(n_bus,1);
   
   odeInputNames  = {};           
   odeOutputNames = {};           
   netInputNames  = {};           
   netOutputNames = {};
              
   for i=1:n_bus
       comp = bus{i}.a_Component;
       ncom = numel(comp);

       Ax = cell(1,ncom);
       Av = cell(1,ncom);
       Bu = cell(1,ncom);
       Cx = cell(1,ncom);
       Cv = cell(1,ncom);
       Du = cell(1,ncom);

       idx = 1;
       while idx<=ncom
           
           if ~bus{i}.l_isNonUnit
               sslin = comp{idx}.odeLinearSystem;

               lg_Bv = ismember(fieldnames(sslin.InputGroup), ["Vre","Vim"]+"_"+comp{idx}.str_tag);                       

               Cv{idx} = sslin.D(:, lg_Bv)^-1;
               Cx{idx} = -Cv{idx} * sslin.C;                                      
               Du{idx} = -Cv{idx} * sslin.D(:,~lg_Bv);
               Av{idx} = sslin.B(:, lg_Bv)*Cv{idx};
               Ax{idx} = sslin.A - Av{idx}*Cv{idx}*Cx{idx};                       
               Bu{idx} = -Av{idx} * Cv{idx} * Du{idx} + sslin.B(:,~lg_Bv);                                                                                                                   
               
               
               if idx == 1
                   arrayfun(@(S) attach_itag(S,"ode"), ["Ire","Iim"]+"_"+bus{i}.str_tag);                               
                   arrayfun(@(S) attach_itag(S,"net"), ["Ire","Iim"]+"_"+bus{i}.str_tag);    
                   arrayfun(@(S) attach_otag(S,"ode"), ["Vre","Vim"]+"_"+bus{i}.str_tag);                       
                   arrayfun(@(S) attach_otag(S,"net"), ["Vre","Vim"]+"_"+bus{i}.str_tag);                       
               end

               u_idx = reshape(comp{idx}.str_u+"_"+comp{idx}.str_tag, 1, []); 
               arrayfun(@(S,N) attach_itag(S,"ode"), u_idx);                       
                                          
           end                   
           idx = idx + 1;                       
       end                              
       

       A{i} =  blkdiag(Ax{:});
       B{i} = [vertcat(Av{:}), blkdiag(Bu{:})];
       C{i} =  horzcat(Cx{:});
       D{i} = [plus(Cv{:}), horzcat(Du{:})];
   end

   SS = diag(A, B, C, D);

   nx = size(SS{1},2);
   nu = size(SS{2},2);
   SS{3}  = [eye(nx); SS{3}];           
   SS{4}  = [zeros(nx,nu);SS{4}];

   ss_ode = ss(SS{:});           

   [port_i, port_o] = get_IO_port();
   ss_ode.InputName   = odeInputNames;
   ss_ode.OutputName  = [port_o; odeOutputNames];

   Ymat = complex2matrix( obj.odeNetwork.get_admittance_matrix.Variables );           
   
   % ss_net = ss(-Ymat);           
   ss_net = ss(Ymat);           
   ss_net.InputName  = netInputNames;           
   ss_net.OutputName = netOutputNames;

   sys = connect(ss_ode, ss_net, port_i, port_o);

   sys.InputName  = port_i;
   sys.OutputName = port_o;
   sys.StateName  = port_o;

   A = sys.A;
   B = sys.B;
   C = sys.C;
   D = sys.D;

   obj.odeLinearSystem = sys;


   function attach_itag(str, opt)
       switch opt
           case "ode"                       
               odeInputNames = [odeInputNames; {char(str)}];               
           case "net"                       
               netOutputNames = [netOutputNames; {char(str)}];
       end               
   end

   function attach_otag(str, opt)
       switch opt
           case "ode"                       
               odeOutputNames = [odeOutputNames; {char(str)}];               
           case "net"                       
               netInputNames = [netInputNames; {char(str)}];               
       end               
   end

   function dmat = diag(varargin)
       dmat = cellfun(@(M) blkdiag(M{:}), varargin, 'UniformOutput', false);               
   end

   function l = ismember(arg1, arg2)
       narg = length(arg2);
       lmat = zeros(length(arg1),narg);
       for argi = 1:numel(arg2)
           lmat(:,argi) = strcmp(arg1,arg2(argi));
       end

       l = logical( sum(lmat,2) );
   end
   
   function Mat = plus(varargin)
       if nargin == 1
           Mat = varargin{:};
       else
           Mat = zeros(size(varargin{1}));
           for argi=1:nargin
               Mat = Mat + varargin{argi};
           end
       end
   end

   function Mat = complex2matrix(mat)

       Mat = cell2mat( arrayfun(@(M) [real(M), -imag(M); imag(M), real(M)], mat, 'UniformOutput', false) );                             
       lg = true(numel(obj.odeNetwork.a_Bus),1);
       lg(obj.odeNonUnitBus) = false;
       lg = logical( kron(lg,ones(2,1)) );
       Mat = Mat(lg,lg) - Mat(lg,~lg) * Mat(~lg,~lg)^-1 * Mat(~lg,lg);
   end

   function [input, output] = get_IO_port()
       BUS = obj.odeNetwork.a_Bus;

       input  = cell(numel(BUS),1);
       output = cell(numel(BUS),1);
       for argi = 1:numel(BUS)
           COMP = BUS{argi}.a_Component;

           str_x = [];
           str_u = [];                   
           if argi ~= obj.odeNonUnitBus
               str_x = cell2mat( cellfun(@(C) C.str_x + "_" + C.str_tag, COMP, 'UniformOutput', false) );
               str_u = cell2mat( cellfun(@(C) C.str_u + "_" + C.str_tag, COMP, 'UniformOutput', false) );                                          
           end

           input{argi}  = str_u;
           output{argi} = str_x;
       end

       input  = cell2mat(input);
       output = cell2mat(output);
   end

end