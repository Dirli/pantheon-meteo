/*
* Copyright (c) 2018 Dirli <litandrej85@gmail.com>
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*/

namespace Meteo {
    public class Dialogs.Preferences : Gtk.Dialog {
        public Preferences (MainWindow main_window) {
            Object (border_width: 6,
                    deletable: false,
                    destroy_with_parent: true,
                    resizable: false,
                    title: _("Preferences"),
                    transient_for: main_window,
                    window_position: Gtk.WindowPosition.CENTER_ON_PARENT
            );

            modal = true;

            string? flag = null;

            //Define sections
            Gtk.Label tit1_pref = new Gtk.Label (_("Interface"));
            tit1_pref.get_style_context ().add_class ("preferences");
            tit1_pref.halign = Gtk.Align.START;
            var tit2_pref = new Gtk.Label (_("General"));
            tit2_pref.get_style_context ().add_class ("preferences");
            tit2_pref.halign = Gtk.Align.START;

            //Select type of icons:symbolic or realistic
            Gtk.Label icon_label = new Gtk.Label (_("Symbolic icons") + ":");
            icon_label.halign = Gtk.Align.END;
            Gtk.Switch icon = new Gtk.Switch ();
            icon.halign = Gtk.Align.START;

            //Update interval
            Gtk.Label update_lab = new Gtk.Label (_("Update conditions every") + " :");
            update_lab.halign = Gtk.Align.END;
            Gtk.SpinButton update_box = new Gtk.SpinButton.with_range (1, 24, 1);
            update_box.set_halign (Gtk.Align.END);
            update_box.set_width_chars (4);

            //System units
            Gtk.Label unit_lab = new Gtk.Label (_("Units") + ":");
            unit_lab.halign = Gtk.Align.CENTER;

            var unit_box = new Granite.Widgets.ModeButton ();
            unit_box.append_text ("\u00B0" + "C - m/s");
            unit_box.append_text ("\u00B0" + "F - mph");

            if (main_window.settings.get_string ("units") == "metric") {
                unit_box.selected = 0;
            } else {
                unit_box.selected = 1;
            }

            // local api ley
            Gtk.Label api_key_label = new Gtk.Label (_("Personal api key") + ":");
            api_key_label.halign = Gtk.Align.START;
            var local_key = new Gtk.Entry ();
            local_key.hexpand = true;
            local_key.placeholder_text = _("Enter personal api key");

            //Automatic location
            Gtk.Label loc_label = new Gtk.Label (_("Find my location automatically") + ":");
            loc_label.halign = Gtk.Align.END;
            Gtk.Switch loc = new Gtk.Switch ();
            loc.halign = Gtk.Align.START;

            //Create UI
            var layout = new Gtk.Grid ();
            layout.valign = Gtk.Align.START;
            layout.column_spacing = 12;
            layout.row_spacing = 12;
            layout.margin = 12;
            layout.margin_top = 0;

            layout.attach (tit1_pref,  0, 0, 2, 1);

            layout.attach (icon_label, 0, 1, 1, 1);
            layout.attach (icon,       1, 1, 1, 1);

            //Select indicator
#if INDICATOR_EXIST
            Gtk.Label ind_label = new Gtk.Label (_("Use System Tray Indicator") + ":");
            ind_label.halign = Gtk.Align.END;
            Gtk.Switch ind = new Gtk.Switch ();
            ind.halign = Gtk.Align.START;
            layout.attach (ind_label,  0, 2, 1, 1);
            layout.attach (ind,        1, 2, 1, 1);
#endif

            layout.attach (tit2_pref,  0, 3, 2, 1);
            layout.attach (unit_lab,   0, 4, 2, 1);
            layout.attach (unit_box,   0, 5, 2, 1);
            layout.attach (update_lab, 0, 6, 1, 1);
            layout.attach (update_box, 1, 6, 1, 1);
            layout.attach (loc_label,  0, 7, 1, 1);
            layout.attach (loc,        1, 7, 1, 1);
            layout.attach (api_key_label, 0, 8, 2, 1);
            layout.attach (local_key,     0, 9, 2, 1);

            Gtk.Box content = this.get_content_area () as Gtk.Box;
            content.valign = Gtk.Align.START;
            content.border_width = 6;
            content.add (layout);

            //Actions
            add_button (_("Close"), Gtk.ResponseType.CLOSE);
            this.response.connect ((source, response_id) => {
                switch (response_id) {
                    case Gtk.ResponseType.CLOSE:
                        if (flag != null) {
                            Utils.clear_cache ();
                            main_window.settings.set_string ("idplace", flag);
                        }
                        destroy ();
                        break;
                }
            });
            show_all ();

            main_window.settings.bind("auto", loc, "active", GLib.SettingsBindFlags.DEFAULT);
#if INDICATOR_EXIST
            main_window.settings.bind("indicator", ind, "active", GLib.SettingsBindFlags.DEFAULT);
#endif
            main_window.settings.bind("symbolic", icon, "active", GLib.SettingsBindFlags.DEFAULT);
            main_window.settings.bind("interval", update_box, "value", SettingsBindFlags.DEFAULT);
            main_window.settings.bind("personal-key", local_key, "text", SettingsBindFlags.DEFAULT);
            unit_box.mode_changed.connect (() => {
                if (unit_box.selected == 1) {
                    main_window.settings.set_string ("units", "imperial");
                } else {
                    main_window.settings.set_string ("units", "metric");
                }
                flag = main_window.settings.get_string ("idplace");
            });
            icon.state_set.connect((state) => {
                flag = main_window.settings.get_string ("idplace");
                return false;
            });
            loc.state_set.connect((state) => {
                flag = main_window.settings.get_boolean ("auto") ? "" : "0";
                return false;
            });
        }
    }
}
