/*
 * CLI.hpp
 * command line interface core/common routines for libtzsolar (C++ implementation of LongitudeTZ)
 */

#pragma once
#include <string>
#include <iostream>
#include <optional>
#include "version.hpp"
#include <boost/program_options.hpp>
#include <boost/algorithm/string.hpp>

namespace po = boost::program_options;
namespace alg = boost::algorithm;

namespace longitude_tz {

    template<class TZ>
    class CLI {

        private:

        TZ tz_obj;

        protected:

        // convert CLI arguments to a TZ object (TZSolar or compatible interface)
        static const TZ arg2tz(const po::variables_map &vm) {
            // create TZSolar object from --tzname request
            if (vm.count("tzname") > 0) {
                std::string tzname = vm["tzname"].as<std::string>();
                return TZ(tzname);
            }

            // create TZSolar object from --longitude request
            if (vm.count("longitude") <= 0) {
                // if control fell through, report parameter error
                throw std::runtime_error( "build_tz_obj: --tzname or --longitude option required" );
            }

            // initialize
            float lon = vm["longitude"].as<float>();
            bool use_lon_tz = false;  // flag defaults to false
            if (vm.count("type") > 0) {
                std::string type_param = vm["type"].as<std::string>();
                if (type_param == "longitude" or type_param == "lon") {
                    use_lon_tz = true;
                } else if (type_param == "hour") {
                    use_lon_tz = false;
                } else {
                    throw std::runtime_error( std::string("build_tz_obj: bad --type '" + type_param
                        + "' - use hour or longitude"));
                }
            }
            std::optional<short> opt_latitude;
            if (vm.count("latitude") > 0) {
                float lat = vm["latitude"].as<float>();
                opt_latitude.emplace(lat);
            }
            return TZ(lon, use_lon_tz, opt_latitude);
        }

        public:

        // constructor
        explicit CLI(const po::variables_map &vm) : tz_obj(arg2tz(vm)) {}

        // destructor
        virtual ~CLI() {};

        // convert an int to a string with zero-padding
        static std::string zeropad(const std::size_t length, const unsigned short value) {
            std::string num = std::to_string(value);
            if (num.length() > length) {
                return num;
            }
            std::string pad(std::size_t(length - num.length()), '0');
            return pad + num;
        }
        
        // generate standard 1-hour-wide (15 degrees longitude) time zones
        // input parameter: integer hours from GMT in the range
        // These correspond to the GMT+x/GMT-x time zones, except with boundaries defined by longitude lines.
        static void gen_hour_tz(const short hour) {
            // validate parameter
            if (hour<-12 || hour>12) {
                throw std::runtime_error( "gen_hour_tz: hour parameter must be -12 to +12 inclusive" );
            }

            // Hours line up with time zones. So it's a equal to time zone offset.
            std::string sign = (hour >= 0) ? "+" : "-";
            std::string e_w = (hour >= 0) ? "East" : "West";

            // generate strings from time zone parameters
            unsigned short offset_hr = std::abs(hour);
            unsigned short offset_min = 0;
            std::string zone_abbrev = e_w + zeropad(2, offset_hr);
            std::string zone_name = std::string("Solar/") + zone_abbrev;
            std::string offset_str = sign + std::to_string(offset_hr) + ":" + zeropad(2, offset_min);

            // output time zone data
            std::cout << std::string("# Solar Time by hourly increment: ") << sign << offset_hr << std::endl;
            std::cout << "# Zone\tNAME\t\tSTDOFF\tRULES\tFORMAT\t[UNTIL]" << std::endl;
            std::cout << "Zone\t" << zone_name << "\t" << offset_str << "\t-\t" << zone_abbrev << std::endl;
            std::cout << std::endl;
            return;
        }

