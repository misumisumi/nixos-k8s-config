# setup-drbd

zfs on drbdを構築する上で注意すべき点を次に記載する。

- drbd9の自動昇格機能はzfsと併用できない
  - `auto-promote no;`で自動昇格機能を無効化する必要あり

## 参考

- [Tips for using ZFS and Zpools over DRBD with Pacemaker.](https://kb.linbit.com/using-zfs-over-drbd-with-pacemaker)
