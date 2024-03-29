#------------------------------------------------------------------------------#
# 3-phase GPM simulation
# with oxidation
# Based on multi_multi_v3
#------------------------------------------------------------------------------#
[Mesh]
  type = GeneratedMesh
  dim = 2

  xmin = 0
  xmax = 4
  nx = 40


  ymin = 0
  ymax = 11
  ny = 110

  uniform_refine = 1

  #skip_partitioning = false
[]
#------------------------------------------------------------------------------#
[Problem]
  type = FEProblem
  coord_type = RZ
  rz_coord_axis = Y
[]

[GlobalParams]
  # Interface thickness from Grand Potential material
  width = 0.2
[../]

#------------------------------------------------------------------------------#
[Functions]
  [./ic_func_etaa0]
    type = ParsedFunction
    value = 'int_thick:=0.2; 1e-18+ 0.5^2*(1.0-tanh(pi*(x-1.0)/int_thick))*(1.0+tanh(pi*(-y+10.0)/int_thick))'
  [../]
  [./ic_func_etab0]
    type = ParsedFunction
    value = 'int_thick:=0.2; 1e-18+ 0.5^2*(1.0+tanh(pi*(x-1.0)/int_thick))*(1.0+tanh(pi*(-y+10.0)/int_thick))'
  [../]
  [./ic_func_etag0]
    type = ParsedFunction
    value = 'int_thick:=0.2; 1e-18+ 0.5*(1.0+tanh(pi*(y-10.0)/int_thick))'
  [../]
  [./ic_func_oxygen]
    type = ParsedFunction
    value = 'int_thick:=0.2; -3*(0.5^2*(1.0+tanh(pi*(x-1.0)/int_thick))*(1.0+tanh(pi*(-y+10.0)/int_thick)))'
  [../]
[]

#------------------------------------------------------------------------------#
# Bnds stuff
[AuxVariables]
  [./bnds]
    order = FIRST
    family = LAGRANGE
  [../]

  # Auxiliary variables for Reaction_GPM kernel
  [./rho_c_var]
    family = MONOMIAL
    order = CONSTANT
  [../]
  [./rho_o_var]
    family = MONOMIAL
    order = CONSTANT
  [../]
  [./rho_m_var]
    family = MONOMIAL
    order = CONSTANT
  [../]

  [./recomb_m_var]
    # family = MONOMIAL
    # order = CONSTANT
  [../]
  [./recomb_o_var]
    # family = MONOMIAL
    # order = CONSTANT
  [../]
[]

[AuxKernels]
  [./BndsCalc]
    type = BndsCalcAux
    variable = bnds
    execute_on = timestep_end
    v = 'etaa0 etab0 etag0'
    var_name_base = 'eta'
  [../]

  [./rho_c_aux]
    type = MaterialRealAux
    property = 'rho_c'
    variable = rho_c_var
  [../]
  [./rho_o_aux]
    type = MaterialRealAux
    property = 'rho_o'
    variable = rho_o_var
  [../]
  [./rho_m_aux]
    type = MaterialRealAux
    property = 'rho_m'
    variable = rho_m_var
  [../]
[]

#------------------------------------------------------------------------------#
[Variables]
  [./w_c]
  [../]
  [./w_m]
  [../]
  [./w_o]
  [../]

  #Phase alpha: carbon fiber
  [./etaa0]
  [../]
  #Phase beta: char
  [./etab0]
  [../]
  #Phase gamma: gas
  [./etag0]
  [../]
[]

#------------------------------------------------------------------------------#
[ICs]
  [./IC_etaa0]
    type = FunctionIC
    variable = etaa0
    function = ic_func_etaa0
  [../]
  [./IC_etab0]
    type = FunctionIC
    variable = etab0
    function = ic_func_etab0
  [../]
  [./IC_etag0]
    type = FunctionIC
    variable = etag0
    function = ic_func_etag0
  [../]
  [./IC_w_c]
    type = ConstantIC
    variable = w_c
    value = 0.0
  [../]
  [./IC_w_o]
    type = ConstantIC
    variable = w_o
    value = 0.0
  [../]
  [./IC_w_m]
    type = ConstantIC
    variable = w_m
    value = 0.0
  [../]
  # [./IC_oxygen]
  #   type = FunctionIC
  #   variable = w_o
  #   function = ic_func_oxygen
  # [../]
