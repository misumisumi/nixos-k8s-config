{
  nixidy = {
    defaults.destination.server = "https:/172.16.100.100";
    target = {
      repository = "https://github.com/misumisumi/ProjectQueentet-manufests.git";
      branch = "develop";
      rootPath = "./manifests/dev";
      kubeconfigPath = "./env/dev/kubeconfig";
    };
  };
}
