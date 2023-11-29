classdef GFMI_vsm_DCconst < component.GFM.GFMI
    methods
        function obj = GFMI_vsm_DCconst()
            obj@component.GFM.GFMI();

            vsm = component.GFM.ReferenceModel.vsm();
            obj.set_reference_model(vsm);

            Vconst = component.GFM.DCsource.Vconstant();
            obj.set_dc_source(Vconst);

        end
    end
end