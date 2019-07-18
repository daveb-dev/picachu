//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "ParabolicGrandPotential.h"

registerMooseObject("PhaseFieldApp", ParabolicGrandPotential);

template <>
InputParameters
validParams<ParabolicGrandPotential>()
{
  InputParameters params = validParams<DerivativeFunctionMaterialBase>();
  params.addClassDescription(
      "Implement the grand-potential density derived from a parabolic free energy.");

  params.addRequiredCoupledVar("w", "Chemical Potential");

  params.addRequiredParam<Real>("A", "Parabolic Coefficient");
  params.addRequiredParam<Real>("Va", "Atomic Volume");
  params.addRequiredParam<Real>("c_eq", "Equilibrium Concentration");

  return params;
}

ParabolicGrandPotential::ParabolicGrandPotential(const InputParameters & parameters)
  : DerivativeFunctionMaterialBase(parameters),
    _w(coupledValue("w")),
    _A(getParam<Real>("A")),
    _Va(getParam<Real>("Va")),
    _c_eq(getParam<Real>("c_eq"))
{
}

Real
ParabolicGrandPotential::computeF()
{
  return -0.5 * pow(_w[_qp],2) / ( pow(_Va,2) * _A) - _c_eq * _w[_qp] / _Va;
}

Real
ParabolicGrandPotential::computeDF(unsigned int i_var)
{
  return - _w[_qp] / (_Va * _A) - _c_eq / _Va;
}

Real
ParabolicGrandPotential::computeD2F(unsigned int i_var, unsigned int j_var)
{
  return - 1 / (_Va * _A);
}
