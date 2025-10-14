let
  inherit (builtins) fromJSON;
  config = fromJSON (builtins.readFile ../../config.json);
in
{
  hostConfigs = config.hosts;
  getHostConfig = tag: config.hosts.${tag};
}
