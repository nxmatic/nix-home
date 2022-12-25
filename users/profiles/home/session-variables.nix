{ config, pkgs, ... }:
let
  xdg = config.home-manager.users."${config.lima-vm.user.name}".xdg;
  variables = {
    XDG_CONFIG_HOME = xdg.configHome;
    XDG_CACHE_HOME = xdg.cacheHome;
    XDG_DATA_HOME = xdg.dataHome;

    EDITOR = "/etc/profiles/per-user/${config.lima-vm.user.name}/bin/nvim";
    VISUAL = "/etc/profiles/per-user/${config.lima-vm.user.name}/bin/nvim";

    # fix "xdg-open fork-bomb" your preferred browser from here
    BROWSER = "${pkgs.firefox-wayland}/bin/firefox";

    # node
    NODE_REPL_HISTORY = "${xdg.dataHome}/node_repl_history";
    PKG_CACHE_PATH = "${xdg.cacheHome}/pkg-cache";

    # npm
    NPM_CONFIG_USERCONFIG = "${xdg.configHome}/npm/config";
    NPM_CONFIG_CACHE = "${xdg.configHome}/npm";
    # TODO: used to be XDG_RUNTIME_DIR NPM_CONFIG_TMP = "/tmp/npm";

    # Make sure virsh runs without root
    LIBVIRT_DEFAULT_URI = "qemu:///system";

    # wget
    WGETRC = "${xdg.configHome}/wgetrc";

    # Java
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot='${xdg.configHome}/java'";
    _JAVA_AWT_WM_NONREPARENTING = "1";

    # docker
    DOCKER_CONFIG = "${xdg.configHome}/docker";
  };
in
{
  home-manager = pkgs.lib.setAttrByPath [ "users" config.lima-vm.user.name ] {
    home.sessionVariables = variables;
    systemd.user.sessionVariables = variables;
  };
}
