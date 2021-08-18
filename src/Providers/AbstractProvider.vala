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
    public abstract class Providers.AbstractProvider : GLib.Object {
        public signal void show_alert (uint code);
        public signal void updated_today (Structs.WeatherStruct w);
        public signal void updated_long (Gee.ArrayList<Structs.WeatherStruct?> f);

        public int64 sunrise { get; set; default = 0; }
        public int64 sunset { get; set; default = 0; }

        public abstract void update_forecast (bool advanced, string units);
    }
}
