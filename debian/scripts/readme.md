  Installer Scripts format
  ```
  #!/usr/bin/env bash

      fn='downloaded.archive.name'; tn='archive-folder-name'; url='URI.tar*';
      set_source 'tar' 
      configure_build ARGUMENTS PASSSED TO configure --prefix=$CUST_INST_PREFIX;
      make;make desired commands
  ```
