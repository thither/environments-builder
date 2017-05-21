# Debian Enviroment Builder

####   A bash based script to Compile and Install debian environment



## Usages:
  * bash build-debian-env.sh 
     * --sources source-1 source-2  (builds and installs only the specified sources)
       * --help 
     * --verbose
     * --stage N
     
## Directories Configurations: 
  *  ```CUST_INST_PREFIX=/usr/local ``` (equal to the configure --prefix)
 
  *  ```BUILDS_ROOT=~/builds ```
  *  ```SCRIPTS_PATH=$BUILDS_ROOT/scripts ```
  *  ```DOWNLOAD_PATH=$BUILDS_ROOT/downloads ```
  *  ```BUILDS_PATH=$BUILDS_ROOT/sources ```
  *  ```BUILDS_LOG_PATH=$BUILDS_ROOT/logs/$( date  +"%Y-%m-%d_%H-%M-%S") ```
  *  ```BUILTS_PATH=$BUILDS_ROOT/builts ```

## Source Configuration:
 * Add in the function _do_build() to add a named-source case in follow structure:
  ```
    'named-source')
      fn='downloaded.archive.name'; tn='archive-folder-name'; url='URI.tar*';
      set_source 'tar' 
      configure_build ARGUMENTS PASSSED TO configure --prefix=$CUST_INST_PREFIX;
      make;make deciered commands
      shift;;
  ```
 * or the same format os the _do_build function's case, add a bash file in SCRIPTS_PATH directory with the filename named-source.sh (First applies, if exists, the source filename)

## Logging:
Logs are created in the BUILDS_LOG_PATH in a folder of date-time under filename stage number and source-name 

## Liscense:
Please, consult with the liscenses of the sources
