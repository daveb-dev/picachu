#------------------------------------------------------------------------------#
# Fiber, char and gas simulation (status: not running)
# Trying to make carbon phases be 2 grains
#------------------------------------------------------------------------------#

[Mesh]
  type = GeneratedMesh
  dim = 2

  xmin = 0
  xmax = 20
  nx = 20

  ymin = 0
  ymax = 20
  ny = 20

  uniform_refine = 1
[]

#------------------------------------------------------------------------------#
[GlobalParams]
  op_num = 2
  var_name_base = eta_a
[]

#------------------------------------------------------------------------------#
[Variables]
  [./w]
  [../]
  [./eta_a0]
  [../]
  [./eta_a1]
  [../]
  [./eta_b]
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
  [./IC_eta0]
    type = FunctionIC
    variable = eta_a0
    function = ic_func_fiber
  [../]
  [./IC_eta1]
    type = FunctionIC
    variable = eta_a1
    function = ic_func_char
  [../]
  [./IC_eta2]
    type = FunctionIC
    variable = eta_b
    function = ic_func_gas
  [../]
  [./IC_w]
    type = ConstantIC
    value = -0.05
    variable = w
  [../]
[]

#------------------------------------------------------------------------------#
[Functions]
  [./ic_func_fiber]
    type = ParsedFunction
    value = '0.5*(1.0-tanh((x-10.0)/sqrt(2.0)))*(1.0+tanh((-y+10.0)/sqrt(2.0)))'
  [../]
  [./ic_func_char]
    type = ParsedFunction
    value = '0.5*(1.0-tanh((-x+10.0)/sqrt(2.0)))*(1.0+tanh((-y+10.0)/sqrt(2.0)))'
  [../]
  [./ic_func_gas]
    type = ParsedFunction
    value = '1.0+tanh((y-10.0)/sqrt(2.0))'
  [../]
[]

#------------------------------------------------------------------------------#
[BCs]
[]

