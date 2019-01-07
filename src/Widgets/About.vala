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
    public class About : Granite.GtkPatch.AboutDialog {
        public About () {
            modal = true;
            destroy_with_parent = true;
            authors = {"Dirli <litandrej85@gmail.com>", "Carlos Suárez <bitseater@gmail.com>", "Paulo Galardi <lainsce@airmail.cc>"};
            comments = _("A forecast application with OpenWeatherMap API");
            license_type = Gtk.License.GPL_2_0;
            program_name = "Pantheon-meteo";
            translator_credits = "(ru) Dirli <litandrej85@gmail.com>";
            website = "https://github.com/Dirli/pantheon-meteo";
            website_label = _("website");
            logo_icon_name = "io.elementary.meteo";
            response.connect (() => {destroy ();});
            show_all ();
        }
    }
}
