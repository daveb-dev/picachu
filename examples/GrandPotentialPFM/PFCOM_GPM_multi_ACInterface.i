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
  int_width = 0.25
[]

#------------------------------------------------------------------------------#
[Variables]
  [./w]
  [../]

  [./eta1]
  [../]
  [./eta2]
  [../]
  # [./eta3]
  # [../]
[]

#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
[ICs]
  [./IC_w]
    type = BoundingBoxIC_TANH
    variable = w
    inside = 0
    outside = 0
    y1 = 0
    y2 = 10.0
    x1 = 0
    x2 = 1.0
  [../]

  [./IC_eta1]
    type = BoundingBoxIC_TANH
    variable = eta1
    inside = 1.0
    outside = 0.0
    y1 = 0
    y2 = 10.0
    x1 = 0
    x2 = 1.0
  [../]

  [./IC_eta2]
    type = BoundingBoxIC_TANH
    variable = eta2
    inside = 0.0
    outside = 1.0
    y1 = 0
    y2 = 10.0
    x1 = 0
    x2 = 1.0
    # y1 = 0
    # y2 = 10.0
    # x1 = 1.0
    # x2 = 3.0
  [../]

  # [./IC_eta3]
  #   type = BoundingBoxIC
  #   variable = eta3
  #   inside = 1.0
  #   outside = 0.0
  #   x1 = 0.0
  #   x2 = 3.0
  #   y1 = 10.0
  #   y2 = 12.0
  # [../]
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
    type = AllenCahn
    variable = eta1
    mob_name = L
    f_name = GP_total
    args = 'w eta2'# eta3'
  [../]

  [./AC_multi_int_1]
    type = ACInterface
    variable = eta1
    kappa_name = kappa_op
  [../]

  [./AC_switch_1]
    type = ACSwitching
    variable = eta1
    Fj_names  = 'GP_fiber GP_char' #GP_gas'
    hj_names  = 'h1 h2' #h3
    args = 'eta2 w' #eta3
  [../]

  [./eta1_dot]
    type = TimeDerivative
    variable = eta1
  [../]

  #----------------------------------------------------------------------------#
  # Order Parameter Kernels
  [./AC_bulk_2]
    type = AllenCahn
    f_name = GP_total
    variable = eta2
    mob_name = L
    args = 'w eta1'# eta3'
  [../]

  [./AC_multi_int_2]
    type = ACInterface
    variable = eta2
    kappa_name = kappa_op
  [../]

  [./AC_switch_2]
    type = ACSwitching
    variable = eta2
    Fj_names  = 'GP_fiber GP_char'# GP_gas'
    hj_names  = 'h1 h2'# h3'
    args = 'eta1 w'#eta3
  [../]

  [./eta2_dot]
    type = TimeDerivative
    variable = eta1
  [../]

  #----------------------------------------------------------------------------#
  # Order Parameter Kernels
  # [./AC_bulk_3]
  #   type = AllenCahn
  #   f_name = GP_total
  #   variable = eta3
  #   mob_name = L
  #   args = 'w eta1 eta2'
  # [../]
  #
  # [./AC_multi_int_3]
  #   type = ACMultiInterface
  #   variable = eta3
  #   mob_name = L
  #   etas = 'eta1 eta2 eta3'
  #   kappa_names = 'kappa31 kappa32 kappa33'
  # [../]
  #
  #
  # [./AC_switch_3]
  #   type = ACSwitching
  #   variable = eta3
  #   Fj_names  = 'GP_fiber GP_char GP_gas'
  #   hj_names  = 'h1 h2 h3'
  #   args = 'eta1 eta2 w'
  # [../]
  #
  # [./eta3_dot]
  #   type = TimeDerivative
  #   variable = eta3
  # [../]

  #----------------------------------------------------------------------------#
  # Coupled Kernels
  [./coupled_eta1dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = eta1
    Fj_names = 'x_fiber x_char'# x_gas'
    hj_names = 'h1 h2'# h3'
    args = 'eta1 eta2'# eta3'
  [../]
  [./coupled_eta2dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = eta2
    Fj_names = 'x_fiber x_char'# x_gas'
    hj_names = 'h1 h2'# h3'
    args = 'eta1 eta2'# eta3'
  [../]
  # [./coupled_eta3dot]
  #   type = CoupledSwitchingTimeDerivative
  #   variable = w
  #   v = eta3
  #   Fj_names = 'x_fiber x_char x_gas'
  #   hj_names = 'h1 h2 h3'
  #   args = 'eta1 eta2 eta3'
  # [../]

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
  [./kappas]
    type = GenericConstantMaterial

    prop_values ='1e-3 1e-3 1e-3
                  1e-3 1e-3 1e-3
                  1e-3 1e-3 1e-3'

    prop_names = 'kappa11 kappa12 kappa13
                  kappa21 kappa22 kappa23
                  kappa31 kappa32 kappa33'
  [../]
  [./constants]
    type = GenericConstantMaterial
    prop_names  = 'D      chi'
    prop_values = '0.1    0.03'
  [../]

  [./interfacial_param]
    type = GenericConstantMaterial
    prop_names  = 'kappa_op     L'
    prop_values = '1e-3         1e-3'
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

    all_etas = 'eta1 eta2'# eta3'
    phase_etas = 'eta1'

    outputs = exodus
    output_properties = h1
  [../]
  [./switch_2]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h2

    all_etas = 'eta1 eta2'# eta3'
    phase_etas = 'eta2'

    outputs = exodus
    output_properties = h2
  [../]
  # [./switch_3]
  #   type = SwitchingFunctionMultiPhaseMaterial
  #   h_name = h3
  #
  #   all_etas = 'eta1 eta2 eta3'
  #   phase_etas = 'eta3'
  #
  #   outputs = exodus
  #   output_properties = h3
  # [../]

  # Concentrations
  [./x_fiber]
    type = DerivativeParsedMaterial
    f_name = x_fiber

    function = 'w/(Va*A) + x_eq'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A'
    constant_expressions = '0.9702    34.5350'

    outputs = exodus
    output_properties = x_fiber
    enable_jit = false
  [../]

  [./x_char]
    type = DerivativeParsedMaterial
    f_name = x_char

    function = 'w/(Va*A) + x_eq'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A'
    constant_expressions = '0.9702    34.5350'

    outputs = exodus
    output_properties = x_char
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
  [./GP_fiber]
    type = DerivativeParsedMaterial
    f_name = GP_fiber

    function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va +Ref'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A            Ref'
    constant_expressions = '0.9702    34.5350      -0.0052'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_fiber
    enable_jit = false
  [../]

  # Grand potential density of the gas phase according to parabolic free energy
  [./GP_char]
    type = DerivativeParsedMaterial
    f_name = GP_char

    function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va +Ref'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A            Ref'
    constant_expressions = '0.9702    34.5350      -0.0052'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_char
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

  # Total GP
  [./total_GrandPotential]
    type = DerivativeParsedMaterial
    f_name = GP_total

    function = 'h1*GP_fiber +h2*GP_char'# + h3*GP_gas'

    args = 'w eta1 eta2'# eta3'
    material_property_names = 'h1 h2 GP_fiber(w) GP_char(w) GP_gas(w)'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_total
  [../]
[]

#------------------------------------------------------------------------------#
[Postprocessors]
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
  # solve_type = NEWTON
  type = Transient
  scheme = bdf2

  # petsc_options_iname = '-pc_type -ksp_gmres_restart -sub_pc_type -pc_asm_overlap'
  # petsc_options_value = 'asm      31                  lu           1'

  solve_type = PJFNK
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart'
  petsc_options_value = 'hypre    boomeramg      31'

  l_max_its = 15
  l_tol = 1e-3
  nl_max_its = 10
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-8

  end_time = 1e4
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
  file_base = ./results_multi_v2/PFCOM_GPM_multi_v2_out
  execute_on = 'INITIAL TIMESTEP_END FINAL'
[]

#------------------------------------------------------------------------------#
