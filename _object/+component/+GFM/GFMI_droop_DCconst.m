classdef GFMI_droop_DCconst < component.GFM.GFMI
    methods
        function obj = GFMI_droop_DCconst()
            obj@component.GFM.GFMI()

            droop = component.GFM.ReferenceModel.droop();
            obj.set_reference_model(droop);

            Vconst = component.GFM.DCsource.Vconstant();
            obj.set_dc_source(Vconst);
            
        end
    end
end