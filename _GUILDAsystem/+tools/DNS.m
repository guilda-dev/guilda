function address = DNS(domain)
    arguments
        domain {mustBeA(domain,["cell","string","char"])} = '';
    end
    if isempty(domain)
        domain  = input('class name : ','s');
    end

    if iscell(domain)
        tools.cellfun(@(o) tools.DNS(o), domain)
    % elseif eval(['numel(?',domain,')'])==1
    %         address = domain;
    else
        if strcmp( domain(end-1:end), '.m')
            domain = domain(1:end-2);
        end
        switch domain

        % 送電線モデル
            case 'branch_pi'
                address = 'branch.pi';
            case 'branch_pi_transfer'
                address = branch.pi_transfer;

        % 母線モデル
            case 'bus_PQ'
                address = 'bus.PQ';
            case 'bus_PV'
                address = 'bus.PV';
            case 'bus_slack'
                address = 'bus.slack';
                    
        % 発電機モデル
            case 'generator_1axis'
                address = 'component.generator.one_axis';
            case 'generator_2axis'
                address = 'component.generator.two_axis';
            case 'generator_classical'
                address = 'component.generator.classical';
            case 'generator_park'
                address = 'component.generator.park';

        % 負荷モデル
            case 'load_impedance'
                address = 'component.load.impedance';
            case 'load_voltage'
                address = 'component.load.voltage';
            case 'load_current'
                address = 'component.load.current';
            case 'load_power'
                address = 'component.load.power';

        % avr
            case 'avr'
                address = 'component.generator.avr.base';
            case 'avr_IEEE_DC1'
                address = 'component.generator.avr.IEEE_DC1';
            case 'avr_IEEE_ST1'
                address = 'component.generator.avr.IEEE_ST1';
            case 'avr_sadamoto2019'
                address = 'component.generator.avr.sadamoto2019';
            case 'avr_IEEE_type1'
                address = 'component.generator.avr.IEEE_type1';

        % pss
            case 'pss'
                address = 'component.generator.pss.base';
            case 'pss_IEEE_PSS1'
                address = 'component.generator.pss.IEEE_PSS1';

        % governor
            case 'governor'
                address = 'component.generator.governor.base';
        
        % controller
            case 'controller_broadcast_PI_AGC'
                address = 'controller.broadcast_PI_AGC';
            case 'controller_retrofit_LQR'
                address = 'controller.local_LQR_retrofit';
            case 'controller_local_LQR'
                address = 'controller.local_LQR';

        % その他
            case 'component_empty'
                address = 'component.empty';
            otherwise
                address = search_class(tools.pwd,domain,[]);
        end
    end
    if isnan(address)
        error('This class could not be identified.')
    end
end

function val = search_class(path,domain,address)
    val  = nan;
    list = dir(path);
    list = struct2table(list);
    for i = find(~list{:,'isdir'})'
        file = strrep([address,list{i,'name'}{1}],'.m','');
        try
            isclass = eval(['numel(?',file,')']);
        catch
            isclass = false;
        end
        if isclass
        if ismember(domain,name_candidate(file))
            val = file;
            return
        end
        end
    end
    for i = find(list{:,'isdir'})'
        folder = list{i,'name'}{1};
        if folder(1)=='+'
            val = search_class(fullfile(path,folder),domain,[address,folder(2:end),'.']);
            if ~isnan(val)
                return
            end
        elseif ismember(folder,{'_object','_script'})
            val = search_class(fullfile(path,folder),domain,[]);
            if ~isnan(val)
                return
            end
        end
    end
end

function domain = name_candidate(file)
    idx = find(file=='.');
    domain = tools.arrayfun(@(i) file(i:end),[0,idx]+1);

    if contains(file,'.base')
        file = strrep(file,'.base','');
        idx = find(file=='.');
        domain = [domain,tools.arrayfun(@(i) file(i:end),[0,idx]+1)];
    end

    domain = [domain,tools.cellfun(@(d) strrep(d,'.','_'), domain)];
end