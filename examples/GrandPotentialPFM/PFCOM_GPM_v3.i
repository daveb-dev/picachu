#------------------------------------------------------------------------------#
# PFCOM using the grand potential model
#------------------------------------------------------------------------------#
[Mesh]
  # length scale -> microns
  type = GeneratedMesh
  dim = 2

  xmin = 0.0
  xmax = 3.0
  nx = 12

  ymin = 0.0
  ymax = 12.0
  ny = 48

  uniform_refine = 2
  elem_type = QUAD4
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
  [./w_i]
  [../]

  [./eta]
  [../]
[]

#------------------------------------------------------------------------------#
[ICs]
  [./IC_w]
    type = BoundingBoxIC
    variable = w_i
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
    variable = w_i
    f_name = chi
    args = ''
  [../]

  #----------------------------------------------------------------------------#
  # Diffusion Kernel (-D grad(u))
  [./Diffusion]
    type = MatDiffusion
    variable = w_i
    D_name = D
    args = ''
  [../]

  #----------------------------------------------------------------------------#
  # Order Parameter Kernels
  [./AC_bulk]
    type = AllenCahn
    variable = eta
    f_name = GP_total
    args = 'w_i'
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
    variable = w_i
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
    prop_names  = 'D    chi'
    prop_values = '1.0  1.0'
  [../]

  [./interfacial_param]
    type = GenericConstantMaterial
    prop_names  = 'kappa_op     L'
    prop_values = '1.0e-3      0.1'
  [../]

  [./E_f_v]
    # Units: eV
    type = GenericConstantMaterial
    prop_names = 'E_f_v'
    prop_values = '4.0'
  [../]

  [./E_f_i]
    # Units: eV
    type = GenericConstantMaterial
    prop_names = 'E_f_i'
    prop_values = '0.0'
  [../]

  [./k_b]
    # Units: eV/atom-K
    type = GenericConstantMaterial
    prop_names = 'k_b'
    prop_values = '1.0'
    #prop_values = '8.6173e-5'
  [../]

  [./T]
    # Units: K
    type = GenericConstantMaterial
    prop_names = 'T'
    prop_values = '1.0'
  [../]

  [./Va]
    # Units:
    type = GenericConstantMaterial
    prop_names = 'Va'
    prop_values = '1.0'
  [../]

  # [./tol]
  #   type = GenericConstantMaterial
  #   prop_names = 'tol'
  #   prop_values = '1e-4'
  # [../]

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

    function = '1 / Va * (c_s - c_g) * dh'

    args = 'eta'
    material_property_names = 'Va dh:=D[h,eta]'

    constant_names =       'c_g   c_s'
    constant_expressions = '0.1   1.0'

    derivative_order = 1

    outputs = exodus
  [../]

  #----------------------------------------------------------------------------#
  # SOLID PHASE: IDEAL SOLUTION MODEL FREE ENERGY
  #----------------------------------------------------------------------------#
  # Concentration of component i according to ideal solution model
  [./x_i_sol]
    type = DerivativeParsedMaterial
    f_name = x_i_sol

    function = '((exp((w_i-(E_f_i-E_f_v))/(k_b*T)))^(-1)+1)^(-1)'

    args = 'w_i eta'

    material_property_names = 'h(eta) E_f_v E_f_i k_b T Va'

    derivative_order = 2

    outputs = exodus
    output_properties = x_i_sol
  [../]


  [./check_x_i]
    type = DerivativeParsedMaterial
    f_name = x_check
    function = 'Va*dw'
    material_property_names = 'Va dw:=D[GP_i,w_i]'
    derivative_order = 2
    outputs = exodus
    output_properties = x_check
  [../]

  #----------------------------------------------------------------------------#
  # Sum of the concentrations of all the components in the solid
  # Used to calculate vacancy concentration using 1-x_sum
  [./x_sum]
    type = DerivativeSumMaterial
    f_name = x_sum

    args =  'w_i eta'
    sum_materials = 'x_i_sol'

    derivative_order = 2

    outputs = exodus
    output_properties = x_sum
  [../]

  #----------------------------------------------------------------------------#
  # Grand potential density in the solid - vacancy contribution
  [./GP_v]
    type = DerivativeParsedMaterial
    f_name = GP_v

    function = '(1-x_sum)/Va*(E_f_v + k_b*T* plog(1-x_sum,tol))'

    args = 'w_i eta'
    material_property_names = 'x_sum(w_i,eta) E_f_v k_b T Va'

    constant_names = 'tol'
    constant_expressions = '1e-4'

    outputs = exodus
    output_properties = GP_v
  [../]

  #----------------------------------------------------------------------------#
  # Grand potential density in the solid - individual components contribution
  [./GP_i]
    type = DerivativeParsedMaterial
    f_name = GP_i

    function = 'x_i_sol/Va*(E_f_i +k_b*T*plog(x_i_sol,tol) -w_i)'

    args = 'w_i eta'
    material_property_names = 'x_i_sol(w_i,eta) x_sum(w_i,eta) E_f_i k_b T Va'

    constant_names = 'tol'
    constant_expressions = '1e-4'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_i
  [../]

  #----------------------------------------------------------------------------#
  # Grand potential density in the solid - sum of individual components contrbution
  [./GP_i_sum]
    type = DerivativeSumMaterial
    f_name = GP_i_sum

    args = 'w_i eta'
    sum_materials = 'GP_i'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_i_sum
  [../]


  #----------------------------------------------------------------------------#
  # Grand potential of the solid phase according to ideal solution model
  [./solid_GrandPotential]
    type = DerivativeParsedMaterial
    f_name = GP_sol

    function = 'GP_v + GP_i_sum'

    args = 'w_i eta'
    material_property_names = 'GP_v(w_i) GP_i_sum(w_i)'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_sol
  [../]

  #----------------------------------------------------------------------------#
  # GAS PHASE: PARABOLIC FREE ENERGY
  #----------------------------------------------------------------------------#
  # Molar fraction in the gas phase
  [./x_i_gas]
    type = DerivativeParsedMaterial
    f_name = 'x_i_gas'

    function = 'w_i/(Va*A) + c_eq'

    args = 'w_i'
    material_property_names = 'Va'

    constant_names =       'c_eq   A'
    constant_expressions = '0.1   20.0'

    derivative_order = 2

    outputs = exodus
    output_properties = x_i_gas
  [../]

  # Grand potential density of the gas phase according to parabolic free energy
  [./gas_GrandPotential]
    type = DerivativeParsedMaterial
    f_name = GP_gas

    function = '-0.5*w_i^2/(Va^2 *A) - c_eq*w_i/Va'

    args = 'w_i eta'
    material_property_names = 'Va'

    constant_names =       'c_eq   A'
    constant_expressions = '0.1   20.0'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_gas
  [../]

  #----------------------------------------------------------------------------#
  # TOTAL GRAND POTENTIAL
  #----------------------------------------------------------------------------#
  # Molar fraction throughout the entire domain
  [./x_i]
    type = DerivativeParsedMaterial
    f_name = x_i

    function = '(1-h)*x_i_sol + h*x_i_gas'

    args = 'w_i eta'

    material_property_names = 'h(eta) x_i_sol x_i_gas'

    derivative_order = 2

    outputs = exodus
    output_properties = x_i
  [../]


  # Total GP
  [./total_GrandPotential]
    type = DerivativeParsedMaterial
    f_name = GP_total

    function = 'h*GP_gas + (1-h)*GP_sol'

    args = 'w_i eta'
    material_property_names = 'h(eta) g(eta) GP_gas(w_i) GP_sol(w_i)'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_total
  [../]
[]

#------------------------------------------------------------------------------#
[Postprocessors]
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

  end_time = 150
  dtmax = 2

  [./Adaptivity]
    max_h_level = 3
    initial_adaptivity = 2
    coarsen_fraction = 0.1
    refine_fraction = 0.7
  [../]

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
  file_base = ./results_v3/PFCOM_GPM_v3_out
  execute_on = 'TIMESTEP_END'
[]

#------------------------------------------------------------------------------#
