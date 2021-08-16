/*
 * Copyright (c) 2018 Dirli <litandrej85@gmail.com>
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
    public class Widgets.Statusbar : Gtk.ActionBar {
        private Gtk.Label new_msg;
        private Gtk.Label provider_label;
        private string provider_name = "openweathermap.org";

        construct {
            provider_label = new Gtk.Label ("");
            provider_label.margin = 2;
            pack_end (provider_label);

            new_msg = new Gtk.Label ("");
            new_msg.margin = 2;
            pack_start (new_msg);
        }

        public void mod_provider_label (bool personal_key) {
            provider_label.set_label (provider_name + (personal_key ? " (pesonal key)" : " (public key)"));
        }

        public void add_msg (string msg) {
            new_msg.set_text (msg);
        }
    }
}
