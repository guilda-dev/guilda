classdef input < supporters.for_simulate.option.base

    methods
        function obj = input(net,t,data)
            obj@supporters.for_simulate.option.base(net,t,data)
        end
        
        function fdata = get_ufunc(obj,tlim)
            fdata = [];
            idx = 1;
            for i = 1:numel(obj.data)
                f = ufunc_factory(obj.data(i),tlim);
                if ~isempty(f)
                    fdata(idx).index   = obj.data(i).index;                                                         %#ok
                    fdata(idx).ufunc   = f;                                                                         %#ok
                    inu = tools.varrayfun(@(i) i*ones(obj.network.a_bus{i}.component.get_nu,1),obj.data(i).index);
                    fdata(idx).logimat = tools.harrayfun(@(i) inu==i,obj.data(i).index);                            %#ok
                    idx = idx+1;    
                end
            end
        end

        function [tlist,out] = timetable(obj)
            tlist = obj.timelist;
            nbus  = numel(obj.network.a_bus);
            tab   = false(nbus, numel(tlist));
            for i = 1:numel(obj.data)
                itime = obj.data(i).time;
                ibus  = obj.data(i).index;
                idx   = tlist>=itime(1) & tlist< itime(2);
                tab(ibus,idx) = true;
            end
            out = array2table(tab,"RowNames","component"+(1:nbus));
        end

        function plot(obj,ax)
            tlist = obj.timelist;

            nbus  = numel(obj.network.a_bus);
            tdata = linspace(obj.time(1),obj.time(end),1000);
            udata = cell(nbus,1);
            for it = 1:numel(tlist)-1
                fdata = obj.get_ufunc(tlist([it,it+1]));
                within = tdata>=tlist(it) & tdata<=tlist(it+1);
                for i = 1:numel(fdata)
                    udata_i = tools.harrayfun(@(t) fdata(i).ufunc(t),tdata(within));
                    for jj = 1:numel(fdata(i).index)
                        idx = fdata(i).index(jj);
                        if isempty(udata{idx})
                            udata{idx} = zeros(obj.network.a_bus{idx}.component.get_nu,1000);
                        end
                        udata{idx}(:,within) = udata{idx}(:,within) + udata_i(fdata(i).logimat(:,jj),:);
                    end
                end
            end
            idata = find(tools.hcellfun(@(d) ~isempty(d),udata));
            ndata = numel(idata);
            nv = ceil(sqrt(ndata));
            nr = ceil(ndata/nv);

            if nargin<2
                figure
                for i = 1:numel(idata)
                    subplot(nr,nv,i)
                    grid on
                    plot(tdata,udata{idata(i)},'LineWidth',1.5)
                    xlabel('Time(s)')
                    legend(obj.network.a_bus{idata(i)}.component.get_port_name)
                    subtitle([class(obj.network.a_bus{idata(i)}.component),'@bus',num2str(idata(i))])
                end
            else
                hold(ax,'on')
                grid(ax,'on')
                xlabel(ax,'Time(s)')
                lword = [];
                for i = 1:numel(idata)
                    plot(tdata,udata{idata(i)},'LineWidth',1.5)
                    lword = [lword, tools.cellfun(@(n) [n,'@mac',num2str(idata(i))],obj.network.a_bus{idata(i)}.component.get_port_name)];%#ok
                end
                legend(lword)
                hold(ax,'off')
            end
        end

        function [varargout] = sentence(obj,language)
            if nargin<2
                if contains( get(0,'lang'), 'ja')
                    language = 'Japanese';
                else
                    language = 'English';
                end
            end
            switch language
                case 'Japanese'
                    w = {@(i) [num2str(i),'番目の地絡 \n'],...
                         @(t) ['　　　時間　：',num2str(t(1)),'~',num2str(t(2)),'秒 \n'],...
                         @(b) ['　　母線番号：',mat2str(b),'\n']};
                otherwise  %'English'
                    w = {@(i) [num2str(i),'-th fault\n'],...
                         @(t) ['  time span  :',num2str(t(1)),'~',num2str(t(2)),'(s) \n'],...
                         @(b) ['  bus number :',mat2str(b),'\n']};
            end

            word = cell(1,numel(obj.data));
            for i = 1:numel(obj.data)
                it = obj.data(i).time;
                ib = obj.data(i).index;
                word{i} = [w{1}(i),w{2}(it),w{3}(ib)];
            end
            word = horzcat(word{:});
            if nargout<1
                if ~isempty(word)
                    fprintf(word);
                end
            else
                varargout{1} = word;
            end
        end
    end


    methods(Access=protected)

        function organize(obj)
            indata  = obj.data;
            if isempty(indata)
                return
            end
            fn_diff = setdiff({'time','index','u','method','function'},fieldnames(indata));
            for i = 1:numel(fn_diff)
                indata(1).(fn_diff{i}) = [];
            end
            nanidx = [];
            for i = 1:numel(indata)
                if isempty(indata(i).index)
                    warning(['The ',num2str(i),'-th condition for a "u" is ignored because "index" was not detected.'])
                    nanidx = [nanidx,i];%#ok
                    continue
                end
                if isempty(indata(i).time)
                    indata(i).time = [obj.time(1),obj.time(end)];
                end
                if isempty(indata(i).function)
                    if isempty(indata(i).u)
                        warning(['The ',num2str(i),'-th condition for a "u" is ignored because no input data was detected.'])
                        nanidx = [nanidx,i];%#ok
                        continue
                    elseif isempty(indata(i).method)
                        indata(i).method = 'zoh';
                    end
                    if size(indata(i).u,2)~=numel(indata(i).time)
                        if size(indata(i).u,1) == numel(indata(i).time)
                            indata(i).u = (indata(i).u).';
                        else
                            warning(['The ',num2str(i),'-th condition for a "u" is ignored because  the number of elements in "time" and "u" do not match.'])
                            nanidx = [nanidx,i];%#ok
                            continue
                        end
                    end
                    nu_data = size(indata(i).u,1);
                    nu_each = tools.harrayfun(@(i) obj.network.a_bus{i}.component.get_nu, indata(i).index);
                    if nu_data ~= sum(nu_each)
                        if all( (nu_each-nu_each(1))==0 ) && ( nu_each(1) == nu_data )
                            indata(i).u = kron( ones(numel(nu_each),1), indata(i).u );
                        else
                            warning(['The ',num2str(i),'-th condition for a "u" is ignored because the number of input ports of the target device does not match the number of elements in "u"'])
                            nanidx = [nanidx,i];%#ok
                            continue
                        end
                    end
                    if ~ismember(indata(i).method,{'zoh','foh','sigmoid','sin','cos'})
                        warning(['The ',num2str(i),'-th condition for a "u" is ignored because the the "method" name could not be identified.'])
                        nanidx = [nanidx,i];%#ok
                        continue
                    end
                else
                    indata(i).method = 'function';
                end
            end
            obj.data = indata;
        end

    end
end

function f = ufunc_factory(data,tlim)
    f = [];
    tlist = data.time;
    is = find(tlist<=tlim(1), 1, 'last' );
    ie = find(tlist>=tlim(2), 1, 'first');
    ts = tlist(is);
    te = tlist(ie);
    dt = te-ts;
    us = data.u(:,is);
    ue = data.u(:,ie);
    du = ue-us;
    if ~isempty(ts) && ~isempty(te)
        if ts==te
            f = @(t) us*(t==ts);
        else
            switch data.method
                case 'zoh'
                    f = @(t) us;
                case 'foh'
                    f = @(t) ((te-t)*us+(t-ts)*ue)/dt;
                case 'sigmoid'
                    f = @(t) us + du * (1 - cos( (t-ts)/dt * pi ))/2;
                case {'sin','cos'}
                    f = @(t) us + du * 1./(1+exp(-20*(t-ts)/dt+10));
                case 'function'
                    f = data.function;
            end
        end
    end
end