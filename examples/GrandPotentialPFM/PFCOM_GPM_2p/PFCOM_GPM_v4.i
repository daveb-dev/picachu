#------------------------------------------------------------------------------#
# PFCOM using the grand potential model
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
  # IC Coordinates
  y1 = 0
  y2 = 10.0
  x1 = 0
  x2 = 1.0
[]

#------------------------------------------------------------------------------#
[Variables]
  [./w]
  [../]

  [./eta]
  [../]
[]

#------------------------------------------------------------------------------#
[ICs]
  [./IC_w]
    type = BoundingBoxIC
    variable = w
    inside = 0
    outside = 0
  [../]

  [./IC_eta]
    type = BoundingBoxIC
    variable = eta
    inside = 0.0
    outside = 1.0
  [../]
[]

#------------------------------------------------------------------------------#
[Kernels]
  #----------------------------------------------------------------------------#
  # Susceptibility
  [./w_dot]
    type = SusceptibilityTimeDerivative
    variable = w
    f_name = chi
    args = ''
  [../]

  #----------------------------------------------------------------------------#
  # Diffusion Kernel (-D grad(u))
  [./Diffusion]
    type = MatDiffusion
    variable = w
    D_name = D
    args = ''
  [../]

  #----------------------------------------------------------------------------#
  # Order Parameter Kernels
  [./AC_bulk]
    type = AllenCahn
    variable = eta
    f_name = GP_total
    args = 'w'
  [../]

  [./AC_int]
    type = ACInterface
    variable = eta
  [../]

  [./e_dot]
    type = TimeDerivative
    variable = eta
  [../]

  #----------------------------------------------------------------------------#
  # Coupled Kernels
  [./coupled_etadot]
    type = CoupledSusceptibilityTimeDerivative
    variable = w
    v = eta
    f_name = ft
    args = 'eta'
  [../]

[]

#------------------------------------------------------------------------------#
[Materials]
  #----------------------------------------------------------------------------#
  [./constants]
    type = GenericConstantMaterial
    prop_names  = 'D      chi'
    prop_values = '0.1   0.03'
  [../]

  [./interfacial_param]
    type = GenericConstantMaterial
    prop_names  = 'kappa_op     L'
    prop_values = '1e-2         1e-3'
  [../]

  [./Va]
    # Units:
    type = GenericConstantMaterial
    prop_names = 'Va'
    prop_values = '1.0'
  [../]

  #----------------------------------------------------------------------------#
  # Order Parameter Materials
  [./switching_function]
    type = SwitchingFunctionMaterial
    function_name = h

    eta = eta
    h_order =  HIGH

    outputs = exodus
    output_properties = h
  [../]

  [./barrier_function]
    type = BarrierFunctionMaterial
    function_name = g

    eta = eta

    g_order =  SIMPLE

    outputs = exodus
    output_properties = g
  [../]

  [./coupled_eta_function]
    type = DerivativeParsedMaterial
    f_name = ft

    function = '1 / Va * (x_s - x_g) * dh'

    args = 'eta'
    material_property_names = 'Va dh:=D[h,eta]'

    constant_names =       'x_g   x_s'
    constant_expressions = '0.0   0.9702'

    derivative_order = 1

    outputs = exodus
  [../]

  # Concentrations
  [./x_sol]
    type = DerivativeParsedMaterial
    f_name = x_sol

    function = 'w/(Va*A) + x_eq'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A'
    constant_expressions = '0.9702    34.5350'

    outputs = exodus
    output_properties = x_sol
    enable_jit = false
  [../]

  [./x_gas]
    type = DerivativeParsedMaterial
    f_name = x_gas

    function = 'w/(Va*A) + x_eq'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq    A'
    constant_expressions = '0.0     30.0'

    outputs = exodus
    output_properties = x_gas
    enable_jit = false
  [../]

  # Grand potential density of the gas phase according to parabolic free energy
  [./GP_sol]
    type = DerivativeParsedMaterial
    f_name = GP_sol

    function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va +Ref'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A            Ref'
    constant_expressions = '0.9702    34.5350      -0.0052'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_sol
    enable_jit = false
  [../]

  # Grand potential density of the gas phase according to parabolic free energy
  [./GP_gas]
    type = DerivativeParsedMaterial
    f_name = GP_gas

    function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq  A'
    constant_expressions = '0.0   30.0'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_gas
    enable_jit = false
  [../]

  #----------------------------------------------------------------------------#
  # TOTAL GRAND POTENTIAL
  #----------------------------------------------------------------------------#
  # Molar fraction throughout the entire domain
  [./x]
    type = DerivativeParsedMaterial
    f_name = x

    function = '(1-h)*x_sol + h*x_gas'

    args = 'w eta'

    material_property_names = 'h(eta) x_sol x_gas'

    derivative_order = 2

    outputs = exodus
    output_properties = x
  [../]


  # Total GP
  [./total_GrandPotential]
    type = DerivativeParsedMaterial
    f_name = GP_total

    function = 'h*GP_gas + (1-h)*GP_sol'

    args = 'w eta'
    material_property_names = 'h(eta) GP_gas(w) GP_sol(w)'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_total
  [../]
[]

#------------------------------------------------------------------------------#
[Postprocessors]
  [./total_carbon]
    type = ElementIntegralMaterialProperty
    mat_prop = 'x'
    execute_on = 'INITIAL TIMESTEP_END'
  [../]
  [./total_GP]
    type = ElementIntegralMaterialProperty
    mat_prop = 'GP_total'
    execute_on = 'INITIAL TIMESTEP_END'
  [../]

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
    growth_factor = 2.0
    cutback_factor = 0.8
    optimal_iterations = 12
    iteration_window = 0
  [../]
[]

#------------------------------------------------------------------------------#
[Outputs]
  exodus = true
  csv = true
  file_base = ./results_v4/PFCOM_GPM_v4_out
  execute_on = 'INITIAL TIMESTEP_END FINAL'
  perf_graph = true
[]

#------------------------------------------------------------------------------#
