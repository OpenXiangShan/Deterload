{ writeText
, runCommand

, gen_init_cpio
}@args:
let
  name = "init.cpio";
  cpio_list = writeText "cpio_list" ''
    dir /bin          755 0 0
    dir /etc          755 0 0
    dir /dev          755 0 0
    dir /lib          755 0 0
    dir /proc         755 0 0
    dir /sbin         755 0 0
    dir /sys          755 0 0
    dir /tmp          755 0 0
    dir /usr          755 0 0
    dir /mnt          755 0 0
    slink /usr/bin /bin 755 0 0
    dir /usr/lib      755 0 0
    dir /usr/sbin     755 0 0
    dir /var          755 0 0
    dir /var/tmp      755 0 0
    dir /root         755 0 0
    dir /var/log      755 0 0

    nod /dev/console  644 0 0 c 5 1
    nod /dev/null     644 0 0 c 1 3
  '';
in runCommand name {
  passthru = args // { inherit cpio_list; };
} ''
  mkdir -p $out
  ${gen_init_cpio}/bin/gen_init_cpio -t 0 ${cpio_list} > $out/${name}
''
