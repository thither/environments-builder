# Debian Enviroment Builder

####   A bash based script to Compile and Install debian environment




## Usages:
  * bash build-debian-env.sh 
     * --sources source-1 source-2  (builds and installs only the specified sources)
       * --help 
     * --verbose
     * --stage N
     
## Directories Configurations:
  * CUST_INST_PREFIX=/usr/local
    * equal to the configure --prefix
  * BUILDS_ROOT=~/builds
  * SCRIPTS_PATH=$BUILDS_ROOT/scripts
  * DOWNLOAD_PATH=$BUILDS_ROOT/downloads
  * BUILDS_PATH=$BUILDS_ROOT/sources
  * BUILDS_LOG_PATH=$BUILDS_ROOT/logs/$( date  +"%Y-%m-%d_%H-%M-%S")
  * BUILTS_PATH=$BUILDS_ROOT/builts

## Liscense:
Please, consult with the liscenses of the sources
