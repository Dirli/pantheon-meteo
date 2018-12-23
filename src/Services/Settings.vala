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

public class Meteo.Services.Settings : GLib.Settings {
    private static Settings ? instance = null;

    private Settings () {
        Object(schema_id: "io.elementary.meteo");
    }

    public static Settings get_default () {
        if (instance == null) {
            instance = new Settings ();
        }

        return instance;
    }
}
