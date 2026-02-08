{
  traits = [
    {
      name = "proxy";
      module =
        { conf, ... }:
        { lib, pkgs, ... }:
        {
          disabledModules = [ "services/networking/xray.nix" ];
          imports = [ ./_services/xray.nix ];
          services.v2raya = {
            enable = true;
            cliPackage = pkgs.xray;
          };

          systemd.tmpfiles.rules = [
            "L+ /root/.local/share/xray/geoip.dat   - root root - ${pkgs.v2ray-geoip}/share/v2ray/geoip.dat"
            "L+ /root/.local/share/xray/geosite.dat - root root - ${pkgs.v2ray-domain-list-community}/share/v2ray/geosite.dat"
          ];

          boot.kernel.sysctl = {
            "net.ipv4.ip_forward" = 1;
            "net.ipv6.conf.all.forwarding" = 1;
          };

          services.xray.enable = true;
          services.xray.settings = {
            log.loglevel = "info";

            inbounds = [
              {
                tag = "tun";
                protocol = "tun";
                settings = {
                  name = "xray_tun";
                  MTU = 1500;
                  UserLevel = 0;
                };
                sniffing = {
                  enabled = true;
                  destOverride = [
                    "http"
                    "tls"
                    "quic"
                  ];
                  metadataOnly = false;
                  domainsExcluded = [ ];
                  routeOnly = true;
                };
              }
            ];

            outbounds = [
              {
                tag = "proxy";
                protocol = "socks";
                settings = {
                  address = "127.0.0.1";
                  port = 1024;
                };
              }
              {
                tag = "direct";
                protocol = "freedom";
              }
            ];

            routing = {
              domainStrategy = "AsIs";
              rules = [
                {
                  inboundTag = [ "tun" ];
                  outboundTag = "direct";
                  process = [
                    ".v2rayA-wrapped"
                    ".xray-wrapped"
                    "sing-box"
                  ];
                }
                {
                  inboundTag = [ "tun" ];
                  outboundTag = "direct";
                  ip = [ "geoip:private" ];
                }
                {
                  inboundTag = [ "tun" ];
                  outboundTag = "direct";
                  domain = [ "geosite:private" ];
                }
                {
                  inboundTag = [ "tun" ];
                  outboundTag = "proxy";
                }
              ];
            };
          };
          systemd.services.xray.wantedBy = lib.mkForce [ ];

          services.sing-box.enable = true;
          services.sing-box.settings = {
            log.level = "info";
            log.timestamp = true;

            inbounds = [
              {
                tag = "tun";
                type = "tun";
                interface_name = "singbox_tun";
                address = [
                  "172.19.0.1/30"
                  "fdfe:dcba:9876::1/126"
                ];
                mtu = 9000;
                auto_route = true;
                strict_route = true;
                stack = "gvisor";
              }
            ];

            outbounds = [
              {
                tag = "proxy";
                type = "socks";
                version = "5";
                server = "127.0.0.1";
                server_port = 1024;
              }
              {
                tag = "direct";
                type = "direct";
              }
            ];

            route = {
              auto_detect_interface = true;
              rules = [
                {
                  outbound = "direct";
                  process_name = [
                    ".v2rayA-wrapped"
                    ".xray-wrapped"
                    "xray"
                  ];
                }
                {
                  outbound = "direct";
                  ip_is_private = true;
                }
                {
                  outbound = "direct";
                  rule_set = [ "geosite-private" ];
                }
                { outbound = "proxy"; }
              ];
              rule_set = [
                {
                  tag = "geosite-private";
                  type = "local";
                  format = "binary";
                  path = "${pkgs.sing-geosite}/share/sing-box/rule-set/geosite-private.srs";
                }
              ];
              final = "proxy";
            };
          };
          systemd.services.sing-box.wantedBy = lib.mkForce [ ];
        };
    }
  ];
}
