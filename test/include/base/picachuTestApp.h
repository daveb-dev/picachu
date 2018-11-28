//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
#ifndef PICACHUTESTAPP_H
#define PICACHUTESTAPP_H

#include "MooseApp.h"

class picachuTestApp;

template <>
InputParameters validParams<picachuTestApp>();

class picachuTestApp : public MooseApp
{
public:
  picachuTestApp(InputParameters parameters);
  virtual ~picachuTestApp();

  static void registerApps();
  static void registerAll(Factory & f, ActionFactory & af, Syntax & s, bool use_test_objs = false);
};

#endif /* PICACHUTESTAPP_H */
