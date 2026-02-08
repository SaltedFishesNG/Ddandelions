{
  traits = [
    {
      name = "fcitx5";
      module =
        { conf, ... }:
        { pkgs, ... }:
        {
          i18n.inputMethod = {
            enable = true;
            type = "fcitx5";
            fcitx5 = {
              waylandFrontend = true;
              addons = with pkgs; [
                fcitx5-fluent
                fcitx5-gtk
                fcitx5-pinyin-zhwiki
                kdePackages.fcitx5-chinese-addons
              ];
              settings.addons = {
                classicui.globalSection.Theme = "FluentDark-solid";
                pinyin.globalSection.FirstRun = "False";
              };
              settings.inputMethod = {
                "Groups/0" = {
                  Name = "Default";
                  "Default Layout" = "us";
                  DefaultIM = "keyboard-us";
                };
                "Groups/0/Items/0" = {
                  Name = "keyboard-us";
                  Layout = "";
                };
                "Groups/0/Items/1" = {
                  Name = "pinyin";
                  Layout = "";
                };
              };
              settings.globalOptions = {
                # 切换输入法
                "Hotkey/TriggerKeys" = {
                  "0" = "Control+space";
                };
                # 激活输入法
                "Hotkey/ActivateKeys" = {
                  "0" = "VoidSymbol";
                };
                # 取消激活输入法
                "Hotkey/DeactivateKeys" = {
                  "0" = "VoidSymbol";
                };
                # 临时切换输入法
                "Hotkey/AltTriggerKeys" = {
                  "0" = "VoidSymbol";
                };
                # 向前切换输入法分组
                "Hotkey/EnumerateGroupForwardKeys" = {
                  "0" = "VoidSymbol";
                };
                # 向后切换输入法分组
                "Hotkey/EnumerateGroupBackwardKeys" = {
                  "0" = "VoidSymbol";
                };
                Behavior = {
                  # 允许在密码框中使用输入法
                  AllowInputMethodForPassword = true;
                  # 输入密码时显示预编辑文本
                  ShowPreeditForPassword = true;
                };
              };
              ignoreUserConfig = true;
            };
          };
        };
    }
  ];
}
