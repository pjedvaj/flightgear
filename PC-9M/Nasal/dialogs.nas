var Radio = gui.Dialog.new("/sim/gui/dialogs/radios/dialog",
        "Aircraft/PC-9M/Systems/tranceivers.xml");

var ap_settings = gui.Dialog.new("/sim/gui/dialogs/autopilot/dialog",
        "Aircraft/PC-9M/Systems/autopilot-dlg.xml");

gui.menuBind("radio", "dialogs.Radio.open()");
gui.menuBind("autopilot-settings", "dialogs.ap_settings.open()");


