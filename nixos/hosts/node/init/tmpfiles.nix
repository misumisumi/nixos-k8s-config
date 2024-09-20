{
  systemd.tmpfiles.rules = [
    "d /.keystore 0700 root root -"
    "d /etc/secrets 0700 root root -"
  ];
}
