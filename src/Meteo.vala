/*
* Copyright (c) 2018-2020 Dirli <litandrej85@gmail.com>
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
    public class MeteoApp : Gtk.Application {
        private MainWindow main_window;

        construct {
            application_id = Constants.APP_NAME;
            flags |= GLib.ApplicationFlags.FLAGS_NONE;
        }

        public override void activate () {
            if (main_window == null) {
                main_window = new MainWindow (this);
                main_window.show_all ();
            }

            main_window.present ();
        }

        public static int main (string [] args) {
            var app = new Meteo.MeteoApp ();
            return app.run (args);
        }
    }
}
