{
  nixidy = {
    defaults.destination.server = "https:/10.10.100.100";
    target = {
      repository = "https://github.com/misumisumi/ProjectQueentet-manufests.git";
      branch = "develop";
      rootPath = "./manifests/dev";
      kubeconfigPath = "./env/dev/kubeconfig";
    };
  };
}
