function bus = add_bus(obj, opt)
% <@Desc>
% Adds a new Bus object to the power network.
% <@Role>
% Layer Structure
% <@Abst>
% Creates a Bus instance with the given parameters and registers it in the network.
% <@Signatures>
% [
%   "bus = net.add_bus()",
%   "bus = net.add_bus(Tag=\"B\", V=1.0, Varg=0, Gshunt=0, Bshunt=0)"
% ]
% <@varargin>
% [
%   {
%     "Name": "Tag",
%     "Type": "string scalar",
%     "Description": "Tag prefix for the bus name.",
%     "Required": false,
%     "Default": "\"B\""
%   },
%   {
%     "Name": "V",
%     "Type": "double scalar",
%     "Description": "Initial voltage magnitude [pu].",
%     "Required": false,
%     "Default": "1"
%   },
%   {
%     "Name": "Varg",
%     "Type": "double scalar",
%     "Description": "Initial voltage angle [rad].",
%     "Required": false,
%     "Default": "0"
%   },
%   {
%     "Name": "Gshunt",
%     "Type": "double scalar",
%     "Description": "Shunt conductance [pu].",
%     "Required": false,
%     "Default": "0"
%   },
%   {
%     "Name": "Bshunt",
%     "Type": "double scalar",
%     "Description": "Shunt susceptance [pu].",
%     "Required": false,
%     "Default": "0"
%   }
% ]
% <@varargout>
% [
%   {
%     "Name": "bus",
%     "Type": "Bus",
%     "Description": "Newly created and registered Bus object."
%   }
% ]
% <@Examples>
% [
%   "```matlab\nbus = net.add_bus(V=1.0, Varg=0);\n```"
% ]
    arguments
        obj 
        opt.Varg              (1,1) double = 0 /180*pi;
        opt.V                 (1,1) double = 1;
        opt.Gshunt            (1,1) double = 0;
        opt.Bshunt            (1,1) double = 0;
        opt.Vmin              (1,1) double = 0.5;
        opt.Vmax              (1,1) double = 1.5;
        opt.baseKV            (1,1) double = 230;
        opt.baseMVA           (1,1) double = 100;
        opt.OPFinit_Varg0     (1,1) double = 0/180*pi;
        opt.OPFinit_V0        (1,1) double = 1;
        opt.Tag               (1,1) string = 'B';
        opt.Xaxis             (1,1) double = nan;
        opt.Yaxis             (1,1) double = nan;
        opt.Marker            (1,1) string = "s";
    end

    n_Bus   = numel(obj.a_Bus);
    str_Bus = opt.Tag+num2str(n_Bus+1,"%.3d");

    opt = rmfield(opt,"Tag");
    % opt = namedargs2cell(opt);
    % bus = Bus(str_Bus, opt{:});
    bus = Bus(str_Bus, opt);
    bus.set_network(obj)

    obj.a_Bus = [obj.a_Bus;{bus}];
    obj.log_edit(obj.str_tag+" <<-Add--- "+bus.str_tag,"Topology");
end