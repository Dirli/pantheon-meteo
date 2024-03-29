/*
 * Copyright (c) 2018-2020 Dirli <litandrej85@gmail.com>
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
    public class Views.DefaultPage : Granite.Widgets.Welcome  {
        public DefaultPage () {
            Object (title: _("Weather application"),
                    subtitle: _("Displays the weather forecast for the selected city."));
        }

        construct {
            append ("find-location-symbolic", _("Auto location"), _("Determine automatically location"));
            append ("mark-location-symbolic", _("Manual location"), _("Determine the location manually"));
        }
    }
}
