/*
 * Copyright (c) 2020-2021 Dirli <litandrej85@gmail.com>
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

namespace Meteo.Structs {
    public struct WeatherStruct {
        public int64 date;
        public string description;
        public string icon_name;
        public string temp;
        public string pressure;
        public string wind;
        public string clouds;
        public string humidity;
    }

    public struct LocationStruct {
        public string city;
        public string country;
        public string idplace;
        public double latitude;
        public double longitude;
    }
}
