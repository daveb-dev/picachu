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
[GlobalParams]
[]

#------------------------------------------------------------------------------#
[Variables]
  [./w]
  [../]

  [./eta1]
  [../]
  [./eta2]
  [../]
  [./eta3]
  [../]
[]

#------------------------------------------------------------------------------#
# [AuxVariables]
#   [./bnds]
#     order = FIRST
#     family = LAGRANGE
#   [../]
# []

#------------------------------------------------------------------------------#
[ICs]
  [./IC_w]
    type = BoundingBoxIC
    variable = w
    inside = 0
    outside = 0
    y1 = 0
    y2 = 10.0
    x1 = 0
    x2 = 1.0
  [../]

  [./IC_eta1]
    type = BoundingBoxIC
    variable = eta1
    inside = 1.0
    outside = 0.0
    y1 = 0
    y2 = 10.0
    x1 = 0
    x2 = 1.0
  [../]

  [./IC_eta2]
    type = BoundingBoxIC
    variable = eta2
    inside = 0.0
    outside = 1.0
    y1 = 0
    y2 = 10.0
    x1 = 1.0
    x2 = 3.0
  [../]

  [./IC_eta3]
    type = BoundingBoxIC
    variable = eta3
    inside = 0.0
    outside = 1.0
    x1 = 0.0
    x2 = 3.0
    y1 = 10.0
    y2 = 12.0
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
  [./AC_bulk_1]
    type = ACGrGrMulti
    variable = eta1
    v = 'eta2 eta3'
    gamma_names = 'gamma gamma'
  [../]

  [./AC_int_1]
    type = ACInterface
    variable = eta1
  [../]

  [./AC_switch_1]
    type = ACSwitching
    variable = eta1
    Fj_names  = 'GP_fiber GP_char GP_gas'
    hj_names  = 'h1 h2 h3'
    args = 'eta2 eta3 w'
  [../]

  [./eta1_dot]
    type = TimeDerivative
    variable = eta1
  [../]

  #----------------------------------------------------------------------------#
  # Order Parameter Kernels
  [./AC_bulk_2]
    type = ACGrGrMulti
    variable = eta2
    v = 'eta1 eta3'
    gamma_names = 'gamma gamma'
  [../]

  [./AC_int_2]
    type = ACInterface
    variable = eta2
  [../]

  [./AC_switch_2]
    type = ACSwitching
    variable = eta2
    Fj_names  = 'GP_fiber GP_char GP_gas'
    hj_names  = 'h1 h2 h3'
    args = 'eta1 eta3 w'
  [../]

  [./eta2_dot]
    type = TimeDerivative
    variable = eta1
  [../]

  #----------------------------------------------------------------------------#
  # Order Parameter Kernels
  [./AC_bulk_3]
    type = ACGrGrMulti
    variable = eta3
    v = 'eta1 eta2'
    gamma_names = 'gamma gamma'
  [../]

  [./AC_int_3]
    type = ACInterface
    variable = eta3
  [../]

  [./AC_switch_3]
    type = ACSwitching
    variable = eta3
    Fj_names  = 'GP_fiber GP_char GP_gas'
    hj_names  = 'h1 h2 h3'
    args = 'eta1 eta2 w'
  [../]

  [./eta3_dot]
    type = TimeDerivative
    variable = eta3
  [../]


  #----------------------------------------------------------------------------#
  # Coupled Kernels
  [./coupled_eta1dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = eta1
    Fj_names = 'x_fiber x_char x_gas'
    hj_names = 'h1 h2 h3'
    args = 'eta1 eta2 eta3'
  [../]
  [./coupled_eta2dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = eta2
    Fj_names = 'x_fiber x_char x_gas'
    hj_names = 'h1 h2 h3'
    args = 'eta1 eta2 eta3'
  [../]
  [./coupled_eta3dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = eta3
    Fj_names = 'x_fiber x_char x_gas'
    hj_names = 'h1 h2 h3'
    args = 'eta1 eta2 eta3'
  [../]

[]


#------------------------------------------------------------------------------#
# [AuxKernels]
#   [./BndsCalc]
#     type = BndsCalcAux
#     variable = bnds
#     execute_on = timestep_end
#   [../]
# []

#------------------------------------------------------------------------------#
[Materials]
  #----------------------------------------------------------------------------#
  [./constants]
    type = GenericConstantMaterial
    prop_names  = 'D    chi   gamma   mu'
    prop_values = '0.1  1.0   1.0     1.0'
  [../]

  [./interfacial_param]
    type = GenericConstantMaterial
    prop_names  = 'kappa_op     L'
    prop_values = '5e-3          0.1'
  [../]

  [./Va]
    # Units:
    type = GenericConstantMaterial
    prop_names = 'Va'
    prop_values = '1.0'
  [../]

  #----------------------------------------------------------------------------#
  # Order Parameter Materials
  [./switch_1]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h1

    all_etas = 'eta1 eta2 eta3'
    phase_etas = 'eta1'

    outputs = exodus
    output_properties = h1
  [../]
  [./switch_2]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h2

    all_etas = 'eta1 eta2 eta3'
    phase_etas = 'eta2'

    outputs = exodus
    output_properties = h2
  [../]
  [./switch_3]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h3

    all_etas = 'eta1 eta2 eta3'
    phase_etas = 'eta3'

    outputs = exodus
    output_properties = h3
  [../]

  # Concentrations
  [./x_fiber]
    type = DerivativeParsedMaterial
    f_name = x_fiber

    function = 'w/(Va*A) + x_eq'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq  A'
    constant_expressions = '0.3   20.0'

    outputs = exodus
    output_properties = x_sol
  [../]

  [./x_char]
    type = DerivativeParsedMaterial
    f_name = x_char

    function = 'w/(Va*A) + x_eq'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq  A'
    constant_expressions = '0.7   20.0'

    outputs = exodus
    output_properties = x_sol
  [../]

  [./x_gas]
    type = DerivativeParsedMaterial
    f_name = x_gas

    function = 'w/(Va*A) + x_eq'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq  A'
    constant_expressions = '0.1  20.0'

    outputs = exodus
    output_properties = x_gas
  [../]

  # Grand potential density of the gas phase according to parabolic free energy
  [./GP_fiber]
    type = DerivativeParsedMaterial
    f_name = GP_fiber

    function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq  A'
    constant_expressions = '0.3   20.0'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_sol
  [../]

  # Grand potential density of the gas phase according to parabolic free energy
  [./GP_char]
    type = DerivativeParsedMaterial
    f_name = GP_char

    function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq  A'
    constant_expressions = '0.7   20.0'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_sol
  [../]

  # Grand potential density of the gas phase according to parabolic free energy
  [./GP_gas]
    type = DerivativeParsedMaterial
    f_name = GP_gas

    function = 'Ref -0.5*w^2/(Va^2 *A) - x_eq*w/Va'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq  A      Ref'
    constant_expressions = '0.1   20.0    1.0'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_gas
  [../]
[]

#------------------------------------------------------------------------------#
[Postprocessors]
  # [./total_carbon]
  #   type = ElementIntegralMaterialProperty
  #   mat_prop = 'x'
  #   execute_on = 'INITIAL TIMESTEP_END'
  # [../]
  # Stats
  [./dt]
    type = TimestepSize
  [../]
  [./alive_time]
    type = PerformanceData
    event = ALIVE
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

  #end_time = 150
  dtmax = 2

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 1e-2
    growth_factor = 10.0
    cutback_factor = 0.8
    optimal_iterations = 12
    iteration_window = 0
  [../]
[]

#------------------------------------------------------------------------------#
[Outputs]
  exodus = true
  csv = true
  file_base = ./results_multi_v1/PFCOM_GPM_multi_v1_out
  execute_on = 'INITIAL TIMESTEP_END FINAL'
[]

#------------------------------------------------------------------------------#
