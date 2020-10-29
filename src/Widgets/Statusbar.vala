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
    public class Widgets.Statusbar : Gtk.ActionBar {
        private Gtk.Label new_msg;
        private Gtk.Label provider_label;
        private string provider_name = "openweathermap.org";

        construct {
            provider_label = new Gtk.Label ("");
            provider_label.margin = 10;
            pack_end (provider_label);

            new_msg = new Gtk.Label ("");
            new_msg.margin = 10;
            pack_start (new_msg);
        }

        public void mod_provider_label (bool personal_key) {
            provider_label.set_label (provider_name + (personal_key ? " (pesonal key)" : " (public key)"));
        }

        public void add_msg (string msg) {
            new_msg.set_text (msg);
        }

        public void no_connection () {
            new_msg.set_text (_("Check internet connection"));
        }

        public void bad_account () {
            new_msg.set_text (_("Problems with api-key"));
        }

        public void not_available () {
            new_msg.set_text (_("Data not available"));
        }

        public void not_location () {
            new_msg.set_text (_("No location defined"));
        }

        private static Meteo.Widgets.Statusbar? _statusbar = null;
        public static unowned Meteo.Widgets.Statusbar get_default () {
            if (_statusbar == null) {
                _statusbar = new Statusbar ();
            }
            return _statusbar;
        }

    }
}
