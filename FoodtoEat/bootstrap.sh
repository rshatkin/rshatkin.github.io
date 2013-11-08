cd ~
mkdir -p src
 
 
# First install PostgreSQL 9.2, plus contributed packages and any missing prerequisites
# ===
 
# add the Postgres PPA
echo 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main' \
  | sudo tee /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | sudo apt-key add -
sudo aptitude update
 
# the following is necessary on 13.04 (and possibly 12.10?)
sudo aptitude install postgresql-common --target-release raring
 
# then
sudo aptitude install postgresql-9.2 postgresql-server-dev-9.2 postgresql-contrib-9.2 \
  build-essential checkinstall libjson0-dev libxml2-dev libproj-dev python2.7-dev swig
 
 
# Now for GEOS, GDAL and PostGIS
# ===
 
# download and compile geos in /opt/geos
cd ~/src/
wget http://download.osgeo.org/geos/geos-3.4.1.tar.bz2
tar xvjf geos-3.4.1.tar.bz2
cd geos-3.4.1/
./configure --prefix=/opt/geos --enable-python
make -j2
sudo checkinstall  # uninstall with: sudo dpkg -r geos
 
# download and compile gdal in /opt/gdal
cd ~/src/
wget http://download.osgeo.org/gdal/1.10.0/gdal-1.10.0.tar.gz
tar xvzf gdal-1.10.0.tar.gz
cd gdal-1.10.0/
./configure --prefix=/opt/gdal --with-geos=/opt/geos/bin/geos-config \
  --with-pg=/usr/lib/postgresql/9.2/bin/pg_config --with-python
make -j2
sudo checkinstall  # uninstall with: sudo dpkg -r gdal
 
# download and compile postgis in default location
cd ~/src/
wget http://download.osgeo.org/postgis/source/postgis-2.1.0.tar.gz
tar xvzf postgis-2.1.0.tar.gz
cd postgis-2.1.0/
./configure --with-geosconfig=/opt/geos/bin/geos-config \
  --with-gdalconfig=/opt/gdal/bin/gdal-config
make -j2
sudo checkinstall  # uninstall with: sudo dpkg -r postgis
 
# for command-line tools:
echo 'export PATH="$PATH:/opt/geos/bin:/opt/gdal/bin:/usr/lib/postgresql/9.2/bin"' >> .bashrc
 
# so libraries are found:
echo '/opt/geos/lib
/opt/gdal/lib' | sudo tee /etc/ld.so.conf.d/geolibs.conf
 
sudo ldconfig
 
# restart postgres
sudo /etc/init.d/postgresql restart
 
# restore a pg_dump -Fc backup from an earlier PostGIS version
echo 'create database foodtoeat;' | sudo -u postgres psql
echo 'create extension postgis; create extension postgis_topology;' | sudo -u postgres psql -d foodtoeat
 
echo 'create database testdb;' | sudo -u postgres psql
echo 'create extension postgis; create extension postgis_topology;' | sudo -u postgres psql -d testdb
 
echo 'create database slave;' | sudo -u postgres psql
echo 'create extension postgis; create extension postgis_topology;' | sudo -u postgres psql -d slave