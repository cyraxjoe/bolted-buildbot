{}: 
let
  inherit(builtins) typeOf hasAttr;
in
{
 # utility functions
 coerceToString = prop: if (typeOf prop) == "int" then toString prop else prop;

 missingAttr = a: config: !(hasAttr a config);  

 bigErrorMsg = msg: ''
   #########################################################
   ${ msg }
   #########################################################
 '';
}

