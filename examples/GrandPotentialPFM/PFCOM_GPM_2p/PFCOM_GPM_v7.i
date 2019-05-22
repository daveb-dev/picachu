#------------------------------------------------------------------------------#
# PFCOM using the grand potential model
# Using function IC for a hyperbolic tangent profile
# Using GP Action!
#------------------------------------------------------------------------------#
[Mesh]
  # length scale -> microns
  type = GeneratedMesh
  dim = 2

  xmin = 0.0
  xmax = 3.0
  nx = 60

  ymin = 0.0
  ymax = 12.0
  ny = 240
[]

#------------------------------------------------------------------------------#
[Problem]
  type = FEProblem
  coord_type = RZ
  rz_coord_axis = Y
[]

#------------------------------------------------------------------------------#
# Coordinates for bounding box IC
[GlobalParams]
[]

#------------------------------------------------------------------------------#
[Variables]
  [./w_c]
  [../]
  [./eta0]
  [../]
  [./eta1]
  [../]
[]

#------------------------------------------------------------------------------#
[ICs]
  [./IC_w_c]
    type = ConstantIC
    variable = w_c
    value = 0.0
  [../]

  [./IC_eta0] #fiber
    type = FunctionIC
    variable = eta0
    function = fiber
  [../]

  [./IC_eta1] #gas
    type = FunctionIC
    variable = eta1
    function = gas
  [../]
[]

#------------------------------------------------------------------------------#
[Functions]
  [./fiber]
    type = ParsedFunction
    value = '(1/2)^2*(1.0-tanh((x-1.0)/0.1))*(1.0+tanh((-y+10.0)/0.1))'
  [../]

  [./gas]
    type = ParsedFunction
    value = '1-(1/2)^2*(1.0-tanh((x-1.0)/0.1))*(1.0+tanh((-y+10.0)/0.1))'
  [../]
[]

#------------------------------------------------------------------------------#
[Modules]
  [./PhaseField]
    [./GrandPotential]
      chemical_potentials = 'w_c' # Different chemical potentials
      mobilities = 'D'
      susceptibilities = 'chi'

      free_energies_w = 'x_fiber x_gas' #Fj_names for ACInterface
      free_energies_gr = 'GP_fiber GP_gas' #Fj_names for ACSwitching
      switching_function_names = 'h_fiber h_gas' #Fj_names for ACInterface

      gamma_gr = gamma
      kappa_gr = kappa
      mobility_name_gr = L

      op_num = 2
      var_name_base = eta
      # This is a hack because the action is not made to not have any grains
      # But it doesn't matter, this will assign the correct kernels to etas
    [../]
  [../]
[]

#------------------------------------------------------------------------------#
[Kernels]
[]

#------------------------------------------------------------------------------#
[Materials]
  #----------------------------------------------------------------------------#
  [./constants]
    type = GenericConstantMaterial
    prop_names  = 'D      chi    gamma   mu'
    prop_values = '0.1   0.03    1.5     1.0'
  [../]

  [./interfacial_param]
    type = GenericConstantMaterial
    prop_names  = 'kappa     L'
    prop_values = '1e-2         1e-3'
  [../]

  [./Va]
    # Units:
    type = GenericConstantMaterial
    prop_names = 'Va'
    prop_values = '1.0'
  [../]

  #----------------------------------------------------------------------------#
  # Switching Functions
  [./switch_fiber]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_fiber
    all_etas = 'eta0 eta1'
    phase_etas = 'eta0'

    outputs = exodus
    output_properties = h_fiber
  [../]

  [./switch_gas]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_gas
    all_etas = 'eta0 eta1'
    phase_etas = 'eta1'

    outputs = exodus
    output_properties = h_gas
  [../]

  #----------------------------------------------------------------------------#
  # Concentrations
  [./x_fiber]
    type = DerivativeParsedMaterial
    f_name = x_fiber

    function = 'w_c/(Va*A) + x_eq'

    args = 'w_c'
    material_property_names = 'Va'

    constant_names =       'x_eq      A'
    constant_expressions = '0.9702    34.5350'

    outputs = exodus
    output_properties = x_fiber
    enable_jit = false
  [../]

  [./x_gas]
    type = DerivativeParsedMaterial
    f_name = x_gas

    function = 'w_c/(Va*A) + x_eq'

    args = 'w_c'
    material_property_names = 'Va'

    constant_names =       'x_eq    A'
    constant_expressions = '0.0     30.0'

    outputs = exodus
    output_properties = x_gas
    enable_jit = false
  [../]

  #----------------------------------------------------------------------------#
  # Grand potential density of the fiber phase according to parabolic free energy
  [./GP_fiber]
    type = DerivativeParsedMaterial
    f_name = GP_fiber

    function = '-0.5*w_c^2/(Va^2 *A) - x_eq*w_c/Va +Ref'

    args = 'w_c'
    material_property_names = 'Va'

    constant_names =       'x_eq      A            Ref'
    constant_expressions = '0.9702    34.5350      -0.0052'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_fiber
    enable_jit = false
  [../]

  # Grand potential density of the gas phase according to parabolic free energy
  [./GP_gas]
    type = DerivativeParsedMaterial
    f_name = GP_gas

    function = '-0.5*w_c^2/(Va^2 *A) - x_eq*w_c/Va'

    args = 'w_c'
    material_property_names = 'Va'

    constant_names =       'x_eq  A'
    constant_expressions = '0.0   30.0'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_gas
    enable_jit = false
  [../]

[]

#------------------------------------------------------------------------------#
[Postprocessors]
  # [./total_carbon]
  #   type = ElementIntegralMaterialProperty
  #   mat_prop = 'x'
  #   execute_on = 'INITIAL TIMESTEP_END'
  # [../]
  # [./total_GP]
  #   type = ElementIntegralMaterialProperty
  #   mat_prop = 'GP_total'
  #   execute_on = 'INITIAL TIMESTEP_END'
  # [../]

  # Stats
  [./dt]
    type = TimestepSize
  [../]
  [./alive_time]
    type = PerfGraphData
     data_type = TOTAL
     section_name = 'Root'
  [../]
  [./mem_usage]
    type = MemoryUsage
    mem_type = physical_memory
  [../]
[]

#------------------------------------------------------------------------------#
[Preconditioning]
  [./SMP]
    type = SMP
    full = true
  [../]
[]

#------------------------------------------------------------------------------#
[Executioner]
  type = Transient
  scheme = bdf2
  solve_type = NEWTON

  l_max_its = 15
  l_tol = 1e-3
  nl_max_its = 15
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-8

  end_time = 10000
  #dtmax = 2

  [./Predictor]
    type = SimplePredictor
    scale = 1
  [../]

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 1e-2
    growth_factor = 2
    cutback_factor = 0.8
    optimal_iterations = 12
    iteration_window = 0
  [../]
[]

#------------------------------------------------------------------------------#
[Outputs]
  exodus = true
  csv = true
  file_base = ./results_v7/PFCOM_GPM_v7_out
  execute_on = 'INITIAL TIMESTEP_END FINAL'
  perf_graph = true
[]

#------------------------------------------------------------------------------#
