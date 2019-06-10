#------------------------------------------------------------------------------#
# Fiber, char and gas simulation (status: not running)
#------------------------------------------------------------------------------#

[Mesh]
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


#------------------------------------------------------------------------------#
[Variables]
  [./w]
  [../]
  [./etaa0]
  [../]
  [./etab0]
  [../]
  [./etag0]
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
  [./IC_etaa0]
    type = FunctionIC
    variable = etaa0
    function = ic_func_fiber
  [../]
  [./IC_etab0]
    type = FunctionIC
    variable = etab0
    function = ic_func_char
  [../]
  [./IC_etag0]
    type = FunctionIC
    variable = etag0
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
    value = '(1/2)^2*(1.0-tanh((x-1.0)/0.1))*(1.0+tanh((-y+10.0)/0.1))'
  [../]
  [./ic_func_char]
    type = ParsedFunction
    value = '(1/2)^2*(1.0-tanh((-x+1.0)/0.1))*(1.0+tanh((-y+10.0)/0.1))'
  [../]
  [./ic_func_gas]
    type = ParsedFunction
    value = '1/2*(1.0+tanh((y-10.0)/0.1))'
  [../]
[]

#------------------------------------------------------------------------------#
[BCs]
[]

#------------------------------------------------------------------------------#
[Kernels]
  #----------------------------------------------------------------------------#
  # Kernels for etaa0 - fiber
  [./AC_bulk_a0]
    type = ACGrGrMulti
    variable = etaa0
    v =           'etab0 etag0'
    gamma_names = 'gab   gag'
  [../]

  [./AC_switch_a0]
    type = ACSwitching
    variable = etaa0
    Fj_names  = 'GP_a GP_b GP_g'
    hj_names  = 'h_a h_b h_g'
    args = 'etab0 etag0 w'
  [../]

  [./AC_int_a0]
    type = ACInterface
    variable = etaa0
    kappa_name = kappa
  [../]

  [./etaa0_dot]
    type = TimeDerivative
    variable = etaa0
  [../]

  #----------------------------------------------------------------------------#
  # Kernels for etab0 - char
  [./AC_bulk_b0]
    type = ACGrGrMulti
    variable = etab0
    v =           'etaa0 etag0'
    gamma_names = 'gab   gbg'
  [../]

  [./AC_switch_b0]
    type = ACSwitching
    variable = etab0
    Fj_names  = 'GP_a GP_b GP_g'
    hj_names  = 'h_a h_b h_g'
    args = 'etaa0 etag0 w'
  [../]

  [./AC_int_b0]
    type = ACInterface
    variable = etab0
    kappa_name = kappa
  [../]

  [./etab0_dot]
    type = TimeDerivative
    variable = etab0
  [../]

  #----------------------------------------------------------------------------#
  # Kernels for etag0 - gas
  [./AC_bulk_g0]
    type = ACGrGrMulti
    variable = etag0
    v =           'etaa0 etab0'
    gamma_names = 'gab   gbg'
  [../]

  [./AC_switch_g0]
    type = ACSwitching
    variable = etag0
    Fj_names  = 'GP_a GP_b GP_g'
    hj_names  = 'h_a h_b h_g'
    args = 'etaa0 etab0 w'
  [../]

  [./AC_int_g0]
    type = ACInterface
    variable = etag0
    kappa_name = kappa
  [../]

  [./etag0_dot]
    type = TimeDerivative
    variable = etag0
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
  [./coupled_etaa0dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = etaa0
    Fj_names  = 'rho_a  rho_b   rho_g'
    hj_names  = 'h_a    h_b     h_g'
    args      = 'etaa0  etab0   etag0'
  [../]

  [./coupled_etab0dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = etab0
    Fj_names  = 'rho_a  rho_b   rho_g'
    hj_names  = 'h_a    h_b     h_g'
    args      = 'etaa0  etab0   etag0'
  [../]

  [./coupled_etag0dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = etag0
    Fj_names  = 'rho_a  rho_b   rho_g'
    hj_names  = 'h_a    h_b     h_g'
    args      = 'etaa0  etab0   etag0'
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
    prop_names =  'kappa_c  kappa   L   D    chi  Vm   ka    caeq kb    cbeq  gab gag gbg mu'
    prop_values = '0        1       1.0 1.0  1.0  1.0  10.0  0.1  10.0  0.9   4.5 2.5 1.5 1.0'
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
    h_name = h_a
    all_etas = 'etaa0 etab0 etag0'
    phase_etas = 'etaa0'
    outputs = exodus
    output_properties = h_a
  [../]
  [./switch_char]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_b
    all_etas = 'etaa0 etab0 etag0'
    phase_etas = 'etab0'
    outputs = exodus
    output_properties = h_b
  [../]
  [./switch_gas]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_g
    all_etas = 'etaa0 etab0 etag0'
    phase_etas = 'etag0'
    outputs = exodus
    output_properties = h_g
  [../]

  #----------------------------------------------------------------------------#
  # Number densities
  [./rho_a]
    type = DerivativeParsedMaterial
    f_name = rho_a

    function = 'w/(Va*A) + x_eq'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A'
    constant_expressions = '0.9    10.0'

    outputs = exodus
    output_properties = rho_a
  [../]

  [./rho_b]
    type = DerivativeParsedMaterial
    f_name = rho_b

    function = '1/Va*(w/(Va*A) + x_eq)'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A'
    constant_expressions = '0.7    10.0'

    outputs = exodus
    output_properties = rho_b
  [../]

  [./rho_g]
    type = DerivativeParsedMaterial
    f_name = rho_g

    function = '1/Va*(w/(Va*A) + x_eq)'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq    A'
    constant_expressions = '0.1     10.0'

    outputs = exodus
    output_properties = rho_g
  [../]

  #----------------------------------------------------------------------------#
  # Grand Potentials
  # Grand potential density of the fiber phase according to a parabolic free energy
  [./GP_a]
    type = DerivativeParsedMaterial
    f_name = GP_a

    function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va +Ref'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A            Ref'
    constant_expressions = '0.9       10.0          0 '

    derivative_order = 2

    outputs = exodus
    output_properties = GP_a
  [../]

  # Grand potential density of the char phase according to a parabolic free energy
  [./GP_b]
    type = DerivativeParsedMaterial
    f_name = GP_b

    function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va +Ref'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq      A      Ref'
    constant_expressions = '0.7    10.0      0'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_b
  [../]

  # Grand potential density of the gas phase according to a parabolic free energy
  [./GP_g]
    type = DerivativeParsedMaterial
    f_name = GP_g

    function = '-0.5*w^2/(Va^2 *A) - x_eq*w/Va'

    args = 'w'
    material_property_names = 'Va'

    constant_names =       'x_eq  A'
    constant_expressions = '0.1   10.0'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_g
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

  #solve_type = NEWTON
  solve_type = PJFNK
  petsc_options_iname = -pc_type
  petsc_options_value = asm

  #petsc_options_iname = '-pc_type -ksp_gmres_restart -sub_pc_type -pc_asm_overlap'
  #petsc_options_value = 'asm      31                  lu           1'

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
  file_base = ./results_GPM_v4/GPM_v4_out
  execute_on = 'INITIAL TIMESTEP_END FINAL'
[]

#------------------------------------------------------------------------------#
[Debug]
  show_var_residual_norms = true
[]
