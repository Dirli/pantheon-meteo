/*
 * Copyright (c) 2018-2021 Dirli <litandrej85@gmail.com>
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

namespace Meteo.Enums {
    public enum EntryColumn {
        DISPLAY_NAME = 0,
        LOCATION,
        LOCAL_COMPARE_NAME,
        ENGLISH_COMPARE_NAME,
        NUM_COLUMNS
    }

    public enum ForecastType {
        CURRENT,
        PERIOD,
    }

    public enum ForecastProvider {
        GWEATHER;
        //  OWM;

        public string to_string () {
            switch (this) {
                case GWEATHER:
                    return "GWeather";
                //  case OWM:
                //      return "OpenWeatherMap";
                default:
                    GLib.assert_not_reached ();
            }
        }
    }

    public enum Units {
        METRIC,
        IMPERIAL,
        CUSTOM;

        public string to_string () {
            switch (this) {
                case IMPERIAL:
                    return "imperial";
                case METRIC:
                    return "metric";
                case CUSTOM:
                    return "";
                default:
                    GLib.assert_not_reached ();
            }
        }
    }
}
