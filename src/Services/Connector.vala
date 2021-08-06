/*
* Copyright (c) 2018-2021 Dirli <litandrej85@gmail.com>
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
    public class Services.Connector : Services.AbstractService {
        public bool use_symbolic { get; set; }

        public Connector () {}

        public Providers.AbstractProvider? get_weather_provider (string api, string id) {
            var provider = new Providers.OWMProvider (api, id, use_symbolic);

            return provider;
        }


    }
}
