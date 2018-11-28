#include "picachuApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "ModulesApp.h"
#include "MooseSyntax.h"

template <>
InputParameters
validParams<picachuApp>()
{
  InputParameters params = validParams<MooseApp>();
  return params;
}

picachuApp::picachuApp(InputParameters parameters) : MooseApp(parameters)
{
  picachuApp::registerAll(_factory, _action_factory, _syntax);
}

picachuApp::~picachuApp() {}

void
picachuApp::registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  ModulesApp::registerAll(f, af, s);
  Registry::registerObjectsTo(f, {"picachuApp"});
  Registry::registerActionsTo(af, {"picachuApp"});

  /* register custom execute flags, action syntax, etc. here */
}

void
picachuApp::registerApps()
{
  registerApp(picachuApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
extern "C" void
picachuApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  picachuApp::registerAll(f, af, s);
}
extern "C" void
picachuApp__registerApps()
{
  picachuApp::registerApps();
}