[]

#------------------------------------------------------------------------------#
  #    #  ######  #####   #    #  ######  #        ####
  #   #   #       #    #  ##   #  #       #       #
  ####    #####   #    #  # #  #  #####   #        ####
  #  #    #       #####   #  # #  #       #            #
  #   #   #       #   #   #   ##  #       #       #    #
  #    #  ######  #    #  #    #  ######  ######   ####
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
[Kernels]
  # Chemical reaction
  # [./Recomb_C]
  #   type = Reaction_GPM
  #   mob_name = K
  #   atomic_vol = Va
  #   variable = w_c
  #   v = 'rho_c_var'
  #   w = 'rho_o_var'
  #   #args = 'etaa0 etab0 etag0 rho_m_var'
  # [../]
  # [./Recomb_O] #From c
  #   type = Reaction_GPM
  #   mob_name = K
  #   atomic_vol = Va
  #   variable = w_o
  #   v = 'rho_o_var'
  #   w = 'rho_c_var'
  #   save_in = recomb_o_var
  #   #args = 'etaa0 etab0 etag0 rho_m_var'
  # [../]


  [./Recomb_O] #From m
    type = Reaction_GPM
    mob_name = K
    atomic_vol = Va
    variable = w_o
    v = 'rho_o_var'
    w = 'rho_m_var'
    save_in = recomb_o_var
    #args = 'etaa0 etab0 etag0 rho_m_var'
  [../]

  [./Recomb_M]
    type = Reaction_GPM
    mob_name = K
    atomic_vol = Va
    variable = w_m
    v = 'rho_o_var'
    w = 'rho_m_var'
    save_in = recomb_m_var
    #args = 'etaa0 etab0 etag0 rho_m_var'
  [../]

  #----------------------------------------------------------------------------#
  # etaa0 kernels
  [./ACa0_bulk]
    type = ACGrGrMulti
    variable = etaa0
    v =           'etab0 etag0'
    gamma_names = 'gab   gag'
    mob_name = L
    args = 'etaa0 etab0 etag0'
  [../]

  [./ACa0_sw]
    type = ACSwitching
    variable = etaa0
    Fj_names  = 'omega_a omega_b omega_g'
    hj_names  = 'h_a     h_b     h_g'
    args = 'etaa0 etab0 etag0 w_c w_o w_m'
    mob_name = L
  [../]

  [./ACa0_int]
    type = ACInterface
    variable = etaa0
    kappa_name = kappa
    mob_name = L
    args = 'etab0 etag0'

  [../]

  [./etaa0_dot]
    type = TimeDerivative
    variable = etaa0
  [../]

  #----------------------------------------------------------------------------#
  # etab0 kernels
  [./ACb0_bulk]
    type = ACGrGrMulti
    variable = etab0
    v =           'etaa0 etag0'
    gamma_names = 'gab   gbg'
    mob_name = L
    args = 'etaa0 etab0 etag0'
  [../]

  [./ACb0_sw]
    type = ACSwitching
    variable = etab0
    Fj_names  = 'omega_a omega_b omega_g'
    hj_names  = 'h_a     h_b     h_g'
    args = 'etaa0 etab0 etag0 w_c w_o w_m'
    mob_name = L
  [../]

  [./ACb0_int]
    type = ACInterface
    variable = etab0
    kappa_name = kappa
    mob_name = L
    args = 'etaa0 etag0'
  [../]

  [./etab0_dot]
    type = TimeDerivative
    variable = etab0
  [../]

  #----------------------------------------------------------------------------#
  # etag0 kernels
  [./ACg0_bulk]
    type = ACGrGrMulti
    variable = etag0
    v =           'etaa0 etab0'
    gamma_names = 'gag   gbg'
    mob_name = L
    args = 'etaa0 etab0 etag0'
  [../]

  [./ACg0_sw]
    type = ACSwitching
    variable = etag0
    Fj_names  = 'omega_a omega_b omega_g'
    hj_names  = 'h_a     h_b     h_g'
    args = 'etaa0 etab0 etag0 w_c w_o w_m'
    mob_name = L
  [../]

  [./ACg0_int]
    type = ACInterface
    variable = etag0
    kappa_name = kappa
    mob_name = L
    args = 'etaa0 etab0'
  [../]

  [./etag0_dot]
    type = TimeDerivative
    variable = etag0
  [../]

  #----------------------------------------------------------------------------#
  # Chemical potential kernels
  #----------------------------------------------------------------------------#
  # Carbon
  [./w_c_dot]
    type = SusceptibilityTimeDerivative
    variable = w_c
    f_name = chi_c
    args = '' # in this case chi (the susceptibility) is simply a constant
  [../]

  [./diffusion_c]
    type = MatDiffusion
    variable = w_c
    diffusivity = Dchi_c
    args = ''
  [../]

  #----------------------------------------------------------------------------#
  # Carbon in the Matrix
  [./w_m_dot]
    type = SusceptibilityTimeDerivative
    variable = w_m
    f_name = chi_m
    args = '' # in this case chi (the susceptibility) is simply a constant
  [../]

  [./diffusion_m]
    type = MatDiffusion
    variable = w_m
    diffusivity = Dchi_m
    args = ''
  [../]


  #----------------------------------------------------------------------------#
  # Oxygen
  [./w_o_dot]
    type = SusceptibilityTimeDerivative
    variable = w_o
    f_name = chi_o
    args = '' # in this case chi (the susceptibility) is simply a constant
  [../]

  [./diffusion_o]
    type = MatDiffusion
    variable = w_o
    diffusivity = Dchi_o
    args = ''
  [../]

  #----------------------------------------------------------------------------#
  # Coupled kernels
  #----------------------------------------------------------------------------#
  # Carbon
  [./coupled_etaa0dot_c]
    type = CoupledSwitchingTimeDerivative
    variable = w_c
    v = etaa0
    Fj_names = 'rho_c_a rho_c_b rho_c_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_o w_m'
  [../]

  [./coupled_etab0dot_c]
    type = CoupledSwitchingTimeDerivative
    variable = w_c
    v = etab0
    Fj_names = 'rho_c_a rho_c_b rho_c_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_o w_m'
  [../]

  [./coupled_etag0dot_c]
    type = CoupledSwitchingTimeDerivative
    variable = w_c
    v = etag0
    Fj_names = 'rho_c_a rho_c_b rho_c_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_o w_m'
  [../]

  #----------------------------------------------------------------------------#
  # Carbon in the Matrix
  [./coupled_etaa0dot_m]
    type = CoupledSwitchingTimeDerivative
    variable = w_m
    v = etaa0
    Fj_names = 'rho_m_a rho_m_b rho_m_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_o w_c'
  [../]

  [./coupled_etab0dot_m]
    type = CoupledSwitchingTimeDerivative
    variable = w_m
    v = etab0
    Fj_names = 'rho_m_a rho_m_b rho_m_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_o w_c'
  [../]

  [./coupled_etag0dot_m]
    type = CoupledSwitchingTimeDerivative
    variable = w_m
    v = etag0
    Fj_names = 'rho_m_a rho_m_b rho_m_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_o w_c'
  [../]

  #----------------------------------------------------------------------------#
  # Oxygen
  [./coupled_etaa0dot_o]
    type = CoupledSwitchingTimeDerivative
    variable = w_o
    v = etaa0
    Fj_names = 'rho_o_a rho_o_b rho_o_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_c w_m'
  [../]

  [./coupled_etab0dot_o]
    type = CoupledSwitchingTimeDerivative
    variable = w_o
    v = etab0
    Fj_names = 'rho_o_a rho_o_b rho_o_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_c w_m'
  [../]

  [./coupled_etag0dot_o]
    type = CoupledSwitchingTimeDerivative
    variable = w_o
    v = etag0
    Fj_names = 'rho_o_a rho_o_b rho_o_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_c w_m'
  [../]

  #----------------------------------------------------------------------------#
  # END OF KERNELS
