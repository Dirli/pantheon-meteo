# Pantheon-meteo
Know the forecast of the next hours & days using OpenWeatherMap API (https://openweathermap.org/) or GWeather

<p align="left">
    <a href="https://paypal.me/Dirli85">
        <img src="https://img.shields.io/badge/Donate-PayPal-green.svg">
    </a>
</p>

----

### Features:
* Current weather, with information about temperature, pressure, wind speed and direction, sunrise & sunset.
* Forecast for next 18 hours.
* Forecast for next 5-10 days (depending on the provider).
* Choose your units (custom, metric or imperial).
* Choosing a forecast provider
* Wingpanel indicator.

----

![Screenshot](data/screenshot1.png)

![Screenshot](data/screenshot2.png)  

![Prefrences](data/screenshot3.png)

---

## Building and Installation

### You'll need the following dependencies to build:
* libgeoclue-2-dev
* libgranite-dev
* libgtk-3-dev
* libgweather-3-dev
* libjson-glib-dev
* libsoup2.4-dev
* libwingpanel-dev (>= 3.0)
* meson
* valac

### How to build
    meson build --prefix=/usr
    ninja -C build
    sudo ninja -C build install
