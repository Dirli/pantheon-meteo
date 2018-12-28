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

namespace Meteo.Widgets {
    public class Preferences : Gtk.Dialog {
        private GLib.Settings settings;
        private bool flag;
        public Preferences (Meteo.MainWindow window, Meteo.Widgets.Header header) {
            resizable = false;
            deletable = false;
            transient_for = window;
            modal = true;

            settings = Meteo.Services.Settings.get_default ();
            flag = false;

            //Define sections
            Gtk.Label tit1_pref = new Gtk.Label ("Interface");
            tit1_pref.get_style_context ().add_class ("preferences");
            tit1_pref.halign = Gtk.Align.START;
            var tit2_pref = new Gtk.Label ("General");
            tit2_pref.get_style_context ().add_class ("preferences");
            tit2_pref.halign = Gtk.Align.START;

            //Select type of icons:symbolic or realistic
            Gtk.Label icon_label = new Gtk.Label ("Symbolic icons:");
            icon_label.halign = Gtk.Align.END;
            Gtk.Switch icon = new Gtk.Switch ();
            icon.halign = Gtk.Align.START;

            //Update interval
            Gtk.Label update_lab = new Gtk.Label ("Update conditions every :");
            update_lab.halign = Gtk.Align.END;
            Gtk.SpinButton update_box = new Gtk.SpinButton.with_range (1, 24, 1);
            update_box.set_halign (Gtk.Align.END);
            update_box.set_width_chars (4);

            //System units
            Gtk.Label unit_lab = new Gtk.Label ("Units" + ":");
            unit_lab.halign = Gtk.Align.CENTER;

            var unit_box = new Granite.Widgets.ModeButton ();
            unit_box.append_text ("\u00B0" + "C - m/s");
            unit_box.append_text ("\u00B0" + "F - mph");

            if (settings.get_string ("units") == "metric") {
                unit_box.selected = 0;
            } else {
                unit_box.selected = 1;
            }

            //Automatic location
            Gtk.Label loc_label = new Gtk.Label ("Find my location automatically:");
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
            Gtk.Label ind_label = new Gtk.Label ("Use System Tray Indicator:");
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

            Gtk.Box content = this.get_content_area () as Gtk.Box;
            content.valign = Gtk.Align.START;
            content.border_width = 6;
            content.add (layout);

            //Actions
            add_button ("Close", Gtk.ResponseType.CLOSE);
            this.response.connect ((source, response_id) => {
                switch (response_id) {
                    case Gtk.ResponseType.CLOSE:
                        if (flag) {
                            Meteo.Utils.clear_cache ();
                            settings.set_boolean ("refresh", true);
                            settings.set_boolean ("refresh", false);
                        }
                        destroy ();
                        break;
                }
            });
            show_all ();

            settings.bind("auto", loc, "active", GLib.SettingsBindFlags.DEFAULT);
#if INDICATOR_EXIST
            settings.bind("indicator", ind, "active", GLib.SettingsBindFlags.DEFAULT);
#endif
            settings.bind("symbolic", icon, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("interval", update_box, "value", SettingsBindFlags.DEFAULT);
            unit_box.mode_changed.connect (() => {
                if (unit_box.selected == 1) {
                    settings.set_string ("units", "imperial");
                } else {
                    settings.set_string ("units", "metric");
                }
            });
            settings.changed.connect(on_settings_change);
        }

        private void on_settings_change(string key) {
            switch (key) {
                case "units":
                case "auto":
                case "symbolic":
                    flag = true;
                break;
            }
        }
    }
}