#------------------------------------------------------------------------------#
[Kernels]
  #----------------------------------------------------------------------------#
  # Kernels for eta_a0 - fiber
  [./AC_bulk_0]
    type = ACGrGrMulti
    variable = eta_a0
    v =           'eta_a1 eta_b'
    gamma_names = 'gab   gbb'
  [../]

  [./AC_switch_0]
    type = ACSwitching
    variable = eta_a0
    Fj_names  = 'GP_fiber GP_gas'
    hj_names  = 'h_fiber h_gas'
    args = 'eta_a1 eta_b w'
  [../]

  [./AC_int_0]
    type = ACInterface
    variable = eta_a0
    kappa_name = kappa
  [../]

  [./eta0_dot]
    type = TimeDerivative
    variable = eta_a0
  [../]

  #----------------------------------------------------------------------------#
  # Kernels for eta_a1 - char
  [./AC_bulk_1]
    type = ACGrGrMulti
    variable = eta_a1
    v =           'eta_a0 eta_b'
    gamma_names = 'gab   gbb'
  [../]

  [./AC_switch_1]
    type = ACSwitching
    variable = eta_a1
    Fj_names  = 'GP_fiber GP_gas'
    hj_names  = 'h_fiber h_gas'
    args = 'eta_a0 eta_b w'
  [../]

  [./AC_int_1]
    type = ACInterface
    variable = eta_a1
    kappa_name = kappa
  [../]

  [./eta1_dot]
    type = TimeDerivative
    variable = eta_a1
  [../]

  #----------------------------------------------------------------------------#
  # Kernels for eta_b - gas
  [./AC_bulk_2]
    type = ACGrGrMulti
    variable = eta_b
    v =           'eta_a0 eta_a1'
    gamma_names = 'gbb   gbb'
  [../]

  [./AC_switch_2]
    type = ACSwitching
    variable = eta_b
    Fj_names  = 'GP_fiber GP_gas'
    hj_names  = 'h_fiber h_gas'
    args = 'eta_a0 eta_a1 w'
  [../]

  [./AC_int_2]
    type = ACInterface
    variable = eta_b
    kappa_name = kappa
  [../]

  [./eta2_dot]
    type = TimeDerivative
    variable = eta_b
  [../]

  #----------------------------------------------------------------------------#
  #Chemical potential
  [./w_dot]
    type = SusceptibilityTimeDerivative
    variable = w
    f_name = chi
    args = '' # in this case chi (the susceptibility) is simply a constant
  [../]

  [./Diffusion]
    type = MatDiffusion
    variable = w
    D_name = Dchi
    args = ''
  [../]

  #----------------------------------------------------------------------------#
  # Coupled Kernels
  [./coupled_eta0dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = eta_a0
    Fj_names = 'x_fiber x_gas'
    hj_names = 'h_fiber   h_gas'
    args = 'eta_a0 eta_a1 eta_b'
  [../]

  [./coupled_eta1dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = eta_a1
    Fj_names = 'x_fiber x_gas'
    hj_names = 'h_fiber h_gas'
    args = 'eta_a0 eta_a1  eta_b'
  [../]

  [./coupled_eta2dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = eta_b
    Fj_names = 'x_fiber x_gas'
    hj_names = 'h_fiber h_gas'
    args = 'eta_a0 eta_a1 eta_b'
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
  [./const]
    type = GenericConstantMaterial
    prop_names =  'kappa_c  kappa   L   D    chi  Vm   ka    caeq kb    cbeq  gab gbb mu'
    prop_values = '0        1       1.0 1.0  1.0  1.0  10.0  0.1  10.0  0.9   4.5 1.5 1.0'
  [../]

  [./Mobility]
    type = DerivativeParsedMaterial
    f_name = Dchi
    material_property_names = 'D chi'
    function = 'D*chi'
    derivative_order = 2
    enable_jit = false
  [../]


  #----------------------------------------------------------------------------#
  # Switching Functions
  [./switch_fiber]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_fiber

    all_etas = 'eta_a0 eta_a1 eta_b'
    phase_etas = 'eta_a0 eta_a1'

    outputs = exodus
    output_properties = h_fiber
  [../]
  # [./switch_char]
  #   type = SwitchingFunctionMultiPhaseMaterial
  #   h_name = h_char
  #
  #   all_etas = 'eta_a0 eta_a1 eta_b'
  #   phase_etas = 'eta_a1'
  #
  #   outputs = exodus
  #   output_properties = h_char
  # [../]
  [./switch_gas]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_gas

    all_etas = 'eta_a0 eta_a1 eta_b'
    phase_etas = 'eta_b'

    outputs = exodus
    output_properties = h_gas
  [../]

  #----------------------------------------------------------------------------#
  # Concentrations
  [./x_fiber]
    type = DerivativeParsedMaterial
    f_name = x_fiber

    function = 'w/(Va*A) + x_eq'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A'
    constant_expressions = '0.9    10.0'

    outputs = exodus
    output_properties = x_fiber
  [../]

  # [./x_char]
  #   type = DerivativeParsedMaterial
  #   f_name = x_char
  #
  #   function = 'w/(Va*A) + x_eq'
  #
  #   args = 'w'
  #   material_property_names = 'Va'
  #
  #   constant_names =       'x_eq      A'
  #   constant_expressions = '0.7    10.0'
  #
  #   outputs = exodus
  #   output_properties = x_char
  # [../]

  [./x_gas]
    type = DerivativeParsedMaterial
    f_name = x_gas

    function = 'w/(Va*A) + x_eq'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq    A'
    constant_expressions = '0.1     10.0'

    outputs = exodus
    output_properties = x_gas
  [../]

  #----------------------------------------------------------------------------#
  # Grand Potentials
  # Grand potential density of the fiber phase according to a parabolic free energy
  [./GP_fiber]
    type = DerivativeParsedMaterial
    f_name = GP_fiber

    function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va +Ref'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A            Ref'
    constant_expressions = '0.9       10.0          0 '

    derivative_order = 2

    outputs = exodus
    output_properties = GP_fiber
  [../]

  # Grand potential density of the char phase according to a parabolic free energy
  # [./GP_char]
  #   type = DerivativeParsedMaterial
  #   f_name = GP_char
  #
  #   function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va +Ref'
  #
  #   args = 'w'
  #   material_property_names = 'Va'
  #
  #   constant_names =       'x_eq      A            Ref'
  #   constant_expressions = '0.7    10.0      0'
  #
  #   derivative_order = 2
  #
  #   outputs = exodus
  #   output_properties = GP_char
  # [../]

  # Grand potential density of the gas phase according to a parabolic free energy
  [./GP_gas]
    type = DerivativeParsedMaterial
    f_name = GP_gas

    function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq  A'
    constant_expressions = '0.1   10.0'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_gas
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

  petsc_options_iname = '-pc_type -ksp_gmres_restart -sub_pc_type -pc_asm_overlap'
  petsc_options_value = 'asm      31                  lu           1'

  l_tol = 1.0e-3
  nl_rel_tol = 1.0e-8
  nl_abs_tol = 1e-8
  num_steps = 2

  [./TimeStepper]
    type = SolutionTimeAdaptiveDT
    dt = 0.1
  [../]
[]

#------------------------------------------------------------------------------#
[Outputs]
  exodus = true
  csv = true
  file_base = ./results_GPM_v5/GPM_v5_out
  execute_on = 'INITIAL TIMESTEP_END FINAL'
[]

#------------------------------------------------------------------------------#
[Debug]
  show_var_residual_norms = true
[]
