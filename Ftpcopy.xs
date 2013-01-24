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
        HV * result;
        struct ftpparse fp;
        int val;
    CODE:
        val = ftpparse(&fp, buffer, strlen(buffer), 0);
        if(val)
        {
          result = (HV*)sv_2mortal((SV*)newHV());
          hv_store(result, "name",            4, newSVpv(fp.name,fp.namelen), 0);
          hv_store(result, "flagtrycwd",     10, newSViv(fp.flagtrycwd), 0);
          hv_store(result, "flagtryretr",    11, newSViv(fp.flagtryretr), 0);
          hv_store(result, "sizetype",        8, newSViv(fp.sizetype), 0);
          /* FIXME size is 64 bit */
          hv_store(result, "size",            4, newSVuv(fp.size), 0);
          hv_store(result, "mtimetype",       9, newSViv(fp.mtimetype), 0);
          /* FIXME mtime is 64 bit */
          hv_store(result, "mtime",           5, newSVuv(fp.mtime.x), 0);
          hv_store(result, "idtype",          6, newSViv(fp.idtype), 0);
          hv_store(result, "id",              2, newSVpv(fp.id, fp.idlen), 0);
          hv_store(result, "format",          6, newSViv(fp.format), 0);
          hv_store(result, "flagbrokenmlsx", 14, newSViv(fp.flagbrokenmlsx), 0);
          if(fp.symlink != NULL)
          {
            hv_store(result, "symlink", 7, newSVpv(fp.symlink, fp.symlinklen), 0);
          }
          RETVAL = newRV((SV*)result);
        }
        else
        {
          XSRETURN_EMPTY;
        }
    OUTPUT:
        RETVAL
       