        // generate longitude-based solar time zone info
        // input parameter: integer degrees of longitude in the range 180 to -180,
        // Solar Time Zone centered on the meridian, including one half degree either side of the meridian.
        // Each time zone is named for its 1-degree-wide range.
        // The exception is at the Solar Date Line, where +12 and -12 time zones are one half degree wide.
        static void gen_lon_tz(const short deg) {
            // validate parameter
            if (deg<-180 || deg>180) {
                throw std::runtime_error( "gen_lon_tz: longitude parameter must be -180 to +180 inclusive" );
            }

            // use integer degrees to compute time zone parameters: longitude, east/west sign and minutes offset
            // $deg>=0: positive degrees (east longitude), straightforward assignments of data
            // $deg<0: negative degrees (west longitude)
            std::string sign = (deg >= 0) ? "" : "-";
            std::string e_w = (deg >= 0) ? "E" : "W";

            // derive time zone parameters from 4 minutes of offset for each degree of longitude
            unsigned short lon = std::abs(deg);
            unsigned short offset = 4 * lon;
            unsigned short offset_hr = int(offset/60);
            unsigned short offset_min = offset%60;

            // generate strings from time zone parameters
            std::string zone_abbrev = std::string("Lon") + zeropad(3, lon) + e_w;
            std::string zone_name = std::string("Solar/") + zone_abbrev;
            std::string offset_str = sign + std::to_string(offset_hr) + ":" + zeropad(2, offset_min);

            // output time zone data
            std::cout << std::string("# Solar Time by degree of longitude: ") << lon << " " << e_w << std::endl;
            std::cout << "# Zone\tNAME\t\tSTDOFF\tRULES\tFORMAT\t[UNTIL]" << std::endl;
            std::cout << "Zone\t" << zone_name << "\t" << offset_str << "\t-\t" << zone_abbrev << std::endl;
            std::cout << std::endl;
            return;
        }

        // generate and print tzfile data on standard output
        static void do_tzfile() {
            // generate solar time zones in increments of 15 degrees of longitude (EastXX or WestXX)
            // standard 1-hour-wide time zones
            for (short h_zone = -12; h_zone <= 12; h_zone++) {
                gen_hour_tz(h_zone);
            }

            // generate solar time zones in incrememnts of 4 minutes / 1 degree of longitude (LonXXXE or LonXXXW)
            // hyperlocal 4-minute-wide time zones for conversion to/from niche uses of local solar time
            for (short d_zone = -180; d_zone <= 180; d_zone++) {
                gen_lon_tz(d_zone);
            }
        }
        
        // process get requests on specified fields
        void do_tz_op(const std::string &get_param) {
            std::vector<std::string> get_fields;
            alg::split( get_fields, get_param, alg::is_any_of(","));
            for ( auto iter = get_fields.begin(); iter != get_fields.end(); iter++ ) {
                auto value = tz_obj.get(*iter);
                if (value.has_value()) {
                    std::cout << value.value() << std::endl;
                } else {
                    std::cout << std::endl;
                }
            }
        }

        // core of the mainline routine
        static int mainline_core(int argc, char* argv[]) {
            po::options_description desc("lon-tz longitude time zones tool usage");

            // define options
            desc.add_options()
            ("help", "Display this help message")
            ("version", "Display the version number")
            ("debug", "Enable debugging output")
            ("tzfile,tzdata", "Generate timezone database file")
            ("tzname", po::value<std::string>(), "Select a solar time zone by name")
            ("longitude", po::value<float>(), "Set the longitude parameter for a solar time zone")
            ("latitude", po::value<float>(), "Set the optional latitude parameter for a solar time zone")
            ("type", po::value<std::string>(), "Set the type of a solar time zone as 'longitude' or 'hour', defaults to hour")
            ("get", po::value<std::string>(), "Specify field(s) to print from a solar time zone")
            ;

            // process options
            po::variables_map vm;
            po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
            po::notify(vm);

            // print help
            if (vm.count("help")) {
                std::cout << desc;
                return 0;
            }

            // print version
            if (vm.count("version")) {
                std::cout << "Longitude time zones library, C++ implementation version " << lon_tz_version.full;
                return 0;
            }

            // set debugging flag
            if (vm.count("debug")) {
                TZ::set_debug_flag(true);
            }

            // check that one and only one of the mutually-exclusive arguments was provided
            bool has_tzfile = vm.count("tzfile") > 0;
            bool has_tzname = vm.count("tzname") > 0;
            bool has_lon = vm.count("longitude") > 0;
            if ((has_tzfile ? 1 : 0) + (has_tzname ? 1 : 0) + (has_lon ? 1 : 0) != 1 ) {
                std::cerr << "usage: " << desc;
                throw std::runtime_error( "Mutually exclusive arguments: one and only one of --tzfile, --tzname or --longitude allowed" );
            }

            // output tzfile time zone data
            if ( has_tzfile ) {
                CLI<TZ>::do_tzfile();
                return 0;
            }

            // process time zone queries specified from --tzname or --longitude
            // note: by the logic above, one and only one of --tzname or --longitude must be set at this point
            CLI<TZ> cli_obj(vm);

            // process get requests for specified field(s)
            cli_obj.do_tz_op(vm["get"].as<std::string>());

            return 0;
        }
    };
}
