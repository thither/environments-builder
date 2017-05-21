  Installer Scripts format
  ```
  #!/usr/bin/env bash

      fn='downloaded.archive.name'; tn='archive-folder-name'; url='URI.tar*';
      set_source 'tar' # follow, the location is at the extracted archive folder 
      # ./configure 
      # or
      configure_build ARGUMENTS PASSSED TO configure --prefix=$CUST_INST_PREFIX;  # configure out-of-source folder
      make;make desired commands
  ```