[]


#------------------------------------------------------------------------------#
[Materials]
  #----------------------------------------------------------------------------#
  # Switching functions
  # Phase alpha: fiber
  [./switch_a]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_a
    all_etas = 'etaa0 etab0 etag0'
    phase_etas = 'etaa0'

    outputs = exodus
    output_properties = h_a
  [../]

  # Phase beta: char
  [./switch_b]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_b
    all_etas = 'etaa0 etab0 etag0'
    phase_etas = 'etab0'

    outputs = exodus
    output_properties = h_b
  [../]

  # Phase gamma: gas
  [./switch_g]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_g
    all_etas = 'etaa0 etab0 etag0'
    phase_etas = 'etag0'

    outputs = exodus
    output_properties = h_g
  [../]

  #----------------------------------------------------------------------------#
  # Grand potential densities
  [./omega_a]
    type = DerivativeParsedMaterial
    f_name = omega_a
    args = 'w_c w_o w_m'

    function = '-0.5*w_c^2/(Va^2 *A_c_a) - xeq_c_a*w_c/Va
                -0.5*w_o^2/(Va^2 *A_o_a) - xeq_o_a*w_o/Va
                -0.5*w_m^2/(Va^2 *A_m_a) - xeq_m_a*w_m/Va'

    material_property_names = 'Va A_c_a A_o_a xeq_c_a xeq_o_a A_m_a xeq_m_a'

    derivative_order = 2
    outputs = exodus
    output_properties = omega_a
  [../]

  [./omega_b]
    type = DerivativeParsedMaterial
    f_name = omega_b

    args = 'w_c w_o w_m'

    function = '-0.5*w_c^2/(Va^2 *A_c_b) - xeq_c_b*w_c/Va
                -0.5*w_o^2/(Va^2 *A_o_b) - xeq_o_b*w_o/Va
                -0.5*w_m^2/(Va^2 *A_m_b) - xeq_m_b*w_m/Va'

    material_property_names = 'Va A_c_b A_o_b xeq_c_b xeq_o_b A_m_b xeq_m_b'

    derivative_order = 2
    outputs = exodus
    output_properties = omega_b
  [../]

  [./omega_g]
    type = DerivativeParsedMaterial
    f_name = omega_g

    args = 'w_c w_o w_m'

    function = '-0.5*w_c^2/(Va^2 *A_c_g) - xeq_c_g*w_c/Va
                -0.5*w_o^2/(Va^2 *A_o_g) - xeq_o_g*w_o/Va
                -0.5*w_m^2/(Va^2 *A_m_g) - xeq_m_g*w_m/Va'

    material_property_names = 'Va A_c_g A_o_g xeq_c_g xeq_o_g A_m_g xeq_m_g'

    derivative_order = 2
    outputs = exodus
    output_properties = omega_g
  [../]

  [./omega]
    type = DerivativeParsedMaterial
    f_name = omega
    args = 'etaa0 etab0 etag0'

    function = 'h_a*omega_a + h_b*omega_b + h_g*omega_g'

    material_property_names = 'h_a h_b h_g omega_a omega_b omega_g'

    outputs = exodus
    output_properties = omega
  [../]

  #----------------------------------------------------------------------------#
  # CARBON
  [./rho_c_a]
    type = DerivativeParsedMaterial
    f_name = rho_c_a
    args = 'w_c'

    function = 'w_c/(A_c_a*Va^2) + xeq_c_a/Va'

    material_property_names = 'Va A_c_a xeq_c_a'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_c_a
  [../]

  [./rho_c_b]
    type = DerivativeParsedMaterial
    f_name = rho_c_b
    args = 'w_c'

    function = 'w_c/(A_c_b*Va^2) + xeq_c_b/Va'

    material_property_names = 'Va A_c_b xeq_c_b'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_c_b
  [../]

  [./rho_c_g]
    type = DerivativeParsedMaterial
    f_name = rho_c_g
    args = 'w_c'

    function = 'w_c/(A_c_g*Va^2) + xeq_c_g/Va'

    material_property_names = 'Va A_c_g xeq_c_g'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_c_g
  [../]

  [./rho_c]
    type = DerivativeParsedMaterial
    f_name = rho_c
    args = 'w_c etaa0 etab0 etag0'

    function = 'h_a*rho_c_a + h_b*rho_c_b + h_g*rho_c_g'

    material_property_names = 'h_a h_b h_g rho_c_a rho_c_b rho_c_g'

    outputs = exodus
    output_properties = rho_c
  [../]

  [./x_c]
    type = DerivativeParsedMaterial
    f_name = x_c
    args = 'w_c etaa0 etab0 etag0'

    function = 'Va*rho_c'

    material_property_names = 'Va rho_c'

    outputs = exodus
    output_properties = x_c
  [../]

  #----------------------------------------------------------------------------#
  # CARBON IN THE MATRIX
  [./rho_m_a]
    type = DerivativeParsedMaterial
    f_name = rho_m_a
    args = 'w_m'

    function = 'w_m/(A_m_a*Va^2) + xeq_m_a/Va'

    material_property_names = 'Va A_m_a xeq_m_a'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_m_a
  [../]

  [./rho_m_b]
    type = DerivativeParsedMaterial
    f_name = rho_m_b
    args = 'w_m'

    function = 'w_m/(A_m_b*Va^2) + xeq_m_b/Va'

    material_property_names = 'Va A_m_b xeq_m_b'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_m_b
  [../]

  [./rho_m_g]
    type = DerivativeParsedMaterial
    f_name = rho_m_g
    args = 'w_m'

    function = 'w_m/(A_m_g*Va^2) + xeq_m_g/Va'

    material_property_names = 'Va A_m_g xeq_m_g'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_m_g
  [../]

  [./rho_m]
    type = DerivativeParsedMaterial
    f_name = rho_m
    args = 'w_m etaa0 etab0 etag0'

    function = 'h_a*rho_m_a + h_b*rho_m_b + h_g*rho_m_g'

    material_property_names = 'h_a h_b h_g rho_m_a rho_m_b rho_m_g'

    outputs = exodus
    output_properties = rho_m
  [../]

  [./x_m]
    type = DerivativeParsedMaterial
    f_name = x_m
    args = 'w_m etaa0 etab0 etag0'

    function = 'Va*rho_m'

    material_property_names = 'Va rho_m'

    outputs = exodus
    output_properties = x_m
  [../]

  #----------------------------------------------------------------------------#
  # OXYGEN
  [./rho_o_a]
    type = DerivativeParsedMaterial
    f_name = rho_o_a
    args = 'w_o'

    function = 'w_o/(A_o_a*Va^2) + xeq_o_a/Va'

    material_property_names = 'Va A_o_a xeq_o_a'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_o_a
  [../]

  [./rho_o_b]
    type = DerivativeParsedMaterial
    f_name = rho_o_b
    args = 'w_o'

    function = 'w_o/(A_o_b*Va^2) + xeq_o_b/Va'

    material_property_names = 'Va A_o_b xeq_o_b'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_o_b
  [../]

  [./rho_o_g]
    type = DerivativeParsedMaterial
    f_name = rho_o_g
    args = 'w_o'

    function = 'w_o/(A_o_g*Va^2) + xeq_o_g/Va'

    material_property_names = 'Va A_o_g xeq_o_g'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_o_g
  [../]

  [./rho_o]
    type = DerivativeParsedMaterial
    f_name = rho_o
    args = 'w_o etaa0 etab0 etag0'

    function = 'h_a*rho_o_a + h_b*rho_o_b + h_g*rho_o_g'

    material_property_names = 'h_a h_b h_g rho_o_a rho_o_b rho_o_g'

    outputs = exodus
    output_properties = rho_o
  [../]

  [./x_o]
    type = DerivativeParsedMaterial
    f_name = x_o
    args = 'w_o etaa0 etab0 etag0'

    function = 'Va*rho_o'

    material_property_names = 'Va rho_o'

    outputs = exodus
    output_properties = x_o
  [../]


  #----------------------------------------------------------------------------#
    #####     ##    #####     ##    #    #   ####
    #    #   #  #   #    #   #  #   ##  ##  #
    #    #  #    #  #    #  #    #  # ## #   ####
    #####   ######  #####   ######  #    #       #
    #       #    #  #   #   #    #  #    #  #    #
    #       #    #  #    #  #    #  #    #   ####
  #----------------------------------------------------------------------------#
  # Reaction rate constants
  [./phase_mobility]
    type = DerivativeParsedMaterial
    f_name = L
    args = 'etaa0 etab0 etag0'

     function = '(Lab*etaa0^2*etab0^2 +Lag*etaa0^2*etag0^2 +Lbg*etab0^2*etag0^2)/
                 (etaa0^2*etab0^2 +etaa0^2*etag0^2 +etab0^2*etag0^2)'

    constant_names        = 'Lab      Lag       Lbg'
    constant_expressions  = '1.0      1.2       2.0'

    derivative_order = 2
    outputs = exodus
    output_properties = L
  [../]

  #----------------------------------------------------------------------------#
  # Reaction rate constants
  # [./phase_mobility]
  #   type = GenericConstantMaterial
  #
  #   prop_names = 'L'
  #   prop_values = '1'
  #
  #   outputs = exodus
  #   output_properties = L
  # [../]

  #----------------------------------------------------------------------------#
  # # Reaction rate constants
  # [./reaction_rates]
  #   type = DerivativeParsedMaterial
  #   f_name = K
  #   args = 'rho_c_var rho_m_var etaa0 etab0 etag0'
  #
  #   function = '(rho_m_var-1)'
  #
  #   material_property_names = 'h_a h_b'
  #
  #   derivative_order = 2
  #   outputs = exodus
  #   #output_properties = K
  # [../]

  #----------------------------------------------------------------------------#
  # Reaction rate constants
  [./reaction_rates]
    type = GenericConstantMaterial

    prop_names = 'K'
    prop_values = '-0.1'

    outputs = exodus
    output_properties = K
  [../]

  #----------------------------------------------------------------------------#
  # Constant parameters
  [./atomic_vol]
    type = GenericConstantMaterial
    prop_names =  'Va'
    prop_values = '1.0'
    outputs = exodus
  [../]

  #----------------------------------------------------------------------------#
  # Grand Potential Interface Parameters
  [./iface]
    # reproduce the parameters from GrandPotentialMultiphase.i
    type = GrandPotentialInterface
    gamma_names = ' gab        gag        gbg'
    # angles = 178 91 91 degrees
    # sigma = '0.0349       1.0002     1.0002'
    sigma ='0.4714  0.6161 0.6161'

    mu_name = mu
    kappa_name = kappa
    outputs = exodus
  [../]

  [./params_carbon]
    type = GenericConstantMaterial
    prop_names  = 'A_c_a    xeq_c_a
                   A_c_b    xeq_c_b
                   A_c_g    xeq_c_g'
    prop_values = '1e2       0.95
                   1e1       0.0
                   1e1       0.0'

    outputs = exodus
  [../]

  [params_cmatrix]
    type = GenericConstantMaterial
    prop_names  = 'A_m_a    xeq_m_a
                   A_m_b    xeq_m_b
                   A_m_g    xeq_m_g'
    prop_values = '1e2       0.0
                   1e1       0.70
                   1e1       0.0'

    outputs = exodus
  [../]

  [./params_oxygen]
    type = GenericConstantMaterial
    prop_names  = 'A_o_a    xeq_o_a
                   A_o_b    xeq_o_b
                   A_o_g    xeq_o_g'
    prop_values = '1e1      0.0
                   1e1      0.0
                   1e2      0.96'

    outputs = exodus
  [../]

  # Diffusivities
  [./diff_c]
    type = DerivativeParsedMaterial
    f_name = D_c
    args = 'etaa0 etab0 etag0'
    material_property_names = 'h_a h_b h_g'
    function = '(h_a*1e-6+ h_b*1e-6 +h_g*1)'

    outputs = exodus
    output_properties = D_c
  [../]

  [./diff_m]
    type = DerivativeParsedMaterial
    f_name = D_m
    args = 'etaa0 etab0 etag0'
    material_property_names = 'h_a h_b h_g'
    function = '(h_a*1e-6+ h_b*1e-6 +h_g*1)'

    outputs = exodus
    output_properties = D_m
  [../]

  [./diff_o]
    type = DerivativeParsedMaterial
    f_name = D_o
    args = 'etaa0 etab0 etag0'
    material_property_names = 'h_a h_b h_g'

    function = '(h_a*1e-6 + h_b*1e-6 +h_g*1)'

    outputs = exodus
    output_properties = D_o
  [../]

  #------------------------------------------------------------------------------#
    ######  #    #  #####
    #       ##   #  #    #
    #####   # #  #  #    #
    #       #  # #  #    #
    #       #   ##  #    #
    ######  #    #  #####
  #------------------------------------------------------------------------------#

  [./chi_c]
    type = DerivativeParsedMaterial
    f_name = chi_c

    function = '(h_a/A_c_a + h_b/A_c_b + h_g/A_c_g) / Va^2'

    material_property_names = 'Va h_a A_c_a h_b A_c_b h_g A_c_g'

    derivative_order = 2
    outputs = exodus
    output_properties = chi_c
  [../]

  [./mob_c]
    type = DerivativeParsedMaterial
    f_name = Dchi_c
    material_property_names = 'D_c chi_c'
    function = 'D_c*chi_c'
    derivative_order = 2

    outputs = exodus
    output_properties = Dchi_c
  [../]

  [./chi_m]
    type = DerivativeParsedMaterial
    f_name = chi_m

    function = '(h_a/A_m_a + h_b/A_m_b + h_g/A_m_g) / Va^2'

    material_property_names = 'Va h_a A_m_a h_b A_m_b h_g A_m_g'

    derivative_order = 2
    outputs = exodus
    output_properties = chi_m
  [../]

  [./mob_m]
    type = DerivativeParsedMaterial
    f_name = Dchi_m
    material_property_names = 'D_m chi_m'
    function = 'D_m*chi_m'
    derivative_order = 2

    outputs = exodus
    output_properties = Dchi_m
  [../]


  [./chi_o]
    type = DerivativeParsedMaterial
    f_name = chi_o

    function = '(h_a/A_o_a + h_b/A_o_b + h_g/A_o_g) / Va^2'

    material_property_names = 'Va h_a A_o_a h_b A_o_b h_g A_o_g'

    derivative_order = 2
    outputs = exodus
    output_properties = chi_o
  [../]

  [./mob_o]
    type = DerivativeParsedMaterial
    f_name = Dchi_o
    material_property_names = 'D_o chi_o'
    function = 'D_o*chi_o'
    derivative_order = 2

    outputs = exodus
    output_properties = Dchi_o
  [../]

  [./sum_eta]
    type = DerivativeParsedMaterial
    f_name = sum_eta
    args = 'etaa0 etab0 etag0'
    function = 'etaa0 + etab0 + etag0'
    outputs = exodus
    output_properties = sum_eta
  [../]
