{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.valheim;
  escapeSlash = string: strings.escape ["/"] string;
in {
  options = {
    services.valheim = {
      enable = mkEnableOption "Valheim Dedicated Server";

      user = mkOption {
        type = types.str;
        default = "steam";
        description = lib.mdDoc ''
          User account under which valheim children processes run.
        '';
      };

      group = mkOption {
        type = types.str;
        default = "users";
        description = lib.mdDoc ''
          Group under which valheim children processes run.
        '';
      };

      installDir = mkOption {
        type = types.str;
        default = "Valheim";
        description = lib.mdDoc ''
          Where to install valheim dedicated server
        '';
      };

      servername = mkOption {
        type = types.str;
        default = "My server";
        description = lib.mdDoc ''
          Enter the name of your server that will be visible
          in the Server list
        '';
      };

      port = mkOption {
        type = types.int;
        default = 2456;
        description = lib.mdDoc ''
          Choose the Port which you want the server to
          communicate with. Please note that this has to
          correspond with the Port Forwarding settings on
          your Router.
          Valheim uses the specified Port AND specified
          Port+1. Default Ports are 2456-2457.
          If you’re using the Crossplay backend (enabled
          using the “-crossplay” argument), you do not
          need to do Port Forwarding on your Router. The
          Port number is still used to distinguish between
          multiple servers on the same public IP address
        '';
      };

      world = mkOption {
        type = types.str;
        default = "Dedicated";
        description = lib.mdDoc ''
          A World with the name entered will be created.
          You may also choose an already existing World
          by entering its name
        '';
      };

      secret = mkOption {
        type = types.str;
        default = "Secret";
        description = lib.mdDoc ''
          Set the password
        '';
      };

      saveDir = mkOption {
        type = types.str;
        default = "Saves";
        description = lib.mdDoc ''
          Overrides the default save path where Worlds
          and permission-files are stored.
        '';
      };

      # all read from saveDir location
      adminList = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc ''
          Add one Platform User ID per line to set admin role.
          The Platform User ID can be obtained from the Server log or from within the
          game using the F2 panel and follows the format [Platform]_[User ID] (case sensitive).
        '';
      };

      bannedList = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc ''
          Add one Platform User ID per line to ban player.
          The Platform User ID can be obtained from the Server log or from within the
          game using the F2 panel and follows the format [Platform]_[User ID] (case sensitive).
        '';
      };

      permittedList = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc ''
          Add one Platform User ID per line to allow player.
          The Platform User ID can be obtained from the Server log or from within the
          game using the F2 panel and follows the format [Platform]_[User ID] (case sensitive).
        '';
      };

      public = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc ''
          Set the visibility of your server. 1 is default and
          will make the server visible in the browser.
          Set it to 0 to make the server invisible and only
          joinable via the ‘Join IP’-button.
          Setting public to 0 is a good option if you wish to
          run a local LAN server, where players can join via
          the local IP of the server
        '';
      };

      logFile = mkOption {
        type = types.str;
        default = "Logs/log.txt";
        description = lib.mdDoc ''
          Sets the location to save the log file
        '';
      };

      saveInterval = mkOption {
        type = types.int;
        default = 1800;
        description = lib.mdDoc ''
          Change how often the world will save in seconds.
          Default is 30 minutes (1800 seconds).
        '';
      };

      backups = mkOption {
        type = types.int;
        default = 4;
        description = lib.mdDoc ''
          Sets how many automatic backups will be kept.
          The first is the ‘short’ backup length, and the rest
          are the ‘long’ backup length.
          By default that means one backup that is 2 hours
          old, and 3 backups that are 12 hours apart
        '';
      };

      backupsShort = mkOption {
        type = types.int;
        default = 7200;
        description = lib.mdDoc ''
          Sets the interval between the first automatic
          backups.
          Default is 2 hours (7200 seconds)
        '';
      };

      backupsLong = mkOption {
        type = types.int;
        default = 43200;
        description = lib.mdDoc ''
          Sets the interval between the subsequent
          automatic backups.
          Default is 12 hours (43200 seconds)
        '';
      };

      crossPlay = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Runs the Server on the Crossplay backend
          (PlayFab), which lets users from any platform
          join.
          If you do not include this argument, the Steam
          backend is used, which means only Steam users
          can see and join the Server
        '';
      };

      instanceID = mkOption {
        type = types.str;
        default = "1";
        description = lib.mdDoc ''
          If you’re hosting multiple servers with the same
          port from the same MAC address, write
          something unique here for each server to ensure
          that they get unique PlayFab IDs
        '';
      };
    };
  };

  # Implementation
  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      group = cfg.group;
      description = "valheim user";
      shell = pkgs.bash;
      isNormalUser = true;
		  createHome = true;
    };

    # this group already exists
    #users.groups = optionalAttrs (cfg.group == "users") {
    #  users.gid = config.ids.gids.users;
    #};

    networking.firewall = {
      allowedTCPPorts = [ cfg.port (cfg.port + 1) (cfg.port + 2) ];
      allowedUDPPorts = [ cfg.port (cfg.port + 1) (cfg.port + 2) ];
    };

    systemd.services.valheim = {
      description  = "Valheim Dedicated Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = with pkgs; [
        coreutils-full
        gnugrep
        gnused
        steamPackages.steamcmd
        patchelf
        steam-run
      ];
      script = ''
        cd ~
        rm -r {.local,.steam,.config,Valheim} || true
        mkdir -p {${cfg.saveDir}/worlds_local/,Valheim,Saves,Logs}

        ${if ((builtins.stringLength cfg.adminList) > 0) then "echo ${escapeShellArg cfg.adminList} > ${cfg.saveDir}/adminlist.txt" else ""}
        ${if ((builtins.stringLength cfg.bannedList) > 0) then "echo ${escapeShellArg cfg.bannedList} > ${cfg.saveDir}/bannedlist.txt" else ""}
        ${if ((builtins.stringLength cfg.permittedList) > 0) then "echo ${escapeShellArg cfg.permittedList} > ${cfg.saveDir}/permittedList.txt" else ""}

        steamcmd \
          +force_install_dir ~/${cfg.installDir} \
          +login anonymous +app_update 896660 validate \
          +quit

        cp ${cfg.installDir}/start_server.sh ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/\/bin\/bash/\/run\/current-system\/sw\/bin\/bash/' ${cfg.installDir}/custom_start_server.sh

        sed -i -E 's/My server/${cfg.servername}/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/2456/${builtins.toString cfg.port}/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/Dedicated/${cfg.world}/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/secret/${cfg.secret}/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/(-crossplay)/-savedir ~\/${escapeSlash cfg.saveDir} \1/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/(-crossplay)/-public ${builtins.toString (if cfg.public then 1 else 0)} \1/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/(-crossplay)/-logFile ~\/${escapeSlash cfg.logFile} \1/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/(-crossplay)/-saveinterval ${builtins.toString cfg.saveInterval} \1/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/(-crossplay)/-backups ${builtins.toString cfg.backups} \1/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/(-crossplay)/-backupsshort ${builtins.toString cfg.backupsShort} \1/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/(-crossplay)/-backupslong ${builtins.toString cfg.backupsLong} \1/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/(-crossplay)/-instanceid ${cfg.instanceID} \1/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/(-crossplay)/-nographics \1/' ${cfg.installDir}/custom_start_server.sh
        sed -i -E 's/(-crossplay)/${if cfg.crossPlay then "\1" else ""}/' ${cfg.installDir}/custom_start_server.sh

        cp ${cfg.installDir}/valheim_server.x86_64 ${cfg.installDir}/valheim_server.x86_64_Backup
        patchelf --set-interpreter ${pkgs.glibc}/lib64/ld-linux-x86-64.so.2 ${cfg.installDir}/valheim_server.x86_64

        cd ${cfg.installDir}
        steam-run ./custom_start_server.sh
      '';

      # according to https://www.freedesktop.org/software/systemd/man/systemd.service.html
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        TimeoutStartSec = "10min";

        ## Hardening
        # List of all Settings: from https://www.freedesktop.org/software/systemd/man/systemd-system.conf.html#
        ##NoNewPrivileges = "true";
        #OOMPolicy # kill when out of memory
        ##ProtectSystem = "full";
        ##ProtectKernelLogs = "true";
        ##ProtectControlGroups = "true";
        #PrivateTmp = "true";
        #PrivateDevices # for Services with PrivateUsers
        #MemoryDenyWriteExecute # reject generating code at runtime
      };
    };
  };
}

