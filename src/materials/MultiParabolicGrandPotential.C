//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "MultiParabolicGrandPotential.h"

registerMooseObject("PhaseFieldApp", MultiParabolicGrandPotential);

template <>
InputParameters
validParams<MultiParabolicGrandPotential>()
{
  InputParameters params = validParams<DerivativeFunctionMaterialBase>();
  params.addClassDescription(
      "Implement the grand-potential density derived from a parabolic free energy.");

  params.addRequiredCoupledVar("phase_ws", "Vector of the chemical potential of each component");

  params.addRequiredParam<std::vector<Real>>("A", "Vector of the parabolic coefficient for each component");
  params.addRequiredParam<std::vector<Real>>("Va", "Vector of the atomic volume of each component");
  params.addRequiredParam<std::vector<Real>>("c_eq", "Vector of the equilibrium concentration (molar fraction) of each component");

  return params;
}

MultiParabolicGrandPotential::MultiParabolicGrandPotential(const InputParameters & parameters)
  : DerivativeFunctionMaterialBase(parameters),
    _num_w_p(coupledComponents("phase_ws")),
    _w_p(_num_w_p),
    _A(getParam<std::vector<Real>>("A")),
    _Va(getParam<std::vector<Real>>("Va")),
    _c_eq(getParam<std::vector<Real>>("c_eq"))
{
  // Fetch w values and names for phase components
  for (unsigned int i = 0; i < _num_w_p; ++i)
  {
    _w_p[i] = &coupledValue("phase_ws", i);
  }
}

Real
MultiParabolicGrandPotential::computeF()
{
  Real sum_p = 0.0;

  for (unsigned int i = 0; i < _num_w_p; ++i)
  {
    sum_p += - 0.5 * pow((*_w_p[i])[_qp],2) / ( pow(_Va[i],2) * _A[i]) - _c_eq[i] * (*_w_p[i])[_qp] / _Va[i];
  }

  return sum_p;
}

Real
MultiParabolicGrandPotential::computeDF(unsigned int i_var)
{
  unsigned int i = argIndex(i_var);

  return - (*_w_p[i])[_qp] / (_Va[i] * _A[i]) - _c_eq[i] / _Va[i];
}

Real
MultiParabolicGrandPotential::computeD2F(unsigned int i_var, unsigned int j_var)
{
  unsigned int i = argIndex(i_var);
  unsigned int j = argIndex(j_var);

  if (i == j)
    return - 1 / (_Va[i] * _A[i]);
  return 0;

}
