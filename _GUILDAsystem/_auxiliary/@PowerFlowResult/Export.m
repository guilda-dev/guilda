function str_file = Export(obj, filename, opt)
% <@Desc>
% Writes the result to a file. The format follows the extension of filename:
%   .csv / .txt / .xlsx / .xls : the bus table (tab_bus) or, with Table="branch", the
%                                branch table (tab_branch); phasors as complex numbers.
%   .json                      : the iteration history for the GridSpring viewer
%                                (https://ta-nish18.github.io/GridSpring/). It reads the
%                                bus types and the admittance matrix from the network.
% A relative filename is relative to the current folder.
% calculate_powerflow(..., Export=filename) calls it.
% <@Role> Export
% <@Summary> Write the bus/branch table or the iteration history to a file.
% <@Signatures>
% [
%   "str_file = Export(result)",
%   "str_file = Export(result, filename)",
%   "str_file = Export(result, filename, Table=\"branch\")"
% ]
% <@Parameters>
% [
%   {"Name": "result", "Type": "PowerFlowResult", "Description": "Result to write.", "Required": true, "Default": "-"},
%   {"Name": "filename", "Type": "string scalar", "Description": "Output file; its extension selects the format.", "Required": false, "Default": "\"<yyMMdd_HHmmss>_PowerFlow.csv\""},
%   {"Name": "Table", "Type": "\"bus\" | \"branch\"", "Description": "Table written to a CSV or Excel file.", "Required": false, "Default": "\"bus\""}
% ]
% <@Returns>
% [
%   {"Name": "str_file", "Type": "string scalar", "Description": "Path of the written file."}
% ]
    arguments
        obj
        filename  (1,1) string = string(datetime("now","Format","uuMMdd_HHmmss")) + "_PowerFlow.csv"
        opt.Table (1,1) string {mustBeMember(opt.Table,["bus","branch"])} = "bus"
    end
    str_file = filename;
    [~, ~, str_ext] = fileparts(str_file);

    switch lower(str_ext)
        case {".csv", ".txt", ".xlsx", ".xls"}
            if opt.Table == "bus"
                tab = obj.tab_bus;
            else
                tab = obj.tab_branch;
            end
            writetable(tab, str_file, "WriteRowNames", true);
        case ".json"
            export_json(obj, str_file);
        otherwise
            error('GUILDA:PowerFlowResult:ExportFormat', '%s', ...
                  msg('GUILDA:PowerFlowResult:ExportFormat', char(str_ext)));
    end
end


function export_json(obj, str_file)
% Iteration history in the format of the GridSpring viewer
    net = obj.a_PowerNetwork;
    if isempty(net)
        error('GUILDA:PowerFlowResult:NoNetwork', '%s', msg('GUILDA:PowerFlowResult:NoNetwork'));
    end
    tab_PFset = tools.vcellfun(@(b) b.get_pf_set, net.a_Bus);
    str_bus   = string(tab_PFset.Properties.RowNames);
    tab_Ymat  = net.get_admittance_matrix;
    cm_Y      = tab_Ymat{str_bus,str_bus};
    n_Bus     = size(tab_PFset,1);

    out = struct();

    l_slack = tab_PFset.Type'=="slack";
    l_PV    = tab_PFset.Type'=="PV";
    l_PQ    = tab_PFset.Type'=="PQ";

    out.Text =   n_Bus+"Bus Model" +newline + ...
                 " > slack : "              + mat2str(find(l_slack)) + newline + ...
                 " > PV ("+sum(l_PV)+") : " + mat2str(find(l_PV))    + newline +...
                 " > PQ ("+sum(l_PQ)+") : " + mat2str(find(l_PQ))    ;

    out.nodes(n_Bus) = struct('Color',[], 'Label',[], 'Hover',[], ...
                              'Varg' ,[], 'Vabs' ,[] );

    cr_Vbus  = obj.cm_Vhistory;
    rr_Varg  = unwrap(angle(cr_Vbus), [], 2);
    rr_Vabs  = abs(cr_Vbus);
    cr_Ibus  = cm_Y * cr_Vbus;
    cr_Sbus  = cr_Vbus .* conj(cr_Ibus);
    rr_Pflow = -real(cr_Sbus);
    rr_Iflow = -imag(cr_Sbus) ./ rr_Vabs;

    l_foh = isfield(obj.options, "Method") && obj.options.Method == "dynamic" ...
            && obj.options.dynamic.foh_PQ ~= 0;

    for i_bus = 1:n_Bus
        tab_i = tab_PFset(i_bus,:);

        type = tab_i.Type;
        h = "Bus"+i_bus+" ("+type+")"+newline;
        p = nan;
        q = nan;
        switch type
            case "PV"
                c = [0,1,0,1];
                p = {tab_i.P};
                h = h+"P="+tab_i.P+", V="+tab_i.V;
            case "PQ"
                c = [1,0,0,1];
                p = {tab_i.P};
                q = {tab_i.Q};
                h = h+"P="+tab_i.P+", Q="+tab_i.Q;
            case "slack"
                c = [0,0,1,1];
                h = h+"Varg="+tab_i.Varg+", V="+tab_i.V;
            otherwise
                c = [0,0,0,1];
        end
        l = num2str(i_bus);

        if l_foh
            scale = min( obj.rv_step/obj.options.dynamic.foh_PQ, 1);
            if iscell(p); p = p{1}*scale; end
            if iscell(q); q = q{1}*scale; end
        end

        out.nodes(i_bus).Color = c;
        out.nodes(i_bus).Label = l;
        out.nodes(i_bus).Hover = h;
        out.nodes(i_bus).Pset  = p;
        out.nodes(i_bus).Qset  = q;
        out.nodes(i_bus).Pflow = rr_Pflow(i_bus,:);
        out.nodes(i_bus).Iflow = rr_Iflow(i_bus,:);
        out.nodes(i_bus).Varg  = rr_Varg(i_bus,:);
        out.nodes(i_bus).Vabs  = rr_Vabs(i_bus,:);
    end
    g = graph(abs(cm_Y),'omitselfloops');
    out.edges = reshape(g.Edges.EndNodes.', [], 1).';

    jsonStr = jsonencode(out,"PrettyPrint",true);
    fid     = fopen(str_file, 'w');
    if fid < 0
        error('GUILDA:PowerFlowResult:FileOpen', '%s', msg('GUILDA:PowerFlowResult:FileOpen', char(str_file)));
    end
    fwrite(fid, jsonStr, 'char');
    fclose(fid);

    disp("<INFO>")
    disp("  Exported json file: "+str_file);
    disp("  You can upload this json file to the following link to visualize the calculation process.");
    fprintf('  <a href="https://ta-nish18.github.io/GridSpring/">https://ta-nish18.github.io/GridSpring/</a>\n\n')
end
