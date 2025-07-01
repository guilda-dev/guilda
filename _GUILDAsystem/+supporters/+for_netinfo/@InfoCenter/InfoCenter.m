classdef InfoCenter < handle

    properties
        network_handle
    end

    properties(SetAccess=protected)
        data
    end

    methods
        fprintf(obj,lang)

        function obj = InfoCenter(net)
            obj.network_handle = net;
            obj.initialize;
        end

        function data = initialize(obj)
            data = struct;
            data.bus    = obj.busdata;
            data.branch = obj.branchdata;

            data.component = obj.macdata;
            de.component = obj.uni_state('mac');
            du.component = obj.uni_port('mac');
            dp.component = obj.uni_parameter('mac');

            
            data.controller_local = obj.lcondata;
            de.controller_local = obj.uni_state('cl');
            dp.controller_local = obj.uni_parameter('cl');
            
            data.controller_global = obj.gcondata;
            de.controller_global = obj.uni_state('cg');
            dp.controller_global = obj.uni_parameter('cg');

            data.x_equilibrium = de;
            data.u_equilibrium = du;
            data.parameter   = dp;

            obj.data = data;
        end

        function tab = uni_state(obj,mlg)
            switch mlg
                case 'mac'
                    func = @(c) reshape(c.x_equilibrium,1,[]);
                    rowname = "mac";
                case {'cl','cg'}
                    func = @(c) reshape(c.get_x0,1,[]);
                    rowname = "con";
            end

            tab = obj.uni_tab(func,@(c)c.get_state_name,mlg);
            tab.Properties.RowNames = rowname+(1:size(tab,1));
        end

        function tab = uni_port(obj,mlg)
            switch mlg
                case 'mac'
                    func = @(c) reshape(c.u_equilibrium,1,[]);
                    rowname = "mac";
                case {'cl','cg'}
                    tab = [];return
            end
            tab = obj.uni_tab(func,@(c)c.get_port_name,mlg);
            tab.Properties.RowNames = rowname+(1:size(tab,1));
        end

        function tab = uni_parameter(obj,mlg)
            vars = unique(obj.broadcast(@(c)c.parameter.Properties.VariableNames(:),mlg),'stable');
            tab = horztab(obj.broadcast(@(c) {c.parameter},mlg),vars);
        end


        %% Get method : Class Names
        function out = get_names_component(obj)
            out = tools.vcellfun(@(b) string(class(b.component)), obj.a_bus);
        end
        function out = get_names_bus(obj)
            out = tools.vcellfun(@(b) string(class(b)), obj.a_bus);
        end
        function out = get_names_branch(obj)
            out = tools.vcellfun(@(b) string(class(b)), obj.a_branch);
        end
        function out = get_names_lcon(obj)% local controller
            out = tools.vcellfun(@(c) string(class(c)), obj.a_controller_local);
        end
        function out = get_names_gcon(obj)% global controller
            out = tools.vcellfun(@(c) string(class(c)), obj.a_controller_global);
        end


        %% Data Tab build
        function data = build_bus_tab(obj)
            if isempty(obj.network_handle.a_bus)
                data=[];
                return
            end
            
            % extract data
            net = obj.network_handle;
            Vst = net.V_equilibrium;
            Ist = net.I_equilibrium;
            Sst = Vst .* conj(Ist);
            shunt = tools.vcellfun(@(b) b.shunt, net.a_bus);

            % build table
            f = @(n,d) array2table(d,'VariableNames',{n});
            data = [ f( 'class'        ,obj.cn_bus      ) ,...
                     f( '|V|(pu)'      ,abs(   Vst )    ) ,...
                     f( '∠V(deg)'      ,angle( Vst )    ) ,...
                     f( '|I|(pu)'      ,abs(   Ist )    ) ,...
                     f( '∠I(deg)'      ,angle( Ist )    ) ,...
                     f( 'P(MW)'        ,real(  Sst )    ) ,...
                     f( 'Q(MVar)'      ,imag(  Sst )    ) ,...
                     f( 'S(VA)'        ,abs(   Sst )    ) ,...
                     f( 'θ(factor)'    ,cos(angle(Sst)) ) ,...
                     f( 'shunt'        ,shunt           ) ,...
                     f( 'component'    ,obj.cn_mac      ) ,...
                     f( 'Vequilibrium' ,Vst             ) ,...
                     f( 'Iequilibrium' ,Ist             ) ...
                  ];
            data.Properties.RowNames = "bus" + (1:numel(net.a_bus))';
        end

        function data = build_branch_tab(obj)
            if isempty(obj.network_handle.a_branch)
                data=[];
                return
            end
            f = @(n,d) array2table(d,'VariableNames',{n});
            p = @(n)   obj.broadcast(@(c) get_prop(c,n), 'bra');
            net = obj.network_handle;
            data = [ f( 'class'   ,obj.cn_br ) ,...
                     f( 'from'    ,p( 'from')) ,...
                     f( 'to'      ,p(  'to' )) ,...
                     f( 'x'       ,p(  'x'  )) ,...
                     f( 'y'       ,p(  'y'  )) ,...
                     f( 'phase'   ,p('phase')) ,...
                     f( 'tap'     ,p( 'tap' )) ,...
                     f( 'parallel',obj.get_parallel('bra')) ...
                  ];
            data = mergevars(data,{'from','to'},'NewVariableName','bus_number');
            data.Properties.RowNames = "branch" + (1:numel(net.a_branch))';
        end

        function data = macdata(obj)
            if isempty(obj.network_handle.a_bus)
                data=[];return
            end
            f = @(n,d) array2table(d,'VariableNames',{n});
            net = obj.network_handle;
            data = [ f( 'class'   , obj.cn_mac                                  ),...
                     f( 'state'   , obj.broadcast(@(c){c.get_state_name},'mac') ), ...
                     f( 'port'    , obj.broadcast(@(c){c.get_port_name },'mac') ), ...
                     f( 'parallel',obj.get_parallel('mac')                      )  ...
                  ];
            data.Properties.RowNames = "mac" + (1:numel(net.a_bus))';
        end

        function data = lcondata(obj)
            if isempty(obj.network_handle.a_controller_local)
                data=[];return
            end
            f = @(n,d) array2table(d,'VariableNames',{n});
            net = obj.network_handle;
            data = [ f( 'class'        ,obj.cn_cl                                  ),...
                     f( 'index_observe',obj.broadcast(@(c) {c.index_observe} ,'cl') ),...
                     f( 'index_input'  ,obj.broadcast(@(c) {c.index_input  } ,'cl') ),...
                     f( 'state'        , obj.broadcast(@(c){c.get_state_name},'cl') ), ...
                     f( 'parallel'     ,obj.get_parallel('cl')                     ) ...
                  ];
            data.Properties.RowNames = "con" + (1:numel(net.a_controller_local))';
        end

        function data = gcondata(obj)
            if isempty(obj.network_handle.a_controller_global)
                data=[];return
            end
            f = @(n,d) array2table(d,'VariableNames',{n});
            net = obj.network_handle;
            data = [ f( 'class'        ,obj.cn_cg                                  ),...
                     f( 'index_observe',obj.broadcast(@(c) {c.index_observe} ,'cg') ),...
                     f( 'index_input'  ,obj.broadcast(@(c) {c.index_input  } ,'cg') ),...
                     f( 'state'        , obj.broadcast(@(c){c.get_state_name},'cg') ), ...
                     f( 'parallel'     ,obj.get_parallel('cg')                     ) ...
                  ];
            data.Properties.RowNames = "con" + (1:numel(net.a_controller_global))';
        end

        function tab = uni_tab(obj,fdata,ftag,mlg)
            vars = unique(obj.broadcast(@(c)reshape(ftag(c),[],1),mlg),'stable');
            tab = obj.broadcast(@(c) {array2table(fdata(c),'VariableNames',ftag(c))},mlg);
            tab = horztab(tab,vars);
        end


    end

    methods(Access=private)

        function out = broadcast(obj,func,target)
            net = obj.network_handle;
            switch target
                case 'mac';out=tools.vcellfun(@(b) func(b.component), net.a_bus);
                case 'bus';out=tools.vcellfun(@(b) func(b), net.a_bus);
                case 'cl' ;out=tools.vcellfun(@(c) func(c), net.a_controller_local );
                case 'cg' ;out=tools.vcellfun(@(c) func(c), net.a_controller_global);
                case 'bra';out=tools.vcellfun(@(c) func(c), net.a_branch);
            end
        end

        function out = get_parallel(obj,target)
            out = obj.broadcast(@(c) string(c.parallel), target);
        end

        function [tab,uni] = uni_comp(obj,func)
            para = tools.cellfun(@(b) func(b.component), obj.network_handle.a_bus);
            uni = unique(horzcat(para{:}),'stable');
            tab = tools.hcellfun( @(is) ...
                  tools.vcellfun( @(ib) ...
                    ismember(is,func(ib.component)) ...
                  ,obj.network_handle.a_bus) ...
                  ,uni);
            tab = array2table(tab,'VariableNames',uni);
            tab.Properties.RowNames = "mac"+(1:numel(obj.network_handle.a_bus));
        end

        function [tab,uni] = uni_con(obj,func,gl)
            a_con = obj.network_handle.(['a_controller_',gl]);
            if isempty(a_con)
                tab = []; uni = [];
                return
            end
            para = tools.arrayfun(@(i) func(a_con{i}), 1:numel(a_con));
            uni = unique(horzcat(para{:}),'stable');
            tab = tools.hcellfun( @(is)...
                  tools.vcellfun( @(ib)...
                    ismember(is,func(ib))...
                  ,a_con)...
                  ,uni);
            tab = array2table(tab,'VariableNames',uni);
            if ~isempty(tab)
                tab.Properties.RowNames = "con"+(1:numel(a_con));
            end
        end