[]
#------------------------------------------------------------------------------#
# END OF MATERIALS


#------------------------------------------------------------------------------#
[BCs]
  [./oxygen]
    type = PresetBC
    boundary = 'top'
    variable = 'w_o'
    value = '0'
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
  # Preconditioned JFNK (default)
  type = Transient

  # scheme =  explicit-euler
  # solve_type = NEWTON

  scheme = bdf2
  solve_type = PJFNK
  # petsc_options_iname = '-pc_type'
  # petsc_options_value = 'asm'
  petsc_options_iname = '-pc_type -ksp_grmres_restart -sub_ksp_type -sub_pc_type -pc_asm_overlap'
  petsc_options_value = 'asm      31                  preonly       lu           2'

  nl_max_its = 15
  nl_abs_tol = 1e-10
  nl_rel_tol = 1.0e-8

  l_max_its = 15
  l_tol = 1.0e-8

  start_time = 0.0
  end_time = 10000

  dtmax = 1
  dtmin = 2e-14

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.001
    growth_factor = 1.1
    cutback_factor = 0.9
    optimal_iterations = 12
    iteration_window = 0
  [../]

  # [./Predictor]
  #   type = SimplePredictor
  #   scale = 1
  # [../]

[]

#------------------------------------------------------------------------------#
[VectorPostprocessors]
  # [./grain_volumes]
  #   type = FeatureVolumeVectorPostprocessor
  #   flood_counter = grain_tracker
  #   single_feature_per_element = true
  #   execute_on = 'INITIAL TIMESTEP_END FINAL'
  #   outputs = none
  # [../]
  [./vol_fiber]
    type = FeatureVolumeVectorPostprocessor
    flood_counter = fiber_counter
    execute_on = 'INITIAL TIMESTEP_END FINAL'
    outputs = none
  [../]
  [./vol_matrix]
    type = FeatureVolumeVectorPostprocessor
    flood_counter = matrix_counter
    execute_on = 'INITIAL TIMESTEP_END FINAL'
    outputs = none
  [../]
  # [./line]
  #   type = LineValueSampler
  #   num_points  = 400
  #   start_point = '5.0 0.0 0.0'
  #   end_point   = '5.0 10.0 0.0'
  #   variable    = etaa0
  #   sort_by     = y
  #   execute_on  = 'INITIAL TIMESTEP_END FINAL'
  #   outputs     = vector
  # [../]
