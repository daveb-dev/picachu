#------------------------------------------------------------------------------#
# PFCOM using the grand potential model
# Using function IC for a hyperbolic tangent profile
# Added oxygen
#------------------------------------------------------------------------------#
[Mesh]
  # length scale -> microns
  type = GeneratedMesh
  dim = 2

  xmin = 0.0
  xmax = 3.0
  nx = 6

  ymin = 0.0
  ymax = 12.0
  ny = 24
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
  [./w_o]
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
    value = -0.5
  [../]

  [./IC_w_o]
    type = ConstantIC
    variable = w_o
    value = -0.5
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
[Kernels]
  #----------------------------------------------------------------------------#
  # eta0 kernels
  [./AC0_bulk]
    type = ACGrGrMulti
    variable = eta0
    v =           'eta1'
    gamma_names = 'gamma'
    mob_name = L
  [../]

  [./AC0_sw]
    type = ACSwitching
    variable = eta0
    Fj_names  = 'omega_a omega_b'
    hj_names  = 'h_a     h_b'
    args = 'eta1 w_c w_o'
    mob_name = L
  [../]

  [./AC0_int]
    type = ACInterface
    variable = eta0
    kappa_name = kappa
    mob_name = L
  [../]

  [./eta0_dot]
    type = TimeDerivative
    variable = eta0
  [../]

  #----------------------------------------------------------------------------#
  # eta1 kernels
  [./AC1_bulk]
    type = ACGrGrMulti
    variable = eta1
    v =           'eta0'
    gamma_names = 'gamma'
    mob_name = L
  [../]

  [./AC1_sw]
    type = ACSwitching
    variable = eta1
    Fj_names  = 'omega_a omega_b'
    hj_names  = 'h_a     h_b'
    args = 'eta0 w_c w_o'
    mob_name = L
  [../]

  [./AC1_int]
    type = ACInterface
    variable = eta1
    kappa_name = kappa
    mob_name = L
  [../]

  [./eta1_dot]
    type = TimeDerivative
    variable = eta1
  [../]

  [./w_c_dot]
    type = SusceptibilityTimeDerivative
    variable = w_c
    f_name = chi
    args = ''
  [../]

  [./diffusion_c]
    type = MatDiffusion
    variable = w_c
    diffusivity = Dchi
    args = ''
  [../]

  [./w_o_dot]
    type = SusceptibilityTimeDerivative
    variable = w_o
    f_name = chi
    args = ''
  [../]

  [./diffusion_o]
    type = MatDiffusion
    variable = w_o
    diffusivity = Dchi
    args = ''
  [../]


  [./coupled_eta0dot_c]
    type = CoupledSwitchingTimeDerivative
    variable = w_c
    v = eta0
    Fj_names = 'rho_c_a rho_c_b'
    hj_names = 'h_a   h_b   '
    args = 'eta0 eta1 w_o'
  [../]

  [./coupled_eta1dot_c]
    type = CoupledSwitchingTimeDerivative
    variable = w_c
    v = eta1
    Fj_names = 'rho_c_a rho_c_b'
    hj_names = 'h_a   h_b'
    args = 'eta0 eta1 w_o'
  [../]

  [./coupled_eta0dot_o]
    type = CoupledSwitchingTimeDerivative
    variable = w_o
    v = eta0
    Fj_names = 'rho_o_a rho_o_b'
    hj_names = 'h_a   h_b   '
    args = 'eta0 eta1 w_c'
  [../]

  [./coupled_eta1dot_o]
    type = CoupledSwitchingTimeDerivative
    variable = w_o
    v = eta1
    Fj_names = 'rho_o_a rho_o_b'
    hj_names = 'h_a   h_b   '
    args = 'eta0 eta1 w_c'
  [../]
[]