%         function [state,para] = xpara_data(~,list,f,row)
%             [nlist,~,ilist] = unique(tools.vcellfun(@(c) string(class(c)),list),'stable');
% 
%             state = struct;
%             para  = struct;
%             for i = 1:numel(nlist)
%                 idx = find(ilist==i);
%                 
%                 statenames = unique( tools.hcellfun(@(c) c.get_state_name, list(idx)), 'stable');
%                 i_state = tools.vcellfun(@(c) tabcomp(array2table(reshape(c.(f),1,[]),'VariableNames',c.get_state_name),statenames),list(idx));
%                 i_state.Properties.RowNames = row + idx(:); 
% 
%                 paranames = unique( tools.hcellfun(@(c) c.parameter.Properties.VariableNames, list(idx)), 'stable');
%                 i_para = tools.vcellfun(@(c) tabcomp(c.parameter,paranames),list(idx));
%                 i_para.Properties.RowNames = row + idx(:); 
% 
%                 fd = strsplit(nlist(i),'.');
%                 state = setfield(state,fd{:},i_state);
%                 para  = setfield( para,fd{:},i_para );
%             end
%             
%         end
        
    end
    
end

function out = horztab(tab,vars)
    if isempty(vars)
        out = array2table(zeros(size(tab,1),0));
        return
    end
    out = tools.hcellfun( @(iv)array2table(tools.vcellfun( @(it)get_prop(it,iv),tab),'VariableNames',{iv}),vars);
end

function out = get_prop(c,prop)
    if ismember(prop,properties(c)); out = c.(prop);
    else; out = nan;
    end
end