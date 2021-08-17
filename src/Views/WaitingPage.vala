/*
 * Copyright (c) 2021 Dirli <litandrej85@gmail.com>
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
    public class Views.WaitingPage : Gtk.Box {
        public signal void time_up ();

        private uint t_id = 0;
        private uint waiting_time = 0;

        private Gtk.Spinner spinner;
        private Gtk.Label page_label;

        public WaitingPage () {
            Object (orientation: Gtk.Orientation.HORIZONTAL,
                    spacing: 10,
                    valign: Gtk.Align.CENTER,
                    halign: Gtk.Align.CENTER);
        }

        construct {
            spinner = new Gtk.Spinner ();
            page_label = new Gtk.Label (null);

            add (spinner);
            add (page_label);

            get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        }

        public void update_page_label (string s) {
            page_label.set_label (s);
        }

        public void start_spinner (bool start) {
            waiting_time = 0;

            if (start) {
                spinner.start ();

                if (t_id == 0) {
                    t_id = GLib.Timeout.add_seconds (1, () => {
                        if (waiting_time++ < 15) {
                            return true;
                        } else {
                            start_spinner (false);
                            time_up ();

                            return false;
                        }
                    });
                }
            } else {
                spinner.stop ();

                if (t_id > 0) {
                    GLib.Source.remove (t_id);
                    t_id = 0;
                }
            }
        }
    }
}