#------------------------------------------------------------------------------#
[Materials]
  #----------------------------------------------------------------------------#
  [./constants]
    type = GenericConstantMaterial
    prop_names  = 'D     chi    gamma   mu   Dchi'
    prop_values = '0.1   0.03    1.5    1.0  0.003'
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

  [./params_oxygen]
    type = GenericConstantMaterial
    prop_names =  'xeq_o_b    xeq_o_a   A_o_b   A_o_a'
    prop_values = '0.9          0.1           1.0       100.0'
  [../]

  [./params_carbon]
    type = GenericConstantMaterial
    prop_names =  'xeq_c_b    xeq_c_a   A_c_b   A_c_a'
    prop_values = '0.1          0.9           1.0       100.0'
  [../]

  #0.9702    34.5350
  #----------------------------------------------------------------------------#
  # Switching Functions
  [./h_a]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_a
    all_etas = 'eta0 eta1'
    phase_etas = 'eta0'

    outputs = exodus
    output_properties = h_a
  [../]

  [./h_b]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_b
    all_etas = 'eta0 eta1'
    phase_etas = 'eta1'

    outputs = exodus
    output_properties = h_b
  [../]

  #----------------------------------------------------------------------------#
  # Concentrations

  #----------------------------------------------------------------------------#
  # Carbon
  [./rho_c_a]
    type = DerivativeParsedMaterial
    f_name = rho_c_a

    function = 'w_c/(Va^2*A_c_a) + xeq_c_a/Va'

    args = 'w_c'
    material_property_names = 'Va A_c_a xeq_c_a'

    outputs = exodus
    output_properties = rho_c_a
    enable_jit = false
  [../]
  [./rho_c_b]
    type = DerivativeParsedMaterial
    f_name = rho_c_b

    function = 'w_c/(Va^2*A_c_b) + xeq_c_b/Va'

    args = 'w_c'
    material_property_names = 'Va A_c_b xeq_c_b'

    outputs = exodus
    output_properties = rho_c_b
    enable_jit = false
  [../]
  [./x_c]
    type = DerivativeParsedMaterial
    f_name = x_c

    function = 'h_a*rho_c_a + h_b*rho_c_b'

    args = ''
    material_property_names = 'h_a h_b rho_c_a rho_c_b'

    outputs = exodus
    output_properties = x_c
    enable_jit = false
  [../]


  #----------------------------------------------------------------------------#
  # Oxygen
  [./rho_o_a]
    type = DerivativeParsedMaterial
    f_name = rho_o_a

    function = 'w_c/(Va^2*A_o_a) + xeq_o_a/Va'

    args = 'w_c'
    material_property_names = 'Va A_o_a xeq_o_a'

    outputs = exodus
    output_properties = rho_o_a
    enable_jit = false
  [../]
  [./rho_o_b]
    type = DerivativeParsedMaterial
    f_name = rho_o_b

    function = 'w_o/(Va^2*A_o_b) + xeq_o_b/Va'

    args = 'w_o'
    material_property_names = 'Va A_o_b xeq_o_b'

    outputs = exodus
    output_properties = rho_o_b
    enable_jit = false
  [../]
  [./x_o]
    type = DerivativeParsedMaterial
    f_name = x_o

    function = 'h_a*rho_o_a + h_b*rho_o_b'

    args = ''
    material_property_names = 'h_a h_b rho_o_a rho_o_b'

    outputs = exodus
    output_properties = x_o
    enable_jit = false
  [../]


  #----------------------------------------------------------------------------#
  # Grand potential density of the fiber phase according to parabolic free energy
  [./omega_test]
    type = MultiParabolicGrandPotential
    f_name = omega_test

    phase_ws = 'w_c w_o'
    A = '100 100'
    Va = '1 1'
    c_eq = '0.9 0.1'

    derivative_order = 2
    outputs = exodus
  [../]

  #----------------------------------------------------------------------------#
  # Grand potential density of the fiber phase according to parabolic free energy
  [./omega_a]
    type = DerivativeParsedMaterial
    f_name = omega_a

    function = '-0.5*w_c^2/(Va^2 *A_c_a) - xeq_c_a*w_c/Va +Ref
                -0.5*w_o^2/(Va^2 *A_o_a) - xeq_o_a*w_o/Va'

    args = 'w_c w_o'
    material_property_names = 'Va A_c_a A_o_a xeq_c_a xeq_o_a'

    constant_names =       'Ref'
    constant_expressions = '0'

    derivative_order = 2

    outputs = exodus

  [../]

  # Grand potential density of the gas phase according to parabolic free energy
  [./omega_b]
    type = DerivativeParsedMaterial
    f_name = omega_b

    function = '-0.5*w_c^2/(Va^2 *A_c_b) - xeq_c_b*w_c/Va
                -0.5*w_o^2/(Va^2 *A_o_b) - xeq_o_b*w_o/Va'

    args = 'w_c w_o'
    material_property_names = 'Va A_c_b A_o_b xeq_c_b xeq_o_b'

    derivative_order = 2

    outputs = exodus

  [../]

[]

#------------------------------------------------------------------------------#
[Postprocessors]
  [./GP_parsed]
    type = ElementIntegralMaterialProperty
    mat_prop = 'omega_a'
    execute_on = 'initial timestep_end'
  [../]

  [./GP_material]
    type = ElementIntegralMaterialProperty
    mat_prop = 'omega_test'
    execute_on = 'initial timestep_end'
  [../]

  [./diff]
    type = DifferencePostprocessor
    value1 = GP_parsed
    value2 = GP_material
    execute_on = 'initial timestep_end'
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
  # solve_type = NEWTON

  # NEWTON Takes 172s to run 20 timesteps, reaches 48s with a max dt of 8
  # All the shabang below takes 510s, reaches 1212s!!, max dt of 219!

  petsc_options_iname = '-pc_type -ksp_gmres_restart -sub_pc_type -pc_asm_overlap'
  petsc_options_value = 'asm      31                  lu           1'

  l_max_its = 15
  l_tol = 1e-3
  nl_max_its = 15
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-8

  num_steps = 2
  dt = 1e-2

  # [./Predictor]
  #   type = SimplePredictor
  #   scale = 1
  # [../]
  #
  # [./TimeStepper]
  #   type = IterationAdaptiveDT
  #   dt = 1e-2
  #   growth_factor = 1.2
  #   cutback_factor = 0.8
  #   optimal_iterations = 12
  #   iteration_window = 0
  # [../]
[]

#------------------------------------------------------------------------------#
[Outputs]
  exodus = true
  execute_on = 'INITIAL TIMESTEP_END FINAL'
[]

#------------------------------------------------------------------------------#
