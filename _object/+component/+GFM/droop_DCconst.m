classdef droop_DCconst < component.GFM.Inverter
    methods
        function obj = droop_DCconst()
            obj@component.GFM.Inverter()

            droop = component.GFM.ReferenceModel.droop();
            obj.set_reference_model(droop);

            Vconst = component.GFM.DCsource.Vconstant();
            obj.set_dc_source(Vconst);
            
        end
    end
end