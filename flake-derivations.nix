system: flakeRef:
let
  inherit (builtins) isAttrs attrValues concatMap elem filter foldl' getFlake;

  isDerivation = value: value.type or null == "derivation";

  collect = pred: attrs:
    if pred attrs then
      [ attrs ]
    else if isAttrs attrs then
      concatMap (collect pred) (attrValues attrs)
    else
      [ ];

  unique = foldl' (acc: e: if elem e acc then acc else acc ++ [ e ]) [ ];

  pipe = foldl' (x: f: f x);

in pipe (getFlake flakeRef).outputs [
  (collect isDerivation)
  (filter (drv: drv.system == system))
  (map (drv: drv.drvPath))
  unique
]
