/*
 * Copyright (c) 2018-2020 Dirli <litandrej85@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

namespace Meteo {
    public class Dialogs.Preferences : Gtk.Dialog {
        public GLib.Settings settings {get;  construct set; }

        public Preferences (MainWindow main_window) {
            Object (border_width: 6,
                    modal: true,
                    deletable: false,
                    destroy_with_parent: true,
                    resizable: false,
                    title: _("Preferences"),
                    transient_for: main_window,
                    settings: main_window.settings,
                    window_position: Gtk.WindowPosition.CENTER_ON_PARENT);
        }

        construct {
            set_default_response (Gtk.ResponseType.CLOSE);

            //Interface sections
            var interface_title = new Gtk.Label (_("Interface"));
            interface_title.get_style_context ().add_class ("preferences");
            interface_title.halign = Gtk.Align.START;

            //Select type of icons:symbolic or realistic
            Gtk.Label icon_label = new Gtk.Label (_("Symbolic icons") + ":");
            icon_label.halign = Gtk.Align.END;
            Gtk.Switch icon = new Gtk.Switch ();
            icon.halign = Gtk.Align.START;

            //Create UI
            var layout = new Gtk.Grid ();
            layout.valign = Gtk.Align.START;
            layout.column_spacing = 12;
            layout.row_spacing = 12;
            layout.margin = 12;
            layout.margin_top = 0;

            var top = 0;
            layout.attach (interface_title, 0, top++, 2);
            layout.attach (icon_label,      0, top);
            layout.attach (icon,            1, top++);

            //Select indicator
#if INDICATOR_EXIST
            Gtk.Label ind_label = new Gtk.Label (_("Use System Tray Indicator") + ":");
            ind_label.halign = Gtk.Align.END;
            Gtk.Switch ind_switch = new Gtk.Switch ();
            ind_switch.halign = Gtk.Align.START;

            layout.attach (ind_label,  0, top);
            layout.attach (ind_switch, 1, top++);

            settings.bind ("indicator", ind_switch, "active", GLib.SettingsBindFlags.DEFAULT);
#endif

            //Update interval
            var days_label = new Gtk.Label (_("Display the forecast for (d.)") + " :");
            days_label.halign = Gtk.Align.END;
            var days_box = new Gtk.SpinButton.with_range (5, 10, 1);
            days_box.set_halign (Gtk.Align.START);
            days_box.set_width_chars (4);

            layout.attach (days_label,      0, top);
            layout.attach (days_box,        1, top++);
            layout.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, top++, 2, 1);

            // General section
            var general_title = new Gtk.Label (_("General"));
            general_title.get_style_context ().add_class ("preferences");
            general_title.halign = Gtk.Align.START;

            //System units
            var units = settings.get_int ("units");
            var unit_label = new Gtk.Label (_("Units") + ":");
            unit_label.halign = Gtk.Align.CENTER;
            var unit_box = new Granite.Widgets.ModeButton ();

            unit_box.append_text ("Metric");
            unit_box.append_text ("Imperial");
            unit_box.append_text ("Custom");
            unit_box.selected = units & 3;

            var tunit_label = new Gtk.Label (_("Temperature unit"));
            tunit_label.halign = Gtk.Align.END;
            var t_units = new Gtk.ComboBoxText ();
            t_units.append_text (_("kelvin"));
            t_units.append_text (_("centigrade"));
            t_units.append_text (_("fahrenheit"));
            t_units.active = (units & 00070) >> 3;

            var punit_label = new Gtk.Label (_("Pressure unit"));
            punit_label.halign = Gtk.Align.END;
            var p_units = new Gtk.ComboBoxText ();
            p_units.append_text (_("kiloPascal"));
            p_units.append_text (_("hectoPascal"));
            p_units.append_text (_("millibars"));
            p_units.append_text (_("millimeters of mercury"));
            p_units.append_text (_("inches of mercury"));
            p_units.active = (units & 00700) >> 6;

            var sunit_label = new Gtk.Label (_("Speed unit"));
            sunit_label.halign = Gtk.Align.END;
            var s_units = new Gtk.ComboBoxText ();
            s_units.append_text (_("meters per second"));
            s_units.append_text (_("kilometers per hour"));
            s_units.append_text (_("miles per hour"));
            s_units.append_text (_("knots"));
            s_units.active = (units & 07000) >> 9;

            //Update interval
            var update_label = new Gtk.Label (_("Update conditions every (h.)") + " :");
            update_label.halign = Gtk.Align.END;
            var update_box = new Gtk.SpinButton.with_range (1, 24, 1);
            update_box.set_halign (Gtk.Align.START);
            update_box.set_width_chars (4);

            //Automatic location
            var location_label = new Gtk.Label (_("Find my location automatically") + ":");
            location_label.halign = Gtk.Align.END;
            Gtk.Switch loc = new Gtk.Switch ();
            loc.tooltip_text = _("Need to install the geoclue service");
            loc.halign = Gtk.Align.START;

            layout.attach (general_title,  0, top++, 2, 1);
            layout.attach (unit_label,     0, top++, 2, 1);
            layout.attach (unit_box,       0, top++, 2, 1);
            layout.attach (tunit_label,    0, top);
            layout.attach (t_units,        1, top++);
            layout.attach (punit_label,    0, top);
            layout.attach (p_units,        1, top++);
            layout.attach (sunit_label,    0, top);
            layout.attach (s_units,        1, top++);
            layout.attach (update_label,   0, top);
            layout.attach (update_box,     1, top++);
            layout.attach (location_label, 0, top);
            layout.attach (loc,            1, top++);
            layout.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, top++, 2, 1);

            // Providers section
            var providers_title = new Gtk.Label (_("Providers"));
            providers_title.get_style_context ().add_class ("preferences");
            providers_title.halign = Gtk.Align.START;

            var provider_label = new Gtk.Label (_("Provider"));
            provider_label.halign = Gtk.Align.END;
            var providers = new Gtk.ComboBoxText ();
            providers.append_text (Enums.ForecastProvider.GWEATHER.to_string ());
            //  providers.append_text (Enums.ForecastProvider.OWM.to_string ());
            providers.active = settings.get_enum ("provider");

            // local api ley
            var api_key_label = new Gtk.Label (_("Personal api key:"));
            api_key_label.halign = Gtk.Align.START;
            var api_key_entry = new Gtk.Entry ();
            api_key_entry.hexpand = true;
            api_key_entry.placeholder_text = _("Enter personal api key");

            GLib.Idle.add (() => {
                api_key_entry.sensitive = providers.active != 0;
                t_units.sensitive = unit_box.selected == 2;
                p_units.sensitive = unit_box.selected == 2;
                s_units.sensitive = unit_box.selected == 2;

                return false;
            });

            providers.changed.connect (() => {
                settings.reset ("personal-key");
                api_key_entry.sensitive = providers.active != 0;
            });

            layout.attach (providers_title, 0, top++, 2, 1);
            layout.attach (provider_label,  0, top);
            layout.attach (providers,       1, top++);
            layout.attach (api_key_label,   0, top++, 2, 1);
            layout.attach (api_key_entry,   0, top++, 2, 1);


            Gtk.Box content = this.get_content_area () as Gtk.Box;
            content.valign = Gtk.Align.START;
            content.border_width = 6;
            content.add (layout);

            //Actions
            add_button (_("Close"), Gtk.ResponseType.CLOSE);

            response.connect (() => {
                var new_unit = unit_box.selected;
                if (unit_box.selected == 2) {
                    new_unit |= (t_units.active << 3);
                    new_unit |= (p_units.active << 6);
                    new_unit |= (s_units.active << 9);
                }

                if (new_unit != units) {
                    settings.set_int ("units", new_unit);
                }

                if (providers.active != settings.get_enum ("provider")) {
                    if (providers.active == Enums.ForecastProvider.GWEATHER || api_key_entry.text.length > 0) {
                        settings.reset ("idplace");
                        settings.set_enum ("provider", providers.active);
                    } else {
                        //
                    }
                }

                destroy ();
            });

            settings.bind ("auto", loc, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("symbolic", icon, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("interval", update_box, "value", SettingsBindFlags.DEFAULT);
            settings.bind ("days-count", days_box, "value", SettingsBindFlags.DEFAULT);
            settings.bind ("personal-key", api_key_entry, "text", SettingsBindFlags.DEFAULT);

            unit_box.mode_changed.connect (() => {
                t_units.sensitive = unit_box.selected == 2;
                p_units.sensitive = unit_box.selected == 2;
                s_units.sensitive = unit_box.selected == 2;
            });
        }
    }
}
