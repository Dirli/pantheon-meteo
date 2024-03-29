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

namespace Meteo {
    public class Services.Connector : GLib.Object {
        public Connector () {}

        public Providers.AbstractProvider? get_weather_provider (Enums.ForecastProvider provider_type, Structs.LocationStruct loc, string api) {
            if (provider_type == Enums.ForecastProvider.GWEATHER) {
                if (loc.city != "") {
                    return new Providers.GWeatherProvider (loc.city, loc.latitude, loc.longitude);
                }
            } else if (provider_type == Enums.ForecastProvider.OWM) {
                if (api != "") {
                    return new Providers.OWMProvider (api, loc);
                }
            }

            return null;
        }
    }
}