[]

#------------------------------------------------------------------------------#
[Postprocessors]
  [./volume]
    type = VolumePostprocessor
    execute_on = 'initial'
    outputs = none
  [../]

  [./fiber_counter]
    type = FeatureFloodCount
    variable = etaa0
    compute_var_to_feature_map = true
    execute_on = 'INITIAL TIMESTEP_END FINAL'
    outputs = none
  [../]
  [./matrix_counter]
    type = FeatureFloodCount
    variable = etab0
    compute_var_to_feature_map = true
    execute_on = 'INITIAL TIMESTEP_END FINAL'
    outputs = none
  [../]

  [./volume_fiber]
    type = FeatureVolumeFraction
    mesh_volume = volume
    feature_volumes = vol_fiber
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  [../]
  [./volume_matrix]
    type = FeatureVolumeFraction
    mesh_volume = volume
    feature_volumes = vol_matrix
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  [../]

  # [./grain_tracker]
  #   type = GrainTracker
  #   variable = 'etaa0 etab0'
  #   threshold = 0.1
  #   compute_var_to_feature_map = true
  #   execute_on = 'initial'
  #   outputs = none
  # [../]

  [./total_carbon]
    type =ElementIntegralVariablePostprocessor
    variable = rho_c_var
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  [../]
  [./total_oxygen]
    type = ElementIntegralVariablePostprocessor
    variable = rho_o_var
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  [../]
  [./total_carbon_m]
    type = ElementIntegralVariablePostprocessor
    variable = rho_m_var
    execute_on = 'INITIAL TIMESTEP_END FINAL'
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
[Outputs]
  append_date = true

  [./exodus]
    type = Exodus
    execute_on = 'INITIAL TIMESTEP_END'
    file_base = ./results_3p/moose_out
  [../]

  [./csv]
    type = CSV
    execute_on = 'INITIAL TIMESTEP_END'
    file_base = ./results_3p/moose_out
  [../]

   # [./vector]
   #   type = CSV
   #   execute_on = 'INITIAL FINAL'
   #   file_base = ./results/moose_vector_out
   # [../]
[]


#------------------------------------------------------------------------------#
[Debug]
  show_var_residual_norms = true
[]
