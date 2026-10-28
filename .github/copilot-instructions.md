# japanese feedback
Please provide your feedback in Japanese.

# Project Overview
This software is designed with object-oriented programming (OOP).
Its functions include power system modeling, power flow analysis, OPF,
approximate linearization, eigenvalue analysis, and time-domain simulation.

# Coding Convention (Naming Convention)

## 1. Classes and Methods
- **Class names**: UpperCamelCase
  - Example: `Component`, `SimulationResult`
- **Method names**: snake_case
  - Example: `calculate_power_flow`, `on_edit`

## 2. Property and Variable Naming Rules
Variables should generally follow **`[type][size]_[name]`** in snake_case.

### Variable Type (First Prefix)
- `c`: complex
- `r`: real
- `l`: logical
- `s`: symbolic variable (sym)
- `f`: symbolic function
- `i`: index
- `n`: count/number
- `str`: string

### Size (Second Prefix)
- *(none)*: scalar (do not add a size prefix for scalars)
- `v`: column vector
- `r`: row vector
- `m`: matrix

### Naming Examples
- **`cv_Vequilibrium`**: [c: complex] + [v: column vector] + [_Vequilibrium]
- **`im_solution`**: [i: index] + [m: matrix] + [_solution]
- **`r_gain`**: [r: real] + [none: scalar] + [_gain]
- **`str_message`**: [str: string] + [none: scalar] + [_message]

---

## 3. Exception Rules (Fixed Prefixes)
For the following data types, use the fixed prefixes regardless of size.

- **Dictionary type**: `dict_` + [name]
  - Example: `dict_params`
- **Function handle**: `fcn_` + [name]
  - Example: `fcn_objective`
- **Table type**: `tab_` + [name]
  - Example: `tab_bus_data`
- **Struct type**: `sct_` + [name]
  - Example: `sct_results`
- **GUILDA-specific class (cell array)**: `a_` + **[ClassName]**
  - Used for cell arrays that store GUILDA class objects.
  - Example: `a_Controller` (stores `Controller` class objects)
- **Parameter class**: `params_` + [data name]
  - Used when storing GUILDA's `Parameter` class.
  - Example: `params_generator`

## 4. How to Document Class Definitions

#### Help Comments for Class Definition

Write class-level tags directly below `classdef`, then keep constructor usage examples concrete:

```matlab
classdef MyClass
    % <@Desc> Handles state updates and utility calculations for a subsystem.
    % <@Role> CoreComponent
    % <@Constructor> Create class instance with optional gain and label.
    %  i.e.
    %  >> obj = MyClass(r_gain, str_label)
    %      - r_gain: scalar gain value (default: 1.0)
    %      - str_label: display name (default: "default")

    properties
        r_gain
        str_label
    end

    methods
        function obj = MyClass(r_gain, str_label)
            arguments
                r_gain (1,1) double = 1.0
                str_label (1,1) string = "default"
            end
            obj.r_gain = r_gain;
            obj.str_label = str_label;
        end
    end
end
```

#### Help Comments for Methods

Add method tags immediately above each method body. Structured tags are parsed as JSON only.
- **Text tags:** `Desc`, `Role`, `Abst`, `DetailsCode`, `Argin`, `Argout`, `Option`
- **Structured tags (JSON only):** `Signatures`, `varargin`, `varargout`, `Examples`
 **Structured schema:** `varargin` = `Name`, `Type`, `Description`, `Required`, `Default` / `varargout` = `Name`, `Type`, `Description`

```matlab
methods
    function rv_y = calculate_output(obj, rv_u, r_gain)
    % <@Desc>
    % Computes an output vector from input data using a configurable gain.
    % <@Abst>
    % Typical example of method tags with parameters, return values, and examples.
    % <@Signatures>
    % [
    %   "rv_y = obj.calculate_output(rv_u, r_gain)",
    %   "rv_y = obj.calculate_output(rv_u)"
    % ]
    % <@varargin>
    % [
    %   {
    %     "Name": "rv_u",
    %     "Type": "double vector",
    %     "Description": "Input signal vector.",
    %     "Required": true,
    %     "Default": "-"
    %   },
    %   {
    %     "Name": "r_gain",
    %     "Type": "double scalar",
    %     "Description": "Scaling gain applied to the input.",
    %     "Required": false,
    %     "Default": "1.0"
    %   }
    % ]
    % <@varargout>
    % [
    %   {
    %     "Name": "rv_y",
    %     "Type": "double vector",
    %     "Description": "Scaled output vector."
    %   }
    % ]
    % <@Examples>
    % [
    %   "```matlab\nrv_y = obj.calculate_output(rv_u, 2.0);\n```",
    %   "```matlab\nrv_y = obj.calculate_output(randn(5,1));\n```"
    % ]
    end
end
```

Notes: If a structured tag is omitted or invalid JSON, exporter writes an empty default value.

#### Help Comments for Properties

Document each property right above its declaration. This helps readers understand data intent quickly:

```matlab
properties
    % <@Desc> Gain applied to input/output calculations.
    % <@Role> simulate
    % <@Type> double
    % <@Size> 1x1
    r_gain

    % <@Desc> Last computed output cached for diagnostics.
    % <@Role> linearize
    % <@Type> double
    % <@Size> Nx1
    rv_last_output
end
```

---

# Design and Implementation Guidelines

## Class Constructors
- Even when called without arguments (`nargin == 0`), constructors must initialize instances with default values.

```matlab
methods
    function obj = MyClass(arg1)
        arguments
            arg1 = 0
        end
        obj.r_value = arg1;
    end
end