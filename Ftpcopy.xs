#include "ftpparse.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = File::Listing::Ftpcopy		PACKAGE = File::Listing::Ftpcopy

int
return42()
    CODE:
        RETVAL = (10*4+2);
    OUTPUT:
        RETVAL

SV *
ftpparse(buffer)
        char *buffer;
    INIT:
        HV * results;
        struct ftpparse fp;
        int val;
    CODE:
        val = ftpparse(&fp, buffer, strlen(buffer), 0);
        if(val)
        {
          results = (HV*)sv_2mortal((SV*)newHV());
          hv_store(results, "name", 4, newSVpv(fp.name,fp.namelen), 0);
          hv_store(results, "size", 4, newSViv(fp.size), 0);
          RETVAL = newRV((SV*)results);
        }
        else
        {
          /* return; */
        }
    OUTPUT:
        RETVAL
       

