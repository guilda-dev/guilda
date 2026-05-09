const GUILDAhandle_Info = {
  "ClassName": "GUILDAhandle",
  "properties": [],
  "methods": [
    {
      "Name": "exportClassDoc",
      "Defining": "GUILDAhandle",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Hidden": false,
      "Desc": "This method uses MATLAB's reflection capabilities to extract metadata from the class properties and methods.\nIt also reads custom tags defined in the help comments.\nThe extracted information is saved as a JavaScript file for the GUILDA documentation database.",
      "Role": "Data Export",
      "Abst": "Export documentation as JavaScript files",
      "Argin": "\"str_path\":\n>> (optional) string specifying the output path for the JavaScript file.\n>> Default value: fullfile(GUILDA.pwd,'_GUILDAdoc','database','GUILDAobject')",
      "Argout": "\"sct_info\": struct containing the following fields:\n- classname\n- description\n- Role\n- Constructor",
      "Option": "None"
    },
    {
      "Name": "GUILDAhandle",
      "Defining": "GUILDAhandle",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "GUILDAhandle is a base class for all classes in GUILDA that require handle behavior.\nIn this class, we implement a static method to export documentation as JavaScript files for use in the GUILDA documentation website.",
      "Role": "Data Export",
      "Abst": "",
      "Argin": "",
      "Argout": "",
      "Option": ""
    }
  ]
};
