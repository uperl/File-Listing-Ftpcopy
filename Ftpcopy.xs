#include "ftpparse.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = File::Listing::Ftpcopy		PACKAGE = File::Listing::Ftpcopy

SV *
ftpparse(buffer)
        char *buffer;
    INIT:
        HV * result;
        struct ftpparse fp;
        int val;
        char b[48];
    CODE:
        val = ftpparse(&fp, buffer, strlen(buffer), 0);
        if(val)
        {
          result = (HV*)sv_2mortal((SV*)newHV());
          hv_store(result, "name",            4, newSVpv(fp.name,fp.namelen), 0);
          hv_store(result, "flagtrycwd",     10, newSViv(fp.flagtrycwd), 0);
          hv_store(result, "flagtryretr",    11, newSViv(fp.flagtryretr), 0);
          hv_store(result, "sizetype",        8, newSViv(fp.sizetype), 0);
          /*
           * If UV is 64 bit then store size as a UV,
           * otherwise use sprintf and store it as a string.
           * use PRIu64 which is c99, otherwise try %llu
           * and cross fingers that it is supported.
           */
#if IS_64BIT_UV
          hv_store(result, "size",            4, newSVuv(fp.size), 0);
#else
#ifdef PRIu64
          sprintf(b, "%"PRIu64,fp.size);
#else
          sprintf(b, "%llu",fp.size);
#endif
          hv_store(result, "size",            4, newSVpv(b,0), 0);
#endif
          hv_store(result, "mtimetype",       9, newSViv(fp.mtimetype), 0);
#if IS_64BIT_UV
          hv_store(result, "mtime",           5, newSVuv(fp.mtime.x), 0);
#else
#ifdef PRIu64
          sprintf(b, "%"PRIu64,fp.mtime.x);
#else
          sprintf(b, "%llu",fp.mtime.x);
#endif
          hv_store(result, "mtime",           5, newSVpv(b,0), 0);
#endif
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
       

int
_return42()
    CODE:
        RETVAL = (10*4+2);
    OUTPUT:
        RETVAL

int
_size_of_UV()
    CODE:
        RETVAL = sizeof(UV);
    OUTPUT:
        RETVAL

