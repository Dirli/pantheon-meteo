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
        public string location;
        public string country;
        public string idplace;
    }
}
