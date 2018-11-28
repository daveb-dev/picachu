//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "Production.h"

registerMooseObject("PhaseFieldApp", Production);

template <>
InputParameters
validParams<Production>()
{
  InputParameters params = validParams<Kernel>();
  params.addRequiredCoupledVar("v", "1st coupled nonlinear variable");
  params.addRequiredCoupledVar("w", "2nd coupled nonlinear variable");
  params.addClassDescription(
      "Kernel to add -L*u*v, where L=reaction rate, u = variable, and v = coupled variable");
  params.addParam<MaterialPropertyName>("mob_name", "L", "The reaction rate used with the kernel");
  params.addCoupledVar("args", "Vector of nonlinear variable arguments this object depends on");
  return params;
}

Production::Production(const InputParameters & parameters)
  : DerivativeMaterialInterface<JvarMapKernelInterface<Kernel>>(parameters),
    _v_name(getVar("v", 0)->name()),
    _v(coupledValue("v")),
    _v_var(coupled("v")),
    _w_name(getVar("w", 0)->name()),
    _w(coupledValue("w")),
    _w_var(coupled("w")),
    _L(getMaterialProperty<Real>("mob_name")),
    _dLdu(getMaterialPropertyDerivative<Real>("mob_name", _var.name())),
    _dLdv(getMaterialPropertyDerivative<Real>("mob_name", _v_name)),
    _dLdw(getMaterialPropertyDerivative<Real>("mob_name", _w_name)),
    _nvar(_coupled_moose_vars.size()),
    _dLdarg(_nvar)
{
  // Get reaction rate derivatives
  for (unsigned int i = 0; i < _nvar; ++i)
    _dLdarg[i] = &getMaterialPropertyDerivative<Real>("mob_name", _coupled_moose_vars[i]->name());
}

void
Production::initialSetup()
{
  validateNonlinearCoupling<Real>("mob_name");
}

Real
Production::computeQpResidual()
{
  return -_L[_qp] * _test[_i][_qp] * _v[_qp] * _w[_qp];
}

Real
Production::computeQpJacobian()
{
  return -_dLdu[_qp] * _v[_qp] * _w[_qp] * _phi[_j][_qp]  * _test[_i][_qp];
}

Real
Production::computeQpOffDiagJacobian(unsigned int jvar)
{
  // first handle the case where jvar is a coupled variable v being added to residual
  // the first term in the sum just multiplies by L which is always needed
  // the second term accounts for cases where L depends on v
  if (jvar == _v_var)
    return -(_L[_qp] + _dLdv[_qp] * _v[_qp]) * _w[_qp] * _phi[_j][_qp] * _test[_i][_qp];

  if (jvar == _w_var)
    return -(_L[_qp] + _dLdw[_qp] * _w[_qp]) * _v[_qp] * _phi[_j][_qp] * _test[_i][_qp];

  //  for all other vars get the coupled variable jvar is referring to
  const unsigned int cvar = mapJvarToCvar(jvar);

  return -(*_dLdarg[cvar])[_qp] * _phi[_j][_qp] * _u[_qp] * _v[_qp] * _test[_i][_qp];
}
