[Mesh]
 type = GeneratedMesh
 dim = 2

 xmax = 10
 nx = 100
 ymax = 10
 ny = 100

[]

[Variables]
  [./u]
    order = FIRST
    family = LAGRANGE

    [./InitialCondition]
      type = BoundingBoxIC_TANH
      x1 = 0
      y1 = 0
      x2 = 5
      y2 = 5
      inside = 1
      outside = 0.1
      int_width = 1.0
    [../]
  [../]
[]

[AuxVariables]

  [./u_aux]
    order = FIRST
    family = LAGRANGE

    [./InitialCondition]
      type = ConstantIC
      value = 0
    [../]
  [../]
[]

[Kernels]
  active = 'diff'

  [./diff]
    type = Diffusion
    variable = u
  [../]
[]

[BCs]
  active = 'left right'

  [./left]
    type = DirichletBC
    variable = u
    boundary = 1
    value = 0
  [../]

  [./right]
    type = DirichletBC
    variable = u
    boundary = 2
    value = 1
  [../]
[]

[Executioner]
  type = Steady

  solve_type = 'PJFNK'
[]

[Outputs]
  file_base = out
  exodus = true
[]