### Seperating valheim into multiple unit files:
#    systemd.services.install-valheim = {
#      description  = "Install and update Valheim Dedicated Server";
#      wantedBy = [ "multi-user.target" ];
#      after = [ "network.target" ];
#      path = with pkgs; [
#        steamPackages.steamcmd
#        patchelf
#      ];
#
#      script = ''
#        cd ~
#        rm -r {.local,.steam,.config,Valheim} || true
#        mkdir -p {${cfg.saveDir}/worlds_local/,Valheim,Saves,Logs}
#
#        ${if ((builtins.stringLength cfg.adminList) > 0) then "echo ${escapeShellArg cfg.adminList} > ${cfg.saveDir}/adminlist.txt" else ""}
#        ${if ((builtins.stringLength cfg.bannedList) > 0) then "echo ${escapeShellArg cfg.bannedList} > ${cfg.saveDir}/bannedlist.txt" else ""}
#        ${if ((builtins.stringLength cfg.permittedList) > 0) then "echo ${escapeShellArg cfg.permittedList} > ${cfg.saveDir}/permittedList.txt" else ""}
#
#        steamcmd +@sSteamCmdForcePlatformType linux \
#                 +force_install_dir ~/${cfg.installDir} \
#                 +login anonymous \
#                 +app_update 896660 -beta none validate  \
#                 +quit
#
#        cp ${cfg.installDir}/valheim_server.x86_64 ${cfg.installDir}/valheim_server.x86_64_Backup
#        patchelf --set-interpreter ${pkgs.glibc}/lib64/ld-linux-x86-64.so.2 ${cfg.installDir}/valheim_server.x86_64
#      '';
#
#      serviceConfig = {
#        User = cfg.user;
#        Group = cfg.group;
#        TimeoutStartSec = "10min";
#      };
#    };
#
#    systemd.services.valheim-server = {
#      description  = "Valheim Dedicated Server";
#      wantedBy = [ "multi-user.target" ];
#      after = [ "install-valheim.service" ];
#
#      path = with pkgs; [
#        coreutils-full
#        steam-run
#      ];
#
#      #"steam-run ./valheim_server.x86_64"
#
#      ## Hier ist glaube ich wieder das problem mit dem environment
#      script = ''
#			       export LD_LIBRARY_PATH="~/${cfg.installDir}/linux64:${pkgs.glibc}/lib";
#			       export SteamAppId="892970";
#
#             cd ~/${cfg.installDir}
#             steam-run ./valheim_server.x86_64
#              -name ${cfg.servername} \
#              -port ${builtins.toString cfg.port} \
#              -world ${cfg.world} \
#              -password ${cfg.secret} \
#              -savedir ~/${cfg.saveDir} \
#              -public ${builtins.toString cfg.public} \
#              -logFile ~/${cfg.logFile} \
#              -saveinterval ${builtins.toString cfg.saveInterval} \
#              -backups ${builtins.toString cfg.backups} \
#              -backupsshort ${builtins.toString cfg.backupsShort} \
#              -backupslong ${builtins.toString cfg.backupsLong} \
#              -instanceid ${cfg.instanceID} \
#              -nographics \
#              -batchmode \
#              ${if cfg.crossPlay then "-crossplay" else ""}
#      '';
#
#      # according to https://www.freedesktop.org/software/systemd/man/systemd.service.html
#      serviceConfig = {
#        User = cfg.user;
#        Group = cfg.group;
#        TimeoutStartSec = "10min";
#        #WorkingDirectory = "/home/${cfg.user}/${cfg.installDir}";
#
#        #ExecStart = lib.escapeShellArgs [
#        #  #"steam-run ./valheim_server.x86_64"
#        #  "/home/${cfg.user}/${cfg.installDir}/valheim_server.x86_64"
#        #  "-name ${cfg.servername}"
#        #  "-port ${builtins.toString cfg.port}"
#        #  "-world ${cfg.world}"
#        #  "-password ${cfg.secret}"
#        #  "-savedir ${cfg.saveDir}"
#        #  "-public ${builtins.toString cfg.public}"
#        #  "-logFile ${cfg.logFile}"
#        #  "-saveinterval ${builtins.toString cfg.saveInterval}"
#        #  "-backups ${builtins.toString cfg.backups}"
#        #  "-backupsshort ${builtins.toString cfg.backupsShort}"
#        #  "-backupslong ${builtins.toString cfg.backupsLong}"
#        #  "-instanceid ${cfg.instanceID}"
#        #  "-nographics"
#        #  "-batchmode"
#        #  "${if cfg.crossPlay then "-crossplay" else ""}"
#        #];
