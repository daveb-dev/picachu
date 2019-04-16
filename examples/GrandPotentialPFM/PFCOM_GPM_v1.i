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
    # note w_i = A*(c-cleq), A = 1.0, cleq = 0.0 ,i.e., w_i = c (in the matrix/liquid phase)
    type = BoundingBoxIC
    variable = w_i
    inside = 0.7
    outside = 0.1
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
    #Units        microJ/micron2
    prop_names  = 'kappa_op     L'
    prop_values = '1.0e-3      0.1'
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

    function = '1 / Va * (c_s - c_g) * dh'

    args = 'eta'
    material_property_names = 'dh:=D[h,eta]'

    constant_names =       'c_g   c_s   Va'
    constant_expressions = '1.0   0.1   1.0'

    derivative_order = 1

    outputs = exodus
  [../]

  #----------------------------------------------------------------------------#
  # SOLID PHASE: IDEAL SOLUTION MODEL FREE ENERGY
  #----------------------------------------------------------------------------#
  # Concentration of component i according to ideal solution model
  [./c_i]
    type = DerivativeParsedMaterial
    f_name = c_i

    function = '(1-h)*exp((w_i-Va*(E_f_i-E_f_vac))/k_b*T)/(1+exp((w_i-Va*(E_f_i-E_f_vac))/k_b*T))'

    args = 'w_i eta'

    constant_names =        'E_f_i  E_f_vac    k_b     T      Va'
    constant_expressions =  '1.0    0.1        1.0     1.0    1.0'

    material_property_names = 'h(eta)'

    derivative_order = 2

    outputs = exodus
    output_properties = c_i
  [../]

  #----------------------------------------------------------------------------#
  # Sum of the concentrations of all the components in the solid
  # Used to calculate vacancy concentration using 1-c_sum
  [./c_sum]
    type = DerivativeSumMaterial
    f_name = c_sum

    args =  'w_i eta'
    sum_materials = 'c_i'

    derivative_order = 2

    outputs = exodus
    output_properties = c_sum
  [../]

  #----------------------------------------------------------------------------#
  # Grand potential density in the solid - vacancy contribution
  [./GP_vac]
    type = DerivativeParsedMaterial
    f_name = GP_vac

    function = '(1-h)*(1-c_sum)*(E_f_vac + k_b*T/Va * plog(1-c_sum,tol))'

    args = 'w_i eta'
    material_property_names = 'c_sum(w_i) h(eta)'

    constant_names =       'E_f_vac   k_b   T     Va   tol'
    constant_expressions = '1.0       1.0   1.0   1.0   1e-4'

    outputs = exodus
    output_properties = GP_vac
  [../]

  #----------------------------------------------------------------------------#
  # Grand potential density in the solid - individual components contribution
  [./GP_i]
    type = DerivativeParsedMaterial
    f_name = GP_i

    function = 'c_i/Va * (Va*E_f_i -w_i +k_b*T*plog(c_i,tol))'

    args = 'w_i'
    material_property_names = 'c_i(w_i) c_sum(w_i)'

    constant_names =       'E_f_i   k_b   T     Va      tol  '
    constant_expressions = '1.0     1.0   1.0   1.0    1e-4'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_i
  [../]

  #----------------------------------------------------------------------------#
  # Grand potential density in the solid - sum of individual components contrbution
  [./GP_i_sum]
    type = DerivativeSumMaterial
    f_name = GP_i_sum

    args = 'w_i'
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

    function = 'GP_vac + GP_i_sum'

    args = 'w_i'
    material_property_names = 'GP_vac(w_i) GP_i_sum(w_i)'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_sol
  [../]

  #----------------------------------------------------------------------------#
  # GAS PHASE: PARABOLIC FREE ENERGY
  #----------------------------------------------------------------------------#
  # Grand potential density of the gas phase according to parabolic free energy
  [./gas_GrandPotential]
    type = DerivativeParsedMaterial
    f_name = GP_gas

    function = '-0.5*w_i^2/(Va^2 *A) - c_g*w_i/Va'

    args = 'w_i'

    constant_names = 'c_g A Va'
    constant_expressions = '1.0 1.0 1.0'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_gas
  [../]

  #----------------------------------------------------------------------------#
  # TOTAL GRAND POTENTIAL
  #----------------------------------------------------------------------------#
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

  end_time = 500

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
  file_base = ./results/PFCOM_GPM_v1_out
  execute_on = 'TIMESTEP_END'
[]

#------------------------------------------------------------------------------#
