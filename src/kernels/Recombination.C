//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "Recombination.h"

registerMooseObject("PhaseFieldApp", Recombination);

template <>
InputParameters
validParams<Recombination>()
{
  InputParameters params = validParams<Kernel>();
  params.addRequiredCoupledVar("v", "Coupled nonlinear variable");
  params.addClassDescription(
      "Kernel to add -L*u*v, where L=reaction rate, u = variable, and v = coupled variable");
  params.addParam<MaterialPropertyName>("mob_name", "L", "The reaction rate used with the kernel");
  params.addCoupledVar("args", "Vector of nonlinear variable arguments this object depends on");
  return params;
}

Recombination::Recombination(const InputParameters & parameters)
  : DerivativeMaterialInterface<JvarMapKernelInterface<Kernel>>(parameters),
    _v_name(getVar("v", 0)->name()),
    _v(coupledValue("v")),
    _v_var(coupled("v")),
    _L(getMaterialProperty<Real>("mob_name")),
    _dLdu(getMaterialPropertyDerivative<Real>("mob_name", _var.name())),
    _dLdv(getMaterialPropertyDerivative<Real>("mob_name", _v_name)),
    _nvar(_coupled_moose_vars.size()),
    _dLdarg(_nvar)
{
  // Get reaction rate derivatives
  for (unsigned int i = 0; i < _nvar; ++i)
    _dLdarg[i] = &getMaterialPropertyDerivative<Real>("mob_name", _coupled_moose_vars[i]->name());
}

void
Recombination::initialSetup()
{
  validateNonlinearCoupling<Real>("mob_name");
}

Real
Recombination::computeQpResidual()
{
  return -_L[_qp] * _test[_i][_qp] * _u[_qp] * _v[_qp];
}

Real
Recombination::computeQpJacobian()
{
  return -(_dLdu[_qp] * _u[_qp] + _L[_qp]) * _phi[_j][_qp] * _v[_qp] * _test[_i][_qp];
}

Real
Recombination::computeQpOffDiagJacobian(unsigned int jvar)
{
  // first handle the case where jvar is a coupled variable v being added to residual
  // the first term in the sum just multiplies by L which is always needed
  // the second term accounts for cases where L depends on v
  if (jvar == _v_var)
    return -(_L[_qp] + _dLdv[_qp] * _v[_qp]) * _phi[_j][_qp] * _u[_qp] * _test[_i][_qp];

  //  for all other vars get the coupled variable jvar is referring to
  const unsigned int cvar = mapJvarToCvar(jvar);

  return -(*_dLdarg[cvar])[_qp] * _phi[_j][_qp] * _u[_qp] * _v[_qp] * _test[_i][_qp];
}
