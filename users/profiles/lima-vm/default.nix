{ hmUsers, ... }:
{
  home-manager.users = { inherit (hmUsers) lima-vm; };

  lima-vm = {
    # These are your personal settings
    # The only required settings are `name` and `password`,
    # for convenience, use publicKeys to add your SSH keys
    # The rest is used for programs like git
    user = {
      name = "lima-vm";
      password = "lima-vm";
      fullName = "lima VM";
      publicKeys = [ ];
    };
  };
}
