ALL: world_outline_map.svg world_zone_map.png world_zone_map-1200.png

map_dl/ne_50m_admin_0_countries.shp:
	[ -d map_dl ] || mkdir map_dl
	cd map_dl \
		&& curl https://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_countries.zip --output ne_50m_admin_0_countries.zip \
		&& unzip ne_50m_admin_0_countries.zip

map_dl/ne_50m_admin_0_tiny_countries.shp:
	[ -d map_dl ] || mkdir map_dl
	cd map_dl \
		&& curl https://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_tiny_countries.zip --output ne_50m_admin_0_tiny_countries.zip \
		&& unzip ne_50m_admin_0_tiny_countries.zip

map_dl/ne_50m_graticules_15.shp:
	[ -d map_dl ] || mkdir map_dl
	cd map_dl \
		&& curl https://naciscdn.org/naturalearth/50m/physical/ne_50m_graticules_15.zip --output ne_50m_graticules_15.zip \
		&& unzip ne_50m_graticules_15.zip

world_outline_map.svg: perlshaper.pl map_dl/ne_50m_admin_0_countries.shp map_dl/ne_50m_admin_0_tiny_countries.shp map_dl/ne_50m_graticules_15.shp Makefile
	./perlshaper.pl -v map_dl/ne_50m_admin_0_countries.shp map_dl/ne_50m_admin_0_tiny_countries.shp map_dl/ne_50m_graticules_15.shp -type location -round 2 -centre 0,0 -psize 0.25 -svgWidth 2400 -svgHeight 1100 -pointSize 0.25 > world_outline_map.svg

world_zone_map.png: world_outline_map.svg annotate-time-zones.pl Makefile
	./annotate-time-zones.pl > world_zone_map.png

world_zone_map-1200.png: world_zone_map.png
	pngtopnm "$<" | pamscale --width 1200 | pnmtopng -compression=9 > "$@"

